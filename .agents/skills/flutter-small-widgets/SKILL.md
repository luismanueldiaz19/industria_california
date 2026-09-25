---
name: flutter-small-widgets
description: >-
  Use this skill when the user asks to create, modify, or refactor Flutter Widgets
  in this project, specifically emphasizing a reduction in font sizes and widget sizes
  (padding, margins, heights, icon sizes, etc.) for a more compact UI design.
---

# Creating Compact Flutter Widgets

When creating or modifying Flutter Widgets in this project, prioritize a compact UI design. Follow these guidelines:

1.  **Typography**: Use smaller font sizes for text elements. 
    *   Example: If a title was `fontSize: 24`, consider using `20` or `18`. 
    *   For body text, prefer sizes between `12` and `14`.
2.  **Spacing (Padding & Margins)**: Reduce padding and margins inside and around containers, cards, and buttons. 
    *   Example: Instead of `EdgeInsets.all(16.0)`, try `EdgeInsets.all(8.0)` or `12.0`.
3.  **Element Sizes**: 
    *   Reduce the height of buttons, text fields, and list tiles.
    *   Use smaller icons (e.g., `size: 20` or `18` instead of default 24).
4.  **Density**: Utilize `VisualDensity.compact` where applicable, especially in ListTiles and DataTables.
5.  **Layout**: Ensure elements are closer together but remain clearly readable and accessible.

Always verify that the resulting UI remains usable despite the smaller sizes.
