-- ============================================================================
-- RecipeRadar: UI/Theme.lua
-- Visual styling, 3-Slice Art Textures, Plaque Title & Dropdown frames
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
        if frame.SetBackdropColor then frame:SetBackdropColor(0.07, 0.08, 0.10, 0.96) end
        if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.42, 0.35, 0.20, 1.0) end
    end
end

function RR.UI.Theme:SkinPanel(frame, bgAlpha)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(self.BackdropPanel)
        if frame.SetBackdropColor then frame:SetBackdropColor(0.04, 0.05, 0.06, bgAlpha or 0.95) end
        if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(0.18, 0.20, 0.25, 0.8) end
    end
end

--- Creates the authentic Title Banner Plaque
function RR.UI.Theme:CreateTitlePlaque(parent, width, height, titleText)
    local banner = CreateFrame("Frame", nil, parent)
    banner:SetSize(width or 360, height or 44)

    local left = banner:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(RR.ADDON_PATH .. "\\images\\art_header_plaque.tga")
    left:SetTexCoord(0, 0.125, 0, 1)
    left:SetSize(23, height or 44)
    left:SetPoint("LEFT", 0, 0)

    local right = banner:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(RR.ADDON_PATH .. "\\images\\art_header_plaque.tga")
    right:SetTexCoord(0.875, 1, 0, 1)
    right:SetSize(23, height or 44)
    right:SetPoint("RIGHT", 0, 0)

    local mid = banner:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture(RR.ADDON_PATH .. "\\images\\art_header_plaque.tga")
    mid:SetTexCoord(0.125, 0.875, 0, 1)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetHeight(height or 44)

    banner.text = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    banner.text:SetPoint("CENTER", 0, 2)
    banner.text:SetTextColor(1, 0.82, 0, 1)
    banner.text:SetText(titleText or RR.NAME)

    return banner
end

--- Creates an authentic WoW DropDown frame with 3-slice background and gold scroll down button
function RR.UI.Theme:CreateDropDownFrame(parent, width, titleText, onClick)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    f:SetSize(width or 120, 24)

    local left = f:CreateTexture(nil, "BACKGROUND")
    left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    left:SetTexCoord(0, 0.1953125, 0, 1)
    left:SetSize(20, 32)
    left:SetPoint("TOPLEFT", -12, 4)

    local right = f:CreateTexture(nil, "BACKGROUND")
    right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    right:SetTexCoord(0.8046875, 1, 0, 1)
    right:SetSize(20, 32)
    right:SetPoint("TOPRIGHT", 12, 4)

    local mid = f:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    mid:SetTexCoord(0.1953125, 0.8046875, 0, 1)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetHeight(32)

    local btn = CreateFrame("Button", nil, f)
    btn:SetSize(20, 20)
    btn:SetPoint("RIGHT", 4, 0)
    btn:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    btn:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
    btn:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight")
    btn:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", 4, 0)
    text:SetPoint("RIGHT", btn, "LEFT", -2, 0)
    text:SetJustifyH("LEFT")
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

--- Creates a WoW-styled dark button
function RR.UI.Theme:CreateButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width or 80, height or 22)
    btn:SetText(text or "")

    local font = btn:GetFontString()
    if font then
        font:SetFontObject("GameFontNormalSmall")
        font:SetTextColor(0.95, 0.90, 0.70, 1)
    end

    btn.SetActive = function(self, active)
        self.isActive = active
        local fs = self:GetFontString()
        if fs then
            if active then
                fs:SetTextColor(1, 0.85, 0.2, 1)
            else
                fs:SetTextColor(0.80, 0.80, 0.80, 1)
            end
        end
    end

    return btn
end
