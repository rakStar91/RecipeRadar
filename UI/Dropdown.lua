-- ============================================================================
-- RecipeRadar: UI/Dropdown.lua
-- Standalone reusable custom dropdown popup with mousewheel scrolling & multi-select
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.Dropdown = {}

local dropdownPopup = nil

function RR.UI.Dropdown:GetPopupFrame()
    if not dropdownPopup then
        dropdownPopup = CreateFrame("Frame", "RecipeRadarDropdownPopup", UIParent, BackdropTemplateMixin and "BackdropTemplate")
        dropdownPopup:SetFrameStrata("TOOLTIP")
        dropdownPopup:SetClampedToScreen(true)
        RR.UI.Theme:SkinWindow(dropdownPopup)
        dropdownPopup:Hide()

        dropdownPopup.buttons = {}

        local scrollFrame = CreateFrame("ScrollFrame", "RecipeRadarDropdownScroll", dropdownPopup)
        scrollFrame:SetPoint("TOPLEFT", 4, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)
        dropdownPopup.scrollFrame = scrollFrame

        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(100, 100)
        scrollFrame:SetScrollChild(scrollChild)
        dropdownPopup.scrollChild = scrollChild

        -- ScrollBar slider
        local scrollBar = CreateFrame("Slider", "RecipeRadarDropdownScrollBar", dropdownPopup, BackdropTemplateMixin and "BackdropTemplate")
        scrollBar:SetWidth(10)
        scrollBar:SetPoint("TOPRIGHT", -4, -4)
        scrollBar:SetPoint("BOTTOMRIGHT", -4, 4)
        RR.UI.Theme:SkinPanel(scrollBar, 0.8)
        scrollBar:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
        scrollBar:SetOrientation("VERTICAL")
        scrollBar:SetMinMaxValues(0, 100)
        scrollBar:SetValue(0)
        scrollBar:SetValueStep(22)
        scrollBar:SetScript("OnValueChanged", function(selfSB, val)
            scrollFrame:SetVerticalScroll(val)
        end)
        dropdownPopup.scrollBar = scrollBar

        local function onMouseWheel(selfF, delta)
            if not scrollBar:IsShown() then return end
            local current = scrollBar:GetValue() or 0
            local minVal, maxVal = scrollBar:GetMinMaxValues()
            local step = 22 * 2
            if delta < 0 then
                scrollBar:SetValue(math.min(maxVal, current + step))
            else
                scrollBar:SetValue(math.max(minVal, current - step))
            end
        end
        dropdownPopup.onMouseWheel = onMouseWheel

        dropdownPopup:EnableMouseWheel(true)
        dropdownPopup:SetScript("OnMouseWheel", onMouseWheel)
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", onMouseWheel)
        scrollChild:EnableMouseWheel(true)
        scrollChild:SetScript("OnMouseWheel", onMouseWheel)

        local clickWatcher = CreateFrame("Frame", nil, dropdownPopup)
        clickWatcher:SetScript("OnUpdate", function()
            if dropdownPopup:IsShown() and not dropdownPopup:IsMouseOver() and (not dropdownPopup.currentAnchor or not dropdownPopup.currentAnchor:IsMouseOver()) then
                if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
                    dropdownPopup:Hide()
                end
            end
        end)
    end
    return dropdownPopup
end

--- Shows or toggles the popup menu anchored to anchorBtn with given items
function RR.UI.Dropdown:Show(anchorBtn, items)
    local popup = self:GetPopupFrame()

    if popup:IsShown() and popup.currentAnchor == anchorBtn then
        popup:Hide()
        return
    end

    popup.currentAnchor = anchorBtn
    popup:ClearAllPoints()
    popup:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -2)

    local maxWidth = (anchorBtn:GetWidth() or 120) + 20
    local itemHeight = 22
    local count = #items
    local maxVisible = 14
    local visibleCount = math.min(count, maxVisible)
    local totalContentHeight = count * itemHeight
    local viewHeight = visibleCount * itemHeight
    local needsScroll = count > maxVisible

    for i, itm in ipairs(items) do
        local btn = popup.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, popup.scrollChild, BackdropTemplateMixin and "BackdropTemplate")
            btn:SetHeight(itemHeight)
            RR.UI.Theme:SkinPanel(btn, 0.6)

            btn.icon = btn:CreateTexture(nil, "OVERLAY")
            btn.icon:SetSize(16, 16)
            btn.icon:SetPoint("LEFT", 6, 0)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.text:SetPoint("LEFT", 26, 0)
            btn.text:SetPoint("RIGHT", -22, 0)
            btn.text:SetJustifyH("LEFT")

            btn.check = btn:CreateTexture(nil, "OVERLAY")
            btn.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            btn.check:SetSize(16, 16)
            btn.check:SetPoint("RIGHT", -4, 0)

            btn:SetScript("OnEnter", function(selfB)
                if selfB.SetBackdropColor then selfB:SetBackdropColor(0.25, 0.28, 0.35, 1) end
            end)
            btn:SetScript("OnLeave", function(selfB)
                if selfB.SetBackdropColor then selfB:SetBackdropColor(0.04, 0.05, 0.06, 0.6) end
            end)
            btn:EnableMouseWheel(true)
            btn:SetScript("OnMouseWheel", function(selfB, delta)
                if popup and popup.onMouseWheel then
                    popup.onMouseWheel(selfB, delta)
                end
            end)

            popup.buttons[i] = btn
        end

        btn.text:SetText(itm.text)

        if itm.icon then
            btn.icon:SetTexture(itm.icon)
            btn.icon:Show()
            btn.text:SetPoint("LEFT", 26, 0)
        else
            btn.icon:Hide()
            btn.text:SetPoint("LEFT", 8, 0)
        end

        local strWidth = (btn.text:GetStringWidth() or 80) + 50
        if strWidth > maxWidth then maxWidth = strWidth end

        if itm.checked then
            btn.check:Show()
            btn.text:SetTextColor(1, 0.82, 0, 1)
        else
            btn.check:Hide()
            btn.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end

        btn:SetScript("OnClick", function()
            popup:Hide()
            if itm.func then itm.func() end
        end)
        btn:Show()
    end

    for i = count + 1, #popup.buttons do
        popup.buttons[i]:Hide()
    end

    -- Update scroll child width and button widths
    local childWidth = maxWidth
    popup.scrollChild:SetSize(childWidth, totalContentHeight)
    for i = 1, count do
        local btn = popup.buttons[i]
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", popup.scrollChild, "TOPLEFT", 0, -((i - 1) * itemHeight))
        btn:SetSize(childWidth, itemHeight)
    end

    popup.scrollFrame:ClearAllPoints()
    if needsScroll then
        popup.scrollFrame:SetPoint("TOPLEFT", 4, -4)
        popup.scrollFrame:SetPoint("BOTTOMRIGHT", -16, 4)
        popup.scrollBar:Show()
        local maxScroll = math.max(0, totalContentHeight - viewHeight)
        popup.scrollBar:SetMinMaxValues(0, maxScroll)
        popup.scrollBar:SetValue(0)
    else
        popup.scrollFrame:SetPoint("TOPLEFT", 4, -4)
        popup.scrollFrame:SetPoint("BOTTOMRIGHT", -4, 4)
        popup.scrollBar:Hide()
        popup.scrollFrame:SetVerticalScroll(0)
    end

    local finalPopupWidth = maxWidth + (needsScroll and 20 or 8)
    local finalPopupHeight = viewHeight + 8

    popup:SetSize(finalPopupWidth, finalPopupHeight)
    popup:Show()
end

function RR.UI.Dropdown:Hide()
    if dropdownPopup then
        dropdownPopup:Hide()
    end
end
