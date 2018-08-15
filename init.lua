exchange_shop = {}
exchange_shop.storage_size = 5 * 4
exchange_shop.shopname = "exchange_shop:shop"

local modpath = minetest.get_modpath("exchange_shop")
local has_currency = minetest.get_modpath("currency")
local has_bitchange = minetest.get_modpath("bitchange")

-- Currency migrate options
exchange_shop.migrate = {
	use_lbm = false,
	-- ^ Runs once on each unique loaded mapblock
	on_interact = true
	-- ^ Converts shop nodes "on the fly"
}


if has_bitchange then
	minetest.register_alias("exchange_shop:shop", "bitchange:shop")
	exchange_shop.shopname = "bitchange:shop"
else
	minetest.register_alias("bitchange:shop", "exchange_shop:shop")
	dofile(modpath .. "/shop_functions.lua")
	dofile(modpath .. "/shop.lua")
end
dofile(modpath .. "/pipes.lua")

if has_currency then
	local new_groups = table.copy(minetest.registered_nodes["currency:shop"].groups)
	new_groups.not_in_creative_inventory = 1
	minetest.override_item("currency:shop", {
		groups = new_groups
	})

	dofile(modpath .. "/currency_migrate.lua")
	if exchange_shop.migrate.on_interact then
		dofile(modpath .. "/currency_override.lua")
	end
end
