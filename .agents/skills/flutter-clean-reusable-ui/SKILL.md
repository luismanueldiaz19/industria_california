---
name: flutter-clean-reusable-ui
description: >-
  Use this skill when creating, refactoring, or reviewing Flutter and Dart code to
  eliminate code bloat and duplication. Enforces Clean Architecture, DRY principles,
  reusable core UI components (buttons, dropdowns, inputs, date pickers), centralized
  formatters (dates, currency, numbers), and compact UI density rules.
---

# Flutter Clean Architecture & Reusable Compact UI

Enforce clean code, eliminate boilerplate and duplicated UI logic, and maintain a consistent, compact design system across Flutter applications.

## When to Use

- Creating new screens, dialogs, or complex forms.
- Refactoring bloated widgets, repeated `InputDecoration`, duplicated button styles, or repeated dialog calls.
- Implementing or formatting dates, currency, and numbers.
- Applying compact visual sizing (fonts, paddings, icon dimensions).

---

## 1. Clean Code & Architectural Standards

- **Single Responsibility (SRP)**: Keep `build()` methods declarative and small. If a widget file exceeds ~250 lines, extract sections into dedicated private or shared widgets.
- **Separation of Concerns**: Never execute business logic, HTTP requests, or raw database queries inside UI widgets. UI only dispatches actions and renders state.
- **DRY (Don't Repeat Yourself)**: Avoid duplicating inline decorations, border styles, or modal configurations across multiple views.
- **State & Callbacks**: Child widgets must remain dumb/stateless where possible. Pass pure callbacks (`VoidCallback`, `ValueChanged<T>`) instead of coupling children to parent controllers or global states.
- **Const Constructors**: Use `const` everywhere possible to avoid unnecessary widget rebuilds.

---

## 2. Reusable Core UI Components


`frontend\lib\core\widgets`
`frontend\lib\core\utils`

All recurring inputs, buttons, and dialogs must live in a centralized directory (e.g., `frontend\lib\core\widgets`,
`frontend\lib\core\utils`).
