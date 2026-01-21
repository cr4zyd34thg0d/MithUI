# 🎮 MithUI

**A clean, all-in-one UI addon for World of Warcraft 12.0 (Midnight)**

One addon. Nine modules. Zero clutter.

---

## ✨ What's Included

| Module | What It Does |
|--------|--------------|
| 🎯 **Cast Bar** | Luxthos-style centered cast bar with spell icon and timer |
| 🎡 **Radial Menu** | OPie-style pie menu for mounts, hearthstones, and class abilities |
| 🏪 **Auto Vendor** | Auto-repair and sell junk when you visit a vendor |
| 💬 **Tooltips** | Shows item level, spec, guild, and target-of-target on hover |
| 📝 **Chat** | Clickable URLs, copy button, class-colored names |
| 🗺️ **Minimap** | Hides clutter, collects addon buttons, optional square shape |
| ⚔️ **Combat Text** | Floating damage/healing numbers |
| 🎯 **Nameplates** | Quest mobs glow orange, interruptible casts glow green |

---

## 📦 Installation

1. Download or clone this repo
2. Rename the folder to `MithUI` (if needed)
3. Copy to: `World of Warcraft\_retail_\Interface\AddOns\MithUI`
4. Restart WoW or `/reload`

---

## 🚀 Quick Start

Type `/mu` to open the settings GUI — everything is configurable from there.

**Individual module commands:**
```
/mc  → Cast Bar
/mp  → Radial Menu (Pie)
/av  → Auto Vendor
/tt  → Tooltips
/chat → Chat
/mm  → Minimap
/ct  → Combat Text
/np  → Nameplates
```

---

## 🎯 Cast Bar

Clean, minimal, Luxthos-inspired.

- Centered below your character
- Shows spell icon + timer
- **Blue** = casting, **Green** = channeling, **Red** = can't interrupt
- Drag to move (when unlocked)

```
/mc test     → Preview the bar
/mc lock     → Lock position
/mc unlock   → Unlock to move
```

---

## 🎡 Radial Menu

Like OPie — a pie menu that pops up with your stuff.

**How to use:**
1. Set a keybind in **Key Bindings → MithUI**
2. **Hold** the key — category menu appears (Mounts, Hearthstones, Class)
3. **Move mouse** toward a category — sub-menu opens with items
4. **Move to specific item** — it highlights
5. **Release** the key — activates that item

**3 Categories:**
1. **Mounts** — Your favorite mounts + random favorite
2. **Hearthstones** — All your hearthstones and teleport toys
3. **Class Abilities** — Death Gate, Soulwell, Ritual of Summoning, etc.

**Keybinds available:**
- Toggle Radial Menu (starts at category selection)
- Radial Menu: Mounts (skips to mounts directly)
- Radial Menu: Hearthstones (skips to hearthstones directly)
- Radial Menu: Class (skips to class abilities directly)

```
/mp          → Open menu (click mode)
/mp refresh  → Refresh rings (detect new items)
/mp list     → List all rings
```

---

## 🏪 Auto Vendor

Set it and forget it.

- ✅ Auto-repairs your gear (uses guild bank first)
- ✅ Auto-sells gray junk items
- ✅ Shows gold earned/spent in chat

```
/av toggle   → Turn on/off
/av junk     → Toggle junk selling
/av guild    → Toggle guild bank repair
```

---

## 💬 Tooltips

More info on hover.

- **Item Level** on players
- **Spec** (Arms Warrior, Holy Paladin, etc.)
- **Guild** name
- **Target of Target** (who are they attacking?)
- Class-colored names

```
/tt toggle   → Turn on/off
/tt ilvl     → Toggle item level
/tt spec     → Toggle spec display
```

---

## 📝 Chat

Small improvements, big difference.

- **Clickable URLs** — Click to copy
- **Copy button** — Hover top-right of chat frame
- **Short channels** — [Guild] → [G], [Party] → [P]
- **Class colors** — Names colored by class

```
/chat urls   → Toggle clickable URLs
/chat copy   → Open copy window
/chat short  → Toggle short channel names
```

---

## 🗺️ Minimap

Declutter your minimap.

- Hides zoom buttons (just scroll instead)
- Collects addon buttons (show on hover)
- Optional: hide calendar, hide clock, square shape

```
/mm toggle   → Turn on/off
/mm square   → Toggle square minimap
/mm buttons  → Toggle button collection
```

---

## ⚔️ Combat Text

Floating numbers for damage and healing.

- **White** = your damage
- **Green** = your healing  
- **Red** (left side) = damage you're taking
- **BIG** = critical hits

```
/ct toggle   → Turn on/off
/ct crits    → Toggle crit highlighting
/ct incoming → Toggle incoming damage
```

---

## 🎯 Nameplates

Tidy Plates-style with smart indicators.

### Visual Cues:
- 🟠 **Orange health bar** = Quest mob (kill it for your quest!)
- 🟢 **Green glowing cast bar** = Interruptible (kick it!)
- 🔴 **Red cast bar + shield** = Can't interrupt
- Threat colors show who has aggro

### Themes:
```
/np theme grey      → Clean minimal (default)
/np theme neon      → Glowing style
/np theme clean     → Modern look
/np theme thin      → Minimal thin bars
/np theme headline  → Names only, no bars
```

```
/np toggle   → Turn on/off
/np quest    → Toggle quest mob highlighting
/np threat   → Toggle threat colors
```

---

## ⚙️ Settings GUI

Type `/mu` to open the full settings panel.

8 tabs for all modules — checkboxes, sliders, everything you need.

---

## 📋 Requirements

- World of Warcraft 12.0 (Midnight)
- Interface: 120000

---

## 👤 Author

**Mith**

Version **1.3.0**

---

*One addon to rule them all.* 🧙‍♂️
