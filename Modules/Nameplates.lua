-- MithUI Nameplates Module
-- Clean nameplates with quest highlighting and interrupt indicators

local addonName, MithUI = ...

local Nameplates = {}
MithUI:RegisterModule("nameplates", Nameplates)

local db

-- Theme definitions
local THEMES = {
    -- Clean minimal grey style
    grey = {
        name = "Grey",
        healthBarHeight = 10,
        healthBarTexture = "Interface\\Buttons\\WHITE8x8",
        barColor = {0.5, 0.5, 0.5},
        bgColor = {0.15, 0.15, 0.15, 0.9},
        borderColor = {0.3, 0.3, 0.3, 1},
        borderSize = 1,
        nameFont = "Fonts\\FRIZQT__.TTF",
        nameFontSize = 9,
        nameFontFlags = "OUTLINE",
        showGlow = false,
        glowColor = {0, 0, 0, 0},
    },
    -- Neon glowing style
    neon = {
        name = "Neon",
        healthBarHeight = 8,
        healthBarTexture = "Interface\\Buttons\\WHITE8x8",
        barColor = {0.2, 0.8, 0.2},
        bgColor = {0.05, 0.05, 0.05, 0.95},
        borderColor = {0.1, 0.1, 0.1, 1},
        borderSize = 1,
        nameFont = "Fonts\\FRIZQT__.TTF",
        nameFontSize = 8,
        nameFontFlags = "OUTLINE",
        showGlow = true,
        glowColor = {0.3, 1.0, 0.3, 0.4},
        glowSize = 4,
    },
    -- Clean modern style
    clean = {
        name = "Clean",
        healthBarHeight = 12,
        healthBarTexture = "Interface\\Buttons\\WHITE8x8",
        barColor = {0.8, 0.2, 0.2},
        bgColor = {0.1, 0.1, 0.1, 0.85},
        borderColor = {0, 0, 0, 1},
        borderSize = 2,
        nameFont = "Fonts\\FRIZQT__.TTF",
        nameFontSize = 10,
        nameFontFlags = "OUTLINE",
        showGlow = false,
        glowColor = {0, 0, 0, 0},
    },
    -- Thin minimal bars
    thin = {
        name = "Thin",
        healthBarHeight = 6,
        healthBarTexture = "Interface\\Buttons\\WHITE8x8",
        barColor = {0.7, 0.7, 0.7},
        bgColor = {0.1, 0.1, 0.1, 0.8},
        borderColor = {0.2, 0.2, 0.2, 1},
        borderSize = 1,
        nameFont = "Fonts\\FRIZQT__.TTF",
        nameFontSize = 8,
        nameFontFlags = "OUTLINE",
        showGlow = false,
        glowColor = {0, 0, 0, 0},
    },
    -- Headline mode - names only, no bars
    headline = {
        name = "Headline",
        healthBarHeight = 0,  -- No health bar
        healthBarTexture = "Interface\\Buttons\\WHITE8x8",
        barColor = {0, 0, 0, 0},
        bgColor = {0, 0, 0, 0},
        borderColor = {0, 0, 0, 0},
        borderSize = 0,
        nameFont = "Fonts\\FRIZQT__.TTF",
        nameFontSize = 12,
        nameFontFlags = "OUTLINE",
        showGlow = false,
        glowColor = {0, 0, 0, 0},
        nameOnly = true,
    },
}

-- Default settings
local defaults = {
    enabled = true,
    -- Theme
    theme = "grey",
    -- Health bar
    healthBarHeight = 12,
    healthBarWidth = 120,
    healthBarTexture = "Interface\\Buttons\\WHITE8x8",
    -- Colors
    friendlyColor = {0.3, 0.7, 0.3},
    enemyColor = {0.8, 0.2, 0.2},
    neutralColor = {0.9, 0.7, 0.0},
    questColor = {1.0, 0.6, 0.0},      -- Orange for quest mobs
    tappedColor = {0.5, 0.5, 0.5},
    -- Threat colors
    threatHigh = {1.0, 0.0, 0.0},      -- Red - you have aggro (bad for DPS)
    threatMed = {1.0, 0.6, 0.0},       -- Orange - close to pulling
    threatLow = {0.3, 0.7, 0.3},       -- Green - safe
    threatTank = {0.3, 0.5, 0.9},      -- Blue - tank has it
    useThreatColors = true,
    -- Class colors
    useClassColors = true,
    -- Cast bar
    showCastBar = true,
    castBarHeight = 10,
    castBarColor = {0.8, 0.7, 0.2},
    interruptibleColor = {0.8, 0.7, 0.2},
    nonInterruptibleColor = {0.7, 0.2, 0.2},
    -- Features
    showQuestIndicator = true,
    showTargetHighlight = true,
    targetGlowColor = {1.0, 1.0, 1.0, 0.8},
    hideFullHealth = false,
    showHealthText = true,
    showNameText = true,
    -- Scale
    targetScale = 1.2,
    nonTargetAlpha = 0.8,
}

-- Class colors
local CLASS_COLORS = RAID_CLASS_COLORS

-- Track modified nameplates
local modifiedPlates = {}

-- Reusable tooltip for quest mob scanning (created once, reused)
local questScanTooltip

function Nameplates:OnInitialize()
    MithUI.defaults.nameplates = defaults
end

function Nameplates:OnEnable()
    db = MithUIDB.nameplates
    self:SetupNameplates()
    self:RegisterEvents()
end

function Nameplates:SetupNameplates()
    -- Set nameplate CVars for cleaner look
    if db.enabled then
        SetCVar("nameplateShowFriendlyNPCs", 0)
        SetCVar("nameplateShowOnlyNames", 0)
        SetCVar("nameplateMotion", 1)  -- Stacking
        SetCVar("nameplateOverlapH", 0.8)
        SetCVar("nameplateOverlapV", 1.1)
    end
end

function Nameplates:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    events:RegisterEvent("UNIT_HEALTH")
    events:RegisterEvent("QUEST_LOG_UPDATE")
    
    events:SetScript("OnEvent", function(self, event, ...)
        if event == "NAME_PLATE_UNIT_ADDED" then
            local unit = ...
            Nameplates:OnNameplateAdded(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            local unit = ...
            Nameplates:OnNameplateRemoved(unit)
        elseif event == "PLAYER_TARGET_CHANGED" then
            Nameplates:UpdateAllTargetHighlights()
        elseif event == "UNIT_THREAT_LIST_UPDATE" then
            local unit = ...
            Nameplates:UpdateThreat(unit)
        elseif event == "UNIT_HEALTH" then
            local unit = ...
            Nameplates:UpdateHealth(unit)
        elseif event == "QUEST_LOG_UPDATE" then
            Nameplates:UpdateAllQuestIndicators()
        end
    end)
end

function Nameplates:OnNameplateAdded(unit)
    if not db.enabled then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    self:StyleNameplate(nameplate, unit)
end

function Nameplates:OnNameplateRemoved(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate and modifiedPlates[nameplate] then
        -- Clean up our additions
        if modifiedPlates[nameplate].questIcon then
            modifiedPlates[nameplate].questIcon:Hide()
        end
        if modifiedPlates[nameplate].targetGlow then
            modifiedPlates[nameplate].targetGlow:Hide()
        end
        if modifiedPlates[nameplate].castBar then
            modifiedPlates[nameplate].castBar:Hide()
        end
        modifiedPlates[nameplate] = nil
    end
end

function Nameplates:StyleNameplate(nameplate, unit)
    local unitFrame = nameplate.UnitFrame
    if not unitFrame then return end
    
    -- Initialize our data
    modifiedPlates[nameplate] = modifiedPlates[nameplate] or {}
    local data = modifiedPlates[nameplate]
    data.unit = unit
    
    -- Style health bar
    self:StyleHealthBar(nameplate, unit)
    
    -- Add quest indicator
    if db.showQuestIndicator then
        self:AddQuestIndicator(nameplate, unit)
    end
    
    -- Add target highlight
    if db.showTargetHighlight then
        self:AddTargetHighlight(nameplate, unit)
    end
    
    -- Add cast bar
    if db.showCastBar then
        self:AddCastBar(nameplate, unit)
    end
    
    -- Update colors
    self:UpdateNameplateColor(nameplate, unit)
    
    -- Update target state
    self:UpdateTargetHighlight(nameplate, unit)
end

function Nameplates:StyleHealthBar(nameplate, unit)
    local unitFrame = nameplate.UnitFrame
    if not unitFrame or not unitFrame.healthBar then return end
    
    local healthBar = unitFrame.healthBar
    
    -- Set size
    healthBar:SetHeight(db.healthBarHeight)
    healthBar:SetStatusBarTexture(db.healthBarTexture)
    
    -- Add background if not exists
    if not healthBar.mithBG then
        healthBar.mithBG = healthBar:CreateTexture(nil, "BACKGROUND")
        healthBar.mithBG:SetAllPoints()
        healthBar.mithBG:SetColorTexture(0, 0, 0, 0.7)
    end
    
    -- Add border if not exists
    if not healthBar.mithBorder then
        healthBar.mithBorder = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
        healthBar.mithBorder:SetPoint("TOPLEFT", -1, 1)
        healthBar.mithBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        healthBar.mithBorder:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        healthBar.mithBorder:SetBackdropBorderColor(0, 0, 0, 1)
    end
    
    -- Health text
    if db.showHealthText then
        if not healthBar.mithHealthText then
            healthBar.mithHealthText = healthBar:CreateFontString(nil, "OVERLAY")
            healthBar.mithHealthText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            healthBar.mithHealthText:SetPoint("CENTER")
        end
        self:UpdateHealthText(nameplate, unit)
    end
end

function Nameplates:UpdateHealthText(nameplate, unit)
    local unitFrame = nameplate.UnitFrame
    if not unitFrame or not unitFrame.healthBar then return end
    
    local healthBar = unitFrame.healthBar
    if not healthBar.mithHealthText then return end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    if maxHealth > 0 then
        local percent = math.floor((health / maxHealth) * 100)
        healthBar.mithHealthText:SetText(percent .. "%")
    end
end

function Nameplates:AddQuestIndicator(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data then return end
    
    -- Create quest icon
    if not data.questIcon then
        data.questIcon = nameplate:CreateTexture(nil, "OVERLAY")
        data.questIcon:SetSize(16, 16)
        data.questIcon:SetPoint("LEFT", nameplate.UnitFrame.healthBar, "RIGHT", 4, 0)
        data.questIcon:SetTexture("Interface\\MINIMAP\\ObjectIconsAtlas")
        data.questIcon:SetTexCoord(0.127, 0.158, 0.379, 0.410)  -- Quest ! icon
    end
    
    -- Check if quest mob
    local isQuestMob = self:IsQuestMob(unit)
    if isQuestMob then
        data.questIcon:Show()
        -- Also tint the health bar orange
        if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
            nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(db.questColor))
        end
    else
        data.questIcon:Hide()
    end
end

function Nameplates:IsQuestMob(unit)
    -- Check if unit is needed for a quest
    if UnitIsPlayer(unit) then return false end
    
    -- Also check unit classification first (fast check)
    local classification = UnitClassification(unit)
    if classification == "questboss" then
        return true
    end
    
    -- Create reusable tooltip once, then reuse it
    if not questScanTooltip then
        questScanTooltip = CreateFrame("GameTooltip", "MithQuestScanTooltip", nil, "GameTooltipTemplate")
    end
    
    questScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    questScanTooltip:SetUnit(unit)
    
    for i = 1, questScanTooltip:NumLines() do
        local line = _G["MithQuestScanTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                -- Look for quest progress indicators
                if text:match("%d+/%d+") or text:match("%(.*Quest.*)") then
                    questScanTooltip:Hide()
                    return true
                end
            end
        end
    end
    
    questScanTooltip:Hide()
    return false
end

function Nameplates:AddTargetHighlight(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data then return end
    
    if not data.targetGlow then
        data.targetGlow = nameplate:CreateTexture(nil, "BACKGROUND", nil, -1)
        data.targetGlow:SetPoint("TOPLEFT", nameplate.UnitFrame.healthBar, "TOPLEFT", -8, 8)
        data.targetGlow:SetPoint("BOTTOMRIGHT", nameplate.UnitFrame.healthBar, "BOTTOMRIGHT", 8, -8)
        data.targetGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
        data.targetGlow:SetBlendMode("ADD")
        data.targetGlow:SetVertexColor(unpack(db.targetGlowColor))
        data.targetGlow:Hide()
    end
end

function Nameplates:UpdateTargetHighlight(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data or not data.targetGlow then return end
    
    local isTarget = UnitIsUnit(unit, "target")
    
    if isTarget then
        data.targetGlow:Show()
        nameplate:SetScale(db.targetScale)
        nameplate:SetAlpha(1)
    else
        data.targetGlow:Hide()
        nameplate:SetScale(1)
        nameplate:SetAlpha(db.nonTargetAlpha)
    end
end

function Nameplates:UpdateAllTargetHighlights()
    for nameplate, data in pairs(modifiedPlates) do
        if data.unit then
            self:UpdateTargetHighlight(nameplate, data.unit)
        end
    end
end

function Nameplates:AddCastBar(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data then return end
    
    local unitFrame = nameplate.UnitFrame
    if not unitFrame then return end
    
    -- Create custom cast bar
    if not data.castBar then
        local castBar = CreateFrame("StatusBar", nil, nameplate)
        castBar:SetSize(db.healthBarWidth, db.castBarHeight)
        castBar:SetPoint("TOP", unitFrame.healthBar, "BOTTOM", 0, -2)
        castBar:SetStatusBarTexture(db.healthBarTexture)
        castBar:SetMinMaxValues(0, 1)
        castBar:SetValue(0)
        castBar:Hide()
        
        -- Background
        castBar.bg = castBar:CreateTexture(nil, "BACKGROUND")
        castBar.bg:SetAllPoints()
        castBar.bg:SetColorTexture(0, 0, 0, 0.7)
        
        -- Border
        castBar.border = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
        castBar.border:SetPoint("TOPLEFT", -1, 1)
        castBar.border:SetPoint("BOTTOMRIGHT", 1, -1)
        castBar.border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        castBar.border:SetBackdropBorderColor(0, 0, 0, 1)
        
        -- Spell name
        castBar.spellText = castBar:CreateFontString(nil, "OVERLAY")
        castBar.spellText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        castBar.spellText:SetPoint("CENTER")
        
        -- Shield icon for non-interruptible
        castBar.shield = castBar:CreateTexture(nil, "OVERLAY")
        castBar.shield:SetSize(14, 14)
        castBar.shield:SetPoint("LEFT", castBar, "LEFT", 2, 0)
        castBar.shield:SetTexture("Interface\\CastingBar\\UI-CastingBar-Small-Shield")
        castBar.shield:Hide()
        
        -- Interrupt glow (green = kick it!)
        castBar.interruptGlow = castBar:CreateTexture(nil, "BACKGROUND", nil, -1)
        castBar.interruptGlow:SetPoint("TOPLEFT", -4, 4)
        castBar.interruptGlow:SetPoint("BOTTOMRIGHT", 4, -4)
        castBar.interruptGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
        castBar.interruptGlow:SetBlendMode("ADD")
        castBar.interruptGlow:Hide()
        
        data.castBar = castBar
    end
    
    -- Register for cast events
    self:SetupCastBarEvents(nameplate, unit)
end

function Nameplates:SetupCastBarEvents(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data or not data.castBar then return end
    
    local castBar = data.castBar
    
    -- Update function
    castBar:SetScript("OnUpdate", function(self, elapsed)
        if not data.casting and not data.channeling then
            self:Hide()
            return
        end
        
        local currentTime = GetTime()
        
        if data.casting then
            local progress = (currentTime - data.startTime) / (data.endTime - data.startTime)
            if progress >= 1 then
                self:Hide()
                data.casting = false
                return
            end
            self:SetValue(progress)
        elseif data.channeling then
            local progress = (data.endTime - currentTime) / (data.endTime - data.startTime)
            if progress <= 0 then
                self:Hide()
                data.channeling = false
                return
            end
            self:SetValue(progress)
        end
    end)
    
    -- Check for current cast
    self:UpdateCastBar(nameplate, unit)
end

function Nameplates:UpdateCastBar(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data or not data.castBar then return end
    
    local castBar = data.castBar
    
    -- Check for casting
    local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    
    if name then
        data.casting = true
        data.channeling = false
        data.startTime = startTime / 1000
        data.endTime = endTime / 1000
        
        castBar.spellText:SetText(name)
        castBar:SetValue(0)
        
        -- Color based on interruptibility
        if notInterruptible then
            castBar:SetStatusBarColor(unpack(db.nonInterruptibleColor))
            castBar.shield:Show()
            castBar.interruptGlow:Hide()
            castBar.border:SetBackdropBorderColor(0.7, 0.2, 0.2, 1)
        else
            castBar:SetStatusBarColor(unpack(db.interruptibleColor))
            castBar.shield:Hide()
            castBar.interruptGlow:Show()
            castBar.interruptGlow:SetVertexColor(0.3, 1.0, 0.3, 0.5)  -- Green glow = KICK IT!
            castBar.border:SetBackdropBorderColor(0.3, 1.0, 0.3, 1)
        end
        
        castBar:Show()
        return
    end
    
    -- Check for channeling
    name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
    
    if name then
        data.casting = false
        data.channeling = true
        data.startTime = startTime / 1000
        data.endTime = endTime / 1000
        
        castBar.spellText:SetText(name)
        castBar:SetValue(1)
        
        if notInterruptible then
            castBar:SetStatusBarColor(unpack(db.nonInterruptibleColor))
            castBar.shield:Show()
            castBar.interruptGlow:Hide()
            castBar.border:SetBackdropBorderColor(0.7, 0.2, 0.2, 1)
        else
            castBar:SetStatusBarColor(unpack(db.interruptibleColor))
            castBar.shield:Hide()
            castBar.interruptGlow:Show()
            castBar.interruptGlow:SetVertexColor(0.3, 1.0, 0.3, 0.5)
            castBar.border:SetBackdropBorderColor(0.3, 1.0, 0.3, 1)
        end
        
        castBar:Show()
        return
    end
    
    -- No cast
    data.casting = false
    data.channeling = false
    castBar:Hide()
end

function Nameplates:UpdateNameplateColor(nameplate, unit)
    local unitFrame = nameplate.UnitFrame
    if not unitFrame or not unitFrame.healthBar then return end
    
    local healthBar = unitFrame.healthBar
    local r, g, b
    
    -- Check if quest mob first
    if db.showQuestIndicator and self:IsQuestMob(unit) then
        r, g, b = unpack(db.questColor)
    -- Class colors for players
    elseif db.useClassColors and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class and CLASS_COLORS[class] then
            local color = CLASS_COLORS[class]
            r, g, b = color.r, color.g, color.b
        end
    -- Threat colors
    elseif db.useThreatColors and UnitThreatSituation("player", unit) then
        local status = UnitThreatSituation("player", unit)
        if status == 3 then
            r, g, b = unpack(db.threatHigh)
        elseif status == 2 then
            r, g, b = unpack(db.threatMed)
        elseif status == 1 then
            r, g, b = unpack(db.threatMed)
        else
            r, g, b = unpack(db.threatLow)
        end
    -- Reaction colors
    elseif UnitIsTapDenied(unit) then
        r, g, b = unpack(db.tappedColor)
    elseif UnitIsFriend("player", unit) then
        r, g, b = unpack(db.friendlyColor)
    elseif UnitIsEnemy("player", unit) then
        r, g, b = unpack(db.enemyColor)
    else
        r, g, b = unpack(db.neutralColor)
    end
    
    if r then
        healthBar:SetStatusBarColor(r, g, b)
    end
end

function Nameplates:UpdateThreat(unit)
    if not unit then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate and modifiedPlates[nameplate] then
        self:UpdateNameplateColor(nameplate, unit)
    end
end

function Nameplates:UpdateHealth(unit)
    if not unit then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate and modifiedPlates[nameplate] then
        self:UpdateHealthText(nameplate, unit)
        
        -- Also update cast bar
        self:UpdateCastBar(nameplate, unit)
    end
end

function Nameplates:UpdateAllQuestIndicators()
    for nameplate, data in pairs(modifiedPlates) do
        if data.unit then
            self:AddQuestIndicator(nameplate, data.unit)
        end
    end
end

-- Cast event handler (global)
local castEvents = CreateFrame("Frame")
castEvents:RegisterEvent("UNIT_SPELLCAST_START")
castEvents:RegisterEvent("UNIT_SPELLCAST_STOP")
castEvents:RegisterEvent("UNIT_SPELLCAST_FAILED")
castEvents:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
castEvents:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
castEvents:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")

castEvents:SetScript("OnEvent", function(self, event, unit)
    if not unit then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate and modifiedPlates[nameplate] then
        Nameplates:UpdateCastBar(nameplate, unit)
    end
end)

-- Slash command handler
function Nameplates:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        MithUI:Print("Nameplates " .. (db.enabled and "enabled" or "disabled"))
        if db.enabled then
            self:SetupNameplates()
        end
        
    elseif cmd == "theme" then
        local themeName = args[2]
        if themeName and THEMES[themeName] then
            db.theme = themeName
            MithUI:Print("Theme set to: " .. THEMES[themeName].name)
            -- Refresh all nameplates
            for nameplate, data in pairs(modifiedPlates) do
                if data.unit then
                    self:StyleNameplate(nameplate, data.unit)
                end
            end
        else
            MithUI:Print("Available themes:")
            for name, theme in pairs(THEMES) do
                local current = (db.theme == name) and " |cff00ff00(current)|r" or ""
                print("  |cff00ff00" .. name .. "|r - " .. theme.name .. current)
            end
        end
        
    elseif cmd == "quest" then
        db.showQuestIndicator = not db.showQuestIndicator
        MithUI:Print("Quest indicator " .. (db.showQuestIndicator and "shown" or "hidden"))
        
    elseif cmd == "threat" then
        db.useThreatColors = not db.useThreatColors
        MithUI:Print("Threat colors " .. (db.useThreatColors and "enabled" or "disabled"))
        
    elseif cmd == "class" then
        db.useClassColors = not db.useClassColors
        MithUI:Print("Class colors " .. (db.useClassColors and "enabled" or "disabled"))
        
    elseif cmd == "cast" then
        db.showCastBar = not db.showCastBar
        MithUI:Print("Cast bars " .. (db.showCastBar and "shown" or "hidden"))
        
    elseif cmd == "health" then
        db.showHealthText = not db.showHealthText
        MithUI:Print("Health text " .. (db.showHealthText and "shown" or "hidden"))
        
    elseif cmd == "target" then
        db.showTargetHighlight = not db.showTargetHighlight
        MithUI:Print("Target highlight " .. (db.showTargetHighlight and "enabled" or "disabled"))
        
    else
        MithUI:Print("Nameplate commands:")
        print("  |cff00ff00/np toggle|r - Enable/disable")
        print("  |cff00ff00/np theme [name]|r - Change theme (grey/neon/clean/thin/headline)")
        print("  |cff00ff00/np quest|r - Toggle quest mob indicator (orange)")
        print("  |cff00ff00/np threat|r - Toggle threat colors")
        print("  |cff00ff00/np class|r - Toggle class colors")
        print("  |cff00ff00/np cast|r - Toggle cast bars")
        print("  |cff00ff00/np health|r - Toggle health text")
        print("  |cff00ff00/np target|r - Toggle target highlight")
        print("")
        print("  |cff00ff00Green glow|r on cast bar = INTERRUPT!")
        print("  |cff00ff00Orange|r health bar = Quest mob")
    end
end

-- Slash command
SLASH_MITHPLATES1 = "/mithplates"
SLASH_MITHPLATES2 = "/np"

SlashCmdList["MITHPLATES"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    Nameplates:SlashCommand(args)
end
