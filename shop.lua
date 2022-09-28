--[[
	Exchange Shop

This code is based on the idea of Dan Duncombe's exchange shop
	https://web.archive.org/web/20160403113102/https://forum.minetest.net/viewtopic.php?id=7002
]]

local S = exchange_shop.S
local shop_positions = {}

local tconcat = table.concat

local function get_exchange_shop_formspec(mode, pos, meta)
	local name = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
	meta = meta or minetest.get_meta(pos)

	local function listring(src)
		return "listring[" .. name .. ";" .. src .. "]" ..
			"listring[current_player;main]"
	end

	local function make_slots(x, y, w, h, list, label)
		local slots_image = ""
		for _x = 1, w do
		for _y = 1, h do
			slots_image = slots_image ..
				"item_image[" .. _x + x - 1 .. "," .. _y + y - 1 .. ";1,1;default:cell]"
		end
		end

		return tconcat({
			("label[%f,%f;%s]"):format(x, y - 0.5, label),
		--	("image[%f,%f;0.6,0.6;shop_front.png]"):format(x + 0.15, y + 0.3),
		--	("image[%f,%f;0.6,0.6;%s]"):format(x + 0.15, y + 0.0, arrow),
		--	("item_image[%f,%f;1,1;default:cell]"):format(x, y),
		--	("item_image[%f,%f;1,1;default:cell]"):format(x + 1, y),
		--	("item_image[%f,%f;1,1;default:cell]"):format(x, y + 1),
		--	("item_image[%f,%f;1,1;default:cell]"):format(x + 1, y + 1),
			(slots_image),
			("list[" .. name .. ";%s;%f,%f;%u,%u;]"):format(list, x, y, w, h)
		})
	end

	if mode == "customer" then
		-- customer
		local formspec = (
			"size[9,8.75]" ..
			"item_image[0,-0.1;1,1;".. exchange_shop.shopname .. "]" ..
			"label[0.9,0.1;" .. S("Exchange Shop") .. "]" ..
			default.gui_close_btn() ..
			make_slots(1, 1.1, 2, 2, "cust_ow", S("You give:")) ..
			"button[3,3.2;3,1;exchange;" .. S("Exchange") .. "]" ..
			make_slots(6, 1.1, 2, 2, "cust_og", S("You get:"))
		)
		-- Insert fallback slots
		local inv_pos = 4.75

		local main_image = ""
		for x = 1, 9 do
		for y = 1, 4 do
			main_image = main_image ..
				"item_image[" .. x - 1 .. "," .. y + inv_pos - 1 .. ";1,1;default:cell]"
		end
		end

		formspec = formspec ..
			main_image ..
			"list[current_player;main;0," .. inv_pos .. ";9,4;]"

		return formspec
	end

	if mode == "owner_custm" or mode == "owner_stock" then
		local overflow = not meta:get_inventory():is_empty("custm_ej")

		-- owner
		local formspec = (
			"size[10,10]" ..
			"item_image[0,-0.1;1,1;".. exchange_shop.shopname .. "]" ..
			"label[0.9,0.1;" .. S("Exchange Shop") .. "]" ..
			default.gui_close_btn("9.3,-0.1") ..
			make_slots(0.1, 2, 2, 2, "cust_ow", S("You need:")) ..
			make_slots(2.6, 2, 2, 2, "cust_og", S("You give:")) ..
			"label[5,0.4;" .. S("Current stock:") .. "]"
		)

		if overflow then
			formspec = (formspec ..
				"item_image[0.1,4.4;1,1;default:cell]" ..
				"item_image[1.1,4.4;1,1;default:cell]" ..
				"item_image[2.1,4.4;1,1;default:cell]" ..
				"item_image[3.1,4.4;1,1;default:cell]" ..
				"list[" .. name .. ";custm_ej;0.1,4.4;4,1;]" ..
				"label[0.1,5.3;" .. S("Ejected items:") .. " " .. S("Remove me!") .. "]" ..
				listring("custm_ej")
			)
		end

		local stock_image = ""
		for x = 1, 5 do
		for y = 1, 4 do
			stock_image = stock_image ..
				"item_image[" .. x + 4 .. "," .. y .. ";1,1;default:cell]"
		end
		end

		local arrow = "default_arrow_bg.png"
		if mode == "owner_custm" then
			formspec = (formspec ..
				"button[6.25,5.25;2.4,0.5;view_stock;" .. S("Income") .. "]" ..
				stock_image ..
				"list[" .. name .. ";custm;5,1;5,4;]" ..
				listring("custm"))
			arrow = arrow .. "\\^\\[transformFY"
		else
			formspec = (formspec ..
				"button[6.25,5.25;2.4,0.5;view_custm;" .. S("Outgoing") .. "]" ..
				stock_image ..
				"list[" .. name .. ";stock;5,1;5,4;]" ..
				listring("stock"))
		end

		local main_image = ""
		for x = 1, 9 do
		for y = 1, 4 do
			main_image = main_image ..
				"item_image[" .. x - 0.5 .. "," .. y + 5 .. ";1,1;default:cell]"
		end
		end

		formspec = formspec ..
		--	"label[1,5.4;" .. S("Use (E) + (Right click) for customer interface") .. "]" ..
			main_image ..
			"image[8.65,5.2;0.6,0.6;" .. arrow .. "]" ..
			"list[current_player;main;0.5,6;9,4;]"

		return formspec
	end
	return ""
end


minetest.register_on_player_receive_fields(function(sender, formname, fields)
	if formname ~= "exchange_shop:shop_formspec" then
		return
	end

	local player_name = sender:get_player_name()
	local pos = shop_positions[player_name]
	if not pos then
		return
	end

	if fields.quit or minetest.get_node(pos).name ~= exchange_shop.shopname then
		shop_positions[player_name] = nil
		return
	end

	local meta = minetest.get_meta(pos)
	if fields.exchange then
		local shop_inv = meta:get_inventory()
		local player_inv = sender:get_inventory()
		if shop_inv:is_empty("cust_ow")
				and shop_inv:is_empty("cust_og") then
			return
		end

		local err_msg, resend = exchange_shop.exchange_action(player_inv, shop_inv, pos)
		-- Throw error message
		if err_msg then
			minetest.chat_send_player(player_name, minetest.colorize("#F33",
				S("Exchange Shop:") .. " " .. err_msg))
		end
		if resend then
			minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
				get_exchange_shop_formspec("customer", pos, meta))
		end
	elseif (fields.view_custm or fields.view_stock)
			and not minetest.is_protected(pos, player_name) then
		local mode = "owner_stock"
		if fields.view_custm then
			mode = "owner_custm"
		end
		minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
			get_exchange_shop_formspec(mode, pos, meta))
	end
end)

minetest.register_node(exchange_shop.shopname, {
	description = S("Exchange Shop"),
	tiles = {
		"shop_top.png", "shop_top.png",
		"shop_side.png","shop_side.png",
		"shop_side.png", "shop_front.png"
	},
	paramtype2 = "facedir",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	sounds = default.node_sound_wood_defaults(),

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("infotext", S("Exchange Shop") .. "\n" .. S("Owned by @1", owner))
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("stock", exchange_shop.storage_size) -- needed stock for exchanges
		inv:set_size("custm", exchange_shop.storage_size) -- stock of the customers exchanges
		inv:set_size("custm_ej", 4) -- ejected items if shop has no inventory room
		inv:set_size("cust_ow", 2 * 2) -- owner wants
		inv:set_size("cust_og", 2 * 2) -- owner gives
	end,

	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		if inv:is_empty("stock") and inv:is_empty("custm")
				and inv:is_empty("cust_ow") and inv:is_empty("custm_ej")
				and inv:is_empty("cust_og") then
			return true
		end
		if player then
			minetest.chat_send_player(player:get_player_name(),
				S("Cannot dig exchange shop: one or multiple stocks are in use."))
		end
		return false
	end,

	on_rightclick = function(pos, _, clicker)
		local player_name = clicker:get_player_name()
		local meta = minetest.get_meta(pos)

		local mode = "customer"
		if not minetest.is_protected(pos, player_name) and
				not clicker:get_player_control().aux1 then
			mode = "owner_custm"
		end
		shop_positions[player_name] = pos
		minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
			get_exchange_shop_formspec(mode, pos, meta))
	end,

	allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
		local player_name = player:get_player_name()
		return not minetest.is_protected(pos, player_name) and count or 0
	end,

	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		local player_name = player:get_player_name()

		if listname == "custm" then
			minetest.chat_send_player(player_name,
				S("Exchange shop: Insert your trade goods into 'Outgoing'."))
			return 0
		end
		if not minetest.is_protected(pos, player_name)
				and listname ~= "custm_ej" then
			return stack:get_count()
		end
		return 0
	end,

	allow_metadata_inventory_take = function(pos, _, _, stack, player)
		local player_name = player:get_player_name()
		return not minetest.is_protected(pos, player_name) and stack:get_count() or 0
	end
})

minetest.register_craft({
	output = exchange_shop.shopname,
	recipe = {
		{"default:gold_ingot", "default:ruby", "default:gold_ingot"},
		{"default:ruby", "default:chest", "default:ruby"},
		{"default:gold_ingot", "default:ruby", "default:gold_ingot"}
	}
})

minetest.register_on_leaveplayer(function(player)
	shop_positions[player:get_player_name()] = nil
end)
