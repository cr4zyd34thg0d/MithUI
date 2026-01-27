-- MithUI Minimap Cleanup Module
-- Hide/organize minimap buttons, clean up clutter

local addonName, MithUI = ...

local Minimap = {}
MithUI:RegisterModule("minimap", Minimap)

local db
local buttonBag  -- Frame to hold collected buttons

-- Default settings
local defaults = {
    enabled = true,
    hideZoomButtons = true,
    hideWorldMap = false,
    hideTracking = false,
    hideCalendar = false,
    hideClock = false,
    collectButtons = true,
    buttonBagScale = 0.8,
    squareMinimap = false,
    borderColor = {0.2, 0.2, 0.2, 1},
}

-- Known addon buttons to collect
local ADDON_BUTTONS = {
    "LibDBIcon10_",
    "MiniMapTracking",
    "MiniMapMailFrame",
    "GameTimeFrame",
    "MinimapZoomIn",
    "MinimapZoomOut",
}

function Minimap:OnInitialize()
    MithUI.defaults.minimap = defaults
end

function Minimap:OnEnable()
    -- Ensure minimap settings exist in database
    if not MithUIDB.minimap then
        MithUIDB.minimap = {}
        MithUI:CopyTable(defaults, MithUIDB.minimap)
    end
    db = MithUIDB.minimap

    -- Delay to let other addons create their buttons
    C_Timer.After(2, function()
        Minimap:ApplySettings()
        Minimap:CollectButtons()
    end)
end

function Minimap:ApplySettings()
    if not db or not db.enabled then return end
    
    -- Hide zoom buttons (removed in WoW 12.0, check existence)
    if db.hideZoomButtons then
        if MinimapZoomIn then
            MinimapZoomIn:Hide()
            MinimapZoomIn:UnregisterAllEvents()
        end
        if MinimapZoomOut then
            MinimapZoomOut:Hide()
            MinimapZoomOut:UnregisterAllEvents()
        end

        -- Enable scroll zoom instead
        _G.Minimap:EnableMouseWheel(true)
        _G.Minimap:SetScript("OnMouseWheel", function(self, delta)
            if delta > 0 then
                if _G.Minimap_ZoomIn then
                    _G.Minimap_ZoomIn()
                else
                    _G.Minimap:SetZoom(min(_G.Minimap:GetZoom() + 1, _G.Minimap:GetZoomLevels()))
                end
            else
                if _G.Minimap_ZoomOut then
                    _G.Minimap_ZoomOut()
                else
                    _G.Minimap:SetZoom(max(_G.Minimap:GetZoom() - 1, 0))
                end
            end
        end)
    end
    
    -- Hide world map button
    if db.hideWorldMap and MiniMapWorldMapButton then
        MiniMapWorldMapButton:Hide()
        MiniMapWorldMapButton:UnregisterAllEvents()
    end
    
    -- Hide tracking button
    if db.hideTracking and MiniMapTracking then
        MiniMapTracking:Hide()
    end
    
    -- Hide calendar
    if db.hideCalendar and GameTimeFrame then
        GameTimeFrame:Hide()
        GameTimeFrame:UnregisterAllEvents()
    end
    
    -- Hide clock
    if db.hideClock and TimeManagerClockButton then
        TimeManagerClockButton:Hide()
    end
    
    -- Square minimap (optional)
    if db.squareMinimap then
        _G.Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8x8")
    end
    
    -- Custom border
    if not _G.Minimap.mithBorder then
        local border = CreateFrame("Frame", nil, _G.Minimap, "BackdropTemplate")
        border:SetPoint("TOPLEFT", -3, 3)
        border:SetPoint("BOTTOMRIGHT", 3, -3)
        border:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 2,
        })
        border:SetBackdropBorderColor(unpack(db.borderColor))
        _G.Minimap.mithBorder = border
    end
end

function Minimap:CollectButtons()
    if not db or not db.collectButtons then return end
    
    -- Create button bag (hidden container that shows on hover)
    if not buttonBag then
        buttonBag = CreateFrame("Frame", "MithUIMinimapButtonBag", _G.Minimap, "BackdropTemplate")
        buttonBag:SetSize(200, 40)
        buttonBag:SetPoint("TOPLEFT", _G.Minimap, "BOTTOMLEFT", 0, -5)
        buttonBag:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        buttonBag:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        buttonBag:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        buttonBag:SetScale(db.buttonBagScale)
        buttonBag:Hide()
        
        -- Show on minimap hover
        _G.Minimap:HookScript("OnEnter", function()
            if db.collectButtons then
                buttonBag:Show()
            end
        end)
        
        _G.Minimap:HookScript("OnLeave", function()
            C_Timer.After(0.5, function()
                if not buttonBag:IsMouseOver() and not _G.Minimap:IsMouseOver() then
                    buttonBag:Hide()
                end
            end)
        end)
        
        buttonBag:SetScript("OnLeave", function()
            C_Timer.After(0.5, function()
                if not buttonBag:IsMouseOver() and not _G.Minimap:IsMouseOver() then
                    buttonBag:Hide()
                end
            end)
        end)
    end
    
    -- Find and collect addon buttons
    local buttons = {}
    local children = {_G.Minimap:GetChildren()}
    
    for _, child in ipairs(children) do
        local name = child:GetName()
        if name and child:IsObjectType("Button") then
            -- Check if it's an addon button
            local isAddonButton = false
            for _, pattern in ipairs(ADDON_BUTTONS) do
                if name:match(pattern) then
                    isAddonButton = true
                    break
                end
            end
            
            -- Also check for LibDBIcon buttons
            if name:match("^LibDBIcon") then
                isAddonButton = true
            end
            
            if isAddonButton and child:IsShown() then
                table.insert(buttons, child)
            end
        end
    end
    
    -- Also scan for buttons around the minimap
    local minimapChildren = {MinimapBackdrop:GetChildren()}
    for _, child in ipairs(minimapChildren) do
        if child:IsObjectType("Button") and child:IsShown() then
            local name = child:GetName()
            if name and name:match("^LibDBIcon") then
                table.insert(buttons, child)
            end
        end
    end
    
    -- Position collected buttons in the bag
    local xOffset = 5
    for i, button in ipairs(buttons) do
        button:SetParent(buttonBag)
        button:ClearAllPoints()
        button:SetPoint("LEFT", buttonBag, "LEFT", xOffset, 0)
        button:SetSize(32, 32)
        xOffset = xOffset + 34
    end
    
    -- Resize bag to fit buttons
    if #buttons > 0 then
        buttonBag:SetWidth(xOffset + 5)
    else
        buttonBag:Hide()
    end
end

-- Slash command handler
function Minimap:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        MithUI:Print("Minimap cleanup " .. (db.enabled and "enabled" or "disabled"))
        if db.enabled then
            self:ApplySettings()
            self:CollectButtons()
        else
            ReloadUI()  -- Need reload to restore hidden elements
        end
        
    elseif cmd == "zoom" then
        db.hideZoomButtons = not db.hideZoomButtons
        MithUI:Print("Zoom buttons " .. (db.hideZoomButtons and "hidden" or "shown"))
        self:ApplySettings()
        
    elseif cmd == "calendar" then
        db.hideCalendar = not db.hideCalendar
        MithUI:Print("Calendar " .. (db.hideCalendar and "hidden" or "shown"))
        self:ApplySettings()
        
    elseif cmd == "clock" then
        db.hideClock = not db.hideClock
        MithUI:Print("Clock " .. (db.hideClock and "hidden" or "shown"))
        self:ApplySettings()
        
    elseif cmd == "buttons" then
        db.collectButtons = not db.collectButtons
        MithUI:Print("Button collection " .. (db.collectButtons and "enabled" or "disabled"))
        if db.collectButtons then
            self:CollectButtons()
        end
        
    elseif cmd == "square" then
        db.squareMinimap = not db.squareMinimap
        MithUI:Print("Square minimap " .. (db.squareMinimap and "enabled" or "disabled") .. " (reload required)")
        
    else
        MithUI:Print("Minimap commands:")
        print("  |cff00ff00/mm toggle|r - Enable/disable all")
        print("  |cff00ff00/mm zoom|r - Toggle zoom buttons")
        print("  |cff00ff00/mm calendar|r - Toggle calendar")
        print("  |cff00ff00/mm clock|r - Toggle clock")
        print("  |cff00ff00/mm buttons|r - Toggle button collection")
        print("  |cff00ff00/mm square|r - Toggle square minimap")
    end
end

-- Slash command
SLASH_MITHMINIMAP1 = "/mithminimap"
SLASH_MITHMINIMAP2 = "/mm"

SlashCmdList["MITHMINIMAP"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    Minimap:SlashCommand(args)
end
