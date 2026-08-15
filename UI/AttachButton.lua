-- ============================================================================
-- RecipeRadar: UI/AttachButton.lua
-- Draggable launch button attached to trade skill frames with full DragonflightUI,
-- ElvUI, Skillet & Blizzard frame reskin compatibility
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.AttachButton = {}

local CANDIDATE_FRAMES = {
    "DragonflightUIProfessionFrame",
    "DragonflightUIRetailProfessionFrame",
    "SkilletFrame",
    "MRTF_TradeSkillFrame",
    "TradeSkillFrame",
    "CraftFrame",
}

function RR.UI.AttachButton:Initialize()
    if self.button then return end

    local btn = CreateFrame("Button", "RecipeRadarAttachButton", UIParent, BackdropTemplateMixin and "BackdropTemplate")
    btn:SetSize(32, 22)
    btn:SetFrameStrata("HIGH")
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
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
        local x, y = selfBtn:GetCenter()
        local profile = RR.Config:GetProfile()
        if profile and profile.buttonPosition and x and y then
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

--- Returns the currently visible parent profession window (DragonflightUI, Skillet or Blizzard)
function RR.UI.AttachButton:GetVisibleParentFrame()
    for _, name in ipairs(CANDIDATE_FRAMES) do
        local f = _G[name]
        if f and f:IsVisible() then
            return f
        end
    end
    return nil
end

function RR.UI.AttachButton:HookFrames()
    -- 1. Event watcher
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("TRADE_SKILL_SHOW")
    watcher:RegisterEvent("TRADE_SKILL_CLOSE")
    watcher:RegisterEvent("CRAFT_SHOW")
    watcher:RegisterEvent("CRAFT_CLOSE")

    watcher:SetScript("OnEvent", function(_, event)
        if event == "TRADE_SKILL_SHOW" or event == "CRAFT_SHOW" then
            self:PositionButton()
            self.button:Show()

            -- DragonflightUI might render a split-second later
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function()
                    if self.button:IsShown() then
                        self:PositionButton()
                    end
                end)
            end
        elseif event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" then
            -- Small delay check to confirm if another candidate (like DragonflightUI) is still open
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function()
                    if not self:GetVisibleParentFrame() then
                        self.button:Hide()
                    end
                end)
            else
                self.button:Hide()
            end
        end
    end)

    -- 2. Direct OnShow / OnHide hooks on known addon candidate frames
    for _, name in ipairs(CANDIDATE_FRAMES) do
        local f = _G[name]
        if f and f.HookScript then
            f:HookScript("OnShow", function()
                self:PositionButton()
                self.button:Show()
            end)
            f:HookScript("OnHide", function()
                if not self:GetVisibleParentFrame() then
                    self.button:Hide()
                end
            end)
        end
    end
end

function RR.UI.AttachButton:PositionButton()
    if not self.button then return end

    local parentFrame = self:GetVisibleParentFrame() or UIParent
    local profile = RR.Config:GetProfile()
    local pos = profile.buttonPosition

    self.button:ClearAllPoints()
    if pos and pos.isCustom and pos.x and pos.y then
        self.button:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    else
        if parentFrame and parentFrame ~= UIParent then
            self.button:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 4, -40)
        else
            self.button:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
        end
    end
end
