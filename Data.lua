-- SkillNotes Data: rotation & step CRUD over account-wide saved variables.
local addonName, ns = ...

local Data = {}
ns.Data = Data

local function newId()
	ns.DB.nextId = (ns.DB.nextId or 0) + 1
	return ns.DB.nextId
end

-- Create a rotation. Returns id or nil + error string.
function Data.CreateRotation(name)
	name = name and strtrim(name) or ""
	if name == "" then return nil, "Name cannot be empty." end
	for _, r in pairs(ns.DB.rotations) do
		if r.name == name then return nil, "A rotation named '" .. name .. "' already exists." end
	end
	local id = newId()
	ns.DB.rotations[id] = {
		id = id,
		name = name,
		dir = "HORIZONTAL",
		specID = nil,
		steps = {},
	}
	return id
end

function Data.GetRotation(id)
	return ns.DB.rotations[id]
end

function Data.GetRotationByName(name)
	if not name or name == "" then return nil end
	local lower = name:lower()
	for _, r in pairs(ns.DB.rotations) do
		if r.name:lower() == lower then return r end
	end
end

function Data.ListRotations()
	local list = {}
	for _, r in pairs(ns.DB.rotations) do list[#list + 1] = r end
	table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
	return list
end

function Data.RenameRotation(id, newName)
	newName = newName and strtrim(newName) or ""
	if newName == "" then return false, "Name cannot be empty." end
	for rid, r in pairs(ns.DB.rotations) do
		if rid ~= id and r.name == newName then return false, "Name already exists." end
	end
	local r = ns.DB.rotations[id]
	if not r then return false, "Rotation not found." end
	r.name = newName
	return true
end

function Data.DeleteRotation(id)
	if not ns.DB.rotations[id] then return false end
	ns.DB.rotations[id] = nil
	if ns.Overlay then ns.Overlay.DespawnByRotation(id) end
	return true
end

-- Steps ----------------------------------------------------------------------

function Data.AddStep(rotationId, step)
	local r = ns.DB.rotations[rotationId]
	if not r or not step or not step.fileID then return nil end
	r.steps[#r.steps + 1] = step
	return #r.steps
end

function Data.RemoveStep(rotationId, stepIndex)
	local r = ns.DB.rotations[rotationId]
	if not r then return false end
	if r.steps[stepIndex] then
		table.remove(r.steps, stepIndex)
		return true
	end
	return false
end

-- direction: -1 to move earlier, +1 to move later.
function Data.MoveStep(rotationId, stepIndex, direction)
	local r = ns.DB.rotations[rotationId]
	if not r then return false end
	local steps = r.steps
	local newIdx = stepIndex + direction
	if newIdx < 1 or newIdx > #steps then return false end
	steps[stepIndex], steps[newIdx] = steps[newIdx], steps[stepIndex]
	return true
end

function Data.SetStepLabel(rotationId, stepIndex, label)
	local r = ns.DB.rotations[rotationId]
	if not r or not r.steps[stepIndex] then return false end
	r.steps[stepIndex].label = (label and label ~= "") and label or nil
	return true
end

function Data.SetDirection(rotationId, dir)
	local r = ns.DB.rotations[rotationId]
	if not r then return false end
	r.dir = dir
	return true
end

function Data.SetSpec(rotationId, specID)
	local r = ns.DB.rotations[rotationId]
	if not r then return false end
	r.specID = specID -- nil = all specs
	return true
end
