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

local function GetSpecIconPath(spec, class)
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
    local colorRanges = {
        {0, 25, {102, 102, 102}, {30, 255, 0}},   -- Gray to Green
        {25, 50, {30, 255, 0}, {0, 112, 255}},    -- Green to Blue
        {50, 75, {0, 112, 255}, {163, 53, 238}},  -- Blue to Purple
        {75, 99.5, {163, 53, 238}, {226, 104, 168}} -- Purple to Pink
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

local function GetFormattedText(data, class, separator, tooltip)
    local specIconPath = GetSpecIconPath(data.s, class)
    -- Get the color for the parse percentage and rank percentage
    local parseColor = GetSmoothGradientColor(data.p)
    local rankColor = GetSmoothGradientColor(data.r)
    local starsColor = GetSmoothGradientColor((data.a / 1080) * 100)
    local classColor = GetClassColor(class)

    -- Convert color object to WoW's color string format
    local parseColorString = string.format("|cFF%02x%02x%02x", parseColor[1], parseColor[2], parseColor[3])
    local rankColorString = string.format("|cff%02x%02x%02x", rankColor[1], rankColor[2], rankColor[3])
    local starsColorString = string.format("|cff%02x%02x%02x", starsColor[1], starsColor[2], starsColor[3])
    local classColorString = string.format("|cff%02x%02x%02x", classColor.r, classColor.g, classColor.b)

    -- Formatting the displayed text with color
    local displayTextParse = string.format("%sAvg: %d%%|r%s", parseColorString, data.p, separator)
    local displayTextRank = string.format("%sRank: %d|r%s", rankColorString, data.k, separator)
    local displayTextStars = string.format("%sAll Stars: %d|r%s", starsColorString, data.a, separator)
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
    end

    if displayTextParse == "" and displayTextStars == "" and displayTextRank == "" then
        return ""
    end


    return string.format("%s %s%s%s", specDisplay, displayTextParse, displayTextStars, displayTextRank)
    -- if tooltip then
    --     if WCLRT_Settings["TooltipSpecDisplay"] == 1 then
    --         return string.format("|T%s:0|t %s%s%s", specIconPath, displayTextParse, displayTextStars, displayTextRank)
    --     else
    --         return string.format("%s  %s%s%s", displayTextClass, displayTextParse, displayTextStars, displayTextRank)
    --     end
    -- else
    --     if WCLRT_Settings["PaneSpecDisplay"] == 1 then
    --         return string.format("|T%s:0|t %s%s%s%s%s", specIconPath, displayTextParse, separator, displayTextStars, separator, displayTextRank)
    --     else
    --         return string.format("%s  %s%s%s%s%s", displayTextClass, displayTextParse, separator, displayTextStars, separator, displayTextRank)
    --     end
    -- end
end

local function AddPlayerDataToTooltip(unit)
    local name, realm = UnitName(unit)
    -- Check if the player is from the same realm. Adjust if necessary for cross-realm.
    if realm == nil or realm == "" then
        realm = GetRealmName()
    end

	if realm ~= 'Benediction' then
		return
	end

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
    local name, realm = UnitName("player")
    -- Check if the player is from the same realm. Adjust if necessary for cross-realm.
    if realm == nil or realm == "" then
        realm = GetRealmName()
    end

	if realm ~= 'Benediction' then
		return
	end

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

    local name, realm = UnitName(unit)
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
    local WCLDataDisplayFrame = CreateFrame("Frame", "WCLDataDisplayFrame", CharacterFrame)
    WCLDataDisplayFrame:SetSize(200, 50)  -- Adjust the size as needed
    WCLDataDisplayFrame:SetPoint("TOP", CharacterFrame, "TOP", 0, -190)  -- Adjust positioning as needed
    WCLDataDisplayFrame:SetPoint("LEFT", CharacterFrame, "LEFT", 70, 0)  -- Adjust positioning as needed

    WCLDataDisplayFrame:Hide()

    -- Initialize text font string for WCLDataDisplayFrame
    WCLDataDisplayFrame.text = WCLDataDisplayFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    WCLDataDisplayFrame.text:SetAllPoints()
    WCLDataDisplayFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    WCLDataDisplayFrame.text:SetJustifyH("LEFT")  -- Align text to the left horizontally


    -- Show and update the data display frame when the character stats frame is shown
    CharacterFrame:HookScript("OnShow", function()
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
        TooltipAllStars = true, -- or false
        TooltipRank = true, -- or false
        TooltipSpecDisplay = 1, -- or any other integer
        PaneAvgParse = true, -- or false
        PaneAllStars = true, -- or false
        PaneRank = true, -- or false
        PaneSpecDisplay = 1 -- or any other integer
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

local thisRealm = GetRealmName()
wclData = PlayerDB[thisRealm]
print(wclData['Lightspyer']['p'])
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

        local tooltipGroupLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        tooltipGroupLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
        tooltipGroupLabel:SetText("Tooltip Options")

        local tooltip_checkbox1 = CreateCheckbox(panel, "Show Average Parse Percentage in Tooltip", "tooltip_WCLRT-AvgParse", "TooltipAvgParse", tooltipGroupLabel, "TOPLEFT", "BOTTOMLEFT", 0, -15)
        local tooltip_checkbox2 = CreateCheckbox(panel, "Show All Stars in Tooltip", "tooltip_WCLRT-AllStars", "TooltipAllStars", tooltip_checkbox1, "TOPLEFT", "BOTTOMLEFT", 0, -5)
        local tooltip_checkbox3 = CreateCheckbox(panel, "Show Rank in Tooltip", "tooltip_WCLRT-Rank", "TooltipRank", tooltip_checkbox2, "TOPLEFT", "BOTTOMLEFT", 0, -5)

        local dropdown1 = CreateDropdown(panel, "tooltip_SpecDisplay", "TooltipSpecDisplay", tooltip_checkbox3, "TOPLEFT", "BOTTOMLEFT", 0, -10, {"Icon", "Text"}, "Tooltip Spec Display Options")

        local paneGroupLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        paneGroupLabel:SetPoint("TOPLEFT", dropdown1, "BOTTOMLEFT", 0, -20)
        paneGroupLabel:SetText("Character/Inspect Pane Options")

        local pane_checkbox1 = CreateCheckbox(panel, "Show Average Parse Percentage in Panes", "pane_WCLRT-AvgParse", "PaneAvgParse", paneGroupLabel, "TOPLEFT", "BOTTOMLEFT", 0, -15)
        local pane_checkbox2 = CreateCheckbox(panel, "Show All Stars in Panes", "pane_WCLRT-AllStars", "PaneAllStars", pane_checkbox1, "TOPLEFT", "BOTTOMLEFT", 0, -5)
        local pane_checkbox3 = CreateCheckbox(panel, "Show Rank in Panes", "pane_WCLRT-Rank", "PaneRank", pane_checkbox2, "TOPLEFT", "BOTTOMLEFT", 0, -5)

        local dropdown2 = CreateDropdown(panel, "tooltip_SpecDisplay", "PaneSpecDisplay", pane_checkbox3, "TOPLEFT", "BOTTOMLEFT", 0, -10, {"Icon", "Text"}, "Pane Spec Display Options")
        firstLoad = false
    end
end)