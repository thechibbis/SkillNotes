-- SkillNotes Overlay: in-world display of a rotation as a row/column of icons.
-- Display-only: no click-to-cast, no combat-data reads. Icons render from cached
-- fileIDs only — never re-query C_Spell/C_Item at display time.
local addonName, ns = ...

local Overlay = {}
ns.Overlay = Overlay

-- live overlay frames keyed by overlayId (this session only)
local frames = {}

local PLAYER_UNIT = "player"

-- Is this overlay currently allowed by its rotation's spec-gate?
local function passesSpecGate(rotation)
    if not rotation or rotation.specID == nil then return true end
    local currentSpec = GetSpecialization and GetSpecialization() or nil
    local specInfo = currentSpec and GetSpecializationInfo(currentSpec)
    return rotation.specID == nil or rotation.specID == specInfo
end

local function nextOverlayId()
    ns.CharDB.nextOverlayId = (ns.CharDB.nextOverlayId or 0) + 1
    return ns.CharDB.nextOverlayId
end

-- Build/rebuild the icon children for an overlay frame.
-- Pools icon frames across relayouts to avoid leaking widgets (layout runs on
-- every step edit / setting change; recreating each time would orphan hundreds
-- of frames after a few minutes of editing).
local function layout(frame)
    local rotation = ns.DB.rotations[frame.rotationId]
    if not rotation then
        frame:Hide()
        return
    end

    local isHorz = rotation.dir ~= "VERTICAL"
    local size = frame.settings.iconSize
    local gap = frame.settings.spacing
    local steps = rotation.steps
    local n = #steps


    frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.Text:SetPoint("CENTER", frame, "TOP", 0, 0)
    frame.Text:SetText(rotation.name or "")

    frame.icons = frame.icons or {}
    -- Grow pool if needed; reuse existing frames, hide extras.
    for i = 1, math.max(n, #frame.icons) do
        local icon = frame.icons[i]
        if i <= n then
            if not icon then
                icon = CreateFrame("Frame", nil, frame)
                icon:EnableMouse(true)
                icon.tex = icon:CreateTexture(nil, "ARTWORK")
                icon.tex:SetAllPoints()
                icon:SetScript("OnEnter", function(_self)
                    GameTooltip:SetOwner(_self, "ANCHOR_RIGHT")
                    local step = steps[i]
                    GameTooltip:SetText(step.name or "?", 1, 1, 1)
                    GameTooltip:AddLine("Type: " .. step.kind, 0.6, 0.8, 1)
                    GameTooltip:AddLine("ID: " .. tostring(step.id), 0.5, 0.5, 0.5)
                    GameTooltip:Show()
                end)
                icon:SetScript("OnLeave", function(_self) GameTooltip:Hide() end)
                frame.icons[i] = icon
            end
            icon:SetSize(size, size)
            if isHorz then
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", frame, "LEFT", (i - 1) * (size + gap), 0)
            else
                icon:ClearAllPoints()
                icon:SetPoint("TOP", frame, "TOP", 0, -((i - 1) * (size + gap)))
            end
            local step = steps[i]
            icon.tex:SetTexture(step.fileID)
            -- Caption: reuse or create the FontString.
            if step.label and step.label ~= "" then
                if not icon.label then
                    icon.label = icon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                end
                if isHorz then
                    icon.label:ClearAllPoints()
                    icon.label:SetPoint("TOP", icon, "BOTTOM", 0, -2)
                else
                    icon.label:ClearAllPoints()
                    icon.label:SetPoint("RIGHT", icon, "LEFT", -2, 0)
                end
                icon.label:SetText(step.label)
                icon.label:Show()
            elseif icon.label then
                icon.label:Hide()
            end
            icon:Show()
        elseif icon then
            icon:Hide()
        end
    end

    if n == 0 then
        frame:SetSize(size, size)
    else
        local span = n * size + (n - 1) * gap
        if isHorz then
            frame:SetSize(math.max(size, span), size + 20)
        else
            frame:SetSize(size + 20, math.max(size, span))
        end
    end
end

local function applySettings(frame)
    frame:SetAlpha(frame.settings.alpha or 1.0)
    -- Border shown only when unlocked (edit mode).
    if frame.settings.locked then
        frame.bg:Hide()
    else
        frame.bg:Show()
    end
end

local function savePosition(frame)
    local point, _, relPoint, x, y = frame:GetPoint(1)
    if not point then return end
    local data = ns.CharDB.overlays[frame.overlayId]
    if data then
        data.point = point
        data.relPoint = relPoint
        data.x = x
        data.y = y
    end
end

local function makeFrame(overlayId, rotationId, settings, anchor)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame.overlayId = overlayId
    frame.rotationId = rotationId
    frame.settings = settings
    frame.icons = {}

    -- Subtle backdrop so unlocked overlays are grabbable/visible.
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.3)

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(_self)
        if _self.settings.locked then return end
        _self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(_self)
        _self:StopMovingOrSizing()
        savePosition(_self)
    end)

    frame:SetScript("OnEnter", function(_self)
        GameTooltip:SetOwner(_self, "ANCHOR_TOPLEFT")
        local r = ns.DB.rotations[_self.rotationId]
        GameTooltip:SetText(r and r.name or "SkillNotes", 1, 1, 1)
        GameTooltip:AddLine("Right-click for options.", 0.6, 0.8, 1)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(_self) GameTooltip:Hide() end)

    -- Right-click context menu (size / spacing / alpha / direction / lock / delete).
    -- Plain Frames don't have RegisterForClicks/OnClick; use OnMouseDown instead.
    frame:SetScript("OnMouseDown", function(_self, button)
        if button ~= "RightButton" then return end
        ns.Config.OpenOverlayMenu(_self)
    end)

    if anchor then
        frame:SetPoint(anchor.point, UIParent, anchor.relPoint, anchor.x, anchor.y)
    else
        frame:SetPoint("CENTER")
    end

    layout(frame)
    applySettings(frame)

    frames[overlayId] = frame
    return frame
end

-- Spawn a new overlay for a rotation. If nearCursor, anchor at cursor.
function Overlay.Spawn(rotationId, nearCursor)
    local rotation = ns.DB.rotations[rotationId]
    if not rotation then return nil end
    if not passesSpecGate(rotation) then
        ns.Print("Rotation '" ..
            rotation.name .. "' is spec-gated to your inactive spec; overlay hidden until you switch.")
    end
    local id = nextOverlayId()
    local settings = {
        iconSize = ns.defaults.iconSize,
        spacing = ns.defaults.spacing,
        alpha = ns.defaults.alpha,
        locked = false,
    }
    local anchor = { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT" }
    if nearCursor then
        local scale = UIParent:GetEffectiveScale()
        local mx, my = GetCursorPosition()
        anchor.x, anchor.y = mx / scale - 40, my / scale - 40
    else
        anchor.x, anchor.y = 200, 200
    end
    ns.CharDB.overlays[id] = {
        id = id,
        rotationId = rotationId,
        settings = settings,
        point = anchor.point,
        relPoint = anchor.relPoint,
        x = anchor.x,
        y = anchor.y,
        locked = false,
    }
    local frame = makeFrame(id, rotationId, settings, anchor)
    if not passesSpecGate(rotation) then frame:Hide() end
    return frame
end

-- Restore all saved overlays for this character on login.
function Overlay.RestoreAll()
    for overlayId, data in pairs(ns.CharDB.overlays) do
        local rotation = ns.DB.rotations[data.rotationId]
        if rotation then
            local anchor = { point = data.point, relPoint = data.relPoint, x = data.x, y = data.y }
            local frame = makeFrame(overlayId, data.rotationId, data.settings, anchor)
            if not passesSpecGate(rotation) then frame:Hide() end
        else
            -- Rotation was deleted (shouldn't happen — DeleteRotation cleans up,
            -- but guard against stale data after a content/patch change).
            ns.CharDB.overlays[overlayId] = nil
        end
    end
end

-- Despawn all overlays bound to a rotation (used on rotation deletion).
function Overlay.DespawnByRotation(rotationId)
    for overlayId, frame in pairs(frames) do
        if frame.rotationId == rotationId then
            frame:Hide()
            frame:GetParent():SetScript("OnUpdate", nil)
            frames[overlayId] = nil
            ns.CharDB.overlays[overlayId] = nil
        end
    end
end

-- Remove all overlays for this character (and their saved data).
function Overlay.DespawnAll()
    for overlayId, frame in pairs(frames) do
        frame:Hide()
        frames[overlayId] = nil
    end
    wipe(ns.CharDB.overlays)
    ns.CharDB.overlays = {}
end

-- Re-render every live overlay bound to a rotation (used after config edits).
function Overlay.RefreshByRotation(rotationId)
    for _, frame in pairs(frames) do
        if frame.rotationId == rotationId then
            layout(frame)
            local rotation = ns.DB.rotations[rotationId]
            if rotation and not passesSpecGate(rotation) then
                frame:Hide()
            else
                frame:Show()
            end
        end
    end
end

-- Toggle edit mode (unlock/lock all overlays at once).
function Overlay.SetAllLocked(locked)
    for overlayId, frame in pairs(frames) do
        frame.settings.locked = locked
        ns.CharDB.overlays[overlayId].locked = locked
        applySettings(frame)
    end
end

function Overlay.GetAllFrames()
    return frames
end

-- Context-menu helpers (called by Config.OpenOverlayMenu).
function Overlay.GetFrame(overlayId) return frames[overlayId] end

function Overlay.Delete(overlayId)
    local frame = frames[overlayId]
    if frame then
        frame:Hide()
        frames[overlayId] = nil
    end
    ns.CharDB.overlays[overlayId] = nil
end

function Overlay.Relayout(overlayId)
    local frame = frames[overlayId]
    if frame then
        layout(frame)
        applySettings(frame)
    end
end

-- Re-evaluate spec-gates on all live overlays.
function Overlay.ReevaluateSpecGates()
    for _, frame in pairs(frames) do
        local rotation = ns.DB.rotations[frame.rotationId]
        if rotation then
            if passesSpecGate(rotation) then frame:Show() else frame:Hide() end
        end
    end
end

ns.OnDBReady(function()
    -- Restore saved overlays once both DBs and the player are available.
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self)
        Overlay.RestoreAll()
        self:UnregisterEvent("PLAYER_LOGIN")
    end)
    -- Spec-gating: re-evaluate when the player changes specialization.
    local spec = CreateFrame("Frame")
    spec:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", PLAYER_UNIT)
    spec:SetScript("OnEvent", function()
        Overlay.ReevaluateSpecGates()
    end)
end)
