## Why

Players have no lightweight, display-only way to annotate skill/spell rotations as on-screen icon overlays. Rotation-helper addons that *recommend* next actions are dead under Midnight's Addon Disarmament (Hekili et al.), but a static, user-authored reference overlay — one that reads no combat data and recommends nothing — sits safely in the unrestricted quadrant and is genuinely useful for memorizing openers and priority sequences.

## What Changes

- Add a config UI for authoring **rotations**: named, ordered sequences of spell/buff/item steps, each displayed as a cached icon with an optional caption.
- Support two input paths for adding steps: **drag from the in-game spellbook**, and a **custom spell/item-by-ID** entry field (accepts spellID or itemID).
- Add per-rotation **direction** (horizontal/vertical) that drives both overlay layout and the visible reorder button pair (◀▶ or ▲▼).
- Add **spec-gating**: a rotation may be bound to a specific specialization or shown on all specs.
- Add in-world **overlay placement**: slash command spawns a draggable overlay bound to a rotation; right-click context menu for size/spacing/alpha/lock/delete.
- Store rotations account-wide (`SavedVariables`); overlay positions per-character (`SavedVariablesPerCharacter`).
- Display-only: no click-to-cast, no auto-advance, no combat-data reads. Icons are cached as texture FileIDs at authoring time and never re-queried at display time.

## Capabilities

### New Capabilities

- `rotation-authoring`: Creating and editing rotations — ordered sequences of spell/buff/item steps — via a config UI, with drag-from-spellbook and custom-ID input paths, per-rotation direction, and spec-gating.
- `overlay-display`: Rendering a rotation as a movable, lockable on-screen overlay of icons, placed in-world via slash command, spec-gated at display time, with per-character positions.

### Modified Capabilities

None — this is a greenfield addon (current `SkillNotes.lua` is a hello-world stub).

## Impact

- **Affected areas**: `SkillNotes.toc`, `SkillNotes.lua` (replaced/expanded), new Lua modules under the addon folder. No existing capabilities modified.
- **Migration**: Current `SkillNotes.lua` hello-world is replaced. No `SavedVariables` migration needed (first introduction of `SkillNotesDB` / `SkillNotesCharDB`).
- **Risks**: Midnight's per-spell "secret" flags could make `C_Spell.GetSpellTexture`/`C_Spell.GetSpellName` return nil for individual secret-flagged spells; mitigated by graceful degradation (step shows a placeholder icon + the raw ID). Custom-ID resolution runs at authoring time only and is tagged `AllowedWhenTainted`, so combat-state restrictions do not apply.
- **Out of scope**: click-to-cast, auto-advance on cast events, reading Blizzard's Rotation Assistant, aura-snapshot capture, bag-drag for items.
