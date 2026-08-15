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

    btn:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            RR.UI.MainWindow:Toggle()
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
        GameTooltip:AddLine(RR.COLORS.WHITE .. "Left Click: Toggle RecipeRadar tracker")
        GameTooltip:AddLine(RR.COLORS.GREY .. "Left Drag: Move around minimap ring")
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.button = btn
    self:UpdatePosition()
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
