local def = table.copy(minetest.registered_nodes["currency:shop"])
def.groups.not_in_creative_inventory = 1

minetest.override_item("currency:shop", {
	groups = def.groups,
	on_construct = function() end,
	after_place_node = function(pos, ...)
		local node = minetest.get_node(pos)
		node.name = exchange_shop.shopname
		minetest.swap_node(pos, node)

		local new_def = minetest.registered_nodes[exchange_shop.shopname]
		if new_def.on_construct then
			new_def.on_construct(pos)
		end
		new_def.after_place_node(pos, unpack({...}))

	end
})