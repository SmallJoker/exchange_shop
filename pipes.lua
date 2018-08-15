if minetest.get_modpath("pipeworks") then
	minetest.override_item(exchange_shop.shopname, {
		groups = {choppy=2, oddly_breakable_by_hand=2,
			tubedevice=1, tubedevice_receiver=1},
		tube = {
			insert_object = function(pos, node, stack, direction)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:add_item("stock", stack)
			end,
			can_insert = function(pos, node, stack, direction)
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				return inv:room_for_item("stock", stack)
			end,
			input_inventory = "custm",
			connect_sides = {left=1, right=1, back=1, top=1, bottom=1}
		}
	})
end

if minetest.get_modpath("tubelib") then
	tubelib.register_node(exchange_shop.shopname, {}, {
		on_pull_item = function(pos, side)
			local meta = minetest.get_meta(pos)
			return tubelib.get_item(meta, "custm")
		end,
		on_push_item = function(pos, side, item)
			local meta = minetest.get_meta(pos)
			return tubelib.put_item(meta, "stock", item)
		end,
		on_unpull_item = function(pos, side, item)
			local meta = minetest.get_meta(pos)
			return tubelib.put_item(meta, "stock", item)
		end,
	})

end
