-- ============================================================================
-- RecipeRadar: UI/Theme.lua
-- 3-Slice Art Textures, Plaque Banner, Dark Buttons & Dropdown Frames
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

--- Creates the authentic 3-Slice Title Banner Plaque
function RR.UI.Theme:CreateTitlePlaque(parent, width, height, titleText)
    local banner = CreateFrame("Frame", nil, parent)
    banner:SetSize(width or 380, height or 44)

    local plaqueTex = RR.ADDON_PATH .. "\\images\\header_plaque.tga"

    local left = banner:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(plaqueTex)
    left:SetTexCoord(0, 0.125, 0, 1)
    left:SetSize(24, height or 44)
    left:SetPoint("LEFT", 0, 0)

    local right = banner:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(plaqueTex)
    right:SetTexCoord(0.875, 1, 0, 1)
    right:SetSize(24, height or 44)
    right:SetPoint("RIGHT", 0, 0)

    local mid = banner:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture(plaqueTex)
    mid:SetTexCoord(0.125, 0.875, 0, 1)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetHeight(height or 44)

    banner.text = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    banner.text:SetPoint("CENTER", 0, 2)
    banner.text:SetTextColor(1, 0.82, 0, 1)
    banner.text:SetText(titleText or RR.NAME)

    banner.SetTitle = function(selfB, newText)
        selfB.text:SetText(newText)
    end

    return banner
end

--- Creates the authentic 3-Slice Dark Button using button_blank texture
function RR.UI.Theme:CreateDarkButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    btn:SetSize(width or 80, height or 22)

    local btnTex = RR.ADDON_PATH .. "\\images\\button_blank.tga"

    local left = btn:CreateTexture(nil, "BACKGROUND")
    left:SetTexture(btnTex)
    left:SetTexCoord(0, 0.25, 0, 1)
    left:SetSize(12, height or 22)
    left:SetPoint("LEFT", 0, 0)

    local right = btn:CreateTexture(nil, "BACKGROUND")
    right:SetTexture(btnTex)
    right:SetTexCoord(0.75, 1, 0, 1)
    right:SetSize(12, height or 22)
    right:SetPoint("RIGHT", 0, 0)

    local mid = btn:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture(btnTex)
    mid:SetTexCoord(0.25, 0.75, 0, 1)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetHeight(height or 22)

    btn.pieces = { left, mid, right }

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(text or "")
    btn.text:SetTextColor(0.95, 0.90, 0.70, 1)

    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            for _, p in ipairs(self.pieces) do p:SetVertexColor(1.2, 1.2, 1.2, 1) end
            self.text:SetTextColor(1, 1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            for _, p in ipairs(self.pieces) do p:SetVertexColor(1, 1, 1, 1) end
            self.text:SetTextColor(0.95, 0.90, 0.70, 1)
        end
    end)

    btn.SetActive = function(self, active)
        self.isActive = active
        if active then
            for _, p in ipairs(self.pieces) do p:SetVertexColor(1.3, 1.0, 0.4, 1) end
            self.text:SetTextColor(1, 0.85, 0.2, 1)
        else
            for _, p in ipairs(self.pieces) do p:SetVertexColor(1, 1, 1, 1) end
            self.text:SetTextColor(0.95, 0.90, 0.70, 1)
        end
    end

    btn.SetLabel = function(self, newText)
        self.text:SetText(newText)
    end

    return btn
end

--- Creates the authentic WoW DropDown frame with 3-slice background and gold scroll down button
function RR.UI.Theme:CreateDropDownFrame(parent, width, titleText, onClick)
    local f = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    f:SetSize(width or 120, 22)

    local left = f:CreateTexture(nil, "BACKGROUND")
    left:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    left:SetTexCoord(0, 0.1953125, 0, 1)
    left:SetSize(20, 30)
    left:SetPoint("TOPLEFT", -10, 4)
    left:SetVertexColor(0.15, 0.15, 0.15, 0.9)

    local right = f:CreateTexture(nil, "BACKGROUND")
    right:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    right:SetTexCoord(0.8046875, 1, 0, 1)
    right:SetSize(20, 30)
    right:SetPoint("TOPRIGHT", 10, 4)
    right:SetVertexColor(0.15, 0.15, 0.15, 0.9)

    local mid = f:CreateTexture(nil, "BACKGROUND")
    mid:SetTexture("Interface\\Glues\\CharacterCreate\\CharacterCreate-LabelFrame")
    mid:SetTexCoord(0.1953125, 0.8046875, 0, 1)
    mid:SetPoint("LEFT", left, "RIGHT", 0, 0)
    mid:SetPoint("RIGHT", right, "LEFT", 0, 0)
    mid:SetHeight(30)
    mid:SetVertexColor(0.15, 0.15, 0.15, 0.9)

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
