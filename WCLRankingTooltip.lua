-- WCLRankingTooltip.lua

-- Assuming playerData is a global table loaded from PlayerDB\DB.lua
-- Ensure playerData is structured as:
-- playerData = {
--   ["PlayerName"] = {
--     p = 75,  -- Parse Percentage
--     a = 1200, -- All-Star Points
--     s = "Frost", -- Spec
--     r = 90 -- Rank Percent
--   },
--   ...
-- }

local classColors = {
    DEATHKNIGHT = {r = 196, g = 30, b = 59},
    DRUID = {r = 255, g = 125, b = 10},
    HUNTER = {r = 171, g = 212, b = 115},
    MAGE = {r = 64, g = 199, b = 235},
    PALADIN = {r = 245, g = 140, b = 186},
    PRIEST = {r = 255, g = 255, b = 255},
    ROGUE = {r = 255, g = 245, b = 105},
    SHAMAN = {r = 0, g = 112, b = 222},
    WARLOCK = {r = 135, g = 135, b = 237},
    WARRIOR = {r = 199, g = 156, b = 110},
}

local possibleStars = 0

if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
	-- wrath
    possibleStars = 1080
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
	-- vanilla
    possibleStars = 720
end

-- Function to retrieve the class color
local function GetClassColor(className)
    local color = classColors[className]
    if color then
        return color
    else
        -- Return a default color if the class name is not found
        return {r = 255, g = 255, b = 255} -- White as default
    end
end

local specIconPaths = {
    -- Death Knight
    ["Blood_DEATHKNIGHT"] = "Interface\\Icons\\spell_deathknight_bloodpresence",
    ["BloodDPS_DEATHKNIGHT"] = "Interface\\Icons\\inv_weapon_shortblade_40",
    ["Frost_DEATHKNIGHT"] = "Interface\\Icons\\spell_frost_arcticwinds",
    ["Unholy_DEATHKNIGHT"] = "Interface\\Icons\\spell_deathknight_unholypresence",
    ["Runeblade_DEATHKNIGHT"] = "Interface\\Icons\\spell_deathknight_darkconviction",
    ["Lichborne_DEATHKNIGHT"] = "Interface\\Icons\\spell_shadow_raisedead",
    -- Druid
    ["Balance_DRUID"] = "Interface\\Icons\\spell_nature_starfall",
    ["Feral_DRUID"] = "Interface\\Icons\\ability_druid_catform",
    ["Restoration_DRUID"] = "Interface\\Icons\\spell_nature_healingtouch",
    ["Guardian_DRUID"] = "Interface\\Icons\\ability_racial_bearform",
    ["Warden_DRUID"] = "Interface\\Icons\\ability_druid_predatoryinstincts",
    -- Hunter
    ["BeastMastery_HUNTER"] = "Interface\\Icons\\ability_hunter_beasttaming",
    ["Marksmanship_HUNTER"] = "Interface\\Icons\\ability_marksmanship",
    ["Survival_HUNTER"] = "Interface\\Icons\\ability_hunter_swiftstrike",
    -- Mage
    ["Arcane_MAGE"] = "Interface\\Icons\\spell_holy_magicalsentry",
    ["Fire_MAGE"] = "Interface\\Icons\\spell_fire_firebolt02",
    ["Frost_MAGE"] = "Interface\\Icons\\spell_frost_frostbolt02",
    -- Paladin
    ["Holy_PALADIN"] = "Interface\\Icons\\spell_holy_holybolt",
    ["Protection_PALADIN"] = "Interface\\Icons\\spell_holy_devotionaura",
    ["Retribution_PALADIN"] = "Interface\\Icons\\spell_holy_auraoflight",
    ["Justicar_PALADIN"] = "Interface\\Icons\\spell_holy_divineintervention",
    -- Priest
    ["Discipline_PRIEST"] = "Interface\\Icons\\spell_holy_powerwordshield",
    ["Holy_PRIEST"] = "Interface\\Icons\\spell_holy_guardianspirit",
    ["Shadow_PRIEST"] = "Interface\\Icons\\spell_shadow_shadowwordpain",
    -- Rogue
    ["Assassination_ROGUE"] = "Interface\\Icons\\ability_rogue_eviscerate",
    ["Combat_ROGUE"] = "Interface\\Icons\\ability_backstab",
    ["Subtlety_ROGUE"] = "Interface\\Icons\\ability_stealth",
    -- Shaman
    ["Elemental_SHAMAN"] = "Interface\\Icons\\spell_nature_lightning",
    ["Enhancement_SHAMAN"] = "Interface\\Icons\\spell_shaman_improvedstormstrike",
    ["Restoration_SHAMAN"] = "Interface\\Icons\\spell_nature_magicimmunity",
    -- Warlock
    ["Affliction_WARLOCK"] = "Interface\\Icons\\spell_shadow_deathcoil",
    ["Demonology_WARLOCK"] = "Interface\\Icons\\spell_shadow_metamorphosis",
    ["Destruction_WARLOCK"] = "Interface\\Icons\\spell_shadow_rainoffire",
    -- Warrior
    ["Arms_WARRIOR"] = "Interface\\Icons\\ability_warrior_savageblow",
    ["Fury_WARRIOR"] = "Interface\\Icons\\ability_warrior_innerrage",
    ["Protection_WARRIOR"] = "Interface\\Icons\\ability_warrior_defensivestance",
    ["Gladiator_WARRIOR"] = "Interface\\Icons\\ability_warrior_improveddisciplines",
}

local function GetSpecIconPath(spec, class)
    -- Default to a generic question mark icon if the spec-class combo is not found
    return specIconPaths[spec .. '_' .. class] or "Interface\\Icons\\inv_misc_questionmark"
end

local function InterpolateColor(color1, color2, factor)
    local r = color1[1] + (color2[1] - color1[1]) * factor
    local g = color1[2] + (color2[2] - color1[2]) * factor
    local b = color1[3] + (color2[3] - color1[3]) * factor
    return {math.floor(r), math.floor(g), math.floor(b)}
end

local function GetSmoothGradientColor(value)
    if not value then
        return {255, 255, 255}
    end
    local colorRanges = {
        {0, 25, {102, 102, 102}, {30, 255, 0}},    -- Gray to Green
        {25, 50, {30, 255, 0}, {0, 112, 255}},     -- Green to Blue
        {50, 75, {0, 112, 255}, {163, 53, 238}},   -- Blue to Purple
        {75, 95, {163, 53, 238}, {255, 128, 0}},   -- Purple to Orange
        {95, 99, {255, 128, 0}, {226, 104, 168}}   -- Orange to Pink
    }
    local specialColor = {229, 204, 128}  -- Special color for value 100

    if value >= 99.5 then
        return specialColor
    end

    for _, range in ipairs(colorRanges) do
        local start, finish, startColor, endColor = unpack(range)
        if value >= start and value <= finish then
            local factor = (value - start) / (finish - start)
            return InterpolateColor(startColor, endColor, factor)
        end
    end

    return {0, 0, 0}  -- Fallback color
end

local function ParseProgressString(progressString)
    local parts = {strsplit(" ", progressString)}
    if #parts ~= 2 then
        return nil, "Invalid format"
    end

    local progressPart = parts[1]
    local completed, total = strmatch(progressPart, "(%d+)/(%d+)")

    if completed and total then
        completed = tonumber(completed)
        total = tonumber(total)
        if total == 0 then
            return nil, "Total cannot be zero"
        end
        return (completed / total) * 100
    else
        return nil, "Invalid progress format"
    end
end

local function GetFormattedText(data, class, separator, tooltip)
    local progressPercent = ParseProgressString(data.o)
    local specIconPath = GetSpecIconPath(data.s, class)
    -- Get the color for the parse percentage and rank percentage
    local parseColor = GetSmoothGradientColor(data.p)
    local rankColor = GetSmoothGradientColor(data.r)
    local starsColor = GetSmoothGradientColor((data.a / possibleStars) * 100)
    local classColor = GetClassColor(class)
    local progressColor = GetSmoothGradientColor(progressPercent)

    -- Convert color object to WoW's color string format
    local parseColorString = string.format("|cFF%02x%02x%02x", parseColor[1], parseColor[2], parseColor[3])
    local rankColorString = string.format("|cff%02x%02x%02x", rankColor[1], rankColor[2], rankColor[3])
    local starsColorString = string.format("|cff%02x%02x%02x", starsColor[1], starsColor[2], starsColor[3])
    local classColorString = string.format("|cff%02x%02x%02x", classColor.r, classColor.g, classColor.b)
    local progressColorString = string.format("|cff%02x%02x%02x", progressColor[1], progressColor[2], progressColor[3])

    -- Formatting the displayed text with color
    local displayTextParse = string.format("%sAvg: %d%%|r%s", parseColorString, data.p, separator)
    local displayTextRank = string.format("%sRank: %d|r%s", rankColorString, data.k, separator)
    local displayTextStars = string.format("%sAll Stars: %d|r%s", starsColorString, data.a, separator)
    local displayTextProgress = string.format("%sExp: %s|r%s", progressColorString, data.o, separator)
    local displayTextClass = string.format("%s%s|r ", classColorString, data.s)
    local displayTextSpec = string.format("|T%s:0|t", specIconPath)
    local specDisplay = ""

    if tooltip then
        if WCLRT_Settings["TooltipSpecDisplay"] == 1 then
            specDisplay = displayTextSpec
        else
            specDisplay = displayTextClass
        end
    else
        if WCLRT_Settings["PaneSpecDisplay"] == 1 then
            specDisplay = displayTextSpec
        else
            specDisplay = displayTextClass
        end
    end

    if tooltip then
        if WCLRT_Settings["TooltipAvgParse"] == false then
            displayTextParse = ""
        end
        if WCLRT_Settings["TooltipAllStars"] == false then
            displayTextStars = ""
        end
        if WCLRT_Settings["TooltipRank"] == false then
            displayTextRank = ""
        end
        if WCLRT_Settings["TooltipExp"] == false then
            displayTextProgress = ""
        end
    else
        if WCLRT_Settings["PaneAvgParse"] == false then
            displayTextParse = ""
        end
        if WCLRT_Settings["PaneAllStars"] == false then
            displayTextStars = ""
        end
        if WCLRT_Settings["PaneRank"] == false then
            displayTextRank = ""
        end
        if WCLRT_Settings["PaneExp"] == false then
            displayTextProgress = ""
        end
    end

    if displayTextParse == "" and displayTextStars == "" and displayTextRank == "" then
        return ""
    end


    return string.format("%s %s%s%s%s", specDisplay, displayTextParse, displayTextStars, displayTextRank, displayTextProgress)
end

local function AddPlayerDataToTooltip(unit)
    local name, _ = UnitName(unit)

    -- Retrieve player data from the database
    local _, classFilename = UnitClass(unit)
    local data = wclData[name]
    if data then
        GameTooltip:AddLine(GetFormattedText(data, classFilename, "  ", true))
        GameTooltip:Show()
    end
end

-- Using the same styling/icons as for the tooltip
local function UpdateWCLDataDisplay()
    if not WCLDataDisplayFrame then return end  -- If the frame doesn't exist, bail out
    local name, _ = UnitName("player")

    local data = wclData[name]
    if data then
        local _, classFilename = UnitClass("player")
        WCLDataDisplayFrame.text:SetText(GetFormattedText(data, classFilename, "\n", false))
    else
        WCLDataDisplayFrame.text:SetText("")
    end
end

local function UpdateInspectWCLDataDisplay()
    local unit = InspectFrame.unit
    if not unit then return end  -- If for some reason the unit isn't set, bail out

    local name, _ = UnitName(unit)
    -- Assuming playerData is structured with realm names, you might need to adjust for players on different realms

    -- Fetch the player's data
    local data = wclData[name]

    if data then
        local _, classFilename = UnitClass(unit)
        WCLDataInspectFrame.text:SetText(GetFormattedText(data, classFilename, "\n", false))
    else
        WCLDataInspectFrame.text:SetText("")
    end
end

local function SetUpWCLDataDisplayFrame()
    -- Proceed to set up your frame now that CharacterFrameInsetRight should exist
    local WCLDataDisplayFrame = CreateFrame("Frame", "WCLDataDisplayFrame", PaperDollItemsFrame)
    WCLDataDisplayFrame:SetSize(200, 50)  -- Adjust the size as needed
    WCLDataDisplayFrame:SetPoint("TOP", PaperDollItemsFrame, "TOP", 0, -190)  -- Adjust positioning as needed
    WCLDataDisplayFrame:SetPoint("LEFT", PaperDollItemsFrame, "LEFT", 70, 0)  -- Adjust positioning as needed

    WCLDataDisplayFrame:Hide()

    -- Initialize text font string for WCLDataDisplayFrame
    WCLDataDisplayFrame.text = WCLDataDisplayFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    WCLDataDisplayFrame.text:SetAllPoints()
    WCLDataDisplayFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    WCLDataDisplayFrame.text:SetJustifyH("LEFT")  -- Align text to the left horizontally


    -- Show and update the data display frame when the character stats frame is shown
    PaperDollItemsFrame:HookScript("OnShow", function()
        UpdateWCLDataDisplay()
        WCLDataDisplayFrame:Show()
    end)
end

local function SetUpWCLInspectDisplayFrame()
    local WCLDataInspectFrame = CreateFrame("Frame", "WCLDataInspectFrame", InspectFrame)
    WCLDataInspectFrame:SetSize(200, 50)  -- Adjust the size as needed
    WCLDataInspectFrame:SetPoint("BOTTOM", InspectFrame, "BOTTOM", 0, 160)  -- Adjust positioning as needed
    WCLDataInspectFrame:SetPoint("LEFT", InspectFrame, "LEFT", 70, 0)  -- Adjust positioning as needed

    WCLDataInspectFrame:Hide()

    -- Initialize text font string for WCLDataInspectFrame
    WCLDataInspectFrame.text = WCLDataInspectFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    WCLDataInspectFrame.text:SetAllPoints()
    WCLDataInspectFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    WCLDataInspectFrame.text:SetJustifyH("LEFT")  -- Align text to the left horizontally

    InspectFrame:HookScript("OnShow", function()
        UpdateInspectWCLDataDisplay()
        WCLDataInspectFrame:Show()
    end)
end

local function UpdateSettingsWithDefaults()
    local defaultSettings = {
        TooltipAvgParse = true, -- or false
        TooltipAllStars = false, -- or false
        TooltipRank = true, -- or false
        TooltipSpecDisplay = 1, -- or any other integer
        TooltipExp = true, -- or false
        PaneAvgParse = true, -- or false
        PaneAllStars = true, -- or false
        PaneRank = true, -- or false
        PaneSpecDisplay = 1, -- or any other integer
        PaneExp = true, -- or false
    }
    -- Ensure WCLRT_Settings table exists
    if not WCLRT_Settings then
        WCLRT_Settings = {}
    end

    -- Iterate through each default setting
    for key, value in pairs(defaultSettings) do
        -- If the setting does not exist, initialize it with the default value
        if WCLRT_Settings[key] == nil then
            WCLRT_Settings[key] = value
        end
    end
end

local function GetPlayerRegion()
    local realmList = GetCVar("portal")
    if realmList then
        realmList = string.lower(realmList)
        if realmList == "us" then
            return "US"
        elseif realmList == "eu" then
            return "EU"
        elseif realmList == "kr" then
            return "KR"
        elseif realmList == "tw" then
            return "TW"
        else
            return "Unknown"
        end
    end
    return "Unknown"
end

thisRealm = GetRealmName()
if GetPlayerRegion() == "EU" then
    thisRealm = thisRealm .. "-EU"
end
wclData = PlayerDB[thisRealm]
if not wclData then
    print('WCL Ranking Tooltip is not currently available on ' .. thisRealm ..  '. Contact the developer for more information. Discord: kikootwo')
    return
end
local firstLoad = true
local addonVersion = "0.0.0"
-- Event frame for tooltip hook
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "WCLRankingTooltip" then
        UpdateSettingsWithDefaults()
        addonVersion = GetAddOnMetadata("WCLRankingTooltip", "Version")
        -- Hook into the GameTooltip to add player data
        GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
            local _, unit = tooltip:GetUnit()
            if unit and UnitIsPlayer(unit) then
                AddPlayerDataToTooltip(unit)
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD") -- Optional: Unregister if you only need to run this once
        SetUpWCLDataDisplayFrame()
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_InspectUI" then
        SetUpWCLInspectDisplayFrame()
    end
end)


local function CreateCheckbox(parent, text, name, setting, pointParent, pointFrom, pointTo, xOffset, yOffset)
    local checkbox = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    checkbox:SetPoint(pointFrom, pointParent, pointTo, xOffset, yOffset)
    checkbox:SetScript("OnClick", function(self)
        WCLRT_Settings[setting] = self:GetChecked()
    end)
    checkbox:SetChecked(WCLRT_Settings[setting])

    -- Create and set the checkbox label text
    local checkboxLabel = checkbox:CreateFontString(nil, "ARTWORK", "GameTooltipText")
    checkboxLabel:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxLabel:SetText(text)
    return checkbox
end

local function CreateDropdown(parent, name, setting, pointParent, pointFrom, pointTo, xOffset, yOffset, options, text)

    local dropdownLabel = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dropdownLabel:SetPoint(pointFrom, pointParent, pointTo, xOffset, yOffset)
    dropdownLabel:SetText(text)

    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", dropdownLabel, "BOTTOMLEFT", 0, -10)
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_SetText(dropdown, "Select Option")

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for k, v in pairs(options) do
            info.text = v
            --info.isNotRadio = true -- Ensures checkbox behavior if needed
            info.func = function(self)
                WCLRT_Settings[setting] = k
                UIDropDownMenu_SetSelectedID(dropdown, k)
                -- Ensure the menu is refreshed to reflect the new selection state correctly
                CloseDropDownMenus()
            end
            info.checked = (k == WCLRT_Settings[setting]) -- Check the item if it's the selected option
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedID(dropdown, WCLRT_Settings[setting])
    return dropdown
end

-- Create the main panel
local panel = CreateFrame("Frame", "WCLRTOptionsPanel", UIParent)
panel.name = "WCL Ranking Tooltip"
InterfaceOptions_AddCategory(panel)

-- Reflect current settings when the panel is opened
panel:SetScript("OnShow", function()
    if firstLoad then
        -- Title
        local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 16, -16)
        title:SetText(panel.name .. " v" .. addonVersion)
        local freshness = nil
        if wclData["data_freshness"] then
            freshness = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            freshness:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
            freshness:SetText(thisRealm .. " Data Last Updated: " .. wclData["data_freshness"])
        end

        local anchor = nil
        if freshness then
            anchor = freshness
        else
            anchor = title
        end

        local tooltipGroupLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        tooltipGroupLabel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -20)
        tooltipGroupLabel:SetText("Tooltip Options")

        local tooltip_checkbox1 = CreateCheckbox(panel, "Show Average Parse Percentage in Tooltip", "tooltip_WCLRT-AvgParse", "TooltipAvgParse", tooltipGroupLabel, "TOPLEFT", "BOTTOMLEFT", 0, -15)
        local tooltip_checkbox2 = CreateCheckbox(panel, "Show All Stars in Tooltip", "tooltip_WCLRT-AllStars", "TooltipAllStars", tooltip_checkbox1, "TOPLEFT", "BOTTOMLEFT", 0, -5)
        local tooltip_checkbox3 = CreateCheckbox(panel, "Show Rank in Tooltip", "tooltip_WCLRT-Rank", "TooltipRank", tooltip_checkbox2, "TOPLEFT", "BOTTOMLEFT", 0, -5)
        local tooltip_checkbox4 = CreateCheckbox(panel, "Show Exp in Tooltip", "tooltip_WCLRT-Exp", "TooltipExp", tooltip_checkbox3, "TOPLEFT", "BOTTOMLEFT", 0, -5)

        local dropdown1 = CreateDropdown(panel, "tooltip_SpecDisplay", "TooltipSpecDisplay", tooltip_checkbox4, "TOPLEFT", "BOTTOMLEFT", 0, -10, {"Icon", "Text"}, "Tooltip Spec Display Options")

        local paneGroupLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        paneGroupLabel:SetPoint("TOPLEFT", dropdown1, "BOTTOMLEFT", 0, -20)
        paneGroupLabel:SetText("Character/Inspect Pane Options")

        local pane_checkbox1 = CreateCheckbox(panel, "Show Average Parse Percentage in Panes", "pane_WCLRT-AvgParse", "PaneAvgParse", paneGroupLabel, "TOPLEFT", "BOTTOMLEFT", 0, -15)
        local pane_checkbox2 = CreateCheckbox(panel, "Show All Stars in Panes", "pane_WCLRT-AllStars", "PaneAllStars", pane_checkbox1, "TOPLEFT", "BOTTOMLEFT", 0, -5)
        local pane_checkbox3 = CreateCheckbox(panel, "Show Rank in Panes", "pane_WCLRT-Rank", "PaneRank", pane_checkbox2, "TOPLEFT", "BOTTOMLEFT", 0, -5)
        local pane_checkbox4 = CreateCheckbox(panel, "Show Exp in Panes", "pane_WCLRT-Exp", "PaneExp", pane_checkbox3, "TOPLEFT", "BOTTOMLEFT", 0, -5)


        local dropdown2 = CreateDropdown(panel, "tooltip_SpecDisplay", "PaneSpecDisplay", pane_checkbox4, "TOPLEFT", "BOTTOMLEFT", 0, -10, {"Icon", "Text"}, "Pane Spec Display Options")
        firstLoad = false
    end
end)

-- Add a /wclwho command for searching outside local range and party/raid.

local function WCLWhoCommand(msg, editbox)
	local name = ""
	local class = ""
	local argNum = 0
	  for arg in string.gmatch(msg, "%S+") do
		argNum = argNum + 1
		if argNum == 1 then name = arg end
		if argNum == 2 then class = arg end
	  end
	
	name = string.sub(name,1,1):upper() .. string.sub(name, 2, string.len(name)):lower() --force first character uppercase, rest lower for matching with database.
	local data = wclData[name]
	if data then
		print(name .. ": " .. GetFormattedText(data, class:upper(), "  ", true))
	else
		print("Name not found in WCLRankingTooltip Database...")
	end
end

SlashCmdList["WCLWHOTEST"] = WCLWhoCommand 
SLASH_WCLWHOTEST1 = '/WCLWHO'
