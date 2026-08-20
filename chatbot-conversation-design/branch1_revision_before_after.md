# Dialogue Revision — Branch 1: File a New Claim

## Feedback received (simulated user testing)
"The claims document question feels abrupt — it jumps straight into a
checklist right after the client says they need to file a claim, which
can feel cold when someone's already dealing with a stressful situation.
The 'yes/no do you have these ready' phrasing feels like a form, not a
conversation."

## Before

BOT: Hi! I'm here to help with claims, policy questions, or general
information. What can I help you with today?

USER: I need to file a claim.

BOT: Sorry to hear that — let's get this moving. What type of claim is
this: motor, life, or something else?

USER: Motor.

BOT: Got it. For a motor claim, I'll need: a completed claim form, a
valid ID, your original policy document, and a police report if a third
party was involved. Do you have these ready?

## After

BOT: Hi! I'm here to help with claims, policy questions, or general
information. What can I help you with today?

USER: I need to file a claim.

BOT: I'm sorry you're dealing with this — let's get it sorted as
smoothly as we can. What type of claim is this: motor, life, or
something else?

USER: Motor.

BOT: Understood. I'll walk you through what's needed step by step, no
need to have it all ready right now. First — do you have a completed
claim form, or would you like me to send you one to fill out?

--- IF THEY DON'T HAVE THE FORM ---
BOT: No problem, I'll send that over now. Once you have it, we'll also
need a valid ID, your original policy document, and — if another
vehicle was involved — a police report. We can go through these one at
a time whenever you're ready.

--- IF THEY HAVE THE FORM ---
BOT: Great. Alongside that, we'll need a valid ID and your original
policy document — and a police report too, if another vehicle was
involved. Do you have those on hand, or should I note what's still
outstanding?

## What changed, and why
- **Added a brief empathetic acknowledgment** ("I'm sorry you're dealing
  with this") before moving into task mode — small, but sets a tone of
  care rather than processing.
- **Replaced the single "do you have these ready?" yes/no gate** with a
  softer, one-item-at-a-time approach ("do you have a completed claim
  form, or would you like me to send you one?") — this breaks the
  document checklist into a conversation instead of a form dump, and
  gives the bot a natural way to help immediately if something is
  missing, rather than a flat "no" dead-ending the flow.
- **Reframed missing documents as normal, not a problem** ("no need to
  have it all ready right now") — reduces pressure on someone who may
  already be stressed from an accident.

This revision keeps the same underlying logic (documents needed,
missing-document handling, submission) but changes the *pacing and tone*
of how it's delivered — the kind of adjustment that only surfaces once
real users interact with the flow, not something you'd catch from
reading the script alone.
