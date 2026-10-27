-------------------------------------------------------
-- Objects recorded in WoW Forever (appended to the Base objects)
-------------------------------------------------------
local forever_objects = {
	{
		["id"] = 176090,
		["location"] = {
			["x"] = "-",
			["y"] = "-",
		},
		["name"] = {
			["Chinese"] = "Human Remains",
			["English"] = "Human Remains",
			["French"] = "Human Remains",
			["German"] = "Menschliche Überreste",
			["Korean"] = "Human Remains",
			["Mexican"] = "Human Remains",
			["Portuguese"] = "Human Remains",
			["Russian"] = "Human Remains",
			["Spanish"] = "Human Remains",
			["Taiwanese"] = "Human Remains",
		},
		["zone_id"] = 1583,
	},
}

for _, entry in ipairs(forever_objects) do
	table.insert(RR_DATA["objects"], entry)
end
