# PriestShieldHUD
Animated absorb HUD for Turtle 1.12 (English client) with styles

## 🛡️ PriestShieldHUD

**Version:** 1.0.0
**Author:** *Jaramiiyo*
**Game Compatibility:** Turtle WoW (Client 1.12 / Patch 1.17.2)
**Language:** English client only

---

### 📖 Description

**PriestShieldHUD** is a lightweight and fully visual **absorb tracker** designed for **Turtle WoW**’s legacy client (1.12).
It detects and displays all **absorb-type shields** applied to your character — such as *Power Word: Shield*, *Mana Shield*, *Ice Barrier*, *Wards*, and others — even if they come from another player.

The addon sums all active shields and shows the **total remaining absorb value** through an animated HUD bar.
Originally made for priests, it now supports **any class** that uses absorb-type spells.

---

### ⚙️ Features

* Tracks **all absorb effects** on the player.
* Works with shields cast **by you or others**.
* Reads absorb values directly from the **buff tooltip**.
* If no value is found, it automatically checks the **Spellbook** and always picks the **highest available rank**.
* Supports multiple absorb-type buffs (adds them together).
* Visual **animated HUD bar** with smooth drain effect.
* Three selectable **HUD styles**, configured via file.
* Movable on screen using **Shift + Left Click**.
* Fully compatible with **Turtle WoW’s old addon API (1.12)**.

---

### 🧩 Installation

1. Download the latest release ZIP.
2. Extract it into your Turtle WoW AddOns directory:

   ```
   TurtleWoW/Interface/AddOns/PriestShieldHUD/
   ```
3. Make sure your file structure looks like this:

   ```
   PriestShieldHUD/
     ├─ PriestShieldHUD.toc
     ├─ core.lua
     └─ config.lua
   ```
4. Restart your game and check the “AddOns” button at character select.
   Ensure **PriestShieldHUD** is enabled.

---

### 🕹️ Usage

* Cast **Power Word: Shield** or any absorb-type ability — the HUD will appear automatically.
* The HUD shows the **total damage absorbable** before your HP is affected.
* The bar animates smoothly as the shield absorbs hits.
* To move the HUD:

  * Hold **Shift + Left Click** and drag.
* To test the addon manually:

  ```
  /psh test
  ```
* To scale the HUD:

  ```
  /psh scale 1.2
  ```
* To toggle debug messages:

  ```
  /psh debug
  ```

---

### 🎨 Configuration

All visual customization is handled through the `config.lua` file inside the addon folder.

```lua
PSH_CFG = {
  style = 1,        -- 1 = Vertical Segments, 2 = Sleek Horizontal, 3 = Dual Column
  segments = 16,
  width = 9,        -- bar width for style 1 & 3
  gap = 2,
  scale = 1.0,
  anim_speed = 160,
  debug = false,
}
```

Each style has its own color configuration that can be edited directly in the same file.

---

### 🧠 How It Works

* **Tooltip Scanning:**
  Reads the buff tooltip to extract phrases like “absorbing 48 damage”.

* **Spellbook Fallback:**
  If the buff has no absorb number, the addon scans your Spellbook and retrieves the **highest-rank** tooltip value.

* **Total Absorb Calculation:**
  All shields currently active on your character are summed together into one combined value.

* **Combat Updates:**
  The addon listens to combat log messages (“absorbs X damage”, “X absorbed”) to update the absorb total dynamically as you take damage.

---

### 👤 Credits

Created and developed by **Jaramiiyo**
All rights reserved.
