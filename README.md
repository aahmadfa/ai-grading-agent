# AI-Assisted Grading System

## Overview
Multi-agent AI system for automated grading of subjective educational assignments using Google Gemini 3 Flash and n8n workflow orchestration.

## Architecture
- **n8n**: Workflow orchestration for AI agents
- **Google Gemini 3 Flash**: LLM with 1M+ token context window
- **Supabase**: PostgreSQL database for HITL persistence
- **Next.js**: Frontend for professor/student interfaces

## Quick Start

### 1. Set up Supabase
1. Create account at [supabase.com](https://supabase.com)
2. Create new project
3. Run the SQL schema from `database/schema.sql`
4. Run seed data from `database/seed_data.sql` (optional)
5. Note your:
   - Project URL
   - Anon key
   - Service role key

### 2. Configure n8n
1. Add Supabase credentials to your n8n workspace
2. Add Google Gemini API key to n8n credentials
3. Import the grading workflow (see `n8n-workflows/`)

### 3. Environment Variables
```bash
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
GEMINI_API_KEY=your_gemini_api_key
N8N_WEBHOOK_URL=your_n8n_webhook_url
```

## Database Schema

### Tables
- **rubrics**: Course rubrics with criteria and few-shot examples
- **submissions**: Student essay submissions  
- **ai_grades**: AI-generated grades pending professor review

### Key Features
- Row Level Security (RLS) for data privacy
- JSONB columns for flexible rubric criteria and AI outputs
- Status tracking for HITL workflow

## AI Agent Workflow

1. **Reader Agent**: Extracts thesis and narrative structure
2. **Specialist Agents**: Parallel evaluation of rubric criteria
3. **Synthesis Agent**: Combines evaluations into unified feedback
4. **Human-in-the-Loop**: Professor reviews and approves grades

## Project Structure
```
├── database/
│   ├── schema.sql      # Database schema
│   └── seed_data.sql   # Sample data
├── n8n-workflows/
│   └── grade-essay.json # Main grading workflow
├── prompts/
│   ├── reader-agent.txt
│   ├── specialist-agent.txt
│   └── synthesis-agent.txt
├── src/
│   ├── app/            # Next.js pages
│   ├── components/     # React components
│   └── lib/           # Supabase client
└── README.md
```

## Development Workflow

1. **Professor**: Upload rubric + few-shot examples via web interface
2. **Student**: Submit essay via web form
3. **n8n Workflow**: Triggers automatically, runs AI agents
4. **Professor**: Reviews AI grades, edits/approves via dashboard
5. **Student**: Receives final approved feedback

## Security & Privacy
- Professors only see their own course data
- Students only see their own submissions and approved grades
- All AI grades require explicit professor approval before student access
- Row Level Security enforced at database level

## Next Steps
- [ ] Set up Supabase project
- [ ] Configure n8n workflow
- [ ] Build professor review interface
- [ ] Add student submission portal
- [ ] Test with real course data
