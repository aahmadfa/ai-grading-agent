# AI-Assisted Grading System - Progress Update Memo

**Project:** AI-Assisted Grading System for Higher Education  
**Period:** From Proposal Creation to Present  
**Date:** February 9, 2026  
**Status:** Design & Documentation Phase Complete, Implementation Phase Pending

---

## Executive Summary

Since creating `proposal.txt`, the project has progressed from concept to fully-designed system architecture. All foundational documentation, database schema, user stories, workflow designs, and literature reviews are complete. The system is validated by 20+ academic sources and ready for n8n workflow implementation.

---

## Completed Deliverables

### 1. Project Foundation

| File | Purpose | Status |
|------|---------|--------|
| `proposal.txt` | Original capstone proposal | ✅ Complete |
| `README.md` | Project overview, quick start, architecture summary | ✅ Complete |
| `.env` | Supabase credentials configured | ✅ Complete |

### 2. Database Infrastructure

| File | Contents | Status |
|------|----------|--------|
| `database/schema.sql` | PostgreSQL schema with 5 tables (rubrics, submissions, ai_grades, few_shot_examples, raw_uploads) + RLS policies | ✅ Complete |
| `database/seed_data.sql` | Sample rubric, few-shot examples, test submission, AI grade | ✅ Complete |

**Key Features:**
- Supabase PostgreSQL with Row Level Security (RLS)
- JSONB rubric storage for flexible criteria
- Multi-tenant data isolation by professor_email
- Audit trail support for grade tracking

### 3. User Requirements

| File | Contents | Status |
|------|----------|--------|
| `USER_STORIES.md` | 25+ user stories covering professors, students, AI system, and cross-cutting requirements | ✅ Complete |

**Story Categories:**
- **Professor Stories:** Upload rubrics, review AI grades, edit feedback, approve/reject
- **Student Stories:** Submit essays, view transparent feedback, compare to rubric
- **AI System Stories:** Multi-agent workflow (Reader → Specialists → Synthesis)
- **Security Stories:** Authentication, audit trails, data isolation

### 4. Workflow Documentation

| File | Contents | Status |
|------|----------|--------|
| `WORKFLOW.md` | Multi-agent grading workflow architecture | ✅ Complete |
| `INGESTION_WORKFLOW.md` | Unstructured data ingestion using Gemini Vision | ✅ Complete |

**Workflow Architecture:**
```
Submission → Reader Agent → Parallel Specialist Agents → Synthesis Agent → HITL Review → Final Grade
```

**Ingestion Pipeline:**
```
Professor Upload (PDF/Image/DOCX) → Gemini Vision Extraction → Structured JSON → Database
```

### 5. Academic Validation

| File | Contents | Status |
|------|----------|--------|
| `LITERATURE_REVIEW.md` | 20+ sources validating user stories, HITL, transparency, multi-agent AI | ✅ Complete |
| `LITERATURE_REVIEW_2.md` | Psychology of human grading & AI consistency research | ✅ Complete |

**Key Research Findings Validating the System:**

1. **Human Grading Psychology** (LITERATURE_REVIEW_2.md):
   - Humans have 0.60-0.80 ICC (inter-rater reliability)
   - Same-rater consistency drops to 0.50-0.70 over time
   - Cognitive biases: halo effect, leniency/severity bias, rater drift
   - Humans disagree with themselves 30-50% of the time

2. **AI Consistency** (LITERATURE_REVIEW_2.md):
   - One-shot LLM grading is inconsistent
   - GPT-4: 0.999 ICC same-day, 0.944 over 3 months
   - Temporal instability caused by API updates, hardware non-determinism
   - Solution: Multi-criteria scoring reduces variance 55-78%

3. **Transparency Effects** (LITERATURE_REVIEW.md):
   - Students with transparency rated AI accuracy 53% higher (0.90 vs 0.59)
   - Transparency increases trust and perceived fairness
   - Human-in-the-loop essential for accountability

4. **Multi-Agent Advantage** (LITERATURE_REVIEW.md):
   - "Agentic AI frameworks enable assessment to be broken down into interpretable stages"
   - Addresses all limitations of one-shot grading (inconsistency, hallucination, black-box)
   - Specialist-per-criterion evaluation matches human cognitive processes

---

## System Architecture Summary

### Data Flow

```
┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│ Professor       │────▶│  Ingestion   │────▶│  Database      │
│ (Rubric/Examples│     │  (Gemini)    │     │  (Supabase)    │
│  Upload)        │     └──────────────┘     └────────────────┘
└─────────────────┘

┌─────────────────┐     ┌──────────────┐     ┌────────────────┐
│ Student         │────▶│  Submission  │────▶│  Database      │
│ (Essay Submit)  │     └──────────────┘     └────────────────┘
└─────────────────┘                                  │
                                                     ▼
                              ┌─────────────────────────────────┐
                              │  Grading Workflow (n8n)         │
                              │  ┌──────────┐ ┌──────────────┐  │
                              │  │ Reader   │ │ Specialists  │  │
                              │  │ Agent    │ │ (Per Criterion│ │
                              │  └──────────┘ └──────────────┘  │
                              │         │              │        │
                              │         └──────┬───────┘        │
                              │                ▼                │
                              │         ┌──────────┐            │
                              │         │ Synthesis│            │
                              │         │ Agent    │            │
                              │         └──────────┘            │
                              └─────────────────────────────────┘
                                                     │
                                                     ▼
                              ┌─────────────────────────────────┐
                              │  Human-in-the-Loop              │
                              │  ┌──────────────────────────┐   │
                              │  │ Professor Review         │   │
                              │  │ - View AI reasoning      │   │
                              │  │ - Edit scores/feedback   │   │
                              │  │ - Approve or Reject      │   │
                              │  └──────────────────────────┘   │
                              └─────────────────────────────────┘
                                                     │
                                                     ▼
                              ┌─────────────────────────────────┐
                              │  Student Notification           │
                              │  ┌──────────────────────────┐   │
                              │  │ View Final Grade         │   │
                              │  │ See Rubric Alignment     │   │
                              │  │ Get Improvement Feedback │   │
                              │  └──────────────────────────┘   │
                              └─────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Database | Supabase PostgreSQL | Data persistence, RLS, multi-tenancy |
| Workflow Engine | n8n Cloud | Workflow orchestration, agent chaining |
| LLM | Google Gemini 3 Flash | Vision + text processing, large context |
| Frontend | (To be determined) | Professor/student interfaces |
| Authentication | Supabase Auth | Secure access control |

---

## Completed Tasks

### Phase 1: Foundation (Complete)
- [x] Document user stories and requirements
- [x] Create Supabase project and get connection details
- [x] Set up database schema with tables and RLS policies
- [x] Configure environment variables

### Phase 2: Data Architecture (Complete)
- [x] Create initial rubric data and few-shot examples
- [x] Document workflow architecture and logic
- [x] Build n8n data ingestion workflow documentation

### Phase 3: Research & Validation (Complete)
- [x] Research and validate user stories with academic literature
- [x] Research psychology of grading & AI consistency

---

## Pending Tasks

### Phase 4: Implementation (Pending)
- [ ] Build n8n grading workflow (Reader → Specialists → Synthesis)
- [ ] Implement n8n ingestion workflow (Gemini Vision extraction)
- [ ] Create professor dashboard for grade review
- [ ] Create student interface for submission/feedback
- [ ] Testing and validation

---

## Key Design Decisions

### 1. Multi-Agent Architecture
**Decision:** Use Reader → Specialist → Synthesis agents instead of one-shot grading  
**Rationale:** 
- Research shows multi-criteria scoring reduces variance 55-78%
- Addresses LLM temporal instability (0.944 ICC over 3 months)
- Prevents "Halo Effect" by isolating criterion evaluation
- Provides transparent reasoning trace for professor review

### 2. Human-in-the-Loop (HITL)
**Decision:** Require professor approval for all AI grades  
**Rationale:**
- Literature: "Verification and reflection must be routine elements, not exceptional safeguards"
- False positives (AI saying wrong work is correct) harm learning more than false negatives
- Addresses both human inconsistency (professor catches AI errors) and AI variance (approval locks grade)

### 3. JSONB Rubric Storage
**Decision:** Store rubrics as JSONB with weighted criteria  
**Rationale:**
- Flexibility for different assignment types
- Supports dynamic criteria without schema changes
- Enables few-shot learning from professor examples

### 4. Unstructured Data Ingestion
**Decision:** Use Gemini Vision to extract rubrics from PDFs, images, documents  
**Rationale:**
- Professors don't write structured JSON; they write documents
- Vision capabilities handle tables, formatting, handwriting
- Reduces friction for professor adoption

### 5. Row Level Security (RLS)
**Decision:** Implement RLS policies for all tables  
**Rationale:**
- Secure multi-tenant data isolation
- Professor can only see their own rubrics/students
- Prevents data leakage between users

---

## Research Contributions

This project addresses a documented gap in the literature:

> "Notable gap in studies examining fully integrated agentic assessment pipelines within real educational contexts" (Wu et al., 2023)

**Contributions:**
1. First fully integrated agentic assessment pipeline study
2. Addresses HITL workflow effectiveness in AI grading
3. Validates multi-criteria approach for LLM consistency
4. Provides transparency mechanisms proven to increase student trust

---

## Risk Mitigation

| Risk | Mitigation Strategy |
|------|---------------------|
| AI inconsistency | Multi-criteria evaluation + professor review |
| Human bias | Rubric-based criteria + AI-generated detailed feedback |
| Temporal drift | Professor approval locks final grades |
| Data security | Supabase RLS + service role key isolation |
| Professor adoption | Unstructured data ingestion reduces setup friction |

---

## Next Steps

### Immediate (This Week)
1. Build n8n grading workflow implementing Reader → Specialists → Synthesis
2. Create test suite with sample submissions
3. Validate AI consistency with multi-criteria approach

### Short-term (Next 2 Weeks)
1. Implement professor review interface
2. Implement student submission/feedback interface
3. End-to-end testing with seed data

### Medium-term (Next Month)
1. Pilot testing with real essays
2. Professor onboarding and training
3. Measure grading efficiency gains

---

## Metrics for Success

| Metric | Target | Measurement Method |
|--------|--------|---------------------|
| Grading time reduction | 60-80% | Compare manual vs AI+HITL time |
| AI-human agreement | >0.90 ICC | Correlation with professor grades |
| Professor satisfaction | >4.0/5.0 | Post-use survey |
| Student trust | >80% | Transparency acceptance survey |
| System consistency | >0.95 ICC | Same-essay, multi-run testing |

---

## Files Delivered

```
/Users/ahmadsully/Desktop/AI Assisted Grading App/
├── proposal.txt                    # Original capstone proposal
├── README.md                       # Project overview & quick start
├── LITERATURE_REVIEW.md            # Academic validation (20+ sources)
├── LITERATURE_REVIEW_2.md          # Psychology & consistency research
├── USER_STORIES.md                 # Comprehensive requirements
├── WORKFLOW.md                     # Multi-agent grading architecture
├── INGESTION_WORKFLOW.md           # Unstructured data pipeline
├── PROGRESS_MEMO.md                # This document
├── .env                            # Supabase credentials
└── database/
    ├── schema.sql                  # PostgreSQL schema + RLS
    └── seed_data.sql               # Sample data for testing
```

---

## Conclusion

The project has successfully transitioned from concept to fully-documented, research-validated system design. All foundational elements are in place:

- ✅ Database schema with security policies
- ✅ User stories covering all stakeholders
- ✅ Multi-agent workflow architecture
- ✅ Unstructured data ingestion pipeline
- ✅ Academic literature validation (20+ sources)
- ✅ Psychology of grading & AI consistency research

The system is **ready for implementation**. The n8n workflows (grading and ingestion) are the next critical deliverables to bring the system to life.

**Status:** Ready to build.

---

*Memo compiled: February 9, 2026*  
*Project phase: Design Complete → Implementation Pending*
