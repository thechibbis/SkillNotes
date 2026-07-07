-- SkillNotes Core: addon namespace, saved-variable loading, shared helpers.
local addonName, ns = ...

-- Default appearance for freshly placed overlays.
ns.defaults = {
	iconSize = 36,
	spacing = 4,
	alpha = 1.0,
}

-- Colored chat prefix used across the addon.
function ns.Print(msg)
	print("|cFF4FFFB0[SkillNotes]|r " .. tostring(msg))
end

-- Lightweight debug logger (surfaces resolver warnings in-game).
function ns.Warn(msg)
	print("|cFFFFD24D[SkillNotes]|r " .. tostring(msg))
end

ns.DB = nil      -- account-wide (SkillNotesDB): { rotations = {}, nextId = n }
ns.CharDB = nil  -- per-character (SkillNotesCharDB): { overlays = {}, nextOverlayId = n }

-- Modules register an init callback to run once saved variables are loaded.
ns.readyCallbacks = {}
function ns.OnDBReady(fn) table.insert(ns.readyCallbacks, fn) end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		-- Account-wide DB
		SkillNotesDB = SkillNotesDB or {}
		SkillNotesDB.rotations = SkillNotesDB.rotations or {}
		SkillNotesDB.nextId = SkillNotesDB.nextId or 1
		ns.DB = SkillNotesDB

		-- Per-character DB
		SkillNotesCharDB = SkillNotesCharDB or {}
		SkillNotesCharDB.overlays = SkillNotesCharDB.overlays or {}
		SkillNotesCharDB.nextOverlayId = SkillNotesCharDB.nextOverlayId or 1
		ns.CharDB = SkillNotesCharDB

		self:UnregisterEvent("ADDON_LOADED")
		for _, fn in ipairs(ns.readyCallbacks) do fn() end
		ns.readyCallbacks = nil
	end
end)
