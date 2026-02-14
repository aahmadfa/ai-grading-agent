-- Seed data for AI-Assisted Grading System
-- Sample rubric based on Vatanasakdakul (2026) rubric from proposal

-- Insert sample rubric
INSERT INTO rubrics (
  course_name,
  professor_email,
  assignment_title,
  assignment_prompt,
  criteria,
  few_shot_examples
) VALUES (
  'Information Systems Capstone',
  'professor@university.edu',
  'Case Study Analysis Report',
  'Analyze a real-world case study using theoretical frameworks from the course. Provide critical analysis and evidence-based recommendations.',
  '[
    {
      "name": "Selection of case study and literature analysis",
      "weight": 25,
      "description": "Quality of case study selection and depth of literature review"
    },
    {
      "name": "Critical analysis and quality of report",
      "weight": 35,
      "description": "Depth of critical thinking, data analysis, and solution quality"
    },
    {
      "name": "Theory integration",
      "weight": 25,
      "description": "Application of theoretical frameworks and academic rigor"
    },
    {
      "name": "Professional presentation",
      "weight": 15,
      "description": "Formatting, grammar, spelling, and academic writing quality"
    }
  ]',
  '[
    {
      "essay": "This case study examines Netflixs transition from DVD rental to streaming services. The company faced significant challenges in content licensing and technology infrastructure. Netflix implemented a phased approach, first maintaining DVD services while building streaming capabilities, then gradually shifting focus. The analysis shows that this strategy allowed Netflix to maintain revenue while investing in future growth. However, the company struggled with content costs and international expansion...",
      "feedback": "Good selection of Netflix case study with clear understanding of the business transformation. Literature review covers key sources but could be more comprehensive. Analysis shows solid understanding of strategic decisions but lacks deeper theoretical framework application. Recommendations are practical but not sufficiently grounded in academic literature.",
      "score": 78,
      "breakdown": {
        "Selection of case study and literature analysis": 75,
        "Critical analysis and quality of report": 80,
        "Theory integration": 70,
        "Professional presentation": 85
      }
    },
    {
      "essay": "Amazon Web Services represents one of the most successful cloud computing platforms in the market. This analysis examines AWSs market dominance through the lens of disruptive innovation theory. The company leveraged its existing infrastructure to create a scalable platform that transformed enterprise computing. AWSs pay-as-you-go model democratized access to computing resources, enabling startups to compete with established players. The platform ecosystem created network effects that strengthened market position...",
      "feedback": "Excellent case study selection with sophisticated application of disruptive innovation theory. Literature review is comprehensive and well-integrated. Critical analysis demonstrates deep understanding of both technical and business aspects. Recommendations are insightful and grounded in solid research. Writing is professional and well-structured.",
      "score": 92,
      "breakdown": {
        "Selection of case study and literature analysis": 90,
        "Critical analysis and quality of report": 95,
        "Theory integration": 90,
        "Professional presentation": 93
      }
    }
  ]'
);

-- Insert sample submission for testing
INSERT INTO submissions (
  rubric_id,
  student_name,
  student_email,
  essay_text
) VALUES (
  (SELECT id FROM rubrics LIMIT 1),
  'Test Student',
  'student@university.edu',
  'This analysis examines Tesla''s approach to electric vehicle manufacturing and market disruption. The company has revolutionized the automotive industry through vertical integration, direct-to-consumer sales, and continuous innovation in battery technology. Tesla''s strategy challenges traditional automotive business models and demonstrates how technology companies can enter established markets. The case study explores Tesla''s supply chain innovations, manufacturing processes, and market expansion strategies...'
);

-- Insert sample AI grade for testing
INSERT INTO ai_grades (
  submission_id,
  reader_output,
  specialist_scores,
  synthesis_feedback,
  final_score,
  status
) VALUES (
  (SELECT id FROM submissions LIMIT 1),
  '{
    "thesis_statement": "Tesla has revolutionized the automotive industry through vertical integration and direct-to-consumer sales models",
    "narrative_summary": "The essay analyzes Tesla''s business model innovations, manufacturing processes, and market impact, positioning the company as a technology disruptor in traditional automotive markets",
    "topic_adherence": true
  }',
  '[
    {
      "agent": "Selection of case study and literature analysis",
      "score": 85,
      "reasoning": "Tesla is an excellent case study for disruption theory. Literature review could be more comprehensive but covers key sources."
    },
    {
      "agent": "Critical analysis and quality of report", 
      "score": 82,
      "reasoning": "Good analysis of Tesla''s business model but lacks deeper examination of financial challenges and competitive responses."
    },
    {
      "agent": "Theory integration",
      "score": 78,
      "reasoning": "Applies disruption theory appropriately but could integrate additional theoretical frameworks for richer analysis."
    },
    {
      "agent": "Professional presentation",
      "score": 88,
      "reasoning": "Well-structured essay with clear arguments. Minor grammatical issues but overall professional quality."
    }
  ]',
  'This essay provides a solid analysis of Tesla''s disruptive impact on the automotive industry. The thesis is clear and well-supported with evidence from Tesla''s business practices. The analysis demonstrates good understanding of disruption theory and its application to Tesla''s market entry. However, the essay could benefit from a more comprehensive literature review and deeper examination of the challenges Tesla faces, including production issues and increasing competition. The writing is professional and well-organized, making complex concepts accessible. Overall, this is a strong analysis that effectively connects theory to practice.',
  83,
  'pending'
);
