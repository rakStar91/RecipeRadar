-- ============================================================================
-- RecipeRadar: UI/AttachButton.lua
-- Draggable launch button attached to trade skill frames with full DragonflightUI,
-- ElvUI, Skillet & Blizzard frame reskin compatibility & Dark Theme styling
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

    -- Create sleek dark-themed 3-slice button matching RecipeRadar's design
    local btn = RR.UI.Theme:CreateDarkButton(UIParent, "RR", 38, 22)
    btn:SetFrameStrata("DIALOG")
    btn:SetToplevel(true)
    btn:SetMovable(true)
    btn:SetClampedToScreen(true)
    btn:EnableMouse(true)
    btn:RegisterForDrag("LeftButton", "RightButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    if btn.text then
        btn.text:SetFontObject("GameFontNormalSmall")
        btn.text:SetTextColor(1, 0.82, 0, 1)
        btn.text:SetText("RR")
    end

    btn:SetScript("OnClick", function(selfBtn, mouseButton)
        if mouseButton == "RightButton" and IsShiftKeyDown() then
            RR.Config:ClearButtonOffset()
            RR.UI.AttachButton:PositionButton()
        else
            RR.UI.MainWindow:Toggle()
        end
    end)

    btn:SetScript("OnDragStart", function(selfBtn)
        selfBtn:StartMoving()
        selfBtn.isMoving = true
    end)

    btn:SetScript("OnDragStop", function(selfBtn)
        selfBtn:StopMovingOrSizing()
        selfBtn.isMoving = false

        local anchor = RR.UI.AttachButton.anchor_frame
        if anchor and anchor:GetLeft() and selfBtn:GetLeft() and anchor:GetTop() and selfBtn:GetTop() then
            local x = selfBtn:GetLeft() - anchor:GetLeft()
            local y = selfBtn:GetTop() - anchor:GetTop()
            RR.Config:SaveButtonOffset(x, y)
        end
        -- Re-anchor relative to craft window so it follows when the craft window is dragged
        RR.UI.AttachButton:PositionButton()
    end)

    btn:SetScript("OnEnter", function(selfBtn)
        if selfBtn.SetTint then selfBtn:SetTint("hover") end
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText(RR.COLORS.TITLE .. "RecipeRadar")
        GameTooltip:AddLine(RR.COLORS.WHITE .. (RR.L["TOOLTIP_TOGGLE"] or "Left Click: Toggle RecipeRadar"))
        GameTooltip:AddLine(RR.COLORS.GREY .. (RR.L["TOOLTIP_DRAG"] or "Drag: Move button position"))
        GameTooltip:AddLine(RR.COLORS.GREY .. "Shift + Right Click: Reset position")
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function(selfBtn)
        if selfBtn.SetTint then selfBtn:SetTint("normal") end
        GameTooltip:Hide()
    end)

    self.button = btn
    self:HookFrames()
end

--- Finds the craft / profession window actually visible on screen
function RR.UI.AttachButton:FindCraftWindow()
    -- 1. Explicit known frames
    for _, name in ipairs(CANDIDATE_FRAMES) do
        local f = _G[name]
        if f and f:IsShown() and (f:GetWidth() or 0) >= 50 then
            return f
        end
    end

    -- 2. Dynamic scan of UIParent children (matching robust window detection)
    local screen_width = UIParent:GetWidth() or 1024
    local screen_height = UIParent:GetHeight() or 768
    local max_width = screen_width * 0.85
    local max_height = screen_height * 0.95

    local best = nil
    local best_width = 0

    for _, child in ipairs({ UIParent:GetChildren() }) do
        local ok, forbidden = pcall(function() return child.IsForbidden and child:IsForbidden() end)
        if ok and not forbidden then
            local read_ok, name, width, height, shown = pcall(function()
                return (child.GetName and child:GetName()) or nil,
                       (child.GetWidth and child:GetWidth()) or 0,
                       (child.GetHeight and child:GetHeight()) or 0,
                       (child.IsShown and child:IsShown()) or false
            end)
            if read_ok and name and shown and width > best_width
                    and width >= 250 and width <= max_width
                    and height >= 200 and height <= max_height then
                local lowered = string.lower(name)
                if string.find(lowered, "tradeskill", 1, true)
                        or string.find(lowered, "profession", 1, true)
                        or string.find(lowered, "craft", 1, true) then
                    best, best_width = child, width
                end
            end
        end
    end
    return best
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
            if self.button then self.button:Show() end

            -- Asynchronous re-check for reskin addons like DragonflightUI that show their frame delayed
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function()
                    if self.button and self.button:IsShown() then
                        self:PositionButton()
                    end
                end)
                C_Timer.After(0.2, function()
                    if self.button and self.button:IsShown() then
                        self:PositionButton()
                    end
                end)
            end
        elseif event == "TRADE_SKILL_CLOSE" or event == "CRAFT_CLOSE" then
            if C_Timer and C_Timer.After then
                C_Timer.After(0.05, function()
                    if not self:FindCraftWindow() then
                        if self.button then self.button:Hide() end
                        if RR.UI.MainWindow and RR.UI.MainWindow.Hide then
                            RR.UI.MainWindow:Hide()
                        end
                    end
                end)
            else
                if not self:FindCraftWindow() then
                    if self.button then self.button:Hide() end
                    if RR.UI.MainWindow and RR.UI.MainWindow.Hide then
                        RR.UI.MainWindow:Hide()
                    end
                end
            end
        end
    end)

    -- 2. Direct OnShow / OnHide hooks on known candidate frames
    for _, name in ipairs(CANDIDATE_FRAMES) do
        local f = _G[name]
        if f and f.HookScript then
            f:HookScript("OnShow", function()
                self:PositionButton()
                if self.button then self.button:Show() end
            end)
            f:HookScript("OnHide", function()
                if not self:FindCraftWindow() then
                    if self.button then self.button:Hide() end
                    if RR.UI.MainWindow and RR.UI.MainWindow.Hide then
                        RR.UI.MainWindow:Hide()
                    end
                end
            end)
            f:HookScript("OnDragStop", function()
                if self.button and self.button:IsShown() then
                    self:PositionButton()
                end
            end)
        end
    end
end

function RR.UI.AttachButton:PositionButton()
    if not self.button then return end

    local parentFrame = self:FindCraftWindow()
    if not parentFrame or not parentFrame:IsVisible() or (parentFrame:GetWidth() or 0) < 50 then
        -- Fallback if no window is visible
        self.anchor_frame = nil
        self.button:ClearAllPoints()
        self.button:SetPoint("TOP", UIParent, "TOP", -200, -80)
        return
    end

    self.anchor_frame = parentFrame
    self.button:SetParent(UIParent)
    self.button:SetFrameStrata("DIALOG")
    self.button:SetToplevel(true)

    -- Hook events on the parent frame if not yet installed
    if not parentFrame.rr_hooks_installed then
        parentFrame.rr_hooks_installed = true
        parentFrame:HookScript("OnHide", function()
            if self.button then self.button:Hide() end
            if RR.UI.MainWindow and RR.UI.MainWindow.Hide then
                RR.UI.MainWindow:Hide()
            end
        end)
        parentFrame:HookScript("OnShow", function()
            if self.button then
                self:PositionButton()
                self.button:Show()
            end
        end)
        parentFrame:HookScript("OnDragStop", function()
            if self.button and self.button:IsShown() then
                self:PositionButton()
            end
        end)
    end

    self.button:ClearAllPoints()
    local offset = RR.Config:GetButtonOffset()
    if offset and type(offset.x) == "number" and type(offset.y) == "number" then
        self.button:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", offset.x, offset.y)
    else
        -- Default position beside the craft window top right
        self.button:SetPoint("TOPLEFT", parentFrame, "TOPRIGHT", 4, -40)
    end
end
