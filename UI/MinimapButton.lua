-- ============================================================================
-- RecipeRadar: UI/MinimapButton.lua
-- Minimap launcher button via LibDataBroker-1.1 / LibDBIcon-1.0
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.MinimapButton = {}

local LDB_NAME = "RecipeRadar"

local function GetIconLib()
    return LibStub and LibStub("LibDBIcon-1.0", true)
end

function RR.UI.MinimapButton:Initialize()
    if self.dataObject then return end

    local icon = GetIconLib()
    local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
    if not icon or not ldb then return end

    self.dataObject = ldb:NewDataObject(LDB_NAME, {
        type = "launcher",
        icon = RR.ADDON_PATH .. "\\images\\minimap.tga",
        OnClick = function(_, button)
            if button == "LeftButton" then
                RR.UI.MainWindow:Toggle()
            elseif button == "RightButton" then
                if RR.UI.SettingsWindow then
                    RR.UI.SettingsWindow:Toggle()
                end
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:SetText(RR.COLORS.TITLE .. "RecipeRadar (v" .. RR.VERSION .. ")")
            tooltip:AddLine(" ")
            tooltip:AddLine(RR.COLORS.WHITE .. RR.L["TOOLTIP_TOGGLE"])
            tooltip:AddLine(RR.COLORS.WHITE .. RR.L["TOOLTIP_MINIMAP_RIGHTCLICK"])
            tooltip:AddLine(RR.COLORS.GREY .. RR.L["TOOLTIP_MINIMAP_DRAG"])
        end,
    })

    icon:Register(LDB_NAME, self.dataObject, RR.Config:GetProfile().minimap)
    self:UpdateVisibility()
end

function RR.UI.MinimapButton:UpdateVisibility()
    local icon = GetIconLib()
    if not self.dataObject or not icon then return end
    if RR.Config:IsMinimapButtonShown() then
        icon:Show(LDB_NAME)
    else
        icon:Hide(LDB_NAME)
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
    local icon = GetIconLib()
    if not self.dataObject or not icon then return end
    icon:Refresh(LDB_NAME, RR.Config:GetProfile().minimap)
end
