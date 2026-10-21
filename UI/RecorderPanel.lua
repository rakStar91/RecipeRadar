-- ============================================================================
-- RecipeRadar: UI/RecorderPanel.lua
-- "Sources" tab of the settings window (WoW Forever only): switch recording on or off, see what was
-- recorded and copy the export. SettingsWindow adds the tab when this file is loaded.
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.RecorderPanel = {}

--- Builds the panel inside the settings content area. createCheckbox is the settings window's checkbox helper.
function RR.UI.RecorderPanel:Create(contentArea, createCheckbox)
    local L = RR.L
    local panel = CreateFrame("Frame", nil, contentArea)
    panel:SetAllPoints(contentArea)
    self.panel = panel

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText(L["REC_EXPORT_TITLE"])

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", 14, -34)
    desc:SetPoint("TOPRIGHT", -14, -34)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.85, 0.85, 0.85, 1)
    desc:SetText(L["SOURCES_DESC"])

    self.cbRecord = createCheckbox(panel, 14, -92, L["SOURCES_OPT_RECORD"], L["SOURCES_OPT_RECORD_DESC"],
        function(_, isChecked)
            RR.Recorder:SetEnabled(isChecked)
        end)

    self.status = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.status:SetPoint("TOPLEFT", 14, -162)
    self.status:SetTextColor(1, 0.82, 0, 1)

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 14, -186)
    hint:SetPoint("TOPRIGHT", -14, -186)
    hint:SetJustifyH("LEFT")
    hint:SetTextColor(0.75, 0.75, 0.75, 1)
    hint:SetText(L["REC_EXPORT_HINT"])

    local scroll = CreateFrame("ScrollFrame", "RecipeRadarExportScroll", panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 14, -222)
    scroll:SetPoint("BOTTOMRIGHT", -36, 52)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(0)
    edit:SetFontObject("ChatFontNormal")
    edit:SetWidth(500)
    edit:SetScript("OnEscapePressed", edit.ClearFocus)
    edit:SetScript("OnEditFocusGained", edit.HighlightText)
    -- read-only: typing puts the export text back
    edit:SetScript("OnTextChanged", function(selfEdit, userInput)
        if userInput and self.exportText then
            selfEdit:SetText(self.exportText)
            selfEdit:HighlightText()
        end
    end)
    scroll:SetScrollChild(edit)
    self.edit = edit

    local updateBtn = RR.UI.Theme:CreateDarkButton(panel, L["REC_REFRESH_BUTTON"], 150, 26)
    updateBtn:SetPoint("BOTTOMLEFT", 14, 14)
    updateBtn:SetScript("OnClick", function() panel:RefreshPanel() end)

    local clearBtn = RR.UI.Theme:CreateDarkButton(panel, L["REC_CLEAR_BUTTON"], 190, 26)
    clearBtn:SetPoint("LEFT", updateBtn, "RIGHT", 10, 0)
    clearBtn:SetScript("OnClick", function()
        RR.Recorder:Clear()
        panel:RefreshPanel()
    end)

    --- Called by the settings window whenever the tab is shown
    function panel:RefreshPanel()
        local owner = RR.UI.RecorderPanel
        owner.cbRecord:SetChecked(RR.Recorder:IsEnabled())
        owner.status:SetText(string.format(RR.L["REC_STATUS"], RR.Recorder:GetCounts()))
        owner.exportText = RR.Recorder:IsEmpty() and RR.L["REC_EMPTY"] or RR.Recorder:BuildExport()
        owner.edit:SetText(owner.exportText)
    end

    return panel
end

--- Focuses the export text so it can be copied right away (used by /rr export)
function RR.UI.RecorderPanel:FocusExport()
    if self.edit then
        self.edit:SetFocus()
        self.edit:HighlightText()
    end
end
