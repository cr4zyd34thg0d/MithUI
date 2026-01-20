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
}

-- URL patterns
local URL_PATTERNS = {
    "https?://[%w%.%-_/%%?=&#]+",
    "www%.[%w%.%-_/%%?=&#]+",
    "%d+%.%d+%.%d+%.%d+:%d+",
}

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
    -- Hook all chat frames
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            self:HookChatFrame(chatFrame)
        end
    end
    
    -- Hook AddMessage for URL detection and class colors
    local origAddMessage = ChatFrame1.AddMessage
    
    for i = 1, NUM_CHAT_WINDOWS do
        local chatFrame = _G["ChatFrame" .. i]
        if chatFrame then
            chatFrame.AddMessage = function(frame, text, ...)
                if text and db.enabled then
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
                return origAddMessage(frame, text, ...)
            end
        end
    end
    
    -- Class colors in chat
    if db.classColors then
        self:EnableClassColors()
    end
end

function Chat:HookChatFrame(chatFrame)
    -- Add copy button
    if db.copyChat then
        local copyBtn = CreateFrame("Button", nil, chatFrame)
        copyBtn:SetSize(20, 20)
        copyBtn:SetPoint("TOPRIGHT", chatFrame, "TOPRIGHT", 0, 0)
        copyBtn:SetAlpha(0)
        
        local copyText = copyBtn:CreateFontString(nil, "OVERLAY")
        copyText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        copyText:SetPoint("CENTER")
        copyText:SetText("C")
        copyText:SetTextColor(0.7, 0.7, 0.7)
        
        copyBtn:SetScript("OnEnter", function(self)
            self:SetAlpha(1)
            copyText:SetTextColor(0, 0.8, 1)
        end)
        
        copyBtn:SetScript("OnLeave", function(self)
            self:SetAlpha(0)
            copyText:SetTextColor(0.7, 0.7, 0.7)
        end)
        
        copyBtn:SetScript("OnClick", function()
            Chat:ShowCopyFrame(chatFrame)
        end)
        
        -- Show on chat frame hover
        chatFrame:HookScript("OnEnter", function()
            copyBtn:SetAlpha(0.5)
        end)
        chatFrame:HookScript("OnLeave", function()
            copyBtn:SetAlpha(0)
        end)
    end
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
    copyFrame:SetSize(500, 300)
    copyFrame:SetPoint("CENTER")
    copyFrame:SetFrameStrata("DIALOG")
    copyFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    copyFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    copyFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    copyFrame:SetMovable(true)
    copyFrame:EnableMouse(true)
    copyFrame:RegisterForDrag("LeftButton")
    copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
    copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
    copyFrame:Hide()
    
    -- Title
    local title = copyFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cff00ccffCopy Chat|r - Press Ctrl+C to copy")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, copyFrame)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeBtn:SetScript("OnClick", function() copyFrame:Hide() end)
    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.3, 0.3) end)
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(0.8, 0.8, 0.8) end)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, copyFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    -- Edit box
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(450)
    editBox:SetAutoFocus(true)
    editBox:SetScript("OnEscapePressed", function() copyFrame:Hide() end)
    
    scrollFrame:SetScrollChild(editBox)
    copyFrame.editBox = editBox
end

function Chat:ShowCopyFrame(chatFrame)
    local lines = {}
    local numMessages = chatFrame:GetNumMessages()
    
    for i = 1, numMessages do
        local text = chatFrame:GetMessageInfo(i)
        if text then
            -- Strip color codes for cleaner copy
            text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
            text = text:gsub("|r", "")
            text = text:gsub("|H.-|h", "")
            text = text:gsub("|h", "")
            table.insert(lines, text)
        end
    end
    
    copyFrame.editBox:SetText(table.concat(lines, "\n"))
    copyFrame.editBox:HighlightText()
    copyFrame:Show()
end

-- Handle URL clicks
local origSetHyperlink = ItemRefTooltip.SetHyperlink
ItemRefTooltip.SetHyperlink = function(self, link, ...)
    if link:match("^url:") then
        local url = link:match("^url:(.+)")
        -- Can't open URLs directly, but we can show a copy dialog
        StaticPopupDialogs["MITHUI_COPY_URL"] = {
            text = "Copy this URL:\n\n%s",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            hasEditBox = true,
            OnShow = function(self, data)
                self.editBox:SetText(data)
                self.editBox:HighlightText()
            end,
        }
        StaticPopup_Show("MITHUI_COPY_URL", url, nil, url)
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
        Chat:ShowCopyFrame(ChatFrame1)
        
    else
        MithUI:Print("Chat commands:")
        print("  |cff00ff00/chat toggle|r - Enable/disable all")
        print("  |cff00ff00/chat class|r - Toggle class colors")
        print("  |cff00ff00/chat urls|r - Toggle clickable URLs")
        print("  |cff00ff00/chat time|r - Toggle timestamps")
        print("  |cff00ff00/chat short|r - Toggle short channel names")
        print("  |cff00ff00/chat copy|r - Open copy window")
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
