# World of Warcraft 12.0 (Midnight) AddOn API Reference Guide

## UI & Quality-of-Life Development Focus

**Last Updated:** January 2026 | Patch 12.0.0/12.0.1

---

# CRITICAL: The "Addon Apocalypse"

Patch 12.0 (Midnight) introduces the most significant addon API changes in WoW history. Blizzard has implemented a **"Secret Values"** system that fundamentally changes how addons interact with combat data.

**Key Impact:** Combat information is now wrapped in "secret values" that addons can **display** but cannot programmatically **read or process**. This affects all combat-related functionality while preserving cosmetic/UI customization capabilities.

---

# Secret Values System

Secret values are a new mechanism that restricts addon operations on combat data. Think of combat events as being in a "black box" - addons can change the size, shape, or color of the box, but cannot look inside.

## What Addons CAN Do

- Display secret values via approved widget APIs (`StatusBar:SetValue`, `FontString:SetText`)
- Store secret values in variables or table fields
- Pass secret values to other functions
- Customize UI appearance (size, position, colors, textures)
- Track non-secret data (secondary resources like Holy Power, Runes are declassified)

## What Addons CANNOT Do (Tainted Code)

- Concatenate secret values
- Perform arithmetic on secret values
- Compare or perform boolean tests on secret values
- Use length operator (`#`) on secret values
- Store secret values as table keys
- Perform indexed access on secret values (`secret["foo"] = 1`)
- Call secret values as functions

**Violation Result:** Attempting forbidden operations causes an immediate Lua error.

## Secret Value Testing APIs

| Function | Returns | Description |
|----------|---------|-------------|
| `issecretvalue(value)` | boolean | Returns true if the supplied value is secret |
| `canaccesssecrets()` | boolean | Returns false if calling function cannot access secrets (tainted) |
| `canaccessvalue(value)` | boolean | True if value is not secret OR if caller can access secrets |
| `issecrettable(table)` | boolean | Returns true if table has been marked as secret |
| `canaccesstable(table)` | boolean | True if table is accessible (not secret or caller permitted) |

## Table Secret Behavior

- Untainted code CAN store secret values as table keys, but doing so irrevocably marks the table as secret
- A table in secret state always returns secret values when accessed by untainted code
- Tainted code CANNOT access tables in secret state (any operation will error)

---

# Duration Objects (New in 12.0)

Duration objects are a new construct that allow addons to perform calculations on potentially secret timing data and return results back to Lua. They replace many direct time-value APIs.

## Creating Duration Objects

```lua
local duration = C_DurationUtil.CreateDuration()
```

Creates an empty (zero) duration object.

## Setting Duration Values

| Method | Parameters | Notes |
|--------|------------|-------|
| `:SetTimeSpan()` | start, end | Set explicit time range |
| `:SetTimeFromStart()` | startTime, duration [, modRate] | Set duration from start time |
| `:SetTimeFromEnd()` | endTime, duration [, modRate] | Set duration from end time |

**Note:** These APIs do NOT accept secret values from tainted callers.

## Duration Object Methods

| Method | Description |
|--------|-------------|
| `GetElapsedDuration()` | Get elapsed time (may return secret) |
| `GetRemainingDuration()` | Get remaining time (may return secret) |
| `EvaluateElapsedProgress()` | Get progress as 0-1 value |

## Using Duration Objects with Widgets

### StatusBar

```lua
StatusBar:SetTimerDuration(duration [, interpolation [, direction]])
```

Configures a status bar to render from a duration object. The `direction` parameter (new) allows calculating fill from remaining duration for channeled spells.

### Cooldown

```lua
Cooldown:SetCooldownFromDurationObject(duration [, clearIfZero])
```

Configures a cooldown frame from a duration object.

---

# UnitHealPredictionCalculator (New in 12.0)

A new Lua object for calculating heal prediction and absorb data for unit frames.

```lua
local calculator = CreateUnitHealPredictionCalculator()
UnitGetDetailedHealPrediction(unit, unitDoingTheHealing, calculator)
```

The calculator object provides options for damage absorb clamping:
- Clamp to missing health
- Clamp to missing health after incoming healing
- Clamp to maximum health

---

# Color Curve APIs (New in 12.0)

New APIs allow addons to control health bar colors using color curves, and convert secret boolean values to colors.

| API | Purpose |
|-----|---------|
| `C_CurveUtil.EvaluateColorFromBoolean()` | Convert secret boolean to color |
| `C_CurveUtil.EvaluateColorValueFromBoolean()` | Convert secret boolean to color value |
| Health bar color curves | Specify colors at percentage thresholds |

---

# Conditional Secret Behavior

Not all values are always secret. Some APIs return secrets conditionally:

| API | Secret Behavior |
|-----|-----------------|
| `UnitHealth(unit)` | Returns secret values in combat |
| `UnitName(unit)` | Secret for non-player/pet units in combat |
| `UnitClass(unit)` | First return value conditionally secret |
| Creature names/GUIDs | Secret while in an instance (not just combat) |

## API Documentation Markers

| Marker | Meaning |
|--------|---------|
| `SecretReturns = true` | Function unconditionally returns secrets |
| `SecretWhenUnitIdentityRestricted = true` | Secret for non-player units in combat |
| `ConditionalSecret = true` | Return value may be secret |
| `SecretArguments = "AllowedWhenUntainted"` | Accepts secrets only from untainted code |
| `SecretArguments = "AllowedWhenTainted"` | Always accepts secrets |
| `SecretArguments = "NotAllowed"` | Never accepts secrets |

---

# Whitelisted (Non-Secret) Spells

Blizzard maintains a whitelist of spells exempt from cooldown/aura secrecy:

- All secondary class resources (Holy Power, Runes, Stagger, etc.)
- Skyriding spells
- The GCD spell
- Maelstrom Weapon
- Devourer (Demon Hunter) resource spells
- Combat Resurrection spells
- Personal spell casts (but NOT cooldowns)

*The whitelist is actively being expanded based on community feedback.*

## Cast Bar Improvements

New cast bar functionality includes:
- New cast bar spell sequence ID (non-secret, increments per cast)
- Available via spellcast events, `UnitCastingInfo`, `UnitChannelInfo`
- Enemy empowered cast data (stages, stage percentages) no longer secret

---

# UI Development in 12.0

UI customization remains largely unaffected. The secret values system targets combat logic, not appearance.

## Still Fully Functional

- Frame positioning and sizing
- Texture and color customization
- StatusBar appearance (can still `SetValue` with secrets)
- FontString display (can still `SetText` with secrets)
- Nameplate styling
- Buff/debuff frame positioning and sizing
- SavedVariables for settings
- Slash commands
- Non-combat event handling

## CreateFrame (Unchanged)

```lua
frame = CreateFrame(frameType [, name, parent, template, id])
```

| Frame Type | Common Use |
|------------|------------|
| `Frame` | Base container, event handling |
| `Button` | Clickable elements |
| `StatusBar` | Health/mana bars, progress indicators |
| `Cooldown` | Ability cooldown displays |
| `GameTooltip` | Tooltip frames (inherit `GameTooltipTemplate`) |
| `ScrollFrame` | Scrollable content areas |
| `EditBox` | Text input |
| `Slider` | Value adjustment |
| `CheckButton` | Toggle options |
| `PlayerModel` | 3D model display |

## Widget Script Handlers

| Handler | Triggers When |
|---------|---------------|
| `OnLoad` | Frame is created (XML templates only) |
| `OnShow` | Frame becomes visible |
| `OnHide` | Frame becomes hidden |
| `OnEvent` | Registered event fires |
| `OnUpdate` | Every frame render (use sparingly!) |
| `OnEnter` | Mouse enters frame |
| `OnLeave` | Mouse leaves frame |
| `OnClick` | Button clicked |
| `OnValueChanged` | Slider/StatusBar value changes |
| `OnDragStart` | Drag operation begins |
| `OnDragStop` | Drag operation ends |

---

# Events (Non-Combat UI Events)

These events remain fully functional for UI/QoL addons:

| Event | Purpose |
|-------|---------|
| `ADDON_LOADED` | Your addon has loaded |
| `PLAYER_LOGIN` | Player fully logged in |
| `PLAYER_ENTERING_WORLD` | Zone/instance transition complete |
| `PLAYER_LOGOUT` | Player logging out |
| `BAG_UPDATE` | Bag contents changed |
| `MERCHANT_SHOW` / `MERCHANT_CLOSE` | Vendor window opened/closed |
| `CHAT_MSG_*` | Chat message received |
| `ZONE_CHANGED_*` | Zone transitions |
| `GROUP_ROSTER_UPDATE` | Party/raid composition changed |
| `GUILD_*` | Guild-related events |
| `ACHIEVEMENT_*` | Achievement events |
| `QUEST_*` | Quest tracking events |
| `CURRENCY_DISPLAY_UPDATE` | Currency changed |

## New Event: PARTY_KILL

New event fired when a party member kills a unit.

**Payload:** 2 unitGUIDs (attacker, target). Both are secret when unit identity is secret.

---

# SavedVariables (Unchanged)

Data persistence works exactly as before.

## TOC Declaration

```
## SavedVariables: MyAddonDB
## SavedVariablesPerCharacter: MyAddonCharDB
```

## Best Practices

- Initialize in `ADDON_LOADED` event
- Provide defaults for missing values
- Version your database schema
- Separate account-wide vs character settings

---

# TOC File (Updated for 12.0)

```
## Interface: 120000
```

Interface version `120000` for Midnight pre-patch, `120001` for Midnight launch.

| Directive | Purpose |
|-----------|---------|
| `## Interface:` | Game version compatibility (120000 for 12.0) |
| `## Title:` | Addon name shown in addon list |
| `## Notes:` | Description shown in addon list |
| `## Author:` | Creator name |
| `## Version:` | Your addon version |
| `## SavedVariables:` | Account-wide saved data |
| `## SavedVariablesPerCharacter:` | Per-character saved data |
| `## Dependencies:` | Required addons (comma-separated) |
| `## OptionalDeps:` | Optional dependencies |
| `## LoadOnDemand:` | 1 = load only when requested |

---

# API Changes Summary (12.0.0)

## Added APIs

| API | Purpose |
|-----|---------|
| `C_DurationUtil.CreateDuration()` | Create duration objects |
| `StatusBar:SetTimerDuration()` | Display timer from duration object |
| `Cooldown:SetCooldownFromDurationObject()` | Configure cooldown from duration |
| `CreateUnitHealPredictionCalculator()` | Create heal prediction calculator |
| `UnitGetDetailedHealPrediction()` | Get detailed heal prediction data |
| `C_CurveUtil.EvaluateColorFromBoolean()` | Convert secret boolean to color |
| `C_CurveUtil.EvaluateColorValueFromBoolean()` | Convert secret boolean to color value |
| `issecretvalue()` | Test if value is secret |
| `canaccesssecrets()` | Test if caller can access secrets |
| `canaccessvalue()` | Test if value is accessible |
| `issecrettable()` | Test if table is secret |
| `canaccesstable()` | Test if table is accessible |

## Modified APIs

| API | Change |
|-----|--------|
| `C_Item.GetItemInfo` | Added return 18: itemDescription |
| `C_Reputation.GetFactionParagonInfo` | Added return 6: paragonStorageLevel |
| `C_Reputation.IsFactionParagon` | Return renamed: hasParagon → factionIsParagon |
| `C_SpecializationInfo.GetSpecializationInfo` | Added arg 7: classID |
| `C_VoiceChat.SpeakText` | Added arg 5: overlap; removed arg 3: destination |

## Removed/Changed Events

| Event | Change |
|-------|--------|
| `VOICE_CHAT_TTS_PLAYBACK_FAILED` | Removed destination param |
| `VOICE_CHAT_TTS_PLAYBACK_FINISHED` | Removed numConsumers, destination |
| `VOICE_CHAT_TTS_PLAYBACK_STARTED` | Removed numConsumers, durationMS, destination |
| `PARTY_KILL` | **NEW** - party member kill notification |

---

# Resources

## Official Documentation

- **In-game:** `/api` command for Blizzard_APIDocumentation
- **warcraft.wiki.gg** - Current API wiki (updated for 12.0)
- **wowpedia.fandom.com/wiki/World_of_Warcraft_API**

## Community Resources

- **WoWUIDev Discord** - Primary addon developer community
- **GitHub: Amadeus-/WoWAddonDevGuide** - Claude AI addon guide (11.2.7 base)
- **CurseForge APIInterface addon** - In-game API browser

## Debugging Tools

| Command/Tool | Purpose |
|--------------|---------|
| `/reload` | Reload UI (test changes) |
| `/fstack` | Show frame stack under cursor |
| `/eventtrace` | Monitor events |
| `/dump variable` | Print variable contents |
| `/console scriptErrors 1` | Show Lua errors |
| BugSack addon | Error capture and logging |
| DevTool addon | Variable inspector |

---

# Migration Summary

For UI/QoL addons that don't process combat data programmatically, migration is minimal.

## Update Checklist

1. ☐ Update `## Interface:` to `120000`
2. ☐ Test with "Load out of date addons" disabled
3. ☐ Replace direct time-value APIs with Duration objects if displaying cooldowns
4. ☐ Use `issecretvalue()` to check if values need special handling
5. ☐ For unit frame health displays, use `UnitHealPredictionCalculator`
6. ☐ For health bar colors, use new color curve APIs

## What Doesn't Need Changes

- Pure cosmetic/layout addons
- Chat modifications
- Bag/inventory management
- Quest/achievement tracking
- Auction house tools
- Map enhancements
- Social/guild features
- Tooltip modifications (display only)

---

# Example: Basic UI Frame (12.0 Compatible)

```lua
-- MyAddon.toc
## Interface: 120000
## Title: My Simple UI Addon
## Notes: A basic UI addon for 12.0
## Author: Your Name
## Version: 1.0.0
## SavedVariables: MyAddonDB

MyAddon.lua
```

```lua
-- MyAddon.lua
local addonName, addon = ...

-- Create main frame
local frame = CreateFrame("Frame", "MyAddonFrame", UIParent, "BackdropTemplate")
frame:SetSize(200, 100)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)

-- Make it movable
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Add text
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")
text:SetText("My Addon Frame")

-- Event handling
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            -- Initialize saved variables
            MyAddonDB = MyAddonDB or {}
            print("|cff00ff00" .. addonName .. " loaded!|r")
        end
    elseif event == "PLAYER_LOGIN" then
        -- Player is fully in game
    end
end)

-- Slash command
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
```

---

*This document covers Patch 12.0.0 (pre-patch) and 12.0.1 (Midnight launch).*
*API changes continue throughout Beta. Check official sources for updates.*
