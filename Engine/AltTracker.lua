-- ============================================================================
-- RecipeRadar: Engine/AltTracker.lua
-- Multi-character recipe knowledge tracker across realm
-- ============================================================================

local RR = RecipeRadar
RR.AltTracker = {}

--- Returns a list of all alts on the current realm and their knowledge status for a recipe
-- @param profName string: Profession name
-- @param spellId number: Recipe spell ID
-- @param spellName string: Recipe localized name
-- @return table list of { name = string, class = string, level = number, isKnown = boolean }
function RR.AltTracker:GetAltStatusForRecipe(profName, spellId, spellName)
    local results = {}
    if not (RecipeRadarDB and RecipeRadarDB.characters) then return results end

    local realm = GetRealmName() or "UnknownRealm"
    local realmChars = RecipeRadarDB.characters[realm]
    if not realmChars then return results end

    local playerFaction = UnitFactionGroup("player") or "Neutral"
    local currentCharName = UnitName("player")

    for charName, charData in pairs(realmChars) do
        -- Show alts from the same faction
        if charData.faction == playerFaction and charName ~= currentCharName then
            local isKnown = false
            if charData.professions and charData.professions[profName] and charData.professions[profName].known then
                local knownTable = charData.professions[profName].known
                if (spellId and knownTable[spellId]) or (spellName and knownTable[spellName]) then
                    isKnown = true
                end
            end

            table.insert(results, {
                name = charName,
                class = charData.class or "WARRIOR",
                isKnown = isKnown,
                hasProfession = (charData.professions and charData.professions[profName] ~= nil),
            })
        end
    end

    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end
