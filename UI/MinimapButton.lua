-- ============================================================================
-- RecipeRadar: UI/MinimapButton.lua
-- Circular gold minimap button with dragging around minimap ring
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.MinimapButton = {}

function RR.UI.MinimapButton:Initialize()
    if self.button then return end

    local btn = CreateFrame("Button", "RecipeRadarMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameLevel(8)
    btn:SetToplevel(true)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    -- Overlay circular icon
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(RR.ADDON_PATH .. "\\images\\minimap.tga")
    btn.icon = icon

    -- Circular border ring
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border = border

    btn:SetScript("OnClick", function(selfBtn, button)
        if button == "LeftButton" then
            RR.UI.MainWindow:Toggle()
        elseif button == "RightButton" then
            RR.UI.MinimapButton:OpenContextMenu(selfBtn)
        end
    end)

    btn:SetScript("OnDragStart", function(selfBtn)
        selfBtn.isDragging = true
        selfBtn:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale

            local angle = math.deg(math.atan2(py - my, px - mx))
            if angle < 0 then angle = angle + 360 end

            local profile = RR.Config:GetProfile()
            if profile and profile.minimap then
                profile.minimap.angle = angle
            end
            RR.UI.MinimapButton:UpdatePosition()
        end)
    end)

    btn:SetScript("OnDragStop", function(selfBtn)
        selfBtn.isDragging = false
        selfBtn:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(RR.COLORS.TITLE .. "RecipeRadar (v" .. RR.VERSION .. ")")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(RR.COLORS.WHITE .. (RR.L["TOOLTIP_TOGGLE"] or "Left Click: Toggle RecipeRadar tracker"))
        GameTooltip:AddLine(RR.COLORS.WHITE .. (RR.L["TOOLTIP_MINIMAP_RIGHTCLICK"] or "Right Click: Options"))
        GameTooltip:AddLine(RR.COLORS.GREY .. (RR.L["TOOLTIP_MINIMAP_DRAG"] or "Left Drag: Move around minimap"))
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.button = btn
    self:UpdatePosition()
    self:UpdateVisibility()
end

function RR.UI.MinimapButton:OpenContextMenu(anchorBtn)
    if not RR.UI.Dropdown then return end

    local menu = {
        {
            text = RR.COLORS.TITLE .. "RecipeRadar (v" .. RR.VERSION .. ")",
            isHeader = true,
        },
        {
            text = RR.L["MENU_HIDE_MINIMAP"] or "Hide Minimap Button",
            icon = "Interface\\Icons\\Spell_ChargeNegative",
            func = function()
                RR.UI.MinimapButton:SetShown(false)
                print(RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE .. (RR.L["CMD_MINIMAP_HIDDEN"] or "Minimap button is now hidden. Type '/rr minimap' to show it again."))
            end,
        },
    }

    RR.UI.Dropdown:Show(anchorBtn or self.button, menu)
end

function RR.UI.MinimapButton:UpdateVisibility()
    if not self.button then return end
    if RR.Config:IsMinimapButtonShown() then
        self.button:Show()
    else
        self.button:Hide()
    end
end

function RR.UI.MinimapButton:SetShown(show)
    RR.Config:SetMinimapButtonShown(show)
    self:UpdateVisibility()
end

function RR.UI.MinimapButton:Toggle()
    local isShown = RR.Config:ToggleMinimapButton()
    self:UpdateVisibility()
    return isShown
end

function RR.UI.MinimapButton:UpdatePosition()
    if not self.button then return end
    local profile = RR.Config:GetProfile()
    local angle = (profile and profile.minimap and profile.minimap.angle) or 220
    local rad = math.rad(angle)

    local radius = 80
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius

    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

