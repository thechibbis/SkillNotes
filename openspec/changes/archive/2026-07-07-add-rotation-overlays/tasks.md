## 1. Addon scaffold & data layer

- [x] 1.1 Update `SkillNotes.toc`: set `## Interface: 120007`, add `## SavedVariables: SkillNotesDB` and `## SavedVariablesPerCharacter: SkillNotesCharDB`, list new Lua files in load order
- [x] 1.2 Create `Core.lua`: addon namespace (`local addonName, ns = ...`), `ns.DB`/`ns.CharDB` table references populated on `ADDON_LOADED` / `PLAYER_LOGIN`, defaults merge for rotations/overlays tables
- [x] 1.3 Create `Data.lua`: rotation CRUD functions (create, get, list, rename, delete) operating on `ns.DB.rotations` keyed by unique id; step add/remove/move/label functions
- [x] 1.4 Add unique-name validation and id generation (counter or `GenerateUniqueID`-style) to rotation creation

## 2. Icon resolution (cached at authoring)

- [x] 2.1 Create `Resolve.lua` with `ResolveSpellByCursor()` — reads `GetCursorInfo()` for `"spell"` type, calls `C_SpellBook.GetSpellBookItemInfo` to fetch `iconID`/`name`/`spellID`, returns a step table `{kind="spell", id, fileID, name, label=nil}`
- [x] 2.2 Add `ResolveSpellByID(spellID)` — uses `C_Spell.GetSpellTexture` + `C_Spell.GetSpellName`, returns step table or nil
- [x] 2.3 Add `ResolveItemByID(itemID)` — uses `C_Item.GetItemIconByID` + `C_Item.GetItemName` (or `GetItemInfo`), returns step table or nil
- [x] 2.4 Add `ResolveCustomID(id)` — try `ResolveSpellByID` then fall back to `ResolveItemByID`; returns step table or nil + error reason
- [x] 2.5 Add graceful-nil handling: if any resolver returns nil FileID, return nil and surface a console warning (no blank steps enter SV)

## 3. Config panel: authoring UI

- [x] 3.1 Create `Config.lua` with `SkillNotes:OpenConfig()` — main frame using `BackdropTemplate`, titled "SkillNotes", three-pane layout (rotations list / step editor / rotation settings)
- [x] 3.2 Build left pane: scrollable rotations list with `[New]`/`[Rename]`/`[Delete]` buttons; selecting a rotation populates center pane
- [x] 3.3 Build center pane: step list laid out per `rotation.dir`; each step row shows icon + label field + remove (×) button + direction-matched reorder pair (◀▶ or ▲▼)
- [x] 3.4 Implement drop zone in center pane: `EnableMouse(true)`, `RegisterForDrag`, `SetScript("OnReceiveDrag", ...)` calling `ResolveSpellByCursor`; appended step persisted via Data.lua
- [x] 3.5 Build custom-ID entry row: `EditBox` accepting numeric input + `[Add]` button; on submit call `ResolveCustomID`, append step or show error
- [x] 3.6 Build right pane (rotation settings): direction dropdown (`HORIZONTAL`/`VERTICAL`), spec dropdown (`All Specs` / spec list), reflow center pane on change
- [x] 3.7 Wire `[New Rotation]` flow: prompt for name, validate uniqueness, create via Data.lua, select it
- [x] 3.8 Wire `[Delete Rotation]`: confirm prompt, delete via Data.lua, despawn any overlays bound to it, refresh list
- [x] 3.9 Wire step reorder/remove/caption handlers to Data.lua mutation functions; persist on each change

## 4. Overlay: placement & movement

- [x] 4.1 Create `Overlay.lua` with `Overlay:Spawn(rotationId)` — `CreateFrame("Frame", nil, UIParent)`, `SetMovable(true)`, `SetClampedToScreen(true)`, `RegisterForDrag("LeftButton")`, `StartMoving`/`StopMovingOrSizing` scripts
- [x] 4.2 Render step icons along the rotation's direction axis: create one `Texture` per step at `step.fileID` via `SetTexture`, anchor sequentially (horizontal: left-to-right; vertical: top-to-bottom) with `rotation.spacing` gap
- [x] 4.3 Render optional caption `FontString` beneath each icon when `step.label` is non-nil
- [x] 4.4 Save final position on drag-stop to `ns.CharDB.overlays[overlayId]` with point/relPoint/x/y
- [x] 4.5 Restore overlay positions from `ns.CharDB` on `PLAYER_LOGIN` (spawn all saved overlays for this character)

## 5. Overlay: context menu & settings

- [x] 5.1 Implement right-click context menu on overlays: items for Lock/Unlock, Size (slider or +/-), Spacing, Alpha, Direction toggle, Delete
- [x] 5.2 Wire Size/Spacing/Alpha changes to live re-layout of the overlay and persist to `ns.CharDB`
- [x] 5.3 Wire Direction toggle to update `rotation.dir` (rotation-level setting) and re-layout; refresh config panel if open
- [x] 5.4 Wire Delete to despawn the overlay and remove its `ns.CharDB` entry
- [x] 5.5 Wire Lock to disable dragging + hide edit border; persist locked state

## 6. Slash commands & spec-gating

- [x] 6.1 Register `SlashCmdList["SKILLNOTES"]` for `/sn` with subcommands: `config`, `place <name>`, `unlock`, `lock`
- [x] 6.2 Implement `/sn place <name>`: look up rotation by name, spawn overlay via Overlay:Spawn, print error if not found
- [x] 6.3 Implement `/sn config` to open the config panel; `/sn unlock`/`/sn lock` to toggle all overlays' edit mode
- [x] 6.4 Register `PLAYER_SPECIALIZATION_CHANGED` event; on fire, evaluate each overlay's bound rotation `specID` vs current spec, `Show()`/`Hide()` accordingly
- [x] 6.5 Evaluate spec-gating at spawn time and on `PLAYER_LOGIN` initial overlay restore

## 7. Polish & verification

- [x] 7.1 Replace hello-world body of `SkillNotes.lua` with require/load of new modules (or convert `SkillNotes.lua` to the bootstrap that loads `Core.lua`)
- [x] 7.2 Add GameTooltip on icon hover in overlays and config showing the step's cached name + source kind
- [ ] 7.3 Smoke test (in-game, requires WoW client): create a rotation, add steps via drag and custom ID, place overlay, drag/lock/resize, switch specs, relog — verify persistence and spec-gating. PARTIAL: all 6 Lua files pass `luac -p` syntax validation (addon will load); 3 runtime bugs found & fixed during static review (drop-zone `RegisterForDrag`, orphaned-frame leaks in `Refresh`/`layout`). Remaining: live in-game interaction test.
- [x] 7.4 Verify no per-frame `C_Spell`/`C_Item` calls occur during overlay display (icon uses cached FileID only) — confirmed by static trace of all display/movement/event code paths
- [x] 7.5 Test unresolvable custom ID (e.g., `999999999`) shows error and adds no step — `Resolve.CustomID` returns nil + error when both `GetSpellTexture` and `GetItemIconByID` fail; `Config.AddCustomFromEditBox` calls `ns.Warn(err)` and returns without adding
- [ ] 7.6 Confirm rotations appear on a different character (account-wide) and overlays do not (per-character) — code path fully verified: TOC declares `## SavedVariables: SkillNotesDB` (account) and `## SavedVariablesPerCharacter: SkillNotesCharDB` (per-char); `Core.lua` assigns each to `ns.DB`/`ns.CharDB`; all rotation data touches only `ns.DB.rotations` (Data.lua), all overlay data touches only `ns.CharDB.overlays` (Overlay.lua) — no cross-contamination. Remaining: multi-character in-game confirmation.
