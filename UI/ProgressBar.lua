-- ============================================================================
-- RecipeRadar: UI/ProgressBar.lua
-- Footer progress bar displaying learned/missing recipe stats
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.ProgressBar = {}

function RR.UI.ProgressBar:Create(parent)
    local footer = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", 8, 6)
    footer:SetPoint("BOTTOMRIGHT", -8, 6)
    footer:SetHeight(24)
    RR.UI.Theme:SkinPanel(footer, 0.98)

    local bar = CreateFrame("StatusBar", nil, footer, BackdropTemplateMixin and "BackdropTemplate")
    bar:SetAllPoints(footer)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(0.12, 0.45, 0.20, 1)

    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER", 0, 0)
    text:SetText(string.format(RR.L["PROGRESS_MISSING_FORMAT"], 0, 0))

    local instance = {
        frame = footer,
        bar = bar,
        text = text,
    }

    function instance:SetProgress(curMode, count, total)
        self.bar:SetMinMaxValues(0, total)
        if curMode == "known" then
            self.bar:SetValue(count)
            self.text:SetText(string.format(RR.L["PROGRESS_KNOWN_FORMAT"], count, total))
        else
            self.bar:SetValue(count)
            self.text:SetText(string.format(RR.L["PROGRESS_MISSING_FORMAT"], count, total))
        end
    end

    return instance
end
