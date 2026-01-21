-- MithUI Cast Bar Module
-- Clean minimal cast bar inspired by Luxthos style

local addonName, MithUI = ...

local CastBar = {}
MithUI:RegisterModule("castBar", CastBar)

-- Local references
local db
local casting, channeling = false, false
local startTime, endTime = 0, 0
local previewMode = false
local previewTimer = nil

-- Create main frame
local frame = CreateFrame("Frame", "MithUICastBar", UIParent)
frame:Hide()

function CastBar:OnInitialize()
    -- Will be called when module is registered
end

function CastBar:OnEnable()
    db = MithUIDB.castBar
    self:CreateFrames()
    self:RegisterEvents()
    self:HideBlizzardCastBar()
end

function CastBar:HideBlizzardCastBar()
    -- Hide the default player cast bar
    if PlayerCastingBarFrame then
        PlayerCastingBarFrame:UnregisterAllEvents()
        PlayerCastingBarFrame:Hide()
        PlayerCastingBarFrame:SetScript("OnShow", function(self) self:Hide() end)
    end
    
    -- Also hide the older CastingBarFrame if it exists
    if CastingBarFrame then
        CastingBarFrame:UnregisterAllEvents()
        CastingBarFrame:Hide()
    end
end

function CastBar:OnEnterWorld()
    db = MithUIDB.castBar
    if db.posX and db.posY then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
    end
end

function CastBar:CreateFrames()
    -- Size and scale
    frame:SetSize(db.width, db.height)
    frame:SetScale(db.scale or 1.0)
    frame:SetPoint("CENTER", UIParent, "CENTER", db.posX, db.posY)
    
    -- Background (dark, subtle)
    if not frame.bg then
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    end
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0, 0, 0, 0.7)
    
    -- Status bar (no border frame needed)
    if not frame.bar then
        frame.bar = CreateFrame("StatusBar", nil, frame)
    end
    frame.bar:SetAllPoints()
    frame.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    frame.bar:SetStatusBarColor(unpack(db.barColor))
    frame.bar:SetMinMaxValues(0, 1)
    frame.bar:SetValue(0)
    
    -- Spark (subtle glow at progress point)
    if not frame.spark then
        frame.spark = frame.bar:CreateTexture(nil, "OVERLAY")
    end
    frame.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    frame.spark:SetSize(16, db.height + 6)
    frame.spark:SetBlendMode("ADD")
    frame.spark:SetPoint("CENTER", frame.bar:GetStatusBarTexture(), "RIGHT", 0, 0)
    
    -- Icon (clean, no border)
    if db.showIcon then
        if not frame.icon then
            frame.icon = frame:CreateTexture(nil, "ARTWORK")
        end
        frame.icon:SetSize(db.height, db.height)  -- Square, match bar height
        frame.icon:SetPoint("RIGHT", frame, "LEFT", -4, 0)
        frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        frame.icon:Show()
        
        -- Remove icon border if it exists
        if frame.iconBorder then
            frame.iconBorder:Hide()
        end
    else
        if frame.icon then frame.icon:Hide() end
        if frame.iconBorder then frame.iconBorder:Hide() end
    end
    
    -- Remove old border frame if it exists
    if frame.border then
        frame.border:Hide()
    end
    
    -- Spell name
    if not frame.spellText then
        frame.spellText = frame.bar:CreateFontString(nil, "OVERLAY")
    end
    frame.spellText:SetFont("Fonts\\FRIZQT__.TTF", db.fontSize, "OUTLINE")
    frame.spellText:SetPoint("LEFT", frame.bar, "LEFT", 6, 0)
    frame.spellText:SetJustifyH("LEFT")
    frame.spellText:SetTextColor(1, 1, 1)
    if db.showSpellName then
        frame.spellText:Show()
    else
        frame.spellText:Hide()
    end
    
    -- Timer
    if not frame.timerText then
        frame.timerText = frame.bar:CreateFontString(nil, "OVERLAY")
    end
    frame.timerText:SetFont("Fonts\\FRIZQT__.TTF", db.fontSize, "OUTLINE")
    frame.timerText:SetPoint("RIGHT", frame.bar, "RIGHT", -6, 0)
    frame.timerText:SetJustifyH("RIGHT")
    frame.timerText:SetTextColor(1, 1, 1)
    if db.showTimer then
        frame.timerText:Show()
    else
        frame.timerText:Hide()
    end
    
    -- Make movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    frame:SetScript("OnDragStart", function(self)
        if not db.locked then
            self:StartMoving()
        end
    end)
    
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        db.posX = x
        db.posY = y
    end)
    
    -- Update script
    frame:SetScript("OnUpdate", function(self, elapsed)
        CastBar:OnUpdate(elapsed)
    end)
end

function CastBar:OnUpdate(elapsed)
    local currentTime = GetTime()
    
    if casting then
        local progress = (currentTime - startTime) / (endTime - startTime)
        if progress >= 1 then
            frame:Hide()
            casting = false
            return
        end
        frame.bar:SetValue(progress)
        frame.timerText:SetFormattedText("%.1f", endTime - currentTime)
        
    elseif channeling then
        local progress = (endTime - currentTime) / (endTime - startTime)
        if progress <= 0 then
            frame:Hide()
            channeling = false
            return
        end
        frame.bar:SetValue(progress)
        frame.timerText:SetFormattedText("%.1f", endTime - currentTime)
    end
end

function CastBar:StartCast(unit)
    local name, text, texture, sTime, eTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    if not name then return end
    
    startTime = sTime / 1000
    endTime = eTime / 1000
    casting = true
    channeling = false
    
    frame.spellText:SetText(name)
    if frame.icon then frame.icon:SetTexture(texture) end
    frame.bar:SetValue(0)
    
    if notInterruptible then
        frame.bar:SetStatusBarColor(unpack(db.interruptColor))
    else
        frame.bar:SetStatusBarColor(unpack(db.barColor))
    end
    
    frame:Show()
end

function CastBar:StartChannel(unit)
    local name, text, texture, sTime, eTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
    if not name then return end
    
    startTime = sTime / 1000
    endTime = eTime / 1000
    casting = false
    channeling = true
    
    frame.spellText:SetText(name)
    if frame.icon then frame.icon:SetTexture(texture) end
    frame.bar:SetValue(1)
    
    if notInterruptible then
        frame.bar:SetStatusBarColor(unpack(db.interruptColor))
    else
        frame.bar:SetStatusBarColor(unpack(db.channelColor))
    end
    
    frame:Show()
end

function CastBar:StopCast()
    casting = false
    channeling = false
    frame:Hide()
end

function CastBar:RegisterEvents()
    local events = CreateFrame("Frame")
    events:RegisterEvent("UNIT_SPELLCAST_START")
    events:RegisterEvent("UNIT_SPELLCAST_STOP")
    events:RegisterEvent("UNIT_SPELLCAST_FAILED")
    events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    
    events:SetScript("OnEvent", function(self, event, unit, ...)
        if unit ~= "player" then return end
        
        if event == "UNIT_SPELLCAST_START" then
            CastBar:StartCast(unit)
        elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
            CastBar:StartChannel(unit)
        else
            CastBar:StopCast()
        end
    end)
end

function CastBar:Refresh()
    db = MithUIDB.castBar
    self:CreateFrames()
end

-- Slash command handler
function CastBar:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "lock" then
        db.locked = true
        previewMode = false
        if previewTimer then previewTimer:Cancel() end
        frame:Hide()
        MithUI:Print("Cast bar locked")
        
    elseif cmd == "unlock" then
        db.locked = false
        MithUI:Print("Cast bar unlocked - drag to move")
        frame.spellText:SetText("Drag to move")
        frame.timerText:SetText("")
        frame.bar:SetValue(0.5)
        frame:Show()
        C_Timer.After(5, function()
            if not casting and not channeling and not previewMode then frame:Hide() end
        end)
        
    elseif cmd == "preview" then
        previewMode = not previewMode
        if previewMode then
            db.locked = false
            frame.spellText:SetText("Preview Mode")
            frame.timerText:SetText("2.5")
            if frame.icon then frame.icon:SetTexture(136243) end
            frame.bar:SetValue(0.6)
            frame.bar:SetStatusBarColor(unpack(db.barColor))
            frame:Show()
            MithUI:Print("Preview ON - Drag to position, use /mc scale [num] to resize")
        else
            db.locked = true
            frame:Hide()
            MithUI:Print("Preview OFF - Position saved")
        end
        
    elseif cmd == "test" then
        frame.spellText:SetText("Test Spell")
        frame.timerText:SetText("2.5")
        if frame.icon then frame.icon:SetTexture(136243) end
        frame.bar:SetValue(0.4)
        frame.bar:SetStatusBarColor(unpack(db.barColor))
        frame:Show()
        MithUI:Print("Showing test bar (5 sec)")
        C_Timer.After(5, function()
            if not casting and not channeling and not previewMode then frame:Hide() end
        end)
        
    elseif cmd == "reset" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        db.posX = 0
        db.posY = -200
        db.scale = 1.0
        frame:SetScale(1.0)
        MithUI:Print("Position and scale reset")
        
    elseif cmd == "scale" then
        local scale = tonumber(args[2])
        if scale and scale >= 0.5 and scale <= 3.0 then
            db.scale = scale
            frame:SetScale(scale)
            MithUI:Print("Scale: " .. scale)
        else
            MithUI:Print("Usage: /mc scale [0.5-3.0] (current: " .. (db.scale or 1.0) .. ")")
        end
        
    elseif cmd == "size" then
        local w = tonumber(args[2])
        local h = tonumber(args[3])
        if w then db.width = w end
        if h then db.height = h end
        self:Refresh()
        MithUI:Print("Size: " .. db.width .. "x" .. db.height)
        
    elseif cmd == "color" then
        local hex = args[2]
        if hex then
            local r, g, b = MithUI:ParseColor(hex)
            db.barColor = {r, g, b, 1}
            self:Refresh()
            MithUI:Print("Bar color updated")
        else
            MithUI:Print("Usage: /mc color ff6600")
        end
        
    elseif cmd == "icon" then
        db.showIcon = not db.showIcon
        self:Refresh()
        MithUI:Print("Icon: " .. (db.showIcon and "shown" or "hidden"))
        
    elseif cmd == "timer" then
        db.showTimer = not db.showTimer
        self:Refresh()
        MithUI:Print("Timer: " .. (db.showTimer and "shown" or "hidden"))
        
    else
        MithUI:Print("Cast Bar commands:")
        print("  |cff00ff00/mc preview|r - Toggle preview mode (drag & scale)")
        print("  |cff00ff00/mc lock|r - Lock position")
        print("  |cff00ff00/mc unlock|r - Unlock to move")
        print("  |cff00ff00/mc scale [0.5-3]|r - Set scale (e.g. /mc scale 1.2)")
        print("  |cff00ff00/mc test|r - Show test bar")
        print("  |cff00ff00/mc reset|r - Reset position & scale")
        print("  |cff00ff00/mc size [w] [h]|r - Set size (e.g. /mc size 300 28)")
        print("  |cff00ff00/mc color [hex]|r - Set color (e.g. /mc color ff6600)")
        print("  |cff00ff00/mc icon|r - Toggle icon")
        print("  |cff00ff00/mc timer|r - Toggle timer")
    end
end

-- Shortcut slash command
SLASH_MITHCAST1 = "/mithcast"
SLASH_MITHCAST2 = "/mc"

SlashCmdList["MITHCAST"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    CastBar:SlashCommand(args)
end
