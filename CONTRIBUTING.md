# Contributing to NutriGhar

Thanks for helping improve NutriGhar, an offline-first nutrition tracker focused on Indian foods and everyday portions.

## Before you start

1. Read the project overview in [README.md](README.md).
2. For non-trivial changes, open an issue first so the scope and expected behavior are clear.
3. Keep changes focused. Avoid committing generated build output, local IDE files, secrets, or personal health data.

## Development setup

Install Flutter and the Android SDK, then run:

```bash
flutter pub get
flutter analyze
flutter test
```

If you change food JSON under `assets/data/foods/`, also run:

```bash
dart run scripts/validate_data.dart
```

The food validation script checks JSON structure and required food fields. It reports calorie/macro mismatches as warnings, so review those warnings rather than treating a successful exit as proof that all nutrition values are correct.

## Code and data guidelines

- Follow the existing Dart formatting and lint conventions.
- Prefer small, readable changes over broad unrelated refactors.
- Keep nutrition calculations deterministic and testable.
- Treat AI output as an interpretation or suggestion, not as the source of nutrition facts.
- Ground food matches and nutrition values in the app's local data; do not let a language model invent macros.
- Preserve offline functionality unless a change explicitly documents why network access is needed.
- Do not include real people's personal, weight, or health information in fixtures, logs, screenshots, or test data.

## Pull requests

A helpful pull request includes:

- The problem being solved and the intended behavior.
- A short summary of the implementation.
- Tests or validation commands run, plus any that could not be run.
- Screenshots for UI changes when practical.
- Known limitations, especially for nutrition estimates or AI-assisted features.

Please be respectful in reviews. The aim is to make food tracking more accessible and reliable, not to provide medical diagnosis or individualized medical treatment.
