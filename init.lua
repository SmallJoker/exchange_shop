exchange_shop = {}
exchange_shop.storage_size = 5 * 4
exchange_shop.shopname = "exchange_shop:shop"

-- Internationalisation
exchange_shop.S = minetest.get_translator("exchange_shop")

local modpath = minetest.get_modpath("exchange_shop")
dofile(modpath .. "/shop_functions.lua")
dofile(modpath .. "/shop.lua")
