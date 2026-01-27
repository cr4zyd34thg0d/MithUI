-- MithUI Radial Menu Module (OPie-style)
-- Hold keybind > ring of slices appears at cursor > hover to select > release to execute
-- Scroll wheel switches between rings

local addonName, MithUI = ...

local RadialMenu = {}
MithUI:RegisterModule("radialMenu", RadialMenu)

---------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------
local MAX_SLICES = 32
local DEAD_ZONE_RADIUS = 25
local DEG_TO_RAD = math.pi / 180

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local db
local isOpen = false
local centerX, centerY = 0, 0
local activeRingIndex = 1
local hoveredSliceIndex = 0
local lastHoveredSliceIndex = -1
local rings = {}
local fadeAlpha = 0

---------------------------------------------------------------------------
-- Data: Hearthstone Toys
---------------------------------------------------------------------------
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

---------------------------------------------------------------------------
-- Data: Class Spells
---------------------------------------------------------------------------
local CLASS_SPELLS = {
    DEATHKNIGHT = {
        {id = 50977},   -- Death Gate
    },
    DRUID = {
        {id = 18960},   -- Teleport: Moonglade
        {id = 193753},  -- Dreamwalk
    },
    MAGE = {
        {id = 3561},    -- Teleport: Stormwind
        {id = 3562},    -- Teleport: Ironforge
        {id = 3563},    -- Teleport: Undercity
        {id = 3565},    -- Teleport: Darnassus
        {id = 3566},    -- Teleport: Thunder Bluff
        {id = 3567},    -- Teleport: Orgrimmar
        {id = 32271},   -- Teleport: Exodar
        {id = 32272},   -- Teleport: Silvermoon
        {id = 33690},   -- Teleport: Shattrath (Alliance)
        {id = 33691},   -- Teleport: Shattrath (Horde)
        {id = 49358},   -- Teleport: Stonard
        {id = 49359},   -- Teleport: Theramore
        {id = 53140},   -- Teleport: Dalaran - Northrend
        {id = 88342},   -- Teleport: Tol Barad (Alliance)
        {id = 88344},   -- Teleport: Tol Barad (Horde)
        {id = 120145},  -- Ancient Teleport: Dalaran
        {id = 132621},  -- Teleport: Vale (Alliance)
        {id = 132627},  -- Teleport: Vale (Horde)
        {id = 176242},  -- Teleport: Warspear
        {id = 176248},  -- Teleport: Stormshield
        {id = 193759},  -- Teleport: Hall of the Guardian
        {id = 224869},  -- Teleport: Dalaran - Broken Isles
        {id = 281403},  -- Teleport: Boralus
        {id = 281404},  -- Teleport: Dazar'alor
        {id = 344587},  -- Teleport: Oribos
        {id = 395277},  -- Teleport: Valdrakken
        {id = 446540},  -- Teleport: Dornogal
    },
    MONK = {
        {id = 126892},  -- Zen Pilgrimage
        {id = 126895},  -- Zen Pilgrimage: Return
    },
    SHAMAN = {
        {id = 556},     -- Astral Recall
    },
    WARLOCK = {
        {id = 126},     -- Eye of Kilrogg
        {id = 691},     -- Summon Felhunter
        {id = 697},     -- Summon Voidwalker
        {id = 688},     -- Summon Imp
        {id = 712},     -- Summon Succubus
        {id = 30146},   -- Summon Felguard
        {id = 111771},  -- Demonic Gateway
        {id = 698},     -- Ritual of Summoning
    },
    PRIEST = {
        {id = 73325},   -- Leap of Faith
    },
    HUNTER = {
        {id = 982},     -- Revive Pet
        {id = 883},     -- Call Pet 1
        {id = 83242},   -- Call Pet 2
        {id = 83243},   -- Call Pet 3
        {id = 83244},   -- Call Pet 4
        {id = 83245},   -- Call Pet 5
    },
}

---------------------------------------------------------------------------
-- Data: Raid Target Markers
---------------------------------------------------------------------------
local MARKER_ICONS = {
    [1] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1", -- Star
    [2] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2", -- Circle
    [3] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3", -- Diamond
    [4] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4", -- Triangle
    [5] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5", -- Moon
    [6] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6", -- Square
    [7] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7", -- Cross
    [8] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", -- Skull
}
local MARKER_NAMES = {
    "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull"
}

---------------------------------------------------------------------------
-- Utility: Safe Cooldown Lookup
---------------------------------------------------------------------------
local function GetSpellCooldownSafe(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            return info.startTime or 0, info.duration or 0
        end
    elseif GetSpellCooldown then
        local start, dur = GetSpellCooldown(spellID)
        return start or 0, dur or 0
    end
    return 0, 0
end

local function GetItemCooldownSafe(itemID)
    if GetItemCooldown then
        local start, dur = GetItemCooldown(itemID)
        return start or 0, dur or 0
    end
    return 0, 0
end

local function GetSpellInfoSafe(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, info.iconID
        end
    elseif GetSpellInfo then
        local name, _, icon = GetSpellInfo(spellID)
        return name, icon
    end
    return nil, nil
end

---------------------------------------------------------------------------
-- Frame Creation
---------------------------------------------------------------------------

-- Main container (positioned at cursor on open)
local frame = CreateFrame("Frame", "MithUIRadialMenu", UIParent)
frame:SetFrameStrata("DIALOG")
frame:SetFrameLevel(100)
frame:SetSize(400, 400)
frame:SetPoint("CENTER")
frame:Hide()

-- Secure action button for keybinding and action execution
local keybindButton = CreateFrame("Button", "MithUIRadialMenuButton", UIParent, "SecureActionButtonTemplate")
keybindButton:SetSize(1, 1)
keybindButton:SetPoint("CENTER")
keybindButton:RegisterForClicks("AnyUp", "AnyDown")

-- Background overlay (subtle dark disc behind the ring)
local bgOverlay = frame:CreateTexture(nil, "BACKGROUND")
bgOverlay:SetPoint("CENTER")
bgOverlay:SetSize(300, 300)
bgOverlay:SetColorTexture(0, 0, 0, 0.35)
bgOverlay:SetDrawLayer("BACKGROUND", -8)

-- Center display frame
local centerFrame = CreateFrame("Frame", nil, frame)
centerFrame:SetSize(50, 50)
centerFrame:SetPoint("CENTER")
centerFrame:SetFrameLevel(110)

centerFrame.bg = centerFrame:CreateTexture(nil, "BACKGROUND")
centerFrame.bg:SetAllPoints()
centerFrame.bg:SetColorTexture(0.08, 0.08, 0.08, 0.95)

centerFrame.icon = centerFrame:CreateTexture(nil, "ARTWORK")
centerFrame.icon:SetPoint("TOPLEFT", 4, -4)
centerFrame.icon:SetPoint("BOTTOMRIGHT", -4, 4)
centerFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

centerFrame.border = centerFrame:CreateTexture(nil, "OVERLAY")
centerFrame.border:SetPoint("TOPLEFT", -1, 1)
centerFrame.border:SetPoint("BOTTOMRIGHT", 1, -1)
centerFrame.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
centerFrame.border:SetBlendMode("ADD")
centerFrame.border:SetVertexColor(0.6, 0.6, 0.6, 0.5)

-- Slice name text (below center)
centerFrame.sliceName = centerFrame:CreateFontString(nil, "OVERLAY")
centerFrame.sliceName:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
centerFrame.sliceName:SetPoint("TOP", centerFrame, "BOTTOM", 0, -6)
centerFrame.sliceName:SetWidth(200)
centerFrame.sliceName:SetTextColor(1, 1, 1)

-- Ring name text (above center)
centerFrame.ringName = centerFrame:CreateFontString(nil, "OVERLAY")
centerFrame.ringName:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
centerFrame.ringName:SetPoint("BOTTOM", centerFrame, "TOP", 0, 6)
centerFrame.ringName:SetWidth(200)
centerFrame.ringName:SetTextColor(0.7, 0.7, 0.7)

-- Scroll / status hint
centerFrame.scrollHint = centerFrame:CreateFontString(nil, "OVERLAY")
centerFrame.scrollHint:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
centerFrame.scrollHint:SetPoint("TOP", centerFrame.sliceName, "BOTTOM", 0, -2)
centerFrame.scrollHint:SetTextColor(0.5, 0.5, 0.5)

-- Pointer line from center toward hovered slice
local pointerLine = frame:CreateLine(nil, "OVERLAY")
pointerLine:SetThickness(2)
pointerLine:SetColorTexture(1, 0.82, 0, 0.6)
pointerLine:Hide()

---------------------------------------------------------------------------
-- Slice Frame Pool
---------------------------------------------------------------------------
local sliceFrames = {}

local function CreateSliceFrame(index)
    local sf = CreateFrame("Frame", "MithUIRadialSlice" .. index, frame)
    sf:SetSize(40, 40)
    sf:SetFrameLevel(105)
    sf:EnableMouse(false)

    -- Background
    sf.bg = sf:CreateTexture(nil, "BACKGROUND")
    sf.bg:SetAllPoints()
    sf.bg:SetColorTexture(0.1, 0.1, 0.1, 0.85)

    -- Icon
    sf.icon = sf:CreateTexture(nil, "ARTWORK")
    sf.icon:SetPoint("TOPLEFT", 3, -3)
    sf.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    sf.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Border
    sf.border = CreateFrame("Frame", nil, sf, "BackdropTemplate")
    sf.border:SetAllPoints()
    sf.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
    sf.border:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    -- Cooldown
    sf.cooldown = CreateFrame("Cooldown", nil, sf, "CooldownFrameTemplate")
    sf.cooldown:SetAllPoints(sf.icon)
    sf.cooldown:SetDrawEdge(false)
    sf.cooldown:SetHideCountdownNumbers(true)

    -- Desaturated/unusable overlay
    sf.unusable = sf:CreateTexture(nil, "OVERLAY")
    sf.unusable:SetAllPoints(sf.icon)
    sf.unusable:SetColorTexture(0.3, 0, 0, 0.4)
    sf.unusable:Hide()

    -- Stack count
    sf.count = sf:CreateFontString(nil, "OVERLAY")
    sf.count:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    sf.count:SetPoint("BOTTOMRIGHT", -2, 2)
    sf.count:SetTextColor(1, 1, 1)

    sf.sliceIndex = index
    sf:Hide()
    return sf
end

for i = 1, MAX_SLICES do
    sliceFrames[i] = CreateSliceFrame(i)
end

---------------------------------------------------------------------------
-- Module Lifecycle
---------------------------------------------------------------------------
function RadialMenu:OnInitialize()
    MithUI.defaults.radialMenu = {
        enabled = true,
        scale = 1.0,
        radius = 120,
        sliceSize = 40,
        showCooldowns = true,
        showRingName = true,
        maxMountSlices = 12,
        rings = {
            {name = "Mounts", builtin = "mounts", enabled = true},
            {name = "Hearthstones", builtin = "hearthstones", enabled = true},
            {name = "Class Spells", builtin = "classspells", enabled = true},
            {name = "Target Markers", builtin = "markers", enabled = true},
        },
    }
end

function RadialMenu:OnEnable()
    db = MithUIDB.radialMenu
    if not db then return end

    -- Ensure rings config exists (migration from old format)
    if not db.rings then
        db.rings = {
            {name = "Mounts", builtin = "mounts", enabled = true},
            {name = "Hearthstones", builtin = "hearthstones", enabled = true},
            {name = "Class Spells", builtin = "classspells", enabled = true},
            {name = "Target Markers", builtin = "markers", enabled = true},
        }
    end
    if not db.sliceSize then db.sliceSize = 40 end
    if db.showCooldowns == nil then db.showCooldowns = true end
    if db.showRingName == nil then db.showRingName = true end
    if not db.maxMountSlices then db.maxMountSlices = 12 end

    C_Timer.After(2, function()
        RadialMenu:BuildAllRings()
    end)
end

---------------------------------------------------------------------------
-- Ring Building
---------------------------------------------------------------------------
function RadialMenu:BuildAllRings()
    rings = {}
    if not db or not db.rings then return end

    for i, ringDef in ipairs(db.rings) do
        if ringDef.enabled ~= false then
            local ring = nil
            if ringDef.builtin == "mounts" then
                ring = self:BuildMountsRing()
            elseif ringDef.builtin == "hearthstones" then
                ring = self:BuildHearthstonesRing()
            elseif ringDef.builtin == "classspells" then
                ring = self:BuildClassSpellsRing()
            elseif ringDef.builtin == "markers" then
                ring = self:BuildMarkersRing()
            elseif ringDef.slices then
                ring = self:BuildCustomRing(ringDef)
            end
            if ring and #ring.slices > 0 then
                ring.name = ringDef.name or ring.name
                ring.dbIndex = i
                ring.isCustom = (ringDef.builtin == nil)
                table.insert(rings, ring)
            end
        end
    end

    if activeRingIndex > #rings then
        activeRingIndex = math.max(1, #rings)
    end
end

function RadialMenu:BuildMountsRing()
    local ring = {
        name = "Mounts",
        icon = 413588,
        color = {0.6, 0.4, 1.0},
        slices = {},
    }

    -- Random favorite mount
    table.insert(ring.slices, {
        type = "mount", id = 0,
        name = "Random Favorite",
        icon = 413588,
    })

    local maxSlices = db.maxMountSlices or 12
    local mountIDs = C_MountJournal.GetMountIDs()
    if mountIDs then
        for _, mountID in ipairs(mountIDs) do
            if #ring.slices >= maxSlices then break end
            local name, spellID, icon, _, _, _, isFavorite,
                  _, _, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            if isCollected and isFavorite and not shouldHideOnChar then
                table.insert(ring.slices, {
                    type = "mount", id = mountID,
                    name = name, icon = icon,
                    spellID = spellID,
                })
            end
        end
    end

    return ring
end

function RadialMenu:BuildHearthstonesRing()
    local ring = {
        name = "Hearthstones",
        icon = 134414,
        color = {0.3, 0.8, 0.5},
        slices = {},
    }

    -- Regular Hearthstone
    local hearthCount = GetItemCount(6948)
    if hearthCount and hearthCount > 0 then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(6948)
        table.insert(ring.slices, {
            type = "item", id = 6948,
            name = itemName or "Hearthstone",
            icon = itemIcon or 134414,
        })
    end

    -- Dalaran Hearthstone
    local dalHS = GetItemCount(140192)
    if dalHS and dalHS > 0 then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(140192)
        table.insert(ring.slices, {
            type = "item", id = 140192,
            name = itemName or "Dalaran Hearthstone",
            icon = itemIcon or 1041860,
        })
    end

    -- Garrison Hearthstone
    local garHS = GetItemCount(110560)
    if garHS and garHS > 0 then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(110560)
        table.insert(ring.slices, {
            type = "item", id = 110560,
            name = itemName or "Garrison Hearthstone",
            icon = itemIcon or 1041860,
        })
    end

    -- Hearthstone toys
    for _, toyID in ipairs(HEARTHSTONE_TOYS) do
        if PlayerHasToy and PlayerHasToy(toyID) then
            local _, toyName, toyIcon = C_ToyBox.GetToyInfo(toyID)
            if toyName and toyIcon then
                table.insert(ring.slices, {
                    type = "toy", id = toyID,
                    name = toyName, icon = toyIcon,
                })
            end
        end
    end

    return ring
end

function RadialMenu:BuildClassSpellsRing()
    local _, className = UnitClass("player")
    local spells = CLASS_SPELLS[className]
    if not spells then
        return {name = "Class Spells", icon = 134400, color = {0.2, 0.6, 1.0}, slices = {}}
    end

    local ring = {
        name = "Class Spells",
        icon = nil,
        color = {0.2, 0.6, 1.0},
        slices = {},
    }

    for _, spellDef in ipairs(spells) do
        local spellName, spellIcon = GetSpellInfoSafe(spellDef.id)
        if spellName then
            local isKnown = IsSpellKnown(spellDef.id)
            if isKnown then
                table.insert(ring.slices, {
                    type = "spell", id = spellDef.id,
                    name = spellName,
                    icon = spellIcon or 134400,
                })
                if not ring.icon then
                    ring.icon = spellIcon
                end
            end
        end
    end

    ring.icon = ring.icon or 134400
    return ring
end

function RadialMenu:BuildMarkersRing()
    local ring = {
        name = "Target Markers",
        icon = MARKER_ICONS[8],
        color = {1.0, 0.8, 0.2},
        slices = {},
    }

    -- Clear marker
    table.insert(ring.slices, {
        type = "raidmark", id = 0,
        name = "Clear Marker",
        icon = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
    })

    for i = 1, 8 do
        table.insert(ring.slices, {
            type = "raidmark", id = i,
            name = MARKER_NAMES[i],
            icon = MARKER_ICONS[i],
        })
    end

    return ring
end

function RadialMenu:BuildCustomRing(ringDef)
    local ring = {
        name = ringDef.name or "Custom Ring",
        icon = ringDef.icon or 134400,
        color = ringDef.color or {0.8, 0.8, 0.8},
        slices = {},
    }

    for _, sliceDef in ipairs(ringDef.slices) do
        local slice = {
            type = sliceDef.type,
            id = sliceDef.id,
            name = sliceDef.name,
            icon = sliceDef.icon,
            macrotext = sliceDef.macrotext,
        }

        -- Resolve missing name/icon
        if not slice.name or not slice.icon then
            if slice.type == "spell" then
                local n, ic = GetSpellInfoSafe(slice.id)
                slice.name = slice.name or n
                slice.icon = slice.icon or ic
            elseif slice.type == "item" then
                local itemName, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(slice.id)
                slice.name = slice.name or itemName
                slice.icon = slice.icon or itemIcon
            elseif slice.type == "toy" then
                local _, toyName, toyIcon = C_ToyBox.GetToyInfo(slice.id)
                slice.name = slice.name or toyName
                slice.icon = slice.icon or toyIcon
            elseif slice.type == "mount" then
                if slice.id == 0 then
                    slice.name = slice.name or "Random Favorite"
                    slice.icon = slice.icon or 413588
                else
                    local name, _, icon = C_MountJournal.GetMountInfoByID(slice.id)
                    slice.name = slice.name or name
                    slice.icon = slice.icon or icon
                end
            end
        end

        slice.name = slice.name or "Unknown"
        slice.icon = slice.icon or 134400
        table.insert(ring.slices, slice)
    end

    return ring
end

---------------------------------------------------------------------------
-- Ring Display
---------------------------------------------------------------------------
function RadialMenu:ShowCurrentRing()
    local ring = rings[activeRingIndex]
    if not ring then return end

    local numSlices = math.min(#ring.slices, MAX_SLICES)
    if numSlices == 0 then return end

    local radius = db.radius or 120
    local sliceSize = db.sliceSize or 40

    -- Hide all slices first
    for i = 1, MAX_SLICES do
        sliceFrames[i]:Hide()
    end

    -- Position slices in a circle (0 degrees = top, clockwise)
    for i = 1, numSlices do
        local sf = sliceFrames[i]
        local slice = ring.slices[i]

        local angleDeg = (i - 1) * (360 / numSlices)
        local angleRad = angleDeg * DEG_TO_RAD
        local x = math.sin(angleRad) * radius
        local y = math.cos(angleRad) * radius

        sf:ClearAllPoints()
        sf:SetPoint("CENTER", frame, "CENTER", x, y)
        sf:SetSize(sliceSize, sliceSize)

        -- Icon
        sf.icon:SetTexture(slice.icon or 134400)
        sf.icon:SetDesaturated(false)
        sf.unusable:Hide()

        -- Default border color (ring tint)
        local r, g, b = 0.3, 0.3, 0.3
        if ring.color then
            r = ring.color[1] * 0.5
            g = ring.color[2] * 0.5
            b = ring.color[3] * 0.5
        end
        sf.border:SetBackdropBorderColor(r, g, b, 0.8)
        sf:SetScale(1.0)
        sf:SetAlpha(0.85)

        -- Cooldown
        self:UpdateSliceCooldown(sf, slice)

        -- Stack count for items
        sf.count:SetText("")
        if slice.type == "item" then
            local count = C_Item.GetItemCount(slice.id)
            if count and count > 1 then
                sf.count:SetText(count)
            end
        end

        sf:Show()
    end

    -- Update center display
    local r, g, b = 0.7, 0.7, 0.7
    if ring.color then r, g, b = unpack(ring.color) end

    if db.showRingName then
        centerFrame.ringName:SetText(ring.name)
    else
        centerFrame.ringName:SetText("")
    end
    centerFrame.ringName:SetTextColor(r, g, b)
    centerFrame.icon:SetTexture(ring.icon or 134400)
    centerFrame.sliceName:SetText("")
    centerFrame.border:SetVertexColor(r, g, b, 0.5)

    if #rings > 1 then
        centerFrame.scrollHint:SetText("Scroll: switch rings (" .. activeRingIndex .. "/" .. #rings .. ")")
    else
        centerFrame.scrollHint:SetText("")
    end

    -- Reset hover state
    pointerLine:Hide()
    hoveredSliceIndex = 0
    lastHoveredSliceIndex = -1
end

function RadialMenu:UpdateSliceCooldown(sf, slice)
    if not db.showCooldowns then
        sf.cooldown:Clear()
        return
    end

    local start, duration = 0, 0

    if slice.type == "spell" then
        start, duration = GetSpellCooldownSafe(slice.id)
    elseif slice.type == "item" or slice.type == "toy" then
        start, duration = GetItemCooldownSafe(slice.id)
    end

    if start and duration and duration > 1.5 then
        sf.cooldown:SetCooldown(start, duration)
        sf.icon:SetDesaturated(true)
    else
        sf.cooldown:Clear()
        sf.icon:SetDesaturated(false)
    end
end

---------------------------------------------------------------------------
-- Mouse Tracking & Hover Detection
---------------------------------------------------------------------------
function RadialMenu:GetHoveredSlice()
    local ring = rings[activeRingIndex]
    if not ring then return 0 end

    local numSlices = math.min(#ring.slices, MAX_SLICES)
    if numSlices == 0 then return 0 end

    local x, y = GetCursorPosition()
    local scale = frame:GetEffectiveScale()
    local fx, fy = frame:GetCenter()
    if not fx or not fy then return 0 end

    local dx = x / scale - fx
    local dy = y / scale - fy
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Dead zone: too close to center
    if dist < DEAD_ZONE_RADIUS then
        return 0
    end

    -- Angle: 0 = up, increasing clockwise
    local angle = math.deg(math.atan2(dx, dy))
    if angle < 0 then angle = angle + 360 end

    -- Which slice segment does this angle fall into?
    local segAngle = 360 / numSlices
    local sliceIndex = math.floor(((angle + segAngle / 2) % 360) / segAngle) + 1

    if sliceIndex < 1 then sliceIndex = 1 end
    if sliceIndex > numSlices then sliceIndex = numSlices end

    return sliceIndex
end

function RadialMenu:HighlightSlice(index)
    if index == lastHoveredSliceIndex then return end
    lastHoveredSliceIndex = index

    local ring = rings[activeRingIndex]
    if not ring then return end

    local numSlices = math.min(#ring.slices, MAX_SLICES)

    -- Update all slice visuals
    for i = 1, numSlices do
        local sf = sliceFrames[i]
        if i == index then
            -- Highlighted (gold border, slightly enlarged)
            sf.border:SetBackdropBorderColor(1, 0.82, 0, 1)
            sf:SetScale(1.2)
            sf:SetAlpha(1.0)
        else
            -- Normal (ring-colored border, dimmed)
            local r, g, b = 0.3, 0.3, 0.3
            if ring.color then
                r = ring.color[1] * 0.5
                g = ring.color[2] * 0.5
                b = ring.color[3] * 0.5
            end
            sf.border:SetBackdropBorderColor(r, g, b, 0.8)
            sf:SetScale(1.0)
            sf:SetAlpha(0.7)
        end
    end

    -- Update center display
    if index > 0 and index <= numSlices then
        local slice = ring.slices[index]
        centerFrame.icon:SetTexture(slice.icon or 134400)
        centerFrame.sliceName:SetText(slice.name or "")
        centerFrame.sliceName:SetTextColor(1, 1, 1)
        centerFrame.scrollHint:SetText("")

        -- Pointer line from center toward hovered slice
        local angleDeg = (index - 1) * (360 / numSlices)
        local angleRad = angleDeg * DEG_TO_RAD
        local lineLen = (db.radius or 120) * 0.35
        pointerLine:SetStartPoint("CENTER", frame, 0, 0)
        pointerLine:SetEndPoint("CENTER", frame,
            math.sin(angleRad) * lineLen,
            math.cos(angleRad) * lineLen)
        pointerLine:Show()
    else
        -- No hover: show ring info
        centerFrame.icon:SetTexture(ring.icon or 134400)
        centerFrame.sliceName:SetText("")
        if #rings > 1 then
            centerFrame.scrollHint:SetText("Scroll: switch rings (" .. activeRingIndex .. "/" .. #rings .. ")")
        else
            centerFrame.scrollHint:SetText("")
        end
        pointerLine:Hide()
    end
end

---------------------------------------------------------------------------
-- Secure Button Configuration
---------------------------------------------------------------------------
function RadialMenu:ConfigureSecureButton(slice)
    if InCombatLockdown() then return end

    -- Clear previous attributes
    keybindButton:SetAttribute("type", nil)
    keybindButton:SetAttribute("spell", nil)
    keybindButton:SetAttribute("item", nil)
    keybindButton:SetAttribute("toy", nil)
    keybindButton:SetAttribute("macrotext", nil)

    if not slice then return end

    -- SAB native types handled directly by the secure handler:
    --   spell → type="spell"
    --   item  → type="item" (bag items only)
    --   toy   → type="macro" with /use (toys are collection items, not in bags)
    -- Mount, raidmark, macro go through ExecuteHoveredSlice with hardware event intact.
    if slice.type == "spell" then
        keybindButton:SetAttribute("type", "spell")
        keybindButton:SetAttribute("spell", slice.id)
    elseif slice.type == "item" then
        keybindButton:SetAttribute("type", "item")
        keybindButton:SetAttribute("item", slice.name or "")
    elseif slice.type == "toy" then
        keybindButton:SetAttribute("type", "macro")
        keybindButton:SetAttribute("macrotext", "/use " .. (slice.name or ""))
    end
end

---------------------------------------------------------------------------
-- Action Execution (for API-based actions not handled by SAB)
---------------------------------------------------------------------------
function RadialMenu:ExecuteHoveredSlice()
    local ring = rings[activeRingIndex]
    if not ring then return end

    local numSlices = math.min(#ring.slices, MAX_SLICES)
    if hoveredSliceIndex < 1 or hoveredSliceIndex > numSlices then return end

    local slice = ring.slices[hoveredSliceIndex]

    -- SAB handles spell, item, and toy types natively via ConfigureSecureButton.
    -- Everything else runs here via OnClick which has the hardware event.
    local ok, err = pcall(function()
        if slice.type == "mount" then
            C_MountJournal.SummonByID(slice.id)
        elseif slice.type == "raidmark" then
            SetRaidTarget("target", slice.id)
        elseif slice.type == "macro" then
            RunMacroText(slice.macrotext or "")
        end
    end)
    if not ok then
        MithUI:Print("|cffff0000Action failed:|r " .. tostring(err))
    end
end

---------------------------------------------------------------------------
-- Open / Close / Toggle
---------------------------------------------------------------------------
function RadialMenu:Open(ringIndex)
    if InCombatLockdown() then
        MithUI:Print("Cannot open radial menu in combat")
        return
    end
    if not db or db.enabled == false then return end

    -- Rebuild rings if empty
    if #rings == 0 then
        self:BuildAllRings()
        if #rings == 0 then
            MithUI:Print("No rings available")
            return
        end
    end

    if ringIndex and ringIndex >= 1 and ringIndex <= #rings then
        activeRingIndex = ringIndex
    end

    -- Position at cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    centerX = x / scale
    centerY = y / scale

    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", centerX, centerY)
    frame:SetScale(db.scale or 1.0)

    -- Show ring slices
    self:ShowCurrentRing()

    -- Fade in
    fadeAlpha = 0
    frame:SetAlpha(0)
    frame:Show()
    isOpen = true

    -- Start mouse tracking
    frame:SetScript("OnUpdate", function(_, elapsed)
        RadialMenu:OnUpdate(elapsed)
    end)
end

function RadialMenu:Close()
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    isOpen = false
    hoveredSliceIndex = 0
    lastHoveredSliceIndex = -1

    for i = 1, MAX_SLICES do
        sliceFrames[i]:SetScale(1.0)
        sliceFrames[i]:Hide()
    end

    pointerLine:Hide()
    GameTooltip:Hide()

    if not InCombatLockdown() then
        keybindButton:SetAttribute("type", nil)
    end
end

function RadialMenu:Toggle()
    if isOpen then
        self:Close()
    else
        self:Open()
    end
end

function RadialMenu:SwitchRing(delta)
    if #rings <= 1 then return end

    if delta > 0 then
        activeRingIndex = activeRingIndex - 1
        if activeRingIndex < 1 then activeRingIndex = #rings end
    else
        activeRingIndex = activeRingIndex + 1
        if activeRingIndex > #rings then activeRingIndex = 1 end
    end

    self:ShowCurrentRing()
end

---------------------------------------------------------------------------
-- OnUpdate: Mouse Tracking + Cooldowns
---------------------------------------------------------------------------
local cooldownTimer = 0
local COOLDOWN_UPDATE_INTERVAL = 0.5

function RadialMenu:OnUpdate(elapsed)
    if not isOpen then return end

    -- Fade in animation
    if fadeAlpha < 1 then
        fadeAlpha = math.min(1, fadeAlpha + elapsed * 6)
        frame:SetAlpha(fadeAlpha)
    end

    -- Hover detection
    hoveredSliceIndex = self:GetHoveredSlice()
    self:HighlightSlice(hoveredSliceIndex)

    -- Configure SAB for the current hover target
    local ring = rings[activeRingIndex]
    if ring and hoveredSliceIndex > 0 and hoveredSliceIndex <= #ring.slices then
        self:ConfigureSecureButton(ring.slices[hoveredSliceIndex])
    else
        self:ConfigureSecureButton(nil)
    end

    -- Periodic cooldown refresh
    cooldownTimer = cooldownTimer + elapsed
    if cooldownTimer >= COOLDOWN_UPDATE_INTERVAL then
        cooldownTimer = 0
        self:UpdateAllCooldowns()
    end
end

function RadialMenu:UpdateAllCooldowns()
    local ring = rings[activeRingIndex]
    if not ring then return end

    local numSlices = math.min(#ring.slices, MAX_SLICES)
    for i = 1, numSlices do
        self:UpdateSliceCooldown(sliceFrames[i], ring.slices[i])
    end
end

---------------------------------------------------------------------------
-- Keybind Button: Hold to Open, Release to Execute
---------------------------------------------------------------------------
keybindButton:SetScript("OnClick", function(_, button, down)
    if down then
        RadialMenu:Open()
    else
        if hoveredSliceIndex > 0 then
            RadialMenu:ExecuteHoveredSlice()
        end
        RadialMenu:Close()
    end
end)

---------------------------------------------------------------------------
-- Frame Interaction
---------------------------------------------------------------------------

-- Scroll wheel switches rings
frame:EnableMouseWheel(true)
frame:SetScript("OnMouseWheel", function(_, delta)
    RadialMenu:SwitchRing(delta)
end)

-- Click on frame: left = use + close, right = close
frame:EnableMouse(true)
frame:SetScript("OnMouseDown", function(_, button)
    if button == "RightButton" then
        RadialMenu:Close()
    elseif button == "LeftButton" then
        if hoveredSliceIndex > 0 then
            RadialMenu:ExecuteHoveredSlice()
        end
        RadialMenu:Close()
    end
end)

-- Center frame: same click behavior + scroll
centerFrame:EnableMouse(true)
centerFrame:SetScript("OnMouseDown", function(_, button)
    if button == "RightButton" then
        RadialMenu:Close()
    elseif button == "LeftButton" then
        if hoveredSliceIndex > 0 then
            RadialMenu:ExecuteHoveredSlice()
        end
        RadialMenu:Close()
    end
end)
centerFrame:EnableMouseWheel(true)
centerFrame:SetScript("OnMouseWheel", function(_, delta)
    RadialMenu:SwitchRing(delta)
end)

---------------------------------------------------------------------------
-- Slash Commands
---------------------------------------------------------------------------
SLASH_MITHPIE1 = "/mp"
SlashCmdList["MITHPIE"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word:lower()) end

    local cmd = args[1]

    if not cmd or cmd == "" then
        RadialMenu:Toggle()

    elseif cmd == "refresh" then
        RadialMenu:BuildAllRings()
        if isOpen then RadialMenu:ShowCurrentRing() end
        MithUI:Print("Rings refreshed: " .. #rings .. " found")
        for i, ring in ipairs(rings) do
            print("  " .. ring.name .. ": " .. #ring.slices .. " slices")
        end

    elseif cmd == "scale" then
        local s = tonumber(args[2])
        if s then
            db.scale = s
            frame:SetScale(s)
            MithUI:Print("Scale set to " .. s)
        end

    elseif cmd == "radius" then
        local r = tonumber(args[2])
        if r then
            db.radius = r
            if isOpen then RadialMenu:ShowCurrentRing() end
            MithUI:Print("Radius set to " .. r)
        end

    elseif cmd == "size" then
        local s = tonumber(args[2])
        if s then
            db.sliceSize = s
            if isOpen then RadialMenu:ShowCurrentRing() end
            MithUI:Print("Slice size set to " .. s)
        end

    elseif cmd == "ring" then
        local idx = tonumber(args[2])
        if idx and idx >= 1 and idx <= #rings then
            activeRingIndex = idx
            MithUI:Print("Switched to ring: " .. rings[idx].name)
            if isOpen then RadialMenu:ShowCurrentRing() end
        else
            MithUI:Print("Available rings:")
            for i, ring in ipairs(rings) do
                local marker = (i == activeRingIndex) and " *" or ""
                print("  [" .. i .. "] " .. ring.name .. " (" .. #ring.slices .. " slices)" .. marker)
            end
        end

    elseif cmd == "newring" then
        local ringName = args[2]
        if not ringName or ringName == "" then
            MithUI:Print("Usage: /mp newring <name>")
            return
        end
        -- Capitalize first letter
        ringName = ringName:sub(1,1):upper() .. ringName:sub(2)
        table.insert(db.rings, {name = ringName, enabled = true, slices = {}})
        RadialMenu:BuildAllRings()
        MithUI:Print("Created custom ring: " .. ringName)
        MithUI:Print("Use /mp add <type> <id> to add slices (switch to it first with /mp ring)")

    elseif cmd == "delring" then
        local idx = tonumber(args[2])
        if not idx then
            MithUI:Print("Usage: /mp delring <ring#> (use /mp ring to see numbers)")
            return
        end
        local ring = rings[idx]
        if not ring then
            MithUI:Print("Invalid ring number: " .. idx)
            return
        end
        if not ring.isCustom then
            MithUI:Print("Cannot delete built-in ring: " .. ring.name)
            return
        end
        local dbIdx = ring.dbIndex
        if dbIdx and db.rings[dbIdx] then
            table.remove(db.rings, dbIdx)
            RadialMenu:BuildAllRings()
            MithUI:Print("Deleted ring: " .. ring.name)
        end

    elseif cmd == "add" then
        local ring = rings[activeRingIndex]
        if not ring or not ring.isCustom then
            MithUI:Print("Switch to a custom ring first (/mp ring)")
            return
        end
        local sliceType = args[2]
        local sliceId = args[3]
        if not sliceType or not sliceId then
            MithUI:Print("Usage: /mp add <type> <id>")
            print("  Types: spell, item, toy, mount, macro")
            print("  Example: /mp add spell 1953  (Blink)")
            print("  Example: /mp add item 6948   (Hearthstone)")
            print("  Example: /mp add mount 0     (Random Favorite)")
            return
        end
        local id = tonumber(sliceId)
        if not id and sliceType ~= "macro" then
            MithUI:Print("ID must be a number (except for macro type)")
            return
        end
        local newSlice = {type = sliceType, id = id}
        if sliceType == "macro" then
            -- For macro, join remaining args as macrotext
            local macroText = table.concat(args, " ", 3)
            newSlice.id = 0
            newSlice.macrotext = macroText
            newSlice.name = "Macro"
        end
        local dbIdx = ring.dbIndex
        if dbIdx and db.rings[dbIdx] and db.rings[dbIdx].slices then
            table.insert(db.rings[dbIdx].slices, newSlice)
            RadialMenu:BuildAllRings()
            MithUI:Print("Added " .. sliceType .. " to " .. ring.name)
        end

    elseif cmd == "remove" then
        local ring = rings[activeRingIndex]
        if not ring or not ring.isCustom then
            MithUI:Print("Switch to a custom ring first (/mp ring)")
            return
        end
        local sliceIdx = tonumber(args[2])
        if not sliceIdx then
            MithUI:Print("Usage: /mp remove <slice#> (use /mp list to see slice numbers)")
            return
        end
        local dbIdx = ring.dbIndex
        if dbIdx and db.rings[dbIdx] and db.rings[dbIdx].slices then
            local slices = db.rings[dbIdx].slices
            if sliceIdx < 1 or sliceIdx > #slices then
                MithUI:Print("Invalid slice number: " .. sliceIdx)
                return
            end
            local removed = table.remove(slices, sliceIdx)
            RadialMenu:BuildAllRings()
            MithUI:Print("Removed slice #" .. sliceIdx .. " from " .. ring.name)
        end

    elseif cmd == "list" then
        local ring = rings[activeRingIndex]
        if not ring then
            MithUI:Print("No active ring")
            return
        end
        MithUI:Print("Slices in [" .. ring.name .. "]" .. (ring.isCustom and " (custom)" or " (built-in)") .. ":")
        for i, slice in ipairs(ring.slices) do
            local info = "  [" .. i .. "] " .. (slice.name or "?") .. " (" .. (slice.type or "?") .. ")"
            if slice.id and slice.id ~= 0 then
                info = info .. " id=" .. slice.id
            end
            print(info)
        end

    elseif cmd == "debug" then
        MithUI:Print("Radial Menu Debug:")
        print("  Rings: " .. #rings)
        print("  Active: " .. activeRingIndex)
        print("  Open: " .. tostring(isOpen))
        print("  Hovered: " .. tostring(hoveredSliceIndex))
        print("  Scale: " .. (db.scale or 1.0))
        print("  Radius: " .. (db.radius or 120))
        print("  SliceSize: " .. (db.sliceSize or 40))
        print("  MaxMountSlices: " .. (db.maxMountSlices or 12))
        for i, ring in ipairs(rings) do
            local tag = ring.isCustom and " [custom]" or " [built-in]"
            print("  [" .. i .. "] " .. ring.name .. ": " .. #ring.slices .. " slices" .. tag)
        end

    else
        MithUI:Print("Radial Menu commands:")
        print("  /mp - Toggle menu")
        print("  /mp refresh - Rebuild rings")
        print("  /mp scale <n> - Set scale (0.5-2.0)")
        print("  /mp radius <n> - Set ring radius (60-200)")
        print("  /mp size <n> - Set slice size (24-60)")
        print("  /mp ring [n] - Switch/list rings")
        print("  /mp list - List slices in current ring")
        print("  /mp newring <name> - Create custom ring")
        print("  /mp delring <n> - Delete custom ring")
        print("  /mp add <type> <id> - Add slice to custom ring")
        print("  /mp remove <n> - Remove slice from custom ring")
        print("  /mp debug - Debug info")
        print("  Hold keybind > hover slice > release to use")
        print("  Scroll wheel to switch rings")
        print("  Right-click to cancel")
    end
end
