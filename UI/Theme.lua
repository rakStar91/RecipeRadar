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

function RR.UI.Theme:SkinWindow(frame)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(self.BackdropMain)
        if frame.SetBackdropColor then frame:SetBackdropColor(0.07, 0.08, 0.10, 0.98) end
        if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.42, 0.35, 0.20, 1.0) end
    end
end

function RR.UI.Theme:SkinPanel(frame, bgAlpha)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(self.BackdropPanel)
        if frame.SetBackdropColor then frame:SetBackdropColor(0.03, 0.04, 0.05, bgAlpha or 0.95) end
        if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.18, 0.20, 0.25, 0.8) end
    end
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

    local plaqueTex = RR.ADDON_PATH .. "\\images\\art_header_plaque.tga"
    banner.pieces = self:Create3SlicePieces(banner, plaqueTex, 0.125, 23, "ARTWORK")

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

    local TINTS = {
        normal   = { 0.82, 0.82, 0.82 },
        hover    = { 1.00, 1.00, 1.00 },
        pressed  = { 0.58, 0.58, 0.58 },
        selected = { 1.00, 0.86, 0.45 },
    }

    btn.SetTint = function(button, state)
        local c = TINTS[state] or TINTS.normal
        for _, piece in pairs(button.art_pieces) do
            piece:SetVertexColor(c[1], c[2], c[3], 1)
        end
    end
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
    left:SetVertexColor(0.15, 0.15, 0.15, 0.95)

    local right = f:CreateTexture(nil, "BACKGROUND")
    right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    right:SetTexCoord(0.8046875, 1, 0, 1)
    right:SetSize(22, 34)
    right:SetPoint("TOPRIGHT", 12, 5)
    right:SetVertexColor(0.15, 0.15, 0.15, 0.95)

    local mid = f:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    mid:SetTexCoord(0.1953125, 0.8046875, 0, 1)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetHeight(34)
    mid:SetVertexColor(0.15, 0.15, 0.15, 0.95)

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
    return f
end
