# AI-Assisted Grading Workflow Architecture

## Overview
Multi-agent AI system that transforms subjective essay grading from a single-shot LLM call into a structured, transparent, and human-supervised process.

## Workflow Stages

### Stage 1: Submission Ingestion
```
Student submits essay → Webhook trigger → Save to Supabase → Begin AI grading
```

**Process:**
1. Student uploads essay via web interface
2. Essay saved to `submissions` table with `pending` status
3. n8n webhook `/grade-essay` triggered with `submission_id`
4. Workflow begins AI processing

### Stage 2: Reader Agent (Context Analysis)
```
Essay + Rubric → Gemini Reader Agent → Extract thesis & narrative structure
```

**Purpose:** Establish high-level understanding before detailed analysis

**Input:**
- Student essay text
- Assignment prompt (from rubric)
- Course context (from few-shot examples)

**Output (JSON):**
```json
{
  "thesis_statement": "Tesla has revolutionized automotive industry...",
  "narrative_summary": "Essay analyzes Tesla's business model innovations...",
  "topic_adherence": true
}
```

**Why this matters:** Prevents "Halo Effect" where good grammar masks weak arguments by first establishing the core argument structure.

### Stage 3: Parallel Specialist Agents (Rubric Evaluation)
```
Reader Output → Split into N branches → N Specialist Agents → Individual scores
```

**Dynamic Agent Creation:**
- **4 rubric criteria** → **4 parallel Specialist Agents**
- Each agent specializes in one dimension
- All agents run simultaneously for efficiency

**Specialist Agent Template:**
```
You are evaluating: {criterion.name} ({criterion.weight}% of grade)

Description: {criterion.description}

Reader's Analysis: {reader_output}

Few-Shot Examples: {relevant_examples}

Essay: {essay_text}

Step 1: Identify key elements for this criterion
Step 2: Evaluate quality (0-100)
Step 3: Provide specific reasoning

Output JSON: {score: X, reasoning: "..."}
```

**Example Specialist Outputs:**
```json
[
  {
    "agent": "Thesis & Motive",
    "score": 85,
    "reasoning": "Clear thesis but could be more arguable"
  },
  {
    "agent": "Evidence & Analysis", 
    "score": 78,
    "reasoning": "Good evidence use but analysis could be deeper"
  }
]
```

### Stage 4: Synthesis Agent (Unified Evaluation)
```
Reader Output + All Specialist Scores → Gemini Synthesis Agent → Final grade
```

**Purpose:** Combine specialist evaluations into coherent feedback

**Input:**
- Reader's structural analysis
- All specialist scores and reasoning
- Rubric weights for final calculation

**Synthesis Process:**
1. **Weighted Score Calculation:**
   ```javascript
   final_score = Σ (specialist_score × criterion_weight) / 100
   ```

2. **Feedback Generation:** Creates unified 3-4 paragraph feedback that:
   - Summarizes overall quality
   - Highlights strengths (based on high-scoring criteria)
   - Identifies improvement areas (based on low-scoring criteria)
   - Provides actionable next steps

**Output (JSON):**
```json
{
  "final_score": 82,
  "feedback": "This essay provides a solid analysis of Tesla's disruptive impact...",
  "confidence_score": 0.87,
  "reasoning_trace": "Weighted calculation: Thesis(85×25%) + Evidence(78×35%) + ..."
}
```

### Stage 5: Human-in-the-Loop (Professor Review)
```
AI Grade → Supabase (status='pending') → Professor Dashboard → Approval/Rejection
```

**Process Flow:**
1. AI results saved to `ai_grades` table with `status='pending'`
2. Professor receives notification (email/dashboard)
3. Professor reviews:
   - Student essay (left panel)
   - AI feedback (right panel)
   - Specialist breakdowns (expandable sections)
4. Professor actions:
   - **Approve** → Status becomes `'approved'`, student can view
   - **Edit & Approve** → Save professor edits, status `'approved'`
   - **Reject** → Status `'rejected'`, optionally trigger re-grade

**Why HITL Matters:**
- Prevents hallucinated grades from reaching students
- Allows professor to add contextual insights
- Maintains academic accountability
- Builds student trust through transparency

## Technical Implementation

### n8n Workflow Structure
```
1. Webhook Trigger (POST /grade-essay)
   ↓
2. Supabase: Get submission + rubric
   ↓
3. Gemini: Reader Agent
   ↓
4. Code: Split into N branches (based on rubric criteria)
   ├─ Gemini: Specialist Agent 1
   ├─ Gemini: Specialist Agent 2
   ├─ ...
   └─ Gemini: Specialist Agent N
   ↓
5. Merge (wait for all specialists)
   ↓
6. Gemini: Synthesis Agent
   ↓
7. Supabase: Save AI grade (status='pending')
   ↓
8. Webhook Response (grade_id)
```

### Error Handling
- **Gemini API failures**: Retry with exponential backoff
- **Invalid JSON output**: Parse errors trigger re-prompt
- **Timeout protection**: Each agent has 60-second limit
- **Fallback mechanism**: If synthesis fails, use weighted average of specialists

### Performance Optimization
- **Parallel processing**: All specialists run simultaneously
- **Context caching**: Rubric and few-shot examples reused across agents
- **Batch processing**: Multiple essays can be graded in parallel
- **Token efficiency**: Prompts optimized for Gemini's 1M context window

## Data Flow Example

### Input Data
```json
{
  "submission_id": "123e4567-e89b-12d3-a456-426614174000",
  "essay_text": "Tesla has revolutionized the automotive industry...",
  "rubric": {
    "criteria": [
      {"name": "Thesis", "weight": 25, "description": "..."},
      {"name": "Evidence", "weight": 35, "description": "..."}
    ],
    "few_shot_examples": [...]
  }
}
```

### Intermediate Data (After Reader)
```json
{
  "thesis_statement": "Tesla has revolutionized automotive industry...",
  "narrative_summary": "Essay analyzes Tesla's business model innovations...",
  "topic_adherence": true
}
```

### Intermediate Data (After Specialists)
```json
{
  "specialist_scores": [
    {"agent": "Thesis", "score": 85, "reasoning": "..."},
    {"agent": "Evidence", "score": 78, "reasoning": "..."}
  ]
}
```

### Final Data (After Synthesis)
```json
{
  "final_score": 81,
  "feedback": "This essay provides a solid analysis...",
  "specialist_breakdown": [...],
  "confidence_score": 0.87
}
```

## Advantages Over One-Shot Grading

### Problem with One-Shot LLM Grading
```
Essay → Single LLM Call → Grade + Feedback
```
- **Inconsistency:** Same essay gets different grades on multiple calls
- **Halo Effect:** Good grammar masks weak arguments
- **Black Box:** No reasoning trace for professor review
- **Hallucination Risk:** AI invents evidence or misinterprets

### Our Multi-Agent Solution
```
Essay → Reader → Specialists → Synthesis → Professor Review → Grade
```
- **Consistency:** Structured evaluation reduces variance
- **Transparency:** Each criterion evaluated separately
- **Accountability:** Professor reviews before student sees grade
- **Reliability:** Few-shot learning calibrates to professor's style

## Scaling Considerations

### Current Design Supports
- **Multiple courses:** Different rubrics per course
- **Multiple professors:** RLS isolates data by professor
- **Various assignment types:** Essays, reports, case studies
- **Batch processing:** Grade multiple essays simultaneously

### Future Enhancements
- **Adaptive learning:** System improves from professor feedback patterns
- **Cross-course analytics:** Identify common student weakness patterns
- **Integration with LMS:** Automatic grade posting to Canvas/Blackboard
- **Multilingual support:** Grade essays in different languages

## Monitoring & Analytics

### Key Metrics
- **Processing time:** Average 2-5 minutes per essay
- **Professor approval rate:** % of AI grades approved without edits
- **Student satisfaction:** Feedback quality ratings
- **Inter-rater reliability:** Comparison with manual grading

### Quality Assurance
- **Confidence scores:** AI indicates uncertainty levels
- **Flagging system:** Low confidence grades require professor review
- **Audit trail:** Complete reasoning trace for each grade
- **Feedback loops:** Professor corrections improve future accuracy

This workflow transforms AI grading from a black-box replacement into a transparent decision-support system that enhances rather than replaces human academic judgment.
