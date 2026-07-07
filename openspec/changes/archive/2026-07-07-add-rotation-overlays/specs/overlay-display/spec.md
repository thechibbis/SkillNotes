## ADDED Requirements

### Requirement: Overlay spawning
A player can spawn a draggable overlay bound to a rotation via a slash command.

#### Scenario: Spawn an overlay
- **WHEN** the player runs `/sn place <rotationName>`
- **AND** a rotation with that name exists
- **THEN** an overlay is created near the cursor, displaying that rotation's steps as icons laid out along the rotation's direction axis
- **AND** the overlay is unlocked (draggable) by default

#### Scenario: Spawn with an unknown rotation name
- **WHEN** the player runs `/sn place <name>` and no rotation with that name exists
- **THEN** no overlay is spawned and an error is printed to the chat frame

### Requirement: Overlay movement
An unlocked overlay can be dragged to any position on screen.

#### Scenario: Drag an overlay
- **WHEN** the player drags an unlocked overlay
- **THEN** the overlay follows the cursor
- **AND** on release the final position is saved to per-character saved variables

### Requirement: Overlay lock state
Each overlay can be locked to prevent accidental movement.

#### Scenario: Lock an overlay
- **WHEN** the player right-clicks an overlay and selects "Lock"
- **THEN** the overlay becomes non-draggable and its edit border is hidden
- **AND** the locked state is persisted per-character

#### Scenario: Unlock all overlays
- **WHEN** the player runs `/sn unlock`
- **THEN** all overlays become draggable and show their edit borders

### Requirement: Overlay appearance settings
Each overlay has configurable icon size, spacing, and alpha, set via its right-click context menu.

#### Scenario: Change icon size
- **WHEN** the player sets a new icon size in the overlay's context menu
- **THEN** all icons in that overlay resize to the new value and the setting is persisted per-character

#### Scenario: Change spacing
- **WHEN** the player sets a new spacing value
- **THEN** the gap between icons updates accordingly and the setting is persisted

#### Scenario: Change alpha
- **WHEN** the player sets a new alpha (0.0–1.0)
- **THEN** the overlay's transparency updates and the setting is persisted

### Requirement: Overlay deletion
A player can delete an overlay via its context menu.

#### Scenario: Delete an overlay
- **WHEN** the player selects "Delete" from an overlay's context menu
- **THEN** the overlay is despawned and its per-character entry is removed from saved variables
- **AND** the underlying rotation is unaffected

### Requirement: Overlay spec-gating
An overlay's visibility follows the spec-gating of its bound rotation.

#### Scenario: Hide overlay on spec mismatch
- **WHEN** an overlay's rotation is bound to spec X
- **AND** the player's active spec is not X
- **THEN** the overlay is hidden

#### Scenario: Show overlay on spec match
- **WHEN** the player switches to spec X
- **THEN** the overlay is shown without requiring a re-spawn

#### Scenario: Show overlay with no spec binding
- **WHEN** the overlay's rotation has `specID == nil` (all specs)
- **THEN** the overlay remains visible across all spec changes

### Requirement: Overlay persistence per character
Overlay instances and their positions are stored per-character so each character can have its own layout.

#### Scenario: Overlays persist per character
- **WHEN** the player places overlays on character A and logs in on character B
- **THEN** character B has no overlays until placed, and character A's overlays reappear on character A's next login

### Requirement: Display-only behavior
Overlays never cast spells, read combat data, or react to cast events.

#### Scenario: No interaction with spell casting
- **WHEN** the player clicks an overlay icon
- **THEN** no spell is cast and no game state is modified
- **AND** no combat log, unit health, or cast event is read by the overlay

### Requirement: Overlay icon rendering
Overlay icons render from cached FileIDs without per-frame API calls.

#### Scenario: Render from cache
- **WHEN** an overlay is visible
- **THEN** each step's icon is rendered via `texture:SetTexture(step.fileID)` using the FileID cached at authoring time
- **AND** no `C_Spell` or `C_Item` query occurs during overlay display or movement
