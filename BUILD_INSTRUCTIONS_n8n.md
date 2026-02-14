# Build Instructions: n8n Grading Workflow

**For:** Teammate building the n8n workflow  
**Project:** AI-Assisted Grading System  
**Date:** February 2026  
**Estimated Time:** 3-4 hours  
**Complexity:** Intermediate (familiarity with n8n, HTTP requests, JSON manipulation required)

---

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Access to the shared n8n cloud workspace
- [ ] Supabase project credentials (URL, service role key, anon key)
- [ ] Google Gemini API key (from Google AI Studio)
- [ ] Reviewed `WORKFLOW.md` for architecture understanding
- [ ] Reviewed `database/schema.sql` for table structures
- [ ] Test data available in Supabase (from `seed_data.sql`)

---

## Architecture Overview

The grading workflow is a **multi-agent pipeline** that processes student essay submissions:

```
┌─────────────────────────────────────────────────────────────────┐
│                     GRADING WORKFLOW                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐                                               │
│  │ Trigger      │  New submission in 'submissions' table        │
│  │ (Webhook)    │  Status = 'pending'                           │
│  │              │  Supabase → Webhook → n8n                     │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │ Fetch Data   │  Get essay text + rubric from Supabase        │
│  │ (Supabase)   │                                               │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │ Reader Agent │  Gemini: Summarize essay, identify key points │
│  │ (Gemini API) │  Prompt: "Read and summarize this essay..."   │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────────────────────────────┐                     │
│  │      PARALLEL SPECIALIST AGENTS        │                     │
│  │  (One per rubric criterion - parallel) │                     │
│  │                                        │                     │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐   │                     │
│  │  │Criterion│ │Criterion│ │Criterion│   │                     │
│  │  │   1     │ │   2     │ │   N     │   │                     │
│  │  │ (Thesis)│ │(Evidence)│ │(Style)  │   │                     │
│  │  └────┬────┘ └────┬────┘ └────┬────┘   │                     │
│  │       └─────────────┴───────────┘       │                     │
│  │                    │                    │                     │
│  └────────────────────┼────────────────────┘                     │
│                       ▼                                         │
│  ┌──────────────┐                                               │
│  │ Synthesis    │  Calculate weighted total score                 │
│  │ Agent        │  Generate overall feedback                      │
│  │ (Code Node)  │  Compile criterion breakdown                    │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │ Save Results │  Insert into 'ai_grades' table                  │
│  │ (Supabase)   │  Status = 'pending_review'                      │
│  └──────┬───────┘                                               │
│         │                                                       │
│         ▼                                                       │
│  ┌──────────────┐                                               │
│  │ Notification │  (Optional) Email professor                     │
│  │ (Email/Slack)│                                               │
│  └──────────────┘                                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Create the Webhook Trigger

### Node: Webhook Trigger (Required)
**Why:** Real-time processing when new submissions are inserted

**Configuration:**
```
Node Type: Webhook
Method: POST
Path: submission-received
Response Mode: Response Node
```

**Important Configuration Details:**
1. **Webhook URL:** After saving the workflow, n8n will generate a URL like:
   ```
   https://your-n8n-instance.com/webhook/submission-received
   ```

2. **Configure Supabase Webhook:** In Supabase Dashboard → Database → Webhooks, create a new webhook:
   - **Name:** submission_inserted
   - **Table:** submissions
   - **Events:** INSERT
   - **URL:** Paste the n8n webhook URL
   - **Headers:** (optional) Add authentication if needed

3. **Response Handling:** Add a "Respond to Webhook" node at the END of your workflow to return HTTP 200 to Supabase:
   ```
   Node Type: Respond to Webhook
   Status Code: 200
   Response Body: { "status": "graded", "submission_id": "{{ $json.submission_id }}" }
   ```

**Note:** Supabase webhooks timeout after 5 seconds. If grading takes longer, the webhook will retry. Make your workflow idempotent (safe to run multiple times on same submission).

**Idempotency Check:** At the start of workflow, verify submission isn't already being graded:
```javascript
// Code node after Webhook Trigger
const submission = $input.first().json;
if (submission.status !== 'pending') {
  return [{ json: { skipped: true, reason: "Already processed" } }];
}
return [{ json: submission }];
```

---

## Step 2: Verify & Fetch Submission Data

### Node: Supabase (Get)

**Purpose:** Fetch full submission data from the webhook payload ID

**Configuration:**
```
Node Type: Supabase
Operation: Get
Table: submissions
ID: {{ $json.record.id }}
```

**Note:** Supabase webhooks send the payload in `$json.record`, not `$json` directly.

### Node: Code (Idempotency Check)

**Purpose:** Skip if already processed (prevents duplicate grading on webhook retries)

**Code:**
```javascript
const submission = $input.first().json;

if (submission.status !== 'pending') {
  return [{ 
    json: { 
      skipped: true, 
      reason: "Submission already processed",
      submission_id: submission.id 
    } 
  }];
}

return [{ json: submission }];
```

**After this node, add an IF node:**
- Condition: `skipped` is not true
- If true: Continue workflow
- If false: End execution (submission already graded)

---

## Step 3: Get Rubric and Few-Shot Examples

### Node: Supabase (Get)

**Configuration:**
```
Node Type: Supabase
Operation: Get
Table: rubrics
ID: {{ $json.rubric_id }}
```

**Important:** The rubric JSON contains:
- `criteria[]` - Array of criteria with names, descriptions, weights, max_scores
- `total_points` - Sum of all max_scores

Also fetch few-shot examples:
```
Node Type: Supabase
Operation: Get Many
Table: few_shot_examples
Match: rubric_id = {{ $json.rubric_id }}
Limit: 5
```

---

## Step 4: Reader Agent (Gemini API)

### Node: HTTP Request

**Purpose:** Summarize the essay and identify key arguments for specialist agents.

**Configuration:**
```
Node Type: HTTP Request
Method: POST
URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash:generateContent?key={{ $env.GEMINI_API_KEY }}
Headers:
  Content-Type: application/json
Body (JSON):
```

**Prompt Template:**
```json
{
  "contents": [{
    "parts": [{
      "text": "You are an expert essay analyst. Read the following student essay and provide a structured summary.

ESSAY:
\"\"\"{{ $json.essay_text }}\"\"\"

Please provide:
1. **Main Thesis**: The central argument or claim
2. **Key Points**: 3-5 main supporting points
3. **Evidence Quality**: Brief assessment of evidence used
4. **Structure**: How the essay is organized
5. **Writing Quality**: General assessment of clarity and style

Format your response as JSON:
{
  \"main_thesis\": \"...\",
  \"key_points\": [\"...\", \"...\", \"...\"],
  \"evidence_assessment\": \"...\",
  \"structure_notes\": \"...\",
  \"writing_quality\": \"...\"
}"
    }]
  }],
  "generationConfig": {
    "temperature": 0.1,
    "maxOutputTokens": 1024
  }
}
```

**Why temperature 0.1:** Low temperature for consistency. Research shows this reduces variance.

**Parse Response:** Use "Respond to Webhook" or a Code node to extract the JSON from Gemini's response.

---

## Step 5: Specialist Agents (Parallel Processing)

This is the **most critical** step. You need to create parallel branches, one per rubric criterion.

### Option A: Split Out Node (Recommended)

**Configuration:**
```
Node Type: Split Out
Field: criteria (from rubric JSON)
```

This creates parallel items, one for each criterion.

### Option B: For Each + HTTP Request

For each criterion, create an HTTP Request node calling Gemini:

**Configuration per Specialist:**
```
Node Type: HTTP Request
Method: POST
URL: https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash:generateContent?key={{ $env.GEMINI_API_KEY }}
```

**Specialist Prompt Template:**
```json
{
  "contents": [{
    "parts": [{
      "text": "You are a specialist evaluator focusing ONLY on: {{ $json.criterion_name }}

RUBRIC CRITERION:
Name: {{ $json.criterion_name }}
Description: {{ $json.criterion_description }}
Max Score: {{ $json.max_score }}
Weight: {{ $json.weight }}%

ESSAY SUMMARY (from Reader Agent):
{{ $('Reader Agent').item.json.main_thesis }}
{{ $('Reader Agent').item.json.key_points }}

FULL ESSAY:
\"\"\"{{ $json.essay_text }}\"\"\"

FEW-SHOT EXAMPLES:
{{ $json.few_shot_examples }}

Evaluate this essay SOLELY on {{ $json.criterion_name }}. Provide:

1. **Score** (0-{{ $json.max_score }}): Specific numeric score
2. **Reasoning**: 2-3 sentences explaining the score
3. **Evidence**: Quote specific parts of the essay that support your score
4. **Improvement Tip**: One concrete suggestion for improvement

Respond ONLY with this JSON structure:
{
  \"criterion\": \"{{ $json.criterion_name }}\",
  \"score\": <number>,
  \"max_score\": {{ $json.max_score }},
  \"reasoning\": \"...\",
  \"evidence\": \"...\",
  \"improvement_tip\": \"...\"
}"
    }]
  }],
  "generationConfig": {
    "temperature": 0.1,
    "maxOutputTokens": 512
  }
}
```

**Key Points:**
- Each specialist only evaluates ONE criterion
- Include Reader Agent summary for context
- Include few-shot examples to align with professor's style
- Return structured JSON for easy parsing

---

## Step 6: Aggregate Specialist Results

### Node: Code (JavaScript)

**Purpose:** Combine all specialist evaluations into a single grade object.

**Code:**
```javascript
// Input: Array of specialist results
const specialists = $input.all()[0].json;

// Calculate weighted score
let totalWeightedScore = 0;
let totalPossibleWeighted = 0;

const criterionBreakdown = specialists.map(spec => {
  const weight = spec.json.weight || 25; // Default 25% if not specified
  const score = spec.json.score;
  const maxScore = spec.json.max_score;
  
  const weightedScore = (score / maxScore) * weight;
  const weightedMax = weight;
  
  totalWeightedScore += weightedScore;
  totalPossibleWeighted += weightedMax;
  
  return {
    criterion: spec.json.criterion,
    score: score,
    max_score: maxScore,
    weight: weight,
    weighted_contribution: weightedScore,
    reasoning: spec.json.reasoning,
    evidence: spec.json.evidence,
    improvement_tip: spec.json.improvement_tip
  };
});

// Calculate final percentage
const finalPercentage = (totalWeightedScore / totalPossibleWeighted) * 100;
const finalScore = Math.round(finalPercentage);

// Generate overall feedback summary
const overallFeedback = generateOverallFeedback(criterionBreakdown);

// Return structured result
return {
  json: {
    submission_id: $input.first().json.submission_id,
    overall_score: finalScore,
    total_points: Math.round((finalPercentage / 100) * $input.first().json.total_points),
    max_total_points: $input.first().json.total_points,
    percentage: finalPercentage,
    criterion_breakdown: criterionBreakdown,
    overall_feedback: overallFeedback,
    grading_metadata: {
      model_used: "gemini-3-flash",
      temperature: 0.1,
      specialist_count: specialists.length,
      graded_at: new Date().toISOString()
    }
  }
};

function generateOverallFeedback(breakdown) {
  const strengths = breakdown
    .filter(c => (c.score / c.max_score) >= 0.8)
    .map(c => c.criterion);
  
  const improvements = breakdown
    .filter(c => (c.score / c.max_score) < 0.7)
    .map(c => c.improvement_tip);
  
  let feedback = "## Overall Assessment\n\n";
  
  if (strengths.length > 0) {
    feedback += "**Strengths:** This essay demonstrates strong " + 
                strengths.join(", ") + ".\n\n";
  }
  
  if (improvements.length > 0) {
    feedback += "**Areas for Improvement:**\n";
    improvements.forEach((tip, i) => {
      feedback += `${i + 1}. ${tip}\n`;
    });
  }
  
  return feedback;
}
```

---

## Step 7: Save AI Grade to Database

### Node: Supabase (Insert)

**Configuration:**
```
Node Type: Supabase
Operation: Insert
Table: ai_grades
Data (JSON):
{
  "submission_id": "{{ $json.submission_id }}",
  "rubric_id": "{{ $json.rubric_id }}",
  "overall_score": {{ $json.total_points }},
  "criterion_scores": {{ JSON.stringify($json.criterion_breakdown) }},
  "feedback": "{{ $json.overall_feedback }}",
  "status": "pending_review",
  "graded_by_model": "{{ $json.grading_metadata.model_used }}",
  "grading_metadata": {{ JSON.stringify($json.grading_metadata) }}
}
```

---

## Step 8: Update Submission Status

### Node: Supabase (Update)

**Configuration:**
```
Node Type: Supabase
Operation: Update
Table: submissions
ID: {{ $json.submission_id }}
Data:
{
  "status": "graded"
}
```

---

## Step 9: (Optional) Notify Professor

### Node: Email or Slack

**Email Configuration:**
```
Node Type: Send Email
To: {{ $json.professor_email }}
Subject: New AI Grade Ready for Review - {{ $json.student_name }}
Body: |
  A new essay has been graded by AI and is awaiting your review.
  
  Student: {{ $json.student_name }}
  Assignment: {{ $json.assignment_title }}
  AI Score: {{ $json.overall_score }}/{{ $json.max_total_points }}
  
  Review at: [Dashboard Link]
```

---

## Complete Workflow JSON Structure

Here's the high-level flow structure:

```json
{
  "name": "AI Grading Workflow",
  "nodes": [
    {
      "name": "Webhook Trigger",
      "type": "webhook",
      "position": [0, 300]
    },
    {
      "name": "Get Submission",
      "type": "supabase",
      "position": [200, 300]
    },
    {
      "name": "Check If Pending",
      "type": "if",
      "position": [300, 300]
    },
    {
      "name": "Get Rubric",
      "type": "supabase",
      "position": [400, 300]
    },
    {
      "name": "Reader Agent",
      "type": "httpRequest",
      "position": [600, 300]
    },
    {
      "name": "Split Criteria",
      "type": "splitOut",
      "position": [800, 300]
    },
    {
      "name": "Specialist Agent",
      "type": "httpRequest",
      "position": [1000, 300]
    },
    {
      "name": "Aggregate Results",
      "type": "code",
      "position": [1200, 300]
    },
    {
      "name": "Save AI Grade",
      "type": "supabase",
      "position": [1400, 300]
    },
    {
      "name": "Update Submission",
      "type": "supabase",
      "position": [1600, 300]
    }
  ],
  "connections": {
    "Webhook Trigger": ["Get Submission"],
    "Get Submission": ["Check If Pending"],
    "Check If Pending (true)": ["Get Rubric"],
    "Get Rubric": ["Reader Agent"],
    "Reader Agent": ["Split Criteria"],
    "Split Criteria": ["Specialist Agent"],
    "Specialist Agent": ["Aggregate Results"],
    "Aggregate Results": ["Save AI Grade"],
    "Save AI Grade": ["Update Submission"]
  }
}
```

---

## Testing Procedure

### Step 1: Test with Seed Data

1. Ensure seed data is loaded in Supabase:
   - Sample rubric exists
   - Few-shot examples loaded
   - Test submission in "pending" status

2. Run workflow manually:
   - Click "Execute Workflow"
   - Check execution log for each node

3. Verify database:
   ```sql
   SELECT * FROM ai_grades WHERE submission_id = '<test_submission_id>';
   ```

### Step 2: Validate AI Reasoning

Check that the AI grade includes:
- [ ] Criterion-by-criterion breakdown
- [ ] Specific evidence quotes from essay
- [ ] Actionable improvement tips
- [ ] Metadata (model, temperature, timestamp)

### Step 3: Test Edge Cases

- [ ] Very long essays (10,000+ words)
- [ ] Essays with poor grammar/spelling
- [ ] Essays that are off-topic
- [ ] Empty or very short submissions
- [ ] Non-English essays (if supported)

---

## Troubleshooting Guide

### Problem: Gemini API returns errors

**Symptoms:** HTTP Request node fails with 4xx or 5xx error

**Solutions:**
1. Check API key is valid and has quota remaining
2. Verify essay text isn't too long (Gemini has context limits)
3. Check JSON in prompt is properly escaped
4. Add "Retry" configuration to HTTP Request node:
   ```
   Retry: On Error
   Max Retries: 3
   Retry Interval: 1000ms
   ```

### Problem: Specialist agents timeout

**Symptoms:** Workflow hangs on Specialist Agent node

**Solutions:**
1. Reduce parallel execution (add "Wait" nodes between batches)
2. Increase timeout in HTTP Request node to 60 seconds
3. Consider using Gemini 1.5 Flash instead of 3 Flash for faster responses

### Problem: JSON parsing errors

**Symptoms:** Code node fails with "Unexpected token" or "undefined"

**Solutions:**
1. Add a "Set" node before Code node to validate JSON structure
2. Use try/catch in JavaScript code
3. Add fallback values for missing fields

### Problem: Inconsistent scores between runs

**Symptoms:** Same essay gets different scores on multiple runs

**Expected:** This is documented in LITERATURE_REVIEW_2.md. Variance should be ±5-10%.

**Mitigation:**
1. Ensure temperature is set to 0.1 (not higher)
2. Verify few-shot examples are being included in prompts
3. Accept that some variance is normal - HITL review catches major discrepancies

---

## Environment Variables Required

Add these to your n8n workspace Settings → Variables:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
GEMINI_API_KEY=AIzaSy...
```

**IMPORTANT:** Never expose service role key in frontend code. Only use in n8n backend workflows.

---

## Success Criteria

The workflow is working correctly when:

- [ ] Webhook receives submission within seconds of student upload
- [ ] Idempotency check prevents duplicate grading
- [ ] Reader Agent produces consistent essay summaries
- [ ] Specialist Agents evaluate ALL rubric criteria
- [ ] Weighted scores calculate correctly (Σ(score/max × weight))
- [ ] Results save to ai_grades table with status "pending_review"
- [ ] Professor can review in dashboard and see AI reasoning
- [ ] Entire process completes in under 2 minutes per essay

---

## Next Steps After Build

1. **Integrate with Professor Dashboard** - Build frontend for grade review
2. **Add Monitoring** - Log execution times, error rates, AI/professor agreement
3. **Build Calibration Mode** - Submit same essay 3x to test consistency
4. **Add Strictness Slider** - Professor can adjust grading leniency (see USER_STORIES.md feedback)

---

## Questions?

If you get stuck:
1. Check `WORKFLOW.md` for detailed architecture explanation
2. Review `LITERATURE_REVIEW_2.md` for why we chose this design
3. Test individual nodes before connecting the full workflow
4. Use n8n's "Execute Node" feature to debug step-by-step

**Estimated build time:** 3-4 hours for experienced n8n user, 6-8 hours if new to n8n.

Good luck! 🚀
