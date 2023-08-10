local require = require(script.Parent.loader).load(script)

local Table = require("Table")

return Table.readonly({

	-- Catalog types
	SHIRT = "Shirt",
	T_SHIRT = "T-shirt",
	PANT = "Pant",

	-- Product types
	GAMEPASS = "Gamepass",
})