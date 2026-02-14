-- AI-Assisted Grading Database Schema
-- For Supabase PostgreSQL

-- Rubrics table - stores grading criteria and few-shot examples
CREATE TABLE rubrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_name TEXT NOT NULL,
  professor_email TEXT NOT NULL,
  assignment_title TEXT NOT NULL,
  assignment_prompt TEXT,
  criteria JSONB NOT NULL, -- Array of rubric criteria with weights
  few_shot_examples JSONB, -- Array of past graded essays for few-shot learning
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Submissions table - student essay submissions
CREATE TABLE submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rubric_id UUID REFERENCES rubrics(id) ON DELETE CASCADE,
  student_name TEXT NOT NULL,
  student_email TEXT NOT NULL,
  essay_text TEXT NOT NULL,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Grades table - stores AI-generated grades pending professor review
CREATE TABLE ai_grades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id UUID REFERENCES submissions(id) ON DELETE CASCADE,
  reader_output JSONB, -- Reader agent analysis: thesis, narrative_summary, topic_adherence
  specialist_scores JSONB, -- Array of specialist agent evaluations
  synthesis_feedback TEXT, -- Synthesis agent's unified feedback
  final_score INTEGER, -- Overall score (0-100)
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'regenerating')),
  professor_edits TEXT, -- Professor's modified feedback (if any)
  professor_final_score INTEGER, -- Professor's overridden score (if any)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by TEXT -- Professor email who reviewed
);

-- Raw uploads table for unstructured professor data (PDFs, images, docs)
CREATE TABLE raw_uploads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  professor_email TEXT NOT NULL,
  upload_type TEXT NOT NULL CHECK (upload_type IN ('rubric', 'few_shot_example')),
  file_url TEXT, -- Supabase storage URL
  file_name TEXT,
  file_type TEXT, -- 'pdf', 'png', 'jpg', 'docx'
  extracted_text TEXT, -- Raw OCR/extracted text
  processed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS for raw_uploads
ALTER TABLE raw_uploads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Professors can view their own uploads" ON raw_uploads
  FOR SELECT USING (auth.email() = professor_email);

CREATE POLICY "Professors can insert their own uploads" ON raw_uploads
  FOR INSERT WITH CHECK (auth.email() = professor_email);

-- Indexes
CREATE INDEX idx_submissions_rubric_id ON submissions(rubric_id);
CREATE INDEX idx_ai_grades_submission_id ON ai_grades(submission_id);
CREATE INDEX idx_ai_grades_status ON ai_grades(status);
CREATE INDEX idx_rubrics_professor_email ON rubrics(professor_email);

-- Enable Row Level Security
ALTER TABLE rubrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_grades ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Professors can only access their own rubrics
CREATE POLICY "Professors can view their own rubrics" ON rubrics
  FOR SELECT USING (auth.email() = professor_email);

CREATE POLICY "Professors can insert their own rubrics" ON rubrics
  FOR INSERT WITH CHECK (auth.email() = professor_email);

CREATE POLICY "Professors can update their own rubrics" ON rubrics
  FOR UPDATE USING (auth.email() = professor_email);

-- Professors can access submissions for their rubrics
CREATE POLICY "Professors can view submissions for their rubrics" ON submissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM rubrics 
      WHERE rubrics.id = submissions.rubric_id 
      AND rubrics.professor_email = auth.email()
    )
  );

-- Students can only view their own submissions
CREATE POLICY "Students can view their own submissions" ON submissions
  FOR SELECT USING (auth.email() = student_email);

CREATE POLICY "Students can insert their own submissions" ON submissions
  FOR INSERT WITH CHECK (auth.email() = student_email);

-- Professors can view AI grades for their rubrics
CREATE POLICY "Professors can view grades for their rubrics" ON ai_grades
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM submissions s
      JOIN rubrics r ON s.rubric_id = r.id
      WHERE s.id = ai_grades.submission_id 
      AND r.professor_email = auth.email()
    )
  );

CREATE POLICY "Professors can update grades for their rubrics" ON ai_grades
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM submissions s
      JOIN rubrics r ON s.rubric_id = r.id
      WHERE s.id = ai_grades.submission_id 
      AND r.professor_email = auth.email()
    )
  );

-- Students can view approved grades for their submissions
CREATE POLICY "Students can view approved grades" ON ai_grades
  FOR SELECT USING (
    status = 'approved' AND 
    EXISTS (
      SELECT 1 FROM submissions 
      WHERE submissions.id = ai_grades.submission_id 
      AND submissions.student_email = auth.email()
    )
  );

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_rubrics_updated_at 
  BEFORE UPDATE ON rubrics 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
