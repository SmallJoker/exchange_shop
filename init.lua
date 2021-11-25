exchange_shop = {}
exchange_shop.storage_size = 5 * 4
exchange_shop.shopname = "exchange_shop:shop"

-- Internationalisaton
--exchange_shop.S = minetest.get_translator("exchange_shop")
exchange_shop.S = intllib.make_gettext_pair()
exchange_shop.FS = function(...)
	return minetest.formspec_escape(exchange_shop.S(...))
end

local modpath = minetest.get_modpath("exchange_shop")
dofile(modpath .. "/shop_functions.lua")
dofile(modpath .. "/shop.lua")
