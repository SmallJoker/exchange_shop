local S = exchange_shop.S

function exchange_shop.has_access(meta, player_name)
	local owner = meta:get_string("owner")
	if player_name == owner or owner == "" then
		return true
	end
	local privs = minetest.get_player_privs(player_name)
	return privs.server or privs.protection_bypass
end


-- Tool wear aware replacement for contains_item.
function exchange_shop.list_contains_item(inv, listname, stack)
	local count = stack:get_count()
	if count == 0 then
		return true
	end

	local list = inv:get_list(listname)
	local name = stack:get_name()
	local wear = stack:get_wear()
	for _, list_stack in ipairs(list) do
		if list_stack:get_name() == name and
		   list_stack:get_wear() <= wear then
			if list_stack:get_count() >= count then
				return true
			else
				count = count - list_stack:get_count()
			end
		end
	end
end

-- Tool wear aware replacement for remove_item.
function exchange_shop.list_remove_item(inv, listname, stack)
	local wanted_count = stack:get_count()
	if wanted_count == 0 then
		return stack
	end

	local list = inv:get_list(listname)
	local name = stack:get_name()
	local wear = stack:get_wear()

	-- Information about the removed stack
	-- this includes the metadata of the last taken stack
	local taken_stack = ItemStack()
	local remaining = wanted_count
	local removed_wear = 0

	for index, list_stack in ipairs(list) do
		if list_stack:get_name() == name and
				list_stack:get_wear() <= wear then
			-- Only sell better tools (less worn out)
			taken_stack = list_stack:take_item(remaining)
			inv:set_stack(listname, index, list_stack)

			removed_wear = math.max(removed_wear, taken_stack:get_wear())
			remaining = remaining - taken_stack:get_count()
			if remaining == 0 then
				break
			end
		end
	end

	-- For oversized stacks, ItemStack:add_item returns a leftover
	-- handle the stack count manually to avoid this issue
	taken_stack:set_count(wanted_count - remaining)
	taken_stack:set_wear(removed_wear)
	return taken_stack
end

function exchange_shop.exchange_action(player_inv, shop_inv, pos)
	if not shop_inv:is_empty("cust_ej")
			or not shop_inv:is_empty("custm_ej") then
		return S("One or multiple ejection fields are filled.") .. " " ..
			S("Please empty them or contact the shop owner.")
	end
	local owner_wants = shop_inv:get_list("cust_ow")
	local owner_gives = shop_inv:get_list("cust_og")

	-- Check validness of stack "owner wants"
	for i1, item1 in ipairs(owner_wants) do
		local name1 = item1:get_name()
		for i2, item2 in ipairs(owner_wants) do
			if name1 == "" then
				break
			end
			if i1 ~= i2 and name1 == item2:get_name() then
				return S("The field '@1' can not contain multiple times the same items.",
					S("You need")) .. " " .. S("Please contact the shop owner.")
			end
		end
	end

	-- Check validness of stack "owner gives"
	for i1, item1 in ipairs(owner_gives) do
		local name1 = item1:get_name()
		for i2, item2 in ipairs(owner_gives) do
			if name1 == "" then
				break
			end
			if i1 ~= i2 and name1 == item2:get_name() then
				return S("The field '@1' can not contain multiple times the same items.",
					S("You give")) .. " " .. S("Please contact the shop owner.")
			end
		end
	end

	-- Check for space in the shop
	for _, item in ipairs(owner_wants) do
		if not shop_inv:room_for_item("custm", item) then
			return S("The stock in this shop is full.") .. " " ..
				S("Please contact the shop owner.")
		end
	end

	local list_contains_item = exchange_shop.list_contains_item

	-- Check availability of the shop's items
	for _, item in ipairs(owner_gives) do
		if not list_contains_item(shop_inv, "stock", item) then
			return S("This shop is sold out.")
		end
	end

	-- Check for space in the player's inventory
	for _, item in ipairs(owner_gives) do
		if not player_inv:room_for_item("main", item) then
			return S("You do not have enough space in your inventory.")
		end
	end

	-- Check availability of the player's items
	for _, item in ipairs(owner_wants) do
		if not list_contains_item(player_inv, "main", item) then
			return S("You do not have the required items.")
		end
	end

	local list_remove_item = exchange_shop.list_remove_item

	-- Conditions are ok: (try to) exchange now
	local fully_exchanged = true
	for _, item in ipairs(owner_wants) do
		local stack = list_remove_item(player_inv, "main", item)
		if shop_inv:room_for_item("custm", stack) then
			shop_inv:add_item("custm", stack)
		else
			-- Move to ejection field
			shop_inv:add_item("custm_ej", stack)
			fully_exchanged = false
		end
	end
	for _, item in ipairs(owner_gives) do
		local stack = list_remove_item(shop_inv, "stock", item)
		if player_inv:room_for_item("main", stack) then
			player_inv:add_item("main", stack)
		else
			minetest.item_drop(stack, nil, pos)
			-- Move to ejection field
		--	shop_inv:add_item("cust_ej", stack)
		--	fully_exchanged = false
		end
	end
	if not fully_exchanged then
		return S("Warning! Stacks are overflowing somewhere!"), true
	end
end
