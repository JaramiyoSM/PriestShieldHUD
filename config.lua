-- PriestShieldHUD config (English client only)
-- Choose your style by number here; no slash command to change styles.
-- 1 = Vertical Segments (arcane blue, narrower)
-- 2 = Sleek Horizontal Bar (cyan to white)
-- 3 = Dual Column (gold ticks + blue gauge)
PSH_CFG = {
  style = 1,
  segments = 16,
  width = 9,
  gap = 2,
  scale = 1.0,
  anim_speed = 160,
  debug = false,

  style1 = { color_full = {0.30, 0.75, 1.00}, color_empty = {0.18, 0.18, 0.22}, glow_color = {0.60, 0.90, 1.00} },
  style2 = { bar_color = {0.25, 0.95, 1.00}, bg_color = {0.10, 0.12, 0.16} },
  style3 = { left_color = {1.00, 0.85, 0.30}, right_color = {0.35, 0.80, 1.00}, empty_color = {0.20, 0.20, 0.24} },
}
