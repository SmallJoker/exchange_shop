exchange_shop = {}
exchange_shop.storage_size = 5 * 4
exchange_shop.shopname = "exchange_shop:shop"

local modpath = minetest.get_modpath("exchange_shop")
local has_currency = minetest.get_modpath("currency")
local has_bitchange = minetest.get_modpath("bitchange")
local migrate_currency = true -- TODO testing!
local slow_migrate_currency = false


if has_bitchange then
	minetest.register_alias("exchange_shop:shop", "bitchange:shop")
	exchange_shop.shopname = "bitchange:shop"
else
	dofile(modpath .. "/shop_functions.lua")
	dofile(modpath .. "/shop.lua")
end

if has_currency then
	if migrate_currency then
		dofile(modpath .. "/currency_migrate.lua")
	end
	if slow_migrate_currency then
		dofile(modpath .. "/currency_override.lua")
	end
end
