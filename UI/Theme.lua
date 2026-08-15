-- ============================================================================
-- RecipeRadar: UI/Theme.lua
-- Visual styling, Backdrop templates & color schemes
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.Theme = {}

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

--- Applies dark authentic styling to a frame
function RR.UI.Theme:SkinWindow(frame)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(self.BackdropMain)
        frame:SetBackdropColor(0.07, 0.08, 0.10, 0.96)
        frame:SetBackdropBorderColor(0.42, 0.35, 0.20, 1.0)
    end
end

--- Applies dark panel styling to a child frame
function RR.UI.Theme:SkinPanel(frame, bgAlpha)
    if not frame then return end
    if frame.SetBackdrop then
        frame:SetBackdrop(self.BackdropPanel)
        frame:SetBackdropColor(0.04, 0.05, 0.06, bgAlpha or 0.95)
        frame:SetBackdropBorderColor(0.18, 0.20, 0.25, 0.8)
    end
end

--- Creates a WoW-styled dark button
function RR.UI.Theme:CreateButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 80, height or 24)
    
    if btn.SetBackdrop then
        btn:SetBackdrop(self.BackdropPanel)
        btn:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
        btn:SetBackdropBorderColor(0.35, 0.30, 0.20, 0.9)
    end

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(text or "")
    btn.text:SetTextColor(0.95, 0.90, 0.70, 1)

    btn:SetScript("OnEnter", function(self)
        if not self.isActive then
            self:SetBackdropColor(0.20, 0.22, 0.28, 1)
            self.text:SetTextColor(1, 0.85, 0.2, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self.isActive then
            self:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
            self.text:SetTextColor(0.95, 0.90, 0.70, 1)
        end
    end)

    btn.SetActive = function(self, active)
        self.isActive = active
        if active then
            self:SetBackdropColor(0.30, 0.22, 0.08, 1)
            self:SetBackdropBorderColor(0.85, 0.70, 0.25, 1)
            self.text:SetTextColor(1, 0.85, 0.2, 1)
        else
            self:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
            self:SetBackdropBorderColor(0.35, 0.30, 0.20, 0.9)
            self.text:SetTextColor(0.95, 0.90, 0.70, 1)
        end
    end

    return btn
end
