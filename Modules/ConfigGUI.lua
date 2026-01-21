-- MithUI Config GUI Module
-- Main settings interface

local addonName, MithUI = ...

local ConfigGUI = {}
MithUI:RegisterModule("configGUI", ConfigGUI)

local db
local mainFrame
local currentTab = 1

-- Colors - Warlock Theme (dark purple, fel green, demonic)
local COLORS = {
    bg = {0.05, 0.02, 0.08, 0.97},           -- Deep dark purple
    header = {0.12, 0.04, 0.15, 1},           -- Darker purple header
    border = {0.4, 0.1, 0.5, 1},              -- Purple border
    accent = {0.6, 0.2, 1, 1},                -- Bright purple accent
    fel = {0.4, 1, 0.3, 1},                   -- Fel green
    felDark = {0.2, 0.6, 0.15, 1},            -- Darker fel
    text = {0.9, 0.85, 1, 1},                 -- Light purple-tinted text
    textDim = {0.5, 0.4, 0.6, 1},             -- Dimmed purple text
    tabActive = {0.5, 0.1, 0.6, 1},           -- Active tab purple
    tabInactive = {0.15, 0.05, 0.2, 1},       -- Inactive tab dark
    shadow = {0.6, 0, 0.8, 0.3},              -- Purple shadow/glow
}

function ConfigGUI:OnInitialize()
    -- Will create GUI on first open
end

function ConfigGUI:OnEnable()
    db = MithUIDB
end

function ConfigGUI:Toggle()
    if not mainFrame then
        self:CreateMainFrame()
    end
    
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        self:RefreshTab()
    end
end

function ConfigGUI:CreateMainFrame()
    -- Main window
    mainFrame = CreateFrame("Frame", "MithUIConfigFrame", UIParent, "BackdropTemplate")
    mainFrame:SetSize(450, 400)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetFrameStrata("DIALOG")
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    mainFrame:SetBackdropColor(unpack(COLORS.bg))
    mainFrame:SetBackdropBorderColor(unpack(COLORS.border))
    
    -- Outer glow (demonic purple)
    local glow = mainFrame:CreateTexture(nil, "BACKGROUND", nil, -8)
    glow:SetPoint("TOPLEFT", -15, 15)
    glow:SetPoint("BOTTOMRIGHT", 15, -15)
    glow:SetTexture("Interface\\Buttons\\WHITE8x8")
    glow:SetGradient("VERTICAL", 
        CreateColor(0.3, 0, 0.4, 0.4),
        CreateColor(0.1, 0.3, 0.1, 0.3))
    glow:SetBlendMode("ADD")
    
    -- Inner shadow/vignette effect
    local innerShadow = mainFrame:CreateTexture(nil, "BORDER")
    innerShadow:SetAllPoints()
    innerShadow:SetTexture("Interface\\Buttons\\WHITE8x8")
    innerShadow:SetGradient("VERTICAL",
        CreateColor(0.02, 0, 0.05, 0.5),
        CreateColor(0.08, 0.02, 0.1, 0))
    
    -- Make movable
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    
    -- Close on ESC
    mainFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    mainFrame:SetPropagateKeyboardInput(true)
    
    -- Header
    local header = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    header:SetHeight(36)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    header:SetBackdropColor(unpack(COLORS.header))
    
    -- Title with warlock flair
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff9945ffMith|r|cff33ff33UI|r")  -- Purple + Fel green
    
    -- Version
    local version = header:CreateFontString(nil, "OVERLAY")
    version:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    version:SetPoint("RIGHT", -40, 0)
    version:SetTextColor(unpack(COLORS.textDim))
    version:SetText("v" .. MithUI.version)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", -6, 0)
    closeBtn:SetNormalFontObject("GameFontNormal")
    
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeText:SetTextColor(0.7, 0.5, 0.9)  -- Purple
    
    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(0.4, 1, 0.3) end)  -- Fel green on hover
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(0.7, 0.5, 0.9) end)  -- Purple normally
    closeBtn:SetScript("OnClick", function() mainFrame:Hide() end)
    
    -- Tab container
    local tabContainer = CreateFrame("Frame", nil, mainFrame)
    tabContainer:SetHeight(32)
    tabContainer:SetPoint("TOPLEFT", 0, -36)
    tabContainer:SetPoint("TOPRIGHT", 0, -36)
    
    -- Tabs
    mainFrame.tabs = {}
    local tabNames = {"Cast Bar", "Radial", "Assist", "Vendor", "Tooltips", "Chat", "Minimap", "Plates"}
    
    for i, name in ipairs(tabNames) do
        local tab = CreateFrame("Button", nil, tabContainer, "BackdropTemplate")
        tab:SetSize(52, 28)
        tab:SetPoint("LEFT", (i-1) * 54 + 5, 0)
        tab:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        
        local tabText = tab:CreateFontString(nil, "OVERLAY")
        tabText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        tabText:SetPoint("CENTER")
        tabText:SetText(name)
        tab.text = tabText
        
        tab:SetScript("OnClick", function()
            currentTab = i
            ConfigGUI:RefreshTab()
        end)
        
        tab:SetScript("OnEnter", function(self)
            if currentTab ~= i then
                self:SetBackdropColor(0.25, 0.08, 0.3, 1)  -- Lighter purple on hover
                self.text:SetTextColor(0.8, 0.6, 1)
            end
        end)
        
        tab:SetScript("OnLeave", function(self)
            if currentTab ~= i then
                self:SetBackdropColor(unpack(COLORS.tabInactive))
                self.text:SetTextColor(0.6, 0.5, 0.7)
            end
        end)
        
        mainFrame.tabs[i] = tab
    end
    
    -- Content area
    mainFrame.content = CreateFrame("Frame", nil, mainFrame)
    mainFrame.content:SetPoint("TOPLEFT", 10, -75)
    mainFrame.content:SetPoint("BOTTOMRIGHT", -10, 10)
    
    -- Initialize with first tab
    self:RefreshTab()
end

function ConfigGUI:RefreshTab()
    -- Update tab appearance - Warlock style
    for i, tab in ipairs(mainFrame.tabs) do
        if i == currentTab then
            tab:SetBackdropColor(unpack(COLORS.tabActive))
            tab:SetBackdropBorderColor(0.4, 1, 0.3, 1)  -- Fel green border on active
            tab.text:SetTextColor(0.4, 1, 0.3)  -- Fel green text
        else
            tab:SetBackdropColor(unpack(COLORS.tabInactive))
            tab:SetBackdropBorderColor(unpack(COLORS.border))
            tab.text:SetTextColor(0.6, 0.5, 0.7)  -- Muted purple
        end
    end
    
    -- Clear content - frames
    for _, child in pairs({mainFrame.content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Clear content - regions (textures, fontstrings)
    for _, region in pairs({mainFrame.content:GetRegions()}) do
        region:Hide()
        region:SetParent(nil)
    end
    
    -- Build tab content
    if currentTab == 1 then
        self:BuildCastBarTab()
    elseif currentTab == 2 then
        self:BuildRadialMenuTab()
    elseif currentTab == 3 then
        self:BuildAssistTab()
    elseif currentTab == 4 then
        self:BuildVendorTab()
    elseif currentTab == 5 then
        self:BuildTooltipsTab()
    elseif currentTab == 6 then
        self:BuildChatTab()
    elseif currentTab == 7 then
        self:BuildMinimapTab()
    elseif currentTab == 8 then
        self:BuildNameplatesTab()
    end
end

function ConfigGUI:BuildCastBarTab()
    local content = mainFrame.content
    local yOffset = 0
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Cast Bar", 0, yOffset, 
        MithUIDB.castBar.enabled,
        function(checked)
            MithUIDB.castBar.enabled = checked
            MithUI:Print("Cast Bar " .. (checked and "enabled" or "disabled"))
        end)
    yOffset = yOffset - 30
    
    -- Locked checkbox
    local lockedCB = self:CreateCheckbox(content, "Lock Position", 0, yOffset,
        MithUIDB.castBar.locked,
        function(checked)
            MithUIDB.castBar.locked = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Icon checkbox
    local iconCB = self:CreateCheckbox(content, "Show Spell Icon", 0, yOffset,
        MithUIDB.castBar.showIcon,
        function(checked)
            MithUIDB.castBar.showIcon = checked
            local cb = MithUI:GetModule("castBar")
            if cb then cb:Refresh() end
        end)
    yOffset = yOffset - 30
    
    -- Show Timer checkbox
    local timerCB = self:CreateCheckbox(content, "Show Timer", 0, yOffset,
        MithUIDB.castBar.showTimer,
        function(checked)
            MithUIDB.castBar.showTimer = checked
            local cb = MithUI:GetModule("castBar")
            if cb then cb:Refresh() end
        end)
    yOffset = yOffset - 40
    
    -- Scale slider
    local scaleSlider = self:CreateSlider(content, "Scale", 0, yOffset, 50, 200,
        (MithUIDB.castBar.scale or 1.0) * 100,
        function(value)
            MithUIDB.castBar.scale = value / 100
            local cb = MithUI:GetModule("castBar")
            if cb then cb:Refresh() end
        end)
    yOffset = yOffset - 50
    
    -- Width slider
    local widthSlider = self:CreateSlider(content, "Width", 0, yOffset, 150, 400,
        MithUIDB.castBar.width,
        function(value)
            MithUIDB.castBar.width = value
            local cb = MithUI:GetModule("castBar")
            if cb then cb:Refresh() end
        end)
    yOffset = yOffset - 50
    
    -- Height slider
    local heightSlider = self:CreateSlider(content, "Height", 0, yOffset, 16, 40,
        MithUIDB.castBar.height,
        function(value)
            MithUIDB.castBar.height = value
            local cb = MithUI:GetModule("castBar")
            if cb then cb:Refresh() end
        end)
    yOffset = yOffset - 50
    
    -- Preview button
    local previewBtn = self:CreateButton(content, "Preview Mode", 0, yOffset, 110, function()
        local cb = MithUI:GetModule("castBar")
        if cb then cb:SlashCommand({"preview"}) end
    end)
    
    -- Test button
    local testBtn = self:CreateButton(content, "Test", 120, yOffset, 60, function()
        local cb = MithUI:GetModule("castBar")
        if cb then cb:SlashCommand({"test"}) end
    end)
    
    -- Reset button
    local resetBtn = self:CreateButton(content, "Reset", 190, yOffset, 60, function()
        local cb = MithUI:GetModule("castBar")
        if cb then cb:SlashCommand({"reset"}) end
    end)
end

function ConfigGUI:BuildRadialMenuTab()
    local content = mainFrame.content
    local yOffset = 0
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Radial Menu", 0, yOffset,
        MithUIDB.radialMenu.enabled,
        function(checked)
            MithUIDB.radialMenu.enabled = checked
            MithUI:Print("Radial Menu " .. (checked and "enabled" or "disabled"))
        end)
    yOffset = yOffset - 40
    
    -- Keybind section
    local keybindLabel = content:CreateFontString(nil, "OVERLAY")
    keybindLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    keybindLabel:SetPoint("TOPLEFT", 0, yOffset)
    keybindLabel:SetText("Keybind:")
    keybindLabel:SetTextColor(1, 1, 1)
    
    -- Keybind display
    local keybindDisplay = content:CreateFontString(nil, "OVERLAY")
    keybindDisplay:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    keybindDisplay:SetPoint("LEFT", keybindLabel, "RIGHT", 8, 0)
    keybindDisplay:SetTextColor(0, 0.8, 1)
    
    -- Get current keybind
    local currentBind = GetBindingKey("CLICK MithUIRadialMenuButton:LeftButton") or "Not Set"
    keybindDisplay:SetText(currentBind)
    
    -- Set Keybind button
    local keybindBtn = self:CreateButton(content, "Set Keybind", 150, yOffset, 100, function() end)
    
    -- Keybind capture state
    local capturing = false
    
    keybindBtn:SetScript("OnClick", function(self)
        if capturing then return end
        capturing = true
        keybindDisplay:SetText("|cffff0000Press a key...|r")
        
        -- Create capture frame
        local captureFrame = CreateFrame("Frame", nil, UIParent)
        captureFrame:SetFrameStrata("FULLSCREEN_DIALOG")
        captureFrame:SetAllPoints()
        captureFrame:EnableKeyboard(true)
        captureFrame:SetScript("OnKeyDown", function(self, key)
            -- Ignore modifier keys alone
            if key == "LSHIFT" or key == "RSHIFT" or key == "LCTRL" or key == "RCTRL" or key == "LALT" or key == "RALT" then
                return
            end
            
            -- Build the key string with modifiers
            local bind = ""
            if IsShiftKeyDown() then bind = bind .. "SHIFT-" end
            if IsControlKeyDown() then bind = bind .. "CTRL-" end
            if IsAltKeyDown() then bind = bind .. "ALT-" end
            bind = bind .. key
            
            -- ESC to cancel
            if key == "ESCAPE" then
                keybindDisplay:SetText(GetBindingKey("CLICK MithUIRadialMenuButton:LeftButton") or "Not Set")
                capturing = false
                self:Hide()
                return
            end
            
            -- Set the binding
            if not InCombatLockdown() then
                -- Clear old binding first
                local oldKey = GetBindingKey("CLICK MithUIRadialMenuButton:LeftButton")
                if oldKey then
                    SetBinding(oldKey, nil)
                end
                
                -- Set new binding
                SetBinding(bind, "CLICK MithUIRadialMenuButton:LeftButton")
                SaveBindings(GetCurrentBindingSet())
                
                keybindDisplay:SetText(bind)
                MithUI:Print("Radial Menu bound to: " .. bind)
            else
                MithUI:Print("Cannot change keybinds in combat")
                keybindDisplay:SetText(GetBindingKey("CLICK MithUIRadialMenuButton:LeftButton") or "Not Set")
            end
            
            capturing = false
            self:Hide()
        end)
        
        captureFrame:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" or button == "RightButton" then
                -- Cancel on mouse click
                keybindDisplay:SetText(GetBindingKey("CLICK MithUIRadialMenuButton:LeftButton") or "Not Set")
                capturing = false
                self:Hide()
            end
        end)
    end)
    
    -- Clear keybind button
    local clearBtn = self:CreateButton(content, "Clear", 260, yOffset, 60, function()
        if not InCombatLockdown() then
            local oldKey = GetBindingKey("CLICK MithUIRadialMenuButton:LeftButton")
            if oldKey then
                SetBinding(oldKey, nil)
                SaveBindings(GetCurrentBindingSet())
            end
            keybindDisplay:SetText("Not Set")
            MithUI:Print("Keybind cleared")
        end
    end)
    
    yOffset = yOffset - 50
    
    -- Scale slider
    local scaleSlider = self:CreateSlider(content, "Scale", 0, yOffset, 50, 200,
        (MithUIDB.radialMenu.scale or 1.0) * 100,
        function(value)
            MithUIDB.radialMenu.scale = value / 100
            local rm = MithUI:GetModule("radialMenu")
            if rm and MithUIRadialMenu then
                MithUIRadialMenu:SetScale(value / 100)
            end
        end)
    yOffset = yOffset - 50
    
    -- Radius slider
    local radiusSlider = self:CreateSlider(content, "Ring Radius", 0, yOffset, 60, 200,
        MithUIDB.radialMenu.ringRadius or 150,
        function(value)
            MithUIDB.radialMenu.ringRadius = value
        end)
    yOffset = yOffset - 50
    
    -- Button size slider
    local btnSlider = self:CreateSlider(content, "Button Size", 0, yOffset, 24, 50,
        MithUIDB.radialMenu.buttonSize or 30,
        function(value)
            MithUIDB.radialMenu.buttonSize = value
        end)
    yOffset = yOffset - 50
    
    -- Test menu button
    local openBtn = self:CreateButton(content, "Test Menu", 0, yOffset, 100, function()
        local rm = MithUI:GetModule("radialMenu")
        if rm then rm:Toggle() end
    end)
    yOffset = yOffset - 40
    
    -- Help text
    local helpText = content:CreateFontString(nil, "OVERLAY")
    helpText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    helpText:SetPoint("TOPLEFT", 0, yOffset)
    helpText:SetWidth(400)
    helpText:SetJustifyH("LEFT")
    helpText:SetTextColor(unpack(COLORS.textDim))
    helpText:SetText("Press keybind > Scroll wheel to change rings > Click item")
end

function ConfigGUI:BuildAssistTab()
    local content = mainFrame.content
    local yOffset = 0
    
    if not MithUIDB.assistDisplay then MithUIDB.assistDisplay = {} end
    local adb = MithUIDB.assistDisplay
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Assist Display", 0, yOffset,
        adb.enabled ~= false,
        function(checked)
            adb.enabled = checked
            local ad = MithUI:GetModule("assistDisplay")
            if ad then
                if checked then ad:StartWatching() else ad:StopWatching() end
            end
        end)
    yOffset = yOffset - 30
    
    -- Lock Position
    local lockCB = self:CreateCheckbox(content, "Lock Position", 0, yOffset,
        adb.locked ~= false,
        function(checked)
            adb.locked = checked
            MithUI:Print("Assist Display " .. (checked and "locked" or "unlocked - drag to move"))
        end)
    yOffset = yOffset - 30
    
    -- Show Keybind
    local keybindCB = self:CreateCheckbox(content, "Show Keybind", 0, yOffset,
        adb.showKeybind ~= false,
        function(checked)
            adb.showKeybind = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Spell Name
    local nameCB = self:CreateCheckbox(content, "Show Spell Name", 0, yOffset,
        adb.showSpellName ~= false,
        function(checked)
            adb.showSpellName = checked
        end)
    yOffset = yOffset - 30
    
    -- Glow Effect
    local glowCB = self:CreateCheckbox(content, "Animated Glow", 0, yOffset,
        adb.glowEnabled ~= false,
        function(checked)
            adb.glowEnabled = checked
        end)
    yOffset = yOffset - 40
    
    -- Scale slider
    local scaleSlider = self:CreateSlider(content, "Scale", 0, yOffset, 50, 250,
        (adb.scale or 1.2) * 100,
        function(value)
            adb.scale = value / 100
            if MithUIAssistDisplay then
                MithUIAssistDisplay:SetScale(value / 100)
            end
        end)
    yOffset = yOffset - 50
    
    -- Test button
    local testBtn = self:CreateButton(content, "Test Display", 0, yOffset, 100, function()
        local ad = MithUI:GetModule("assistDisplay")
        if ad then
            -- Stop scanning so test stays visible
            if ad.updateFrame then
                ad.updateFrame:SetScript("OnUpdate", nil)
            end
        end
        if MithUIAssistDisplay then
            local f = MithUIAssistDisplay
            f.icon:SetTexture(136048)
            f.keybind:SetText("S-2")
            f.spellName:SetText("Test Ability")
            f.glow:Show()
            f:Show()
        end
    end)
    
    -- Hide button
    local hideBtn = self:CreateButton(content, "Hide", 110, yOffset, 50, function()
        if MithUIAssistDisplay then
            MithUIAssistDisplay:Hide()
        end
    end)
    
    -- Reset Position button
    local resetBtn = self:CreateButton(content, "Reset Pos", 170, yOffset, 70, function()
        adb.posX, adb.posY = 0, -250
        if MithUIAssistDisplay then
            MithUIAssistDisplay:ClearAllPoints()
            MithUIAssistDisplay:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
        end
        MithUI:Print("Position reset")
    end)
    yOffset = yOffset - 40
    
    -- Help text
    local helpText = content:CreateFontString(nil, "OVERLAY")
    helpText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    helpText:SetPoint("TOPLEFT", 0, yOffset)
    helpText:SetWidth(400)
    helpText:SetTextColor(unpack(COLORS.textDim))
    helpText:SetText("Shows the Blizzard Assist highlighted ability in a larger frame.\nUnlock to drag it anywhere on screen.\nUse /ma for more options.")
end

function ConfigGUI:BuildVendorTab()
    local content = mainFrame.content
    local yOffset = 0
    
    if not MithUIDB.autoVendor then MithUIDB.autoVendor = {} end
    local avdb = MithUIDB.autoVendor
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Auto Vendor", 0, yOffset,
        avdb.enabled ~= false,
        function(checked)
            avdb.enabled = checked
        end)
    yOffset = yOffset - 30
    
    -- Auto Repair
    local repairCB = self:CreateCheckbox(content, "Auto Repair", 0, yOffset,
        avdb.autoRepair ~= false,
        function(checked)
            avdb.autoRepair = checked
        end)
    yOffset = yOffset - 30
    
    -- Use Guild Repair
    local guildCB = self:CreateCheckbox(content, "Use Guild Bank for Repair", 0, yOffset,
        avdb.useGuildRepair ~= false,
        function(checked)
            avdb.useGuildRepair = checked
        end)
    yOffset = yOffset - 30
    
    -- Auto Sell Junk
    local junkCB = self:CreateCheckbox(content, "Auto Sell Junk (Gray Items)", 0, yOffset,
        avdb.autoSellJunk ~= false,
        function(checked)
            avdb.autoSellJunk = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Summary
    local summaryCB = self:CreateCheckbox(content, "Show Summary in Chat", 0, yOffset,
        avdb.showSummary ~= false,
        function(checked)
            avdb.showSummary = checked
        end)
    yOffset = yOffset - 40
    
    -- Help text
    local helpText = content:CreateFontString(nil, "OVERLAY")
    helpText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    helpText:SetPoint("TOPLEFT", 0, yOffset)
    helpText:SetTextColor(unpack(COLORS.textDim))
    helpText:SetText("Use /av for more options\nAdd custom items to sell/never-sell lists")
end

function ConfigGUI:BuildTooltipsTab()
    local content = mainFrame.content
    local yOffset = 0
    
    if not MithUIDB.tooltips then MithUIDB.tooltips = {} end
    local ttdb = MithUIDB.tooltips
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Tooltip Enhancements", 0, yOffset,
        ttdb.enabled ~= false,
        function(checked)
            ttdb.enabled = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Item Level
    local ilvlCB = self:CreateCheckbox(content, "Show Item Level", 0, yOffset,
        ttdb.showItemLevel ~= false,
        function(checked)
            ttdb.showItemLevel = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Spec
    local specCB = self:CreateCheckbox(content, "Show Specialization", 0, yOffset,
        ttdb.showSpec ~= false,
        function(checked)
            ttdb.showSpec = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Guild
    local guildCB = self:CreateCheckbox(content, "Show Guild Info", 0, yOffset,
        ttdb.showGuild ~= false,
        function(checked)
            ttdb.showGuild = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Target of Target
    local totCB = self:CreateCheckbox(content, "Show Target of Target", 0, yOffset,
        ttdb.showTargetOfTarget ~= false,
        function(checked)
            ttdb.showTargetOfTarget = checked
        end)
    yOffset = yOffset - 30
    
    -- Class Colors
    local classCB = self:CreateCheckbox(content, "Class-Colored Names", 0, yOffset,
        ttdb.classColors ~= false,
        function(checked)
            ttdb.classColors = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Item ID (dev)
    local itemidCB = self:CreateCheckbox(content, "Show Item IDs (dev)", 0, yOffset,
        ttdb.showItemID == true,
        function(checked)
            ttdb.showItemID = checked
        end)
    yOffset = yOffset - 30
    
    -- Show Spell ID (dev)
    local spellidCB = self:CreateCheckbox(content, "Show Spell IDs (dev)", 0, yOffset,
        ttdb.showSpellID == true,
        function(checked)
            ttdb.showSpellID = checked
        end)
end

function ConfigGUI:BuildChatTab()
    local content = mainFrame.content
    local yOffset = 0
    
    if not MithUIDB.chat then MithUIDB.chat = {} end
    local chatdb = MithUIDB.chat
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Chat Enhancements", 0, yOffset,
        chatdb.enabled ~= false,
        function(checked)
            chatdb.enabled = checked
        end)
    yOffset = yOffset - 30
    
    -- Class Colors
    local classCB = self:CreateCheckbox(content, "Class-Colored Names", 0, yOffset,
        chatdb.classColors ~= false,
        function(checked)
            chatdb.classColors = checked
        end)
    yOffset = yOffset - 30
    
    -- Clickable URLs
    local urlsCB = self:CreateCheckbox(content, "Clickable URLs", 0, yOffset,
        chatdb.clickableURLs ~= false,
        function(checked)
            chatdb.clickableURLs = checked
        end)
    yOffset = yOffset - 30
    
    -- Copy Chat
    local copyCB = self:CreateCheckbox(content, "Copy Chat Button", 0, yOffset,
        chatdb.copyChat ~= false,
        function(checked)
            chatdb.copyChat = checked
        end)
    yOffset = yOffset - 30
    
    -- Timestamps
    local timeCB = self:CreateCheckbox(content, "Show Timestamps", 0, yOffset,
        chatdb.timestamps == true,
        function(checked)
            chatdb.timestamps = checked
        end)
    yOffset = yOffset - 30
    
    -- Shorten Channels
    local shortCB = self:CreateCheckbox(content, "Shorten Channel Names", 0, yOffset,
        chatdb.shortenChannels ~= false,
        function(checked)
            chatdb.shortenChannels = checked
        end)
    yOffset = yOffset - 40
    
    -- Copy button
    local copyBtn = self:CreateButton(content, "Copy Chat", 0, yOffset, 100, function()
        local chat = MithUI:GetModule("chat")
        if chat then chat:ShowCopyFrame(ChatFrame1) end
    end)
end

function ConfigGUI:BuildMinimapTab()
    local content = mainFrame.content
    local yOffset = 0
    
    if not MithUIDB.minimap then MithUIDB.minimap = {} end
    local mmdb = MithUIDB.minimap
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Minimap Cleanup", 0, yOffset,
        mmdb.enabled ~= false,
        function(checked)
            mmdb.enabled = checked
        end)
    yOffset = yOffset - 30
    
    -- Hide Zoom Buttons
    local zoomCB = self:CreateCheckbox(content, "Hide Zoom Buttons (use scroll)", 0, yOffset,
        mmdb.hideZoomButtons ~= false,
        function(checked)
            mmdb.hideZoomButtons = checked
        end)
    yOffset = yOffset - 30
    
    -- Hide Calendar
    local calCB = self:CreateCheckbox(content, "Hide Calendar", 0, yOffset,
        mmdb.hideCalendar == true,
        function(checked)
            mmdb.hideCalendar = checked
        end)
    yOffset = yOffset - 30
    
    -- Hide Clock
    local clockCB = self:CreateCheckbox(content, "Hide Clock", 0, yOffset,
        mmdb.hideClock == true,
        function(checked)
            mmdb.hideClock = checked
        end)
    yOffset = yOffset - 30
    
    -- Collect Buttons
    local btnsCB = self:CreateCheckbox(content, "Collect Addon Buttons", 0, yOffset,
        mmdb.collectButtons ~= false,
        function(checked)
            mmdb.collectButtons = checked
        end)
    yOffset = yOffset - 30
    
    -- Square Minimap
    local sqCB = self:CreateCheckbox(content, "Square Minimap (reload)", 0, yOffset,
        mmdb.squareMinimap == true,
        function(checked)
            mmdb.squareMinimap = checked
        end)
    yOffset = yOffset - 40
    
    -- Note
    local noteText = content:CreateFontString(nil, "OVERLAY")
    noteText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    noteText:SetPoint("TOPLEFT", 0, yOffset)
    noteText:SetTextColor(unpack(COLORS.textDim))
    noteText:SetText("Some changes require /reload to take effect\nHover minimap to see collected buttons")
end

function ConfigGUI:BuildNameplatesTab()
    local content = mainFrame.content
    local yOffset = 0
    
    if not MithUIDB.nameplates then MithUIDB.nameplates = {} end
    local npdb = MithUIDB.nameplates
    
    -- Enable checkbox
    local enableCB = self:CreateCheckbox(content, "Enable Nameplates", 0, yOffset,
        npdb.enabled ~= false,
        function(checked)
            npdb.enabled = checked
        end)
    yOffset = yOffset - 30
    
    -- Quest Indicator
    local questCB = self:CreateCheckbox(content, "Quest Mob Indicator (orange)", 0, yOffset,
        npdb.showQuestIndicator ~= false,
        function(checked)
            npdb.showQuestIndicator = checked
        end)
    yOffset = yOffset - 30
    
    -- Cast Bars
    local castCB = self:CreateCheckbox(content, "Show Cast Bars", 0, yOffset,
        npdb.showCastBar ~= false,
        function(checked)
            npdb.showCastBar = checked
        end)
    yOffset = yOffset - 30
    
    -- Threat Colors
    local threatCB = self:CreateCheckbox(content, "Threat Colors", 0, yOffset,
        npdb.useThreatColors ~= false,
        function(checked)
            npdb.useThreatColors = checked
        end)
    yOffset = yOffset - 30
    
    -- Class Colors
    local classCB = self:CreateCheckbox(content, "Class Colors (players)", 0, yOffset,
        npdb.useClassColors ~= false,
        function(checked)
            npdb.useClassColors = checked
        end)
    yOffset = yOffset - 30
    
    -- Target Highlight
    local targetCB = self:CreateCheckbox(content, "Target Highlight", 0, yOffset,
        npdb.showTargetHighlight ~= false,
        function(checked)
            npdb.showTargetHighlight = checked
        end)
    yOffset = yOffset - 30
    
    -- Health Text
    local healthCB = self:CreateCheckbox(content, "Show Health %", 0, yOffset,
        npdb.showHealthText ~= false,
        function(checked)
            npdb.showHealthText = checked
        end)
    yOffset = yOffset - 40
    
    -- Help text
    local helpText = content:CreateFontString(nil, "OVERLAY")
    helpText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    helpText:SetPoint("TOPLEFT", 0, yOffset)
    helpText:SetTextColor(unpack(COLORS.textDim))
    helpText:SetText("Use /np theme [name] for themes:\ngrey, neon, clean, thin, headline\n\nGreen glow on cast bar = INTERRUPT!")
end

-- UI Helper: Checkbox
function ConfigGUI:CreateCheckbox(parent, label, x, y, checked, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetSize(24, 24)
    cb:SetChecked(checked)
    
    local text = cb:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    text:SetText(label)
    text:SetTextColor(unpack(COLORS.text))
    
    cb:SetScript("OnClick", function(self)
        onChange(self:GetChecked())
    end)
    
    return cb
end

-- UI Helper: Slider
function ConfigGUI:CreateSlider(parent, label, x, y, minVal, maxVal, currentVal, onChange)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 40)
    container:SetPoint("TOPLEFT", x, y)
    
    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetTextColor(unpack(COLORS.text))
    
    local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 0, -16)
    slider:SetSize(180, 16)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(currentVal)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    
    -- Hide default text
    slider.Low:SetText("")
    slider.High:SetText("")
    slider.Text:SetText("")
    
    local function UpdateText()
        text:SetText(label .. ": " .. math.floor(slider:GetValue()))
    end
    UpdateText()
    
    slider:SetScript("OnValueChanged", function(self, value)
        UpdateText()
        onChange(math.floor(value))
    end)
    
    return container
end

-- UI Helper: Button - Warlock style
function ConfigGUI:CreateButton(parent, label, x, y, width, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 24)
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(0.15, 0.05, 0.2, 1)  -- Dark purple
    btn:SetBackdropBorderColor(unpack(COLORS.border))
    
    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    text:SetPoint("CENTER")
    text:SetText(label)
    text:SetTextColor(unpack(COLORS.text))
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.3, 0.1, 0.4, 1)  -- Brighter purple
        self:SetBackdropBorderColor(0.4, 1, 0.3, 1)  -- Fel green border
        text:SetTextColor(0.4, 1, 0.3)  -- Fel green text
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.05, 0.2, 1)
        self:SetBackdropBorderColor(unpack(COLORS.border))
        text:SetTextColor(unpack(COLORS.text))
    end)
    btn:SetScript("OnClick", onClick)
    
    return btn
end

-- Slash command
SLASH_MITHUI_CONFIG1 = "/mu"

SlashCmdList["MITHUI_CONFIG"] = function(msg)
    ConfigGUI:Toggle()
end
