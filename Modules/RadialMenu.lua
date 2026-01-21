-- MithUI Radial Menu Module
-- OPie-style radial menu with auto-populated rings

local addonName, MithUI = ...

-- Register keybinding category and names (appears in Key Bindings menu)
BINDING_HEADER_MITHUI = "MithUI"
BINDING_NAME_MITHUI_RADIAL_TOGGLE = "Toggle Radial Menu"
BINDING_NAME_MITHUI_RADIAL_MOUNTS = "Radial Menu: Mounts"
BINDING_NAME_MITHUI_RADIAL_HEARTHS = "Radial Menu: Hearthstones"
BINDING_NAME_MITHUI_RADIAL_CLASS = "Radial Menu: Class"

local RadialMenu = {}
MithUI:RegisterModule("radialMenu", RadialMenu)

local db
local isOpen = false
local currentRing = 0  -- 0 = main category ring, 1+ = sub-rings
local selectedSlot = nil
local hoveredSlot = nil
local centerX, centerY = 0, 0  -- Center of the menu for angle calculation
local subMenuOpen = false  -- Are we in a sub-menu?

-- Known hearthstone toy IDs
local HEARTHSTONE_TOYS = {
    -- Standard Hearthstones
    6948,    -- Hearthstone (item, not toy)
    -- Hearthstone Toys
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
    -- Dalaran/Garrison
    140192,  -- Dalaran Hearthstone
    110560,  -- Garrison Hearthstone
}

-- Class teleport/utility spells
local CLASS_SPELLS = {
    DEATHKNIGHT = {
        {spell = "Death Gate", desc = "Teleport to Acherus"},
        {spell = "Raise Ally", desc = "Battle res"},
    },
    DRUID = {
        {spell = "Teleport: Moonglade", desc = "Teleport to Moonglade"},
        {spell = "Dreamwalk", desc = "Teleport to Emerald Dreamway"},
        {spell = "Rebirth", desc = "Battle res"},
    },
    MAGE = {
        {spell = "Teleport: Stormwind", desc = "Teleport"},
        {spell = "Teleport: Orgrimmar", desc = "Teleport"},
        {spell = "Teleport: Dalaran - Northrend", desc = "Teleport"},
        {spell = "Teleport: Dalaran - Broken Isles", desc = "Teleport"},
        {spell = "Teleport: Valdrakken", desc = "Teleport"},
        {spell = "Teleport: Dornogal", desc = "Teleport"},
        {spell = "Portal: Stormwind", desc = "Portal"},
        {spell = "Portal: Orgrimmar", desc = "Portal"},
    },
    MONK = {
        {spell = "Zen Pilgrimage", desc = "Teleport to Peak of Serenity"},
        {spell = "Transcendence", desc = "Place spirit"},
        {spell = "Transcendence: Transfer", desc = "Swap with spirit"},
    },
    WARLOCK = {
        {spell = "Ritual of Summoning", desc = "Summon party member"},
        {spell = "Create Healthstone", desc = "Create Healthstone"},
        {spell = "Create Soulwell", desc = "Create Soulwell"},
        {spell = "Demonic Gateway", desc = "Create gateway"},
    },
    SHAMAN = {
        {spell = "Astral Recall", desc = "Teleport to hearth"},
        {spell = "Ancestral Spirit", desc = "Resurrect"},
    },
    PALADIN = {
        {spell = "Divine Steed", desc = "Speed boost"},
        {spell = "Blessing of Protection", desc = "Immunity"},
    },
    PRIEST = {
        {spell = "Leap of Faith", desc = "Grip ally"},
        {spell = "Mass Resurrection", desc = "Mass res"},
    },
    EVOKER = {
        {spell = "Dream Flight", desc = "Fly and heal"},
        {spell = "Rescue", desc = "Grip ally"},
    },
}

-- Main frame
local frame = CreateFrame("Frame", "MithUIRadialMenu", UIParent)
frame:SetFrameStrata("DIALOG")
frame:SetSize(300, 300)
frame:SetPoint("CENTER")
frame:Hide()

-- Ring indicator
local ringIndicator = frame:CreateFontString(nil, "OVERLAY")
ringIndicator:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
ringIndicator:SetPoint("CENTER", frame, "CENTER", 0, 0)

-- Category ring (main menu)
local categoryRing = {
    name = "Categories",
    color = {0.5, 0.5, 0.5},
    items = {}  -- Will be populated with ring names
}

-- Slot buttons
local slots = {}
local NUM_SLOTS = 12

-- Ring definitions (will be populated dynamically)
local rings = {}

function RadialMenu:OnInitialize()
    MithUI.defaults.radialMenu = {
        enabled = true,
        scale = 1.0,
        ringRadius = 100,
        buttonSize = 40,
        fadeTime = 0.2,
        customMounts = {},     -- User-selected mount IDs
        useAllHearthstones = true,
        useFavoriteMounts = true,
    }
end

function RadialMenu:OnEnable()
    db = MithUIDB.radialMenu
    
    -- Build rings after a short delay to let game data load
    C_Timer.After(1, function()
        RadialMenu:BuildRings()
        RadialMenu:CreateSlots()
        RadialMenu:SetupKeybind()
    end)
end

function RadialMenu:BuildRings()
    rings = {}
    
    -- Ring 1: Mounts (favorites or custom selection)
    local mountRing = {
        name = "Mounts",
        color = {0.6, 0.4, 1.0},
        icon = 413588,  -- Mount icon
        items = {}
    }
    
    -- Add random favorite mount option
    table.insert(mountRing.items, {
        type = "mount",
        id = 0,
        name = "Random Favorite",
        icon = 413588,
    })
    
    -- Get favorite mounts
    if db.useFavoriteMounts then
        local mountIDs = C_MountJournal.GetMountIDs()
        for _, mountID in ipairs(mountIDs) do
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, 
                  isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            
            if isCollected and isFavorite then
                table.insert(mountRing.items, {
                    type = "mount",
                    id = mountID,
                    name = name,
                    icon = icon,
                    spellID = spellID,
                })
            end
        end
    end
    
    -- Add custom mounts if specified
    if db.customMounts then
        for _, mountID in ipairs(db.customMounts) do
            local name, spellID, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            if isCollected then
                -- Check if not already added
                local exists = false
                for _, item in ipairs(mountRing.items) do
                    if item.id == mountID then exists = true break end
                end
                if not exists then
                    table.insert(mountRing.items, {
                        type = "mount",
                        id = mountID,
                        name = name,
                        icon = icon,
                        spellID = spellID,
                    })
                end
            end
        end
    end
    
    table.insert(rings, mountRing)
    
    -- Ring 2: Hearthstones (auto-detect owned)
    local hearthRing = {
        name = "Hearthstones",
        color = {0.3, 0.8, 0.5},
        icon = 134414,  -- Hearthstone icon
        items = {}
    }
    
    -- Check for regular hearthstone in bags
    local hearthstoneCount = C_Item.GetItemCount(6948)
    if hearthstoneCount > 0 then
        local name, _, _, _, icon = C_Item.GetItemInfo(6948)
        table.insert(hearthRing.items, {
            type = "item",
            id = 6948,
            name = name or "Hearthstone",
            icon = icon or 134414,
        })
    end
    
    -- Check for Dalaran Hearthstone
    local dalaranCount = C_Item.GetItemCount(140192)
    if dalaranCount > 0 then
        local name, _, _, _, icon = C_Item.GetItemInfo(140192)
        table.insert(hearthRing.items, {
            type = "item",
            id = 140192,
            name = name or "Dalaran Hearthstone",
            icon = icon or 1041860,
        })
    end
    
    -- Check for Garrison Hearthstone
    local garrisonCount = C_Item.GetItemCount(110560)
    if garrisonCount > 0 then
        local name, _, _, _, icon = C_Item.GetItemInfo(110560)
        table.insert(hearthRing.items, {
            type = "item",
            id = 110560,
            name = name or "Garrison Hearthstone",
            icon = icon or 1041860,
        })
    end
    
    -- Check for hearthstone toys
    for _, toyID in ipairs(HEARTHSTONE_TOYS) do
        if PlayerHasToy(toyID) then
            local itemID, toyName, icon = C_ToyBox.GetToyInfo(toyID)
            if toyName then
                table.insert(hearthRing.items, {
                    type = "toy",
                    id = toyID,
                    name = toyName,
                    icon = icon,
                })
            end
        end
    end
    
    table.insert(rings, hearthRing)
    
    -- Ring 3: Class Abilities
    local _, playerClass = UnitClass("player")
    local classRing = {
        name = "Class",
        color = {1.0, 0.5, 0.3},
        icon = 136116,  -- Generic class icon
        items = {}
    }
    
    local classSpells = CLASS_SPELLS[playerClass]
    if classSpells then
        for _, spellData in ipairs(classSpells) do
            local spellInfo = C_Spell.GetSpellInfo(spellData.spell)
            if spellInfo then
                -- Check if player knows this spell
                if IsSpellKnown(spellInfo.spellID) or IsPlayerSpell(spellInfo.spellID) then
                    table.insert(classRing.items, {
                        type = "spell",
                        id = spellInfo.spellID,
                        name = spellInfo.name,
                        icon = spellInfo.iconID,
                        desc = spellData.desc,
                    })
                    -- Use first spell icon as ring icon
                    if classRing.icon == 136116 then
                        classRing.icon = spellInfo.iconID
                    end
                end
            end
        end
    end
    
    if #classRing.items > 0 then
        table.insert(rings, classRing)
    end
    
    -- Build category ring from available rings
    categoryRing.items = {}
    for i, ring in ipairs(rings) do
        table.insert(categoryRing.items, {
            type = "category",
            id = i,
            name = ring.name,
            icon = ring.icon,
            color = ring.color,
        })
    end
    
    -- Store in db for reference
    db.rings = rings
end

function RadialMenu:CreateSlots()
    local radius = db.ringRadius or 100
    local buttonSize = db.buttonSize or 40
    
    for i = 1, NUM_SLOTS do
        if not slots[i] then
            local slot = CreateFrame("Button", "MithUIRadialSlot"..i, frame, "SecureActionButtonTemplate")
            slot:SetSize(buttonSize, buttonSize)
            
            -- Background
            slot.bg = slot:CreateTexture(nil, "BACKGROUND")
            slot.bg:SetAllPoints()
            slot.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            
            -- Icon
            slot.icon = slot:CreateTexture(nil, "ARTWORK")
            slot.icon:SetPoint("TOPLEFT", 2, -2)
            slot.icon:SetPoint("BOTTOMRIGHT", -2, 2)
            slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            
            -- Border
            slot.border = CreateFrame("Frame", nil, slot, "BackdropTemplate")
            slot.border:SetAllPoints()
            slot.border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 2,
            })
            slot.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            -- Highlight
            slot:SetHighlightTexture("Interface\\Buttons\\WHITE8x8")
            local highlight = slot:GetHighlightTexture()
            highlight:SetVertexColor(1, 1, 1, 0.3)
            
            -- Cooldown
            slot.cooldown = CreateFrame("Cooldown", nil, slot, "CooldownFrameTemplate")
            slot.cooldown:SetAllPoints(slot.icon)
            
            -- Tooltip
            slot:SetScript("OnEnter", function(self)
                if self.tooltipText then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(self.tooltipText, 1, 1, 1)
                    if self.tooltipDesc then
                        GameTooltip:AddLine(self.tooltipDesc, 0.7, 0.7, 0.7)
                    end
                    GameTooltip:Show()
                end
                self.border:SetBackdropBorderColor(1, 0.8, 0, 1)
            end)
            
            slot:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                if rings[currentRing] then
                    local r, g, b = unpack(rings[currentRing].color or {0.3, 0.3, 0.3})
                    self.border:SetBackdropBorderColor(r * 0.7, g * 0.7, b * 0.7, 1)
                end
            end)
            
            slots[i] = slot
        end
        
        slots[i]:SetSize(buttonSize, buttonSize)
        slots[i]:Hide()
    end
end

function RadialMenu:UpdateRing()
    local ring
    
    if currentRing == 0 then
        -- Show category ring (main menu)
        ring = categoryRing
        subMenuOpen = false
    else
        -- Show specific sub-ring
        ring = rings[currentRing]
        subMenuOpen = true
    end
    
    if not ring then return end
    
    -- Update indicator
    ringIndicator:SetText(ring.name)
    local r, g, b = unpack(ring.color or {1, 1, 1})
    ringIndicator:SetTextColor(r, g, b)
    
    -- Hide all slots
    for i = 1, NUM_SLOTS do
        slots[i]:Hide()
    end
    
    local items = ring.items or {}
    local numItems = #items
    if numItems == 0 then return end
    
    local radius = db.ringRadius or 100
    
    for i, item in ipairs(items) do
        local slot = slots[i]
        if slot and i <= NUM_SLOTS then
            -- Position in circle
            local angle = (i - 1) * (360 / numItems) - 90
            local rad = math.rad(angle)
            local x = math.cos(rad) * radius
            local y = math.sin(rad) * radius
            slot:ClearAllPoints()
            slot:SetPoint("CENTER", frame, "CENTER", x, y)
            
            -- Configure slot
            self:ConfigureSlot(slot, item)
            
            -- Border color (use item color for categories, ring color otherwise)
            if item.color then
                local ir, ig, ib = unpack(item.color)
                slot.border:SetBackdropBorderColor(ir, ig, ib, 1)
            else
                slot.border:SetBackdropBorderColor(r * 0.7, g * 0.7, b * 0.7, 1)
            end
            
            slot:Show()
        end
    end
end

function RadialMenu:ConfigureSlot(slot, item)
    slot.tooltipText = item.name or "Unknown"
    slot.tooltipDesc = item.desc
    slot.itemData = item  -- Store for later reference
    
    -- Set icon
    if item.icon then
        slot.icon:SetTexture(item.icon)
    else
        slot.icon:SetTexture(134400)  -- Question mark
    end
    
    -- Clear previous attributes
    slot:SetAttribute("type", nil)
    slot:SetAttribute("spell", nil)
    slot:SetAttribute("item", nil)
    slot:SetAttribute("toy", nil)
    slot:SetAttribute("macrotext", nil)
    
    if item.type == "category" then
        -- Categories don't have actions - they open sub-menus
        -- Action handled by mouse tracking
        slot:SetAttribute("type", nil)
        
    elseif item.type == "spell" then
        slot:SetAttribute("type", "spell")
        slot:SetAttribute("spell", item.id)
        
    elseif item.type == "item" then
        slot:SetAttribute("type", "item")
        slot:SetAttribute("item", "item:" .. item.id)
        
    elseif item.type == "toy" then
        slot:SetAttribute("type", "toy")
        slot:SetAttribute("toy", item.id)
        
    elseif item.type == "mount" then
        if item.id == 0 then
            -- Random favorite mount
            slot:SetAttribute("type", "macro")
            slot:SetAttribute("macrotext", "/run C_MountJournal.SummonByID(0)")
        else
            slot:SetAttribute("type", "macro")
            slot:SetAttribute("macrotext", "/run C_MountJournal.SummonByID(" .. item.id .. ")")
        end
        
    elseif item.type == "macro" then
        slot:SetAttribute("type", "macro")
        slot:SetAttribute("macrotext", item.macro or "")
    end
end

function RadialMenu:Toggle()
    if isOpen then
        self:Close()
    else
        self:Open()
    end
end

function RadialMenu:OpenRing(ringNum)
    if InCombatLockdown() then
        MithUI:Print("Cannot open menu in combat")
        return
    end
    
    -- Set the ring before opening
    if ringNum and ringNum >= 1 and ringNum <= #rings then
        currentRing = ringNum
    end
    
    self:Open()
end

-- Called when keybind is pressed down
function RadialMenu:OnKeyPress(ringNum)
    if InCombatLockdown() then
        MithUI:Print("Cannot open menu in combat")
        return
    end
    
    -- Set ring if specified (1+ for direct ring, nil/0 for category menu)
    if ringNum and ringNum >= 1 and ringNum <= #rings then
        currentRing = ringNum  -- Go directly to sub-ring
    else
        currentRing = 0  -- Start at category menu
    end
    
    self:Open()
end

-- Called when keybind is released
function RadialMenu:OnKeyRelease()
    if not isOpen then return end
    
    -- Activate the hovered slot
    if hoveredSlot and slots[hoveredSlot] then
        local slot = slots[hoveredSlot]
        -- Simulate a click on the slot
        slot:Click()
    end
    
    self:Close()
end

-- Update hovered slot based on mouse position
function RadialMenu:UpdateMouseSelection()
    if not isOpen then return end
    
    local ring
    if currentRing == 0 then
        ring = categoryRing
    else
        ring = rings[currentRing]
    end
    
    if not ring then return end
    
    local numItems = #ring.items
    if numItems == 0 then return end
    
    -- Get mouse position relative to menu center
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x = x / scale
    y = y / scale
    
    local dx = x - centerX
    local dy = y - centerY
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Only select if mouse is far enough from center (deadzone)
    local deadzone = 30
    local prevHovered = hoveredSlot
    
    if distance < deadzone then
        hoveredSlot = nil
    else
        -- Calculate angle from center
        local angle = math.deg(math.atan2(dy, dx))
        
        -- Normalize angle to 0-360
        if angle < 0 then angle = angle + 360 end
        
        -- Adjust for our starting position (-90 degrees / top)
        angle = angle + 90
        if angle >= 360 then angle = angle - 360 end
        
        -- Determine which slot based on angle
        local slotAngle = 360 / numItems
        local slotIndex = math.floor(angle / slotAngle) + 1
        
        if slotIndex > numItems then slotIndex = numItems end
        if slotIndex < 1 then slotIndex = 1 end
        
        hoveredSlot = slotIndex
    end
    
    -- Check if we should open a sub-menu (category hovered)
    if currentRing == 0 and hoveredSlot and hoveredSlot ~= prevHovered then
        local item = categoryRing.items[hoveredSlot]
        if item and item.type == "category" then
            -- Open the sub-ring
            currentRing = item.id
            self:UpdateRing()
            -- Keep the same hovered slot visually until they move
            hoveredSlot = nil
        end
    end
    
    -- Update visual highlighting
    if prevHovered ~= hoveredSlot then
        self:UpdateSlotHighlights()
    end
end

function RadialMenu:UpdateSlotHighlights()
    local ring
    if currentRing == 0 then
        ring = categoryRing
    else
        ring = rings[currentRing]
    end
    
    if not ring then return end
    
    local r, g, b = unpack(ring.color or {0.3, 0.3, 0.3})
    
    for i, slot in ipairs(slots) do
        if slot:IsShown() then
            local item = ring.items[i]
            if i == hoveredSlot then
                -- Highlighted slot
                slot.border:SetBackdropBorderColor(1, 0.8, 0, 1)
                slot.bg:SetColorTexture(0.3, 0.3, 0.3, 0.9)
                slot:SetScale(1.15)
            else
                -- Normal slot - use item color for categories
                if item and item.color then
                    local ir, ig, ib = unpack(item.color)
                    slot.border:SetBackdropBorderColor(ir, ig, ib, 1)
                else
                    slot.border:SetBackdropBorderColor(r * 0.7, g * 0.7, b * 0.7, 1)
                end
                slot.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                slot:SetScale(1.0)
            end
        end
    end
end

function RadialMenu:Open()
    if InCombatLockdown() then
        MithUI:Print("Cannot open menu in combat")
        return
    end
    
    -- Rebuild rings to catch any new items
    self:BuildRings()
    
    -- Center on cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    centerX = x / scale
    centerY = y / scale
    
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    
    -- Reset to category ring (main menu) unless a specific ring was requested
    if currentRing == 0 or currentRing > #rings then
        currentRing = 0
    end
    
    -- Reset hover state
    hoveredSlot = nil
    subMenuOpen = false
    
    self:UpdateRing()
    frame:Show()
    isOpen = true
    
    -- Start mouse tracking
    frame:SetScript("OnUpdate", function(self, elapsed)
        RadialMenu:UpdateMouseSelection()
    end)
end

function RadialMenu:Close()
    frame:Hide()
    frame:SetScript("OnUpdate", nil)
    isOpen = false
    hoveredSlot = nil
    subMenuOpen = false
    currentRing = 0  -- Reset to category menu for next open
    
    -- Reset slot scales
    for _, slot in ipairs(slots) do
        slot:SetScale(1.0)
    end
end

function RadialMenu:NextRing()
    if not isOpen then return end
    currentRing = currentRing + 1
    if currentRing > #rings then
        currentRing = 1
    end
    self:UpdateRing()
end

function RadialMenu:PrevRing()
    if not isOpen then return end
    currentRing = currentRing - 1
    if currentRing < 1 then
        currentRing = #rings
    end
    self:UpdateRing()
end

function RadialMenu:SetupKeybind()
    -- Scroll wheel to change rings
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            RadialMenu:NextRing()
        else
            RadialMenu:PrevRing()
        end
    end)
    
    -- Close on right click
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            RadialMenu:Close()
        end
    end)
    
    -- Close on escape
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            RadialMenu:Close()
        end
    end)
    frame:SetPropagateKeyboardInput(true)
end

function RadialMenu:RefreshRings()
    self:BuildRings()
    if isOpen then
        self:UpdateRing()
    end
end

-- Slash command handler
function RadialMenu:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "show" or cmd == "open" then
        self:Open()
        
    elseif cmd == "hide" or cmd == "close" then
        self:Close()
        
    elseif cmd == "toggle" then
        self:Toggle()
        
    elseif cmd == "refresh" then
        self:RefreshRings()
        MithUI:Print("Rings refreshed")
        
    elseif cmd == "ring" then
        local num = tonumber(args[2])
        if num and num >= 1 and num <= #rings then
            currentRing = num
            if isOpen then self:UpdateRing() end
            MithUI:Print("Ring: " .. rings[currentRing].name)
        else
            MithUI:Print("Rings: 1-" .. #rings)
        end
        
    elseif cmd == "scale" then
        local scale = tonumber(args[2])
        if scale then
            db.scale = scale
            frame:SetScale(scale)
            MithUI:Print("Scale: " .. scale)
        end
        
    elseif cmd == "radius" then
        local radius = tonumber(args[2])
        if radius then
            db.ringRadius = radius
            self:CreateSlots()
            if isOpen then self:UpdateRing() end
            MithUI:Print("Radius: " .. radius)
        end
        
    elseif cmd == "list" then
        MithUI:Print("Rings:")
        for i, ring in ipairs(rings) do
            local r, g, b = unpack(ring.color)
            print(string.format("  %d. |cff%02x%02x%02x%s|r (%d items)", 
                i, r*255, g*255, b*255, ring.name, #ring.items))
        end
        
    elseif cmd == "items" then
        local ringNum = tonumber(args[2]) or currentRing
        local ring = rings[ringNum]
        if ring then
            MithUI:Print(ring.name .. " items:")
            for i, item in ipairs(ring.items) do
                print(string.format("  %d. %s (%s)", i, item.name, item.type))
            end
        end
        
    elseif cmd == "addmount" then
        local mountID = tonumber(args[2])
        if mountID then
            db.customMounts = db.customMounts or {}
            table.insert(db.customMounts, mountID)
            self:RefreshRings()
            MithUI:Print("Added mount ID: " .. mountID)
        else
            MithUI:Print("Usage: /mp addmount [mountID]")
            MithUI:Print("Find mount IDs at wowhead.com")
        end
        
    else
        MithUI:Print("Radial Menu commands:")
        print("  |cff00ff00/mp|r - Toggle menu")
        print("  |cff00ff00/mp refresh|r - Refresh rings (detect new items)")
        print("  |cff00ff00/mp ring [1-3]|r - Switch ring")
        print("  |cff00ff00/mp list|r - List all rings")
        print("  |cff00ff00/mp items [ring#]|r - List items in ring")
        print("  |cff00ff00/mp scale [num]|r - Set scale")
        print("  |cff00ff00/mp radius [num]|r - Set ring radius")
        print("  |cff00ff00/mp addmount [id]|r - Add custom mount")
        print("")
        print("  |cff00ccffKeybind:|r Hold key, move mouse toward option, release")
        print("  |cff00ccffIn menu:|r Scroll wheel changes rings")
        print("  |cff00ccffClose:|r Right-click or ESC")
        print("")
        print("  Set keybinds in: |cff00ff00Key Bindings > MithUI|r")
    end
end

-- Slash command
SLASH_MITHPIE1 = "/mithpie"
SLASH_MITHPIE2 = "/mp"

SlashCmdList["MITHPIE"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    
    if #args == 0 then
        RadialMenu:Toggle()
    else
        RadialMenu:SlashCommand(args)
    end
end
