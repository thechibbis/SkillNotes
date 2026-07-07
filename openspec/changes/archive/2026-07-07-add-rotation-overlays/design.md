## Context

`SkillNotes` is a greenfield WoW addon for Midnight (12.0.7, interface version `120007`). The current code is a hello-world stub (`SkillNotes.lua`) that prints a greeting on `PLAYER_LOGIN`. The addon folder lives at `_retail_/Interface/AddOns/SkillNotes`.

Midnight (Patch 12.0) introduced "Addon Disarmament": combat-state addons that read unit health/power or recommend next spells are restricted, and some spells are individually flagged "secret" so queries about them return opaque tokens. Rotation *advisors* (Hekili) are dead. However, a **display-only, user-authored** overlay that reads no combat data and recommends nothing sits in the unrestricted quadrant. This addon occupies that quadrant.

Relevant Midnight APIs (verified against warcraft.wiki.gg and `Gethe/wow-ui-source` live branch, version `12.0.7.68225`):
- `C_SpellBook.GetSpellBookItemInfo(slotIndex, bank)` → `spellBookItemInfo` with `actionID`, `spellID`, `name`, `iconID` (FileDataID), `isPassive`, `itemType`. Enumerates the player's own spellbook. Tagged `AllowedWhenUntainted`.
- `C_Spell.GetSpellTexture(spellIdentifier)` → `iconID` (FileDataID). Tagged `AllowedWhenTainted` — works even for secret-flagged spells because texture is metadata, not state.
- `C_Spell.GetSpellName(spellIdentifier)` → localized name.
- `C_Item.GetItemIconByID(itemID)` → icon FileID. For custom-item steps.
- `GetCursorInfo()` → on spellbook drag returns `"spell", spellIndex, bookType, spellID, baseSpellID`; on item drag returns `"item", itemID, itemLink`.
- `C_Spell.GetSpellInfo(spellIdentifier)` exists as the consolidated getter; texture and name are also exposed as specific getters.
- `texture:SetTexture(fileID)` renders a cached FileID — no API call per frame.

## Goals / Non-Goals

**Goals:**
- Display user-authored rotation sequences as on-screen icon overlays.
- Two input paths: drag from spellbook; custom spell/item by numeric ID.
- Per-rotation direction (horizontal/vertical) controlling both layout and reorder buttons.
- Spec-gating per rotation.
- Account-wide rotations; per-character overlay positions.
- Zero combat-data dependency; survives Midnight's restrictions by construction.

**Non-Goals:**
- Click-to-cast from overlays.
- Auto-advance / tracking which step is "current" via cast events.
- Reading or re-displaying Blizzard's Rotation Assistant.
- Aura-snapshot capture (no `C_UnitAuras` usage).
- Bag-drag for items (items enter via custom-ID only).
- Minimap button (slash commands only).
- External libraries (Ace3, LibStub, etc.).

## Decisions

### D1: Steps are immutable copies — cache `{kind, id, fileID, name}` at authoring time
At the moment a step is added (via drag or custom-ID entry), resolve the icon FileID and localized name once and store them alongside the source ID. Display reads only `texture:SetTexture(step.fileID)` — never re-queries `C_Spell` or `C_Item`.

**Why**: Eliminates per-frame API calls (overlays are cheap) and makes the overlay secret-proof: even if a spell later becomes secret-flagged, the cached FileID still renders. Also survives patches that rename/reicon spells (icon goes stale, but never breaks).

**Alternative considered**: live-reference (re-query on display). Rejected — per-frame API churn and secret-value exposure for zero benefit.

### D2: Custom-ID field accepts spellID *or* itemID, resolved by try-spell-then-item
A single text field labeled "Spell or Item ID". On submit: try `C_Spell.GetSpellTexture(id)` first; if it returns a FileID, the step is `kind="spell"`. Else try `C_Item.GetItemIconByID(id)`; if non-nil, `kind="item"`. If both fail, show an error and do not add the step.

**Why**: Covers buffs (every buff has a spellID) and items (trinket-as-item icon) with one field and one fallback. Matches the user's decision to widen the custom path.

**Alternative considered**: two separate fields/buttons. Rejected — UX clutter for ~15 lines of fallback logic.

**Edge case**: A spellID and itemID can collide numerically in theory; in practice spell and item ID spaces are disjoint in WoW's data. The try-spell-first order is documented and deterministic.

### D3: Direction is per-rotation and single-source-of-truth for layout + reorder
Each rotation stores `dir = "HORIZONTAL" | "VERTICAL"`. The overlay lays steps out along that axis. The config UI shows **only the matching reorder pair** (◀▶ for horizontal, ▲▼ for vertical) per step — no permanently-disabled buttons.

**Why**: Avoids dead-button clutter; flipping direction is a one-click setting, not a mode change that hides half the UI.

**Alternative considered**: always show all four buttons. Rejected — half always do nothing; confusing.

### D4: Account-wide rotations + catalog; per-character overlay positions
`SavedVariables: SkillNotesDB` holds rotations (and the resolved step cache). `SavedVariablesPerCharacter: SkillNotesCharDB` holds overlay instances per character (position, size, locked, bound rotationId).

**Why**: Players share openers across alts of the same class but position overlays differently per toon's UI layout.

### D5: Spec-gating evaluated at display time via `PLAYER_SPECIALIZATION_CHANGED`
Each rotation optionally stores `specID`. On the spec-change event (and at overlay spawn), compare `rotation.specID` against the current spec; hide the overlay if gated to a different spec. `specID == nil` means "all specs."

**Why**: Cheap, event-driven, no polling. Matches the user's confirmed ask.

### D6: Overlays spawned in-world via slash command; config panel is authoring-only
Slash: `/sn place <rotationName>` (or rotation id) spawns a draggable overlay at the cursor. Right-click → context menu (size, spacing, alpha, direction toggle, lock, delete). `/sn unlock` / `/sn lock` toggles edit mode for all. `/sn config` opens the authoring panel.

**Why**: Keeps the config panel about *authoring rotations*; placement is a world interaction (drag where you want it). Matches the user's Config-UI decision for authoring without forcing placement into the panel.

### D7: No external libraries
Stock Blizzard APIs only. No Ace3, LibStub, LibSharedMedia, LibDBIcon.

**Why**: Trivially Midnight-safe (no dep chain to break), zero install friction, smaller addon. The config UI is built with stock `CreateFrame` + `FrameXML` templates (`UIDropDownMenu`, `EditBox`, `Button`).

### D8: Graceful degradation for unresolvable custom IDs
If both `GetSpellTexture` and `GetItemIconByID` return nil for a custom ID, the step is **not** added and the UI shows a localized error. If a spellbook drag yields a slot with nil icon (future/unloaded spell), skip with a console warning rather than adding a blank step.

**Why**: Prevents broken/blank icons from entering SavedVariables.

## Risks / Trade-offs

- **Risk**: Midnight's per-spell secret flags could make `C_Spell.GetSpellTexture`/`GetSpellName` return nil for individual secret-flagged spells at authoring time, even outside combat. **Mitigation**: try-then-fallback (D2); if both return nil, refuse the step with an error (D8). Worst case: a specific buff can't be added — user falls back to the buff's spellID if known. The display layer is never affected (cached FileIDs always render).
- **Risk**: Spell icon FileIDs drift across patches (Blizzard re-textures). **Mitigation**: icons go stale (show old art) but never break. A "refresh icons" action could be a future enhancement; not in v1.
- **Trade-off**: No click-to-cast means the overlay is reference-only. Players who want one-click execution use their action bar. This is the trade that keeps the addon trivially Midnight-safe.
- **Trade-off**: Custom-ID requires the user to know numeric IDs (from Wowhead). Power-user feature; the spellbook-drag path covers the common case.
- **Risk**: Config UI built on stock FrameXML templates may look unstyled vs. Ace3 panels. **Mitigation**: use `BackdropTemplate` + standard `GameFontNormal` inheritances for a native-looking panel; acceptable for v1.
- **Risk**: Load order — the addon depends on no Blizzard addon's functions, so `PLAYER_LOGIN` suffices; no `ADDON_LOADED` wait needed.
