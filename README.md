# 🎮 MithUI

**A clean, all-in-one UI addon for World of Warcraft 12.0 (Midnight)**

One addon. Ten modules. Zero clutter.

---

## ✨ What's Included

| Module | What It Does |
|--------|--------------|
| 🎯 **Cast Bar** | Luxthos-style centered cast bar with spell icon and timer |
| 🎡 **Radial Menu** | OPie-style pie menu for mounts and hearthstones |
| 💡 **Assist Display** | Shows the Assist-highlighted ability BIG with keybind |
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
/ma  → Assist Display
/av  → Auto Vendor
/tt  → Tooltips
/chat → Chat
/mm  → Minimap
/ct  → Combat Text
/np  → Nameplates
```

---

## 💡 Assist Display (NEW!)

Makes the WoW 12.0 Assist rotation helper actually visible!

When Blizzard's Assist system highlights an ability, this module shows it in a **large, prominent frame** with:
- Big ability icon with blue Blizzard-style glow
- Your keybind displayed prominently
- Spell name below
- Cooldown swipe

**Features:**
- Moveable — unlock and drag anywhere
- Scaleable — make it as big as you need
- Blue animated glow like Blizzard's style

```
/ma toggle   → Enable/disable
/ma lock     → Lock/unlock position (drag when unlocked)
/ma scale 1.5 → Make it bigger (default 1.2)
/ma keybind  → Toggle keybind display
/ma name     → Toggle spell name
/ma glow     → Toggle animated glow
/ma test     → Show test display
/ma reset    → Reset position to default
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

Like OPie — a pie menu for mounts and hearthstones.

**How to use:**
1. Type `/mp` or set a keybind
2. Hover over a category (Mounts or Hearthstones)
3. Scroll wheel to cycle through items — see them in an arc
4. Click or release keybind to use the selected item

**Categories:**
- **Mounts** — Your favorite mounts + random favorite
- **Hearthstones** — All your hearthstone toys and items

```
/mp          → Toggle menu
/mp refresh  → Refresh categories
/mp scale N  → Set scale
/mp debug    → Show debug info
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

```
/np toggle   → Turn on/off
/np quest    → Toggle quest mob highlighting
/np threat   → Toggle threat colors
/np debug    → Debug nameplate detection
```

---

## ⚙️ Settings GUI

Type `/mu` to open the full settings panel.

---

## 📋 Requirements

- World of Warcraft 12.0 (Midnight)
- Interface: 120000

---

## 👤 Author

**Mith**

Version **1.5.0**

---

*One addon to rule them all.* 🧙‍♂️
