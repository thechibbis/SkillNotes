-- SkillNotes Resolve: resolve spell/item icons once at authoring time.
-- All resolvers return an immutable step table {kind, id, fileID, name, label=nil}
-- or nil (+ the resolver never writes blanks: nil fileID => nil step).
local addonName, ns = ...

local Resolve = {}
ns.Resolve = Resolve

local function makeStep(kind, id, fileID, name)
	if not fileID or fileID == 0 then return nil end
	return {
		kind = kind,
		id = id,
		fileID = fileID,
		name = name or tostring(id),
		label = nil,
	}
end

-- Resolve a spell by spellID via the Midnight C_Spell namespace.
function Resolve.SpellByID(spellID)
	if type(spellID) ~= "number" then return nil end
	local fileID = C_Spell.GetSpellTexture(spellID)
	if not fileID then
		ns.Warn("No texture for spell " .. spellID .. ".")
		return nil
	end
	local name = C_Spell.GetSpellName(spellID) or tostring(spellID)
	return makeStep("spell", spellID, fileID, name)
end

-- Resolve an item by itemID via the C_Item namespace.
function Resolve.ItemByID(itemID)
	if type(itemID) ~= "number" then return nil end
	local fileID = C_Item.GetItemIconByID(itemID)
	if not fileID then
		ns.Warn("No icon for item " .. itemID .. ".")
		return nil
	end
	local name = (C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)) or GetItemInfo(itemID) or tostring(itemID)
	return makeStep("item", itemID, fileID, name)
end

-- Custom-ID field: try spell first, then fall back to item.
function Resolve.CustomID(id)
	if type(id) == "string" then id = tonumber(strtrim(id)) end
	if type(id) ~= "number" then return nil, "ID must be numeric." end
	local step = Resolve.SpellByID(id)
	if step then return step end
	step = Resolve.ItemByID(id)
	if step then return step end
	return nil, "No spell or item found with ID " .. id .. "."
end

-- Spellbook drag: read the cursor, prefer the spellbook-context lookup,
-- fall back to spellID-based resolution if the slot index is stale.
function Resolve.SpellByCursor()
	local infoType, spellIndex, bookType, spellID = GetCursorInfo()
	if infoType ~= "spell" or not spellID then
		return nil, "No spell on the cursor."
	end
	local step
	if spellIndex and bookType then
		local bank = (bookType == "pet") and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
		local info = C_SpellBook.GetSpellBookItemInfo(spellIndex, bank)
		if info and info.iconID then
			step = makeStep("spell", spellID, info.iconID, info.name)
		end
	end
	if not step then
		step = Resolve.SpellByID(spellID)
	end
	if not step then
		return nil, "Could not resolve spell " .. tostring(spellID) .. "."
	end
	ClearCursor()
	return step
end
