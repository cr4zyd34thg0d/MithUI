-- MithUI Auto Vendor Module
-- Auto repair, auto sell junk, auto sell specific items

local addonName, MithUI = ...

local AutoVendor = {}
MithUI:RegisterModule("autoVendor", AutoVendor)

local db

-- Default settings
local defaults = {
    enabled = true,
    autoRepair = true,
    useGuildRepair = true,
    autoSellJunk = true,
    autoSellList = {},  -- Custom items to always sell
    neverSellList = {}, -- Items to never sell (by ID)
    showSummary = true,
}

function AutoVendor:OnInitialize()
    -- Add defaults to main defaults
    MithUI.defaults.autoVendor = defaults
end

function AutoVendor:OnEnable()
    db = MithUIDB.autoVendor
    self:RegisterEvents()
end

function AutoVendor:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("MERCHANT_SHOW")
    
    events:SetScript("OnEvent", function(self, event)
        if event == "MERCHANT_SHOW" then
            AutoVendor:OnMerchantShow()
        end
    end)
end

function AutoVendor:OnMerchantShow()
    if not db.enabled then return end
    
    local totalSold = 0
    local itemsSold = 0
    local repairCost = 0
    
    -- Auto Repair
    if db.autoRepair and CanMerchantRepair() then
        local cost, canRepair = GetRepairAllCost()
        if canRepair and cost > 0 then
            local guildRepaired = false
            
            -- Try guild repair first
            if db.useGuildRepair and IsInGuild() then
                local guildMoney = GetGuildBankWithdrawMoney()
                if guildMoney == -1 or guildMoney >= cost then
                    RepairAllItems(true)
                    guildRepaired = true
                    repairCost = cost
                end
            end
            
            -- Fall back to personal gold
            if not guildRepaired then
                if GetMoney() >= cost then
                    RepairAllItems(false)
                    repairCost = cost
                end
            end
        end
    end
    
    -- Auto Sell Junk
    if db.autoSellJunk then
        for bag = 0, 4 do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            for slot = 1, numSlots do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info then
                    local itemID = info.itemID
                    local quality = info.quality
                    
                    -- Check never sell list
                    local neverSell = false
                    for _, id in ipairs(db.neverSellList) do
                        if id == itemID then
                            neverSell = true
                            break
                        end
                    end
                    
                    -- Sell if gray quality (junk) or in custom sell list
                    local shouldSell = false
                    if not neverSell then
                        if quality == 0 then -- Poor/Gray quality
                            shouldSell = true
                        else
                            for _, id in ipairs(db.autoSellList) do
                                if id == itemID then
                                    shouldSell = true
                                    break
                                end
                            end
                        end
                    end
                    
                    if shouldSell then
                        local price = select(11, C_Item.GetItemInfo(itemID)) or 0
                        local count = info.stackCount or 1
                        totalSold = totalSold + (price * count)
                        itemsSold = itemsSold + 1
                        C_Container.UseContainerItem(bag, slot)
                    end
                end
            end
        end
    end
    
    -- Show summary
    if db.showSummary then
        if repairCost > 0 then
            local gold = math.floor(repairCost / 10000)
            local silver = math.floor((repairCost % 10000) / 100)
            local copper = repairCost % 100
            local guildText = db.useGuildRepair and " (guild)" or ""
            MithUI:Print(string.format("Repaired: %dg %ds %dc%s", gold, silver, copper, guildText))
        end
        
        if itemsSold > 0 then
            local gold = math.floor(totalSold / 10000)
            local silver = math.floor((totalSold % 10000) / 100)
            local copper = totalSold % 100
            MithUI:Print(string.format("Sold %d junk items: %dg %ds %dc", itemsSold, gold, silver, copper))
        end
    end
end

-- Slash command handler
function AutoVendor:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        MithUI:Print("Auto Vendor " .. (db.enabled and "enabled" or "disabled"))
        
    elseif cmd == "repair" then
        db.autoRepair = not db.autoRepair
        MithUI:Print("Auto Repair " .. (db.autoRepair and "enabled" or "disabled"))
        
    elseif cmd == "guild" then
        db.useGuildRepair = not db.useGuildRepair
        MithUI:Print("Guild Repair " .. (db.useGuildRepair and "enabled" or "disabled"))
        
    elseif cmd == "junk" then
        db.autoSellJunk = not db.autoSellJunk
        MithUI:Print("Auto Sell Junk " .. (db.autoSellJunk and "enabled" or "disabled"))
        
    elseif cmd == "silent" then
        db.showSummary = not db.showSummary
        MithUI:Print("Summary " .. (db.showSummary and "shown" or "hidden"))
        
    elseif cmd == "addsell" then
        -- Add item to sell list (use with item link or ID)
        local itemID = tonumber(args[2])
        if itemID then
            table.insert(db.autoSellList, itemID)
            local name = C_Item.GetItemInfo(itemID)
            MithUI:Print("Added to sell list: " .. (name or itemID))
        else
            MithUI:Print("Usage: /av addsell [itemID]")
        end
        
    elseif cmd == "neversell" then
        local itemID = tonumber(args[2])
        if itemID then
            table.insert(db.neverSellList, itemID)
            local name = C_Item.GetItemInfo(itemID)
            MithUI:Print("Added to never-sell list: " .. (name or itemID))
        else
            MithUI:Print("Usage: /av neversell [itemID]")
        end
        
    else
        MithUI:Print("Auto Vendor commands:")
        print("  |cff00ff00/av toggle|r - Enable/disable all")
        print("  |cff00ff00/av repair|r - Toggle auto repair")
        print("  |cff00ff00/av guild|r - Toggle guild repair")
        print("  |cff00ff00/av junk|r - Toggle sell junk")
        print("  |cff00ff00/av silent|r - Toggle summary messages")
        print("  |cff00ff00/av addsell [id]|r - Add item to sell list")
        print("  |cff00ff00/av neversell [id]|r - Never sell item")
    end
end

-- Slash command
SLASH_MITHVENDOR1 = "/mithvendor"
SLASH_MITHVENDOR2 = "/av"

SlashCmdList["MITHVENDOR"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    AutoVendor:SlashCommand(args)
end
