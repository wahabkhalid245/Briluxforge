# Core Widgets — Usage Guide

This directory contains every shared UI primitive for Briluxforge.
**Do not create a new widget in `lib/features/` that duplicates functionality here.**
When a Phase-12 widget does not cover your need, extend it in this directory and update this file.

---

## AppButton — `app_button.dart`

```dart
AppButton(
  label: 'Save',
  onPressed: _save,
  variant: AppButtonVariant.primary,   // primary | secondary | ghost
  size: AppButtonSize.normal,          // compact (32) | normal (36) | large (44)
  leadingIcon: Icons.save,             // optional
  isLoading: _saving,                  // swaps label for spinner; keeps size
)
```

**Rules:**
- Replaces `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton` everywhere.
- `primary` — `brandPrimaryMuted` fill + 1 px top-inner highlight. Use for the single most important action per screen.
- `secondary` — 1 px outlined, no fill. Use for cancel / back / alternative actions.
- `ghost` — no border, no fill until hover. Use for low-emphasis inline actions (e.g. "Add API Keys" hint).
- Never reach into `FilledButton.styleFrom` or `ElevatedButton.styleFrom` to style buttons.

---

## AppCard — `app_card.dart`

```dart
AppCard(
  child: ...,
  onTap: _handleTap,   // optional — enables hover elevation + pointer cursor
  padding: const EdgeInsets.all(AppSpacing.lg),  // optional
  color: AppColors.surfaceOverlay,               // optional override
)
```

**Rules:**
- `AppRadii.borderMd` radius, `AppColors.borderSubtle` 1 px border.
- Default background: `AppColors.surfaceRaised` (dark) / `AppColors.surfaceLight` (light).
- Replaces every raw `Card()`, `Container(decoration: BoxDecoration(...))` card pattern.
- Do **not** put an `AppCard` inside another `AppCard` — use `AppColors.surfaceOverlay` as the inner surface directly.

---

## AppToggle — `app_toggle.dart`

```dart
AppToggle(
  value: skill.enabled,
  onChanged: (v) => ref.read(...).toggle(skill.id, v),
  label: 'Code Interpreter',            // optional
  description: 'Runs Python snippets',  // optional (shown below label)
)
```

**Rules:**
- Compact desktop size: 36 × 20 px track. Replaces every `Switch(...)` in the codebase.
- `grep -rn "Switch(" lib/features/` must return zero matches.

---

## AppStatusCard — `app_status_card.dart`

```dart
AppStatusCard(
  variant: AppStatusVariant.success,  // success | error | warning | info
  title: 'API key verified',
  body: 'Requests will now route to Claude.',  // optional
)
```

**Rules:**
- Tinted-background pattern: 12 % opacity hue background, 24 % opacity border, muted foreground text.
- Use for non-interactive banners and inline status indicators.
- For interactive errors with action buttons and optional technical-detail disclosure, use `AppErrorDisplay` instead.

---

## AppDialog + showAppDialog — `app_dialog.dart`

```dart
final confirmed = await showAppDialog<bool>(
  context: context,
  title: 'Delete conversation?',
  body: Text('This cannot be undone.'),
  primaryLabel: 'Delete',
  onPrimary: () => Navigator.pop(context, true),
  secondaryLabel: 'Cancel',
  onSecondary: () => Navigator.pop(context, false),
  maxWidth: 400,          // default 560
  maxHeightFactor: 0.8,   // default 0.8
);
```

**Rules:**
- Every `showDialog(` call in the codebase must go through `showAppDialog`.
- `AlertDialog` is banned; `Dialog` is banned in feature code. Use `AppDialog` exclusively.
- Dialog content is always scrollable — overflow is architecturally impossible.
- For complex dialogs that return custom result types, pass the stateful body as the `body:` widget and call `Navigator.pop<T>(context, value)` from inside it.

---

## AppErrorDisplay — `app_error_display.dart`

```dart
AppErrorDisplay(
  error: ErrorTranslator.translate(
    exception,
    onAction: _retry,
    actionLabel: 'Retry',
  ),
)
```

**Rules:**
- Always produce the `UserFacingError` via `ErrorTranslator.translate()` for `AppException` subtypes.
- For non-`AppException` catches, construct `UserFacingError` directly with the three-part schema (headline / explanation / actionLabel).
- **Never** call `e.toString()` inside a widget file — that is what `ErrorTranslator` is for.
- `technicalDetails` is shown in a collapsed monospace disclosure; it is never visible by default.

---

## AppSuccessGraphic — `app_success_graphic.dart`

```dart
const AppSuccessGraphic()
```

**Rules:**
- Used exclusively on the onboarding "All Set" screen.
- 96 px ring + 40 px checkmark. Entrance animation: ring scales in → check fades in.
- Do **not** use `Icons.check_circle` at large sizes anywhere. If you need a success hero graphic on a new screen, reuse `AppSuccessGraphic`.

---

## Design Token Reference

| Token class | File | Purpose |
|---|---|---|
| `AppRadii` | `app_tokens.dart` | Corner radii: `xs=4`, `sm=8`, `md=12`, `lg=16` |
| `AppSpacing` | `app_tokens.dart` | Spacing: `xxs=2`, `xs=4`, `sm=8`, `md=12`, `lg=16`, `xl=24`, `xxl=32`, `xxxl=48` |
| `AppElevation` | `app_tokens.dart` | Box shadows: `none`, `subtle`, `raised` |
| `AppColors` | `../theme/app_colors.dart` | All colour roles — never use `Color(0xFF...)` in `lib/features/` |

All `EdgeInsets`, `SizedBox`, `BorderRadius`, `BoxShadow`, and `Color` values in feature code **must** come from these token classes.
