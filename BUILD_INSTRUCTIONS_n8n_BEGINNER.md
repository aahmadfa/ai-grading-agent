# n8n Grading Workflow - Step-by-Step Visual Guide

**For:** Beginner n8n user (drag-and-drop, no coding required)  
**Project:** AI-Assisted Grading System  
**Estimated Time:** 2-3 hours  
**Last Updated:** February 2026

---

## Before You Start

### What You'll Build
A workflow that automatically grades student essays when they're submitted. It looks like this:

```
[Student submits essay] → [Webhook receives it] → [AI reads essay] → [AI evaluates each rubric criterion] → [Save grade] → [Notify professor]
```

### Open These Tabs
1. Your n8n cloud workspace (https://[your-workspace].n8n.cloud)
2. Supabase dashboard (for database info)
3. Google AI Studio (for Gemini API key)
4. This document

---

## Part 1: Setup & Credentials (15 minutes)

### Step 1.1: Get Your Gemini API Key

1. Go to https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key (starts with `AIzaSy...`)
4. Save it in a text file - you'll need it in Step 1.3

### Step 1.2: Confirm Supabase Credentials

You should already have these from the project setup:
- Supabase URL: `https://xxxx.supabase.co`
- Service Role Key: `eyJ...` (long string)

If you don't have them, ask your teammate or check the `.env` file in the project.

### Step 1.3: Add Credentials to n8n

This is SUPER IMPORTANT - do this first!

1. In n8n, click the **Settings** gear icon (bottom left)
2. Click **External Secrets** or **Variables** (depending on your n8n version)
3. Click **Add New Variable**
4. Add these three variables one by one:

| Name | Value | Example |
|------|-------|---------|
| `SUPABASE_URL` | Your Supabase URL | `https://abc123.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Your service role key | `eyJhbGciOiJIUzI1NiIs...` |
| `GEMINI_API_KEY` | Your Gemini API key | `AIzaSyABC123...` |

5. Click **Save** after each one

**Visual:** Settings → Variables → + Add Variable

---

## Part 2: Create the Workflow Canvas (5 minutes)

### Step 2.1: Create New Workflow

1. In n8n, click the **+** button (top left, next to "Workflows")
2. Click **Blank Workflow**
3. You'll see an empty canvas with "Add first step" in the middle

### Step 2.2: Name Your Workflow

1. Click "Untitled Workflow" at the top
2. Rename to: `AI Essay Grading Workflow`
3. Press Enter

### Step 2.3: Save Your Work

1. Click **Save** button (top right, floppy disk icon)
2. Your workflow auto-saves, but get in the habit of clicking Save

---

## Part 3: Step 1 - Webhook Trigger (10 minutes)

### What This Does
When a student submits an essay, Supabase sends a "ping" to n8n. This node "catches" that ping.

### How to Add It

1. Click the **+** (Add node) button on the canvas
2. Type "webhook" in the search box
3. Click **Webhook** from the results
4. It appears on your canvas

### Configure the Webhook

1. **Click** on the Webhook node to open settings (right panel opens)

2. **Method**: Select `POST` from dropdown

3. **Path**: Type `grade-essay`
   - This creates a URL like: `https://your-n8n.cloud/webhook/grade-essay`
   - **Copy this URL** - you'll need it in Step 3.5

4. **Response**: Select `Using 'Respond to Webhook' node`
   - This means the workflow will respond later, not immediately

5. Click **Test Step** (bottom of the panel)
   - You'll see "Waiting for webhook call..."
   - Don't close this - we'll test it in Step 3.5

**Visual:** Canvas shows "Webhook" node with orange dot (not connected yet)

---

## Part 4: Step 2 - Get Submission from Database (10 minutes)

### What This Does
The webhook only gives us the submission ID. We need to fetch the full essay text and rubric ID from Supabase.

### How to Add It

1. Click the **+** button on the **right side** of the Webhook node
   - OR: Drag from the Webhook node's output (little circle on right) to empty space
2. Type "supabase" in search
3. Click **Supabase** node

### Connect Supabase Credentials

1. Click the **Supabase** node to open settings
2. **Credential**: Click `Select Credential` dropdown
3. If you see your Supabase credential, select it
4. If not:
   - Click **Create New Credential**
   - **Host**: Type your Supabase URL (from Step 1.2)
   - **Service Role Secret**: Paste your service role key
   - Click **Save**

### Configure the Database Operation

1. **Operation**: Select `Get` from dropdown (this fetches ONE record)

2. **Table**: Click dropdown, select `submissions`

3. **ID**: Click in the field, then click the **gear icon** (expression builder)
   - Type this exactly: `{{ $json.body.record.id }}`
   - This gets the submission ID from the webhook
   - Click outside to close

4. Click **Test Step** (bottom of panel)
   - You'll see an error "Cannot read property..." - that's OK!
   - It's because we haven't sent a real webhook yet

**Visual:** Webhook node → Supabase node (connected by line)

---

## Part 5: Step 3 - Check If Already Graded (10 minutes)

### What This Does
Sometimes webhooks get sent twice (network hiccups). This prevents grading the same essay twice.

### How to Add It

1. Click the **+** on the right side of the Supabase node
2. Type "if" in search
3. Click **IF** node

### Configure the Condition

1. Click the **IF** node to open settings

2. **Conditions**: Keep it simple
   - **Value 1**: Click gear icon, type: `{{ $json.status }}`
   - **Operation**: Select `equals` from dropdown
   - **Value 2**: Type exactly: `pending`

3. This creates two paths:
   - **TRUE** (green line): Status IS "pending" → Continue grading
   - **FALSE** (red line): Status is NOT "pending" → Skip

### Add "No Op" for FALSE Path (Skip)

1. Click the **+** on the **red output** (bottom one) of the IF node
2. Type "no op" in search
3. Click **No Operation, do nothing**
4. This is the "skip" path - nothing happens if already graded

**Visual:** Supabase → IF node with two outputs (green=true, red=false) → red goes to No Op

---

## Part 6: Step 4 - Get Rubric (10 minutes)

### What This Does
Fetch the rubric (grading criteria) that applies to this essay.

### How to Add It

1. Click the **+** on the **green output** (top one) of the IF node
2. Type "supabase"
3. Click **Supabase** node

### Configure the Node

1. **Credential**: Select the same Supabase credential from Step 4.2

2. **Operation**: Select `Get`

3. **Table**: Select `rubrics`

4. **ID**: Click gear icon, type: `{{ $json.rubric_id }}`
   - This gets the rubric_id from the submission we fetched

5. Click **Test Step** (you may see error - OK for now)

**Visual:** IF (green) → Supabase (Get Rubric)

---

## Part 7: Step 5 - Reader Agent (AI Summarizes Essay) (15 minutes)

### What This Does
AI reads the essay and creates a summary. This summary helps all the specialist graders.

### How to Add It

1. Click the **+** on the right side of the Rubric Supabase node
2. Type "http request"
3. Click **HTTP Request** node

### Configure the HTTP Request

1. **Method**: Select `POST`

2. **URL**: Paste this exact URL:
   ```
   https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={{ $env.GEMINI_API_KEY }}
   ```

3. **Authentication**: Select `None` (the API key is in the URL)

4. **Send Body**: Toggle this ON (green)

5. **Content Type**: Select `application/json`

6. **Body**: Click in the text area. Type this JSON exactly:

```json
{
  "contents": [{
    "parts": [{
      "text": "You are an expert essay analyst. Read this student essay and provide a structured summary.\n\nESSAY:\n\"\"\"{{ $json.essay_text }}\"\"\"\n\nProvide:\n1. Main Thesis: The central argument\n2. Key Points: 3-5 main supporting points\n3. Evidence Quality: Brief assessment\n4. Structure: How it's organized\n5. Writing Quality: Clarity and style assessment\n\nFormat as JSON:\n{\n  \"main_thesis\": \"...\",\n  \"key_points\": [\"...\", \"...\"],\n  \"evidence_assessment\": \"...\",\n  \"structure_notes\": \"...\",\n  \"writing_quality\": \"...\"\n}"
    }]
  }],
  "generationConfig": {
    "temperature": 0.1,
    "maxOutputTokens": 1024
  }
}
```

**Important:** The `{{ $json.essay_text }}` pulls the essay from the submission. Make sure it has double curly braces.

7. Click **Test Step** (will error until we test end-to-end)

**Visual:** Rubric Supabase → HTTP Request (Reader Agent)

---

## Part 8: Step 6 - Specialist Agents (Parallel Grading) (20 minutes)

### What This Does
Create multiple AI "graders," one for each rubric criterion. They all grade at the same time.

### How to Add It

1. Click the **+** on the right side of the Reader Agent HTTP node
2. Type "split out"
3. Click **Split Out** node

### Configure Split Out

1. **Field to Split Out**: Click dropdown
2. Select `rubric` → `criteria`
   - This creates one branch for each rubric criterion
   - If rubric has 4 criteria, you get 4 parallel branches

**Visual:** Reader Agent → Split Out (creates multiple branches)

### Add Specialist Grader Node

1. Click the **+** on the right side of Split Out node
2. Type "http request"
3. Click **HTTP Request**

### Configure Specialist HTTP Request

1. **Method**: `POST`

2. **URL**: Paste same URL as Reader Agent:
   ```
   https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={{ $env.GEMINI_API_KEY }}
   ```

3. **Send Body**: Toggle ON

4. **Content Type**: `application/json`

5. **Body**: Type this (longer prompt):

```json
{
  "contents": [{
    "parts": [{
      "text": "You are a specialist grader. Evaluate ONLY this criterion:\n\nCRITERION: {{ $json.name }}\nDESCRIPTION: {{ $json.description }}\nMAX SCORE: {{ $json.max_score }}\nWEIGHT: {{ $json.weight }}%\n\nESSAY SUMMARY:\n{{ $node['Reader Agent'].json.content.parts[0].text }}\n\nFULL ESSAY:\n\"\"\"{{ $node['Supabase'].json.essay_text }}\"\"\"\n\nRate this essay 0-{{ $json.max_score }} on {{ $json.name }} ONLY. Provide:\n\n1. Score: specific number\n2. Reasoning: 2-3 sentences\n3. Evidence: quote from essay\n4. Improvement: one tip\n\nRespond ONLY as JSON:\n{\n  \"criterion\": \"{{ $json.name }}\",\n  \"score\": <number>,\n  \"max_score\": {{ $json.max_score }},\n  \"reasoning\": \"...\",\n  \"evidence\": \"...\",\n  \"improvement_tip\": \"...\"\n}"
    }]
  }],
  "generationConfig": {
    "temperature": 0.1,
    "maxOutputTokens": 512
  }
}
```

**Note:** The `$node['Reader Agent']` references the summary from the previous step.

**Visual:** Split Out → HTTP Request (Specialist) - will duplicate for each criterion

---

## Part 9: Step 7 - Aggregate Results (10 minutes)

### What This Does
Combine all the specialist grades into one final grade.

### How to Add It

1. Click the **+** on the right side of the Specialist HTTP node
2. Type "code"
3. Click **Code** node

### Write the Code

1. Click the **Code** node to open settings
2. In the JavaScript editor, DELETE the default code
3. Paste this exact code:

```javascript
// Get all specialist results
const allResults = $input.all();

// Calculate weighted score
let totalWeightedScore = 0;
let totalWeight = 0;
const breakdown = [];

for (const result of allResults) {
  const specialist = result.json;
  
  // Parse the AI response (it's in content.parts[0].text)
  const aiResponse = specialist.content?.parts?.[0]?.text || specialist.text || '{}';
  
  // Extract JSON from AI response (it may have markdown ```json blocks)
  let jsonStr = aiResponse;
  if (aiResponse.includes('```json')) {
    jsonStr = aiResponse.split('```json')[1].split('```')[0].trim();
  } else if (aiResponse.includes('```')) {
    jsonStr = aiResponse.split('```')[1].split('```')[0].trim();
  }
  
  try {
    const gradeData = JSON.parse(jsonStr);
    
    const weight = gradeData.weight || 25;
    const score = gradeData.score || 0;
    const maxScore = gradeData.max_score || 100;
    
    const weightedScore = (score / maxScore) * weight;
    totalWeightedScore += weightedScore;
    totalWeight += weight;
    
    breakdown.push({
      criterion: gradeData.criterion,
      score: score,
      max_score: maxScore,
      weight: weight,
      percentage: Math.round((score / maxScore) * 100),
      reasoning: gradeData.reasoning,
      evidence: gradeData.evidence,
      improvement_tip: gradeData.improvement_tip
    });
  } catch (e) {
    // If parsing fails, skip this specialist
    console.log('Failed to parse:', jsonStr);
  }
}

const finalPercentage = totalWeight > 0 ? (totalWeightedScore / totalWeight) * 100 : 0;
const finalScore = Math.round(finalPercentage);

// Build feedback summary
let feedback = `## Overall Score: ${finalScore}%\n\n`;
feedback += `### Criterion Breakdown:\n\n`;

for (const item of breakdown) {
  feedback += `**${item.criterion}**: ${item.score}/${item.max_score} (${item.percentage}%)\n`;
  feedback += `- ${item.reasoning}\n`;
  if (item.improvement_tip) {
    feedback += `- 💡 *Tip: ${item.improvement_tip}*\n`;
  }
  feedback += `\n`;
}

// Return the result
return {
  json: {
    overall_score: finalScore,
    percentage: Math.round(finalPercentage * 10) / 10,
    criterion_breakdown: breakdown,
    overall_feedback: feedback,
    graded_at: new Date().toISOString()
  }
};
```

4. Click **Test Step** (may show error until full test)

**Visual:** Specialist HTTP → Code (Aggregate)

---

## Part 10: Step 8 - Save Grade to Database (10 minutes)

### What This Does
Save the final grade to the `ai_grades` table.

### How to Add It

1. Click the **+** on the right side of Code node
2. Type "supabase"
3. Click **Supabase**

### Configure the Node

1. **Credential**: Select your Supabase credential

2. **Operation**: Select `Insert` (creates new record)

3. **Table**: Select `ai_grades`

4. **Columns to Send**: Toggle this ON (allows manual entry)

5. Click **Add Field** for each column:

| Column Name | Value (click gear icon, type expression) |
|-------------|------------------------------------------|
| `submission_id` | `{{ $node['Supabase'].json.id }}` |
| `rubric_id` | `{{ $node['Supabase'].json.rubric_id }}` |
| `overall_score` | `{{ $json.overall_score }}` |
| `criterion_scores` | `{{ JSON.stringify($json.criterion_breakdown) }}` |
| `feedback` | `{{ $json.overall_feedback }}` |
| `status` | Type exactly: `pending_review` |
| `graded_by_model` | Type exactly: `gemini-1.5-flash` |

**Important:** The `$node['Supabase']` refers to the first Supabase node (the one that got the submission).

**Visual:** Code → Supabase (Insert Grade)

---

## Part 11: Step 9 - Update Submission Status (5 minutes)

### What This Does
Mark the submission as "graded" so we don't process it again.

### How to Add It

1. Click the **+** on the right side of the Insert Supabase node
2. Type "supabase"
3. Click **Supabase**

### Configure the Node

1. **Credential**: Select Supabase credential

2. **Operation**: Select `Update` (modifies existing record)

3. **Table**: Select `submissions`

4. **ID**: `{{ $node['Supabase'].json.id }}`

5. **Columns to Send**: Toggle ON

6. **Add Field**:
   - Column: `status`
   - Value: `graded`

**Visual:** Supabase (Insert) → Supabase (Update)

---

## Part 12: Step 10 - Respond to Webhook (5 minutes)

### What This Does
Tell Supabase "I'm done!" so it knows the webhook was processed successfully.

### How to Add It

1. Click the **+** on the right side of Update Supabase node
2. Type "respond to webhook"
3. Click **Respond to Webhook**

### Configure the Node

1. **Status Code**: Type `200`

2. **Response Body Mode**: Select `JSON`

3. **JSON Body**: Type:
```json
{
  "status": "success",
  "message": "Essay graded successfully",
  "score": "{{ $node['Code'].json.overall_score }}"
}
```

**Visual:** Supabase (Update) → Respond to Webhook

---

## Part 13: Set Up Supabase Webhook (15 minutes)

### What This Does
Tell Supabase: "When a new submission is inserted, ping n8n"

### Steps

1. Go to your Supabase Dashboard
2. Click **Database** (left sidebar)
3. Click **Webhooks** (near top)
4. Click **Create New Webhook**
5. Configure:

| Setting | Value |
|---------|-------|
| **Name** | `Grade Essay on Submit` |
| **Table** | `submissions` |
| **Events** | Check `INSERT` only |
| **URL** | Paste your n8n webhook URL from Step 3 |
| **HTTP Method** | `POST` |
| **Headers** | Leave default |

6. Click **Confirm** or **Create Webhook**

### Test the Webhook

1. Go to Supabase Table Editor
2. Find `submissions` table
3. Click **Insert** → **Insert row**
4. Fill in test data:
   - `professor_email`: your email
   - `student_email`: test@student.com
   - `rubric_id`: [copy a rubric ID from your rubrics table]
   - `essay_text`: "This is a test essay about the importance of education..."
   - `status`: `pending`
5. Click **Save**

6. **Check n8n** - you should see the workflow running!

---

## Part 14: Testing Your Workflow (20 minutes)

### Method 1: Test via Supabase (Recommended)

1. Insert test submission in Supabase (as in Part 13)
2. Go to n8n **Executions** tab (top menu)
3. You should see your workflow running
4. Click the execution to see step-by-step progress
5. Check for green checkmarks (success) or red X's (errors)

### Method 2: Test Individual Nodes

1. Click on any node in your workflow
2. Click **Test Step** (bottom of settings panel)
3. See the output data immediately
4. Great for debugging!

### Check Database

After running, check these tables in Supabase:

1. `ai_grades` - should have a new row with:
   - `status`: `pending_review`
   - `overall_score`: number
   - `feedback`: text with breakdown

2. `submissions` - your test row should show:
   - `status`: `graded`

---

## Troubleshooting Common Issues

### Issue: "Cannot read property 'id' of undefined"

**Problem:** The webhook data isn't structured as expected.

**Fix:** In the first Supabase node, change the ID field to:
- Try: `{{ $json.id }}`
- Or: `{{ $json.body.id }}`
- Or: `{{ $json.body.record.id }}`

Test with actual webhook to see the structure.

### Issue: "Failed to execute workflow"

**Problem:** Missing credentials or wrong API key.

**Fix:** 
1. Check Settings → Credentials
2. Verify Gemini API key is valid at https://aistudio.google.com/app/apikey
3. Check Supabase service role key hasn't expired

### Issue: AI returns gibberish or no JSON

**Problem:** The AI didn't follow the JSON format instruction.

**Fix:**
1. In the prompt, add: "Respond ONLY with valid JSON. No markdown, no explanations."
2. Check the Code node error handling - it should skip malformed responses

### Issue: Workflow runs twice on same essay

**Problem:** Webhook retried before status was updated.

**Fix:** The IF node should catch this. Make sure:
1. IF node checks `{{ $json.status }}` equals `pending`
2. The FALSE path goes to No Op
3. Supabase Update happens BEFORE Respond to Webhook

---

## Success Checklist

Your workflow is working when:

- [ ] Webhook receives ping from Supabase within seconds
- [ ] IF node correctly skips already-graded essays
- [ ] Reader Agent creates essay summary
- [ ] Split Out creates parallel branches for each rubric criterion
- [ ] All Specialist Agents return grades
- [ ] Code node calculates final weighted score
- [ ] Grade saves to `ai_grades` table with status `pending_review`
- [ ] Submission status updates to `graded`
- [ ] Total time under 2 minutes per essay

---

## Next Steps After Build

1. **Build Professor Dashboard** - Interface to review AI grades
2. **Add Email Notifications** - Notify professor when grading complete
3. **Add Error Handling** - What happens if AI fails?
4. **Add Strictness Slider** - Professor can adjust grading leniency

---

## Need Help?

If stuck:
1. Check n8n documentation: https://docs.n8n.io
2. Check workflow execution logs (Executions tab)
3. Test individual nodes one at a time
4. Ask your teammate for the original `BUILD_INSTRUCTIONS_n8n.md` for reference

**You've got this!** 🎉

---

*Document created: February 2026*  
*Format: Drag-and-drop visual guide for beginners*
