-- MithUI Radial Menu Module
-- OPie-style radial menu with scroll wheel ring switching

local addonName, MithUI = ...

local RadialMenu = {}
MithUI:RegisterModule("radialMenu", RadialMenu)

local db
local isOpen = false
local currentRing = 1  -- Start at ring 1 (Mounts), scroll to switch
local hoveredSlot = nil
local centerX, centerY = 0, 0

-- Main frame
local frame = CreateFrame("Frame", "MithUIRadialMenu", UIParent)
frame:SetFrameStrata("DIALOG")
frame:SetFrameLevel(100)
frame:SetSize(300, 300)
frame:SetPoint("CENTER")
frame:Hide()

-- Ring name indicator in center
local ringIndicator = frame:CreateFontString(nil, "OVERLAY")
ringIndicator:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
ringIndicator:SetPoint("CENTER", frame, "CENTER", 0, 0)

-- Slot buttons
local slots = {}
local NUM_SLOTS = 12

-- Ring definitions
local rings = {}

-- Known hearthstone toy IDs
local HEARTHSTONE_TOYS = {
    54452, 64488, 93672, 142542, 162973, 163045, 163206, 165669, 165670,
    165802, 166746, 166747, 168907, 172179, 180290, 182773, 183716, 184353,
    188952, 190196, 190237, 193588, 200630, 206195, 208704, 209035, 210455, 212337,
}

-- Class spells
local CLASS_SPELLS = {
    DEATHKNIGHT = {"Death Gate"},
    DRUID = {"Dreamwalk", "Teleport: Moonglade"},
    MAGE = {"Teleport: Stormwind", "Teleport: Orgrimmar", "Teleport: Dalaran - Broken Isles"},
    MONK = {"Zen Pilgrimage"},
    SHAMAN = {"Astral Recall"},
    WARLOCK = {"Ritual of Summoning", "Create Soulwell"},
}

function RadialMenu:OnInitialize()
    MithUI.defaults.radialMenu = {
        enabled = true,
        scale = 1.0,
        ringRadius = 100,
        buttonSize = 44,
        useFavoriteMounts = true,
    }
end

function RadialMenu:OnEnable()
    db = MithUIDB.radialMenu
    C_Timer.After(2, function()
        RadialMenu:BuildRings()
        RadialMenu:CreateSlots()
    end)
end

function RadialMenu:BuildRings()
    rings = {}
    
    -- Ring 1: Mounts
    local mountRing = {
        name = "Mounts",
        color = {0.6, 0.4, 1.0},
        items = {{type = "mount", id = 0, name = "Random Favorite", icon = 413588}}
    }
    
    -- Get favorite mounts
    local mountIDs = C_MountJournal.GetMountIDs()
    if mountIDs then
        for _, mountID in ipairs(mountIDs) do
            local name, spellID, icon, _, _, _, isFavorite, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            if isCollected and isFavorite then
                table.insert(mountRing.items, {type = "mount", id = mountID, name = name, icon = icon})
            end
        end
    end
    table.insert(rings, mountRing)
    
    -- Ring 2: Hearthstones
    local hearthRing = {
        name = "Hearthstones", 
        color = {0.3, 0.8, 0.5},
        items = {}
    }
    
    -- Regular hearthstone
    if C_Item.GetItemCount(6948) > 0 then
        table.insert(hearthRing.items, {type = "item", id = 6948, name = "Hearthstone", icon = 134414})
    end
    -- Dalaran HS
    if C_Item.GetItemCount(140192) > 0 then
        table.insert(hearthRing.items, {type = "item", id = 140192, name = "Dalaran Hearthstone", icon = 1041860})
    end
    -- Garrison HS  
    if C_Item.GetItemCount(110560) > 0 then
        table.insert(hearthRing.items, {type = "item", id = 110560, name = "Garrison Hearthstone", icon = 1041860})
    end
    -- Hearthstone toys
    for _, toyID in ipairs(HEARTHSTONE_TOYS) do
        if PlayerHasToy(toyID) then
            local _, toyName, icon = C_ToyBox.GetToyInfo(toyID)
            if toyName then
                table.insert(hearthRing.items, {type = "toy", id = toyID, name = toyName, icon = icon})
            end
        end
    end
    table.insert(rings, hearthRing)
    
    -- Ring 3: Class abilities
    local _, playerClass = UnitClass("player")
    local classSpells = CLASS_SPELLS[playerClass]
    if classSpells then
        local classRing = {name = "Class", color = {1.0, 0.5, 0.3}, items = {}}
        for _, spellName in ipairs(classSpells) do
            local spellInfo = C_Spell.GetSpellInfo(spellName)
            if spellInfo and (IsSpellKnown(spellInfo.spellID) or IsPlayerSpell(spellInfo.spellID)) then
                table.insert(classRing.items, {type = "spell", id = spellInfo.spellID, name = spellInfo.name, icon = spellInfo.iconID})
            end
        end
        if #classRing.items > 0 then
            table.insert(rings, classRing)
        end
    end
end

function RadialMenu:CreateSlots()
    local buttonSize = db.buttonSize or 44
    
    for i = 1, NUM_SLOTS do
        if not slots[i] then
            local slot = CreateFrame("Button", "MithUIRadialSlot"..i, frame, "SecureActionButtonTemplate")
            slot:SetSize(buttonSize, buttonSize)
            
            -- Background
            slot.bg = slot:CreateTexture(nil, "BACKGROUND")
            slot.bg:SetAllPoints()
            slot.bg:SetColorTexture(0.1, 0.1, 0.1, 0.85)
            
            -- Icon
            slot.icon = slot:CreateTexture(nil, "ARTWORK")
            slot.icon:SetPoint("TOPLEFT", 3, -3)
            slot.icon:SetPoint("BOTTOMRIGHT", -3, 3)
            slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            
            -- Border
            slot.border = CreateFrame("Frame", nil, slot, "BackdropTemplate")
            slot.border:SetAllPoints()
            slot.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
            slot.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
            
            -- Highlight on hover
            slot:SetScript("OnEnter", function(self)
                self.border:SetBackdropBorderColor(1, 0.8, 0, 1)
                self:SetScale(1.15)
                if self.tooltipText then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.tooltipText, 1, 1, 1)
                    GameTooltip:Show()
                end
            end)
            
            slot:SetScript("OnLeave", function(self)
                local ring = rings[currentRing]
                if ring then
                    local r, g, b = unpack(ring.color)
                    self.border:SetBackdropBorderColor(r * 0.8, g * 0.8, b * 0.8, 1)
                end
                self:SetScale(1.0)
                GameTooltip:Hide()
            end)
            
            slots[i] = slot
        end
        slots[i]:SetSize(buttonSize, buttonSize)
        slots[i]:Hide()
    end
end

function RadialMenu:UpdateRing()
    local ring = rings[currentRing]
    if not ring then return end
    
    -- Update center text
    ringIndicator:SetText(ring.name .. " (" .. currentRing .. "/" .. #rings .. ")")
    local r, g, b = unpack(ring.color)
    ringIndicator:SetTextColor(r, g, b)
    
    -- Hide all slots first
    for i = 1, NUM_SLOTS do
        slots[i]:Hide()
    end
    
    local items = ring.items
    local numItems = #items
    if numItems == 0 then return end
    
    local radius = db.ringRadius or 100
    local buttonSize = db.buttonSize or 44
    
    -- Position items in a circle
    for i, item in ipairs(items) do
        if i > NUM_SLOTS then break end
        
        local slot = slots[i]
        local angle = ((i - 1) / numItems) * 360 - 90  -- Start from top
        local rad = math.rad(angle)
        local x = math.cos(rad) * radius
        local y = math.sin(rad) * radius
        
        slot:ClearAllPoints()
        slot:SetPoint("CENTER", frame, "CENTER", x, y)
        slot:SetSize(buttonSize, buttonSize)
        
        -- Configure the slot
        slot.tooltipText = item.name
        slot.icon:SetTexture(item.icon or 134400)
        
        -- Set up click action
        slot:SetAttribute("type", nil)
        slot:SetAttribute("spell", nil)
        slot:SetAttribute("item", nil)
        slot:SetAttribute("toy", nil)
        slot:SetAttribute("macrotext", nil)
        
        if item.type == "spell" then
            slot:SetAttribute("type", "spell")
            slot:SetAttribute("spell", item.id)
        elseif item.type == "item" then
            slot:SetAttribute("type", "item")
            slot:SetAttribute("item", "item:" .. item.id)
        elseif item.type == "toy" then
            slot:SetAttribute("type", "toy")
            slot:SetAttribute("toy", item.id)
        elseif item.type == "mount" then
            slot:SetAttribute("type", "macro")
            slot:SetAttribute("macrotext", "/run C_MountJournal.SummonByID(" .. item.id .. ")")
        end
        
        -- Border color
        slot.border:SetBackdropBorderColor(r * 0.8, g * 0.8, b * 0.8, 1)
        slot:Show()
    end
end

function RadialMenu:Open()
    if InCombatLockdown() then
        MithUI:Print("Cannot open menu in combat")
        return
    end
    
    self:BuildRings()
    
    -- Center on cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    centerX = x / scale
    centerY = y / scale
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    frame:SetScale(db.scale or 1.0)
    
    self:UpdateRing()
    frame:Show()
    isOpen = true
end

function RadialMenu:Close()
    frame:Hide()
    isOpen = false
    for i = 1, NUM_SLOTS do
        slots[i]:SetScale(1.0)
    end
end

function RadialMenu:Toggle()
    if isOpen then
        self:Close()
    else
        self:Open()
    end
end

function RadialMenu:NextRing()
    currentRing = currentRing + 1
    if currentRing > #rings then currentRing = 1 end
    self:UpdateRing()
end

function RadialMenu:PrevRing()
    currentRing = currentRing - 1
    if currentRing < 1 then currentRing = #rings end
    self:UpdateRing()
end

function RadialMenu:OpenRing(ringNum)
    if ringNum and ringNum >= 1 and ringNum <= #rings then
        currentRing = ringNum
    end
    self:Open()
end

-- Scroll wheel to change rings
frame:EnableMouseWheel(true)
frame:SetScript("OnMouseWheel", function(self, delta)
    if delta > 0 then
        RadialMenu:NextRing()
    else
        RadialMenu:PrevRing()
    end
end)

-- Right click or ESC to close
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        RadialMenu:Close()
    end
end)

-- Slash commands
SLASH_MITHPIE1 = "/mp"
SlashCmdList["MITHPIE"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word:lower()) end
    
    local cmd = args[1]
    if not cmd or cmd == "" then
        RadialMenu:Toggle()
    elseif cmd == "mounts" then
        RadialMenu:OpenRing(1)
    elseif cmd == "hearth" then
        RadialMenu:OpenRing(2)
    elseif cmd == "class" then
        RadialMenu:OpenRing(3)
    elseif cmd == "refresh" then
        RadialMenu:BuildRings()
        MithUI:Print("Rings refreshed")
    elseif cmd == "scale" then
        local s = tonumber(args[2])
        if s then db.scale = s; frame:SetScale(s) end
    elseif cmd == "radius" then
        local r = tonumber(args[2])
        if r then db.ringRadius = r; RadialMenu:UpdateRing() end
    else
        MithUI:Print("Radial Menu: /mp [mounts|hearth|class|refresh]")
        print("  Scroll wheel changes rings when open")
    end
end
