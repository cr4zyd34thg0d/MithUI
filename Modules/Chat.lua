-- MithUI Chat Enhancements Module
-- Copy chat, clickable URLs, class colors, timestamps

local addonName, MithUI = ...

local Chat = {}
MithUI:RegisterModule("chat", Chat)

local db

-- Default settings
local defaults = {
    enabled = true,
    classColors = true,
    clickableURLs = true,
    copyChat = true,
    timestamps = false,
    timestampFormat = "%H:%M",
    shortenChannels = true,
    fadeTime = 120,
    maxHistory = 500,
}

-- URL patterns
local URL_PATTERNS = {
    "https?://[%w%.%-_/%%?=&#]+",
    "www%.[%w%.%-_/%%?=&#]+",
    "%d+%.%d+%.%d+%.%d+:%d+",
}

-- Message history for copy feature
local messageHistory = {}

-- Class colors
local CLASS_COLORS = RAID_CLASS_COLORS

function Chat:OnInitialize()
    MithUI.defaults.chat = defaults
end

function Chat:OnEnable()
    db = MithUIDB.chat
    self:SetupChatFrames()
    self:SetupCopyFrame()
end

function Chat:SetupChatFrames()
    -- Hook AddMessage for URL detection, class colors, and history capture
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame and not chatFrame.MithUIHooked then
            local origAddMessage = chatFrame.AddMessage
            
            chatFrame.AddMessage = function(frame, text, r, g, b, ...)
                if text and db and db.enabled then
                    -- Store original for history (strip colors for clean copy)
                    local cleanText = text
                    cleanText = cleanText:gsub("|c%x%x%x%x%x%x%x%x", "")
                    cleanText = cleanText:gsub("|r", "")
                    cleanText = cleanText:gsub("|H.-|h", "")
                    cleanText = cleanText:gsub("|h", "")
                    cleanText = cleanText:gsub("|T.-|t", "")  -- Remove textures
                    
                    -- Add to history
                    table.insert(messageHistory, {
                        text = cleanText,
                        time = date("%H:%M:%S"),
                        frame = i,
                    })
                    
                    -- Trim history
                    while #messageHistory > (db.maxHistory or 500) do
                        table.remove(messageHistory, 1)
                    end
                    
                    -- Add timestamps
                    if db.timestamps then
                        local timestamp = date(db.timestampFormat)
                        text = "|cff888888[" .. timestamp .. "]|r " .. text
                    end
                    
                    -- Make URLs clickable
                    if db.clickableURLs then
                        text = Chat:MakeURLsClickable(text)
                    end
                    
                    -- Shorten channel names
                    if db.shortenChannels then
                        text = Chat:ShortenChannels(text)
                    end
                end
                return origAddMessage(frame, text, r, g, b, ...)
            end
            
            chatFrame.MithUIHooked = true
            
            -- Add copy button to each chat frame
            if db and db.copyChat then
                self:AddCopyButton(chatFrame, i)
            end
        end
    end
    
    -- Class colors in chat
    if db and db.classColors then
        self:EnableClassColors()
    end
end

function Chat:AddCopyButton(chatFrame, frameIndex)
    local copyBtn = CreateFrame("Button", "MithUIChatCopyBtn"..frameIndex, chatFrame)
    copyBtn:SetSize(24, 24)
    copyBtn:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", -2, -2)
    copyBtn:SetAlpha(0.3)
    
    -- Background
    copyBtn.bg = copyBtn:CreateTexture(nil, "BACKGROUND")
    copyBtn.bg:SetAllPoints()
    copyBtn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.7)
    
    local copyText = copyBtn:CreateFontString(nil, "OVERLAY")
    copyText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    copyText:SetPoint("CENTER")
    copyText:SetText("📋")  -- Copy icon
    copyText:SetTextColor(0.8, 0.8, 0.8)
    
    copyBtn:SetScript("OnEnter", function(self)
        self:SetAlpha(1)
        copyText:SetTextColor(0, 0.8, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Click to copy chat")
        GameTooltip:AddLine("Left-click: Copy all", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("Right-click: Copy last 50", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    
    copyBtn:SetScript("OnLeave", function(self)
        self:SetAlpha(0.3)
        copyText:SetTextColor(0.8, 0.8, 0.8)
        GameTooltip:Hide()
    end)
    
    copyBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    copyBtn:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            Chat:ShowCopyFrame(50)
        else
            Chat:ShowCopyFrame()
        end
    end)
end

function Chat:MakeURLsClickable(text)
    for _, pattern in ipairs(URL_PATTERNS) do
        text = text:gsub(pattern, function(url)
            return "|cff00ccff|Hurl:" .. url .. "|h[" .. url .. "]|h|r"
        end)
    end
    return text
end

function Chat:ShortenChannels(text)
    local replacements = {
        ["%[Guild%]"] = "|cff40ff40[G]|r",
        ["%[Party%]"] = "|cffaaaaff[P]|r",
        ["%[Party Leader%]"] = "|cffaaaaff[PL]|r",
        ["%[Raid%]"] = "|cffff7f00[R]|r",
        ["%[Raid Leader%]"] = "|cffff7f00[RL]|r",
        ["%[Raid Warning%]"] = "|cffff0000[RW]|r",
        ["%[Instance%]"] = "|cffffbb00[I]|r",
        ["%[Instance Leader%]"] = "|cffffbb00[IL]|r",
        ["%[Officer%]"] = "|cff40c040[O]|r",
        ["%[Whisper%]"] = "|cffff80ff[W]|r",
        ["%[Say%]"] = "|cffffffff[S]|r",
        ["%[Yell%]"] = "|cffff4040[Y]|r",
    }
    
    for pattern, replacement in pairs(replacements) do
        text = text:gsub(pattern, replacement)
    end
    
    -- Shorten numbered channels like [1. General]
    text = text:gsub("%[(%d+)%. [^%]]+%]", "|cffffcc80[%1]|r")
    
    return text
end

function Chat:EnableClassColors()
    -- Color player names by class in chat
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame:SetScript("OnHyperlinkEnter", function(self, link, text)
                local linkType, data = link:match("^(%a+):(.+)")
                if linkType == "player" then
                    local name = data:match("([^:]+)")
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:SetText(name)
                    GameTooltip:Show()
                end
            end)
            
            chatFrame:SetScript("OnHyperlinkLeave", function()
                GameTooltip:Hide()
            end)
        end
    end
end

-- Copy frame
local copyFrame

function Chat:SetupCopyFrame()
    copyFrame = CreateFrame("Frame", "MithUIChatCopyFrame", UIParent, "BackdropTemplate")
    copyFrame:SetSize(550, 350)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetFrameStrata("DIALOG")
    copyFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    copyFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
    copyFrame:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
    copyFrame:SetMovable(true)
    copyFrame:EnableMouse(true)
    copyFrame:RegisterForDrag("LeftButton")
    copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
    copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
    copyFrame:Hide()
    
    -- Title bar
    local titleBar = CreateFrame("Frame", nil, copyFrame)
    titleBar:SetHeight(28)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints()
    titleBg:SetColorTexture(0.15, 0.15, 0.15, 1)
    
    -- Title
    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetPoint("LEFT", 10, 0)
    title:SetText("|cff00ccffMithUI Chat Copy|r")
    
    -- Instructions
    local instructions = titleBar:CreateFontString(nil, "OVERLAY")
    instructions:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    instructions:SetPoint("CENTER", 0, 0)
    instructions:SetText("|cff888888Ctrl+A to select all, Ctrl+C to copy|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", -4, 0)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("×")
    closeText:SetTextColor(0.8, 0.8, 0.8)
    closeBtn:SetScript("OnClick", function() copyFrame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(0.8, 0.8, 0.8) end)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "MithUIChatCopyScroll", copyFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    -- Edit box
    local editBox = CreateFrame("EditBox", "MithUIChatCopyEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    editBox:SetWidth(500)
    editBox:SetAutoFocus(true)
    editBox:SetTextColor(0.9, 0.9, 0.9)
    editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
    editBox:EnableMouse(true)
    editBox:SetHyperlinksEnabled(false)
    
    scrollFrame:SetScrollChild(editBox)
    copyFrame.editBox = editBox
    copyFrame.scrollFrame = scrollFrame
    
    -- ESC to close
    copyFrame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)
    copyFrame:EnableKeyboard(true)
    copyFrame:SetPropagateKeyboardInput(true)
end

function Chat:ShowCopyFrame(limit)
    local lines = {}
    local count = 0
    local maxLines = limit or #messageHistory
    
    -- Get messages from history (newest first, then reverse)
    local startIdx = math.max(1, #messageHistory - maxLines + 1)
    for i = startIdx, #messageHistory do
        local msg = messageHistory[i]
        if msg and msg.text then
            table.insert(lines, "[" .. msg.time .. "] " .. msg.text)
        end
    end
    
    if #lines == 0 then
        table.insert(lines, "No chat history captured yet.")
        table.insert(lines, "Chat will be captured as new messages arrive.")
    end
    
    local text = table.concat(lines, "\n")
    copyFrame.editBox:SetText(text)
    
    -- Scroll to bottom and select all
    C_Timer.After(0.05, function()
        copyFrame.editBox:SetCursorPosition(0)
        copyFrame.editBox:HighlightText()
    end)
    
    copyFrame:Show()
end

-- Handle URL clicks
local origSetHyperlink = ItemRefTooltip.SetHyperlink
ItemRefTooltip.SetHyperlink = function(self, link, ...)
    if link and link:match("^url:") then
        local url = link:match("^url:(.+)")
        -- Show a copy dialog for the URL
        StaticPopupDialogs["MITHUI_COPY_URL"] = {
            text = "Copy this URL:",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            hasEditBox = true,
            editBoxWidth = 350,
            OnShow = function(self, data)
                self.editBox:SetText(data)
                self.editBox:HighlightText()
                self.editBox:SetFocus()
            end,
            EditBoxOnEscapePressed = function(self)
                self:GetParent():Hide()
            end,
        }
        StaticPopup_Show("MITHUI_COPY_URL", nil, nil, url)
        return
    end
    return origSetHyperlink(self, link, ...)
end

-- Slash command handler
function Chat:SlashCommand(args)
    local cmd = args[1] or "help"
    
    if cmd == "toggle" then
        db.enabled = not db.enabled
        MithUI:Print("Chat enhancements " .. (db.enabled and "enabled" or "disabled"))
        
    elseif cmd == "class" then
        db.classColors = not db.classColors
        MithUI:Print("Class colors " .. (db.classColors and "enabled" or "disabled"))
        
    elseif cmd == "urls" then
        db.clickableURLs = not db.clickableURLs
        MithUI:Print("Clickable URLs " .. (db.clickableURLs and "enabled" or "disabled"))
        
    elseif cmd == "time" then
        db.timestamps = not db.timestamps
        MithUI:Print("Timestamps " .. (db.timestamps and "enabled" or "disabled"))
        
    elseif cmd == "short" then
        db.shortenChannels = not db.shortenChannels
        MithUI:Print("Short channels " .. (db.shortenChannels and "enabled" or "disabled"))
        
    elseif cmd == "copy" then
        Chat:ShowCopyFrame()
        
    elseif cmd == "clear" then
        messageHistory = {}
        MithUI:Print("Chat history cleared")
        
    else
        MithUI:Print("Chat commands:")
        print("  |cff00ff00/chat toggle|r - Enable/disable all")
        print("  |cff00ff00/chat class|r - Toggle class colors")
        print("  |cff00ff00/chat urls|r - Toggle clickable URLs")
        print("  |cff00ff00/chat time|r - Toggle timestamps")
        print("  |cff00ff00/chat short|r - Toggle short channel names")
        print("  |cff00ff00/chat copy|r - Open copy window")
        print("  |cff00ff00/chat clear|r - Clear history")
    end
end

-- Slash command
SLASH_MITHCHAT1 = "/mithchat"
SLASH_MITHCHAT2 = "/chat"

SlashCmdList["MITHCHAT"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    Chat:SlashCommand(args)
end
