-- MithUI Core
-- Main addon framework

local addonName, MithUI = ...

-- Version
MithUI.version = "1.4.0"

-- Default settings structure
MithUI.defaults = {
    castBar = {
        enabled = true,
        width = 280,
        height = 24,
        iconSize = 28,
        posX = 0,
        posY = -200,
        showIcon = true,
        showTimer = true,
        showSpellName = true,
        barColor = {0.4, 0.6, 1.0, 1.0},
        channelColor = {0.3, 0.8, 0.3, 1.0},
        interruptColor = {0.8, 0.3, 0.3, 1.0},
        bgColor = {0.1, 0.1, 0.1, 0.8},
        borderColor = {0.2, 0.2, 0.2, 1.0},
        fontSize = 12,
        locked = true,
    },
    radialMenu = {
        enabled = true,
        scale = 1.0,
        ringRadius = 100,
        buttonSize = 40,
        fadeTime = 0.2,
        keybind = "ALT-G",
    },
}

-- Module registry
MithUI.modules = {}

-- Register a module
function MithUI:RegisterModule(name, module)
    self.modules[name] = module
    if module.OnInitialize then
        module:OnInitialize()
    end
end

-- Get module
function MithUI:GetModule(name)
    return self.modules[name]
end

-- Deep copy table
function MithUI:CopyTable(src, dest)
    dest = dest or {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            dest[k] = self:CopyTable(v, dest[k])
        elseif dest[k] == nil then
            dest[k] = v
        end
    end
    return dest
end

-- Color helper - parse hex or return table
function MithUI:ParseColor(input)
    if type(input) == "table" then
        return unpack(input)
    elseif type(input) == "string" then
        -- Parse hex color like "ff0000" or "#ff0000"
        local hex = input:gsub("#", "")
        local r = tonumber(hex:sub(1,2), 16) / 255
        local g = tonumber(hex:sub(3,4), 16) / 255
        local b = tonumber(hex:sub(5,6), 16) / 255
        return r, g, b, 1
    end
    return 1, 1, 1, 1
end

-- Print helper
function MithUI:Print(msg)
    print("|cff00ccffMithUI|r: " .. msg)
end

-- Event frame
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")

events:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            -- Initialize saved variables
            MithUIDB = MithUIDB or {}
            MithUI:CopyTable(MithUI.defaults, MithUIDB)
            
            MithUI:Print("v" .. MithUI.version .. " loaded! Type |cff00ff00/mith|r for help.")
        end
        
    elseif event == "PLAYER_LOGIN" then
        -- Initialize all modules
        for name, module in pairs(MithUI.modules) do
            if module.OnEnable and MithUIDB[name] and MithUIDB[name].enabled then
                module:OnEnable()
            end
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Apply saved positions
        for name, module in pairs(MithUI.modules) do
            if module.OnEnterWorld then
                module:OnEnterWorld()
            end
        end
    end
end)

-- Main slash command
SLASH_MITHUI1 = "/mith"
SLASH_MITHUI2 = "/mithui"

SlashCmdList["MITHUI"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word:lower())
    end
    
    local cmd = args[1] or "help"
    
    if cmd == "cast" or cmd == "castbar" or cmd == "cb" then
        -- Forward to castbar module
        local castBar = MithUI:GetModule("castBar")
        if castBar and castBar.SlashCommand then
            table.remove(args, 1)
            castBar:SlashCommand(args)
        end
        
    elseif cmd == "pie" or cmd == "radial" or cmd == "rm" then
        -- Forward to radial menu module
        local radial = MithUI:GetModule("radialMenu")
        if radial and radial.SlashCommand then
            table.remove(args, 1)
            radial:SlashCommand(args)
        end
        
    else
        MithUI:Print("Commands:")
        print("  |cff00ff00/mu|r - Open settings GUI")
        print("  |cff00ff00/mc|r - Cast bar options")
        print("  |cff00ff00/mp|r - Radial menu options")
        print("  |cff00ff00/av|r - Auto vendor options")
        print("  |cff00ff00/tt|r - Tooltip options")
        print("  |cff00ff00/chat|r - Chat options")
        print("  |cff00ff00/mm|r - Minimap options")
        print("  |cff00ff00/ct|r - Combat text options")
        print("  |cff00ff00/np|r - Nameplate options")
    end
end

-- Export to global
_G.MithUI = MithUI
