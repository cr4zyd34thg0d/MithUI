-- MithUI Radial Menu Module
-- Nested radial menu - scroll to select, release to cast

local addonName, MithUI = ...

local RadialMenu = {}
MithUI:RegisterModule("radialMenu", RadialMenu)

local db
local isOpen = false
local centerX, centerY = 0, 0

-- Selection state
local activeCategory = nil       -- Which category is being browsed
local selectedItemIndex = 1      -- Currently selected item in category
local selectedItem = nil         -- The actual selected item data

-- Main frame
local frame = CreateFrame("Frame", "MithUIRadialMenu", UIParent)
frame:SetFrameStrata("DIALOG")
frame:SetFrameLevel(100)
frame:SetSize(400, 400)
frame:SetPoint("CENTER")
frame:Hide()

-- Hidden button for keybinding
local keybindButton = CreateFrame("Button", "MithUIRadialMenuButton", UIParent, "SecureActionButtonTemplate")
keybindButton:SetSize(1, 1)
keybindButton:SetPoint("CENTER")
keybindButton:RegisterForClicks("AnyUp", "AnyDown")

-- Center selection display (shows currently selected item)
local selectionFrame = CreateFrame("Frame", nil, frame)
selectionFrame:SetSize(60, 60)
selectionFrame:SetPoint("CENTER")

selectionFrame.bg = selectionFrame:CreateTexture(nil, "BACKGROUND")
selectionFrame.bg:SetAllPoints()
selectionFrame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

selectionFrame.icon = selectionFrame:CreateTexture(nil, "ARTWORK")
selectionFrame.icon:SetPoint("TOPLEFT", 4, -4)
selectionFrame.icon:SetPoint("BOTTOMRIGHT", -4, 4)
selectionFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

selectionFrame.border = selectionFrame:CreateTexture(nil, "OVERLAY")
selectionFrame.border:SetAllPoints()
selectionFrame.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
selectionFrame.border:SetBlendMode("ADD")
selectionFrame.border:SetVertexColor(1, 0.8, 0, 0.8)

selectionFrame.text = selectionFrame:CreateFontString(nil, "OVERLAY")
selectionFrame.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
selectionFrame.text:SetPoint("TOP", selectionFrame, "BOTTOM", 0, -4)
selectionFrame.text:SetWidth(150)

selectionFrame.scrollText = selectionFrame:CreateFontString(nil, "OVERLAY")
selectionFrame.scrollText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
selectionFrame.scrollText:SetPoint("TOP", selectionFrame.text, "BOTTOM", 0, -2)
selectionFrame.scrollText:SetTextColor(0.6, 0.6, 0.6)

-- Category slots (outer ring)
local catSlots = {}
local NUM_CAT_SLOTS = 8

-- Categories data
local categories = {}

-- Hearthstone toys (comprehensive list)
local HEARTHSTONE_TOYS = {
    54452,   -- Ethereal Portal
    64488,   -- The Innkeeper's Daughter
    93672,   -- Dark Portal
    142542,  -- Tome of Town Portal
    162973,  -- Greatfather Winter's Hearthstone
    163045,  -- Headless Horseman's Hearthstone
    163206,  -- Weary Spirit Binding
    165669,  -- Lunar Elder's Hearthstone
    165670,  -- Peddlefeet's Lovely Hearthstone
    165802,  -- Noble Gardener's Hearthstone
    166746,  -- Fire Eater's Hearthstone
    166747,  -- Brewfest Reveler's Hearthstone
    168907,  -- Holographic Digitalization Hearthstone
    172179,  -- Eternal Traveler's Hearthstone
    180290,  -- Night Fae Hearthstone
    182773,  -- Necrolord Hearthstone
    183716,  -- Venthyr Sinstone
    184353,  -- Kyrian Hearthstone
    188952,  -- Dominated Hearthstone
    190196,  -- Enlightened Hearthstone
    190237,  -- Broker Translocation Matrix
    193588,  -- Timewalker's Hearthstone
    200630,  -- Ohn'ir Windsage's Hearthstone
    206195,  -- Path of the Naaru
    208704,  -- Deepdweller's Earthen Hearthstone
    209035,  -- Hearthstone of the Flame
    210455,  -- Draenic Hologem
    212337,  -- Stone of the Hearth
    208802,  -- Notorious Thread's Hearthstone
}

-- Class teleport/utility spells by class
local CLASS_SPELLS = {
    DEATHKNIGHT = {
        50977,   -- Death Gate
    },
    DRUID = {
        18960,   -- Teleport: Moonglade
        193753,  -- Dreamwalk
    },
    MAGE = {
        3561,    -- Teleport: Stormwind
        3562,    -- Teleport: Ironforge
        3563,    -- Teleport: Undercity
        3565,    -- Teleport: Darnassus
        3566,    -- Teleport: Thunder Bluff
        3567,    -- Teleport: Orgrimmar
        32271,   -- Teleport: Exodar
        32272,   -- Teleport: Silvermoon
        33690,   -- Teleport: Shattrath (Alliance)
        33691,   -- Teleport: Shattrath (Horde)
        49358,   -- Teleport: Stonard
        49359,   -- Teleport: Theramore
        53140,   -- Teleport: Dalaran - Northrend
        88342,   -- Teleport: Tol Barad (Alliance)
        88344,   -- Teleport: Tol Barad (Horde)
        120145,  -- Ancient Teleport: Dalaran
        132621,  -- Teleport: Vale of Eternal Blossoms (Alliance)
        132627,  -- Teleport: Vale of Eternal Blossoms (Horde)
        176242,  -- Teleport: Warspear
        176248,  -- Teleport: Stormshield
        193759,  -- Teleport: Hall of the Guardian
        224869,  -- Teleport: Dalaran - Broken Isles
        281403,  -- Teleport: Boralus
        281404,  -- Teleport: Dazar'alor
        344587,  -- Teleport: Oribos
        395277,  -- Teleport: Valdrakken
        446540,  -- Teleport: Dornogal
    },
    MONK = {
        126892,  -- Zen Pilgrimage
        126895,  -- Zen Pilgrimage: Return
    },
    SHAMAN = {
        556,     -- Astral Recall
    },
    WARLOCK = {
        126,     -- Eye of Kilrogg
        691,     -- Summon Felhunter
        697,     -- Summon Voidwalker
        688,     -- Summon Imp
        712,     -- Summon Succubus
        30146,   -- Summon Felguard
        111771,  -- Demonic Gateway
        698,     -- Ritual of Summoning
    },
    PRIEST = {
        73325,   -- Leap of Faith
    },
    HUNTER = {
        982,     -- Revive Pet
        883,     -- Call Pet 1
        83242,   -- Call Pet 2
        83243,   -- Call Pet 3
        83244,   -- Call Pet 4
        83245,   -- Call Pet 5
    },
}


function RadialMenu:OnInitialize()
    MithUI.defaults.radialMenu = {
        enabled = true,
        scale = 1.0,
        radius = 110,
        buttonSize = 44,
        centerSize = 60,
    }
end

function RadialMenu:OnEnable()
    db = MithUIDB.radialMenu
    C_Timer.After(2, function()
        RadialMenu:BuildCategories()
        RadialMenu:CreateSlots()
    end)
end

function RadialMenu:BuildCategories()
    categories = {}
    
    -- Category 1: Favorite Mounts
    local mounts = {
        name = "Mounts",
        icon = 413588,
        color = {0.6, 0.4, 1.0},
        items = {}
    }
    
    -- Add random favorite first
    table.insert(mounts.items, {
        type = "mount", 
        id = 0, 
        name = "Random Favorite", 
        icon = 413588
    })
    
    -- Get ALL favorite mounts
    local mountIDs = C_MountJournal.GetMountIDs()
    if mountIDs then
        for _, mountID in ipairs(mountIDs) do
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, 
                  isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            
            if isCollected and isFavorite and not shouldHideOnChar then
                table.insert(mounts.items, {
                    type = "mount", 
                    id = mountID, 
                    name = name, 
                    icon = icon,
                    spellID = spellID
                })
            end
        end
    end
    
    if #mounts.items > 0 then
        table.insert(categories, mounts)
    end
    
    -- Category 2: Hearthstones
    local hearths = {
        name = "Hearthstones",
        icon = 134414,
        color = {0.3, 0.8, 0.5},
        items = {}
    }
    
    -- Regular hearthstone (check if in bags)
    local hearthCount = C_Item.GetItemCount(6948)
    if hearthCount and hearthCount > 0 then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(6948)
        table.insert(hearths.items, {
            type = "item", 
            id = 6948, 
            name = itemName or "Hearthstone", 
            icon = itemIcon or 134414
        })
    end
    
    -- Dalaran Hearthstone
    local dalHS = C_Item.GetItemCount(140192)
    if dalHS and dalHS > 0 then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(140192)
        table.insert(hearths.items, {
            type = "item", 
            id = 140192, 
            name = itemName or "Dalaran Hearthstone", 
            icon = itemIcon or 1041860
        })
    end
    
    -- Garrison Hearthstone
    local garHS = C_Item.GetItemCount(110560)
    if garHS and garHS > 0 then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(110560)
        table.insert(hearths.items, {
            type = "item", 
            id = 110560, 
            name = itemName or "Garrison Hearthstone", 
            icon = itemIcon or 1041860
        })
    end
    
    -- Check hearthstone toys
    for _, toyID in ipairs(HEARTHSTONE_TOYS) do
        if PlayerHasToy and PlayerHasToy(toyID) then
            local itemID, toyName, icon = C_ToyBox.GetToyInfo(toyID)
            if toyName and icon then
                table.insert(hearths.items, {
                    type = "toy", 
                    id = toyID, 
                    name = toyName, 
                    icon = icon
                })
            end
        end
    end
    
    if #hearths.items > 0 then
        table.insert(categories, hearths)
    end
    
    -- Note: Class spells removed - they require secure action buttons
    -- which cannot be dynamically configured outside of combat
end


function RadialMenu:CreateSlots()
    local buttonSize = db.buttonSize or 44
    
    for i = 1, NUM_CAT_SLOTS do
        if not catSlots[i] then
            local slot = CreateFrame("Button", "MithUIRadialCat"..i, frame)
            slot:SetSize(buttonSize, buttonSize)
            slot.slotIndex = i
            
            slot.bg = slot:CreateTexture(nil, "BACKGROUND")
            slot.bg:SetAllPoints()
            slot.bg:SetColorTexture(0.1, 0.1, 0.1, 0.85)
            
            slot.icon = slot:CreateTexture(nil, "ARTWORK")
            slot.icon:SetPoint("TOPLEFT", 3, -3)
            slot.icon:SetPoint("BOTTOMRIGHT", -3, 3)
            slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            
            slot.border = CreateFrame("Frame", nil, slot, "BackdropTemplate")
            slot.border:SetAllPoints()
            slot.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
            slot.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
            
            -- Item count
            slot.count = slot:CreateFontString(nil, "OVERLAY")
            slot.count:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            slot.count:SetPoint("BOTTOMRIGHT", -2, 2)
            
            slot:SetScript("OnEnter", function(self)
                RadialMenu:OnCategoryEnter(self)
            end)
            
            slot:SetScript("OnLeave", function(self)
                RadialMenu:OnCategoryLeave(self)
            end)
            
            slot:EnableMouseWheel(true)
            slot:SetScript("OnMouseWheel", function(self, delta)
                RadialMenu:OnScroll(delta)
            end)
            
            catSlots[i] = slot
        end
        catSlots[i]:SetSize(buttonSize, buttonSize)
        catSlots[i]:Hide()
    end
end

function RadialMenu:OnCategoryEnter(slot)
    local catIndex = slot.categoryIndex
    if not catIndex or not categories[catIndex] then return end
    
    local cat = categories[catIndex]
    local r, g, b = unpack(cat.color)
    
    -- Highlight
    slot.border:SetBackdropBorderColor(1, 0.8, 0, 1)
    slot:SetScale(1.1)
    
    -- Set this as active category
    activeCategory = catIndex
    selectedItemIndex = 1
    
    -- Update center to show first item
    self:UpdateSelection()
    
    -- Tooltip
    GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
    GameTooltip:SetText(cat.name, r, g, b)
    GameTooltip:AddLine(#cat.items .. " items - scroll to select", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function RadialMenu:OnCategoryLeave(slot)
    local catIndex = slot.categoryIndex
    if catIndex and categories[catIndex] then
        local r, g, b = unpack(categories[catIndex].color)
        slot.border:SetBackdropBorderColor(r * 0.6, g * 0.6, b * 0.6, 1)
    end
    slot:SetScale(1.0)
    GameTooltip:Hide()
end

function RadialMenu:OnScroll(delta)
    if not activeCategory then return end
    
    local cat = categories[activeCategory]
    if not cat or #cat.items == 0 then return end
    
    if delta > 0 then
        selectedItemIndex = selectedItemIndex - 1
        if selectedItemIndex < 1 then
            selectedItemIndex = #cat.items
        end
    else
        selectedItemIndex = selectedItemIndex + 1
        if selectedItemIndex > #cat.items then
            selectedItemIndex = 1
        end
    end
    
    self:UpdateSelection()
end

function RadialMenu:UpdateSelection()
    if not activeCategory then
        selectionFrame.icon:SetTexture(134400)
        selectionFrame.text:SetText("Hover a category")
        selectionFrame.scrollText:SetText("")
        selectedItem = nil
        self:ConfigureSecureButton()
        return
    end
    
    local cat = categories[activeCategory]
    if not cat or #cat.items == 0 then return end
    
    local item = cat.items[selectedItemIndex]
    if not item then return end
    
    selectedItem = item
    
    local r, g, b = unpack(cat.color)
    
    -- Update center display
    selectionFrame.icon:SetTexture(item.icon or 134400)
    selectionFrame.text:SetText(item.name)
    selectionFrame.text:SetTextColor(r, g, b)
    selectionFrame.border:SetVertexColor(r, g, b, 0.8)
    
    -- Scroll indicator
    selectionFrame.scrollText:SetText(selectedItemIndex .. " / " .. #cat.items)
    
    -- Also update the category slot icon to show current selection
    for i = 1, NUM_CAT_SLOTS do
        if catSlots[i].categoryIndex == activeCategory then
            catSlots[i].icon:SetTexture(item.icon or 134400)
            break
        end
    end
    
    -- Configure secure button for this item (for items that need it)
    self:ConfigureSecureButton()
end

function RadialMenu:UpdateCategoryRing()
    for i = 1, NUM_CAT_SLOTS do
        catSlots[i]:Hide()
    end
    
    local numCats = #categories
    if numCats == 0 then
        selectionFrame.text:SetText("No items found")
        return
    end
    
    local radius = db.radius or 110
    local buttonSize = db.buttonSize or 44
    
    for i, cat in ipairs(categories) do
        if i > NUM_CAT_SLOTS then break end
        
        local slot = catSlots[i]
        local angle = ((i - 1) / numCats) * 360 - 90
        local rad = math.rad(angle)
        local x = math.cos(rad) * radius
        local y = math.sin(rad) * radius
        
        slot:ClearAllPoints()
        slot:SetPoint("CENTER", frame, "CENTER", x, y)
        slot:SetSize(buttonSize, buttonSize)
        
        slot.categoryIndex = i
        slot.icon:SetTexture(cat.icon or 134400)
        
        local r, g, b = unpack(cat.color)
        slot.border:SetBackdropBorderColor(r * 0.6, g * 0.6, b * 0.6, 1)
        slot.count:SetText(#cat.items)
        slot.count:SetTextColor(r, g, b)
        
        slot:Show()
    end
    
    selectionFrame.text:SetText("Hover & scroll")
    selectionFrame.text:SetTextColor(0.7, 0.7, 0.7)
    selectionFrame.scrollText:SetText("")
    selectionFrame.icon:SetTexture(134400)
end


function RadialMenu:UseSelectedItem()
    if not selectedItem then return end
    
    local item = selectedItem
    
    if item.type == "toy" then
        C_ToyBox.UseToy(item.id)
    elseif item.type == "mount" then
        if item.id == 0 then
            C_MountJournal.SummonByID(0)  -- Random favorite
        else
            C_MountJournal.SummonByID(item.id)
        end
    elseif item.type == "item" then
        -- Items need secure button - already configured in UpdateSelection
        -- The keybindButton will handle it
    end
end

function RadialMenu:ConfigureSecureButton()
    if InCombatLockdown() then return end
    
    if not selectedItem then
        keybindButton:SetAttribute("type", nil)
        return
    end
    
    local item = selectedItem
    
    keybindButton:SetAttribute("type", nil)
    keybindButton:SetAttribute("spell", nil)
    keybindButton:SetAttribute("item", nil)
    keybindButton:SetAttribute("toy", nil)
    keybindButton:SetAttribute("macrotext", nil)
    
    if item.type == "item" then
        keybindButton:SetAttribute("type", "item")
        keybindButton:SetAttribute("item", "item:" .. item.id)
    elseif item.type == "toy" then
        keybindButton:SetAttribute("type", "toy")
        keybindButton:SetAttribute("toy", item.id)
    elseif item.type == "mount" then
        keybindButton:SetAttribute("type", "macro")
        if item.id == 0 then
            keybindButton:SetAttribute("macrotext", "/run C_MountJournal.SummonByID(0)")
        else
            keybindButton:SetAttribute("macrotext", "/run C_MountJournal.SummonByID(" .. item.id .. ")")
        end
    end
end

function RadialMenu:Open()
    if InCombatLockdown() then
        MithUI:Print("Cannot open menu in combat")
        return
    end
    
    self:BuildCategories()
    
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    centerX = x / scale
    centerY = y / scale
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    frame:SetScale(db.scale or 1.0)
    
    activeCategory = nil
    selectedItemIndex = 1
    selectedItem = nil
    
    self:UpdateCategoryRing()
    frame:Show()
    isOpen = true
end

function RadialMenu:Close(useItem)
    -- useItem parameter kept for compatibility but mounts/toys handled in keybind OnClick
    -- items handled via secure button attributes
    
    frame:Hide()
    isOpen = false
    activeCategory = nil
    selectedItem = nil
    
    for i = 1, NUM_CAT_SLOTS do
        catSlots[i]:SetScale(1.0)
    end
    GameTooltip:Hide()
end

function RadialMenu:Toggle()
    if isOpen then
        self:Close(false)
    else
        self:Open()
    end
end

-- Keybind button - hold to open, release to use
-- The secure button handles items via attributes set in ConfigureSecureButton
-- Mounts and toys are handled via UseSelectedItem since they work with API calls
keybindButton:SetScript("OnClick", function(self, button, down)
    if down then
        RadialMenu:Open()
    else
        -- Release = close menu
        -- For items: the secure button attributes will fire automatically
        -- For mounts/toys: we call UseSelectedItem
        if selectedItem and (selectedItem.type == "mount" or selectedItem.type == "toy") then
            RadialMenu:UseSelectedItem()
        end
        RadialMenu:Close(false)
    end
end)

-- Scroll on main frame
frame:EnableMouseWheel(true)
frame:SetScript("OnMouseWheel", function(self, delta)
    RadialMenu:OnScroll(delta)
end)

-- Right click to close without using
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        RadialMenu:Close(false)
    elseif button == "LeftButton" then
        -- Left click = use and close
        if selectedItem and (selectedItem.type == "mount" or selectedItem.type == "toy") then
            RadialMenu:UseSelectedItem()
        end
        RadialMenu:Close(false)
    end
end)

-- Make center clickable
selectionFrame:EnableMouse(true)
selectionFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        if selectedItem and (selectedItem.type == "mount" or selectedItem.type == "toy") then
            RadialMenu:UseSelectedItem()
        end
        RadialMenu:Close(false)
    elseif button == "RightButton" then
        RadialMenu:Close(false)
    end
end)
selectionFrame:EnableMouseWheel(true)
selectionFrame:SetScript("OnMouseWheel", function(self, delta)
    RadialMenu:OnScroll(delta)
end)

-- Slash commands
SLASH_MITHPIE1 = "/mp"
SlashCmdList["MITHPIE"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word:lower()) end
    
    local cmd = args[1]
    if not cmd or cmd == "" then
        RadialMenu:Toggle()
    elseif cmd == "refresh" then
        RadialMenu:BuildCategories()
        if isOpen then RadialMenu:UpdateCategoryRing() end
        MithUI:Print("Categories refreshed: " .. #categories .. " found")
        for i, cat in ipairs(categories) do
            print("  " .. cat.name .. ": " .. #cat.items .. " items")
        end
    elseif cmd == "scale" then
        local s = tonumber(args[2])
        if s then 
            db.scale = s
            frame:SetScale(s)
        end
    elseif cmd == "radius" then
        local r = tonumber(args[2])
        if r then 
            db.radius = r
            if isOpen then RadialMenu:UpdateCategoryRing() end
        end
    elseif cmd == "debug" then
        MithUI:Print("Debug info:")
        print("  Categories: " .. #categories)
        for i, cat in ipairs(categories) do
            print("  [" .. i .. "] " .. cat.name .. ": " .. #cat.items .. " items")
        end
        print("  Active: " .. tostring(activeCategory))
        print("  Selected: " .. tostring(selectedItemIndex))
    else
        MithUI:Print("Radial Menu: /mp [refresh|scale|radius|debug]")
        print("  Hold keybind to open, scroll to select, release to use")
        print("  Right-click to cancel")
    end
end
