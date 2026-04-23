---@class addonTableSyndicator
local addonTable = select(2, ...)

addonTable.Config = {}

addonTable.Config.Options = {
  ALWAYS_SHOW_CURRENT_CHARACTER = "always_show_current_character",
  SHOW_CHARACTER_RACE_ICONS = "show_character_race_icons",

  SHOW_INVENTORY_TOOLTIPS = "show_inventory_tooltips",
  SHOW_GUILD_BANKS_IN_TOOLTIPS = "show_guild_banks_in_tooltips",
  SHOW_EQUIPPED_ITEMS_IN_TOOLTIPS = "show_equipped_items_in_tooltips",
  SHOW_CURRENCY_TOOLTIPS = "show_currency_tooltips",
  SHOW_TOOLTIPS_ON_SHIFT = "show_tooltips_on_shift",
  TOOLTIPS_CONNECTED_REALMS_ONLY = "tooltips_connected_realms_only_2",
  TOOLTIPS_FACTION_ONLY = "tooltips_faction_only",
  TOOLTIPS_CHARACTER_LIMIT = "tooltips_character_limit",
  TOOLTIPS_SORT_BY_NAME = "tooltips_sort_by_name",
  SHOW_BLANK_LINE_BEFORE_INVENTORY = "show_blank_line_before_inventory",
  SHOW_TOTAL_LINE_AFTER_CHARACTERS = "show_total_line_after_characters",

  AUCTION_VALUE_SOURCE = "auction_value_source",
  NO_AUCTION_VALUE_SOURCE = "no_auction_value_source",

  DEBUG = "debug",
  DEBUG_TIMERS = "debug_timers",
}

addonTable.Config.Defaults = {
  [addonTable.Config.Options.SHOW_INVENTORY_TOOLTIPS] = true,
  [addonTable.Config.Options.SHOW_GUILD_BANKS_IN_TOOLTIPS] = true,
  [addonTable.Config.Options.SHOW_EQUIPPED_ITEMS_IN_TOOLTIPS] = true,
  [addonTable.Config.Options.SHOW_CURRENCY_TOOLTIPS] = true,
  [addonTable.Config.Options.SHOW_TOOLTIPS_ON_SHIFT] = false,
  [addonTable.Config.Options.TOOLTIPS_CONNECTED_REALMS_ONLY] = not Syndicator.Constants.IsRetail,
  [addonTable.Config.Options.TOOLTIPS_SORT_BY_NAME] = false,
  [addonTable.Config.Options.TOOLTIPS_FACTION_ONLY] = false,
  [addonTable.Config.Options.TOOLTIPS_CHARACTER_LIMIT] = 4,
  [addonTable.Config.Options.ALWAYS_SHOW_CURRENT_CHARACTER] = false,
  [addonTable.Config.Options.SHOW_CHARACTER_RACE_ICONS] = true,
  [addonTable.Config.Options.SHOW_BLANK_LINE_BEFORE_INVENTORY] = false,
  [addonTable.Config.Options.SHOW_TOTAL_LINE_AFTER_CHARACTERS] = false,
  [addonTable.Config.Options.AUCTION_VALUE_SOURCE] = "", -- "auctionator" ,"oribos-region", "oribos-realm", "tradeskillmaster-dbrecent", etc.
  [addonTable.Config.Options.NO_AUCTION_VALUE_SOURCE] = false,

  [addonTable.Config.Options.DEBUG] = false,
  [addonTable.Config.Options.DEBUG_TIMERS] = false,
}

function addonTable.Config.IsValidOption(name)
  for _, option in pairs(addonTable.Config.Options) do
    if option == name then
      return true
    end
  end
  return false
end

function addonTable.Config.Create(constant, name, defaultValue)
  addonTable.Config.Options[constant] = name

  addonTable.Config.Defaults[Syndicator.Config.Options[constant]] = defaultValue

  if SYNDICATOR_CONFIG ~= nil and SYNDICATOR_CONFIG[name] == nil then
    SYNDICATOR_CONFIG[name] = defaultValue
  end
end

function addonTable.Config.Set(name, value)
  if SYNDICATOR_CONFIG == nil then
    error("JOURNALATOR_CONFIG not initialized")
  elseif not addonTable.Config.IsValidOption(name) then
    error("Invalid option '" .. name .. "'")
  else
    local oldValue = SYNDICATOR_CONFIG[name]
    SYNDICATOR_CONFIG[name] = value
  end
end

function addonTable.Config.ResetOne(name)
  local newValue = addonTable.Config.Defaults[name]
  if type(newValue) == "table" then
    newValue = CopyTable(newValue)
  end
  addonTable.Config.Set(name, newValue)
end

function addonTable.Config.Reset()
  SYNDICATOR_CONFIG = {}
  for option, value in pairs(addonTable.Config.Defaults) do
    SYNDICATOR_CONFIG[option] = value
  end
end

function addonTable.Config.InitializeData()
  if SYNDICATOR_CONFIG == nil then
    addonTable.Config.Reset()
  else
    for option, value in pairs(addonTable.Config.Defaults) do
      if SYNDICATOR_CONFIG[option] == nil then
        SYNDICATOR_CONFIG[option] = value
      end
    end
  end
end

function addonTable.Config.Get(name)
  -- This is ONLY if a config is asked for before variables are loaded
  if SYNDICATOR_CONFIG == nil then
    return addonTable.Config.Defaults[name]
  else
    return SYNDICATOR_CONFIG[name]
  end
end
