-- ============================================================================
-- RecipeRadar: UI/DetailPane.lua
-- Right column recipe details: Attributes, Sources, TomTom & Alt Tracker
-- ============================================================================

local RR = RecipeRadar
RR.UI = RR.UI or {}
RR.UI.DetailPane = {}

function RR.UI.DetailPane:Create(parent)
    local instance = {
        attrRows = {},
        sourceRows = {},
        selectedRecipe = nil,
    }

    -- 4. Right Column: Details Pane (Authentic Key-Value Grid)
    local detailPane = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
    detailPane:SetPoint("TOPLEFT", 448, -134)
    detailPane:SetPoint("BOTTOMRIGHT", -8, 32)
    RR.UI.Theme:SkinPanel(detailPane, 0.95)
    instance.detailPane = detailPane

    local attrBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    attrBox:SetPoint("TOPLEFT", 6, -6)
    attrBox:SetPoint("TOPRIGHT", -6, -6)
    attrBox:SetHeight(270)
    RR.UI.Theme:SkinPanel(attrBox, 0.7)
    instance.attrBox = attrBox

    instance.detailFactionIcon = attrBox:CreateTexture(nil, "OVERLAY")
    instance.detailFactionIcon:SetSize(28, 28)
    instance.detailFactionIcon:SetPoint("TOPRIGHT", -8, -8)

    instance.attrRows = {}
    local attrKeys = {
        RR.L["LABEL_NAME"],
        RR.L["LABEL_PHASE"],
        RR.L["LABEL_MIN_SKILL"],
        RR.L["LABEL_NEEDS_REP"],
        RR.L["LABEL_SPECIALISATION"],
        RR.L["LABEL_HOLIDAY"],
        RR.L["LABEL_PRICE"],
    }
    local attrY = -6
    for i, labelText in ipairs(attrKeys) do
        local rowF = CreateFrame(i == 1 and "Button" or "Frame", nil, attrBox)
        rowF:SetPoint("TOPLEFT", attrBox, "TOPLEFT", 8, attrY)
        rowF:SetPoint("TOPRIGHT", attrBox, "TOPRIGHT", -8, attrY)
        rowF:SetHeight(13)
        rowF:EnableMouse(true)

        local lbl = rowF:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", 0, 0)
        lbl:SetTextColor(1, 0.82, 0, 1)
        lbl:SetText(labelText)

        local val = rowF:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        val:SetPoint("TOPLEFT", 135, 0)
        val:SetPoint("TOPRIGHT", (i <= 2) and -32 or 0, 0)
        val:SetJustifyH("LEFT")
        val:SetTextColor(1, 1, 1, 1)
        val:SetWordWrap(false)
        val:SetText("-")

        rowF.label = lbl
        rowF.value = val

        if i == 1 then
            -- Interactive Item Tooltip on Hover for Recipe / Item Name
            rowF:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            rowF:SetScript("OnEnter", function(selfBtn)
                local rec = instance.selectedRecipe
                if not rec or not rec.data then return end
                local data = rec.data
                local spellId = data.id or rec.id
                local craftedId = spellId and RR.DB and RR.DB:GetCraftedItemId(spellId)
                local itemId = data.item_id or (data.items and data.items[1]) or craftedId

                if RR.Debug then
                    local recName = data.name and RR.DB:GetLocalizedText(data.name) or "Unknown"
                    print(string.format("|cff00ccff[RecipeRadar Debug]|r Hover: Recipe='%s' | SpellID=%s | CraftedID=%s | FinalItemID=%s", tostring(recName), tostring(spellId), tostring(craftedId), tostring(itemId)))
                end

                GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()

                local shown = false
                if itemId and itemId > 0 then
                    local ok = pcall(function()
                        GameTooltip:SetHyperlink("item:" .. itemId)
                    end)
                    if ok then shown = true end
                end

                if not shown and spellId and spellId > 0 then
                    local ok = pcall(function()
                        GameTooltip:SetHyperlink("spell:" .. spellId)
                    end)
                    if ok then shown = true end
                end

                -- Ensure no unwanted spell icon or placeholder texture (e.g. Samwise face) is displayed
                for k = 1, 10 do
                    local tex = _G["GameTooltipTexture" .. k]
                    if tex then
                        tex:SetTexture(nil)
                        tex:Hide()
                    end
                end
                if GameTooltip.Icon then
                    GameTooltip.Icon:SetTexture(nil)
                    GameTooltip.Icon:Hide()
                end
                if GameTooltip.icon then
                    GameTooltip.icon:SetTexture(nil)
                    GameTooltip.icon:Hide()
                end
                for _, region in ipairs({GameTooltip:GetRegions()}) do
                    if region and region:GetObjectType() == "Texture" then
                        local tex = region:GetTexture()
                        if tex and (type(tex) == "string" and (string.find(tex, "INV_Misc_QuestionMark") or string.find(tex, "Temp") or string.find(tex, "Spell_Shadow_DeathCoil") or string.find(tex, "134400")) or type(tex) == "number" and tex == 134400) then
                            region:SetTexture(nil)
                            region:Hide()
                        end
                    end
                end

                if shown then
                    GameTooltip:Show()
                    if selfBtn.value then
                        selfBtn.value:SetTextColor(1, 0.85, 0.2, 1)
                    end
                else
                    GameTooltip:Hide()
                end
            end)

            rowF:SetScript("OnLeave", function(selfBtn)
                GameTooltip:Hide()
                if selfBtn.value then
                    selfBtn.value:SetTextColor(1, 1, 1, 1)
                end
            end)

            rowF:SetScript("OnClick", function(selfBtn, mouseButton)
                local rec = instance.selectedRecipe
                if not rec or not rec.data then return end
                local data = rec.data
                local spellId = data.id or rec.id
                local itemId = data.item_id or (data.items and data.items[1]) or (spellId and RR.DB and RR.DB:GetCraftedItemId(spellId))

                local itemLink = nil
                if itemId and itemId > 0 then
                    local _, link = GetItemInfo(itemId)
                    itemLink = link or ("item:" .. itemId)
                end
                if not itemLink and spellId and spellId > 0 and GetSpellLink then
                    itemLink = GetSpellLink(spellId)
                end

                if itemLink then
                    if IsModifiedClick("CHATLINK") or IsShiftKeyDown() then
                        if ChatEdit_InsertLink then
                            ChatEdit_InsertLink(itemLink)
                        end
                    elseif IsModifiedClick("DRESSUP") or IsControlKeyDown() then
                        if DressUpItemLink then
                            DressUpItemLink(itemLink)
                        end
                    end
                end
            end)
        end

        table.insert(instance.attrRows, rowF)
        attrY = attrY - 14
    end

    -- "Learnable from:" Header
    local srcHeader = attrBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    srcHeader:SetPoint("TOPLEFT", attrBox, "TOPLEFT", 8, attrY - 4)
    srcHeader:SetTextColor(1, 0.82, 0, 1)
    srcHeader:SetText(RR.L["LABEL_LEARNABLE_BY"])
    instance.srcHeader = srcHeader

    -- Scrollable frame for sources to prevent overflow into Alt character status
    local srcScrollFrame = CreateFrame("ScrollFrame", "RecipeRadarSourceScroll", attrBox)
    srcScrollFrame:SetPoint("TOPLEFT", attrBox, "TOPLEFT", 6, attrY - 20)
    srcScrollFrame:SetPoint("BOTTOMRIGHT", attrBox, "BOTTOMRIGHT", -6, 6)
    srcScrollFrame:EnableMouse(true)
    srcScrollFrame:EnableMouseWheel(true)

    local srcScrollChild = CreateFrame("Frame", nil, srcScrollFrame)
    srcScrollChild:SetPoint("TOPLEFT", 0, 0)
    srcScrollChild:SetWidth(290)
    srcScrollChild:SetHeight(100)
    srcScrollFrame:SetScrollChild(srcScrollChild)
    instance.srcScrollFrame = srcScrollFrame
    instance.srcScrollChild = srcScrollChild

    local srcScrollBar = CreateFrame("Slider", "RecipeRadarSourceScrollBar", srcScrollFrame, "UIPanelScrollBarTemplate")
    srcScrollBar:SetPoint("TOPRIGHT", srcScrollFrame, "TOPRIGHT", -2, -16)
    srcScrollBar:SetPoint("BOTTOMRIGHT", srcScrollFrame, "BOTTOMRIGHT", -2, 16)
    srcScrollBar:SetWidth(14)
    srcScrollBar:SetMinMaxValues(0, 0)
    srcScrollBar:SetValue(0)
    srcScrollBar:SetValueStep(14)
    srcScrollBar:SetScript("OnValueChanged", function(sb, val)
        srcScrollFrame:SetVerticalScroll(val)
    end)
    srcScrollBar:Hide()
    instance.srcScrollBar = srcScrollBar

    srcScrollFrame:SetScript("OnMouseWheel", function(sf, delta)
        local cur = srcScrollBar:GetValue()
        local minVal, maxVal = srcScrollBar:GetMinMaxValues()
        local target = cur - (delta * 24)
        if target < minVal then target = minVal end
        if target > maxVal then target = maxVal end
        srcScrollBar:SetValue(target)
    end)

    -- Interactive source rows pool inside srcScrollChild
    instance.sourceRows = {}
    for i = 1, 30 do
        local row = CreateFrame("Button", nil, srcScrollChild)
        row:SetPoint("TOPLEFT", srcScrollChild, "TOPLEFT", 4, -(i - 1) * 16)
        row:SetPoint("RIGHT", srcScrollChild, "RIGHT", -18, 0)
        row:SetHeight(14)
        row:EnableMouse(true)

        local text = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        text:SetPoint("TOPLEFT", 0, 0)
        text:SetPoint("RIGHT", 0, 0)
        text:SetJustifyH("LEFT")
        text:SetWordWrap(true)
        row.text = text

        row:SetScript("OnEnter", function(btn)
            if btn.waypoint then
                GameTooltip:SetOwner(btn, "ANCHOR_TOP")
                GameTooltip:AddLine(btn.waypoint.name or RR.L["TOMTOM_WAYPOINT"], 1, 0.82, 0)
                if btn.waypoint.zone and btn.waypoint.x and btn.waypoint.y then
                    GameTooltip:AddLine(string.format("%s (%.1f, %.1f)", btn.waypoint.zone, btn.waypoint.x, btn.waypoint.y), 1, 1, 1)
                end
                GameTooltip:AddLine(RR.L["TOMTOM_CLICK_TOOLTIP"], 0.2, 1, 0.2)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(btn)
            if btn.waypoint and RR.Utils and RR.Utils.AddTomTomWaypoint then
                local wp = btn.waypoint
                RR.Utils:AddTomTomWaypoint(wp.name, wp.zone, wp.x, wp.y)
            end
        end)

        row:Hide()
        table.insert(instance.sourceRows, row)
    end

    -- Alt Character Knowledge Section
    local altsBox = CreateFrame("Frame", nil, detailPane, BackdropTemplateMixin and "BackdropTemplate")
    altsBox:SetPoint("TOPLEFT", attrBox, "BOTTOMLEFT", 0, -6)
    altsBox:SetPoint("BOTTOMRIGHT", -6, 6)
    RR.UI.Theme:SkinPanel(altsBox, 0.7)
    local altsTitle = altsBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    altsTitle:SetPoint("TOPLEFT", 6, -6)
    altsTitle:SetText(RR.COLORS.GOLD .. RR.L["ALTS_STATUS"])
    instance.altsText = altsBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instance.altsText:SetPoint("TOPLEFT", altsTitle, "BOTTOMLEFT", 0, -4)
    instance.altsText:SetPoint("BOTTOMRIGHT", -6, 6)
    instance.altsText:SetJustifyH("LEFT")
    instance.altsText:SetJustifyV("TOP")


function instance:Display(recipeItem)
    if not recipeItem then return end
    self.selectedRecipe = recipeItem
    local data = recipeItem.data or {}
    if data.item_id and data.item_id > 0 then
        pcall(function() GetItemInfo(data.item_id) end)
    end
    local locale = GetLocale()
    local meta = RR.DB:GetRecipeAcquisitionMetadata(data)

    
    local rName = recipeItem.name or "-"
    local phaseNum = tonumber(meta.phase or data.phase or 1)
    local rPhase = RR.DB:GetPhaseName(phaseNum)
    local rSkill = tostring(recipeItem.skillReq or 1)
    
    local rRep = "-"
    local repList = meta.reputations or {}
    if #repList == 0 then
        local repFactionId = meta.reputationFactionId or (data.reputation and data.reputation.faction_id)
        local repLvlId = meta.reputationLevel or (data.reputation and (data.reputation.level_id or data.reputation.level))
        if repFactionId then
            table.insert(repList, { faction_id = repFactionId, level_id = repLvlId })
        end
    end

    if #repList > 0 then
        local playerFaction = UnitFactionGroup("player") or "Alliance"
        local repStrings = {}
        for _, repEntry in ipairs(repList) do
            local fName = RR.DB:GetFactionName(repEntry.faction_id)
            local lvlName = repEntry.level_id and RR.DB:GetReputationLevelName(repEntry.level_id)
            if fName and lvlName then
                table.insert(repStrings, { text = string.format("%s (%s)", fName, lvlName), fid = repEntry.faction_id })
            elseif fName then
                table.insert(repStrings, { text = fName, fid = repEntry.faction_id })
            end
        end

        if #repStrings == 1 then
            rRep = repStrings[1].text
        elseif #repStrings > 1 then
            local ALLIANCE_FACTIONS = { [978] = true, [946] = true, [72] = true, [47] = true, [54] = true, [69] = true, [930] = true }
            local HORDE_FACTIONS = { [941] = true, [947] = true, [76] = true, [68] = true, [81] = true, [88] = true, [911] = true }
            
            local matchedRep = nil
            for _, rObj in ipairs(repStrings) do
                if playerFaction == "Alliance" and ALLIANCE_FACTIONS[rObj.fid] then
                    matchedRep = rObj.text
                    break
                elseif playerFaction == "Horde" and HORDE_FACTIONS[rObj.fid] then
                    matchedRep = rObj.text
                    break
                end
            end
            if matchedRep then
                rRep = matchedRep
            else
                local combined = {}
                for _, rObj in ipairs(repStrings) do table.insert(combined, rObj.text) end
                rRep = table.concat(combined, " / ")
            end
        end
    end

    local prof = (RR.Scanner and RR.Scanner:GetCurrentProfession()) or "Leatherworking"
    local rSpec = "-"
    if data.specialisation then
        local specName = nil
        if RR_DATA and RR_DATA["specialisations"] and RR_DATA["specialisations"][prof] then
            for _, sp in ipairs(RR_DATA["specialisations"][prof]) do
                if sp.id == data.specialisation or sp.name == data.specialisation then
                    specName = RR.DB:GetLocalizedText(sp.name)
                    break
                end
            end
        end
        rSpec = specName or tostring(data.specialisation)
    end

    local rHol = "-"
    if data.holiday then
        local holName = nil
        if RR_DATA and RR_DATA["holidays"] then
            for _, h in ipairs(RR_DATA["holidays"]) do
                if h.id == data.holiday then
                    holName = RR.DB:GetLocalizedText(h.name)
                    break
                end
            end
        end
        rHol = holName or tostring(data.holiday)
    end

    local rPrice = "-"
    local priceVal = tonumber(meta.price or data.price)
    if priceVal and priceVal > 0 then
        rPrice = (RR.Utils and RR.Utils.FormatMoney and RR.Utils:FormatMoney(priceVal)) or tostring(priceVal)
    elseif priceVal == 0 then
        rPrice = RR.L["FREE"]
    end
    local rLearnedFrom = "-"

    self.selectedRecipe.waypoint = nil

    local playerFaction = UnitFactionGroup("player") or "Alliance"

    local ALLIANCE_ZONES = {
        [1519] = true, -- Stormwind
        [1537] = true, -- Ironforge
        [1657] = true, -- Darnassus
        [12]   = true, -- Elwynn Forest
        [1]    = true, -- Dun Morogh
        [141]  = true, -- Teldrassil
        [40]   = true, -- Westfall
        [38]   = true, -- Loch Modan
        [148]  = true, -- Darkshore
        [44]   = true, -- Redridge Mountains
        [10]   = true, -- Duskwood
        [11]   = true, -- Wetlands
    }

    local HORDE_ZONES = {
        [1637] = true, -- Orgrimmar
        [1638] = true, -- Thunder Bluff
        [1497] = true, -- Undercity
        [14]   = true, -- Durotar
        [215]  = true, -- Mulgore
        [85]   = true, -- Tirisfal Glades
        [17]   = true, -- The Barrens
        [130]  = true, -- Silverpine Forest
    }

    local function resolveNPC(npcId)
        local npc = RR.DB:GetNPC(npcId)
        if not npc then return nil end
        local nName = RR.DB:GetLocalizedText(npc.name) or "NPC"
        local zId = (npc.location and npc.location.zone_id) or npc.zone_id
        local zName = RR.DB:GetZoneName(zId)
        local nx = tonumber(npc.location and npc.location.x or npc.x)
        local ny = tonumber(npc.location and npc.location.y or npc.y)

        local reacts = npc.reacts
        local effectiveFaction = "Neutral"

        if reacts then
            if type(reacts) == "table" then
                local hasA = false
                local hasH = false
                for _, r in ipairs(reacts) do
                    if r == "Alliance" then hasA = true end
                    if r == "Horde" then hasH = true end
                end
                if hasA and not hasH then effectiveFaction = "Alliance"
                elseif hasH and not hasA then effectiveFaction = "Horde"
                end
            elseif reacts == "Alliance" then
                effectiveFaction = "Alliance"
            elseif reacts == "Horde" then
                effectiveFaction = "Horde"
            end
        end

        -- If faction is neutral or multi-faction, resolve territory via city/zone!
        if effectiveFaction == "Neutral" and zId then
            if ALLIANCE_ZONES[zId] then
                effectiveFaction = "Alliance"
            elseif HORDE_ZONES[zId] then
                effectiveFaction = "Horde"
            end
        end

        local isFactionMatch = (effectiveFaction == playerFaction or effectiveFaction == "Neutral")
        local isOtherFaction = (effectiveFaction ~= playerFaction and effectiveFaction ~= "Neutral")

        return nName, zName, nx, ny, isFactionMatch, isOtherFaction, effectiveFaction
    end

    local function formatNPC(nName, zName, nx, ny, suffix)
        if nx and ny and nx > 0 and ny > 0 then
            return string.format("%s (%s) - %s (%.1f, %.1f)", nName, suffix, zName, nx, ny), { name = nName, zone = zName, x = nx, y = ny }
        else
            return string.format("%s (%s) - %s", nName, suffix, zName), (nx and ny and { name = nName, zone = zName, x = nx, y = ny } or nil)
        end
    end

    local trainerSources = {}
    local vendorSources = {}
    local questSources = {}
    local dropSources = {}

    local function addSourcesToList(srcList, srcData)
        if not srcData then return end
        local sources = srcData.sources or (type(srcData) == "table" and srcData)
        if type(sources) == "table" then
            for _, id in ipairs(sources) do
                table.insert(srcList, id)
            end
        end
    end

    addSourcesToList(trainerSources, data.trainers)
    addSourcesToList(vendorSources, data.vendors)
    addSourcesToList(questSources, data.quests)
    addSourcesToList(dropSources, data.drops)

    if data.items and type(data.items) == "table" then
        for _, itemId in ipairs(data.items) do
            local itm = RR.DB:GetItem(itemId)
            if itm then
                addSourcesToList(vendorSources, itm.vendors)
                addSourcesToList(questSources, itm.quests)
                addSourcesToList(dropSources, itm.drops)
                if itm.price and (not rPrice or rPrice == "-") then
                    rPrice = RR.Utils:FormatMoney(itm.price)
                end
            end
        end
    end

    if (not rPrice or rPrice == "-") then
        if data.trainers and data.trainers.price then
            rPrice = RR.Utils:FormatMoney(data.trainers.price)
        elseif data.vendors and data.vendors.price then
            rPrice = RR.Utils:FormatMoney(data.vendors.price)
        end
    end

    -- Collect ALL possible sources for detailed display
    local allSources = {}
    local seenSources = {}

    -- 1. Vendors
    if vendorSources and type(vendorSources) == "table" then
        for _, id in ipairs(vendorSources) do
            local nName, zName, nx, ny, isFactionMatch, isOtherFaction, effFaction = resolveNPC(id)
            if nName and not seenSources[id] then
                seenSources[id] = true
                local lineText, wp = formatNPC(nName, zName, nx, ny, RR.L["SOURCE_VENDOR"])
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = effFaction,
                    isPlayerFaction = isFactionMatch,
                    isOtherFaction = isOtherFaction,
                })
            end
        end
    end

    -- 2. Trainers
    if trainerSources and type(trainerSources) == "table" then
        for _, id in ipairs(trainerSources) do
            local nName, zName, nx, ny, isFactionMatch, isOtherFaction, effFaction = resolveNPC(id)
            if nName and not seenSources[id] then
                seenSources[id] = true
                local lineText, wp = formatNPC(nName, zName, nx, ny, RR.L["SOURCE_TRAINER"])
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = effFaction,
                    isPlayerFaction = isFactionMatch,
                    isOtherFaction = isOtherFaction,
                })
            end
        end
    end

    -- 3. Quests
    if questSources and type(questSources) == "table" then
        for _, qId in ipairs(questSources) do
            local q = RR.DB:GetQuest(qId)
            if q then
                local qName = (type(q.name) == "table" and (q.name[locale] or q.name["German"] or q.name["English"])) or "Quest"
                local qzId = q.zone_id
                local qx, qy, qNpcName
                local qNpcReacts = nil
                if q.npcs and q.npcs[1] then
                    local npc = RR.DB:GetNPC(q.npcs[1])
                    if npc then
                        if not qzId then qzId = (npc.location and npc.location.zone_id) or npc.zone_id end
                        if not qx then qx = tonumber(npc.location and npc.location.x or npc.x) end
                        if not qy then qy = tonumber(npc.location and npc.location.y or npc.y) end
                        if not qNpcName then qNpcName = RR.DB:GetLocalizedText(npc.name) end
                        qNpcReacts = npc.reacts or npc.faction
                    end
                end
                if q.givers and q.givers.npcs and q.givers.npcs[1] then
                    local npc = RR.DB:GetNPC(q.givers.npcs[1])
                    if npc then
                        if not qzId then qzId = (npc.location and npc.location.zone_id) or npc.zone_id end
                        if not qx then qx = tonumber(npc.location and npc.location.x or npc.x) end
                        if not qy then qy = tonumber(npc.location and npc.location.y or npc.y) end
                        if not qNpcName then qNpcName = RR.DB:GetLocalizedText(npc.name) end
                        if not qNpcReacts then qNpcReacts = npc.reacts or npc.faction end
                    end
                end

                local zName = qzId and RR.DB:GetZoneName(qzId)
                local lineText
                local wp = nil
                if zName and zName ~= (RR.L["ZONE_UNKNOWN"] or "Unknown Zone") and zName ~= "" then
                    if qx and qy and qx > 0 and qy > 0 then
                        lineText = string.format("%s (Quest) - %s (%.1f, %.1f)", qName, zName, qx, qy)
                        wp = { name = qNpcName or qName, zone = zName, x = qx, y = qy }
                    else
                        lineText = string.format("%s (Quest) - %s", qName, zName)
                    end
                else
                    lineText = string.format("%s (Quest)", qName)
                end

                local qFaction = nil
                if q.reacts then
                    if type(q.reacts) == "table" then qFaction = q.reacts[1]
                    elseif type(q.reacts) == "string" then qFaction = q.reacts
                    end
                end
                if not qFaction and qNpcReacts then
                    if type(qNpcReacts) == "table" then qFaction = qNpcReacts[1]
                    elseif type(qNpcReacts) == "string" then qFaction = qNpcReacts
                    end
                end
                if not qFaction then qFaction = "Neutral" end
                local isMatch = (qFaction == playerFaction or qFaction == "Neutral")
                local isOther = (qFaction ~= playerFaction and qFaction ~= "Neutral")
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = qFaction,
                    isPlayerFaction = isMatch,
                    isOtherFaction = isOther,
                })
            end
        end
    end

    -- 3b. World Objects (e.g. Spectral Chalice, Tablet of Madness, Book on ground)
    local objectSources = meta.objects or data.objects
    if objectSources and type(objectSources) == "table" then
        for _, objId in ipairs(objectSources) do
            local obj = RR.DB:GetObject(objId)
            if obj and not seenSources["obj_" .. objId] then
                seenSources["obj_" .. objId] = true
                local oName = RR.DB:GetLocalizedText(obj.name) or RR.L["SOURCE_OBJECT"]
                local zId = (obj.location and obj.location.zone_id) or obj.zone_id
                local zName = zId and RR.DB:GetZoneName(zId)
                local ox = tonumber(obj.location and obj.location.x or obj.x)
                local oy = tonumber(obj.location and obj.location.y or obj.y)
                local lineText, wp = formatNPC(oName, zName, ox, oy, RR.L["SOURCE_OBJECT"])
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = "Neutral",
                    isPlayerFaction = true,
                })
            end
        end
    end

    -- 4. Drops
    if dropSources and type(dropSources) == "table" then
        for _, id in ipairs(dropSources) do
            local nName, zName, nx, ny, isFactionMatch, isOtherFaction, effFaction = resolveNPC(id)
            if nName and not seenSources[id] then
                seenSources[id] = true
                local lineText, wp = formatNPC(nName, zName, nx, ny, RR.L["SOURCE_DROP"])
                table.insert(allSources, {
                    text = lineText,
                    waypoint = wp,
                    faction = effFaction or "Neutral",
                    isPlayerFaction = isFactionMatch,
                    isOtherFaction = isOtherFaction,
                })
            end
        end
    end

    if meta.dropRange then
        table.insert(allSources, {
            text = string.format(RR.L["SOURCE_DROP_LEVEL_RANGE"] or "Drop (Level %d-%d)", meta.dropRange.min_xp_level or 1, meta.dropRange.max_xp_level or 60),
            waypoint = nil,
            isPlayerFaction = true,
        })
    end

    -- 5. Special Actions (e.g. Book in Scholomance, Tablet in Zul'Gurub, Mind Control in BWL)
    local specActionKey = data.special_action or meta.special_action
    if specActionKey then
        local saText = RR.DB:GetSpecialActionText(specActionKey)
        if saText then
            table.insert(allSources, {
                text = string.format(RR.L["LABEL_NOTE"], saText),
                waypoint = nil,
                faction = "Neutral",
                isPlayerFaction = true,
            })
        end
    end

    -- Sort sources: player's faction first, then others!
    table.sort(allSources, function(a, b)
        if a.isPlayerFaction and not b.isPlayerFaction then return true end
        if not a.isPlayerFaction and b.isPlayerFaction then return false end
        return false
    end)

    local attrVals = {
        rName,
        rPhase,
        rSkill,
        rRep,
        rSpec,
        rHol,
        rPrice,
    }
    if self.attrRows then
        for i, rowF in ipairs(self.attrRows) do
            if attrVals[i] then
                rowF.value:SetText(attrVals[i])
            end
        end
    end

    -- Reset source scroll position to top
    if self.srcScrollBar then
        self.srcScrollBar:SetValue(0)
    end
    if self.srcScrollFrame then
        self.srcScrollFrame:SetVerticalScroll(0)
    end

    -- Populate interactive source rows inside srcScrollChild
    local curY = 0
    if self.sourceRows and self.srcScrollChild then
        local childWidth = (self.srcScrollFrame and self.srcScrollFrame:GetWidth() or 300) - 22
        if childWidth > 50 then
            self.srcScrollChild:SetWidth(childWidth)
        end

        for i, row in ipairs(self.sourceRows) do
            local src = allSources[i]
            if src then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", self.srcScrollChild, "TOPLEFT", 4, -curY)
                row:SetPoint("RIGHT", self.srcScrollChild, "RIGHT", -4, 0)

                local factionIcon = ""
                if src.faction == "Alliance" then
                    factionIcon = "|TInterface\\AddOns\\RecipeRadar\\images\\alliance.tga:13:13:0:0|t "
                elseif src.faction == "Horde" then
                    factionIcon = "|TInterface\\AddOns\\RecipeRadar\\images\\horde.tga:13:13:0:0|t "
                else
                    factionIcon = "|TInterface\\AddOns\\RecipeRadar\\images\\neutral.tga:13:13:0:0|t "
                end

                row.text:SetText("• " .. factionIcon .. src.text)
                if src.isOtherFaction then
                    row.text:SetTextColor(0.65, 0.65, 0.65)
                else
                    row.text:SetTextColor(1, 1, 1)
                end
                row.waypoint = src.waypoint
                row:Show()

                -- Calculate exact text height
                local textHeight = math.max(14, math.ceil(row.text:GetStringHeight()) + 2)
                row:SetHeight(textHeight)
                curY = curY + textHeight + 2
            else
                row:Hide()
            end
        end

        local frameHeight = self.srcScrollFrame and self.srcScrollFrame:GetHeight() or 110
        self.srcScrollChild:SetHeight(math.max(frameHeight, curY + 6))

        if curY > (frameHeight - 4) then
            local maxScroll = curY - frameHeight + 12
            self.srcScrollBar:SetMinMaxValues(0, maxScroll)
            self.srcScrollBar:Show()
        else
            self.srcScrollBar:SetMinMaxValues(0, 0)
            self.srcScrollBar:Hide()
        end
    end

    -- Alt knowledge status with clean class icons and texture-based checkmarks
    local curProf = (RR.Scanner and RR.Scanner:GetCurrentProfession()) or "Leatherworking"
    local alts = RR.AltTracker:GetAltStatusForRecipe(curProf, recipeItem.id, recipeItem.name)
    local altsStr = ""
    for _, alt in ipairs(alts) do
        local classKey = alt.class or "WARRIOR"
        local classIcon = ""
        local cCoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classKey]
        if cCoords then
            local left = math.floor(cCoords[1] * 256)
            local right = math.floor(cCoords[2] * 256)
            local top = math.floor(cCoords[3] * 256)
            local bottom = math.floor(cCoords[4] * 256)
            classIcon = string.format("|TInterface\\WorldStateFrame\\Icons-Classes:14:14:0:0:256:256:%d:%d:%d:%d|t ", left, right, top, bottom)
        end

        local cColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classKey]
        local coloredName = alt.name
        if cColor then
            coloredName = string.format("|cff%02x%02x%02x%s|r", cColor.r * 255, cColor.g * 255, cColor.b * 255, alt.name)
        end

        local statusStr
        if alt.isKnown then
            statusStr = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:12:12:0:0|t |cff33ff33" .. (RR.L["LEARNED"] or RR.L["LEARNED"]) .. "|r"
        else
            statusStr = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:12:12:0:0|t |cffff4444" .. (RR.L["MODE_MISSING"] or RR.L["MODE_MISSING"]) .. "|r"
        end

        altsStr = altsStr .. string.format("%s%s: %s\n", classIcon, coloredName, statusStr)
    end
    self.altsText:SetText(altsStr ~= "" and altsStr or (RR.COLORS.GREY .. RR.L["NO_ALTS_REALM"]))

    -- Update Detail Faction Crest
    if self.detailFactionIcon then
        local hasAlliance = meta.factions["Alliance"]
        local hasHorde = meta.factions["Horde"]
        if hasAlliance and not hasHorde then
            self.detailFactionIcon:SetTexture(RR.ADDON_PATH .. "\\images\\alliance.tga")
            self.detailFactionIcon:Show()
        elseif hasHorde and not hasAlliance then
            self.detailFactionIcon:SetTexture(RR.ADDON_PATH .. "\\images\\horde.tga")
            self.detailFactionIcon:Show()
        else
            self.detailFactionIcon:SetTexture(RR.ADDON_PATH .. "\\images\\neutral.tga")
            self.detailFactionIcon:Show()
        end
    end

    -- Re-render list to highlight selected row
end


    return instance
end
