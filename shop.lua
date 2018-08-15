--[[
	Exchange Shop

This code is based on the idea of Dan Duncombe's exchange shop
	https://web.archive.org/web/20160403113102/https://forum.minetest.net/viewtopic.php?id=7002
]]


local shop_positions = {}

local function get_exchange_shop_formspec(mode, pos, meta)
	local name = "nodemeta:"..pos.x..","..pos.y..","..pos.z
	meta = meta or minetest.get_meta(pos)

	local function listring(src)
		return "listring[".. name ..";" .. src .. "]" ..
			"listring[current_player;main]"
	end
	if mode == "customer" then
		local overflow = not meta:get_inventory():is_empty("cust_ej")

		-- customer
		local formspec = (
			(overflow and "size[8,9]" or "size[8,8]")..
			"label[1,0.4;You give:]"..
			"list["..name..";cust_ow;1,1;2,2;]"..
			"button[3,2.4;2,1;exchange;Exchange]"..
			"label[5,0.4;You get:]"..
			"list["..name..";cust_og;5,1;2,2;]"
		)
		-- Insert fallback slots
		local inv_pos = 4
		if overflow then
			formspec = (formspec ..
				"label[0.7,3.5;Ejected items:]"..
				"label[0.7,3.8;(Remove me!)]"..
				"list["..name..";cust_ej;3,3.5;4,1;]"
			)
			inv_pos = 5
		end
		return (formspec ..
			"list[current_player;main;0," .. inv_pos .. ";8,4;]"..
			(overflow and listring("cust_ej") or "")
		)
	end
	if mode == "owner_custm"
			or mode == "owner_stock" then
		local overflow = not meta:get_inventory():is_empty("custm_ej")
		local title = meta:get_string("title")

		-- owner
		local formspec = (
			"size[10,10]"..
			"label[0,0.1;Title:]"..
			"field[1.2,0.5;3,0.5;title;;"..title.."]"..
			"field_close_on_enter[title;false]"..
			"button[3.9,0.2;1,0.5;set_title;Set]"..
			"container[0,2]"..
			"label[0,-0.6;You need:]"..
			"list["..name..";cust_ow;0,0;2,2;]"..
			"label[2.5,-0.6;You give:]"..
			"list["..name..";cust_og;2.5,0;2,2;]"..
			"container_end[]"..
			"label[5,0.1;Current stock:]"
		)

		if overflow then
			formspec = (formspec..
				"list["..name..";custm_ej;0.2,4;4,1;]"..
				"label[0.2,4.9;Ejected items: (Remove me!)]"..
				listring("custm_ej")
			)
		end

		if mode == "owner_custm" then
			formspec = (formspec..
				"button[7.5,0.2;2.5,0.5;view_stock;Income]"..
				"list["..name..";custm;5,1;5,4;]"..
				listring("custm"))
		else
			formspec = (formspec..
				"button[7.5,0.2;2.5,0.5;view_custm;Outgoing]"..
				"list["..name..";stock;5,1;5,4;]"..
				listring("stock"))
		end
		return (formspec..
			"label[1,5.4;Use (E) + (Right click) for customer interface]"..
			"list[current_player;main;1,6;8,4;]")
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
			minetest.get_node(pos).name ~= "exchange_shop:shop" then
		shop_positions[player_name] = nil
		return
	end

	local meta = minetest.get_meta(pos)
	local title = meta:get_string("title")
	local shop_owner = meta:get_string("owner")

	if fields.title and exchange_shop.has_access(meta, player_name) then
		-- Limit title length
		fields.title = fields.title:sub(1, 80)
		if title ~= fields.title then
			if fields.title ~= "" then
				meta:set_string("infotext", "'" .. fields.title
					.. "' (owned by " .. shop_owner .. ")")
			else
				meta:set_string("infotext", "Exchange shop (owned by "
					.. shop_owner ..")")
			end
			meta:set_string("title", minetest.formspec_escape(fields.title))
		end
	end

	if fields.exchange then
		local shop_inv = meta:get_inventory()
		local player_inv = sender:get_inventory()
		if shop_inv:is_empty("cust_ow")
				and shop_inv:is_empty("cust_og") then
			return
		end

		local err_msg, resend = exchange_shop.exchange_action(player_inv, shop_inv)
		-- Throw error message
		if err_msg then
			minetest.chat_send_player(player_name, minetest.colorize("#F33",
				"Exchange shop: " .. err_msg))
		end
		if resend then
			minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
				get_exchange_shop_formspec("customer", pos, meta))
		end
	end
	if (fields.view_custm or fields.view_stock)
			and exchange_shop.has_access(meta, player_name) then
		local mode = "owner_stock"
		if fields.view_custm then
			mode = "owner_custm"
		end
		minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
			get_exchange_shop_formspec(mode, pos, meta))
	end
end)

minetest.register_node(exchange_shop.shopname, {
	description = "Exchange Shop",
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
		meta:set_string("infotext", "Exchange shop (owned by "
			.. owner .. ")")
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Exchange shop (constructing)")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("stock", exchange_shop.storage_size) -- needed stock for exchanges
		inv:set_size("custm", exchange_shop.storage_size) -- stock of the customers exchanges
		inv:set_size("custm_ej", 4) -- ejected items if shop has no inventory room
		inv:set_size("cust_ow", 2*2) -- owner wants
		inv:set_size("cust_og", 2*2) -- owner gives
		inv:set_size("cust_ej", 4) -- ejected items if player has no inventory room
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if inv:is_empty("stock") and inv:is_empty("custm")
				and inv:is_empty("cust_ow") and inv:is_empty("custm_ej")
				and inv:is_empty("cust_og") and inv:is_empty("cust_ej") then
			return true
		end
		minetest.chat_send_player(player:get_player_name(),
			"Cannot dig exchange shop: one or multiple stocks are in use.")
		return false
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		local player_name = clicker:get_player_name()

		local mode = "customer"
		if exchange_shop.has_access(meta, player_name) and
				not clicker:get_player_control().aux1 then
			mode = "owner_custm"
		end
		shop_positions[player_name] = pos
		minetest.show_formspec(player_name, "exchange_shop:shop_formspec",
			get_exchange_shop_formspec(mode, pos, meta))
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		local meta = minetest.get_meta(pos)
		if exchange_shop.has_access(meta, player:get_player_name()) then
			return count
		end
		return 0
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "custm" then
			minetest.chat_send_player(player:get_player_name(),
				"Exchange shop: Insert your trade goods into 'Outgoing'.")
			return 0
		end
		local meta = minetest.get_meta(pos)
		if exchange_shop.has_access(meta, player:get_player_name())
				and listname ~= "cust_ej"
				and listname ~= "custm_ej" then
			return stack:get_count()
		end
		return 0
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		if exchange_shop.has_access(meta, player:get_player_name())
				or listname == "cust_ej" then
			return stack:get_count()
		end
		return 0
	end,
})

minetest.register_craft({
	output = "exchange_shop:shop",
	recipe = {
		{"default:sign_wall"},
		{"default:chest_locked"},
	}
})

minetest.register_on_leaveplayer(function(player)
	shop_positions[player:get_player_name()] = nil
end)

if minetest.get_modpath("wrench") and wrench then
	local STRING = wrench.META_TYPE_STRING
	wrench:register_node("exchange_shop:shop", {
		lists = {"stock", "custm", "custm_ej", "cust_ow", "cust_og", "cust_ej"},
		metas = {
			owner = STRING,
			infotext = STRING,
			title = STRING,
		},
		owned = true
	})
end
