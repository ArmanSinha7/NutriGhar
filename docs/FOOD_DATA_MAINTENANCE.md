# Food Dataset Maintenance

NutriGhar keeps food data in local assets so core food search and nutrition tracking can work offline. Most dataset maintenance happens under `assets/data/foods/`.

## Expected JSON shape

The current validator expects each JSON file in that directory to contain a top-level `foods` array. Each food entry should include:

- `id`: stable identifier.
- `name`: readable food name.
- `category`: food grouping.
- `isVegetarian`: vegetarian classification.
- `confidenceLevel`: the dataset's confidence metadata.
- `per100g`: nutrition fields including `caloriesMin`, `caloriesMax`, `protein`, `carbs`, and `fat`.

Follow the exact shape and types used by neighboring records. Do not add new field conventions to just one file without updating the consuming code.

## Validation command

From the repository root, run:

```bash
dart run scripts/validate_data.dart
```

The validator parses JSON files under `assets/data/foods/`, checks the top-level list and required fields, and compares calorie ranges with a rough macro-based estimate.

A calorie/macro mismatch is currently emitted as a **warning**, not a validation failure. Review the record and its source before merging. The calculation is a sanity check only; it does not verify source quality, cooking method, serving assumptions, or every nutrition value.

## Data quality checklist

Before adding or editing food records:

1. Check for an existing equivalent food to avoid duplicates.
2. Use a stable unique ID and a consistent, user-friendly name.
3. Make serving assumptions explicit. A katori, bowl, or piece can vary in size.
4. Check that quantities use the same per-100-gram basis expected by the app.
5. Preserve the source or provenance in the appropriate dataset metadata when available.
6. Use plausible non-negative values and inspect calorie warnings.
7. Test aliases and spelling variations against food search when the change affects discoverability.

## Review considerations

- Distinguish raw, cooked, fried, and packaged variants when their nutrition differs materially.
- Do not silently convert an approximate portion into an exact gram amount.
- Avoid claims of exactness when the source itself gives a range.
- Do not use generated AI text as a nutrition source. AI may help interpret a user's phrase, but the matched local record supplies the nutrition values.
- Keep the dataset useful for Indian dishes and regional naming variation without making unsupported assumptions about every recipe.

For larger dataset changes, summarize the number of added/changed records and mention validation output in the pull request.
