-- MithUI Tooltip Enhancements Module
-- Item level, spec, guild info, target of target

local addonName, MithUI = ...

local Tooltips = {}
MithUI:RegisterModule("tooltips", Tooltips)

local db

-- Default settings
local defaults = {
    enabled = true,
    showItemLevel = true,
    showSpec = true,
    showGuild = true,
    showTargetOfTarget = true,
    showItemID = false,
    showSpellID = false,
    classColors = true,
    healthText = true,
}

-- Class colors
local CLASS_COLORS = {
    WARRIOR = {0.78, 0.61, 0.43},
    PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45},
    ROGUE = {1.00, 0.96, 0.41},
    PRIEST = {1.00, 1.00, 1.00},
    DEATHKNIGHT = {0.77, 0.12, 0.23},
    SHAMAN = {0.00, 0.44, 0.87},
    MAGE = {0.41, 0.80, 0.94},
    WARLOCK = {0.58, 0.51, 0.79},
    MONK = {0.00, 1.00, 0.59},
    DRUID = {1.00, 0.49, 0.04},
    DEMONHUNTER = {0.64, 0.19, 0.79},
    EVOKER = {0.20, 0.58, 0.50},
}

function Tooltips:OnInitialize()
    MithUI.defaults.tooltips = defaults
end

function Tooltips:OnEnable()
    db = MithUIDB.tooltips
    self:HookTooltips()
end

function Tooltips:HookTooltips()
    -- Hook GameTooltip for unit info
    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        if not db.enabled then return end
        Tooltips:OnTooltipSetUnit(self)
    end)
    
    -- Hook for item tooltips
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
        if not db.enabled then return end
        Tooltips:OnTooltipSetItem(tooltip, data)
    end)
    
    -- Hook for spell tooltips
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
        if not db.enabled then return end
        Tooltips:OnTooltipSetSpell(tooltip, data)
    end)
end

function Tooltips:OnTooltipSetUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if not unit then return end
    
    -- Class color the name
    if db.classColors and UnitIsPlayer(unit) then
        local _, class = UnitClass(unit)
        if class and CLASS_COLORS[class] then
            local r, g, b = unpack(CLASS_COLORS[class])
            local name = UnitName(unit)
            -- First line is usually the name
            local line = _G[tooltip:GetName() .. "TextLeft1"]
            if line then
                line:SetTextColor(r, g, b)
            end
        end
    end
    
    -- Guild
    if db.showGuild and UnitIsPlayer(unit) then
        local guild, rank = GetGuildInfo(unit)
        if guild then
            tooltip:AddLine(string.format("<%s> %s", guild, rank or ""), 0.5, 0.5, 1)
        end
    end
    
    -- Spec (for players)
    if db.showSpec and UnitIsPlayer(unit) then
        local specID = GetInspectSpecialization(unit)
        if specID and specID > 0 then
            local _, specName = GetSpecializationInfoByID(specID)
            if specName then
                tooltip:AddLine("Spec: " .. specName, 0.8, 0.8, 0.8)
            end
        end
    end
    
    -- Item Level (for players)
    if db.showItemLevel and UnitIsPlayer(unit) then
        -- Note: This requires inspect data which may not always be available
        if C_PaperDollInfo and C_PaperDollInfo.GetInspectItemLevel then
            local ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
            if ilvl and ilvl > 0 then
                tooltip:AddLine(string.format("Item Level: %.1f", ilvl), 1, 0.82, 0)
            end
        end
    end
    
    -- Target of Target
    if db.showTargetOfTarget then
        local targetUnit = unit .. "target"
        if UnitExists(targetUnit) then
            local targetName = UnitName(targetUnit)
            local targetClass = select(2, UnitClass(targetUnit))
            local r, g, b = 1, 1, 1
            if targetClass and CLASS_COLORS[targetClass] then
                r, g, b = unpack(CLASS_COLORS[targetClass])
            end
            tooltip:AddLine("Targeting: " .. targetName, r, g, b)
        end
    end
    
    -- Health text
    if db.healthText then
        local health = UnitHealth(unit)
        local maxHealth = UnitHealthMax(unit)
        if maxHealth > 0 then
            local percent = math.floor((health / maxHealth) * 100)
            tooltip:AddLine(string.format("Health: %s / %s (%d%%)", 
                self:FormatNumber(health), 
                self:FormatNumber(maxHealth), 
                percent), 0.2, 1, 0.2)
        end
    end
    
    tooltip:Show()
end

function Tooltips:OnTooltipSetItem(tooltip, data)
    if not data or not data.id then return end
    
    local itemID = data.id
    
    -- Show Item ID
    if db.showItemID then
        tooltip:AddLine("Item ID: " .. itemID, 0.5, 0.5, 0.5)
    end
    
    -- Item Level for equipment
    local _, _, _, itemLevel, _, _, _, _, equipLoc = C_Item.GetItemInfo(itemID)
    if itemLevel and itemLevel > 1 and equipLoc and equipLoc ~= "" then
        -- Already shown by default, but we could enhance it
    end
    
    tooltip:Show()
end

function Tooltips:OnTooltipSetSpell(tooltip, data)
    if not data or not data.id then return end
    
    -- Show Spell ID
    if db.showSpellID then
        tooltip:AddLine("Spell ID: " .. data.id, 0.5, 0.5, 0.5)
    end
    
    tooltip:Show()
end

function Tooltips:FormatNumber(num)
    if num >= 1000000000 then
        return string.format("%.1fB", num / 1000000000)
    elseif num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

-- Slash command handler
function Tooltips:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        MithUI:Print("Tooltips " .. (db.enabled and "enabled" or "disabled"))
        
    elseif cmd == "ilvl" then
        db.showItemLevel = not db.showItemLevel
        MithUI:Print("Item Level " .. (db.showItemLevel and "shown" or "hidden"))
        
    elseif cmd == "spec" then
        db.showSpec = not db.showSpec
        MithUI:Print("Spec " .. (db.showSpec and "shown" or "hidden"))
        
    elseif cmd == "guild" then
        db.showGuild = not db.showGuild
        MithUI:Print("Guild " .. (db.showGuild and "shown" or "hidden"))
        
    elseif cmd == "tot" then
        db.showTargetOfTarget = not db.showTargetOfTarget
        MithUI:Print("Target of Target " .. (db.showTargetOfTarget and "shown" or "hidden"))
        
    elseif cmd == "itemid" then
        db.showItemID = not db.showItemID
        MithUI:Print("Item ID " .. (db.showItemID and "shown" or "hidden"))
        
    elseif cmd == "spellid" then
        db.showSpellID = not db.showSpellID
        MithUI:Print("Spell ID " .. (db.showSpellID and "shown" or "hidden"))
        
    else
        MithUI:Print("Tooltip commands:")
        print("  |cff00ff00/tt toggle|r - Enable/disable all")
        print("  |cff00ff00/tt ilvl|r - Toggle item level")
        print("  |cff00ff00/tt spec|r - Toggle spec display")
        print("  |cff00ff00/tt guild|r - Toggle guild info")
        print("  |cff00ff00/tt tot|r - Toggle target of target")
        print("  |cff00ff00/tt itemid|r - Toggle item IDs")
        print("  |cff00ff00/tt spellid|r - Toggle spell IDs")
    end
end

-- Slash command
SLASH_MITHTOOLTIP1 = "/mithtooltip"
SLASH_MITHTOOLTIP2 = "/tt"

SlashCmdList["MITHTOOLTIP"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    Tooltips:SlashCommand(args)
end
