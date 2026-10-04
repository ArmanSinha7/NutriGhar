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
- Family-oriented nutrition profiles and management

## Why I Built It

Ayushi wanted a practical way to keep track of what she was eating without turning every meal into a manual data-entry task.

That made me focus on three things:

**Indian food first.**  
Nutrition tracking should work with the foods, portions, and terminology people actually use.

**Simple tracking.**  
The goal is to make logging easy enough to keep doing every day.

**Privacy and offline-first design.**  
The core application stores its data locally and does not require a cloud backend for basic nutrition tracking.

## Hacktoberfest 2026 — Build for a Friend

NutriGhar is being developed for the **Hacktoberfest 2026 Weekend Challenge: Build for a Friend**.

The project is built for **Ayushi Sinha — my sister and best friend**.

For the challenge, I am extending NutriGhar with an **open-weight AI meal-understanding workflow** based on the way Ayushi naturally describes what she eats.

The goal is to make food logging work more like a normal conversation:

**Natural-language meal → AI understanding → food matching → deterministic nutrition calculation**

The AI handles language and ambiguity. The application's nutrition engine remains responsible for the actual calculations.

> **The AI understands. The application does the math.**

### Open AI Direction

The challenge-specific AI workflow is designed around **Gemma 3 4B** running locally through **Ollama**.

The model is used for understanding natural-language meal descriptions and extracting structured information such as food items, quantities, and portions.

That output can then be grounded against NutriGhar's local food database before the application's deterministic nutrition calculations are applied.

This approach is intended to provide:

- Local inference
- No per-request API cost
- Better privacy for personal nutrition data
- The ability to experiment with and swap open-weight models
- A path toward improving Indian and Hinglish food understanding

## Tech Stack

| Layer | Technology |
|---|---|
| App | Flutter |
| Language | Dart |
| State Management | Riverpod |
| Local Storage | SharedPreferences + SQLite |
| Charts | fl_chart |
| AI Extension | Gemma 3 4B + Ollama |
| Data | Local Indian food datasets |

## Architecture

### Core application

```
Flutter UI
    ↓
Riverpod state / services
    ↓
Food search + meal logging
    ↓
Nutrition engine
    ↓
Local persistence
    └── SharedPreferences / SQLite
```

### AI-assisted meal workflow

```
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
```

The key design decision is that the model does not become the source of truth for nutrition arithmetic. The application keeps that part deterministic.

## Project Structure

The application is organized into core services and feature modules:

```
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
```

Food data is stored locally under:

```
assets/data/
```

## Getting Started

### Requirements

- Flutter SDK
- Dart
- Android Studio / Android SDK
- Android device or emulator

### Run locally

Clone the repository:

```bash
git clone https://github.com/ArmanSinha7/NutriGhar.git
cd NutriGhar
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Local AI Setup

The challenge-specific AI workflow uses Ollama for local inference.

Install Ollama and pull the model:

```bash
ollama pull gemma3:4b
```

Start Ollama:

```bash
ollama serve
```

When the AI meal-logging workflow is enabled, the Flutter application can connect to the local Ollama endpoint.

> The core nutrition tracker is designed to remain useful without a cloud AI dependency.

## Design Principles

### Local-first
Core nutrition data and calculations are kept local wherever possible.

### Deterministic nutrition math
The AI should not invent calorie or protein values. Nutrition calculations come from application logic and the local food data.

### Grounded AI
AI-generated food interpretations should be checked against the application's food database rather than blindly trusted.

### Indian food context
The experience is designed around Indian meals, portions, and the way people naturally describe them.

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

## Hacktoberfest Story

NutriGhar is not just a nutrition tracker to me.

It started because **Ayushi**, my sister and best friend, asked me for something that would make tracking her food easier while she worked toward losing weight and getting fitter.

The challenge gave me an opportunity to take that personal problem and explore where open-source AI could make the experience genuinely better.

The focus is not on adding an AI chatbot for the sake of having AI. It is on using an open-weight model where language understanding is actually useful, while keeping the nutrition calculations reliable and deterministic.

## Author

**Arman Sinha**

GitHub: https://github.com/ArmanSinha7

Repository: https://github.com/ArmanSinha7/NutriGhar
