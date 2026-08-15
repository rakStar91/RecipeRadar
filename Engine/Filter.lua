-- ============================================================================
-- RecipeRadar: Engine/Filter.lua
-- High performance recipe filtering pipeline
-- ============================================================================

local RR = RecipeRadar
RR.Filter = {}

--- Filters a list of recipes based on current configuration
-- @param recipes table: Raw recipe list from Database
-- @param profName string: Name of profession
-- @param searchQuery string: Optional search filter text
-- @return table filtered recipes, table counts { missing = x, known = y, total = z }
function RR.Filter:ApplyFilters(recipes, profName, searchQuery)
    if not recipes then return {}, { missing = 0, known = 0, total = 0 } end

    local mode = RR.Config:GetFilterSetting("mode") or "missing"
    local zoneMode = RR.Config:GetFilterSetting("zoneMode") or "any"
    local sourceFilters = RR.Config:GetFilterSetting("sources") or {}
    local playerFaction = UnitFactionGroup("player") or "Neutral"
    local currentZone = GetRealZoneText() or ""
    local lastZone = RR.Config:GetLastZone() or ""

    local filtered = {}
    local counts = { missing = 0, known = 0, total = 0 }
    local searchLower = searchQuery and string.lower(strtrim(searchQuery)) or ""
    local locale = GetLocale()

    for _, recipe in ipairs(recipes) do
        local spellId = recipe.id or recipe.spell_id
        local recipeName = ""
        if recipe.name then
            recipeName = recipe.name[locale] or recipe.name["English"] or ""
        end

        local isKnown = RR.Scanner:IsRecipeKnown(profName, spellId, recipeName)

        -- Update stats count
        counts.total = counts.total + 1
        if isKnown then
            counts.known = counts.known + 1
        else
            counts.missing = counts.missing + 1
        end

        -- 1. Mode Check
        local passMode = true
        if mode == "missing" and isKnown then
            passMode = false
        elseif mode == "known" and not isKnown then
            passMode = false
        end

        -- 2. Search Text Check
        local passSearch = true
        if searchLower ~= "" then
            local nameLower = string.lower(recipeName)
            if not string.find(nameLower, searchLower, 1, true) then
                passSearch = false
            end
        end

        -- 3. Faction Check
        local passFaction = true
        if recipe.faction and recipe.faction ~= "Neutral" and recipe.faction ~= playerFaction then
            passFaction = false
        end

        if passMode and passSearch and passFaction then
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
