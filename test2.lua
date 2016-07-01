-- Normal test case for add_avatar() and del_avatar()

local create_map = require "map"
local create_player = require "player"

local debug = function(fmt, ...) print(string.format(fmt, ...)) end

local avatar_id = 0
local function gen_avatar_id()
	avatar_id = avatar_id + 1
	return avatar_id
end

local function check_aoi_list(player, ...)
	local t = table.pack(...)
	assert(#player.aoi_list == #t, string.format("[aoi count](%d) [check count](%d) when check avatar_id(%d)", #player.aoi_list, #t, player:get_avatar_id()))
	for i = 1, #t do
		local avatar_id = i
		local nickname = string.format("player%s", t[i])
		assert( player.aoi_list[i].avatar_id == t[i], string.format("avatar_id(%d) check_id(%d) when check avatar_id(%d)", player.aoi_list[i].avatar_id, t[i], player:get_avatar_id()) )
		assert( player.aoi_list[i].nickname == nickname, string.format("nickname(%s) check_nickname(%s) when check avatar_id(%d)", player.aoi_list[i].nickname, nickname, player:get_avatar_id()) )
	end
end

local function get_avatar_cmp_seq(player, t1, t2)
	assert( type(t1) == "table" )
	assert( type(t2) == "table" )

	table.sort(t1, function(a, b)
		if player[a].grid_x < player[b].grid_x then
			return true
		elseif player[a].grid_x > player[b].grid_x then
			return false
		else
			return player[a].grid_y < player[b].grid_y
		end
	end)
	local r = {}
	table.move(t1, 1, #t1, #r + 1, r)
	table.move(t2, 1, #t2, #r + 1, r)
	return table.unpack(r)
end

-- t --> { {grid = {x1, x2}, add_aoi_before = {y, y, ...}, add_aoi_after = {y, y, ...}, del_aoi = {z, z, ...} }, ... }
-- x1 means the idx_x of grid
-- x2 means the idx_y of grid
-- y/z means the avatar_id of avatar that you want to check
-- add_aoi_before means the id of avatars that have already exist on map
-- add_aoi_after means the id of avatars that add to map after this avatar
-- del_aoi means the id of del avatars
local function test_aoi(map_width, map_height, t)
	avatar_id = 0
	local map = create_map(1, map_width, map_height)

	-- check add avatar
	local player = {}
	for _, v in ipairs(t) do
		local grid_x = assert(v.grid[1])
		local grid_y = assert(v.grid[2])
		local avatar = create_player(gen_avatar_id(), map, grid_x, grid_y)
		player[#player+1] = avatar

		map:add_avatar(avatar, avatar.x, avatar.y)
	end

	for idx, v in ipairs(t) do
		check_aoi_list(player[idx], get_avatar_cmp_seq(player, v.add_aoi_before, v.add_aoi_after))
	end

	-- clear aoi
	for _, avatar in ipairs(player) do
		avatar:clear_aoi()
	end

	-- check del avatar
	for i = #t, 1, -1 do
		local avatar = player[i]
		map:del_avatar(avatar, avatar.x, avatar.y)		
	end

	for idx, v in ipairs(t) do
		check_aoi_list(player[idx], get_avatar_cmp_seq(player, {}, v.del_aoi))
	end
end

local function test_map_add_avatar(width, height)
	-- test case 1 corners
	--[[
	left top
	[1-1(4)] [2-1(1)]
	[1-2(3)] [2-2(2)]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {2, 1}, add_aoi_before = {},        add_aoi_after = {2, 3, 4}, del_aoi = {4, 3, 2} }, 
		[2] = { grid = {2, 2}, add_aoi_before = {1},       add_aoi_after = {3, 4},    del_aoi = {4, 3} },
		[3] = { grid = {1, 2}, add_aoi_before = {1, 2},    add_aoi_after = {4},       del_aoi = {4} },
		[4] = { grid = {1, 1}, add_aoi_before = {1, 2, 3}, add_aoi_after = {},        del_aoi = {} },
	})

	--[[
	right top
	[5-1(2)] [6-1(4)] 
	[5-2(1)] [6-2(3)]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {5, 2}, add_aoi_before = {},        add_aoi_after = {2, 3, 4}, del_aoi = {4, 3, 2} },
		[2] = { grid = {5, 1}, add_aoi_before = {1},       add_aoi_after = {3, 4},    del_aoi = {4, 3} },
		[3] = { grid = {6, 2}, add_aoi_before = {1, 2},    add_aoi_after = {4},       del_aoi = {4} },
		[4] = { grid = {6, 1}, add_aoi_before = {1, 2, 3}, add_aoi_after = {},        del_aoi = {} },
	})

	--[[
	left bottom
	[1-5(1)] [2-5(2)]
	[1-6(4)] [2-6(3)]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {1, 5}, add_aoi_before = {},        add_aoi_after = {2, 3, 4}, del_aoi = {4, 3, 2} },
		[2] = { grid = {2, 5}, add_aoi_before = {1},       add_aoi_after = {3, 4},    del_aoi = {4, 3} },
		[3] = { grid = {2, 6}, add_aoi_before = {1, 2},    add_aoi_after = {4},       del_aoi = {4} },
		[4] = { grid = {1, 6}, add_aoi_before = {1, 2, 3}, add_aoi_after = {},        del_aoi = {} },
	})

	--[[
	right bottom
	[5-5] [6-5] 
	[5-6] [6-6]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {1, 5}, add_aoi_before = {},        add_aoi_after = {2, 3, 4}, del_aoi = {4, 3, 2} },
		[2] = { grid = {2, 5}, add_aoi_before = {1},       add_aoi_after = {3, 4},    del_aoi = {4, 3} },
		[3] = { grid = {2, 6}, add_aoi_before = {1, 2},    add_aoi_after = {4},       del_aoi = {4} },
		[4] = { grid = {1, 6}, add_aoi_before = {1, 2, 3}, add_aoi_after = {},        del_aoi = {} },
	})

	-- test case 2 border

	--[[
	left
	[1-2(5)] [2-2(4)]
	[1-3(6)] [2-3(3)]
	[1-4(1)] [2-4(2)]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {1, 4}, add_aoi_before = {},              add_aoi_after = {2, 3, 6}, del_aoi = {6, 3, 2} },
		[2] = { grid = {2, 4}, add_aoi_before = {1},             add_aoi_after = {3, 6},    del_aoi = {6, 3} },
		[3] = { grid = {2, 3}, add_aoi_before = {1, 2},          add_aoi_after = {4, 5, 6}, del_aoi = {6, 5, 4} },
		[4] = { grid = {2, 2}, add_aoi_before = {3},             add_aoi_after = {5, 6},    del_aoi = {6, 5} },
		[5] = { grid = {1, 2}, add_aoi_before = {3, 4},          add_aoi_after = {6},       del_aoi = {6} },
		[6] = { grid = {1, 3}, add_aoi_before = {1, 2, 3, 4, 5}, add_aoi_after = {},        del_aoi = {} },
	})

	-- top
	--[[
	[3-1(4)] [4-1(6)] [5-1(1)]
	[3-2(5)] [4-2(3)] [5-2(2)]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {5, 1}, add_aoi_before = {},              add_aoi_after = {2, 3, 6}, del_aoi = {6, 3, 2} },
		[2] = { grid = {5, 2}, add_aoi_before = {1},             add_aoi_after = {3, 6},    del_aoi = {6, 3} },
		[3] = { grid = {4, 2}, add_aoi_before = {1, 2},          add_aoi_after = {4, 5, 6}, del_aoi = {6, 5, 4} },
		[4] = { grid = {3, 1}, add_aoi_before = {3},             add_aoi_after = {5, 6},    del_aoi = {6, 5} },
		[5] = { grid = {3, 2}, add_aoi_before = {3, 4},          add_aoi_after = {6},       del_aoi = {6} },
		[6] = { grid = {4, 1}, add_aoi_before = {1, 2, 3, 4, 5}, add_aoi_after = {},        del_aoi = {} },
	})

	-- right
	--[[
	[5-3(1)] [6-3(2)] 
	[5-4(3)] [6-4(6)] 
	[5-5(4)] [6-5(5)] 
	--]]
	test_aoi(width, height, {
		[1] = { grid = {5, 3}, add_aoi_before = {},              add_aoi_after = {2, 3, 6}, del_aoi = {6, 3, 2} },
		[2] = { grid = {6, 3}, add_aoi_before = {1},             add_aoi_after = {3, 6},    del_aoi = {6, 3} },
		[3] = { grid = {5, 4}, add_aoi_before = {1, 2},          add_aoi_after = {4, 5, 6}, del_aoi = {6, 5, 4} },
		[4] = { grid = {5, 5}, add_aoi_before = {3},             add_aoi_after = {5, 6},    del_aoi = {6, 5} },
		[5] = { grid = {6, 5}, add_aoi_before = {3, 4},          add_aoi_after = {6},       del_aoi = {6} },
		[6] = { grid = {6, 4}, add_aoi_before = {1, 2, 3, 4, 5}, add_aoi_after = {},        del_aoi = {} },
	})

	-- bottom
	--[[
	[2-5(1)] [3-5(2)] [4-5(3)] 
	[2-6(4)] [3-6(6)] [4-6(5)]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {2, 5}, add_aoi_before = {},              add_aoi_after = {2, 4, 6},    del_aoi = {6, 4, 2} },
		[2] = { grid = {3, 5}, add_aoi_before = {1},             add_aoi_after = {3, 4, 5, 6}, del_aoi = {6, 5, 4, 3} },
		[3] = { grid = {4, 5}, add_aoi_before = {2},             add_aoi_after = {5, 6},       del_aoi = {6, 5} },
		[4] = { grid = {2, 6}, add_aoi_before = {1, 2},          add_aoi_after = {6},          del_aoi = {6} },
		[5] = { grid = {4, 6}, add_aoi_before = {2, 3},          add_aoi_after = {6},          del_aoi = {6} },
		[6] = { grid = {3, 6}, add_aoi_before = {1, 2, 3, 4, 5}, add_aoi_after = {},           del_aoi = {} },
	})

	-- test case 3 middle
	--[[
	[2-2(2)] [3-2(3)] [4-2(4)]
	[2-3(5)] [3-3(9)] [4-3(6)]
	[2-4(7)] [3-4(8)] [4-4(1)]
	--]]
	test_aoi(width, height, {
		[1] = { grid = {4, 4}, add_aoi_before = {},                       add_aoi_after = {6, 8, 9}, del_aoi = {9, 8, 6} },
		[2] = { grid = {2, 2}, add_aoi_before = {},                       add_aoi_after = {3, 5, 9}, del_aoi = {9, 5, 3} },
		[3] = { grid = {3, 2}, add_aoi_before = {2},                      add_aoi_after = {4, 5, 6, 9}, del_aoi = {9, 6, 5, 4} },
		[4] = { grid = {4, 2}, add_aoi_before = {3},                      add_aoi_after = {6, 9}, del_aoi = {9, 6} },
		[5] = { grid = {2, 3}, add_aoi_before = {2, 3},                   add_aoi_after = {7, 8, 9}, del_aoi = {9, 8, 7} },
		[6] = { grid = {4, 3}, add_aoi_before = {1, 3, 4},                add_aoi_after = {8, 9}, del_aoi = {9, 8} },
		[7] = { grid = {2, 4}, add_aoi_before = {5},                      add_aoi_after = {8, 9}, del_aoi = {9, 8} },
		[8] = { grid = {3, 4}, add_aoi_before = {1, 5, 6, 7},             add_aoi_after = {9}, del_aoi = {9} },
		[9] = { grid = {3, 3}, add_aoi_before = {1, 2, 3, 4, 5, 6, 7, 8}, add_aoi_after = {}, del_aoi = {} },
	})

end

test_map_add_avatar(600, 600)
test_map_add_avatar(501, 501)
