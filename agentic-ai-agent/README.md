# Agentic AI Assistant Agent

## Technologies
- Google Gemini API (gemini-3.6-flash)
- Python
- Function Calling / Tool Use
- Retrieval-Augmented Generation (RAG)
- JSON-based persistent memory

## Skills Demonstrated
- Agentic system design (tool use, multi-step reasoning loops)
- API integration and debugging
- Retrieval-augmented generation (grounding responses in external data)
- Persistent state management
- Safety guardrail design (loop limits, graceful failure handling)
- Command-line environment troubleshooting

## What I Learned
This project was a self-directed, week-long deep dive into agentic AI,
built from raw API calls rather than a framework, to understand the
underlying mechanics before relying on abstractions.

**Day 1 — Concepts.** I studied the distinction between fixed workflows
and true agents, and the ReAct pattern (reason → act → observe → repeat)
that underlies most agentic systems.

**Day 2 — First working agent (tool use).** I built a single-tool
calculator agent from the raw Gemini API, and debugged a model-deprecation
error and a file-sync issue between my editor and the terminal.

**Day 3 — Multiple tools and graceful failure.** I added a second tool
(client lookup) and watched the model choose between tools, chain their
outputs together, and — critically — handle a failed lookup honestly
instead of fabricating data, asking for human clarification instead.

**Day 4/5 — RAG and memory.** I combined a static knowledge file (RAG)
with a persistent memory file that survives across separate script runs.
A fact saved in one run was correctly recalled in a completely separate,
later run — proof the memory persisted outside the conversation itself.

**Day 6 — Safety and evaluation.** I attempted to force the agent's
`max_steps` safety guardrail to trigger using multiple simultaneous
invalid lookups. The agent avoided hitting the limit by parallelizing
independent tool calls and failing gracefully within just two steps — a
useful finding in itself: well-designed tool use can reduce how often a
hard safety limit is actually needed, though the limit remains valuable
as a backstop.

**Day 7 — Shipping the final agent.** I combined tool use, RAG, memory,
and safety guardrails into one final, documented agent.

Real debugging was part of the learning process throughout: an API
model-deprecation error (fixed by reading the error message and updating
the model string), an editor/file-path synchronization issue (diagnosed
by verifying file contents directly from the command line rather than
trusting the editor), and a live encounter with API rate limits — a
practical lesson in why production agents need to handle API-level
failures gracefully, not just tool-level ones.

## Project Evidence

**[View the agent code (`agent.py`)](agent.py)**  
The final combined agent — tool use, RAG, memory, and safety guardrails in one system.

---

**API setup (sanitized)**

![API key page](api-key.png)

---

**Day 2 — 404 model error and fix**

![404 model error and fix](day2-error-fix.png)

**Day 2 — Final working output (three parallel tool calls)**

![Day 2 final working output](day2-output.png)

---

**Day 3 — Adeyemi: successful multi-tool chain**

![Day 3 Adeyemi chain](day3-adeyemi.png)

**Day 3 — Musa: graceful failure**

![Day 3 Musa graceful failure](day3-musa.png)

---

**Day 4/5 — Combined RAG + memory run**

![Combined RAG and memory run](day4-rag-memory.png)

**Day 4/5 — agent_memory.json contents**

![agent_memory.json contents](day4-memory-json.png)

---

**Day 7 — Final capstone run**

![Day 7 final capstone run](day7-final.png)

## How to Run
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
