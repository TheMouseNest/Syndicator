---@class addonTableSyndicator
local addonTable = select(2, ...)

function addonTable.Utilities.Message(text)
  print(NORMAL_FONT_COLOR:WrapTextInColorCode("Syndicator") .. ": " .. text)
end

do
  local callbacksPending = {}
  local frame = CreateFrame("Frame")
  frame:RegisterEvent("ADDON_LOADED")
  frame:SetScript("OnEvent", function(self, eventName, addonName)
    if callbacksPending[addonName] then
      for _, cb in ipairs(callbacksPending[addonName]) do
        cb()
      end
      callbacksPending[addonName] = nil
    end
  end)

  -- Necessary because cannot nest EventUtil.ContinueOnAddOnLoaded
  function addonTable.Utilities.OnAddonLoaded(addonName, callback)
    if select(2, C_AddOns.IsAddOnLoaded(addonName)) then
      callback()
    else
      callbacksPending[addonName] = callbacksPending[addonName] or {}
      table.insert(callbacksPending[addonName], callback)
    end
  end
end

function addonTable.Utilities.GetCharacterFullName()
  local characterName, realm = UnitFullName("player")
  return characterName .. "-" .. realm
end

if addonTable.Constants.IsClassic then
  local tooltip = CreateFrame("GameTooltip", "SyndicatorUtilitiesScanTooltip", nil, "GameTooltipTemplate")
  addonTable.Utilities.ScanningTooltip = tooltip
  tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

  function addonTable.Utilities.DumpClassicTooltip(tooltipSetter)
    if addonTable.Constants.IsBrokenTooltipScanning then
      return {lines = {}}
    end
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltipSetter(tooltip)

    local name = tooltip:GetName()
    local dump = {}

    local row = 1
    while _G[name .. "TextLeft" .. row] ~= nil do
      local leftFontString = _G[name .. "TextLeft" .. row]
      local rightFontString = _G[name .. "TextRight" .. row]

      local entry = {
        leftText = leftFontString:GetText(),
        leftColor = CreateColor(leftFontString:GetTextColor()),
        rightText = rightFontString:GetText(),
        rightColor = CreateColor(rightFontString:GetTextColor()),
      }
      if not rightFontString:IsShown() or entry.rightText == "" or entry.rightText == nil then
        entry.rightText = nil
        entry.rightColor = nil
      end
      if entry.leftText or entry.rightText then
        table.insert(dump, entry)
      end

      row = row + 1
    end

    return {lines = dump}
  end
end

local pendingItems = {}
local itemFrame = CreateFrame("Frame")
itemFrame.elapsed = 0
itemFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
itemFrame:SetScript("OnEvent", function(_, _, itemID)
  if pendingItems[itemID] ~= nil then
    for _, callback in ipairs(pendingItems[itemID]) do
      callback()
    end
    pendingItems[itemID] = nil
  end
end)
itemFrame.OnUpdate = function(self, elapsed)
  itemFrame.elapsed = itemFrame.elapsed + elapsed
  if itemFrame.elapsed > 0.4 then
    for itemID in pairs(pendingItems) do
      C_Item.RequestLoadItemDataByID(itemID)
    end
    itemFrame.elapsed = 0
  end

  if next(pendingItems) == nil then
    itemFrame.elapsed = 0
    self:SetScript("OnUpdate", nil)
    self:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
  end
end

function addonTable.Utilities.LoadItemData(itemID, callback)
  pendingItems[itemID] = pendingItems[itemID] or {}
  table.insert(pendingItems[itemID], callback)
  itemFrame:RegisterEvent("ITEM_DATA_LOAD_RESULT")
  itemFrame:SetScript("OnUpdate", itemFrame.OnUpdate)
  C_Item.RequestLoadItemDataByID(itemID)
end

local function SplitLink(linkString)
  return linkString:match("^(.*)|H(.-)|h(.*)$")
end

-- Get a key to group items in inventory summaries
function addonTable.Utilities.GetItemKey(itemLink)
  local pre, hyperlink, post = SplitLink(itemLink)

  local parts = { strsplit(":", hyperlink) }

  return parts[1] .. ":" .. parts[2]
end

function addonTable.Utilities.GetItemKeyByItemID(itemID)
  local classID, subClassID = select(6, C_Item.GetItemInfoInstant(itemID))
  if classID == Enum.ItemClass.Reagent and subClassID == Enum.ItemReagentSubclass.Keystone then
    return "keystone:" .. tostring(itemID)
  else
    return "item:" .. tostring(itemID)
  end
end

function addonTable.Utilities.IsEquipment(itemLink)
  local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemLink)
  return classID ~= nil and (
    -- Regular equipment
    classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon
    -- Profession equipment (retail only)
    or classID == Enum.ItemClass.Profession
  )
end

-- Order of parameters for the battle pet hyperlink string
local battlePetTooltip = {
  "battlePetSpeciesID",
  "battlePetLevel",
  "battlePetBreedQuality",
  "battlePetMaxHealth",
  "battlePetPower",
  "battlePetSpeed",
}

function addonTable.Utilities.MapPetReturnsToTooltipInfo(_, ...)
  local result = {}
  for index, entry in ipairs({...}) do
    if not battlePetTooltip[index] then
      break
    end
    result[battlePetTooltip[index]] = entry
  end

  return result
end

function addonTable.Utilities.RecoverBattlePetLink(tooltipInfo, itemLink, quality)
  if not tooltipInfo or not tooltipInfo[battlePetTooltip[1]] then
    return itemLink, quality
  end

  local itemString = "battlepet"
  for _, key in ipairs(battlePetTooltip) do
    itemString = itemString .. ":" .. tooltipInfo[key]
  end

  -- Add a nil GUID and displayID so that DressUpLink will preview the battle
  -- pet
  local speciesID = tonumber(tooltipInfo.battlePetSpeciesID)
  local displayID = select(12, C_PetJournal.GetPetInfoBySpeciesID(speciesID))
  itemString = itemString .. ":0000000000000000:" .. displayID

  local name = C_PetJournal.GetPetInfoBySpeciesID(tooltipInfo.battlePetSpeciesID)
  local quality = ITEM_QUALITY_COLORS[tooltipInfo.battlePetBreedQuality].color
  return quality:WrapTextInColorCode("|H" .. itemString .. "|h[" .. name .. "]|h"), tooltipInfo.battlePetBreedQuality
end

local cachedConnectedRealms = {}
function addonTable.Utilities.CacheConnectedRealms()
  cachedConnectedRealms = GetAutoCompleteRealms()
  if #cachedConnectedRealms == 0 then
    cachedConnectedRealms = {GetNormalizedRealmName()}
  end
end

function addonTable.Utilities.GetConnectedRealms()
  return cachedConnectedRealms
end

function addonTable.Utilities.RemoveCharacter(characterName)
  Syndicator.API.DeleteCharacter(characterName)
end

local genders = {"unknown", "male", "female"}
local raceCorrections = {
  ["scourge"] = "undead",
  ["zandalaritroll"] = "zandalari",
  ["highmountaintauren"] = "highmountain",
  ["lightforgeddraenei"] = "lightforged",
  ["earthendwarf"] = "earthen",
  ["harronir"] = "haranir"
}
local prefix
if addonTable.Constants.IsRetail then
  prefix = "raceicon128"
else
  prefix = "raceicon"
end
function addonTable.Utilities.GetCharacterIcon(race, sex)
  race = race:lower()
  return "|A:"..prefix.."-" .. (raceCorrections[race] or race) .. "-" .. genders[sex] .. ":13:13|a"
end
function addonTable.Utilities.GetGuildIcon()
  return "|A:communities-guildbanner-background:13:13|a"
end
function addonTable.Utilities.GetWarbandIcon()
  return "|A:warbands-icon:17:13|a"
end

Syndicator.Utilities.IsEquipment = addonTable.Utilities.IsEquipment
Syndicator.Utilities.GetCharacterIcon = addonTable.Utilities.GetCharacterIcon
Syndicator.Utilities.GetGuildIcon = addonTable.Utilities.GetGuildIcon
Syndicator.Utilities.GetWarbandIcon = addonTable.Utilities.GetWarbandIcon
Syndicator.Utilities.GetConnectedRealms = addonTable.Utilities.GetConnectedRealms

Syndicator.Utilities.DumpClassicTooltip = addonTable.Utilities.DumpClassicTooltip
