# Rotation Authoring

## Purpose

Creating and editing rotations — ordered sequences of spell/buff/item steps — for the SkillNotes addon. Each step is an immutable icon resolved once at authoring time, persisted to account-wide saved variables.

## Requirements

### Requirement: Rotation creation
A player can create a named rotation that holds an ordered sequence of steps, each step representing a spell, buff, or item displayed as an icon.

#### Scenario: Create a new rotation
- **WHEN** the player opens the config panel and clicks "New Rotation"
- **AND** enters a name and confirms
- **THEN** a new rotation with that name, an empty step list, and default direction `HORIZONTAL` is created and persisted to account-wide saved variables

#### Scenario: Rotation requires a unique name
- **WHEN** the player attempts to create a rotation with a name that already exists
- **THEN** creation is refused and an error is shown

### Requirement: Step input via spellbook drag
A player can add a step to a rotation by dragging a spell from the in-game spellbook onto the rotation's drop zone in the config panel.

#### Scenario: Drag a spellbook spell into a rotation
- **WHEN** the player drags a spell from the spellbook and releases it on the rotation's drop zone
- **THEN** a new step is appended with `kind="spell"`, the dragged spell's `spellID`, the spell's icon FileID and localized name resolved once via `C_SpellBook.GetSpellBookItemInfo`, and `label=nil`
- **AND** the step's icon is rendered from the cached FileID without further API calls

#### Scenario: Drag a passive spellbook entry
- **WHEN** the dragged spellbook entry is a passive (e.g., a proc buff like Essence Burst)
- **THEN** it is added as a step just like an active spell, using the same icon and name resolution path

### Requirement: Step input via custom spell or item ID
A player can add a step by entering a numeric ID into a custom field, where the ID is resolved as a spell first, then an item.

#### Scenario: Enter a valid spell ID
- **WHEN** the player types a numeric ID into the custom field and submits
- **AND** `C_Spell.GetSpellTexture(id)` returns a non-nil FileID
- **THEN** a step is added with `kind="spell"`, that `spellID`, the resolved FileID, and the name from `C_Spell.GetSpellName(id)`

#### Scenario: Enter a valid item ID
- **WHEN** the player submits a numeric ID where `C_Spell.GetSpellTexture(id)` returns nil
- **AND** `C_Item.GetItemIconByID(id)` returns a non-nil FileID
- **THEN** a step is added with `kind="item"`, that `itemID`, the resolved FileID, and the item's name

#### Scenario: Enter an unresolvable ID
- **WHEN** the player submits a numeric ID where both spell and item resolution return nil
- **THEN** no step is added and a localized error is shown

### Requirement: Per-rotation direction
Each rotation has a direction setting of `HORIZONTAL` or `VERTICAL` that controls both the overlay's layout axis and which reorder buttons appear in the config panel.

#### Scenario: Set rotation direction
- **WHEN** the player changes a rotation's direction via its dropdown
- **THEN** the direction is persisted and the config panel's step list and reorder buttons reflow to match the chosen axis

#### Scenario: Reorder buttons match direction
- **WHEN** a rotation's direction is `HORIZONTAL`
- **THEN** each step shows left/right reorder buttons only
- **WHEN** a rotation's direction is `VERTICAL`
- **THEN** each step shows up/down reorder buttons only

### Requirement: Step reordering
A player can reorder steps within a rotation using the direction-matched button pair.

#### Scenario: Move a step forward
- **WHEN** the player clicks the forward button (▶ for horizontal, ▼ for vertical) on a step that is not the last in the list
- **THEN** that step swaps position with the next step and the change is persisted

#### Scenario: Move a step backward
- **WHEN** the player clicks the backward button (◀ for horizontal, ▲ for vertical) on a step that is not the first in the list
- **THEN** that step swaps position with the previous step and the change is persisted

### Requirement: Step captions
A player can add an optional text caption to a step, displayed beneath its icon.

#### Scenario: Set a step caption
- **WHEN** the player edits a step's caption field
- **THEN** the caption text is persisted with the step and rendered below the icon in both the config panel and any overlay bound to the rotation

### Requirement: Step removal
A player can remove a step from a rotation.

#### Scenario: Remove a step
- **WHEN** the player clicks the remove (×) button on a step
- **THEN** the step is deleted from the rotation and the change is persisted

### Requirement: Spec-gating
A rotation can be bound to a specific specialization or marked as shown on all specs.

#### Scenario: Bind a rotation to a spec
- **WHEN** the player selects a spec from the rotation's spec dropdown (or "All Specs")
- **THEN** the chosen `specID` (or `nil` for all specs) is persisted with the rotation

#### Scenario: Overlay visibility respects spec
- **WHEN** a rotation bound to spec X has an overlay placed
- **AND** the player's active spec is not X
- **THEN** the overlay is hidden
- **WHEN** the player switches to spec X
- **THEN** the overlay is shown

### Requirement: Rotation persistence
Rotations are stored account-wide so they are shared across all characters.

#### Scenario: Rotations persist across logins
- **WHEN** the player creates rotations on one character and logs in on another character
- **THEN** all previously created rotations are available in the config panel

### Requirement: Rotation deletion
A player can delete a rotation, which also removes any overlays bound to it.

#### Scenario: Delete a rotation
- **WHEN** the player deletes a rotation
- **THEN** the rotation and all its steps are removed from saved variables
- **AND** any in-world overlays bound to that rotation are despawned and their per-character entries removed
