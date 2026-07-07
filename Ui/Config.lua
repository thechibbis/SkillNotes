-- SkillNotes Config: authoring panel + overlay context menu.
-- Root module: creates the Config table and holds cross-file UI state.
-- Actual UI is split across ConfigPanel.lua, ConfigPrompts.lua, OverlayMenu.lua.
--
-- Authoring is panel-based; overlay placement is in-world (handled by Overlay.lua).
local addonName, ns = ...

local Config = {}
ns.Config = Config

-- Cross-file UI state (formerly module-local upvalues in the single Config.lua).
-- Kept on the Config table so the split files can read/write it; ns is
-- addon-private so this does not leak beyond the addon.
Config.selectedRotationId = nil  -- currently selected rotation in the panel
Config.mainFrame = nil            -- cached authoring window (built once)
Config._menuCloser = nil           -- reused click-outside button for the overlay menu
