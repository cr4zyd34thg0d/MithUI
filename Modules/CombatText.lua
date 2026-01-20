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
local FADE_START = 0.7  -- Start fading at 70% through animation
local FLOAT_DISTANCE = 100

-- Default settings
local defaults = {
    enabled = true,
    -- Damage
    showOutgoingDamage = true,
    showIncomingDamage = true,
    showDots = true,
    showPetDamage = true,
    -- Healing
    showOutgoingHealing = true,
    showIncomingHealing = true,
    showHots = true,
    showOverhealing = false,
    -- Other
    showMisses = true,
    showCrits = true,
    showKills = true,
    showInterrupts = true,
    showDispels = true,
    -- Appearance
    fontSize = 24,
    critFontSize = 32,
    fontOutline = true,
    damageColor = {1.0, 0.3, 0.3},
    healingColor = {0.3, 1.0, 0.3},
    critColor = {1.0, 1.0, 0.0},
    missColor = {0.7, 0.7, 0.7},
    -- Position
    offsetX = 0,
    offsetY = 50,
    spreadX = 100,  -- Horizontal spread
}

-- Damage school colors
local SCHOOL_COLORS = {
    [1] = {1.0, 1.0, 0.0},    -- Physical (yellow)
    [2] = {1.0, 0.9, 0.5},    -- Holy
    [4] = {1.0, 0.5, 0.0},    -- Fire
    [8] = {0.3, 1.0, 0.3},    -- Nature
    [16] = {0.5, 0.5, 1.0},   -- Frost
    [32] = {0.5, 0.3, 0.7},   -- Shadow
    [64] = {1.0, 0.5, 1.0},   -- Arcane
}

-- Main frame (anchor)
local anchor = CreateFrame("Frame", "MithUICombatTextAnchor", UIParent)
anchor:SetSize(200, 50)
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

function CombatText:OnInitialize()
    MithUI.defaults.combatText = defaults
end

function CombatText:OnEnable()
    db = MithUIDB.combatText
    self:CreateTextPool()
    self:RegisterEvents()
    self:DisableBlizzardCombatText()
end

function CombatText:DisableBlizzardCombatText()
    -- Disable default floating combat text
    SetCVar("floatingCombatTextCombatDamage", 0)
    SetCVar("floatingCombatTextCombatHealing", 0)
    SetCVar("floatingCombatTextCombatDamageDirectionalScale", 0)
    SetCVar("floatingCombatTextFloatMode", 0)
end

function CombatText:EnableBlizzardCombatText()
    -- Re-enable if user disables our module
    SetCVar("floatingCombatTextCombatDamage", 1)
    SetCVar("floatingCombatTextCombatHealing", 1)
end

function CombatText:CreateTextPool()
    -- Pre-create some text objects
    for i = 1, 20 do
        local text = anchor:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", db.fontSize, db.fontOutline and "OUTLINE" or "")
        text:Hide()
        table.insert(textPool, text)
    end
end

function CombatText:GetText()
    local text = table.remove(textPool)
    if not text then
        text = anchor:CreateFontString(nil, "OVERLAY")
    end
    text:SetFont("Fonts\\FRIZQT__.TTF", db.fontSize, db.fontOutline and "OUTLINE" or "")
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
    if not db.enabled then return end
    
    local textObj = self:GetText()
    textObj:SetText(text)
    textObj:SetTextColor(unpack(color))
    
    -- Size based on crit
    local size = isCrit and db.critFontSize or db.fontSize
    textObj:SetFont("Fonts\\FRIZQT__.TTF", size, db.fontOutline and "OUTLINE" or "")
    
    -- Random horizontal offset for spread
    local xOffset = (math.random() - 0.5) * db.spreadX
    
    -- Direction: 1 = up (outgoing), -1 = down (incoming)
    direction = direction or 1
    
    -- Starting position
    textObj:SetPoint("CENTER", anchor, "CENTER", xOffset + db.offsetX, db.offsetY)
    
    -- Animate
    local startTime = GetTime()
    local startY = db.offsetY
    local endY = startY + (FLOAT_DISTANCE * direction)
    
    local animData = {
        text = textObj,
        startTime = startTime,
        startY = startY,
        endY = endY,
        xOffset = xOffset,
        isCrit = isCrit,
    }
    
    table.insert(activeTexts, animData)
end

-- Animation update
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    local currentTime = GetTime()
    
    for i = #activeTexts, 1, -1 do
        local data = activeTexts[i]
        local progress = (currentTime - data.startTime) / ANIMATION_DURATION
        
        if progress >= 1 then
            -- Animation complete
            CombatText:ReleaseText(data.text)
            table.remove(activeTexts, i)
        else
            -- Update position
            local y = data.startY + (data.endY - data.startY) * progress
            data.text:SetPoint("CENTER", anchor, "CENTER", data.xOffset + (db and db.offsetX or 0), y)
            
            -- Fade out
            if progress > FADE_START then
                local fadeProgress = (progress - FADE_START) / (1 - FADE_START)
                data.text:SetAlpha(1 - fadeProgress)
            end
            
            -- Crit scale animation (pulse)
            if data.isCrit and progress < 0.2 then
                local scale = 1 + (0.3 * (1 - progress / 0.2))
                local size = (db and db.critFontSize or 32) * scale
                data.text:SetFont("Fonts\\FRIZQT__.TTF", size, (db and db.fontOutline) and "OUTLINE" or "")
            end
        end
    end
end)

function CombatText:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    events:SetScript("OnEvent", function(self, event)
        CombatText:OnCombatLogEvent()
    end)
end

function CombatText:OnCombatLogEvent()
    local timestamp, subevent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")
    
    -- Damage events
    if subevent == "SWING_DAMAGE" then
        local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing = select(12, CombatLogGetCurrentEventInfo())
        self:HandleDamage(sourceGUID, destGUID, amount, school, critical, "melee", playerGUID, petGUID)
        
    elseif subevent == "SPELL_DAMAGE" or subevent == "SPELL_PERIODIC_DAMAGE" or subevent == "RANGE_DAMAGE" then
        local spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical = select(12, CombatLogGetCurrentEventInfo())
        local isDot = subevent == "SPELL_PERIODIC_DAMAGE"
        if not isDot or db.showDots then
            self:HandleDamage(sourceGUID, destGUID, amount, spellSchool, critical, spellName, playerGUID, petGUID)
        end
        
    -- Healing events
    elseif subevent == "SPELL_HEAL" or subevent == "SPELL_PERIODIC_HEAL" then
        local spellId, spellName, spellSchool, amount, overhealing, absorbed, critical = select(12, CombatLogGetCurrentEventInfo())
        local isHot = subevent == "SPELL_PERIODIC_HEAL"
        if not isHot or db.showHots then
            self:HandleHealing(sourceGUID, destGUID, amount, overhealing, critical, spellName, playerGUID)
        end
        
    -- Miss events
    elseif subevent == "SWING_MISSED" or subevent == "SPELL_MISSED" or subevent == "RANGE_MISSED" then
        local missType
        if subevent == "SWING_MISSED" then
            missType = select(12, CombatLogGetCurrentEventInfo())
        else
            missType = select(15, CombatLogGetCurrentEventInfo())
        end
        self:HandleMiss(sourceGUID, destGUID, missType, playerGUID)
        
    -- Kill events
    elseif subevent == "PARTY_KILL" then
        if sourceGUID == playerGUID and db.showKills then
            self:DisplayText("KILLING BLOW", {1.0, 0.2, 0.2}, true, 1)
        end
        
    -- Interrupt events
    elseif subevent == "SPELL_INTERRUPT" then
        if sourceGUID == playerGUID and db.showInterrupts then
            local spellName = select(17, CombatLogGetCurrentEventInfo())
            self:DisplayText("Interrupted: " .. (spellName or ""), {1.0, 0.5, 0.0}, false, 1)
        end
        
    -- Dispel events
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
    
    -- Check settings
    if isOutgoing and not db.showOutgoingDamage then return end
    if isIncoming and not db.showIncomingDamage then return end
    if isPet and not db.showPetDamage then return end
    if critical and not db.showCrits then critical = false end
    
    if not isOutgoing and not isIncoming then return end
    
    -- Format number
    local text = self:FormatNumber(amount)
    if critical then
        text = text .. "!"
    end
    
    -- Get color
    local color = SCHOOL_COLORS[school] or db.damageColor
    if critical then
        color = db.critColor
    end
    
    -- Direction (up for outgoing, down for incoming)
    local direction = isOutgoing and 1 or -1
    
    self:DisplayText(text, color, critical, direction)
end

function CombatText:HandleHealing(sourceGUID, destGUID, amount, overhealing, critical, spellName, playerGUID)
    local isOutgoing = sourceGUID == playerGUID
    local isIncoming = destGUID == playerGUID
    
    -- Check settings
    if isOutgoing and not db.showOutgoingHealing then return end
    if isIncoming and not isOutgoing and not db.showIncomingHealing then return end
    if critical and not db.showCrits then critical = false end
    
    if not isOutgoing and not isIncoming then return end
    
    -- Handle overhealing
    local effectiveHeal = amount - (overhealing or 0)
    if effectiveHeal <= 0 and not db.showOverhealing then return end
    
    -- Format
    local text = "+" .. self:FormatNumber(effectiveHeal)
    if critical then
        text = text .. "!"
    end
    
    -- Color
    local color = critical and db.critColor or db.healingColor
    
    self:DisplayText(text, color, critical, 1)
end

function CombatText:HandleMiss(sourceGUID, destGUID, missType, playerGUID)
    if not db.showMisses then return end
    
    local isOutgoing = sourceGUID == playerGUID
    local isIncoming = destGUID == playerGUID
    
    if not isOutgoing and not isIncoming then return end
    
    local text = missType or "MISS"
    local direction = isOutgoing and 1 or -1
    
    self:DisplayText(text, db.missColor, false, direction)
end

function CombatText:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(math.floor(num))
end

-- Slash command handler
function CombatText:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        if db.enabled then
            self:DisableBlizzardCombatText()
        else
            self:EnableBlizzardCombatText()
        end
        MithUI:Print("Combat Text " .. (db.enabled and "enabled" or "disabled"))
        
    elseif cmd == "damage" then
        db.showOutgoingDamage = not db.showOutgoingDamage
        MithUI:Print("Outgoing damage " .. (db.showOutgoingDamage and "shown" or "hidden"))
        
    elseif cmd == "healing" then
        db.showOutgoingHealing = not db.showOutgoingHealing
        MithUI:Print("Outgoing healing " .. (db.showOutgoingHealing and "shown" or "hidden"))
        
    elseif cmd == "incoming" then
        db.showIncomingDamage = not db.showIncomingDamage
        MithUI:Print("Incoming damage " .. (db.showIncomingDamage and "shown" or "hidden"))
        
    elseif cmd == "crits" then
        db.showCrits = not db.showCrits
        MithUI:Print("Crits " .. (db.showCrits and "highlighted" or "normal"))
        
    elseif cmd == "dots" then
        db.showDots = not db.showDots
        MithUI:Print("DoTs " .. (db.showDots and "shown" or "hidden"))
        
    elseif cmd == "hots" then
        db.showHots = not db.showHots
        MithUI:Print("HoTs " .. (db.showHots and "shown" or "hidden"))
        
    elseif cmd == "size" then
        local size = tonumber(args[2])
        if size then
            db.fontSize = size
            MithUI:Print("Font size: " .. size)
        end
        
    elseif cmd == "test" then
        -- Show test numbers
        self:DisplayText("12.5K", db.damageColor, false, 1)
        C_Timer.After(0.2, function()
            self:DisplayText("45.2K!", db.critColor, true, 1)
        end)
        C_Timer.After(0.4, function()
            self:DisplayText("+8.3K", db.healingColor, false, 1)
        end)
        C_Timer.After(0.6, function()
            self:DisplayText("DODGE", db.missColor, false, -1)
        end)
        MithUI:Print("Showing test combat text")
        
    else
        MithUI:Print("Combat Text commands:")
        print("  |cff00ff00/ct toggle|r - Enable/disable")
        print("  |cff00ff00/ct damage|r - Toggle outgoing damage")
        print("  |cff00ff00/ct healing|r - Toggle outgoing healing")
        print("  |cff00ff00/ct incoming|r - Toggle incoming damage")
        print("  |cff00ff00/ct crits|r - Toggle crit highlighting")
        print("  |cff00ff00/ct dots|r - Toggle DoT damage")
        print("  |cff00ff00/ct hots|r - Toggle HoT healing")
        print("  |cff00ff00/ct size [num]|r - Set font size")
        print("  |cff00ff00/ct test|r - Show test numbers")
    end
end

-- Slash command
SLASH_MITHCOMBATTEXT1 = "/mithct"
SLASH_MITHCOMBATTEXT2 = "/ct"

SlashCmdList["MITHCOMBATTEXT"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    CombatText:SlashCommand(args)
end
