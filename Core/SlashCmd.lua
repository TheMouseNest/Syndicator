---@class addonTableSyndicator
local addonTable = select(2, ...)

addonTable.SlashCmd = {}

function addonTable.SlashCmd.Initialize()
  SlashCmdList["Syndicator"] = addonTable.SlashCmd.Handler
  SLASH_Syndicator1 = "/syndicator"
  SLASH_Syndicator2 = "/syn"
end

local INVALID_OPTION_VALUE = "Wrong config value type %s (required %s)"
function addonTable.SlashCmd.Config(optionName, value1, ...)
  if optionName == nil then
    addonTable.Utilities.Message("No config option name supplied")
    for _, name in pairs(addonTable.Config.Options) do
      addonTable.Utilities.Message(name .. ": " .. tostring(addonTable.Config.Get(name)))
    end
    return
  end

  local currentValue = addonTable.Config.Get(optionName)
  if currentValue == nil then
    addonTable.Utilities.Message("Unknown config: " .. optionName)
    return
  end

  if value1 == nil then
    addonTable.Utilities.Message("Config " .. optionName .. ": " .. tostring(currentValue))
    return
  end

  if type(currentValue) == "boolean" then
    if value1 ~= "true" and value1 ~= "false" then
      addonTable.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    addonTable.Config.Set(optionName, value1 == "true")
  elseif type(currentValue) == "number" then
    if tonumber(value1) == nil then
      addonTable.Utilities.Message(INVALID_OPTION_VALUE:format(type(value1), type(currentValue)))
      return
    end
    addonTable.Config.Set(optionName, tonumber(value1))
  elseif type(currentValue) == "string" then
    addonTable.Config.Set(optionName, strjoin(" ", value1, ...))
  else
    addonTable.Utilities.Message("Unable to edit option type " .. type(currentValue))
    return
  end
  addonTable.Utilities.Message("Now set " .. optionName .. ": " .. tostring(addonTable.Config.Get(optionName)))
end

function addonTable.SlashCmd.Debug()
  addonTable.Config.Set(addonTable.Config.Options.DEBUG, not addonTable.Config.Get(addonTable.Config.Options.DEBUG))
  if addonTable.Config.Get(addonTable.Config.Options.DEBUG) then
    addonTable.Utilities.Message("Debug mode on")
  else
    addonTable.Utilities.Message("Debug mode off")
  end
end

function addonTable.SlashCmd.RemoveCharacter(characterName)
  local success = pcall(Syndicator.API.DeleteCharacter, characterName)

  if not success then
    addonTable.Utilities.Message("Unrecognised or current character")
  else
    addonTable.Utilities.Message("Character '" .. characterName .. "' removed.")
  end
end

function addonTable.SlashCmd.RemoveGuild(...)
  local guildName = strjoin(" ", ...)
  local success = pcall(Syndicator.API.DeleteGuild, guildName)

  if not success then
    addonTable.Utilities.Message("Unrecognised or current guild")
  else
    addonTable.Utilities.Message("Guild '" .. guildName .. "' removed.")
  end
end

function addonTable.SlashCmd.HideCharacter(characterName)
  local success = pcall(Syndicator.API.ToggleCharacterHidden, characterName)
  if not success then
    addonTable.Utilities.Message("Unrecognised character")
  else
    local characterData = Syndicator.API.GetByCharacterFullName(characterName)
    addonTable.Utilities.Message("Character '" .. characterName .. "' hidden: " .. tostring(characterData.details.hidden))
  end
end

function addonTable.SlashCmd.HideGuild(...)
  local guildName = strjoin(" ", ...)
  local success = pcall(Syndicator.API.ToggleGuildHidden, guildName)

  if not success then
    addonTable.Utilities.Message("Unrecognised guild")
  else
    local guildData = Syndicator.API.GetByGuildFullName(guildName)
    addonTable.Utilities.Message("Guild '" .. guildName .. "' hidden: " .. tostring(guildData.details.hidden))
  end
end

function addonTable.SlashCmd.Timers()
  addonTable.Config.Set(addonTable.Config.Options.DEBUG_TIMERS, not addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS))
  addonTable.Utilities.Message("Performance timers: " .. (addonTable.Config.Get(addonTable.Config.Options.DEBUG_TIMERS) and "Enabled" or "Disabled"))
end

function addonTable.SlashCmd.Version()
  addonTable.Utilities.Message(
    BLUE_FONT_COLOR:WrapTextInColorCode("Version: ") .. C_AddOns.GetAddOnMetadata("Syndicator", "Version") ..
    LIGHTGRAY_FONT_COLOR:WrapTextInColorCode(", " .. date() .. ", ") ..
    BLUE_FONT_COLOR:WrapTextInColorCode("WoW: ") .. select(4, GetBuildInfo())
  )
end

function addonTable.SlashCmd.CustomiseUI()
  addonTable.CallbackRegistry:TriggerEvent("ShowCustomise")
end

local COMMANDS = {
  [""] = function() Settings.OpenToCategory(Syndicator.OptionsCategory:GetID()) end,
  ["v"] = addonTable.SlashCmd.Version,
  ["version"] = addonTable.SlashCmd.Version,
  ["c"] = addonTable.SlashCmd.Config,
  ["config"] = addonTable.SlashCmd.Config,
  ["d"] = addonTable.SlashCmd.Debug,
  ["timers"] = addonTable.SlashCmd.Timers,
  ["debug"] = addonTable.SlashCmd.Debug,
  ["remove"] = addonTable.SlashCmd.RemoveCharacter,
  ["removecharacter"] = addonTable.SlashCmd.RemoveCharacter,
  ["removeguild"] = addonTable.SlashCmd.RemoveGuild,
  ["hide"] = addonTable.SlashCmd.HideCharacter,
  ["hidecharacter"] = addonTable.SlashCmd.HideCharacter,
  ["hideguild"] = addonTable.SlashCmd.HideGuild,
}
function addonTable.SlashCmd.Handler(input)
  local split = {strsplit("\a", (input:gsub("%s+","\a")))}

  local root = split[1]
  if COMMANDS[root] ~= nil then
    table.remove(split, 1)
    COMMANDS[root](unpack(split))
  else
    addonTable.Utilities.Message("Unknown command '" .. root .. "'")
  end
end
