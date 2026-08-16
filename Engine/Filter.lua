-- ============================================================================
-- RecipeRadar: Engine/Filter.lua
-- High performance multi-criteria recipe filtering pipeline
-- ============================================================================

local RR = RecipeRadar
RR.Filter = {}

function RR.Filter:ApplyFilters(recipes, profName, searchQuery)
    if not recipes then return {}, { missing = 0, known = 0, total = 0 } end

    local mode = RR.Config:GetFilterSetting("mode") or "missing"
    local sourceFilter = RR.Config:GetFilterSetting("sourceFilter") or "any"
    local factionFilter = RR.Config:GetFilterSetting("factionFilter") or "any"
    local zoneFilter = RR.Config:GetFilterSetting("zoneFilter") or "any"
    local phaseFilter = RR.Config:GetFilterSetting("phaseFilter") or 0
    local specFilter = RR.Config:GetFilterSetting("specFilter") or "any"

    local playerFaction = UnitFactionGroup("player") or "Neutral"
    local currentZoneId = RR.DB:GetCurrentZoneId()

    local filtered = {}
    local counts = { missing = 0, known = 0, total = 0 }
    local searchLower = searchQuery and string.lower(strtrim(searchQuery)) or ""

    for _, recipe in ipairs(recipes) do
        local spellId = recipe.id or recipe.spell_id
        local recipeName = RR.DB:GetLocalizedText(recipe.name)
        local isKnown = RR.Scanner:IsRecipeKnown(profName, spellId, recipeName)
        local meta = RR.DB:GetRecipeAcquisitionMetadata(recipe)

        -- Update stats count
        counts.total = counts.total + 1
        if isKnown then
            counts.known = counts.known + 1
        else
            counts.missing = counts.missing + 1
        end

        -- 1. Mode Check (Missing / Learned / All)
        local passMode = true
        if mode == "missing" and isKnown then
            passMode = false
        elseif mode == "known" and not isKnown then
            passMode = false
        end

        -- 2. Source Check (Trainer / Vendor / Quest / Drop / Object / Holiday / Reputation)
        local passSource = true
        if type(sourceFilter) == "table" then
            local matched = false
            for sType, enabled in pairs(sourceFilter) do
                if enabled and meta.sourceTypes[sType] then
                    matched = true
                    break
                end
            end
            if not matched then passSource = false end
        elseif sourceFilter and sourceFilter ~= "any" then
            if not meta.sourceTypes[sourceFilter] then
                passSource = false
            end
        end

        -- 3. Faction Allegiance Check (Alliance, Horde, Neutral)
        local passFaction = true
        if type(factionFilter) == "table" then
            local matched = false
            for fac, enabled in pairs(factionFilter) do
                if enabled then
                    if fac == "Alliance" and (meta.factions["Alliance"] or meta.factions["Neutral"]) then
                        matched = true
                        break
                    elseif fac == "Horde" and (meta.factions["Horde"] or meta.factions["Neutral"]) then
                        matched = true
                        break
                    elseif fac == "Neutral" and meta.factions["Neutral"] then
                        matched = true
                        break
                    end
                end
            end
            if not matched then passFaction = false end
        elseif factionFilter == "Alliance" or factionFilter == "Horde" or factionFilter == "Neutral" then
            if not meta.factions[factionFilter] and not meta.factions["Neutral"] then
                passFaction = false
            end
        end

        -- 3b. Reputation Faction Check (Specific reputation requirement)
        local repFilter = RR.Config:GetFilterSetting("repFilter")
        local passRep = true
        if type(repFilter) == "table" then
            local matched = false
            for fId, enabled in pairs(repFilter) do
                if enabled then
                    if meta.reputationFactionId == fId then
                        matched = true
                        break
                    elseif meta.reputations then
                        for _, r in ipairs(meta.reputations) do
                            if r.faction_id == fId then
                                matched = true
                                break
                            end
                        end
                    end
                end
            end
            if not matched then passRep = false end
        elseif repFilter and type(repFilter) == "number" and repFilter > 0 then
            local hasRep = false
            if meta.reputationFactionId == repFilter then
                hasRep = true
            elseif meta.reputations then
                for _, r in ipairs(meta.reputations) do
                    if r.faction_id == repFilter then
                        hasRep = true
                        break
                    end
                end
            end
            if not hasRep then
                passRep = false
            end
        end

        -- 4. Zone / Region / Continent Check
        local passZone = true
        local continentFilter = RR.Config:GetFilterSetting("continentFilter")
        if continentFilter and continentFilter ~= "any" and type(continentFilter) == "number" and continentFilter > 0 then
            if not meta.continents[continentFilter] then
                passZone = false
            end
        end

        if passZone then
            if zoneFilter == "current" then
                if currentZoneId and not meta.zones[currentZoneId] then
                    passZone = false
                end
            elseif type(zoneFilter) == "number" and zoneFilter > 0 then
                if not meta.zones[zoneFilter] then
                    passZone = false
                end
            end
        end

        -- 5. Phase Check (Strict Phase filter: show recipes introduced in the chosen phases)
        local passPhase = true
        local function matchSinglePhase(reqPhase, mPhase, mExp)
            mExp = mExp or 1
            mPhase = mPhase or 1
            if type(reqPhase) == "string" then
                local expKey, pNum = reqPhase:match("^(%a+)_(%d+)$")
                if expKey and pNum then
                    pNum = tonumber(pNum)
                    if expKey == "tbc" then
                        return (mExp == 2 and mPhase == pNum)
                    elseif expKey == "era" or expKey == "classic" then
                        return (mExp == 1 and mPhase == pNum)
                    end
                end
            elseif type(reqPhase) == "number" and reqPhase > 0 then
                if RR.DB:IsTBC() then
                    return (mExp == 2 and mPhase == reqPhase)
                else
                    return (mPhase == reqPhase)
                end
            end
            return false
        end

        if type(phaseFilter) == "table" then
            local matched = false
            for reqP, enabled in pairs(phaseFilter) do
                if enabled and matchSinglePhase(reqP, meta.phase, meta.expansion) then
                    matched = true
                    break
                end
            end
            if not matched then passPhase = false end
        elseif phaseFilter and phaseFilter ~= 0 and phaseFilter ~= "any" then
            if not matchSinglePhase(phaseFilter, meta.phase, meta.expansion) then
                passPhase = false
            end
        end

        -- 5b. Specialisation Check
        local passSpec = true
        if type(specFilter) == "table" then
            if not specFilter[recipe.specialisation or 0] then
                passSpec = false
            end
        elseif specFilter and specFilter ~= "any" and type(specFilter) == "number" and specFilter > 0 then
            if recipe.specialisation ~= specFilter then
                passSpec = false
            end
        end

        -- 6. Search Query Check
        local passSearch = true
        if searchLower ~= "" then
            local nameLower = string.lower(recipeName)
            if not string.find(nameLower, searchLower, 1, true) then
                passSearch = false
            end
        end

        if passMode and passSource and passFaction and passRep and passZone and passPhase and passSpec and passSearch then
            table.insert(filtered, {
                data = recipe,
                id = spellId,
                name = recipeName,
                isKnown = isKnown,
                skillReq = recipe.min_skill or 1,
            })
        end
    end

    -- Sort by required skill, then by name
    table.sort(filtered, function(a, b)
        if a.skillReq ~= b.skillReq then
            return a.skillReq < b.skillReq
        end
        return a.name < b.name
    end)

    return filtered, counts
end
