"""
Capstone: Insurance Client Assistant Agent
Built across a 7-day self-directed learning sprint on agentic AI.

This agent combines everything from the week into one working system:
  - Tool use (calculator + client lookup)      [Day 2-3]
  - RAG - answers grounded in a real FAQ file   [Day 4]
  - Long-term memory - remembers facts across runs [Day 5]
  - Safety guardrails - max step limit, honest error handling [Day 6]

Author: Chinenye Ugwu
"""

import json
import os
from google import genai
from google.genai import types

client = genai.Client()

KNOWLEDGE_FILE = "policy_faqs.txt"
MEMORY_FILE = "agent_memory.json"

# ---------------------------------------------------------------------
# RAG: read the knowledge base file into context
# ---------------------------------------------------------------------
def load_knowledge() -> str:
    if not os.path.exists(KNOWLEDGE_FILE):
        return "(no knowledge file found)"
    with open(KNOWLEDGE_FILE, "r", encoding="utf-8") as f:
        return f.read()

# ---------------------------------------------------------------------
# MEMORY: simple JSON file, read/write across separate script runs
# ---------------------------------------------------------------------
def load_memory() -> dict:
    if not os.path.exists(MEMORY_FILE):
        return {}
    with open(MEMORY_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def save_memory(memory: dict) -> None:
    with open(MEMORY_FILE, "w", encoding="utf-8") as f:
        json.dump(memory, f, indent=2)

def remember_fact(key: str, value: str) -> str:
    memory = load_memory()
    memory[key] = value
    save_memory(memory)
    return f"Saved: {key} = {value}"

# ---------------------------------------------------------------------
# TOOL: calculator
# ---------------------------------------------------------------------
def calculate(expression: str) -> str:
    try:
        return str(eval(expression))
    except Exception as e:
        return f"Error: could not evaluate '{expression}' - {e}"

# ---------------------------------------------------------------------
# TOOL: fake client lookup (dummy data only - safe for free-tier use)
# ---------------------------------------------------------------------
FAKE_CLIENTS = {
    "adeyemi": {"policy": "Life Assurance", "monthly_premium": 25000, "renewal_date": "2026-09-01"},
    "okafor": {"policy": "Motor Insurance", "monthly_premium": 8000, "renewal_date": "2026-11-15"},
}

def search_client_notes(client_name: str) -> str:
    key = client_name.strip().lower()
    if key in FAKE_CLIENTS:
        return str(FAKE_CLIENTS[key])
    return f"Error: no client found matching '{client_name}'"

TOOL_FUNCTIONS = {
    "calculate": calculate,
    "search_client_notes": search_client_notes,
    "remember_fact": remember_fact,
}

tools = types.Tool(
    function_declarations=[
        types.FunctionDeclaration(
            name="calculate",
            description="Evaluate a math expression, e.g. '1500 * 12'",
            parameters=types.Schema(
                type="OBJECT",
                properties={"expression": types.Schema(type="STRING", description="Math expression")},
                required=["expression"]
            )
        ),
        types.FunctionDeclaration(
            name="search_client_notes",
            description="Look up a (fake, dummy) client's policy notes by name",
            parameters=types.Schema(
                type="OBJECT",
                properties={"client_name": types.Schema(type="STRING", description="Client's name")},
                required=["client_name"]
            )
        ),
        types.FunctionDeclaration(
            name="remember_fact",
            description="Save a fact about a client to long-term memory for future sessions",
            parameters=types.Schema(
                type="OBJECT",
                properties={
                    "key": types.Schema(type="STRING", description="Short label, e.g. 'okafor_contact_pref'"),
                    "value": types.Schema(type="STRING", description="The fact to remember"),
                },
                required=["key", "value"]
            )
        ),
    ]
)

# ---------------------------------------------------------------------
# THE AGENT LOOP - reason, act, observe, repeat, with a safety cap
# ---------------------------------------------------------------------
def run_agent(user_question: str, max_steps: int = 5):
    knowledge = load_knowledge()
    memory = load_memory()

    system_context = (
        f"You are a helpful assistant for an insurance advisor.\n\n"
        f"--- Knowledge base (policy FAQs) ---\n{knowledge}\n\n"
        f"--- Things you remember from past sessions ---\n{json.dumps(memory, indent=2)}\n\n"
        f"If a tool returns an error, do not invent data - ask the user "
        f"for clarification instead. If you learn a new fact worth "
        f"remembering, use the remember_fact tool to save it."
    )

    chat = client.chats.create(
        model="gemini-3.6-flash",
        config=types.GenerateContentConfig(tools=[tools], system_instruction=system_context)
    )
    response = chat.send_message(user_question)

    step = 0
    while step < max_steps:
        step += 1
        function_calls = response.function_calls

        if not function_calls:
            print(f"\n[Final answer after {step} step(s)]:")
            print(response.text)
            return

        print(f"\n[Step {step}] Model wants to call {len(function_calls)} tool(s):")
        tool_responses = []
        for call in function_calls:
            print(f"  -> {call.name}({dict(call.args)})")
            fn = TOOL_FUNCTIONS.get(call.name)
            result = fn(**call.args) if fn else f"Error: unknown tool '{call.name}'"
            print(f"     result: {result}")
            tool_responses.append(
                types.Part.from_function_response(name=call.name, response={"result": result})
            )
        response = chat.send_message(tool_responses)

    print(f"\n[STOPPED: reached max_steps={max_steps} without a final answer. "
          f"Safety limit prevented a runaway loop.]")


if __name__ == "__main__":
    question = (
        "Look up Adeyemi's policy notes, tell me their annual premium, "
        "and remember that Adeyemi prefers WhatsApp for reminders."
    )
    run_agent(question)
