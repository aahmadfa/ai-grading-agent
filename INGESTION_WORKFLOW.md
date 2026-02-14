# Data Ingestion Workflow

## Overview
Automated pipeline that transforms unstructured professor inputs (PDFs, images, documents) into structured database records using Gemini 3 Flash's vision and document understanding capabilities.

## Supported Input Formats

- **PDFs** - Syllabus, rubrics, assignment prompts
- **Images** - PNG/JPG screenshots of Canvas rubrics, handwritten notes
- **Documents** - DOCX files with grading feedback
- **Text** - Direct text input for quick editing

## Workflow Architecture

```
Professor Uploads File
         ↓
Supabase Storage (raw file)
         ↓
Webhook Trigger to n8n
         ↓
Gemini 3 Flash Vision Agent
         ↓
Extracted Structured Data
         ↓
Save to rubrics/few_shot_examples tables
```

## Stage 1: File Upload

**Process:**
1. Professor uploads file via web interface
2. File stored in **Supabase Storage** (secure blob storage)
3. URL saved to `raw_uploads` table with `processed=false`
4. Webhook triggers n8n ingestion workflow

**Database Record:**
```json
{
  "id": "uuid",
  "professor_email": "prof@uni.edu",
  "upload_type": "rubric", // or "few_shot_example"
  "file_url": "https://.../rubric.pdf",
  "file_name": "IS_Capstone_Rubric_2025.pdf",
  "file_type": "pdf",
  "extracted_text": null,
  "processed": false
}
```

## Stage 2: Gemini Vision Extraction

**Gemini 3 Flash Capabilities Used:**
- **Vision understanding** - Reads images, PDFs, documents
- **Structured output** - Returns JSON with extraction schema
- **Large context window** - Can process multi-page documents

**Extraction Prompts:**

### Rubric Extraction
```
You are a data extraction specialist. Analyze this document and extract the grading rubric.

Document: {{file_url or file_content}}

Extract and return JSON:
{
  "course_name": "extracted course name",
  "assignment_title": "assignment name",
  "assignment_prompt": "assignment description/prompt",
  "criteria": [
    {
      "name": "criterion name",
      "weight": percentage_number,
      "description": "what this criterion evaluates"
    }
  ]
}

Guidelines:
- Extract all rubric criteria and their weights
- Weights should sum to 100
- If weights not explicit, infer from grading scale (A=95, B=85, etc.)
- Include assignment prompt if present in document
```

### Few-Shot Example Extraction
```
You are analyzing graded student work. Extract the essay content, feedback, and scores.

Document: {{file_url or file_content}}

Extract and return JSON:
{
  "essay": "full student essay text",
  "feedback": "professor's written feedback",
  "score": overall_number_score,
  "breakdown": {
    "criterion_name_1": score_1,
    "criterion_name_2": score_2
  }
}

Guidelines:
- Extract full essay text (preserve formatting)
- Capture all professor comments/feedback
- Extract individual criterion scores from rubric table
- Calculate overall score if not explicitly stated
- If rubric scores are letter grades, convert to numbers (A=95, B=85, C=75, D=65, F=55)
```

## Stage 3: Data Validation & Storage

**Validation Steps:**
1. Check JSON structure matches expected schema
2. Verify criteria weights sum to 100
3. Ensure essay text is complete (not truncated)
4. Validate score ranges (0-100)

**Error Handling:**
- If extraction fails → Mark as `processed=false`, log error
- If validation fails → Flag for manual review
- If successful → Insert into `rubrics` or use for `few_shot_examples`

## Stage 4: Professor Review (Optional)

**Before committing to database:**
1. Show extracted data to professor for verification
2. Allow editing of extracted fields
3. Professor confirms → Save to database
4. Professor rejects → Re-run extraction or manual entry

## n8n Workflow Structure

```
1. Webhook Trigger (file uploaded)
   ↓
2. Supabase: Get file URL from raw_uploads
   ↓
3. Gemini Vision Agent (extraction)
   Input: {{file_url}}
   Output: Structured JSON
   ↓
4. Code: Validate JSON structure
   ↓
5. If valid:
      Supabase: Insert into rubrics table
      Supabase: Update raw_uploads.processed = true
      Supabase: Store extracted_text
   If invalid:
      Supabase: Flag for review
   ↓
6. Webhook Response (success/failure)
```

## Technical Implementation

### Supabase Storage Setup
1. Create **Storage Bucket** called `professor-uploads`
2. Set RLS policies:
   - Professors can upload to their folder
   - System can read for processing
3. Configure CORS for n8n access

### Gemini API Configuration
**Model:** `gemini-3-flash`
**Features enabled:**
- Vision (for images/PDFs)
- Document understanding (for PDFs)
- JSON output mode

**Rate Limits:**
- ~60 requests per minute (sufficient for batch uploads)
- Each request can handle up to 1M tokens (entire documents)

### Prompt Optimization

**For PDFs with Multiple Pages:**
```
This is a multi-page PDF. Process all pages and combine the information.
If pages contain different sections, maintain the structure in your output.
```

**For Low-Quality Images:**
```
The image quality may be low (screenshot of screen). 
Do your best to extract text. If unclear, indicate uncertainty.
```

**For Handwritten Notes:**
```
This document contains handwritten annotations. 
Transcribe legible handwriting. Ignore illegible sections.
```

## Data Flow Examples

### Example 1: Canvas Rubric Screenshot (PNG)

**Input:** Professor uploads screenshot of Canvas rubric

**Gemini Extraction:**
```json
{
  "course_name": "IS Capstone",
  "assignment_title": "Case Study Analysis",
  "criteria": [
    {
      "name": "Case Study Selection & Literature",
      "weight": 25,
      "description": "Quality of case study and depth of literature analysis"
    },
    {
      "name": "Critical Analysis",
      "weight": 35,
      "description": "Depth of critical thinking and solution quality"
    },
    {
      "name": "Theory Integration",
      "weight": 25,
      "description": "Application of theoretical frameworks"
    },
    {
      "name": "Professional Presentation",
      "weight": 15,
      "description": "Formatting, grammar, spelling"
    }
  ]
}
```

**Database Result:** New rubric record with extracted criteria

### Example 2: Graded Essay with PDF Feedback

**Input:** PDF containing student essay + professor comments

**Gemini Extraction:**
```json
{
  "essay": "Tesla's disruption of the automotive industry began with...",
  "feedback": "Good analysis of Tesla's strategy. However, you could strengthen the discussion of competitive responses. Consider adding more recent data on market share.",
  "score": 82,
  "breakdown": {
    "Case Study Selection & Literature": 85,
    "Critical Analysis": 80,
    "Theory Integration": 82,
    "Professional Presentation": 83
  }
}
```

**Database Result:** Added to rubric's `few_shot_examples` array

## Advantages

1. **Professor-Friendly** - No manual data entry required
2. **Flexible** - Handles any file format Gemini can process
3. **Scalable** - Batch process multiple files
4. **Accurate** - Gemini 3 Flash has excellent document understanding
5. **Reviewable** - Professor can verify extracted data before use

## Limitations

1. **Not 100% accurate** - May misread poor quality images
2. **Requires review** - Professor should verify extracted data
3. **Rate limits** - Large batches may need throttling
4. **Cost** - Each extraction costs API tokens

## Integration with Grading Workflow

**Two-Stage Process:**

**Stage 1: Ingestion (One-time setup)**
- Professor uploads course materials
- AI extracts and structures the data
- Professor reviews and approves
- Data stored in `rubrics` table

**Stage 2: Grading (Ongoing)**
- Student submits essay
- AI grades using structured rubric
- Professor reviews AI grades
- Feedback sent to student

**Benefit:** Professor only needs to upload materials once per course, then the system works automatically.

## Next Steps

1. Create Supabase Storage bucket for file uploads
2. Build web interface for professor uploads
3. Create n8n ingestion workflow
4. Test with sample PDFs/images
5. Add professor review interface before committing data

**Ready to build this ingestion workflow in n8n?**
