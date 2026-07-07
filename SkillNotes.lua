-- SkillNotes: bootstrap. Loads after Core/Data/Resolve/Overlay/Config.
-- Wires slash commands and the final "player ready" hooks.
local addonName, ns = ...

-- /sn config | /sn place <name> | /sn unlock | /sn lock
SLASH_SKILLNOTES1 = "/sn"
SLASH_SKILLNOTES2 = "/skillnotes"
SlashCmdList["SKILLNOTES"] = function(msg)
	msg = msg or ""
	-- Parse the first word as the command (case-insensitive) but leave the
	-- rest of the message untouched so rotation names keep their casing.
	local cmd, arg = msg:match("^(%S+)%s*(.*)$")
	cmd = (cmd or msg):lower()
	arg = (arg or "")
	if cmd == "config" then
		ns.Config.Open()
	elseif cmd == "place" then
		local name = arg and arg ~= "" and arg or nil
		if not name then
			ns.Print("Usage: /sn place <rotation name>")
			return
		end
		local r = ns.Data.GetRotationByName(name)
		if not r then
			ns.Print("No rotation named '" .. name .. "'.")
			return
		end
		ns.Overlay.Spawn(r.id, true)
	elseif cmd == "unlock" then
		ns.Overlay.SetAllLocked(false)
		ns.Print("Overlays unlocked.")
	elseif cmd == "lock" then
		ns.Overlay.SetAllLocked(true)
		ns.Print("Overlays locked.")
	elseif cmd == "remove" then
		ns.Overlay.DespawnAll()
		ns.Print("All overlays removed.")
	else
		ns.Print("Commands: /sn config | /sn place <name> | /sn remove | /sn unlock | /sn lock")
	end
end

ns.OnDBReady(function()
	-- One-shot on player login: ensure overlay module is ready (it registers its
	-- own PLAYER_LOGIN handler for restore; nothing to do here but confirm load).
	ns.Print("Loaded. Use /sn config to begin.")
end)
