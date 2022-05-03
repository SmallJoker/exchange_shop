--[[
	Exchange Shop

This code is based on the idea of Dan Duncombe's exchange shop
	https://web.archive.org/web/20160403113102/https://forum.minetest.net/viewtopic.php?id=7002
]]

local S = exchange_shop.S
local FS = exchange_shop.FS
local shop_positions = {}

local function get_exchange_shop_formspec(mode, pos, meta, player)
	local new_inv = not player_api.compat_mode(player)

	local fs_prepend = default.gui_bg .. default.listcolors
	if not new_inv then
		fs_prepend = fs_prepend ..
		"background[0,0;0,0;formspec_background_color.png^formspec_backround.png;true]"
	end

	local name = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
	meta = meta or minetest.get_meta(pos)

	local function listring(src)
		return "listring[" .. name .. ";" .. src .. "]" ..
			"listring[current_player;main]"
	end

	local function make_slots(x, y, w, h, list, label)
	--	local arrow = "default_arrow_bg.png"
	--	if list == "cust_ow" then
	--		arrow = arrow .. "\\^\\[transformFY"
	--	end

		local slots_image = ""
		for _x = 1, w do
		for _y = 1, h do
			slots_image = slots_image ..
				"item_image[" .. _x + x - 1 .. "," .. _y + y - 1 .. ";1,1;default:cell]"
		end
		end

		return table.concat({
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
		local overflow = false -- not meta:get_inventory():is_empty("cust_ej")

		-- customer
		local formspec = (
			"size[9,8.75]" ..
			"item_image[0,-0.1;1,1;".. exchange_shop.shopname .. "]" ..
			"label[0.9,0.1;" .. S("Exchange Shop") .. "]" ..
			fs_prepend ..
			default.gui_close_btn() ..
			make_slots(1, 1.1, 2, 2, "cust_ow", FS("You give:")) ..
			"button[3,3.2;3,1;exchange;" .. FS("Exchange") .. "]" ..
			make_slots(6, 1.1, 2, 2, "cust_og", FS("You get:"))
		)
		-- Insert fallback slots
		local inv_pos = 4.75
		--[[if overflow then
			formspec = (formspec ..
				"label[0.7,4;" .. FS("Ejected items:") .. "\n" .. FS("Remove me!") .. "]" ..
				"item_image[3,4;1,1;default:cell]" ..
				"item_image[4,4;1,1;default:cell]" ..
				"item_image[5,4;1,1;default:cell]" ..
				"item_image[6,4;1,1;default:cell]" ..
				"list[" .. name .. ";cust_ej;3,4;4,1;]"
			)
			inv_pos = 5
		end]]

		local main_image = ""
		for x = 1, 9 do
		for y = 1, 4 do
			main_image = main_image ..
				"item_image[" .. x - 1 .. "," .. y + inv_pos - 1 .. ";1,1;default:cell]"
		end
		end

		formspec = formspec ..
			main_image ..
			"list[current_player;main;0," .. inv_pos .. ";9,4;]" ..
			(overflow and listring("cust_ej") or "")

		return formspec
	end

	if mode == "owner_custm" or mode == "owner_stock" then
		local overflow = not meta:get_inventory():is_empty("custm_ej")
	--	local title = meta:get_string("title")

		-- owner
		local formspec = (
			"size[10,10]" .. fs_prepend ..
			"item_image[0,-0.1;1,1;".. exchange_shop.shopname .. "]" ..
			"label[0.9,0.1;" .. S("Exchange Shop") .. "]" ..
			default.gui_close_btn("9.3,-0.1") ..
		--	"field[0.3,0.65;3,0.5;title;" .. FS("Title:") .. ";" .. title .. "]" ..
		--	"field_close_on_enter[title;false]" ..
		--	"button[2.8,0.3;1,0.61;set_title;" .. FS("Set") .. "]" ..
			make_slots(0.1, 2, 2, 2, "cust_ow", FS("You need:")) ..
			make_slots(2.6, 2, 2, 2, "cust_og", FS("You give:")) ..
			"label[5,0.4;" .. FS("Current stock:") .. "]"
		)

		if overflow then
			formspec = (formspec ..
				"item_image[0.1,4.4;1,1;default:cell]" ..
				"item_image[1.1,4.4;1,1;default:cell]" ..
				"item_image[2.1,4.4;1,1;default:cell]" ..
				"item_image[3.1,4.4;1,1;default:cell]" ..
				"list[" .. name .. ";custm_ej;0.1,4.4;4,1;]" ..
				"label[0.1,5.3;" .. FS("Ejected items:") .. " " .. FS("Remove me!") .. "]" ..
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
				"button[6.25,5.25;2.4,0.5;view_stock;" .. FS("Income") .. "]" ..
				stock_image ..
				"list[" .. name .. ";custm;5,1;5,4;]" ..
				listring("custm"))
			arrow = arrow .. "\\^\\[transformFY"
		else
			formspec = (formspec ..
				"button[6.25,5.25;2.4,0.5;view_custm;" .. FS("Outgoing") .. "]" ..
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
		--	"label[1,5.4;" .. FS("Use (E) + (Right click) for customer interface") .. "]" ..
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

	if (fields.quit and fields.quit ~= "") or
			minetest.get_node(pos).name ~= exchange_shop.shopname then
		shop_positions[player_name] = nil
		return
	end

	local meta = minetest.get_meta(pos)
	local title = meta:get_string("title")
	local shop_owner = meta:get_string("owner")

	local ftitle = fields.title
	if ftitle and exchange_shop.has_access(meta, player_name) then
		-- Limit title length
		ftitle = ftitle:sub(1, 80)
		if title ~= ftitle then
			local title_text = (ftitle and ftitle ~= "") and
				S("Exchange Shop: \"@1\"", ftitle) or S("Exchange Shop")
			meta:set_string("infotext", title_text .. "\n" .. S("Owned by @1", shop_owner))
			meta:set_string("title", minetest.formspec_escape(ftitle))
		end
	end

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
				get_exchange_shop_formspec("customer", pos, meta, sender))
		end
	end
	if (fields.view_custm or fields.view_stock)
			and exchange_shop.has_access(meta, player_name) then
		local mode = "owner_stock"
		if fields.view_custm then
			mode = "owner_custm"
		end
		minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
			get_exchange_shop_formspec(mode, pos, meta, sender))
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
	groups = {choppy=2, oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("owner", owner)
		meta:set_string("infotext", S("Exchange Shop") .. "\n" .. S("Owned by @1", owner))
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", S("Exchange shop (constructing)"))
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("stock", exchange_shop.storage_size) -- needed stock for exchanges
		inv:set_size("custm", exchange_shop.storage_size) -- stock of the customers exchanges
		inv:set_size("custm_ej", 4) -- ejected items if shop has no inventory room
		inv:set_size("cust_ow", 2*2) -- owner wants
		inv:set_size("cust_og", 2*2) -- owner gives
		inv:set_size("cust_ej", 4) -- ejected items if player has no inventory room
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("stock") and inv:is_empty("custm")
				and inv:is_empty("cust_ow") and inv:is_empty("custm_ej")
				and inv:is_empty("cust_og") and inv:is_empty("cust_ej") then
			return true
		end
		if player then
			minetest.chat_send_player(player:get_player_name(),
				S("Cannot dig exchange shop: one or multiple stocks are in use."))
		end
		return false
	end,
	on_rightclick = function(pos, _, clicker)
		local meta = minetest.get_meta(pos)
		local player_name = clicker:get_player_name()

		local mode = "customer"
		if exchange_shop.has_access(meta, player_name) and
				not clicker:get_player_control().aux1 then
			mode = "owner_custm"
		end
		shop_positions[player_name] = pos
		minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
			get_exchange_shop_formspec(mode, pos, meta, clicker))
	end,
	allow_metadata_inventory_move = function(pos, _, _, _, _, count, player)
		local meta = minetest.get_meta(pos)
		if exchange_shop.has_access(meta, player:get_player_name()) then
			return count
		end
		return 0
	end,
	allow_metadata_inventory_put = function(pos, listname, _, stack, player)
		local player_name = player:get_player_name()
		if listname == "custm" then
			minetest.chat_send_player(player_name,
				S("Exchange shop: Insert your trade goods into 'Outgoing'."))
			return 0
		end
		local meta = minetest.get_meta(pos)
		if exchange_shop.has_access(meta, player_name)
				and listname ~= "cust_ej"
				and listname ~= "custm_ej" then
			return stack:get_count()
		end
		return 0
	end,
	allow_metadata_inventory_take = function(pos, listname, _, stack, player)
		local meta = minetest.get_meta(pos)
		if exchange_shop.has_access(meta, player:get_player_name())
				or listname == "cust_ej" then
			return stack:get_count()
		end
		return 0
	end,
})

minetest.register_craft({
	output = exchange_shop.shopname,
	recipe = {
		{"default:ruby", "default:ruby", "default:ruby"},
		{"default:ruby", "default:chest", "default:ruby"},
		{"default:ruby", "default:ruby", "default:ruby"}
	}
})

minetest.register_on_leaveplayer(function(player)
	shop_positions[player:get_player_name()] = nil
end)
