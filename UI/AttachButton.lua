-- ============================================================================
-- RecipeRadar: UI/AttachButton.lua
-- Draggable launch button attached to trade skill frames with reskin support
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.AttachButton = {}

function RR.UI.AttachButton:Initialize()
    if self.button then return end

    local btn = CreateFrame("Button", "RecipeRadarAttachButton", UIParent)
    btn:SetSize(32, 22)
    btn:SetFrameStrata("HIGH")
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("RightButton")

    RR.UI.Theme:SkinPanel(btn, 0.95)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER", 0, 0)
    btn.text:SetText(RR.COLORS.GOLD .. "RR")

    btn:SetScript("OnClick", function()
        RR.UI.MainWindow:Toggle()
    end)

    btn:SetScript("OnDragStart", function(selfBtn)
        selfBtn:StartMoving()
        selfBtn.isMoving = true
    end)

    btn:SetScript("OnDragStop", function(selfBtn)
        selfBtn:StopMovingOrSizing()
        selfBtn.isMoving = false
        local point, _, _, x, y = selfBtn:GetPoint()
        local profile = RR.Config:GetProfile()
        if profile and profile.buttonPosition then
            profile.buttonPosition.x = x
            profile.buttonPosition.y = y
            profile.buttonPosition.isCustom = true
        end
    end)

    btn:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
        GameTooltip:SetText(RR.COLORS.TITLE .. "RecipeRadar")
        GameTooltip:AddLine(RR.COLORS.WHITE .. "Left Click: Toggle RecipeRadar tracker")
        GameTooltip:AddLine(RR.COLORS.GREY .. "Right Drag: Move button position")
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.button = btn
    self:HookFrames()
end

function RR.UI.AttachButton:HookFrames()
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("TRADE_SKILL_SHOW")
    watcher:RegisterEvent("TRADE_SKILL_CLOSE")
    watcher:RegisterEvent("CRAFT_SHOW")
    watcher:RegisterEvent("CRAFT_CLOSE")

    watcher:SetScript("OnEvent", function(_, event)
        if event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
            self:PositionButton()
            self.button:Show()
        elseif event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" then
            self.button:Hide()
        end
    end)
end

function RR.UI.AttachButton:PositionButton()
    if not self.button then return end

    local parentFrame = nil
    local candidates = {
        "DragonflightUIProfessionFrame",
        "SkilletFrame",
        "TradeSkillFrame",
        "CraftFrame",
    }
    for _, name in ipairs(candidates) do
        local f = _G[name]
        if f and f:IsShown() then
            parentFrame = f
            break
        end
    end

    if not parentFrame then parentFrame = UIParent end

    local profile = RR.Config:GetProfile()
    local pos = profile.buttonPosition

    self.button:ClearAllPoints()
    if pos and pos.isCustom and pos.x and pos.y then
        self.button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    else
        self.button:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 4, -40)
    end
end
