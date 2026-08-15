-- ============================================================================
-- RecipeRadar: UI/RecipeList.lua
-- Left column scrollable recipe list table with zebra shading & source icons
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.RecipeList = {}

local NUM_VISIBLE_ROWS = 19
local ROW_HEIGHT = 20

function RR.UI.RecipeList:Create(parent, onSelectRecipe)
    local listPane = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    listPane:SetPoint("TOPLEFT", 8, -134)
    listPane:SetPoint("BOTTOMLEFT", 8, 32)
    listPane:SetWidth(434)
    RR.UI.Theme:SkinPanel(listPane, 0.95)

    local instance = {
        frame = listPane,
        onSelectRecipe = onSelectRecipe,
        rows = {},
        scrollOffset = 0,
        currentList = {},
        selectedRecipeId = nil,
    }

    for i = 1, NUM_VISIBLE_ROWS do
        local row = CreateFrame("Button", nil, listPane, BackdropTemplateMixin and "BackdropTemplate")
        row:SetPoint("TOPLEFT", 4, -((i - 1) * ROW_HEIGHT + 4))
        row:SetPoint("TOPRIGHT", -22, -((i - 1) * ROW_HEIGHT + 4))
        row:SetHeight(ROW_HEIGHT)

        -- Alternating zebra background
        row.row_bg = row:CreateTexture(nil, "BACKGROUND")
        row.row_bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        row.row_bg:SetAllPoints(row)
        if i % 2 == 0 then
            row.row_bg:SetVertexColor(1, 1, 1, 0.055)
        else
            row.row_bg:SetVertexColor(1, 1, 1, 0)
        end

        -- Selected highlight texture
        row.selected_bg = row:CreateTexture(nil, "BORDER")
        row.selected_bg:SetTexture(RR.ADDON_PATH .. "\\images\\fill_row_selected.tga")
        row.selected_bg:SetAllPoints(row)
        row.selected_bg:Hide()

        -- Hover highlight
        row:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        local hl = row:GetHighlightTexture()
        if hl then hl:SetVertexColor(1, 1, 1, 0.10) end

        -- Text: [Skill] Recipe Name
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 6, 0)
        row.text:SetPoint("RIGHT", -56, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWordWrap(false)

        -- Dedicated fixed column slots for Sources and Faction
        row.iconSource1 = row:CreateTexture(nil, "OVERLAY")
        row.iconSource1:SetSize(14, 14)
        row.iconSource1:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.iconSource1:Hide()

        row.iconSource2 = row:CreateTexture(nil, "OVERLAY")
        row.iconSource2:SetSize(14, 14)
        row.iconSource2:SetPoint("RIGHT", row.iconSource1, "LEFT", -2, 0)
        row.iconSource2:Hide()

        row.iconSource3 = row:CreateTexture(nil, "OVERLAY")
        row.iconSource3:SetSize(14, 14)
        row.iconSource3:SetPoint("RIGHT", row.iconSource2, "LEFT", -2, 0)
        row.iconSource3:Hide()

        -- Faction Icon ALWAYS to the left of source icons
        row.iconFaction = row:CreateTexture(nil, "OVERLAY")
        row.iconFaction:SetSize(14, 14)
        row.iconFaction:SetPoint("RIGHT", row.iconSource3, "LEFT", -4, 0)
        row.iconFaction:Hide()

        -- Hover Tooltip showing Source and Faction restriction
        row:SetScript("OnEnter", function(selfR)
            if selfR.recipeData then
                GameTooltip:SetOwner(selfR, "ANCHOR_RIGHT")
                GameTooltip:AddLine(selfR.recipeData.name or "Rezept", 1, 0.82, 0)
                if selfR.sourceTooltipSources and selfR.sourceTooltipSources ~= "" then
                    GameTooltip:AddLine(RR.L["LABEL_SOURCE_COLON"] .. " " .. selfR.sourceTooltipSources, 1, 1, 1)
                end
                if selfR.sourceTooltipFaction and selfR.sourceTooltipFaction ~= "" then
                    GameTooltip:AddLine(RR.L["DROPDOWN_FACTION"] .. ": " .. selfR.sourceTooltipFaction, 1, 1, 1)
                end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        row:SetScript("OnClick", function(selfRow, mouseButton)
            if selfRow.recipeData then
                local data = selfRow.recipeData.data
                local spellId = data and data.id
                local itemId = data and (data.item_id or (data.items and data.items[1]) or (spellId and RR.DB and RR.DB:GetCraftedItemId(spellId)))
                local itemLink = nil
                if itemId and itemId > 0 then
                    local _, link = GetItemInfo(itemId)
                    itemLink = link
                end
                if not itemLink and spellId and spellId > 0 and GetSpellLink then
                    itemLink = GetSpellLink(spellId)
                end

                if itemLink and (IsModifiedClick("CHATLINK") or IsShiftKeyDown()) then
                    if ChatEdit_InsertLink then ChatEdit_InsertLink(itemLink) end
                    return
                elseif itemLink and (IsModifiedClick("DRESSUP") or IsControlKeyDown()) then
                    if DressUpItemLink then DressUpItemLink(itemLink) end
                    return
                end

                if instance.onSelectRecipe then
                    instance.onSelectRecipe(selfRow.recipeData)
                end
            end
        end)

        instance.rows[i] = row
    end

    -- Scrollbar for list
    instance.scrollOffset = 0
    listPane.SetVerticalScroll = function() end
    local scrollbar = CreateFrame("Slider", "RecipeRadarScroll", listPane, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPRIGHT", -4, -18)
    scrollbar:SetPoint("BOTTOMRIGHT", -4, 18)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function(_, val)
        instance.scrollOffset = math.floor(val or 0)
        if instance.Render then
            instance:Render()
        end
    end)
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValue(0)
    scrollbar:SetValueStep(1)
    instance.scrollbar = scrollbar

    listPane:EnableMouseWheel(true)
    listPane:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollbar:GetValue()
        scrollbar:SetValue(cur - (delta * 2))
    end)

    function instance:Render(recipeList, selectedId)
        if recipeList then
            self.currentList = recipeList
            local maxScroll = math.max(0, #recipeList - NUM_VISIBLE_ROWS)
            self.scrollbar:SetMinMaxValues(0, maxScroll)
            if self.scrollOffset > maxScroll then self.scrollOffset = maxScroll end
        end
        if selectedId ~= nil then
            self.selectedRecipeId = selectedId
        end

        local filtered = self.currentList or {}
        local offset = self.scrollOffset or 0

        local iconMap = {
            trainer = "Interface\\Icons\\INV_Misc_Book_09",
            vendor  = "Interface\\Icons\\INV_Misc_Coin_01",
            drop    = "Interface\\GossipFrame\\VendorGossipIcon",
            quest   = "Interface\\GossipFrame\\AvailableQuestIcon",
            holiday = "Interface\\Icons\\INV_Misc_Gift_01",
            object  = "Interface\\Icons\\INV_Box_01",
        }

        for i = 1, NUM_VISIBLE_ROWS do
            local row = self.rows[i]
            local dataIndex = offset + i

            if dataIndex <= #filtered then
                local item = filtered[dataIndex]
                row.recipeData = item
                local rData = item.data or {}

                -- Skill bracket colored + Name
                local skillColor = "|cff00ff00" -- Green
                if not item.isKnown then skillColor = "|cff44ff44" end
                row.text:SetText(string.format("%s[%d]|r %s", skillColor, item.skillReq or 1, item.name))

                if item.isKnown then
                    row.text:SetTextColor(0.18, 0.83, 0.75, 1) -- Cyan / Turquoise
                else
                    row.text:SetTextColor(0.95, 0.95, 0.95, 1)
                end

                -- Acquisition metadata
                local meta = RR.DB:GetRecipeAcquisitionMetadata(rData)

                local sources = {}
                local sourceLabels = {}
                if meta.sourceTypes["vendor"] then
                    table.insert(sources, "vendor")
                    table.insert(sourceLabels, RR.L["SOURCE_VENDOR"])
                end
                if meta.sourceTypes["drop"] then
                    table.insert(sources, "drop")
                    table.insert(sourceLabels, RR.L["SOURCE_DROP"])
                end
                if meta.sourceTypes["quest"] then
                    table.insert(sources, "quest")
                    table.insert(sourceLabels, RR.L["SOURCE_QUEST"])
                end
                if meta.sourceTypes["trainer"] then
                    table.insert(sources, "trainer")
                    table.insert(sourceLabels, RR.L["SOURCE_TRAINER"])
                end
                if meta.sourceTypes["holiday"] then
                    table.insert(sources, "holiday")
                    table.insert(sourceLabels, RR.L["SOURCE_HOLIDAY"])
                end
                if meta.sourceTypes["object"] then
                    table.insert(sources, "object")
                    table.insert(sourceLabels, RR.L["SOURCE_OBJECT"])
                end

                if #sources == 0 then
                    table.insert(sources, "trainer")
                    table.insert(sourceLabels, RR.L["SOURCE_TRAINER"])
                end

                -- Faction restriction & placement
                local hasAlliance = meta.factions["Alliance"]
                local hasHorde = meta.factions["Horde"]
                local factionText = RR.L["FACTION_ALL"]
                local factionColor = "|cffffff00"

                if hasAlliance and not hasHorde then
                    factionText = RR.L["FACTION_ALLIANCE_ONLY"]
                    factionColor = "|cff0070dd"
                    row.iconFaction:SetTexture(RR.ADDON_PATH .. "\\images\\alliance.tga")
                    row.iconFaction:Show()
                elseif hasHorde and not hasAlliance then
                    factionText = RR.L["FACTION_HORDE_ONLY"]
                    factionColor = "|cffff2020"
                    row.iconFaction:SetTexture(RR.ADDON_PATH .. "\\images\\horde.tga")
                    row.iconFaction:Show()
                else
                    row.iconFaction:Hide()
                end

                -- Render Source Icons flush on the right
                if sources[1] and iconMap[sources[1]] then
                    row.iconSource1:SetTexture(iconMap[sources[1]])
                    row.iconSource1:Show()
                else
                    row.iconSource1:Hide()
                end

                if sources[2] and iconMap[sources[2]] then
                    row.iconSource2:SetTexture(iconMap[sources[2]])
                    row.iconSource2:Show()
                else
                    row.iconSource2:Hide()
                end

                if sources[3] and iconMap[sources[3]] then
                    row.iconSource3:SetTexture(iconMap[sources[3]])
                    row.iconSource3:Show()
                else
                    row.iconSource3:Hide()
                end

                -- Text padding
                row.text:SetPoint("RIGHT", row, "RIGHT", -68, 0)

                row.sourceTooltipSources = table.concat(sourceLabels, ", ")
                row.sourceTooltipFaction = factionColor .. factionText .. "|r"

                -- Selected highlight
                if self.selectedRecipeId and self.selectedRecipeId == item.id then
                    row.selected_bg:Show()
                else
                    row.selected_bg:Hide()
                end

                row:Show()
            else
                row.recipeData = nil
                row.selected_bg:Hide()
                row.iconSource1:Hide(); row.iconSource2:Hide(); row.iconSource3:Hide(); row.iconFaction:Hide()
                row:Hide()
            end
        end
    end

    return instance
end
