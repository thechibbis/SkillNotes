-- SkillNotes Overlay menu: right-click context menu on in-world overlays
-- (size / spacing / alpha / direction / lock / delete).
local addonName, ns = ...

local Config = ns.Config

-- Overlay context menu (opened on right-click of an in-world overlay).
function Config.OpenOverlayMenu(frame)
	if not frame or not frame.overlayId then return end

	local function addItem(menu, text, onClick)
		local b = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
		b:SetSize(150, 22)
		b:SetText(text)
		b:SetScript("OnClick", function()
			onClick()
			menu:Hide()
		end)
		return b
	end

	local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	menu:SetSize(170, 8)
	menu:SetPoint("CENTER")
	menu:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	menu:EnableMouse(true)
	menu:SetFrameStrata("FULLSCREEN_DIALOG")

	local y = 8
	local function add(text, onClick)
		local b = addItem(menu, text, onClick)
		b:SetPoint("TOPLEFT", menu, "TOPLEFT", 8, -y)
		y = y + 26
		menu:SetHeight(y + 8)
	end

	add(frame.settings.locked and "Unlock" or "Lock", function()
		frame.settings.locked = not frame.settings.locked
		ns.CharDB.overlays[frame.overlayId].locked = frame.settings.locked
		ns.Overlay.Relayout(frame.overlayId)
	end)

	add("Size +", function()
		frame.settings.iconSize = math.min(96, (frame.settings.iconSize or 36) + 8)
		ns.CharDB.overlays[frame.overlayId].settings = frame.settings
		ns.Overlay.Relayout(frame.overlayId)
	end)
	add("Size -", function()
		frame.settings.iconSize = math.max(16, (frame.settings.iconSize or 36) - 8)
		ns.CharDB.overlays[frame.overlayId].settings = frame.settings
		ns.Overlay.Relayout(frame.overlayId)
	end)
	add("Spacing +", function()
		frame.settings.spacing = (frame.settings.spacing or 4) + 2
		ns.CharDB.overlays[frame.overlayId].settings = frame.settings
		ns.Overlay.Relayout(frame.overlayId)
	end)
	add("Spacing -", function()
		frame.settings.spacing = math.max(0, (frame.settings.spacing or 4) - 2)
		ns.CharDB.overlays[frame.overlayId].settings = frame.settings
		ns.Overlay.Relayout(frame.overlayId)
	end)
	add("Alpha +", function()
		frame.settings.alpha = math.min(1, (frame.settings.alpha or 1) + 0.1)
		ns.CharDB.overlays[frame.overlayId].settings = frame.settings
		ns.Overlay.Relayout(frame.overlayId)
	end)
	add("Alpha -", function()
		frame.settings.alpha = math.max(0.1, (frame.settings.alpha or 1) - 0.1)
		ns.CharDB.overlays[frame.overlayId].settings = frame.settings
		ns.Overlay.Relayout(frame.overlayId)
	end)
	add("Toggle Direction", function()
		local r = ns.Data.GetRotation(frame.rotationId)
		if r then
			ns.Data.SetDirection(frame.rotationId, r.dir == "HORIZONTAL" and "VERTICAL" or "HORIZONTAL")
			ns.Overlay.RefreshByRotation(frame.rotationId)
			Config.Refresh()
		end
	end)
	add("Delete", function()
		ns.Overlay.Delete(frame.overlayId)
	end)

	-- Click-outside dismissal: a transparent button spanning UIParent at
	-- dialog strata catches the first click and tears down the menu. Reused
	-- across opens so we never stack stray closers.
	if not Config._menuCloser then
		local closer = CreateFrame("Button", nil, UIParent)
		closer:SetAllPoints(UIParent)
		closer:SetFrameStrata("FULLSCREEN_DIALOG")
		closer:EnableMouse(true)
		closer:Hide()
		closer:SetScript("OnClick", function()
			closer:Hide()
			if closer.menu then closer.menu:Hide() end
		end)
		Config._menuCloser = closer
	end
	Config._menuCloser.menu = menu
	Config._menuCloser:Show()
	menu:SetScript("OnHide", function() Config._menuCloser:Hide() end)
end
