-- PriestShieldHUD v1.0.0 (English-only, Turtle 1.12 / Lua 5.0)
if type(PriestShieldHUDDB) ~= "table" then PriestShieldHUDDB = nil end
local cfg = PSH_CFG or {}
local STYLE = cfg.style or 1

local DEBUG = false
local function dprint(msg) if DEBUG and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[PSH]|r "..tostring(msg or "")) end end
local function SetDebug(v) DEBUG = v and true or false; if PriestShieldHUDDB then PriestShieldHUDDB.debug = DEBUG end; dprint("debug "..(DEBUG and "ON" or "OFF")) end

local frame, valueText, labelText
local segments, leftTicks, rightGauge = {}, {}, {}
local barFront, barBack, glow
local maxAbsorb, currentAbsorb, displayAbsorb = 0, 0, 0
local active = false

local tip = CreateFrame("GameTooltip", "PSH_ScanTip", UIParent, "GameTooltipTemplate")
local st  = CreateFrame("GameTooltip", "PSH_SpellTip", UIParent, "GameTooltipTemplate")

local ABSORB_KEYWORDS = {
  "Power Word: Shield", "Mana Shield", "Ice Barrier", "Sacrifice",
  "Fire Ward", "Frost Ward", "Ward", "Barrier", "Absorption", "Shield",
}

local function contains(s, sub) if s and sub and string.find(s, sub) then return true end return false end
local function first_number(s) if s and string.gfind then for n in string.gfind(s, "(%d+)") do return tonumber(n) end end return nil end
local function largest_number(s) local best=0; if s and string.gfind then for n in string.gfind(s, "(%d+)") do local v=tonumber(n) or 0 if v>best then best=v end end end if best>0 then return best end return nil end

local function collectText(prefix)
  local txt=""
  for i=1,15 do
    local fs = getglobal(prefix..i)
    if fs then local t=fs:GetText(); if t and t~="" then txt = txt.."\n"..t end end
  end
  return txt
end

local function parseAbsorbFromEN(text)
  if not text then return nil end
  if string.gfind then
    for n in string.gfind(text, "absorbing%s+(%d+)%s+damage") do return tonumber(n) end
    for n in string.gfind(text, "absorbs%s+(%d+)%s+damage")  do return tonumber(n) end
  end
  return largest_number(text)
end

-- NEW: always pick highest rank from spellbook when falling back
local function spellbookAbsorbFor(name)
  if not name or name == "" then return nil end
  local maxN = 0
  local i=1
  while true do
    local sName = GetSpellName(i, "spell")
    if not sName then break end
    if sName == name then
      st:ClearLines(); st:SetOwner(UIParent, "ANCHOR_NONE"); st:SetSpell(i, "spell")
      local t = collectText("PSH_SpellTipTextLeft")
      local n = parseAbsorbFromEN(t)
      if n and n > maxN then maxN = n end
    end
    i=i+1
  end
  if maxN > 0 then return maxN end
  return nil
end

local function buffAbsorbSum()
  local total = 0
  tip:SetOwner(UIParent, "ANCHOR_NONE")
  for i=1,32 do
    local idx = GetPlayerBuff(i-1, "HELPFUL")
    if idx == -1 then break end
    tip:ClearLines(); tip:SetPlayerBuff(idx)
    local text = collectText("PSH_ScanTipTextLeft")
    local isAbsorb = false
    for k=1, getn(ABSORB_KEYWORDS) do if contains(text, ABSORB_KEYWORDS[k]) then isAbsorb = true; break end end
    if isAbsorb or contains(text, "absorb") or contains(text, "absorbs") or contains(text, "absorbing") then
      local n = parseAbsorbFromEN(text)
      if (not n or n==0) and isAbsorb then
        local first = gsub(text, "\n.*", "")
        if first then
          first = gsub(first, "%s*%b()", "")
          first = gsub(first, ":%s*$", "")
          local sb = spellbookAbsorbFor(first)
          if sb and sb>0 then n = sb end
        end
      end
      if n and n>0 then total = total + n end
    end
  end
  if total > 0 then return total end
  return nil
end

local function applyDisplay()
  if not frame then return end
  if maxAbsorb <= 0 then
    valueText:SetText("0")
    if STYLE == 2 then if barFront then barFront:SetWidth(1); barFront:Hide() end
    elseif STYLE == 3 then for i=1,getn(leftTicks) do leftTicks[i]:SetVertexColor(cfg.style3.empty_color[1],cfg.style3.empty_color[2],cfg.style3.empty_color[3],0.2); rightGauge[i]:SetVertexColor(cfg.style3.empty_color[1],cfg.style3.empty_color[2],cfg.style3.empty_color[3],0.2) end
    else for i=1,getn(segments) do segments[i]:SetVertexColor(cfg.style1.color_empty[1],cfg.style1.color_empty[2],cfg.style1.color_empty[3],0.22) end end
    return
  end
  local disp = displayAbsorb; if disp<0 then disp=0 end; if disp>maxAbsorb then disp=maxAbsorb end
  valueText:SetText(tostring(floor(disp+0.5)))
  local ratio = disp / maxAbsorb; if ratio<0 then ratio=0 end; if ratio>1 then ratio=1 end
  if STYLE == 2 then local fullW=220; local w=max(1,floor(fullW*ratio)); if barFront then barFront:SetWidth(w); barFront:Show() end
  elseif STYLE == 3 then local lit=floor(ratio*getn(rightGauge)+0.0001); for i=1,getn(rightGauge) do if i<=lit then rightGauge[i]:SetVertexColor(cfg.style3.right_color[1],cfg.style3.right_color[2],cfg.style3.right_color[3],1.0); leftTicks[i]:SetVertexColor(cfg.style3.left_color[1],cfg.style3.left_color[2],cfg.style3.left_color[3],0.9) else rightGauge[i]:SetVertexColor(cfg.style3.empty_color[1],cfg.style3.empty_color[2],cfg.style3.empty_color[3],0.25); leftTicks[i]:SetVertexColor(cfg.style3.empty_color[1],cfg.style3.empty_color[2],cfg.style3.empty_color[3],0.25) end end
  else local lit=floor(ratio*getn(segments)+0.0001); for i=1,getn(segments) do if i<=lit then segments[i]:SetVertexColor(cfg.style1.color_full[1],cfg.style1.color_full[2],cfg.style1.color_full[3],1.0) else segments[i]:SetVertexColor(cfg.style1.color_empty[1],cfg.style1.color_empty[2],cfg.style1.color_empty[3],0.25) end end end
end

local function clearWidgets() segments,leftTicks,rightGauge = {},{},{}; barFront,barBack,glow = nil,nil,nil; if frame then local kids = { frame:GetChildren() } for _,k in ipairs(kids) do k:Hide() end end end

local function buildStyle1()
  local s1 = cfg.style1 or {color_full={0.3,0.75,1.0}, color_empty={0.18,0.18,0.22}, glow_color={0.6,0.9,1.0}}
  local totalH = frame:GetHeight() - 30
  local segH = floor((totalH - ((cfg.segments or 16)-1)*(cfg.gap or 2)) / (cfg.segments or 16))
  glow = frame:CreateTexture(nil, "ARTWORK"); glow:SetWidth(frame:GetWidth()-6); glow:SetHeight(frame:GetHeight()-8); glow:SetPoint("CENTER", frame, "CENTER", 0, 6); glow:SetTexture(1,1,1,1); glow:SetVertexColor(s1.glow_color[1], s1.glow_color[2], s1.glow_color[3], 0.07)
  for i=1,(cfg.segments or 16) do local t=frame:CreateTexture(nil,"OVERLAY"); t:SetWidth(cfg.width or 9); t:SetHeight(segH); local y=(i-1)*(segH+(cfg.gap or 2)) - (totalH/2 - segH/2); t:SetPoint("RIGHT", frame, "RIGHT", -10, y); t:SetTexture(1,1,1,1); if t.SetGradientAlpha then t:SetGradientAlpha("VERTICAL", s1.color_full[1], s1.color_full[2], s1.color_full[3], 0.95, s1.color_full[1]*0.5, s1.color_full[2]*0.5, s1.color_full[3]*0.5, 0.95) end; t:SetVertexColor(s1.color_empty[1],s1.color_empty[2],s1.color_empty[3],0.24); segments[i]=t end
end

local function buildStyle2()
  local s2 = cfg.style2 or {bar_color={0.25,0.95,1.0}, bg_color={0.1,0.12,0.16}}
  local w,h = 220,18
  barBack = frame:CreateTexture(nil, "ARTWORK"); barBack:SetPoint("CENTER", frame, "CENTER", 0, 6); barBack:SetWidth(w); barBack:SetHeight(h); barBack:SetTexture(1,1,1,1); barBack:SetVertexColor(s2.bg_color[1],s2.bg_color[2],s2.bg_color[3],0.55)
  barFront = frame:CreateTexture(nil, "OVERLAY"); barFront:SetPoint("LEFT", barBack, "LEFT", 0, 0); barFront:SetWidth(w); barFront:SetHeight(h); barFront:SetTexture(1,1,1,1); if barFront.SetGradientAlpha then barFront:SetGradientAlpha("HORIZONTAL", s2.bar_color[1], s2.bar_color[2], s2.bar_color[3], 0.95, 1,1,1,0.95) end
end

local function buildStyle3()
  local s3 = cfg.style3 or {left_color={1.0,0.85,0.30}, right_color={0.35,0.80,1.0}, empty_color={0.20,0.20,0.24}}
  local totalH = frame:GetHeight() - 30
  local segH = floor((totalH - ((cfg.segments or 16)-1)*(cfg.gap or 2)) / (cfg.segments or 16))
  for i=1,(cfg.segments or 16) do local y=(i-1)*(segH+(cfg.gap or 2)) - (totalH/2 - segH/2)
    local left=frame:CreateTexture(nil,"OVERLAY"); left:SetWidth((cfg.width or 9)-2); left:SetHeight(segH); left:SetPoint("RIGHT", frame, "RIGHT", -28, y); left:SetTexture(1,1,1,1); left:SetVertexColor(s3.empty_color[1],s3.empty_color[2],s3.empty_color[3],0.25); leftTicks[i]=left
    local right=frame:CreateTexture(nil,"OVERLAY"); right:SetWidth((cfg.width or 9)); right:SetHeight(segH); right:SetPoint("RIGHT", frame, "RIGHT", -10, y); right:SetTexture(1,1,1,1); right:SetVertexColor(s3.empty_color[1],s3.empty_color[2],s3.empty_color[3],0.25); rightGauge[i]=right
  end
end

local function rebuildStyle() clearWidgets(); if STYLE==2 then buildStyle2() elseif STYLE==3 then buildStyle3() else buildStyle1() end end

local function createFrame()
  if frame then return end
  frame = CreateFrame("Frame", "PriestShieldHUD_Frame", UIParent)
  frame:SetWidth(260); frame:SetHeight(220)
  frame:SetScale((PriestShieldHUDDB and PriestShieldHUDDB.scale) or (cfg.scale or 1.0))
  local p = (PriestShieldHUDDB and PriestShieldHUDDB.pos) or {point="CENTER", rel="CENTER", x=260, y=-20}
  frame:SetPoint(p.point, UIParent, p.rel, p.x, p.y)
  frame:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=8, edgeSize=8, insets={left=3,right=3,top=3,bottom=3} })
  frame:SetBackdropColor(0,0,0,0.20)
  frame:EnableMouse(true); frame:SetMovable(true)
  frame:SetScript("OnMouseDown", function() if IsShiftKeyDown() and arg1=="LeftButton" then frame:StartMoving() end end)
  frame:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); local point,_,rel,x,y=frame:GetPoint(1); if type(PriestShieldHUDDB)=="table" then PriestShieldHUDDB.pos={point=point,rel=rel,x=x,y=y} end end)
  frame:SetScript("OnUpdate", function() if not active or maxAbsorb<=0 then return end; local fps=GetFramerate() or 30; local step=(cfg.anim_speed or 160)/(fps>0 and fps or 30); if displayAbsorb>currentAbsorb then displayAbsorb=displayAbsorb-step; if displayAbsorb<currentAbsorb then displayAbsorb=currentAbsorb end elseif displayAbsorb<currentAbsorb then displayAbsorb=displayAbsorb+step; if displayAbsorb>currentAbsorb then displayAbsorb=currentAbsorb end else return end; applyDisplay() end)
  frame:Hide()
  valueText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); valueText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 6); valueText:SetTextColor(1,1,0.6); valueText:SetText("0")
  labelText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); labelText:SetPoint("TOP", frame, "TOP", 0, -6); labelText:SetTextColor(0.85,0.9,1.0); labelText:SetText("PWS")
  rebuildStyle()
end

local function deactivate() active=false; maxAbsorb=0; currentAbsorb=0; displayAbsorb=0; if frame then frame:Hide() end; applyDisplay() end
local function activate(total) if not total then return end; active=true; maxAbsorb=total; currentAbsorb=total; displayAbsorb=total; if frame then frame:Show() end; applyDisplay() end

local function absorbFromMsg(msg)
  if not msg then return nil end
  if string.gfind then
    for n in string.gfind(msg, "absorbs%s+(%d+)%s+damage") do return tonumber(n) end
    for n in string.gfind(msg, "(%d+)%s+absorbed") do return tonumber(n) end
  end
  return nil
end

local ev = CreateFrame("Frame", "PSH_EventFrame", UIParent)
ev:RegisterEvent("VARIABLES_LOADED")
ev:RegisterEvent("PLAYER_AURAS_CHANGED")
ev:RegisterEvent("UNIT_AURA")
ev:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
ev:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
ev:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
ev:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
ev:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
ev:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE")
ev:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")

ev:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    if type(PriestShieldHUDDB) ~= "table" then PriestShieldHUDDB = {} end
    if PriestShieldHUDDB.scale == nil then PriestShieldHUDDB.scale = cfg.scale or 1.0 end
    if not PriestShieldHUDDB.pos then PriestShieldHUDDB.pos = {point="CENTER",rel="CENTER",x=260,y=-20} end
    if PriestShieldHUDDB.debug == nil then PriestShieldHUDDB.debug = cfg.debug or false end
    DEBUG = PriestShieldHUDDB.debug and true or false
    createFrame()
    SLASH_PSH1="/psh"; SlashCmdList["PSH"]=function(msg)
      msg=string.lower(msg or "")
      if string.find(msg,"scale") then local n=first_number(msg); if n then PriestShieldHUDDB.scale=n; frame:SetScale(n) else DEFAULT_CHAT_FRAME:AddMessage("PSH: /psh scale 1.2") end
      elseif msg=="test" then activate(1200)
      elseif msg=="hide" then deactivate()
      elseif msg=="debug" then SetDebug(not DEBUG)
      else DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PSH:|r scale <n>, test, hide, debug  (drag with Shift+LeftButton)") end
    end
  elseif event == "UNIT_AURA" or event == "PLAYER_AURAS_CHANGED" or event == "CHAT_MSG_SPELL_SELF_BUFF" then
    if event ~= "UNIT_AURA" or arg1 == "player" then local total=buffAbsorbSum(); if total and total>0 then activate(total) else deactivate() end end
  elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
    if contains(arg1, "fades") and (contains(arg1,"Shield") or contains(arg1,"Barrier") or contains(arg1,"Ward")) then local total=buffAbsorbSum(); if total and total>0 then activate(total) else deactivate() end end
  else
    if not active then return end
    local n = absorbFromMsg(arg1); if n then currentAbsorb=currentAbsorb-n; if currentAbsorb<=0 then local total=buffAbsorbSum(); if total and total>0 then activate(total) else deactivate() end else applyDisplay() end end
  end
end)
