"""
Insurance Chatbot Prototype — working implementation of the conversation
flow designed in chatbot_dialogue_script.md and flow-diagram.png.

Branches: file a claim, check claim status, prospect inquiry, fallback.
Incorporates the empathy revision documented in
branch1_revision_before_after.md (step-by-step document collection
instead of a yes/no form gate).
"""

import json
import os
from google import genai
from google.genai import types

client = genai.Client()

MEMORY_FILE = "chatbot_memory.json"

# ---------------------------------------------------------------------
# Dummy claim records (fake data only, safe for free-tier use)
# ---------------------------------------------------------------------
FAKE_CLAIMS = {
    "CLM-1001": {"status": "In review", "last_updated": "2026-08-15", "type": "Motor"},
    "CLM-1002": {"status": "Approved - payment processing", "last_updated": "2026-08-10", "type": "Life"},
}

REQUIRED_DOCS = {
    "motor": ["completed claim form", "valid ID", "original policy document", "police report (if third party involved)"],
    "life": ["completed claim form", "valid ID", "original policy document", "death certificate"],
    "other": ["completed claim form", "valid ID", "original policy document"],
}

# ---------------------------------------------------------------------
# Memory: remembers contact preference and in-progress claims across runs
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
# Tools for the claim branches
# ---------------------------------------------------------------------
def check_claim_status(reference_number: str) -> str:
    ref = reference_number.strip().upper()
    if ref in FAKE_CLAIMS:
        return str(FAKE_CLAIMS[ref])
    return f"Error: no claim found matching reference '{reference_number}'"

def get_required_documents(claim_type: str) -> str:
    key = claim_type.strip().lower()
    docs = REQUIRED_DOCS.get(key, REQUIRED_DOCS["other"])
    return json.dumps({"claim_type": key, "required_documents": docs})

TOOL_FUNCTIONS = {
    "check_claim_status": check_claim_status,
    "get_required_documents": get_required_documents,
    "remember_fact": remember_fact,
}

tools = types.Tool(
    function_declarations=[
        types.FunctionDeclaration(
            name="check_claim_status",
            description="Look up an existing claim by its reference number",
            parameters=types.Schema(
                type="OBJECT",
                properties={"reference_number": types.Schema(type="STRING", description="Claim reference, e.g. CLM-1001")},
                required=["reference_number"]
            )
        ),
        types.FunctionDeclaration(
            name="get_required_documents",
            description="Get the list of required documents for a given claim type",
            parameters=types.Schema(
                type="OBJECT",
                properties={"claim_type": types.Schema(type="STRING", description="motor, life, or other")},
                required=["claim_type"]
            )
        ),
        types.FunctionDeclaration(
            name="remember_fact",
            description="Save a fact (e.g. contact preference, claim in progress) to memory for future sessions",
            parameters=types.Schema(
                type="OBJECT",
                properties={
                    "key": types.Schema(type="STRING", description="Short label"),
                    "value": types.Schema(type="STRING", description="The fact to remember"),
                },
                required=["key", "value"]
            )
        ),
    ]
)

# ---------------------------------------------------------------------
# System prompt: encodes the branching flow + empathetic tone revisions
# ---------------------------------------------------------------------
SYSTEM_PROMPT = """You are a client assistant chatbot for an insurance
advisor. You handle four kinds of conversations:

1. FILING A NEW CLAIM: Acknowledge with empathy first (the client may
   have just been in an accident or lost someone) before asking
   anything else. Ask the claim type, then use get_required_documents
   to find out what's needed. Walk through documents ONE AT A TIME in
   a conversational way ("do you have X, or would you like me to send
   it to you?") rather than listing everything and asking a blunt
   yes/no. Reassure them they don't need everything ready at once.

2. CHECKING CLAIM STATUS: Ask for their claim reference number, use
   check_claim_status to look it up. If not found, ask them to double
   check the number, and offer to connect them with a human advisor.

3. PROSPECT (still deciding): Be warm and informational, never pushy.
   Ask what coverage they're considering. If they mention cost/price
   concerns, explain flexible payment options and offer a no-commitment
   quote. If unsure, ask if they'd like a follow-up later or to reach
   out whenever ready - respect their pace either way.

4. UNCLEAR INTENT: Ask one clarifying question. If still unclear,
   offer to connect them with a human advisor.

ACROSS ALL BRANCHES: Before ending a conversation where you're
proceeding with something concrete (a claim or handoff), ask their
preferred contact method (call, email, or WhatsApp) and mention that
their information stays within a secure system. Use remember_fact to
save this preference and any other useful facts (like an in-progress
claim) so future conversations can pick up where this one left off.

If a tool returns an error, never invent data - be honest about it and
offer a human handoff instead."""


def run_agent(user_message: str, max_steps: int = 6):
    memory = load_memory()
    full_system_prompt = SYSTEM_PROMPT + f"\n\nThings you remember from past sessions:\n{json.dumps(memory, indent=2)}"

    chat = client.chats.create(
        model="gemini-3.6-flash",
        config=types.GenerateContentConfig(tools=[tools], system_instruction=full_system_prompt)
    )
    response = chat.send_message(user_message)

    step = 0
    while step < max_steps:
        step += 1
        function_calls = response.function_calls

        if not function_calls:
            print(f"\n[BOT]: {response.text}")
            return

        print(f"\n[Step {step}] Calling {len(function_calls)} tool(s):")
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

    print(f"\n[STOPPED: reached max_steps={max_steps}]")


def chat_loop():
    print("Insurance Client Assistant — type 'quit' to end the conversation.\n")
    memory = load_memory()
    full_system_prompt = SYSTEM_PROMPT + f"\n\nThings you remember from past sessions:\n{json.dumps(memory, indent=2)}"

    chat = client.chats.create(
        model="gemini-3.6-flash",
        config=types.GenerateContentConfig(tools=[tools], system_instruction=full_system_prompt)
    )

    while True:
        user_message = input("[YOU]: ").strip()
        if user_message.lower() in ("quit", "exit"):
            print("\n[Session ended]")
            break
        if not user_message:
            continue

        response = chat.send_message(user_message)

        step = 0
        max_steps = 6
        while step < max_steps:
            step += 1
            function_calls = response.function_calls

            if not function_calls:
                print(f"\n[BOT]: {response.text}\n")
                break

            print(f"\n[Step {step}] Calling {len(function_calls)} tool(s):")
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
        else:
            print(f"\n[STOPPED: reached max_steps={max_steps} for this turn]\n")


if __name__ == "__main__":
    chat_loop()
