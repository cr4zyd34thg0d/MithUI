-- MithUI Combat Text Module
-- Clean floating combat text for damage, healing, and events

local addonName, MithUI = ...

local CombatText = {}
MithUI:RegisterModule("combatText", CombatText)

local db

-- Text pools for recycling
local activeTexts = {}
local textPool = {}

-- Animation settings
local ANIMATION_DURATION = 1.5
local FADE_START = 0.7
local FLOAT_DISTANCE = 100

-- Default settings
local defaults = {
    enabled = true,
    showOutgoingDamage = true,
    showIncomingDamage = true,
    showDots = true,
    showPetDamage = true,
    showOutgoingHealing = true,
    showIncomingHealing = true,
    showHots = true,
    showOverhealing = false,
    showMisses = true,
    showCrits = true,
    showKills = true,
    showInterrupts = true,
    showDispels = true,
    fontSize = 24,
    critFontSize = 32,
    fontOutline = true,
    damageColor = {1.0, 0.3, 0.3},
    healingColor = {0.3, 1.0, 0.3},
    critColor = {1.0, 1.0, 0.0},
    missColor = {0.7, 0.7, 0.7},
    offsetX = 0,
    offsetY = 50,
    spreadX = 100,
}

-- Damage school colors
local SCHOOL_COLORS = {
    [1] = {1.0, 1.0, 0.0},
    [2] = {1.0, 0.9, 0.5},
    [4] = {1.0, 0.5, 0.0},
    [8] = {0.3, 1.0, 0.3},
    [16] = {0.5, 0.5, 1.0},
    [32] = {0.5, 0.3, 0.7},
    [64] = {1.0, 0.5, 1.0},
}

-- Create frames at load time (not in combat)
local anchor = CreateFrame("Frame", "MithUICombatTextAnchor", UIParent)
anchor:SetSize(200, 50)
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

local eventFrame = CreateFrame("Frame", "MithUICombatTextEvents", UIParent)
local updateFrame = CreateFrame("Frame", "MithUICombatTextUpdate", UIParent)

function CombatText:OnInitialize()
    MithUI.defaults.combatText = defaults
end

function CombatText:OnEnable()
    db = MithUIDB.combatText
    self:CreateTextPool()
    self:SetupEvents()
    self:DisableBlizzardCombatText()
end

function CombatText:DisableBlizzardCombatText()
    pcall(function()
        SetCVar("floatingCombatTextCombatDamage", 0)
        SetCVar("floatingCombatTextCombatHealing", 0)
        SetCVar("floatingCombatTextCombatDamageDirectionalScale", 0)
        SetCVar("floatingCombatTextFloatMode", 0)
    end)
end

function CombatText:EnableBlizzardCombatText()
    pcall(function()
        SetCVar("floatingCombatTextCombatDamage", 1)
        SetCVar("floatingCombatTextCombatHealing", 1)
    end)
end

function CombatText:CreateTextPool()
    local fontSize = (db and db.fontSize) or 24
    for i = 1, 20 do
        local text = anchor:CreateFontString(nil, "OVERLAY")
        pcall(function()
            text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
        end)
        text:Hide()
        table.insert(textPool, text)
    end
end

function CombatText:GetText()
    local text = table.remove(textPool)
    if not text then
        text = anchor:CreateFontString(nil, "OVERLAY")
    end
    local fontSize = (db and db.fontSize) or 24
    pcall(function()
        text:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "OUTLINE")
    end)
    text:SetAlpha(1)
    text:Show()
    return text
end

function CombatText:ReleaseText(text)
    text:Hide()
    text:SetText("")
    text:ClearAllPoints()
    table.insert(textPool, text)
end

function CombatText:DisplayText(text, color, isCrit, direction)
    if not db or not db.enabled then return end
    
    local textObj = self:GetText()
    textObj:SetText(text)
    textObj:SetTextColor(unpack(color))
    
    local size = isCrit and (db.critFontSize or 32) or (db.fontSize or 24)
    pcall(function()
        textObj:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
    end)
    
    local xOffset = (math.random() - 0.5) * (db.spreadX or 100)
    direction = direction or 1
    
    textObj:SetPoint("CENTER", anchor, "CENTER", xOffset + (db.offsetX or 0), db.offsetY or 50)
    
    table.insert(activeTexts, {
        text = textObj,
        startTime = GetTime(),
        startY = db.offsetY or 50,
        endY = (db.offsetY or 50) + (FLOAT_DISTANCE * direction),
        xOffset = xOffset,
        isCrit = isCrit,
    })
end

function CombatText:SetupEvents()
    -- Register event on the pre-created frame
    eventFrame:UnregisterAllEvents()
    eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    eventFrame:SetScript("OnEvent", function(self, event)
        CombatText:OnCombatLogEvent()
    end)
    
    -- Animation update
    updateFrame:SetScript("OnUpdate", function(self, elapsed)
        local currentTime = GetTime()
        for i = #activeTexts, 1, -1 do
            local data = activeTexts[i]
            local progress = (currentTime - data.startTime) / ANIMATION_DURATION
            
            if progress >= 1 then
                CombatText:ReleaseText(data.text)
                table.remove(activeTexts, i)
            else
                local y = data.startY + (data.endY - data.startY) * progress
                data.text:SetPoint("CENTER", anchor, "CENTER", data.xOffset + (db and db.offsetX or 0), y)
                
                if progress > FADE_START then
                    local fadeProgress = (progress - FADE_START) / (1 - FADE_START)
                    data.text:SetAlpha(1 - fadeProgress)
                end
                
                if data.isCrit and progress < 0.2 then
                    local scale = 1 + (0.3 * (1 - progress / 0.2))
                    local size = ((db and db.critFontSize) or 32) * scale
                    pcall(function()
                        data.text:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
                    end)
                end
            end
        end
    end)
end

function CombatText:OnCombatLogEvent()
    if not db or not db.enabled then return end
    
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    
    if subevent == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical = select(12, CombatLogGetCurrentEventInfo())
        self:HandleDamage(sourceGUID, destGUID, amount, school, critical, "melee", playerGUID, petGUID)
        
    elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "RANGE_DAMAGE" then
        local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical = select(12, CombatLogGetCurrentEventInfo())
        local isDot = subevent == "SPELL_PERIODIC_DAMAGE"
        if not isDot or db.showDots then
            self:HandleDamage(sourceGUID, destGUID, amount, spellSchool, critical, spellName, playerGUID, petGUID)
        end
        
    elseif subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
        local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = select(12, CombatLogGetCurrentEventInfo())
        local isHot = subevent == "SPELL_PERIODIC_HEAL"
        if not isHot or db.showHots then
            self:HandleHealing(sourceGUID, destGUID, amount, overhealing, critical, spellName, playerGUID)
        end
        
    elseif subevent == "SWING_MISSED" or subevent == "SPELL_MISSED" or subevent == "RANGE_MISSED" then
        local missType = subevent == "SWING_MISSED" and select(12, CombatLogGetCurrentEventInfo()) or select(15, CombatLogGetCurrentEventInfo())
        self:HandleMiss(sourceGUID, destGUID, missType, playerGUID)
        
    elseif subevent == "PARTY_KILL" then
        if sourceGUID == playerGUID and db.showKills then
            self:DisplayText("KILLING BLOW", {1.0, 0.2, 0.2}, true, 1)
        end
        
    elseif subevent == "SPELL_INTERRUPT" then
        if sourceGUID == playerGUID and db.showInterrupts then
            local spellName = select(17, CombatLogGetCurrentEventInfo())
            self:DisplayText("Interrupted: " .. (spellName or ""), {1.0, 0.5, 0.0}, false, 1)
        end
        
    elseif subevent == "SPELL_DISPEL" then
        if sourceGUID == playerGUID and db.showDispels then
            local spellName = select(17, CombatLogGetCurrentEventInfo())
            self:DisplayText("Dispelled: " .. (spellName or ""), {0.5, 0.8, 1.0}, false, 1)
        end
    end
end

function CombatText:HandleDamage(sourceGUID, destGUID, amount, school, critical, spellName, playerGUID, petGUID)
    local isOutgoing = sourceGUID == playerGUID or (petGUID and sourceGUID == petGUID)
    local isIncoming = destGUID == playerGUID
    local isPet = petGUID and sourceGUID == petGUID
    
    if isOutgoing and not db.showOutgoingDamage then return end
    if isIncoming and not db.showIncomingDamage then return end
    if isPet and not db.showPetDamage then return end
    if critical and not db.showCrits then critical = false end
    if not isOutgoing and not isIncoming then return end
    
    local text = self:FormatNumber(amount)
    if critical then text = text .. "!" end
    
    local color = SCHOOL_COLORS[school] or db.damageColor
    if critical then color = db.critColor end
    
    self:DisplayText(text, color, critical, isOutgoing and 1 or -1)
end

function CombatText:HandleHealing(sourceGUID, destGUID, amount, overhealing, critical, spellName, playerGUID)
    local isOutgoing = sourceGUID == playerGUID
    local isIncoming = destGUID == playerGUID
    
    if isOutgoing and not db.showOutgoingHealing then return end
    if isIncoming and not isOutgoing and not db.showIncomingHealing then return end
    if critical and not db.showCrits then critical = false end
    if not isOutgoing and not isIncoming then return end
    
    local effectiveHeal = amount - (overhealing or 0)
    if effectiveHeal <= 0 and not db.showOverhealing then return end
    
    local text = "+" .. self:FormatNumber(effectiveHeal)
    if critical then text = text .. "!" end
    
    self:DisplayText(text, critical and db.critColor or db.healingColor, critical, 1)
end

function CombatText:HandleMiss(sourceGUID, destGUID, missType, playerGUID)
    if not db.showMisses then return end
    local isOutgoing = sourceGUID == playerGUID
    local isIncoming = destGUID == playerGUID
    if not isOutgoing and not isIncoming then return end
    self:DisplayText(missType or "MISS", db.missColor, false, isOutgoing and 1 or -1)
end

function CombatText:FormatNumber(num)
    if num >= 1000000 then return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then return string.format("%.1fK", num / 1000) end
    return tostring(math.floor(num))
end

-- Slash commands
SLASH_MITHCOMBATTEXT1 = "/mithct"
SLASH_MITHCOMBATTEXT2 = "/ct"

SlashCmdList["MITHCOMBATTEXT"] = function(msg)
    local cmd = msg:lower():match("^%s*(%S+)") or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        if db.enabled then CombatText:DisableBlizzardCombatText() else CombatText:EnableBlizzardCombatText() end
        MithUI:Print("Combat Text " .. (db.enabled and "enabled" or "disabled"))
    elseif cmd == "test" then
        CombatText:DisplayText("12.5K", db.damageColor, false, 1)
        C_Timer.After(0.2, function() CombatText:DisplayText("45.2K!", db.critColor, true, 1) end)
        C_Timer.After(0.4, function() CombatText:DisplayText("+8.3K", db.healingColor, false, 1) end)
        MithUI:Print("Showing test combat text")
    else
        MithUI:Print("Combat Text: /ct [toggle|test]")
    end
end
