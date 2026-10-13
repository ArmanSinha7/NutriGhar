# AI-Assisted Meal Logging: Design Note

**Status:** Proposed design for the open-weight AI extension. This document describes the intended workflow; it does not claim that every step is implemented in the current app.

## Goal

Let someone describe a meal in natural language, including Indian food names, Hinglish, and approximate household portions. Convert that description into a reviewable structure that the app can match against its local food database.

The model should interpret language. NutriGhar's food data and deterministic calculation code should remain the source of nutrition values.

## Intended data flow

1. **Parse the description.** Extract possible food items, quantities, units, preparation notes, and ambiguities.
2. **Normalize portions.** Preserve the original wording and convert only units the app can interpret safely. Do not silently treat a bowl, katori, or serving as a universal gram value.
3. **Ground each item.** Search the local food catalog and return candidate matches with their database IDs. Do not accept model-generated calorie or macro values.
4. **Ask when uncertain.** If an item has several plausible matches or an unclear portion, ask the user to choose or edit it before logging.
5. **Calculate locally.** Use the app's nutrition calculator and verified food records to compute the meal totals.
6. **Show the result for review.** Present the matched foods, portions, and totals so the user can correct the entry before saving.

## Example extraction format

A model response can use a constrained structure like this:

```json
{
  "items": [
    {
      "food_text": "2 medium rotis",
      "quantity": 2,
      "unit": "piece",
      "preparation": null,
      "needs_clarification": false
    },
    {
      "food_text": "one katori dal",
      "quantity": 1,
      "unit": "katori",
      "preparation": null,
      "needs_clarification": true
    }
  ],
  "clarification_question": "Was the dal thin or thick, and approximately how large was the katori?"
}
```

This is an illustrative schema, not a claim about an existing API. Food IDs, matched names, and nutrition totals should be added by application code after database lookup, not invented by the model.

## Reliability rules

- Treat model output as untrusted input; validate types, allowed units, missing fields, and quantity ranges.
- Never use free-form model-generated nutrition numbers as authoritative facts.
- Keep the user's original food phrase so they can understand and correct the match.
- Make uncertainty visible. Prefer asking a question to confidently choosing a weak match.
- If local inference is unavailable, allow ordinary manual food search and logging to continue.
- Avoid presenting nutrition estimates as medical advice or as exact measurements when the portion is approximate.

## Evaluation plan

Use a small, version-controlled test set with synthetic examples covering:

- Common dishes and ingredients, such as roti, rice, dal, poha, idli, and sabzi.
- Hinglish and spelling variations.
- Household units such as katori, bowl, cup, piece, and spoon.
- Mixed meals with multiple items.
- Missing quantity, ambiguous food names, and unsupported items.
- Similar names that should map to different catalog entries.

Measure item extraction accuracy, quantity/unit accuracy, catalog-match accuracy, clarification behavior, latency, and whether the same input produces a stable structured result. Keep nutrition calculation tests separate from language parsing tests.

## Model boundary

Gemma 3 4B through Ollama is the currently documented direction for local experimentation. Keep model access behind a small service interface so another model or a manual-only flow can be used without rewriting nutrition calculations.
