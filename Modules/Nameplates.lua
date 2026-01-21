-- MithUI Nameplates Module
-- Clean nameplates with quest highlighting and interrupt indicators
-- Compatible with WoW 12.0 (Midnight)

local addonName, MithUI = ...

local Nameplates = {}
MithUI:RegisterModule("nameplates", Nameplates)

local db

-- Default settings
local defaults = {
    enabled = true,
    -- Colors
    friendlyColor = {0.3, 0.7, 0.3},
    enemyColor = {0.8, 0.2, 0.2},
    neutralColor = {0.9, 0.7, 0.0},
    questColor = {1.0, 0.5, 0.0},      -- Orange for quest mobs
    tappedColor = {0.5, 0.5, 0.5},
    -- Threat colors
    threatHigh = {1.0, 0.0, 0.0},
    threatMed = {1.0, 0.6, 0.0},
    threatLow = {0.3, 0.7, 0.3},
    useThreatColors = true,
    -- Class colors
    useClassColors = true,
    -- Cast bar
    showCastBar = true,
    interruptGlow = true,
    -- Features
    showQuestIndicator = true,
    showTargetHighlight = true,
    showHealthPercent = true,
}

-- Track modified nameplates
local modifiedPlates = {}

-- Class colors
local CLASS_COLORS = RAID_CLASS_COLORS

function Nameplates:OnInitialize()
    MithUI.defaults.nameplates = defaults
end

function Nameplates:OnEnable()
    db = MithUIDB.nameplates
    if not db then return end
    
    self:SetupCVars()
    self:RegisterEvents()
    
    -- Process existing nameplates
    C_Timer.After(0.5, function()
        for i, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
            local unit = nameplate.namePlateUnitToken
            if unit then
                self:OnNameplateAdded(unit)
            end
        end
    end)
end

function Nameplates:SetupCVars()
    if not db or not db.enabled then return end
    
    -- Basic nameplate settings
    SetCVar("nameplateShowFriendlyNPCs", 0)
    SetCVar("nameplateMotion", 1)
    SetCVar("nameplateOverlapH", 0.8)
    SetCVar("nameplateOverlapV", 1.1)
    SetCVar("nameplateMaxDistance", 60)
    SetCVar("nameplateOtherTopInset", 0.08)
    SetCVar("nameplateOtherBottomInset", 0.1)
end

function Nameplates:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    events:RegisterEvent("PLAYER_TARGET_CHANGED")
    events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    events:RegisterEvent("UNIT_HEALTH")
    events:RegisterEvent("UNIT_SPELLCAST_START")
    events:RegisterEvent("UNIT_SPELLCAST_STOP")
    events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
    events:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
    
    events:SetScript("OnEvent", function(self, event, unit, ...)
        if event == "NAME_PLATE_UNIT_ADDED" then
            Nameplates:OnNameplateAdded(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            Nameplates:OnNameplateRemoved(unit)
        elseif event == "PLAYER_TARGET_CHANGED" then
            Nameplates:UpdateAllTargets()
        elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_HEALTH" then
            Nameplates:UpdateUnit(unit)
        elseif event:match("SPELLCAST") then
            Nameplates:UpdateCastBar(unit)
        end
    end)
end

function Nameplates:OnNameplateAdded(unit)
    if not db or not db.enabled then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    -- Store reference
    modifiedPlates[nameplate] = {unit = unit}
    
    -- Apply our modifications
    self:ModifyNameplate(nameplate, unit)
end

function Nameplates:OnNameplateRemoved(unit)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if nameplate then
        -- Clean up our additions
        local data = modifiedPlates[nameplate]
        if data then
            if data.questIcon then data.questIcon:Hide() end
            if data.targetGlow then data.targetGlow:Hide() end
            if data.healthText then data.healthText:Hide() end
            if data.castGlow then data.castGlow:Hide() end
        end
        modifiedPlates[nameplate] = nil
    end
end

function Nameplates:ModifyNameplate(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data then return end
    
    -- Find the health bar - try multiple paths for compatibility
    local healthBar = self:GetHealthBar(nameplate)
    if not healthBar then return end
    
    data.healthBar = healthBar
    
    -- Apply color
    self:UpdateColor(nameplate, unit)
    
    -- Add quest indicator
    if db.showQuestIndicator then
        self:AddQuestIndicator(nameplate, unit)
    end
    
    -- Add target highlight
    if db.showTargetHighlight then
        self:AddTargetHighlight(nameplate, unit)
        self:UpdateTargetHighlight(nameplate, unit)
    end
    
    -- Add health percent text
    if db.showHealthPercent then
        self:AddHealthText(nameplate, unit)
    end
    
    -- Add cast bar glow
    if db.showCastBar and db.interruptGlow then
        self:AddCastBarGlow(nameplate, unit)
    end
end

function Nameplates:GetHealthBar(nameplate)
    -- Try different paths for the health bar
    if nameplate.UnitFrame and nameplate.UnitFrame.healthBar then
        return nameplate.UnitFrame.healthBar
    elseif nameplate.UnitFrame and nameplate.UnitFrame.HealthBar then
        return nameplate.UnitFrame.HealthBar
    elseif nameplate.UnitFrame and nameplate.UnitFrame.Health then
        return nameplate.UnitFrame.Health
    end
    
    -- Search children for a StatusBar
    for _, child in pairs({nameplate:GetChildren()}) do
        if child.healthBar then return child.healthBar end
        if child.HealthBar then return child.HealthBar end
        -- Check grandchildren
        for _, grandchild in pairs({child:GetChildren()}) do
            if grandchild:IsObjectType("StatusBar") then
                return grandchild
            end
        end
    end
    
    return nil
end

function Nameplates:GetCastBar(nameplate)
    if nameplate.UnitFrame and nameplate.UnitFrame.castBar then
        return nameplate.UnitFrame.castBar
    elseif nameplate.UnitFrame and nameplate.UnitFrame.CastBar then
        return nameplate.UnitFrame.CastBar
    end
    return nil
end

function Nameplates:UpdateColor(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data or not data.healthBar then return end
    
    local r, g, b
    
    -- Quest mob (orange) - highest priority
    if db.showQuestIndicator and self:IsQuestMob(unit) then
        r, g, b = unpack(db.questColor)
    -- Class colors for players
    elseif db.useClassColors and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class and CLASS_COLORS and CLASS_COLORS[class] then
            local color = CLASS_COLORS[class]
            r, g, b = color.r, color.g, color.b
        end
    -- Threat colors for enemies
    elseif db.useThreatColors and UnitCanAttack("player", unit) then
        local status = UnitThreatSituation("player", unit)
        if status then
            if status >= 3 then
                r, g, b = unpack(db.threatHigh)
            elseif status >= 2 then
                r, g, b = unpack(db.threatMed)
            elseif status >= 1 then
                r, g, b = unpack(db.threatMed)
            else
                r, g, b = unpack(db.threatLow)
            end
        end
    end
    
    -- Fallback to reaction colors
    if not r then
        if UnitIsTapDenied(unit) then
            r, g, b = unpack(db.tappedColor)
        elseif UnitIsFriend("player", unit) then
            r, g, b = unpack(db.friendlyColor)
        elseif UnitIsEnemy("player", unit) then
            r, g, b = unpack(db.enemyColor)
        else
            r, g, b = unpack(db.neutralColor)
        end
    end
    
    -- Apply color
    if r and data.healthBar.SetStatusBarColor then
        data.healthBar:SetStatusBarColor(r, g, b)
    end
end

function Nameplates:IsQuestMob(unit)
    if not unit or UnitIsPlayer(unit) then return false end
    
    -- Check for quest boss classification
    local classification = UnitClassification(unit)
    if classification == "questboss" then return true end
    
    -- Check tooltip for quest progress text
    local tooltip = _G["MithUIQuestTooltip"]
    if not tooltip then
        tooltip = CreateFrame("GameTooltip", "MithUIQuestTooltip", nil, "GameTooltipTemplate")
    end
    
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltip:SetUnit(unit)
    
    for i = 1, tooltip:NumLines() do
        local line = _G["MithUIQuestTooltipTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and (text:match("%d+/%d+") or text:match("Quest")) then
                tooltip:Hide()
                return true
            end
        end
    end
    
    tooltip:Hide()
    return false
end

function Nameplates:AddQuestIndicator(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data then return end
    
    if not data.questIcon then
        data.questIcon = nameplate:CreateTexture(nil, "OVERLAY")
        data.questIcon:SetSize(20, 20)
        data.questIcon:SetTexture(136814)  -- Quest exclamation mark
    end
    
    -- Position relative to health bar or nameplate
    if data.healthBar then
        data.questIcon:SetPoint("LEFT", data.healthBar, "RIGHT", 4, 0)
    else
        data.questIcon:SetPoint("RIGHT", nameplate, "RIGHT", 20, 0)
    end
    
    local isQuest = self:IsQuestMob(unit)
    if isQuest then
        data.questIcon:Show()
    else
        data.questIcon:Hide()
    end
end

function Nameplates:AddTargetHighlight(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data then return end
    
    if not data.targetGlow then
        data.targetGlow = nameplate:CreateTexture(nil, "BACKGROUND", nil, -8)
        data.targetGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
        data.targetGlow:SetBlendMode("ADD")
        data.targetGlow:SetVertexColor(1, 1, 1, 0.3)
        data.targetGlow:Hide()
    end
    
    -- Position around health bar
    if data.healthBar then
        data.targetGlow:SetPoint("TOPLEFT", data.healthBar, "TOPLEFT", -6, 6)
        data.targetGlow:SetPoint("BOTTOMRIGHT", data.healthBar, "BOTTOMRIGHT", 6, -6)
    else
        data.targetGlow:SetPoint("TOPLEFT", nameplate, "TOPLEFT", -4, 4)
        data.targetGlow:SetPoint("BOTTOMRIGHT", nameplate, "BOTTOMRIGHT", 4, -4)
    end
end

function Nameplates:UpdateTargetHighlight(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data or not data.targetGlow then return end
    
    if UnitIsUnit(unit, "target") then
        data.targetGlow:Show()
        nameplate:SetAlpha(1)
    else
        data.targetGlow:Hide()
        nameplate:SetAlpha(0.85)
    end
end

function Nameplates:AddHealthText(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data or not data.healthBar then return end
    
    if not data.healthText then
        data.healthText = data.healthBar:CreateFontString(nil, "OVERLAY")
        data.healthText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        data.healthText:SetPoint("CENTER", data.healthBar, "CENTER", 0, 0)
        data.healthText:SetTextColor(1, 1, 1)
    end
    
    self:UpdateHealthText(nameplate, unit)
end

function Nameplates:UpdateHealthText(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data or not data.healthText then return end
    
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    if maxHealth > 0 then
        local pct = math.floor((health / maxHealth) * 100)
        data.healthText:SetText(pct .. "%")
    else
        data.healthText:SetText("")
    end
end

function Nameplates:AddCastBarGlow(nameplate, unit)
    local data = modifiedPlates[nameplate]
    if not data then return end
    
    local castBar = self:GetCastBar(nameplate)
    if not castBar then return end
    
    data.castBar = castBar
    
    if not data.castGlow then
        data.castGlow = castBar:CreateTexture(nil, "BACKGROUND", nil, -1)
        data.castGlow:SetPoint("TOPLEFT", castBar, "TOPLEFT", -4, 4)
        data.castGlow:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 4, -4)
        data.castGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
        data.castGlow:SetBlendMode("ADD")
        data.castGlow:Hide()
    end
end

function Nameplates:UpdateCastBar(unit)
    if not unit then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate then return end
    
    local data = modifiedPlates[nameplate]
    if not data or not data.castGlow then return end
    
    -- Check if casting
    local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
    if not name then
        name, _, _, _, _, _, notInterruptible = UnitChannelInfo(unit)
    end
    
    if name then
        if notInterruptible then
            -- Red glow = can't interrupt
            data.castGlow:SetVertexColor(0.8, 0.2, 0.2, 0.5)
            data.castGlow:Show()
        else
            -- GREEN GLOW = INTERRUPT THIS!
            data.castGlow:SetVertexColor(0.2, 1.0, 0.2, 0.6)
            data.castGlow:Show()
        end
    else
        data.castGlow:Hide()
    end
end

function Nameplates:UpdateUnit(unit)
    if not unit then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
    if not nameplate or not modifiedPlates[nameplate] then return end
    
    self:UpdateColor(nameplate, unit)
    self:UpdateHealthText(nameplate, unit)
end

function Nameplates:UpdateAllTargets()
    for nameplate, data in pairs(modifiedPlates) do
        if data.unit then
            self:UpdateTargetHighlight(nameplate, data.unit)
        end
    end
end

-- Slash commands
SLASH_MITHPLATES1 = "/np"
SLASH_MITHPLATES2 = "/mithplates"

SlashCmdList["MITHPLATES"] = function(msg)
    if not db then return end
    
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        MithUI:Print("Nameplates " .. (db.enabled and "enabled" or "disabled"))
        if db.enabled then
            Nameplates:SetupCVars()
        end
        
    elseif cmd == "quest" then
        db.showQuestIndicator = not db.showQuestIndicator
        MithUI:Print("Quest indicator " .. (db.showQuestIndicator and "enabled" or "disabled"))
        
    elseif cmd == "threat" then
        db.useThreatColors = not db.useThreatColors
        MithUI:Print("Threat colors " .. (db.useThreatColors and "enabled" or "disabled"))
        
    elseif cmd == "class" then
        db.useClassColors = not db.useClassColors
        MithUI:Print("Class colors " .. (db.useClassColors and "enabled" or "disabled"))
        
    elseif cmd == "target" then
        db.showTargetHighlight = not db.showTargetHighlight
        MithUI:Print("Target highlight " .. (db.showTargetHighlight and "enabled" or "disabled"))
        
    elseif cmd == "health" then
        db.showHealthPercent = not db.showHealthPercent
        MithUI:Print("Health % " .. (db.showHealthPercent and "shown" or "hidden"))
        
    elseif cmd == "cast" then
        db.showCastBar = not db.showCastBar
        db.interruptGlow = db.showCastBar
        MithUI:Print("Cast bar glow " .. (db.showCastBar and "enabled" or "disabled"))
        
    elseif cmd == "refresh" then
        -- Re-apply to all nameplates
        for i, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
            local unit = nameplate.namePlateUnitToken
            if unit then
                Nameplates:ModifyNameplate(nameplate, unit)
            end
        end
        MithUI:Print("Nameplates refreshed")
        
    else
        MithUI:Print("Nameplate commands:")
        print("  |cff00ff00/np toggle|r - Enable/disable")
        print("  |cff00ff00/np quest|r - Toggle quest mob indicator (orange)")
        print("  |cff00ff00/np threat|r - Toggle threat colors")
        print("  |cff00ff00/np class|r - Toggle class colors (players)")
        print("  |cff00ff00/np target|r - Toggle target highlight")
        print("  |cff00ff00/np health|r - Toggle health %")
        print("  |cff00ff00/np cast|r - Toggle cast bar interrupt glow")
        print("  |cff00ff00/np refresh|r - Refresh all nameplates")
        print("")
        print("  |cff00ff00Green glow|r on cast bar = INTERRUPT!")
        print("  |cffff8000Orange|r health bar = Quest mob")
    end
end
