# NutriGhar 🥗

> **An offline-first Indian nutrition and weight-management companion built for my sister and best friend, Ayushi Sinha.**

NutriGhar started with a simple request from my sister, Ayushi: she wanted an easier way to track her daily calories and protein while working toward losing weight and getting fitter.

Instead of building another generic calorie counter, I wanted to make something that understands the way we actually talk about food in India — from roti and dal to katori-sized portions and everyday Hinglish descriptions.

## What NutriGhar Does

NutriGhar is a Flutter-based Android application for personal nutrition tracking.

### 🥗 Food & Meal Tracking
- Search a large Indian-focused food database
- Log meals and portions
- Support common Indian food names and aliases
- Track daily calories and protein
- Add custom foods

### 🎯 Personal Goals
- Set nutrition and weight goals
- Calculate calorie and protein targets
- Track progress toward personal goals
- Monitor weight trends

### 📊 Progress & Insights
- View nutrition history
- Track weight changes
- See daily progress toward calorie and protein targets
- Get simple nutrition insights

### 🔥 Habits & Consistency
- Habit tracking
- Streak tracking
- Meal-preparation support

### 👨‍👩‍👧 Family Profiles
- Support for personal/family-oriented nutrition tracking

## Why I Built It

Ayushi wanted a practical way to keep track of what she was eating without turning every meal into a manual data-entry task.

That made me focus on three things:

**Indian food first.**  
Nutrition apps often feel easier when the database and portions match the food people actually eat.

**Simple tracking.**  
The goal is to make logging something you can keep doing every day.

**Privacy and offline-first design.**  
NutriGhar stores its core data locally and does not require a cloud backend for the basic nutrition-tracking experience.

## Hacktoberfest 2026 — Build for a Friend

NutriGhar is being developed as part of the **Hacktoberfest 2026 Weekend Challenge: Build for a Friend**.

For the challenge, the project is being extended with an **open-weight AI meal-understanding layer** designed around the way Ayushi and I naturally describe meals.

The direction is:

**Natural-language meal → AI understanding → food matching → deterministic nutrition calculation**

The AI is intended to handle the language and ambiguity in a meal description, while the application's existing nutrition engine remains responsible for the actual calculations.

This separation is deliberate:

> **The AI understands. The application does the math.**

### Open AI Direction

The AI extension uses **Gemma 3 4B** through **Ollama** for local inference.

The goal is to make natural-language meal logging more useful for Indian and Hinglish inputs while keeping the processing local rather than relying on a proprietary cloud API.

This approach provides:
- Local inference
- No per-request API cost
- Better privacy for personal nutrition data
- The ability to experiment with and swap open-weight models
- A path toward future customization for Indian/Hinglish food terminology

## Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Local Storage | SharedPreferences + SQLite |
| Charts | fl_chart |
| Local AI | Gemma 3 4B + Ollama |
| Data | Local Indian food datasets |

## Architecture

At its core, NutriGhar follows a local-first architecture:

\`\`\`
Flutter UI
    ↓
Riverpod state / services
    ↓
Food search + meal logging
    ↓
Local nutrition engine
    ↓
Local persistence
    └── SharedPreferences / SQLite
\`\`\`

The AI-assisted meal workflow extends that flow:

\`\`\`
Natural-language meal
        ↓
Gemma 3 4B (local)
        ↓
Structured food + portion extraction
        ↓
NutriGhar food search / grounding
        ↓
Deterministic nutrition calculation
        ↓
Daily calories + protein
\`\`\`

## Project Structure

The main application areas are organized around core services and features:

\`\`\`
lib/
├── core/
│   ├── database/
│   ├── di/
│   ├── models/
│   ├── services/
│   ├── theme/
│   └── widgets/
│
├── features/
│   ├── fact_corner/
│   ├── family/
│   ├── foods/
│   ├── goals/
│   ├── habits/
│   ├── home/
│   ├── log/
│   ├── meal_prep/
│   ├── onboarding/
│   └── progress/
│
└── main.dart
\`\`\`

Food data is stored locally under:

\`\`\`
assets/data/
\`\`\`

## Getting Started

### Requirements

- Flutter SDK
- Android Studio / Android SDK
- Dart
- An Android device or emulator

### Run locally

Clone the repository:

\`\`\`bash
git clone https://github.com/ArmanSinha7/NutriGhar.git
cd NutriGhar
\`\`\`

Install dependencies:

\`\`\`bash
flutter pub get
\`\`\`

Run the application:

\`\`\`bash
flutter run
\`\`\`

## Local AI Setup

The open-weight AI extension uses Ollama.

Install Ollama and pull the model:

\`\`\`bash
ollama pull gemma3:4b
\`\`\`

Start Ollama:

\`\`\`bash
ollama serve
\`\`\`

The Flutter application can then connect to the local Ollama endpoint when the AI meal-logging extension is enabled.

> **Note:** The core nutrition tracker remains useful without cloud AI. Local inference is used for the AI-assisted natural-language workflow.

## Design Principles

### Local-first
Core nutrition data and calculations are designed to work locally.

### Deterministic nutrition math
The AI should not invent calorie or protein values. Nutrition calculations are handled by application logic and the local food data.

### Grounded AI
AI-generated food interpretations should be grounded against the application's food database rather than blindly accepted.

### Indian food context
The database and user experience are designed around Indian meals, portions, and terminology.

## Roadmap

- [x] Core calorie and protein tracking
- [x] Indian food database
- [x] Goals and progress tracking
- [x] Habit and streak support
- [x] Offline-first storage
- [ ] AI-assisted natural-language meal logging
- [ ] Better Hinglish meal understanding
- [ ] Friend-specific meal recommendations
- [ ] Model comparison and evaluation
- [ ] Fully on-device inference on supported Android hardware

## Hacktoberfest Submission

This project is being submitted for:

**Hacktoberfest Weekend Challenge: Build for a Friend**

The person behind the project is **Ayushi Sinha — my sister and best friend**.

The challenge-specific AI work focuses on turning the real-world way she describes her meals into structured nutrition entries while keeping the rest of the nutrition pipeline reliable and deterministic.

## License

This project is open source. See the repository for the current licensing status and project files.

## Author

**Arman Sinha**

GitHub: https://github.com/ArmanSinha7
