# User Stories - AI-Assisted Grading System

**FEEDBACK**
* Add the scale slider for grading (strictness)


## Actors

1. **Professor** - Course instructor who creates rubrics, reviews AI grades, and provides final approval
2. **Student** - Learner who submits assignments and receives graded feedback
3. **AI System** - Multi-agent workflow that automates grading based on professor-defined rubrics

---

## Professor User Stories

### Rubric Management

**US-P1: Upload Rubric Document**
> As a professor, I want to upload my existing rubric document (PDF, image, or DOCX) so that the system can automatically extract and structure the grading criteria.

**Acceptance Criteria:**
- Can upload PDF, PNG, JPG, or DOCX files
- System extracts criteria names, descriptions, and weights
- Professor can review and edit extracted data before saving
- Extracted rubric is stored for future use

---

**US-P2: Define Rubric Criteria Manually**
> As a professor, I want to manually create or edit rubric criteria so that I have full control over the grading standards.

**Acceptance Criteria:**
- Can add/edit/delete criteria
- Can set weights for each criterion (sum must equal 100%)
- Can add detailed descriptions for each criterion
- Can preview the rubric before saving

---

**US-P3: Upload Few-Shot Examples**
> As a professor, I want to upload previously graded student essays with my feedback and scores so that the AI can learn my grading style.

**Acceptance Criteria:**
- Can upload essay files with associated grading data
- Can extract scores from rubric tables or enter manually
- System stores few-shot examples linked to rubric
- Can add multiple examples for better calibration

---

### Assignment Management

**US-P4: Create Assignment**
> As a professor, I want to create a new assignment linked to a specific rubric so that students know what criteria their work will be evaluated on.

**Acceptance Criteria:**
- Can select from existing rubrics
- Can set assignment title, description, and due date
- Can configure submission settings (file types, word limits)
- Assignment appears in student dashboard

---

**US-P5: View Pending AI Grades**
> As a professor, I want to see all AI-generated grades awaiting my review so that I can efficiently process student submissions.

**Acceptance Criteria:**
- Dashboard shows pending grades count
- Can sort/filter by date, student, or course
- Shows confidence scores for each grade
- Can batch-select multiple submissions for review

---

### Grade Review & Approval

**US-P6: Review AI-Generated Grade**
> As a professor, I want to view the AI's grading decision alongside the student essay so that I can evaluate the AI's accuracy.

**Acceptance Criteria:**
- Side-by-side view: essay (left) + AI feedback (right)
- Shows breakdown by each rubric criterion
- Displays AI's reasoning for each score
- Shows overall score and confidence level

---

**US-P7: Edit AI Feedback**
> As a professor, I want to modify the AI-generated feedback before sending it to the student so that I can add my expertise and correct any errors.

**Acceptance Criteria:**
- Can edit any part of the AI feedback
- Can adjust individual criterion scores
- Can add personal comments
- Changes are tracked and visible

---

**US-P8: Approve Grade**
> As a professor, I want to approve the AI-generated grade so that the student can receive their feedback.

**Acceptance Criteria:**
- One-click approval if no edits needed
- Approval triggers notification to student
- Grade becomes visible to student immediately
- Approval is logged with timestamp

---

**US-P9: Reject and Request Re-grading**
> As a professor, I want to reject an AI grade and request the system to re-grade with different parameters so that I can improve accuracy for edge cases.

**Acceptance Criteria:**
- Can add notes explaining why grade was rejected
- Can trigger re-grading with adjusted prompts
- System learns from rejections to improve future grades
- Original grade is archived for comparison

---

### Analytics & Reporting

**US-P10: View Grading Analytics**
> As a professor, I want to see statistics on my course's grading patterns so that I can understand student performance trends.

**Acceptance Criteria:**
- Shows average scores by criterion
- Displays grade distribution histogram
- Shows AI vs Professor agreement rates
- Tracks time saved vs manual grading

---

**US-P11: Export Grades**
> As a professor, I want to export grades in CSV or LMS-compatible format so that I can import into my institution's gradebook.

**Acceptance Criteria:**
- Can export by assignment or course
- CSV includes all rubric breakdowns
- Canvas/Blackboard import formats supported
- One-click export from dashboard

---

## Student User Stories

### Submission

**US-S1: Submit Essay**
> As a student, I want to submit my essay assignment so that I can receive graded feedback.

**Acceptance Criteria:**
- Can upload DOCX, PDF, or paste text
- Shows word count and submission requirements
- Receives confirmation of successful submission
- Can view submission status (pending review)

---

**US-S2: View Submission History**
> As a student, I want to see all my past submissions and their grades so that I can track my progress.

**Acceptance Criteria:**
- Dashboard shows all assignments by course
- Shows submission date and current status
- Links to view graded feedback when approved
- Shows overall course grade trend

---

### Receiving Feedback

**US-S3: View Graded Feedback**
> As a student, I want to receive detailed, rubric-aligned feedback on my essay so that I understand my strengths and areas for improvement.

**Acceptance Criteria:**
- Shows overall score and grade
- Displays breakdown by each rubric criterion
- Shows specific feedback for each criterion
- Includes actionable improvement suggestions
- Feedback is available immediately after professor approval

---

**US-S4: Compare to Rubric**
> As a student, I want to see how my essay was evaluated against the rubric criteria so that I understand the grading standards.

**Acceptance Criteria:**
- Shows rubric criteria alongside my scores
- Highlights areas where I met/exceeded expectations
- Identifies specific weaknesses
- Links to examples of excellent work (anonymized)

---

**US-S5: Request Clarification**
> As a student, I want to ask questions about my grade so that I can understand the feedback better.

**Acceptance Criteria:**
- Can submit questions about specific feedback points
- Professor receives notification
- Response is attached to the grade record
- Conversation history is preserved

---

## System (AI) User Stories

### Data Ingestion

**US-AI1: Extract Rubric from Document**
> As the AI system, I want to parse uploaded documents (PDFs, images, DOCX) to extract structured rubric criteria so that I can use them for grading.

**Acceptance Criteria:**
- Handles PDF, PNG, JPG, DOCX formats
- Extracts criteria names, descriptions, and weights
- Validates that weights sum to 100%
- Returns structured JSON
- Flags uncertain extractions for professor review

---

**US-AI2: Extract Few-Shot Examples**
> As the AI system, I want to parse graded student work to extract essay text, scores, and feedback so that I can learn the professor's grading style.

**Acceptance Criteria:**
- Extracts essay text with formatting preserved
- Identifies scores from rubric tables
- Captures professor's written feedback
- Links extracted data to rubric criteria
- Handles both structured (table) and unstructured (comments) data

---

### Grading Process

**US-AI3: Perform Reader Analysis**
> As the AI system, I want to analyze a student essay to extract the thesis and narrative structure so that I can provide context to specialist agents.

**Acceptance Criteria:**
- Identifies thesis statement
- Summarizes narrative flow
- Checks topic adherence
- Outputs structured JSON
- Completes in <30 seconds

---

**US-AI4: Evaluate by Criterion**
> As the AI system, I want to evaluate a student essay against a specific rubric criterion so that I can provide granular, objective scoring.

**Acceptance Criteria:**
- Evaluates one criterion at a time
- Provides score (0-100) and detailed reasoning
- References specific evidence from essay
- Uses few-shot examples for calibration
- Completes in <60 seconds per criterion

---

**US-AI5: Synthesize Final Grade**
> As the AI system, I want to combine all specialist evaluations into a unified grade and feedback so that the professor receives a complete assessment.

**Acceptance Criteria:**
- Calculates weighted final score
- Generates coherent multi-paragraph feedback
- Identifies key strengths and weaknesses
- Provides actionable next steps
- Assigns confidence score
- Completes in <30 seconds

---

**US-AI6: Store Results for Review**
> As the AI system, I want to save the grading results with "pending" status so that the professor can review before students see the grade.

**Acceptance Criteria:**
- Saves complete reasoning trace
- Stores all specialist scores
- Sets status to "pending"
- Triggers notification to professor
- Preserves data for audit trail

---

### Learning & Improvement

**US-AI7: Learn from Professor Corrections**
> As the AI system, I want to analyze patterns in professor-approved vs rejected grades so that I can improve future grading accuracy.

**Acceptance Criteria:**
- Tracks professor edit patterns
- Identifies criteria where AI struggles
- Adjusts prompts based on feedback
- Reports accuracy improvements over time
- Suggests calibration needs to professor

---

## Cross-Cutting Requirements

### Security & Privacy

**US-SEC1: Data Isolation**
> As a user, I want my course data to be isolated from other professors so that my intellectual property and student information remain private.

**Acceptance Criteria:**
- RLS policies enforce data isolation by professor
- Students can only see their own data
- Rubrics are not shared between professors without consent
- Audit logs track all data access

---

**US-SEC2: Audit Trail**
> As a professor, I want a complete history of all grading decisions so that I can demonstrate fairness in case of grade disputes.

**Acceptance Criteria:**
- Logs AI-generated scores and reasoning
- Records professor edits and approvals
- Preserves timestamps for all actions
- Exportable audit reports

---

### Performance & Reliability

**US-PERF1: Fast Grading**
> As a professor, I want essays to be graded within 5 minutes so that I don't have to wait long for AI results.

**Acceptance Criteria:**
- 95% of essays graded in <5 minutes
- Parallel processing for multiple submissions
- Graceful handling of API rate limits
- Progress indicator for long essays

---

**US-PERF2: High Availability**
> As a user, I want the system to be available 99% of the time so that I can access grades when needed.

**Acceptance Criteria:**
- <1% downtime during semester
- Automatic retries for failed API calls
- Data persistence prevents loss during outages
- Status page for system health

---

## Prioritization

### Must Have (MVP)
- US-P1, US-P2: Rubric upload/creation
- US-P3: Few-shot examples
- US-P6, US-P7, US-P8: Review, edit, approve grades
- US-S1: Submit essay
- US-S3: View graded feedback
- US-AI3, US-AI4, US-AI5: Reader, Specialist, Synthesis agents
- US-AI6: Store pending grades

### Should Have (Phase 2)
- US-P4: Create assignments
- US-P5: View pending grades dashboard
- US-P10: Analytics
- US-S2, US-S4: Submission history, rubric comparison
- US-AI1, US-AI2: Document ingestion (can use manual entry for MVP)

### Nice to Have (Phase 3)
- US-P9: Reject and re-grade
- US-P11: Export grades
- US-S5: Request clarification
- US-AI7: Learning from corrections
- US-SEC2: Audit trail (logging is built-in)

## Acceptance Criteria Format

Each user story follows the format:
- **Given** [context]
- **When** [action]
- **Then** [expected outcome]

Example:
```
US-P6: Review AI-Generated Grade
Given: I am a professor with pending AI grades
When: I click on a pending submission
Then: I see the student essay and AI's grading breakdown side-by-side
```
