-- MithUI Assist Display Module
-- Shows the highlighted "Assist" recommended ability in a larger, more visible frame
-- Compatible with WoW 12.0 (Midnight) Assist system

local addonName, MithUI = ...

local AssistDisplay = {}
MithUI:RegisterModule("assistDisplay", AssistDisplay)

local db
local isEnabled = false
local currentHighlightedButton = nil
local currentSpellID = nil

-- Main display frame
local frame = CreateFrame("Frame", "MithUIAssistDisplay", UIParent)
frame:SetSize(70, 70)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
frame:SetFrameStrata("HIGH")
frame:SetFrameLevel(50)
frame:Hide()

-- Make it moveable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
    if db and not db.locked and not InCombatLockdown() then
        self:StartMoving()
    end
end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then
        local point, _, relPoint, x, y = self:GetPoint()
        db.posX, db.posY = x, y
    end
end)

-- Background
frame.bg = frame:CreateTexture(nil, "BACKGROUND")
frame.bg:SetAllPoints()
frame.bg:SetColorTexture(0.02, 0.02, 0.02, 0.85)

-- Icon
frame.icon = frame:CreateTexture(nil, "ARTWORK")
frame.icon:SetPoint("TOPLEFT", 4, -4)
frame.icon:SetPoint("BOTTOMRIGHT", -4, 4)
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Blue glow effect
frame.glow = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
frame.glow:SetPoint("TOPLEFT", -10, 10)
frame.glow:SetPoint("BOTTOMRIGHT", 10, -10)
frame.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
frame.glow:SetBlendMode("ADD")
frame.glow:SetVertexColor(0.3, 0.6, 1, 0.8)

-- Animated glow
local glowAnim = frame.glow:CreateAnimationGroup()
glowAnim:SetLooping("BOUNCE")
local fade = glowAnim:CreateAnimation("Alpha")
fade:SetFromAlpha(0.5)
fade:SetToAlpha(1)
fade:SetDuration(0.5)

-- Border
frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
frame.border:SetAllPoints()
frame.border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2})
frame.border:SetBackdropBorderColor(0.3, 0.6, 1, 1)

-- Keybind text
frame.keybind = frame:CreateFontString(nil, "OVERLAY")
frame.keybind:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
frame.keybind:SetPoint("BOTTOM", frame, "BOTTOM", 0, 6)
frame.keybind:SetTextColor(1, 1, 1)

-- Spell name
frame.spellName = frame:CreateFontString(nil, "OVERLAY")
frame.spellName:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
frame.spellName:SetPoint("TOP", frame, "BOTTOM", 0, -2)
frame.spellName:SetWidth(120)
frame.spellName:SetTextColor(0.9, 0.9, 0.9)

-- Cooldown overlay
frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
frame.cooldown:SetPoint("TOPLEFT", frame.icon, "TOPLEFT", 0, 0)
frame.cooldown:SetPoint("BOTTOMRIGHT", frame.icon, "BOTTOMRIGHT", 0, 0)
frame.cooldown:SetDrawEdge(false)
frame.cooldown:SetDrawSwipe(true)
frame.cooldown:SetSwipeColor(0, 0, 0, 0.6)

function AssistDisplay:OnInitialize()
    MithUI.defaults.assistDisplay = {
        enabled = true,
        scale = 1.2,
        posX = 0,
        posY = -250,
        locked = true,
        showKeybind = true,
        showSpellName = true,
        glowEnabled = true,
    }
end

function AssistDisplay:OnEnable()
    db = MithUIDB.assistDisplay
    if not db then return end
    
    frame:SetScale(db.scale or 1.2)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", db.posX or 0, db.posY or -250)
    
    if db.enabled then
        self:StartWatching()
    end
end

function AssistDisplay:StartWatching()
    isEnabled = true
    
    if not self.updateFrame then
        self.updateFrame = CreateFrame("Frame")
    end
    
    self.updateFrame:SetScript("OnUpdate", function(_, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed < 0.1 then return end  -- 10 FPS check (slower = less errors)
        self.elapsed = 0
        pcall(AssistDisplay.ScanForHighlight, AssistDisplay)
    end)
    
    self.updateFrame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
    self.updateFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    self.updateFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    self.updateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    self.updateFrame:SetScript("OnEvent", function(_, event)
        if event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
            pcall(AssistDisplay.UpdateCooldown, AssistDisplay)
        else
            pcall(AssistDisplay.ScanForHighlight, AssistDisplay)
        end
    end)
end

function AssistDisplay:StopWatching()
    isEnabled = false
    if self.updateFrame then
        self.updateFrame:SetScript("OnUpdate", nil)
        self.updateFrame:UnregisterAllEvents()
    end
    frame:Hide()
    glowAnim:Stop()
end

function AssistDisplay:ScanForHighlight()
    if not isEnabled then return end
    
    local foundButton = nil
    
    -- Scan main action bar
    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            local ok, highlighted = pcall(self.IsButtonHighlighted, self, button)
            if ok and highlighted then
                foundButton = button
                break
            end
        end
    end
    
    -- Scan multi bars if not found
    if not foundButton then
        local barNames = {"MultiBarBottomLeftButton", "MultiBarBottomRightButton", 
                         "MultiBarRightButton", "MultiBarLeftButton",
                         "MultiBar5Button", "MultiBar6Button", "MultiBar7Button"}
        for _, barName in ipairs(barNames) do
            for i = 1, 12 do
                local button = _G[barName .. i]
                if button then
                    local ok, highlighted = pcall(self.IsButtonHighlighted, self, button)
                    if ok and highlighted then
                        foundButton = button
                        break
                    end
                end
            end
            if foundButton then break end
        end
    end
    
    if foundButton ~= currentHighlightedButton then
        currentHighlightedButton = foundButton
        if foundButton then
            pcall(self.ShowHighlight, self, foundButton)
        else
            self:HideHighlight()
        end
    end
end

function AssistDisplay:IsButtonHighlighted(button)
    if not button then return false end
    
    local ok, visible = pcall(function() return button:IsVisible() end)
    if not ok or not visible then return false end
    
    -- Check SpellActivationAlert (proc glow)
    if button.SpellActivationAlert then
        local ok2, shown = pcall(function() return button.SpellActivationAlert:IsShown() end)
        if ok2 and shown then return true end
    end
    
    -- Check overlay (lowercase)
    if button.overlay then
        local ok2, shown = pcall(function() return button.overlay:IsShown() end)
        if ok2 and shown then return true end
    end
    
    -- Check Overlay (capital O)
    if button.Overlay then
        local ok2, shown = pcall(function() return button.Overlay:IsShown() end)
        if ok2 and shown then return true end
    end
    
    -- Check SpellHighlightTexture
    if button.SpellHighlightTexture then
        local ok2, shown = pcall(function() return button.SpellHighlightTexture:IsShown() end)
        if ok2 and shown then return true end
    end
    
    -- Check SpellHighlightAnim
    if button.SpellHighlightAnim then
        local ok2, playing = pcall(function() return button.SpellHighlightAnim:IsPlaying() end)
        if ok2 and playing then return true end
    end
    
    -- LibActionButton compatibility
    if button.__LAB_overlay then
        local ok2, shown = pcall(function() return button.__LAB_overlay:IsShown() end)
        if ok2 and shown then return true end
    end
    
    -- Check children for overlay/glow frames (WoW 12.0 Midnight)
    local ok3, children = pcall(function() return {button:GetChildren()} end)
    if ok3 and children then
        for _, child in ipairs(children) do
            local ok4, childShown = pcall(function() return child:IsShown() end)
            if ok4 and childShown then
                local ok5, name = pcall(function() return child:GetName() or "" end)
                if ok5 and name then
                    if name:match("Overlay") or name:match("Glow") or name:match("Alert") or name:match("Highlight") then
                        return true
                    end
                end
                -- Check debug name too
                local ok6, debugName = pcall(function() return child:GetDebugName() or "" end)
                if ok6 and debugName then
                    if debugName:match("SpellActivation") or debugName:match("Assist") then
                        return true
                    end
                end
            end
        end
    end
    
    return false
end

function AssistDisplay:ShowHighlight(button)
    if not button then return end
    
    local icon, keybind, spellName
    local actionSlot
    
    -- Get action slot safely
    local ok1, slot = pcall(function()
        return button.action or button:GetAttribute("action")
    end)
    if ok1 then actionSlot = slot end
    
    -- Get action info safely
    if actionSlot then
        local ok2, actionType, id = pcall(GetActionInfo, actionSlot)
        if ok2 and actionType == "spell" and id then
            local ok3, spellInfo = pcall(C_Spell.GetSpellInfo, id)
            if ok3 and spellInfo then
                icon = spellInfo.iconID
                spellName = spellInfo.name
                currentSpellID = id
            end
        elseif ok2 and actionType == "item" and id then
            local ok3, itemName, _, _, _, _, _, _, _, itemIcon = pcall(C_Item.GetItemInfo, id)
            if ok3 then
                spellName = itemName
                icon = itemIcon
            end
            currentSpellID = nil
        elseif ok2 and actionType == "macro" and id then
            local ok3, macroSpell = pcall(GetMacroSpell, id)
            if ok3 and macroSpell then
                local ok4, spellInfo = pcall(C_Spell.GetSpellInfo, macroSpell)
                if ok4 and spellInfo then
                    icon = spellInfo.iconID
                    spellName = spellInfo.name
                    currentSpellID = spellInfo.spellID
                end
            end
            if not icon then
                local ok4, _, macroIcon = pcall(GetMacroInfo, id)
                if ok4 then
                    icon = macroIcon
                    spellName = "Macro"
                end
            end
        end
    end
    
    -- Fallback to button icon
    if not icon and button.icon then
        local ok, tex = pcall(function() return button.icon:GetTexture() end)
        if ok then icon = tex end
    end
    
    -- Get keybind safely
    local btnName = button:GetName()
    if btnName then
        local ok, bind = pcall(GetBindingKey, btnName:upper())
        if ok then keybind = bind end
        
        if not keybind then
            local btnID = button:GetID()
            if btnID then
                if btnName:match("^ActionButton") then
                    local ok2, bind2 = pcall(GetBindingKey, "ACTIONBUTTON" .. btnID)
                    if ok2 then keybind = bind2 end
                elseif btnName:match("MultiBarBottomLeft") then
                    local ok2, bind2 = pcall(GetBindingKey, "MULTIACTIONBAR1BUTTON" .. btnID)
                    if ok2 then keybind = bind2 end
                elseif btnName:match("MultiBarBottomRight") then
                    local ok2, bind2 = pcall(GetBindingKey, "MULTIACTIONBAR2BUTTON" .. btnID)
                    if ok2 then keybind = bind2 end
                elseif btnName:match("MultiBarRight") then
                    local ok2, bind2 = pcall(GetBindingKey, "MULTIACTIONBAR3BUTTON" .. btnID)
                    if ok2 then keybind = bind2 end
                elseif btnName:match("MultiBarLeft") then
                    local ok2, bind2 = pcall(GetBindingKey, "MULTIACTIONBAR4BUTTON" .. btnID)
                    if ok2 then keybind = bind2 end
                end
            end
        end
    end
    
    -- Format keybind
    if keybind then
        keybind = keybind:gsub("SHIFT%-", "S-")
        keybind = keybind:gsub("CTRL%-", "C-")
        keybind = keybind:gsub("ALT%-", "A-")
        keybind = keybind:gsub("NUMPAD", "N")
    else
        keybind = ""
    end
    
    -- Update display
    frame.icon:SetTexture(icon or 134400)
    frame.keybind:SetText(keybind)
    frame.keybind:SetShown(db.showKeybind and keybind ~= "")
    frame.spellName:SetText(spellName or "")
    frame.spellName:SetShown(db.showSpellName and spellName)
    
    pcall(self.UpdateCooldown, self)
    
    if db.glowEnabled then
        glowAnim:Play()
        frame.glow:Show()
    else
        frame.glow:Hide()
    end
    
    frame:Show()
end

function AssistDisplay:HideHighlight()
    frame:Hide()
    glowAnim:Stop()
    currentHighlightedButton = nil
    currentSpellID = nil
end

function AssistDisplay:UpdateCooldown()
    if not currentHighlightedButton or not frame:IsShown() then return end
    
    local start, duration
    
    if currentSpellID then
        local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, currentSpellID)
        if ok and cdInfo then
            start, duration = cdInfo.startTime, cdInfo.duration
        end
    elseif currentHighlightedButton.action then
        local ok, s, d = pcall(GetActionCooldown, currentHighlightedButton.action)
        if ok then
            start, duration = s, d
        end
    end
    
    if start and duration and duration > 0 then
        frame.cooldown:SetCooldown(start, duration)
    else
        frame.cooldown:Clear()
    end
end

-- Slash commands
SLASH_MITHASSIST1 = "/ma"
SLASH_MITHASSIST2 = "/assist"

SlashCmdList["MITHASSIST"] = function(msg)
    if not db then return end
    
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word:lower()) end
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        if db.enabled then
            AssistDisplay:StartWatching()
            MithUI:Print("Assist display enabled")
        else
            AssistDisplay:StopWatching()
            MithUI:Print("Assist display disabled")
        end
    elseif cmd == "lock" then
        db.locked = not db.locked
        MithUI:Print("Assist display " .. (db.locked and "locked" or "unlocked - drag to move"))
    elseif cmd == "scale" then
        local s = tonumber(args[2])
        if s and s > 0 then
            db.scale = s
            frame:SetScale(s)
            MithUI:Print("Scale set to " .. s)
        end
    elseif cmd == "keybind" then
        db.showKeybind = not db.showKeybind
        MithUI:Print("Keybind display " .. (db.showKeybind and "shown" or "hidden"))
    elseif cmd == "name" then
        db.showSpellName = not db.showSpellName
        MithUI:Print("Spell name " .. (db.showSpellName and "shown" or "hidden"))
    elseif cmd == "glow" then
        db.glowEnabled = not db.glowEnabled
        MithUI:Print("Glow effect " .. (db.glowEnabled and "enabled" or "disabled"))
        if not db.glowEnabled then
            glowAnim:Stop()
            frame.glow:Hide()
        end
    elseif cmd == "test" then
        isEnabled = false
        if AssistDisplay.updateFrame then
            AssistDisplay.updateFrame:SetScript("OnUpdate", nil)
        end
        frame.icon:SetTexture(136048)
        frame.keybind:SetText("S-2")
        frame.spellName:SetText("Test Ability")
        frame.glow:Show()
        glowAnim:Play()
        frame:Show()
        MithUI:Print("Test display shown. Use /ma toggle to resume.")
    elseif cmd == "hide" then
        frame:Hide()
        MithUI:Print("Display hidden")
    elseif cmd == "reset" then
        db.posX, db.posY = 0, -250
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -250)
        MithUI:Print("Position reset")
    else
        MithUI:Print("Assist Display: /ma toggle|lock|scale N|keybind|name|glow|test|hide|reset")
    end
end
