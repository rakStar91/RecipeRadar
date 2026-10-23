-- ============================================================================
-- RecipeRadar: UI/Theme.lua
-- Exact 3-Slice Art Textures, Plaque Banner, Dark Buttons & Dropdown Frames
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.Theme = {}

local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate"

-- Standard Classic Backdrop Templates
RR.UI.Theme.BackdropMain = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

RR.UI.Theme.BackdropPanel = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false,
    tileSize = 8,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- ----------------------------------------------------------------------------
-- Skins: every color of the frame art lives here, so a skin is only a new entry.
-- window / panel colors are the backdrop colors (panels get their alpha from the caller),
-- button holds the tints of the button art per state, plaque the tint of the title banner art,
-- dropdown the tint of the dropdown label art, popup* the colors of the dropdown list entries.
-- ----------------------------------------------------------------------------
-- "dark" is shown as "Classic Era" and "bronze" as "WoW Forever"; the keys stay for saved settings
RR.UI.Theme.SKIN_ORDER = { "dark", "bronze", "tbc" }

RR.UI.Theme.SKINS = {
    dark = {
        nameKey = "SKIN_DARK",
        window = { 0.07, 0.08, 0.10, 0.98 },
        windowBorder = { 0.42, 0.35, 0.20, 1.0 },
        panel = { 0.03, 0.04, 0.05 },
        panelBorder = { 0.18, 0.20, 0.25, 0.8 },
        button = {
            normal   = { 0.82, 0.82, 0.82 },
            hover    = { 1.00, 1.00, 1.00 },
            pressed  = { 0.58, 0.58, 0.58 },
            selected = { 1.00, 0.86, 0.45 },
        },
        plaqueArt = "art_header_plaque_plain",
        plaque = { 1, 1, 1 },
        dropdown = { 0.15, 0.15, 0.15, 0.95 },
        popupItem = { 0.04, 0.05, 0.06, 0.6 },
        popupHover = { 0.25, 0.28, 0.35, 1 },
        popupHeader = { 0.12, 0.14, 0.20, 0.95 },
    },
    -- warm brown and bronze, like the WoW Forever profession window
    bronze = {
        nameKey = "SKIN_BRONZE",
        window = { 0.11, 0.08, 0.06, 0.98 },
        windowBorder = { 0.72, 0.50, 0.25, 1.0 },
        panel = { 0.07, 0.05, 0.04 },
        panelBorder = { 0.45, 0.31, 0.17, 0.9 },
        button = {
            normal   = { 0.88, 0.72, 0.55 },
            hover    = { 1.00, 0.90, 0.74 },
            pressed  = { 0.62, 0.48, 0.36 },
            selected = { 1.00, 0.80, 0.45 },
        },
        plaqueArt = "art_header_plaque_plain",
        plaque = { 1.00, 0.86, 0.70 },
        dropdown = { 0.30, 0.20, 0.12, 0.95 },
        popupItem = { 0.08, 0.06, 0.04, 0.6 },
        popupHover = { 0.34, 0.23, 0.12, 1 },
        popupHeader = { 0.22, 0.15, 0.08, 0.95 },
    },
    -- dark with fel green, like The Burning Crusade
    tbc = {
        nameKey = "SKIN_TBC",
        window = { 0.04, 0.08, 0.05, 0.98 },
        windowBorder = { 0.35, 0.80, 0.25, 1.0 },
        panel = { 0.03, 0.06, 0.04 },
        panelBorder = { 0.20, 0.50, 0.16, 0.9 },
        button = {
            normal   = { 0.65, 0.90, 0.60 },
            hover    = { 0.85, 1.00, 0.80 },
            pressed  = { 0.45, 0.65, 0.42 },
            selected = { 0.62, 1.00, 0.35 },
        },
        plaqueArt = "art_header_plaque_plain",
        plaque = { 0.65, 1.00, 0.55 },
        dropdown = { 0.10, 0.22, 0.10, 0.95 },
        popupItem = { 0.03, 0.07, 0.04, 0.6 },
        popupHover = { 0.14, 0.34, 0.14, 1 },
        popupHeader = { 0.08, 0.20, 0.08, 0.95 },
    },
}

-- Everything that was skinned, so a skin change can recolor it (weak: frames are never kept alive by this)
local skinnedWindows = setmetatable({}, { __mode = "k" })
local skinnedPanels = setmetatable({}, { __mode = "k" })   -- frame -> background alpha
local skinnedButtons = setmetatable({}, { __mode = "k" })
local skinnedPlaques = setmetatable({}, { __mode = "k" })
local skinnedDropdowns = setmetatable({}, { __mode = "k" })

--- Returns the key of the skin chosen in the settings ("dark" when none or an unknown one is stored)
function RR.UI.Theme:GetSkinKey()
    local profile = RR.Config and RR.Config:GetProfile()
    local key = profile and profile.skin
    return (key and self.SKINS[key]) and key or "dark"
end

function RR.UI.Theme:GetSkin()
    return self.SKINS[self:GetSkinKey()]
end

local function applyWindowSkin(frame)
    local skin = RR.UI.Theme:GetSkin()
    if frame.SetBackdropColor then frame:SetBackdropColor(unpack(skin.window)) end
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(unpack(skin.windowBorder)) end
end

local function applyPanelSkin(frame, bgAlpha)
    local skin = RR.UI.Theme:GetSkin()
    local r, g, b = unpack(skin.panel)
    if frame.SetBackdropColor then frame:SetBackdropColor(r, g, b, bgAlpha) end
    if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(unpack(skin.panelBorder)) end
end

function RR.UI.Theme:SkinWindow(frame)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(self.BackdropMain)
        skinnedWindows[frame] = true
        applyWindowSkin(frame)
    end
end

function RR.UI.Theme:SkinPanel(frame, bgAlpha)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(self.BackdropPanel)
        skinnedPanels[frame] = bgAlpha or 0.95
        applyPanelSkin(frame, bgAlpha or 0.95)
    end
end

-- the plaque art is cut in three: both ends keep their size, the middle stretches (fraction of the image width)
local PLAQUE_CAP_UV = 0.125

local function applyPlaqueSkin(banner)
    local skin = RR.UI.Theme:GetSkin()
    local c = skin.plaque
    local pieces = banner.pieces
    local art = RR.ADDON_PATH .. "\\images\\" .. skin.plaqueArt .. ".tga"
    pieces.left:SetTexture(art)
    pieces.left:SetTexCoord(0, PLAQUE_CAP_UV, 0, 1)
    pieces.right:SetTexture(art)
    pieces.right:SetTexCoord(1 - PLAQUE_CAP_UV, 1, 0, 1)
    pieces.middle:SetTexture(art)
    pieces.middle:SetTexCoord(PLAQUE_CAP_UV, 1 - PLAQUE_CAP_UV, 0, 1)
    for _, piece in pairs(pieces) do
        piece:SetVertexColor(c[1], c[2], c[3], 1)
    end
end

local function applyDropdownSkin(dropdown)
    local c = RR.UI.Theme:GetSkin().dropdown
    for _, piece in ipairs(dropdown.artPieces) do
        piece:SetVertexColor(c[1], c[2], c[3], c[4])
    end
end

--- Recolors everything that was skinned with the skin that is chosen now
function RR.UI.Theme:ApplySkin()
    for frame in pairs(skinnedWindows) do applyWindowSkin(frame) end
    for frame, bgAlpha in pairs(skinnedPanels) do applyPanelSkin(frame, bgAlpha) end
    for btn in pairs(skinnedButtons) do btn:SetTint(btn.isSelected and "selected" or "normal") end
    for banner in pairs(skinnedPlaques) do applyPlaqueSkin(banner) end
    for dropdown in pairs(skinnedDropdowns) do applyDropdownSkin(dropdown) end
    if RR.UI.Dropdown then RR.UI.Dropdown:Hide() end
end

--- Chooses a skin, stores it in the profile and applies it to the open windows
function RR.UI.Theme:SetSkin(key)
    if not self.SKINS[key] then return end
    local profile = RR.Config and RR.Config:GetProfile()
    if profile then profile.skin = key end
    self:ApplySkin()
end

function RR.UI.Theme:Create3SlicePieces(parent, texture, cap_uv, cap_px, layer)
    layer = layer or "BACKGROUND"
    local pieces = {}

    pieces.left = parent:CreateTexture(nil, layer)
    pieces.left:SetTexture(texture)
    pieces.left:SetTexCoord(0, cap_uv, 0, 1)
    pieces.left:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    pieces.left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    pieces.left:SetWidth(cap_px)

    pieces.right = parent:CreateTexture(nil, layer)
    pieces.right:SetTexture(texture)
    pieces.right:SetTexCoord(1 - cap_uv, 1, 0, 1)
    pieces.right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    pieces.right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    pieces.right:SetWidth(cap_px)

    pieces.middle = parent:CreateTexture(nil, layer)
    pieces.middle:SetTexture(texture)
    pieces.middle:SetTexCoord(cap_uv, 1 - cap_uv, 0, 1)
    pieces.middle:SetPoint("TOPLEFT", pieces.left, "TOPRIGHT", 0, 0)
    pieces.middle:SetPoint("BOTTOMRIGHT", pieces.right, "BOTTOMLEFT", 0, 0)

    return pieces
end

--- Creates the authentic 3-Slice Title Banner Plaque
function RR.UI.Theme:CreateTitlePlaque(parent, width, height, titleText)
    local banner = CreateFrame("Frame", nil, parent)
    banner:SetSize(width or 380, height or 46)

    -- texture and tint come from the skin (applyPlaqueSkin below)
    local plaqueTex = RR.ADDON_PATH .. "\\images\\" .. self:GetSkin().plaqueArt .. ".tga"
    banner.pieces = self:Create3SlicePieces(banner, plaqueTex, PLAQUE_CAP_UV, 23, "ARTWORK")

    skinnedPlaques[banner] = true
    applyPlaqueSkin(banner)

    banner.text = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    banner.text:SetPoint("CENTER", banner, "CENTER", 0, -3)
    banner.text:SetTextColor(1, 0.82, 0, 1)
    banner.text:SetText(titleText or RR.NAME)

    banner.SetTitle = function(selfB, newText)
        selfB.text:SetText(newText)
    end

    return banner
end

--- Creates the authentic 3-Slice Dark Button using art_button.tga
function RR.UI.Theme:CreateDarkButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 80, height or 24)

    local btnTex = RR.ADDON_PATH .. "\\images\\art_button.tga"
    btn.art_pieces = self:Create3SlicePieces(btn, btnTex, 0.0625, 6, "BACKGROUND")

    btn.SetTint = function(button, state)
        local tints = RR.UI.Theme:GetSkin().button
        local c = tints[state] or tints.normal
        for _, piece in pairs(button.art_pieces) do
            piece:SetVertexColor(c[1], c[2], c[3], 1)
        end
    end
    skinnedButtons[btn] = true
    btn:SetTint("normal")

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("LEFT", btn, "LEFT", 4, 0)
    btn.text:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    btn.text:SetJustifyH("CENTER")
    btn.text:SetWordWrap(false)
    btn.text:SetText(text or "")
    btn.text:SetTextColor(0.90, 0.90, 0.90, 1)

    btn:SetScript("OnEnter", function(selfB)
        if not selfB.isSelected then
            selfB:SetTint("hover")
            selfB.text:SetTextColor(1, 1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(selfB)
        if not selfB.isSelected then
            selfB:SetTint("normal")
            selfB.text:SetTextColor(0.90, 0.90, 0.90, 1)
        end
    end)
    btn:SetScript("OnMouseDown", function(selfB)
        selfB:SetTint("pressed")
    end)
    btn:SetScript("OnMouseUp", function(selfB)
        if selfB.isSelected then
            selfB:SetTint("selected")
        else
            selfB:SetTint("hover")
        end
    end)

    btn.SetActive = function(selfB, active)
        selfB.isSelected = active
        if active then
            selfB:SetTint("selected")
            selfB.text:SetTextColor(1, 0.85, 0.2, 1)
        else
            selfB:SetTint("normal")
            selfB.text:SetTextColor(0.90, 0.90, 0.90, 1)
        end
    end

    btn.SetLabel = function(selfB, newText)
        selfB.text:SetText(newText)
    end
    btn.SetText = btn.SetLabel

    return btn
end

--- Creates an authentic WoW DropDown frame with 3-slice background and gold scroll down button
function RR.UI.Theme:CreateDropDownFrame(parent, width, titleText, onClick)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    f:SetSize(width or 120, 24)

    local left = f:CreateTexture(nil, "BACKGROUND")
    left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    left:SetTexCoord(0, 0.1953125, 0, 1)
    left:SetSize(22, 34)
    left:SetPoint("TOPLEFT", -12, 5)

    local right = f:CreateTexture(nil, "BACKGROUND")
    right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    right:SetTexCoord(0.8046875, 1, 0, 1)
    right:SetSize(22, 34)
    right:SetPoint("TOPRIGHT", 12, 5)

    local mid = f:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    mid:SetTexCoord(0.1953125, 0.8046875, 0, 1)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetHeight(34)

    f.artPieces = { left, mid, right }
    skinnedDropdowns[f] = true
    applyDropdownSkin(f)

    local btn = CreateFrame("Button", nil, f)
    btn:SetSize(20, 20)
    btn:SetPoint("RIGHT", 2, 0)
    btn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    btn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    btn:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 4, 0)
    text:SetPoint("RIGHT", btn, "LEFT", -2, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetText(titleText or "")

    local clickBtn = CreateFrame("Button", nil, f)
    clickBtn:SetAllPoints(f)
    clickBtn:SetScript("OnClick", function()
        if onClick then onClick(f) end
    end)
    btn:SetScript("OnClick", function()
        if onClick then onClick(f) end
    end)

    f.text = text
    f.button = btn
    f.clickBtn = clickBtn
    return f
end

local STRATA_ORDER = { "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP" }

local function strataIndex(name)
    for i, strata in ipairs(STRATA_ORDER) do
        if strata == name then return i end
    end
    return #STRATA_ORDER
end

--- Keeps a window one strata below the world map while the map is open, so it never covers the map
-- @param frame Frame the window
-- @param normalStrata string the strata the window has otherwise
function RR.UI.Theme:KeepBehindWorldMap(frame, normalStrata)
    local map = WorldMapFrame
    if not (map and map.HookScript) then return end

    local function update()
        local index = strataIndex(normalStrata)
        if map:IsShown() then
            index = math.max(1, math.min(index, strataIndex(map:GetFrameStrata()) - 1))
        end
        frame:SetFrameStrata(STRATA_ORDER[index])
    end
    map:HookScript("OnShow", update)
    map:HookScript("OnHide", update)
    update()
end

--- Standardized tooltip attachment using HookScript
function RR.UI.Theme:AddTooltip(frame, title, text, anchor)
    if not frame then return end
    local target = frame.clickBtn or frame
    target:HookScript("OnEnter", function(selfF)
        GameTooltip:SetOwner(selfF, anchor or "ANCHOR_RIGHT")
        if title then
            GameTooltip:AddLine(title, 1.0, 0.82, 0.0, true)
        end
        if text and text ~= "" then
            GameTooltip:AddLine(text, 0.90, 0.90, 0.90, true)
        end
        GameTooltip:Show()
    end)
    target:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- WoW Forever ships the scroll bar of the current client (flagged in its data); Classic Era and TBC keep the old template.
function RR.UI.Theme:HasModernScrollBar()
    return RR_DATA["modern_scrollbar"] == true
end

-- Horizontal room a scroll bar takes at the edge of its list, so rows can stay clear of it
function RR.UI.Theme:GetScrollBarSpace()
    return self:HasModernScrollBar() and 24 or 22
end

--- Creates a vertical scroll bar that is used like a Slider (SetMinMaxValues, SetValue, GetValue, Show, Hide)
-- opts.name: global name (optional)
-- opts.onValueChanged(bar, value): called when the value changes, by the user or by SetValue
-- opts.step: value change of one arrow click
-- opts.visible: size of the visible area in value units (number or function), the thumb size follows from it
-- opts.integer: whole values only (list rows)
-- opts.width: width of the old template
-- opts.right, opts.inset: distance to the right edge of the parent and to its top and bottom (old template)
function RR.UI.Theme:CreateScrollBar(parent, opts)
    if not self:HasModernScrollBar() then
        -- the template calls SetVerticalScroll on its parent, which plain frames do not have
        if not parent.SetVerticalScroll then parent.SetVerticalScroll = function() end end
        local bar = CreateFrame("Slider", opts.name, parent, "UIPanelScrollBarTemplate")
        bar:SetWidth(opts.width or 16)
        bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", opts.right or -4, -(opts.inset or 18))
        bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", opts.right or -4, opts.inset or 18)
        -- own handler first: the template's one runs on the first SetValue otherwise
        bar:SetScript("OnValueChanged", function(_, value) opts.onValueChanged(bar, value) end)
        bar:SetMinMaxValues(0, 0)
        bar:SetValue(0)
        bar:SetValueStep(opts.step or 1)
        return bar
    end

    local bar = CreateFrame("EventFrame", opts.name, parent, "MinimalScrollBar")
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", (opts.right or -4) - 5, -3)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", (opts.right or -4) - 5, 3)
    local minValue, maxValue, value, step = 0, 0, 0, opts.step or 1

    local function percentOf(v)
        local range = maxValue - minValue
        return range > 0 and (v - minValue) / range or 0
    end

    -- the thumb size and the arrow step are fractions of the whole scroll range
    local function updateExtents()
        local range = maxValue - minValue
        if range > 0 then
            local visible = type(opts.visible) == "function" and opts.visible() or opts.visible or 0
            bar:SetPanExtentPercentage(step / range)
            bar:SetVisibleExtentPercentage(visible / (visible + range))
        else
            bar:SetVisibleExtentPercentage(1)
        end
    end

    bar:RegisterCallback("OnScroll", function(_, percentage)
        local newValue = minValue + percentage * (maxValue - minValue)
        if opts.integer then newValue = math.floor(newValue + 0.5) end
        if math.abs(newValue - value) > 0.000001 then
            value = newValue
            opts.onValueChanged(bar, value)
        end
    end, bar)

    function bar:SetMinMaxValues(minV, maxV)
        local oldValue = value
        minValue, maxValue = minV, maxV
        value = math.max(minV, math.min(maxV, value))
        updateExtents()
        self:SetScrollPercentage(percentOf(value), true)
        if value ~= oldValue then opts.onValueChanged(self, value) end
    end

    function bar:GetMinMaxValues()
        return minValue, maxValue
    end

    function bar:SetValue(v)
        -- the scroll event stores the value and tells the owner
        self:SetScrollPercentage(percentOf(math.max(minValue, math.min(maxValue, v))), true)
    end

    function bar:GetValue()
        return value
    end

    function bar:SetValueStep(s)
        step = s
        updateExtents()
    end

    return bar
end
