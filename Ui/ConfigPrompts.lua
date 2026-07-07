-- SkillNotes Config prompts: modal popups for new / delete rotation flows.
local addonName, ns = ...

local Config = ns.Config

-- New rotation flow: prompt for a name via a tiny popup, then create.
function Config.NewRotationPrompt()
	local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	popup:SetSize(300, 120)
	popup:SetPoint("CENTER")
	popup:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})
	popup:EnableMouse(true)

	local edit = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
	edit:SetSize(260, 24)
	edit:SetPoint("TOP", popup, "TOP", 0, -28)
	edit:SetAutoFocus(true)
	edit:SetMaxLetters(32)

	local function confirm()
		local name = edit:GetText()
		local id, err = ns.Data.CreateRotation(name)
		if not id then
			ns.Warn(err or "Could not create rotation.")
			return
		end
		Config.Select(id)
		popup:Hide()
	end

	edit:SetScript("OnEnterPressed", confirm)

	local ok = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	ok:SetSize(90, 22)
	ok:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 24, 16)
	ok:SetText("OK")
	ok:SetScript("OnClick", confirm)

	local cancel = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
	cancel:SetSize(90, 22)
	cancel:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -24, 16)
	cancel:SetText("Cancel")
	cancel:SetScript("OnClick", function() popup:Hide() end)
end

function Config.DeleteRotationPrompt(id)
	local r = ns.Data.GetRotation(id)
	if not r then return end
	StaticPopupDialogs["SKILLNOTES_DELETE_ROT"] = {
		text = "Delete rotation '" .. r.name .. "'? This also removes any overlays bound to it.",
		button1 = "Delete",
		button2 = "Cancel",
		OnAccept = function()
			ns.Data.DeleteRotation(id)
			if Config.selectedRotationId == id then Config.selectedRotationId = nil end
			Config.Refresh()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show("SKILLNOTES_DELETE_ROT")
end
