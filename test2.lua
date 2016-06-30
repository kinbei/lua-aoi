-- Normal test case for add_avatar()

local create_map = require "map"
local create_player = require "player"

local avatar_id = 0
local function gen_avatar_id()
	avatar_id = avatar_id + 1
	return avatar_id
end

local function check_aoi_list(player, ...)
	local t = table.pack(...)
	if not(#player.aoi_list == #t) then
		for _, v in ipairs(player.aoi_list) do
			print(string.format("aoi avatar_id(%d) grid(%s,%s)", v.avatar_id, player.grid_x, player.grid_y))
		end
		for _, v in ipairs(t) do
			print(string.format("check avatar_id(%d)", v))
		end
	end
	assert(#player.aoi_list == #t, string.format("aoilist(%d) checklist(%d)", #player.aoi_list, #t))
	for i = 1, #t do
		local avatar_id = i
		local nickname = string.format("player%s", t[i])
		assert( player.aoi_list[i].avatar_id == t[i], string.format("avatar_id(%d) check_id(%d)", player.aoi_list[i].avatar_id, t[i]) )
		assert( player.aoi_list[i].nickname == nickname )
	end
end

--[[
-----------------------------
[1-1] [2-1] [3-1] [4-1] [5-1] [6-1] 
[1-2] [2-2] [3-2] [4-2] [5-2] [6-2] 
[1-3] [2-3] [3-3] [4-3] [5-3] [6-3] 
[1-4] [2-4] [3-4] [4-4] [5-4] [6-4] 
[1-5] [2-5] [3-5] [4-5] [5-5] [6-5] 
[1-6] [2-6] [3-6] [4-6] [5-6] [6-6] 
-----------------------------
]]--

-- test case 1
do
	local function test_corners_aoi(t)
		avatar_id = 0
		local map = create_map(1, 600, 600)

		local player = {}
		for _, v in ipairs(t) do
			local grid_x = assert(v[1])
			local grid_y = assert(v[2])
			player[#player+1] = create_player(gen_avatar_id(), map, grid_x, grid_y)
		end

		map:add_avatar( player[2], player[2].x, player[2].y )
		map:add_avatar( player[3], player[3].x, player[3].y )
		map:add_avatar( player[4], player[4].x, player[4].y )
		map:add_avatar( player[1], player[1].x, player[1].y )

		-- add avatar event --> { avatar_id = xx, nickname = xx }
		local function get_avatar_cmp_seq(t1, t2)
			table.sort(t1, function(a, b)
				if player[a].grid_x < player[b].grid_x then
					return true
				else
					return player[a].grid_y < player[b].grid_y
				end
			end)
			local r = {}
			table.move(t1, 1, #t1, #r + 1, r)
			table.move(t2, 1, #t2, #r + 1, r)
			return table.unpack(r)
		end

		check_aoi_list(player[1], get_avatar_cmp_seq({2, 3, 4}, {}))
		check_aoi_list(player[2], get_avatar_cmp_seq({}, {3, 4, 1}))
		check_aoi_list(player[3], get_avatar_cmp_seq({}, {2, 4, 1}))
		check_aoi_list(player[4], get_avatar_cmp_seq({2, 3}, {1}))
	end

	test_corners_aoi({{1, 1}, {2, 1}, {2, 2}, {1, 2}})
	test_corners_aoi({{1, 6}, {2, 5}, {1, 5}, {2, 6}})
	test_corners_aoi({{6, 1}, {5, 2}, {5, 1}, {6, 2}})
	test_corners_aoi({{6, 6}, {6, 5}, {5, 5}, {5, 6}})
end

-- test case 2
do
	local function test_border_aoi(t)
		avatar_id = 0
		local map = create_map(1, 600, 600)

		local player = {}
		for _, v in ipairs(t) do
			local grid_x = assert(v[1])
			local grid_y = assert(v[2])
			player[#player+1] = create_player(gen_avatar_id(), map, grid_x, grid_y)
		end

		map:add_avatar( player[2], player[2].x, player[2].y )
		map:add_avatar( player[3], player[3].x, player[3].y )
		map:add_avatar( player[4], player[4].x, player[4].y )
		map:add_avatar( player[5], player[5].x, player[5].y )
		map:add_avatar( player[1], player[1].x, player[1].y )

		-- add avatar event -- {avatar_id = xx, nickname = xx}
		local function get_avatar_cmp_seq(t1, t2)
			table.sort(t1, function(a, b)
				if player[a].grid_x < player[b].grid_x then
					return true
				else
					return player[a].grid_y < player[b].grid_y
				end
			end)
			local r = {}
			table.move(t1, 1, #t1, #r + 1, r)
			table.move(t2, 1, #t2, #r + 1, r)
			return table.unpack(r)
		end

		check_aoi_list(player[1], get_avatar_cmp_seq({2, 3, 4, 5}, {}))
		check_aoi_list(player[2], get_avatar_cmp_seq({}, {3, 4, 5, 1}))
		check_aoi_list(player[3], get_avatar_cmp_seq({2}, {4, 5, 1}))
		check_aoi_list(player[4], get_avatar_cmp_seq({2, 3}, {5, 1}))
	end

	test_border_aoi({{1, 3}, {1, 2}, {2, 2}, {2, 3}, {2, 4}, {1, 4}})
	test_border_aoi({{4, 1}, {5, 1}, {5, 2}, {4, 2}, {3, 1}, {3, 2}})
	test_border_aoi({{6, 4}, {5, 3}, {6, 3}, {5, 4}, {5, 5}, {6, 5}})
	test_border_aoi({{3, 6}, {2, 6}, {2, 5}, {3, 5}, {4, 5}, {4, 6}})
end