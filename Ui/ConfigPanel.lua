-- SkillNotes Config panel: main authoring window (rotation list, step list,
-- settings pane, drop zone, custom-ID entry).
local addonName, ns = ...

local Config = ns.Config

-- Layout constants
local WIN_W, WIN_H = 1024, 460
local LEFT_W = 220
local RIGHT_W = 220
local PADDING = 8

-- Build the main config window once; reuse on subsequent opens.
local function ensureFrame()
    if Config.mainFrame then return Config.mainFrame end

    local f = CreateFrame("Frame", "SkillNotesConfigFrame", UIParent, "BackdropTemplate")
    f:SetSize(WIN_W, WIN_H)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropBorderColor(0.4, 0.4, 0.4)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:SetFrameStrata("DIALOG")
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("SkillNotes")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

    -- Three panes
    local left = CreateFrame("Frame", nil, f, "BackdropTemplate")
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -40)
    left:SetSize(LEFT_W, WIN_H - 60)
    left:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    left:SetBackdropColor(0, 0, 0, 0.2)

    local center = CreateFrame("Frame", nil, f, "BackdropTemplate")
    center:SetPoint("TOPLEFT", left, "TOPRIGHT", PADDING, 0)
    center:SetPoint("TOPRIGHT", f, "TOPRIGHT", -RIGHT_W - 24, -40)
    center:SetHeight(WIN_H - 60)
    center:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    center:SetBackdropColor(0, 0, 0, 0.15)

    local right = CreateFrame("Frame", nil, f, "BackdropTemplate")
    right:SetPoint("TOPLEFT", center, "TOPRIGHT", PADDING, 0)
    right:SetSize(RIGHT_W - PADDING, WIN_H - 60)
    right:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    right:SetBackdropColor(0, 0, 0, 0.2)

    f.left, f.center, f.right = left, center, right

    -- Left pane: New button + scrollable list
    local newBtn = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    newBtn:SetSize(LEFT_W - 16, 22)
    newBtn:SetPoint("TOPLEFT", left, "TOPLEFT", 8, -8)
    newBtn:SetText("New Rotation")
    newBtn:SetScript("OnClick", function() Config.NewRotationPrompt() end)
    f.newBtn = newBtn

    local delBtn = CreateFrame("Button", nil, left, "UIPanelButtonTemplate")
    delBtn:SetSize(LEFT_W - 16, 22)
    delBtn:SetPoint("TOPLEFT", newBtn, "BOTTOMLEFT", 0, -4)
    delBtn:SetText("Delete")
    delBtn:SetScript("OnClick", function()
        if Config.selectedRotationId then Config.DeleteRotationPrompt(Config.selectedRotationId) end
    end)
    f.delBtn = delBtn

    local scroll = CreateFrame("ScrollFrame", nil, left, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", delBtn, "BOTTOMLEFT", 0, -8)
    scroll:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -28, 8)
    f.scroll = scroll

    local list = CreateFrame("Frame", nil, scroll)
    list:SetSize(LEFT_W - 32, 1)
    scroll:SetScrollChild(list)
    f.list = list

    -- Center pane: step list + drop zone + custom-ID row (populated on select)
    -- RegisterForDrag is required on the drop target for OnReceiveDrag to fire.
    center:SetScript("OnReceiveDrag", function() Config.ReceiveDrop() end)
    center:EnableMouse(true)
    center:RegisterForDrag("LeftButton")
    -- Right pane: rotation settings (direction / spec) populated on select
    f.dirLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.dirLabel:SetPoint("TOPLEFT", right, "TOPLEFT", 12, -12)
    f.dirLabel:SetText("Direction")

    f.dirBtn = CreateFrame("Button", nil, right, "UIPanelButtonTemplate")
    f.dirBtn:SetSize(RIGHT_W - 24, 22)
    f.dirBtn:SetPoint("TOPLEFT", f.dirLabel, "BOTTOMLEFT", 0, -4)
    f.dirBtn:SetScript("OnClick", function()
        if not Config.selectedRotationId then return end
        local r = ns.Data.GetRotation(Config.selectedRotationId)
        if not r then return end
        ns.Data.SetDirection(Config.selectedRotationId, r.dir == "HORIZONTAL" and "VERTICAL" or "HORIZONTAL")
        Config.Refresh()
        ns.Overlay.RefreshByRotation(Config.selectedRotationId)
    end)

    f.specLabel = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.specLabel:SetPoint("TOPLEFT", f.dirBtn, "BOTTOMLEFT", 0, -12)
    f.specLabel:SetText("Spec")

    f.specBtn = CreateFrame("Button", nil, right, "UIPanelButtonTemplate")
    f.specBtn:SetSize(RIGHT_W - 24, 22)
    f.specBtn:SetPoint("TOPLEFT", f.specLabel, "BOTTOMLEFT", 0, -4)
    f.specBtn:SetScript("OnClick", function()
        if not Config.selectedRotationId then return end
        local r = ns.Data.GetRotation(Config.selectedRotationId)
        if not r then return end
        -- Toggle between nil (all) and current spec.
        if r.specID == nil then
            local cur = GetSpecialization and GetSpecialization()
            r.specID = cur and GetSpecializationInfo(cur) or nil
        else
            r.specID = nil
        end
        ns.Overlay.ReevaluateSpecGates()
        Config.Refresh()
    end)

    -- Place an in-world overlay bound to the selected rotation.
    f.placeBtn = CreateFrame("Button", nil, right, "UIPanelButtonTemplate")
    f.placeBtn:SetSize(RIGHT_W - 24, 22)
    f.placeBtn:SetPoint("TOPLEFT", f.specBtn, "BOTTOMLEFT", 0, -12)
    f.placeBtn:SetText("Place Overlay")
    f.placeBtn:SetScript("OnClick", function()
        if not Config.selectedRotationId then return end
        local r = ns.Data.GetRotation(Config.selectedRotationId)
        if not r then return end
        -- pcall so any error surfaces in chat instead of being silently swallowed.
        local ok, err = pcall(ns.Overlay.Spawn, r.id, true)
        if not ok then
            ns.Print("Error placing overlay: " .. tostring(err))
        end
    end)
    -- Custom-ID entry row (lives at the bottom of the center pane).
    local idLabel = center:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    idLabel:SetPoint("BOTTOMLEFT", center, "BOTTOMLEFT", 12, 12)
    idLabel:SetText("Spell/Item ID:")
    f.idLabel = idLabel

    local idEdit = CreateFrame("EditBox", nil, center, "InputBoxTemplate")
    idEdit:SetSize(80, 20)
    idEdit:SetPoint("LEFT", idLabel, "RIGHT", 8, 0)
    idEdit:SetAutoFocus(false)
    idEdit:SetNumeric(true)
    idEdit:SetMaxLetters(8)
    f.idEdit = idEdit

    local addBtn = CreateFrame("Button", nil, center, "UIPanelButtonTemplate")
    addBtn:SetSize(70, 22)
    addBtn:SetPoint("LEFT", idEdit, "RIGHT", 8, 0)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", function() Config.AddCustomFromEditBox() end)
    idEdit:SetScript("OnEnterPressed", function() Config.AddCustomFromEditBox() end)
    f.addBtn = addBtn

    -- Drop-zone hint
    local dropHint = center:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    dropHint:SetPoint("CENTER", center, "CENTER", 0, 20)
    dropHint:SetText("Drag spells from your spellbook here\n— or —\nEnter a Spell/Item ID below")
    dropHint:SetJustifyH("CENTER")
    f.dropHint = dropHint

    Config.mainFrame = f
    return f
end

-- Selecting a rotation populates the center and right panes.
function Config.Select(id)
    Config.selectedRotationId = id
    Config.Refresh()
end

-- Re-render the left list, the center step list, and the right settings.
-- Pools child frames across refreshes to avoid orphaning widgets.
function Config.Refresh()
    local f = ensureFrame()
    f.list = f.list -- ensure field exists
    f.list.children = f.list.children or {}
    local listPool = f.list.children
    local rotations = ns.Data.ListRotations()
    local y = 0
    for i, r in ipairs(rotations) do
        local btn = listPool[i]
        if not btn then
            btn = CreateFrame("Button", nil, f.list, "UIPanelButtonTemplate")
            btn:SetSize(LEFT_W - 32, 22)
            btn:SetScript("OnClick", function() Config.Select(r.id) end)
            listPool[i] = btn
        end
        btn:SetPoint("TOPLEFT", f.list, "TOPLEFT", 0, -y)
        btn:SetText(r.name)
        -- Re-bind click in case rotation id changed in a pooled slot.
        btn:SetScript("OnClick", function() Config.Select(r.id) end)
        if r.id == Config.selectedRotationId then btn:LockHighlight() else btn:UnlockHighlight() end
        btn:Show()
        y = y + 26
    end
    for i = #rotations + 1, #listPool do listPool[i]:Hide() end
    f.list:SetHeight(math.max(1, y))

    -- Center pane: render steps for the selected rotation.
    -- Pool row frames across refreshes (rebuilds fire on every label edit /
    -- reorder / remove) to avoid orphaning widgets.
    f.center.children = f.center.children or {}
    local centerPool = f.center.children
    -- Hide all pooled rows first; we re-show the ones we use.
    for _, child in ipairs(centerPool) do child:Hide() end

    local poolIdx = 1
    local function acquireRow()
        local row = centerPool[poolIdx]
        if not row then
            row = CreateFrame("Frame", nil, f.center)
            row:SetSize(f.center:GetWidth() - 24, 44)
            --
            row.tex = row:CreateTexture(nil, "ARTWORK")
            row.tex:SetSize(32, 32)
            row.tex:SetPoint("LEFT", row, "LEFT", 0, 0)
            --
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.name:SetPoint("LEFT", row.tex, "RIGHT", 8, 0)
            --
            row.lbl = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
            row.lbl:SetSize(120, 20)
            row.lbl:SetPoint("LEFT", row.name, "RIGHT", 12, 0)
            row.lbl:SetAutoFocus(false)
            --
            row.back = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.back:SetSize(24, 22)
            row.back:SetPoint("RIGHT", row, "RIGHT", -56, 0)
            --
            row.fwd = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.fwd:SetSize(24, 22)
            row.fwd:SetPoint("LEFT", row.back, "RIGHT", 4, 0)
            --
            row.rem = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.rem:SetSize(24, 22)
            row.rem:SetPoint("LEFT", row.fwd, "RIGHT", 4, 0)
            row.rem:SetText("×")
            --
            centerPool[poolIdx] = row
        end
        poolIdx = poolIdx + 1
        return row
    end

    local rotation = Config.selectedRotationId and ns.Data.GetRotation(Config.selectedRotationId)
    if not rotation then
        f.dropHint:Show()
    else
        f.dropHint:Hide()
        local isHorz = rotation.dir ~= "VERTICAL"
        local stepY = 8

        local header = acquireRow()
        -- Header is a FontString-style row: reuse the name field, hide others.
        header.tex:Hide()
        header.lbl:Hide()
        header.back:Hide()
        header.fwd:Hide()
        header.rem:Hide()
        header.name:SetFontObject("GameFontNormalLarge")
        header.name:ClearAllPoints()
        header.name:SetPoint("TOPLEFT", header, "TOPLEFT", 0, 0)
        header.name:SetText(rotation.name)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", f.center, "TOPLEFT", 12, -stepY)
        header:Show()
        stepY = stepY + 28

        for i, step in ipairs(rotation.steps) do
            local row = acquireRow()
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", f.center, "TOPLEFT", 12, -stepY)
            row.tex:Show()
            row.tex:SetTexture(step.fileID)
            row.name:SetFontObject("GameFontHighlightSmall")
            row.name:ClearAllPoints()
            row.name:SetPoint("LEFT", row.tex, "RIGHT", 8, 0)
            row.name:SetText(step.name)
            row.lbl:Show()
            row.lbl:SetText(step.label or "")
            -- Bind handlers to the current step index (closures capture `i`).
            row.lbl:SetScript("OnEnterPressed", function(_self)
                ns.Data.SetStepLabel(Config.selectedRotationId, i, _self:GetText())
                _self:ClearFocus()
                ns.Overlay.RefreshByRotation(Config.selectedRotationId)
            end)
            row.lbl:SetScript("OnEditFocusLost", function(_self)
                ns.Data.SetStepLabel(Config.selectedRotationId, i, _self:GetText())
                ns.Overlay.RefreshByRotation(Config.selectedRotationId)
            end)
            row.back:Show()
            row.back:SetText(isHorz and "◀" or "▲")
            row.back:SetScript("OnClick", function()
                ns.Data.MoveStep(Config.selectedRotationId, i, -1)
                Config.Refresh()
                ns.Overlay.RefreshByRotation(Config.selectedRotationId)
            end)
            row.fwd:Show()
            row.fwd:SetText(isHorz and "▶" or "▼")
            row.fwd:SetScript("OnClick", function()
                ns.Data.MoveStep(Config.selectedRotationId, i, 1)
                Config.Refresh()
                ns.Overlay.RefreshByRotation(Config.selectedRotationId)
            end)
            row.rem:Show()
            row.rem:SetScript("OnClick", function()
                ns.Data.RemoveStep(Config.selectedRotationId, i)
                Config.Refresh()
                ns.Overlay.RefreshByRotation(Config.selectedRotationId)
            end)
            row:Show()
            stepY = stepY + 48
        end
    end

    -- Right pane: settings labels
    local rotation2 = Config.selectedRotationId and ns.Data.GetRotation(Config.selectedRotationId)
    if rotation2 then
        f.dirBtn:SetText(rotation2.dir == "VERTICAL" and "Vertical" or "Horizontal")
        if rotation2.specID == nil then
            f.specBtn:SetText("All Specs")
        else
            local cur = GetSpecialization and GetSpecialization()
            local name = cur and select(2, GetSpecializationInfo(cur)) or "Spec " .. tostring(rotation2.specID)
            f.specBtn:SetText("Spec: " .. name)
        end
    else
        f.dirBtn:SetText("—")
        f.specBtn:SetText("—")
    end
    f.placeBtn:SetEnabled(rotation2 ~= nil)
end

function Config.Open()
    local f = ensureFrame()
    Config.Refresh()
    f:Show()
end

-- Receive a spell dragged from the spellbook onto the center pane.
function Config.ReceiveDrop()
    if not Config.selectedRotationId then
        ns.Warn("Select or create a rotation first.")
        return
    end
    local step, err = ns.Resolve.SpellByCursor()
    if not step then
        ns.Warn(err or "Could not add that spell.")
        return
    end
    ns.Data.AddStep(Config.selectedRotationId, step)
    Config.Refresh()
    ns.Overlay.RefreshByRotation(Config.selectedRotationId)
end

-- Custom-ID field submit handler.
function Config.AddCustomFromEditBox()
    if not Config.selectedRotationId then
        ns.Warn("Select or create a rotation first.")
        return
    end
    local f = Config.mainFrame
    local text = f.idEdit:GetText()
    if not text or text == "" then return end
    local step, err = ns.Resolve.CustomID(text)
    if not step then
        ns.Warn(err or "Could not resolve that ID.")
        return
    end
    ns.Data.AddStep(Config.selectedRotationId, step)
    f.idEdit:SetText("")
    Config.Refresh()
    ns.Overlay.RefreshByRotation(Config.selectedRotationId)
end
