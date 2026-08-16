-------------------------------------------------------
-- RecipeRadar - TBC Data Module
-------------------------------------------------------

RR_DATA_TBC = {
    -- Injects missing vendor/source mappings for TBC items
    InjectMissingSources = function(self)
        if RR_LOGIC_ITEM_OBJECT and RR_LOGIC_ITEM_OBJECT.GetItemById then
            local subtlety_recipe = RR_LOGIC_ITEM_OBJECT:GetItemById(33150)
            if subtlety_recipe and subtlety_recipe.vendors and subtlety_recipe.vendors.sources then
                if not RR_TOOLS:ListContainsNumber(subtlety_recipe.vendors.sources, 17585) then
                    table.insert(subtlety_recipe.vendors.sources, 17585)
                end
            end
        end
    end,

    -- Fixes Engineering Specialization tags (Goblin vs Gnome)
    FixEngineeringSpecializations = function(self)
        if RR_DATA and RR_DATA["skills"] and RR_DATA["skills"]["Engineering"] then
            for _, skill in pairs(RR_DATA["skills"]["Engineering"]) do
                if skill.id == 30558 or skill.id == 30560 then
                    skill.specialisation = 20222 -- Goblin Engineering
                end
            end
        end
    end,
}

-- Execute data fixes on load
if C_Timer and C_Timer.After then
    C_Timer.After(2.0, function()
        RR_DATA_TBC:InjectMissingSources()
        RR_DATA_TBC:FixEngineeringSpecializations()
    end)
else
    RR_DATA_TBC:InjectMissingSources()
    RR_DATA_TBC:FixEngineeringSpecializations()
end
