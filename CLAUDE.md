# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Flutter-based research chatbot application using Google Gemini AI (via Firebase AI) with Riverpod state management. Currently web-only.

## Common Commands

```bash
# Run the app
flutter run

# Build for web
flutter build web

# Run tests
flutter test

# Analyze code
flutter analyze

# Install dependencies
flutter pub get

# Code generation (required after adding @riverpod annotations)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode for code generation
flutter pub run build_runner watch
```

## Architecture

**State Management:** Riverpod with code generation (`@riverpod` annotations)

**Directory Structure:**
- `lib/models/` - Data models (Message, ChatSession) with copyWith() immutability pattern
- `lib/providers/chat_provider.dart` - All Riverpod providers; `chat_provider.g.dart` is generated (do not edit)
- `lib/services/gemini_service.dart` - Firebase AI/Gemini API integration with streaming responses
- `lib/screens/` - Top-level screens (ChatScreen handles responsive layout)
- `lib/widgets/` - Reusable components (ChatView, ChatInput, MessageBubble, Sidebar)

**Data Flow:**
1. User input via `ChatInput` → `ChatController.sendMessage()`
2. `ChatController` updates `ChatSession` state and calls `GeminiService`
3. `GeminiService` streams response chunks from Gemini 1.5 Flash
4. `ChatView` watches `activeSessionProvider` and re-renders as stream updates

**Responsive Breakpoint:** 900px (desktop: sidebar visible, mobile: sidebar in drawer)

## Key Patterns

**Riverpod Providers:**
- `@Riverpod(keepAlive: true)` for singleton services (GeminiService)
- `@riverpod class` for state notifiers (ChatSessions, ChatController)
- `@riverpod` for derived/computed state (activeSession)

**Model Conventions:**
- Immutable with `copyWith()` methods
- `toJson()`/`fromJson()` factories for serialization
- Auto-generated UUIDs and timestamps

**Widget Patterns:**
- `ConsumerWidget` for read-only provider access
- `ref.watch()` in widgets, `ref.read()` in controllers
- Auto-scroll uses `WidgetsBinding.addPostFrameCallback()`

## Firebase Setup

Firebase credentials in `lib/firebase_options.dart` need to be configured with real values. Currently web platform only - other platforms throw `UnsupportedError`.
