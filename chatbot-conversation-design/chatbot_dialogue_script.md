# Insurance Client Chatbot — Scripted Dialogue

## Branch 1: File a new claim

BOT: Hi! I'm here to help with claims, policy questions, or general
information. What can I help you with today?

USER: I need to file a claim.

BOT: Sorry to hear that — let's get this moving. What type of claim is
this: motor, life, or something else?

USER: Motor.

BOT: Got it. For a motor claim, I'll need: a completed claim form, a
valid ID, your original policy document, and a police report if a third
party was involved. Do you have these ready?

--- IF YES ---
BOT: Great — you can upload them here, or reply "email" and I'll send
you a secure upload link instead. Once received, claims are typically
processed within 10 working days.

--- IF NO / MISSING SOME ---
BOT: No problem — here's what's still needed: [missing items]. You
don't have to do this all at once. I can save your progress and you can
continue anytime, or I can connect you with an advisor for help
gathering documents. Which would you prefer?

---

## Branch 2: Check status of an existing claim

BOT: Hi! I'm here to help with claims, policy questions, or general
information. What can I help you with today?

USER: I want to check my claim status.

BOT: Sure — could you share your claim reference number?

--- IF FOUND ---
BOT: Found it. Your claim is currently [status], last updated [date].
[If applicable: next step needed from client].

--- IF NOT FOUND ---
BOT: I couldn't find a claim under that reference — could you double
check the number? If it's not turning up, I can connect you with an
advisor to look into it directly.

---

## Branch 3: Prospect — still deciding

BOT: Hi! I'm here to help with claims, policy questions, or general
information. What can I help you with today?

USER: I'm just looking into insurance options, not sure yet.

BOT: Happy to help you explore! What type of coverage are you
considering: life, motor, or something else?

USER: Life insurance, but I'm not sure it's worth it right now.

BOT: Totally understandable — it's a big decision. Life assurance
covers [brief benefit summary]. A common concern at this stage is cost
— is that part of what's on your mind, or is it more about
understanding what's covered?

--- IF PRICE CONCERN ---
BOT: That's fair. Premiums can be paid monthly rather than as one lump
sum, and coverage levels are flexible to fit different budgets. Would
it help if I put together a personalized quote for you to look over, no
commitment?

--- IF COVERAGE QUESTION ---
BOT: [Answer grounded in policy FAQ content, e.g. what's covered, claim
process, etc.]
Does that answer it, or is there something else you're weighing?

--- CLOSING (either path) ---
BOT: No pressure at all — would you like me to follow up in a few days,
or would you rather reach out whenever you're ready?

---

## Branch 4: Unclear intent / fallback

BOT: Hi! I'm here to help with claims, policy questions, or general
information. What can I help you with today?

USER: [something ambiguous, e.g. "I have a question"]

BOT: Happy to help — just to make sure I point you the right way, are
you looking to file a claim, check an existing claim, or ask about a
policy?

--- IF STILL UNCLEAR ---
BOT: No worries — let me connect you with one of our advisors who can
help directly. What's the best way to reach you: call, email, or
WhatsApp?

---

## Shared closing step (all branches)

BOT: Before we wrap up — I'll just need a few details to proceed, and
everything shared here stays within our secure system. Would you
prefer we follow up by call, email, or WhatsApp going forward?

USER: [preference]

BOT: Perfect, noted. Thank you for reaching out — is there anything
else I can help with today?
