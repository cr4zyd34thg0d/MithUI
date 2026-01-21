-- MithUI Tooltip Enhancements Module
-- Target of target, guild info

local addonName, MithUI = ...

local Tooltips = {}
MithUI:RegisterModule("tooltips", Tooltips)

local db

function Tooltips:OnInitialize()
    MithUI.defaults.tooltips = {
        enabled = true,
        showTargetOfTarget = true,
        showGuild = true,
        showItemID = false,
        showSpellID = false,
    }
end

function Tooltips:OnEnable()
    db = MithUIDB.tooltips
    if not db then return end
    
    -- Use TooltipDataProcessor for WoW 10.0+
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        -- Unit tooltips
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
            if not db or not db.enabled then return end
            Tooltips:OnUnitTooltip(tooltip)
        end)
        
        -- Item tooltips
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if db and db.enabled and db.showItemID and data and data.id then
                tooltip:AddLine("Item ID: " .. data.id, 0.5, 0.5, 0.5)
            end
        end)
        
        -- Spell tooltips
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
            if db and db.enabled and db.showSpellID and data and data.id then
                tooltip:AddLine("Spell ID: " .. data.id, 0.5, 0.5, 0.5)
            end
        end)
    end
end

function Tooltips:OnUnitTooltip(tooltip)
    local _, unit = tooltip:GetUnit()
    if not unit then return end
    
    -- Target of Target
    if db.showTargetOfTarget then
        local tot = unit .. "target"
        if UnitExists(tot) then
            local totName = UnitName(tot)
            tooltip:AddLine("Targeting: " .. (totName or "Unknown"), 1, 0.8, 0)
        end
    end
    
    -- Guild
    if db.showGuild and UnitIsPlayer(unit) then
        local guild = GetGuildInfo(unit)
        if guild then
            tooltip:AddLine("<" .. guild .. ">", 0.4, 0.8, 0.4)
        end
    end
end

-- Slash command
SLASH_MITHTOOLTIP1 = "/tt"
SlashCmdList["MITHTOOLTIP"] = function(msg)
    if not db then return end
    local cmd = msg:lower():match("^%s*(%S+)") or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        MithUI:Print("Tooltips " .. (db.enabled and "enabled" or "disabled"))
    elseif cmd == "tot" then
        db.showTargetOfTarget = not db.showTargetOfTarget
        MithUI:Print("Target of Target " .. (db.showTargetOfTarget and "shown" or "hidden"))
    elseif cmd == "guild" then
        db.showGuild = not db.showGuild
        MithUI:Print("Guild " .. (db.showGuild and "shown" or "hidden"))
    else
        MithUI:Print("Tooltip: /tt [toggle|tot|guild]")
    end
end
