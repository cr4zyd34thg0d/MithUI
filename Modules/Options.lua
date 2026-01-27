-- MithUI Options Panel
-- Integrates with WoW's Interface > AddOns menu

local addonName, MithUI = ...

local Options = {}
MithUI:RegisterModule("options", Options)

local db

-- Panel references
local mainPanel
local subPanels = {}

function Options:OnInitialize()
    -- Will create panels after ADDON_LOADED
end

function Options:OnEnable()
    db = MithUIDB
    self:CreateOptionsPanel()
end

function Options:CreateOptionsPanel()
    -- Main panel (shows in AddOns list)
    mainPanel = CreateFrame("Frame")
    mainPanel.name = "MithUI"
    
    -- Title
    local title = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ccffMithUI|r")
    
    -- Description
    local desc = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText("Clean, minimal UI enhancements for WoW")
    
    -- Version
    local version = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -4)
    version:SetTextColor(0.5, 0.5, 0.5)
    version:SetText("Version " .. MithUI.version)
    
    -- Instructions
    local instructions = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    instructions:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -20)
    instructions:SetWidth(550)
    instructions:SetJustifyH("LEFT")
    instructions:SetText("Select a module from the list on the left to configure it.\n\nOr use |cff00ff00/mu|r in chat to open the standalone settings window.")
    
    -- Slash command reminder
    local slashTitle = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    slashTitle:SetPoint("TOPLEFT", instructions, "BOTTOMLEFT", 0, -20)
    slashTitle:SetText("Quick Commands:")
    
    local slashList = mainPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slashList:SetPoint("TOPLEFT", slashTitle, "BOTTOMLEFT", 0, -8)
    slashList:SetWidth(550)
    slashList:SetJustifyH("LEFT")
    slashList:SetText("|cff00ff00/mu|r - Open settings GUI\n|cff00ff00/mc|r - Cast Bar\n|cff00ff00/mp|r - Radial Menu\n|cff00ff00/av|r - Auto Vendor\n|cff00ff00/tt|r - Tooltips\n|cff00ff00/chat|r - Chat\n|cff00ff00/mm|r - Minimap\n|cff00ff00/np|r - Nameplates")
    
    -- Register with new Settings API (WoW 10.0+)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(mainPanel, mainPanel.name)
        Settings.RegisterAddOnCategory(category)
        mainPanel.category = category
        
        -- Create sub-panels for each module
        self:CreateSubPanel(category, "Cast Bar", self.BuildCastBarOptions)
        self:CreateSubPanel(category, "Radial Menu", self.BuildRadialMenuOptions)
        self:CreateSubPanel(category, "Auto Vendor", self.BuildVendorOptions)
        self:CreateSubPanel(category, "Tooltips", self.BuildTooltipsOptions)
        self:CreateSubPanel(category, "Chat", self.BuildChatOptions)
        self:CreateSubPanel(category, "Minimap", self.BuildMinimapOptions)
        self:CreateSubPanel(category, "Nameplates", self.BuildNameplatesOptions)
    else
        -- Fallback for older API
        InterfaceOptions_AddCategory(mainPanel)
    end
end

function Options:CreateSubPanel(parentCategory, name, buildFunc)
    local panel = CreateFrame("Frame")
    panel.name = name
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ccff" .. name .. "|r")
    
    -- Content area
    panel.content = CreateFrame("Frame", nil, panel)
    panel.content:SetPoint("TOPLEFT", 16, -50)
    panel.content:SetPoint("BOTTOMRIGHT", -16, 16)
    
    -- Build the options
    panel:SetScript("OnShow", function(self)
        if not self.initialized then
            buildFunc(Options, self.content)
            self.initialized = true
        end
    end)
    
    -- Register as sub-category
    if Settings and Settings.RegisterCanvasLayoutSubcategory then
        local subcategory = Settings.RegisterCanvasLayoutSubcategory(parentCategory, panel, name)
        subPanels[name] = subcategory
    end
end

-- Helper: Create checkbox
function Options:CreateCheckbox(parent, label, x, y, dbTable, dbKey, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    
    cb:SetChecked(dbTable[dbKey] ~= false)
    
    cb:SetScript("OnClick", function(self)
        dbTable[dbKey] = self:GetChecked()
        if onChange then onChange(self:GetChecked()) end
    end)
    
    return cb
end

-- Helper: Create slider
function Options:CreateSlider(parent, label, x, y, minVal, maxVal, dbTable, dbKey, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(250, 50)
    container:SetPoint("TOPLEFT", x, y)
    
    local text = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("TOPLEFT", 0, 0)
    
    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -20)
    slider:SetSize(200, 17)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(dbTable[dbKey] or minVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    
    slider.Low:SetText(minVal)
    slider.High:SetText(maxVal)
    slider.Text:SetText("")
    
    local function UpdateText()
        text:SetText(label .. ": " .. math.floor(slider:GetValue()))
    end
    UpdateText()
    
    slider:SetScript("OnValueChanged", function(self, value)
        dbTable[dbKey] = math.floor(value)
        UpdateText()
        if onChange then onChange(math.floor(value)) end
    end)
    
    return container
end

-- Cast Bar Options
function Options:BuildCastBarOptions(content)
    if not MithUIDB.castBar then MithUIDB.castBar = {} end
    local db = MithUIDB.castBar
    local yOffset = 0
    
    Options:CreateCheckbox(content, "Enable Cast Bar", 0, yOffset, db, "enabled")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Lock Position", 0, yOffset, db, "locked")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Spell Icon", 0, yOffset, db, "showIcon", function()
        local cb = MithUI:GetModule("castBar")
        if cb then cb:Refresh() end
    end)
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Timer", 0, yOffset, db, "showTimer", function()
        local cb = MithUI:GetModule("castBar")
        if cb then cb:Refresh() end
    end)
    yOffset = yOffset - 40
    
    Options:CreateSlider(content, "Width", 0, yOffset, 150, 400, db, "width", function()
        local cb = MithUI:GetModule("castBar")
        if cb then cb:Refresh() end
    end)
    yOffset = yOffset - 60
    
    Options:CreateSlider(content, "Height", 0, yOffset, 16, 40, db, "height", function()
        local cb = MithUI:GetModule("castBar")
        if cb then cb:Refresh() end
    end)
end

-- Radial Menu Options
function Options:BuildRadialMenuOptions(content)
    if not MithUIDB.radialMenu then MithUIDB.radialMenu = {} end
    local db = MithUIDB.radialMenu
    local yOffset = 0

    Options:CreateCheckbox(content, "Enable Radial Menu", 0, yOffset, db, "enabled")
    yOffset = yOffset - 30

    Options:CreateCheckbox(content, "Show Cooldowns on Slices", 0, yOffset, db, "showCooldowns")
    yOffset = yOffset - 30

    Options:CreateCheckbox(content, "Show Ring Name", 0, yOffset, db, "showRingName")
    yOffset = yOffset - 40

    -- Initialize scalePercent from scale for slider
    db.scalePercent = (db.scale or 1) * 100

    Options:CreateSlider(content, "Scale", 0, yOffset, 50, 200, db, "scalePercent", function(val)
        db.scale = val / 100
        if MithUIRadialMenu then MithUIRadialMenu:SetScale(db.scale) end
    end)
    yOffset = yOffset - 60

    Options:CreateSlider(content, "Ring Radius", 0, yOffset, 60, 200, db, "radius")
    yOffset = yOffset - 60

    Options:CreateSlider(content, "Slice Size", 0, yOffset, 24, 60, db, "sliceSize")
    yOffset = yOffset - 60

    Options:CreateSlider(content, "Max Favorite Mounts", 0, yOffset, 4, 32, db, "maxMountSlices", function(val)
        local rm = MithUI:GetModule("radialMenu")
        if rm then rm:BuildAllRings() end
    end)
    yOffset = yOffset - 60

    -- Keybind info
    local keybindInfo = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    keybindInfo:SetPoint("TOPLEFT", 0, yOffset)
    keybindInfo:SetWidth(400)
    keybindInfo:SetJustifyH("LEFT")
    keybindInfo:SetText("|cff00ccffKeybind:|r Use |cff00ff00/mu|r to set keybind, or Key Bindings > Addons > MithUI\n\n|cff00ccffUsage:|r Hold keybind > Hover slice > Release to use\nScroll wheel to switch rings | Right-click to cancel\n\n|cff00ccffRings:|r Mounts, Hearthstones, Class Spells, Target Markers\nEnable/disable rings in |cff00ff00/mu|r settings")
end

-- Auto Vendor Options
function Options:BuildVendorOptions(content)
    if not MithUIDB.autoVendor then MithUIDB.autoVendor = {} end
    local db = MithUIDB.autoVendor
    local yOffset = 0
    
    Options:CreateCheckbox(content, "Enable Auto Vendor", 0, yOffset, db, "enabled")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Auto Repair", 0, yOffset, db, "autoRepair")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Use Guild Bank for Repair", 0, yOffset, db, "useGuildRepair")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Auto Sell Junk (Gray Items)", 0, yOffset, db, "autoSellJunk")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Summary in Chat", 0, yOffset, db, "showSummary")
end

-- Tooltips Options
function Options:BuildTooltipsOptions(content)
    if not MithUIDB.tooltips then MithUIDB.tooltips = {} end
    local db = MithUIDB.tooltips
    local yOffset = 0
    
    Options:CreateCheckbox(content, "Enable Tooltip Enhancements", 0, yOffset, db, "enabled")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Item Level", 0, yOffset, db, "showItemLevel")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Specialization", 0, yOffset, db, "showSpec")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Guild Info", 0, yOffset, db, "showGuild")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Target of Target", 0, yOffset, db, "showTargetOfTarget")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Class-Colored Names", 0, yOffset, db, "classColors")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Item IDs (dev)", 0, yOffset, db, "showItemID")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Spell IDs (dev)", 0, yOffset, db, "showSpellID")
end

-- Chat Options
function Options:BuildChatOptions(content)
    if not MithUIDB.chat then MithUIDB.chat = {} end
    local db = MithUIDB.chat
    local yOffset = 0
    
    Options:CreateCheckbox(content, "Enable Chat Enhancements", 0, yOffset, db, "enabled")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Class-Colored Names", 0, yOffset, db, "classColors")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Clickable URLs", 0, yOffset, db, "clickableURLs")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Copy Chat Button", 0, yOffset, db, "copyChat")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Timestamps", 0, yOffset, db, "timestamps")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Shorten Channel Names", 0, yOffset, db, "shortenChannels")
end

-- Minimap Options
function Options:BuildMinimapOptions(content)
    if not MithUIDB.minimap then MithUIDB.minimap = {} end
    local db = MithUIDB.minimap
    local yOffset = 0
    
    Options:CreateCheckbox(content, "Enable Minimap Cleanup", 0, yOffset, db, "enabled")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Hide Zoom Buttons (use scroll)", 0, yOffset, db, "hideZoomButtons")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Hide Calendar", 0, yOffset, db, "hideCalendar")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Hide Clock", 0, yOffset, db, "hideClock")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Collect Addon Buttons", 0, yOffset, db, "collectButtons")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Square Minimap (requires reload)", 0, yOffset, db, "squareMinimap")
end

-- Nameplates Options
function Options:BuildNameplatesOptions(content)
    if not MithUIDB.nameplates then MithUIDB.nameplates = {} end
    local db = MithUIDB.nameplates
    local yOffset = 0
    
    Options:CreateCheckbox(content, "Enable Nameplates", 0, yOffset, db, "enabled")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Quest Mob Indicator (orange)", 0, yOffset, db, "showQuestIndicator")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Cast Bars", 0, yOffset, db, "showCastBar")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Threat Colors", 0, yOffset, db, "useThreatColors")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Class Colors (players)", 0, yOffset, db, "useClassColors")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Target Highlight", 0, yOffset, db, "showTargetHighlight")
    yOffset = yOffset - 30
    
    Options:CreateCheckbox(content, "Show Health %", 0, yOffset, db, "showHealthText")
    yOffset = yOffset - 40
    
    -- Theme info
    local themeInfo = content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    themeInfo:SetPoint("TOPLEFT", 0, yOffset)
    themeInfo:SetWidth(400)
    themeInfo:SetJustifyH("LEFT")
    themeInfo:SetText("|cff00ccffThemes:|r Use /np theme [name]\nAvailable: grey, neon, clean, thin, headline\n\n|cff00ff00Green glow|r on cast bar = INTERRUPT!")
end

-- Open options panel
function Options:Open()
    if Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(mainPanel.category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(mainPanel)
        InterfaceOptionsFrame_OpenToCategory(mainPanel) -- Call twice for sub-panels
    end
end
