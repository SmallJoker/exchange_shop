-- Combine stacks into a new list
local function compress_list(list)
	local items = {}
	local new_list = {}
	for i, stack in pairs(list or {}) do
		if not stack:is_empty() then
			if stack:get_stack_max() == 1 then
				table.insert(new_list, stack)
			else
				items[stack:get_name()] = (items[stack:get_name()] or 0)
					+ stack:get_count()
			end
		end
	end
	for name, count in pairs(items) do
		local max = ItemStack(name):get_stack_max()

		repeat
			local take = math.min(max, count)
			local stack = ItemStack(name)
			stack:set_count(take)
			table.insert(new_list, stack)
			count = count - take
		until count == 0
	end
	return new_list
end

local function list_add_list(inv, list_name, list)
	local leftover_list = {}
	for i, stack in pairs(list or {}) do
		local leftover = inv:add_item(list_name, stack)
		if not leftover:is_empty() then
			table.insert(leftover_list, leftover)
		end
	end
	if #leftover_list > 0 then
		minetest.log("warning", "[exchange_shop] List " .. list_name
			.. " is full. Possible item loss!")
	end
	return leftover_list
end

function exchange_shop.migrate_shop_node(pos, node)
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")
	local title = meta:get_string("infotext")
	local inv = meta:get_inventory()
	local def = minetest.registered_nodes[exchange_shop.shopname]

	-- Create new slots
	def.on_construct(pos)
	meta:set_string("owner", owner)
	meta:set_string("infotext", title)

	list_add_list(inv, "custm", inv:get_list("customers_gave"))
	inv:set_size("customers_gave", 0)

	local new_owner_gives = compress_list(inv:get_list("owner_gives"))
	local new_owner_wants = compress_list(inv:get_list("owner_wants"))
	local dst_gives = "cust_og"
	local dst_wants = "cust_ow"
	if #new_owner_gives > 4 or #new_owner_wants > 4 then
		-- Not enough space (from 6 slots to 4)
		-- redirect everything to the stock
		dst_gives = "stock"
		dst_wants = "custm"
	end
	list_add_list(inv, dst_gives, new_owner_gives)
	list_add_list(inv, dst_wants, new_owner_wants)

	inv:set_size("owner_gives", 0)
	inv:set_size("owner_takes", 0)

	node.name = exchange_shop.shopname
	minetest.swap_node(pos, node)
end

if exchange_shop.migrate.use_lbm then
	minetest.register_lbm({
		label = "currency shop to exchange shop migration",
		name = "exchange_shop:currency_migrate",
		nodenames = { "currency:shop" },
		run_at_every_load = false,
		action = exchange_shop.migrate_shop_node
	})

	-- Clean up garbage
	minetest.register_on_joinplayer(function(player)
		local inv = player:get_inventory()
		for i, name in pairs({"customer_gives", "customer_gets"}) do
			if inv:get_size(name) > 0 then
				local leftover = list_add_list(inv, "main", inv:get_list(name))
				list_add_list(inv, "craft", leftover)
				inv:set_size(name, 0)
			end
		end
	end)
end
