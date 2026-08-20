# Agentic AI: 7-Day Learning Sprint — Insurance Client Assistant

## What this is
A self-directed, week-long deep dive into agentic AI — from core concepts to a
working agent — built using Google Gemini's free-tier API. No framework used;
built from raw API calls to understand the underlying mechanics before
relying on abstractions.

## What the final agent does
`agent.py` is an insurance-client assistant agent that combines four core
agentic AI capabilities into one system:

- **Tool use** — can call a calculator and a client-lookup function, deciding
  on its own which tool(s) a question requires and in what order.
- **RAG (Retrieval-Augmented Generation)** — answers policy questions by
  reading `policy_faqs.txt` directly, grounding responses in real reference
  material instead of relying on the model's general knowledge.
- **Long-term memory** — can save facts (e.g. a client's contact preference)
  to `agent_memory.json`, and correctly recalls them in later, completely
  separate runs of the script.
- **Safety guardrails** — a hard step limit prevents runaway loops, and the
  agent is instructed to ask for clarification rather than invent data when
  a lookup fails.

## What I learned, day by day
| Day | Focus | Key takeaway |
|---|---|---|
| 1 | Concepts | Workflows vs. agents; the ReAct loop (reason → act → observe) |
| 2 | Tool use | Built a single-tool calculator agent; debugged a model-deprecation error and an editor/file-sync issue |
| 3 | Multi-tool agents | Watched the model choose between tools, chain results, and fail gracefully (asked for clarification instead of fabricating a client record) |
| 4/5 | RAG + memory | Combined a static knowledge file with a persistent memory file; confirmed a fact saved in one run was correctly recalled in a separate run |
| 6 | Safety & evaluation | Tried to force the step-limit guardrail to trigger; found the agent's own efficient behavior (parallel tool calls, honest failure) made this hard to force — a useful finding in itself |
| 7 | Shipping | Combined everything into one final, documented agent |

## Notable debugging moments (real troubleshooting, not just happy-path code)
- **API model deprecation**: hit a `404` error when a model version became
  unavailable mid-project; fixed by reading the error message and updating
  the model string.
- **Editor/file-path mismatch**: repeated Notepad saves weren't reaching the
  file actually being executed; diagnosed using `type file | findstr` to
  verify file contents directly from the command line rather than trusting
  the editor, then resolved using PowerShell's `Get-Content`/`Set-Content`
  to edit the file in place.
- **API rate limits**: hit the free tier's daily request quota mid-session;
  a real example of why production agents need to handle API-level failures
  gracefully, not just tool-level failures.

## How to run it
```bash
python -m venv agent-env
agent-env\Scripts\activate      # Windows
pip install google-genai
set GEMINI_API_KEY=your-key-here
python agent.py
```

## Files
- `agent.py` — the final combined agent
- `policy_faqs.txt` — sample knowledge base (dummy data)
- `agent_memory.json` — generated automatically after first run

## Tech
Python, Google Gemini API (`gemini-3.6-flash`), function calling / tool use.
No agent framework used — built directly on the raw API to understand the
mechanics first.
