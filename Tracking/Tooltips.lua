---@class addonTableSyndicator
local addonTable = select(2, ...)

addonTable.Tooltips = {}

local LibBattlePetTooltipLine = LibStub("LibBattlePetTooltipLine-1-0")

local function CharacterAndRealmComparator(a, b)
  if a.realmNormalized == b.realmNormalized then
    return a.character < b.character
  else
    return a.realmNormalized < b.realmNormalized
  end
end

local function GuildAndRealmComparator(a, b)
  if a.realmNormalized == b.realmNormalized then
    return a.guild < b.guild
  else
    return a.realmNormalized < b.realmNormalized
  end
end

local function IsBoA(itemLink)
  if itemLink:match("battlepet:") then
    return true
  end

  local tooltipData
  if addonTable.Constants.IsClassic then
    tooltipData = addonTable.Utilities.DumpClassicTooltip(function(tooltip) tooltip:SetHyperlink(itemLink) end)
  else
    tooltipData = C_TooltipInfo.GetHyperlink(itemLink)
  end

  if not tooltipData then
    return false
  end

  for _, line in ipairs(tooltipData.lines) do
    if tIndexOf(addonTable.Constants.AccountBoundTooltipLines, line.leftText) ~= nil then
      return true
    end
  end

  return false
end

function addonTable.Tooltips.AddItemLines(tooltip, summaries, itemLink)
  if itemLink == nil then
    return
  end

  local success, key = pcall(addonTable.Utilities.GetItemKey, itemLink)

  if not success then
    return
  end

  local connectedRealmsOnly = addonTable.Config.Get("tooltips_connected_realms_only_2")
  local factionOnly = addonTable.Config.Get("tooltips_faction_only")
  if IsBoA(itemLink) then
    connectedRealmsOnly = false
    factionOnly = false
  end
  local tooltipInfo = summaries:GetTooltipInfo(key, connectedRealmsOnly, factionOnly)

  -- Remove any equipped information from the tooltip if the option is disabled
  -- (and remove the character if it has none of the items not equipped)
  if not addonTable.Config.Get("show_equipped_items_in_tooltips") then
    for _, char in ipairs(tooltipInfo.characters) do
      char.equipped = 0
    end
  end

  if addonTable.Config.Get("tooltips_sort_by_name") then
    table.sort(tooltipInfo.characters, CharacterAndRealmComparator)
    table.sort(tooltipInfo.guilds, GuildAndRealmComparator)
  else
    table.sort(tooltipInfo.characters, function(a, b)
      local left = a.bags + a.bank + a.mail + a.equipped + a.void + a.auctions
      local right = b.bags + b.bank + b.mail + b.equipped + b.void + b.auctions
      if left == right then
        return CharacterAndRealmComparator(a, b)
      else
        return left > right
      end
    end)
    table.sort(tooltipInfo.guilds, function(a, b)
      if a.bank == b.bank then
        return GuildAndRealmComparator(a, b)
      else
        return a.bank > b.bank
      end
    end)
  end

  if not addonTable.Config.Get(addonTable.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS) then
    tooltipInfo.guilds = {}
  end

  if #tooltipInfo.characters == 0 and #tooltipInfo.guilds == 0 and tooltipInfo.warband[1] == 0 then
    return
  end

  -- Used to ease adding to battle pet tooltip which doesn't have AddDoubleLine
  local function AddDoubleLine(left, right, ...)
    if tooltip.AddDoubleLine then
      tooltip:AddDoubleLine(left, right, ...)
    elseif tooltip.PetType then
      LibBattlePetTooltipLine:AddDoubleLine(tooltip, left, right)
    end
  end

  local result = "  "
  local totals = 0
  local seenRealms = {}

  for index, s in ipairs(tooltipInfo.characters) do
    totals = totals + s.bags + s.bank + s.mail + s.equipped + s.void + s.auctions
    seenRealms[s.realmNormalized] = true
  end
  for index, s in ipairs(tooltipInfo.guilds) do
    totals = totals + s.bank
    seenRealms[s.realmNormalized] = true
  end
  totals = totals + tooltipInfo.warband[1]
  seenRealms[GetNormalizedRealmName() or ""] = true -- ensure realm name is shown for a different realm

  local realmCount = 0
  for realm in pairs(seenRealms) do
    realmCount = realmCount + 1
  end
  local appendRealm = false
  if realmCount > 1 then
    appendRealm = true
  end

  if totals == 0 then
    return
  end

  local blankLineAdded = false
  if addonTable.Config.Get(addonTable.Config.Options.SHOW_BLANK_LINE_BEFORE_INVENTORY) then
    tooltip:AddLine(" ")
    blankLineAdded = true
  end

  if not addonTable.Config.Get(addonTable.Config.Options.SHOW_TOTAL_LINE_AFTER_CHARACTERS) then
    AddDoubleLine(addonTable.Locales.INVENTORY, LINK_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.TOTAL_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(totals))))
  end

  local currentCharacter = UnitName("player")
  local currentRealm = GetNormalizedRealmName()
  local charactersToShow = {}
  for _, s in ipairs(tooltipInfo.characters) do
    if addonTable.Config.Get(addonTable.Config.Options.ALWAYS_SHOW_CURRENT_CHARACTER) and s.character == currentCharacter and s.realmNormalized == currentRealm then
      table.insert(charactersToShow, 1, s)
    else
      table.insert(charactersToShow, s)
    end
  end

  local charactersShown = 0
  for _, s in ipairs(charactersToShow) do
    local entries = {}
    if s.bags > 0 then
      table.insert(entries, addonTable.Locales.BAGS_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.bags)))
    end
    if s.bank > 0 then
      table.insert(entries, addonTable.Locales.BANK_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.bank)))
    end
    if s.mail > 0 then
      table.insert(entries, addonTable.Locales.MAIL_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.mail)))
    end
    if s.equipped > 0 then
      table.insert(entries, addonTable.Locales.EQUIPPED_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.equipped)))
    end
    if s.void > 0 then
      table.insert(entries, addonTable.Locales.VOID_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.void)))
    end
    if s.auctions > 0 then
      table.insert(entries, addonTable.Locales.AUCTIONS_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.auctions)))
    end
    local character = s.character
    if appendRealm then
      character = character .. "-" .. s.realmNormalized
    end
    if s.className then
      character = "|c" .. (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[s.className].colorStr .. character .. "|r"
    end
    if addonTable.Config.Get(addonTable.Config.Options.SHOW_CHARACTER_RACE_ICONS) and s.race then
      character = addonTable.Utilities.GetCharacterIcon(s.race, s.sex) .. " " .. character
    end
    if #entries > 0 then
      if charactersShown >= addonTable.Config.Get("tooltips_character_limit") then
        tooltip:AddLine("  ...")
        break
      end
      AddDoubleLine("  " .. character, LINK_FONT_COLOR:WrapTextInColorCode(strjoin(", ", unpack(entries))))
      charactersShown = charactersShown + 1
    end
  end

  for index = 1, math.min(#tooltipInfo.guilds, addonTable.Config.Get("tooltips_character_limit")) do
    local s = tooltipInfo.guilds[index]
    local output = addonTable.Locales.GUILD_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(s.bank))
    local guild = TRANSMOGRIFY_FONT_COLOR:WrapTextInColorCode(s.guild)
    if appendRealm then
      guild = guild .. "-" .. s.realmNormalized
    end
    if addonTable.Config.Get(addonTable.Config.Options.SHOW_CHARACTER_RACE_ICONS) then
      guild = addonTable.Utilities.GetGuildIcon() .. " " .. guild
    end
    AddDoubleLine("  " .. guild, LINK_FONT_COLOR:WrapTextInColorCode(output))
  end
  if #tooltipInfo.guilds > addonTable.Config.Get("tooltips_character_limit") then
    tooltip:AddLine("  ...")
  end
  if tooltipInfo.warband[1] > 0 then
    local icon = ""
    if addonTable.Config.Get(addonTable.Config.Options.SHOW_CHARACTER_RACE_ICONS) then
      icon = addonTable.Utilities.GetWarbandIcon() .. " "
    end
    AddDoubleLine("  " .. icon .. PASSIVE_SPELL_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.WARBAND), LINK_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.BANK_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(tooltipInfo.warband[1]))))
  end

  if addonTable.Config.Get(addonTable.Config.Options.SHOW_TOTAL_LINE_AFTER_CHARACTERS) then
    if addonTable.Config.Get(addonTable.Config.Options.SHOW_BLANK_LINE_BEFORE_INVENTORY) and not blankLineAdded then
      tooltip:AddLine(" ")
    end
    AddDoubleLine(addonTable.Locales.INVENTORY, LINK_FONT_COLOR:WrapTextInColorCode(addonTable.Locales.TOTAL_X:format(WHITE_FONT_COLOR:WrapTextInColorCode(totals))))
  end

  if addonTable.Constants.IsClassic then
    tooltip:Show()
  end
end

function addonTable.Tooltips.AddCurrencyLines(tooltip, currencyID)
  if tIndexOf(addonTable.Constants.SharedCurrencies, currencyID) ~= nil then
    return
  end

  local summary = addonTable.Tracking.GetCurrencyTooltipData(currencyID, addonTable.Config.Get("tooltips_connected_realms_only_2"), addonTable.Config.Get("tooltips_faction_only"))

  if addonTable.Config.Get("tooltips_sort_by_name") then
    table.sort(summary, CharacterAndRealmComparator)
  else
    table.sort(summary, function(a, b)
      if a.quantity == b.quantity then
        return CharacterAndRealmComparator(a, b)
      else
        return a.quantity > b.quantity
      end
    end)
  end

  local quantity = 0
  local seenRealms = {}

  for index, s in ipairs(summary) do
    quantity = quantity + s.quantity
    seenRealms[s.realmNormalized] = true
  end
  seenRealms[GetNormalizedRealmName() or ""] = true -- ensure realm name is shown for a different realm

  if quantity == 0 then -- nothing to show
    return
  end

  local realmCount = 0
  for realm in pairs(seenRealms) do
    realmCount = realmCount + 1
  end
  local appendRealm = false
  if realmCount > 1 then
    appendRealm = true
  end

  tooltip:AddDoubleLine(addonTable.Locales.ALL_CHARACTERS_COLON, WHITE_FONT_COLOR:WrapTextInColorCode(FormatLargeNumber(quantity)))

  local currentCharacter = UnitName("player")
  local currentRealm = GetNormalizedRealmName()
  local charactersToShow = {}
  for _, s in ipairs(summary) do
    if addonTable.Config.Get(addonTable.Config.Options.ALWAYS_SHOW_CURRENT_CHARACTER) and s.character == currentCharacter and s.realmNormalized == currentRealm then
      table.insert(charactersToShow, 1, s)
    else
      table.insert(charactersToShow, s)
    end
  end

  for index = 1, math.min(#charactersToShow, addonTable.Config.Get("tooltips_character_limit")) do
    local s = charactersToShow[index]
    local character = s.character
    if appendRealm then
      character = character .. "-" .. s.realmNormalized
    end
    if s.className then
      character = "|c" .. (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[s.className].colorStr .. character .. "|r"
    end
    if addonTable.Config.Get(addonTable.Config.Options.SHOW_CHARACTER_RACE_ICONS) and s.race then
      character = addonTable.Utilities.GetCharacterIcon(s.race, s.sex) .. " " .. character
    end
    tooltip:AddDoubleLine("  " .. character, WHITE_FONT_COLOR:WrapTextInColorCode(FormatLargeNumber(s.quantity)))
  end
  if #summary > addonTable.Config.Get("tooltips_character_limit") then
    tooltip:AddLine("  ...")
  end

  if addonTable.Constants.IsClassic then
    tooltip:Show()
  end
end
