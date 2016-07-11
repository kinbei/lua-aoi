-- Normal test case for mov_avatar()

local create_map = require "map"
local create_player = require "player"

local debug = function(fmt, ...) print(string.format(fmt, ...)) end

local avatar_id = 0
local function gen_avatar_id()
	avatar_id = avatar_id + 1
	return avatar_id
end

local AVATAR_EVENT_ADD = 1
local AVATAR_EVENT_DEL = 2
local AVATAR_EVENT_MOV = 3

local function check_common(chk_player, chk_idx, aoi_event, player)
	assert( aoi_event.avatar_id == player:get_avatar_id(), 
		string.format("aoi_avatar_id(%d) chk_avatar_id(%d) when check avatar_id(%d) idx(%d)", 
			aoi_event.avatar_id, player:get_avatar_id(), chk_player:get_avatar_id(), chk_idx) 
	)
	assert( aoi_event.nickname == player.nickname, 
		string.format("aoi_nickname(%s) chk_nickname(%s) when check avatar_id(%d) idx(%d)", 
			aoi_event.nickname, player.nickname, chk_player:get_avatar_id(), chk_idx) 
	)
end

local function check_add_avatar(chk_player, chk_idx, aoi_event, player)
	check_common(chk_player, chk_idx, aoi_event, player)
	assert(aoi_event.event_type == AVATAR_EVENT_ADD,
		string.format("invalid event_type(%d) when check avatar_id(%d) idx(%d)", aoi_event.event_type, chk_player:get_avatar_id(), chk_idx)
	)
end

local function check_del_avatar(chk_player, chk_idx, aoi_event, player)
	check_common(chk_player, chk_idx, aoi_event, player)
	assert(aoi_event.event_type == AVATAR_EVENT_DEL,
		string.format("invalid event_type(%d) when check avatar_id(%d) idx(%d)", aoi_event.event_type, chk_player:get_avatar_id(), chk_idx)
	)
end

local function check_mov_avatar(chk_player, chk_idx, aoi_event, player)
	check_common(chk_player, chk_idx, aoi_event, player)
	assert(aoi_event.event_type == AVATAR_EVENT_MOV, 
		string.format("invalid event_type(%d) when check avatar_id(%d) idx(%d)", aoi_event.event_type, chk_player:get_avatar_id(), chk_idx)
	)
end

-- player --> { avatar_id = player, ... }
-- avatar_id the avatar id of the player that want to check
-- chk_aoi: the test case of check aoi
-- chk_aoi = { {avatar_id, check_function}, ... }
-- check_function = function(avatar, aoi_event)
local function check_aoi_list(tbl_player, chk_player, chk_aoi)
	assert(#chk_player.aoi_list == #chk_aoi, 
		string.format("[aoi count](%d) [check count](%d) when check avatar_id(%d)", #chk_player.aoi_list, #chk_aoi, chk_player:get_avatar_id())
	)

	for i = 1, #chk_aoi do
		local avatar_id = assert(chk_aoi[i][1])
		local aoi_chk_func = assert(chk_aoi[i][2])
		local player = assert(tbl_player[avatar_id])
		aoi_chk_func(chk_player, i, chk_player.aoi_list[i], player)
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

local function gen_player_pos(map, grid_x, grid_y)
	assert(map.map_grid[grid_x])
	local grid = assert(map.map_grid[grid_x][grid_y])
	local x = math.random(grid.left, grid.right)
	local y = math.random(grid.top, grid.bottom)
	return x, y
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

	local tbl_player = {}
	for _, v in ipairs(t) do
		local grid_x = assert(v.grid[1])
		local grid_y = assert(v.grid[2])
		local player = create_player(gen_avatar_id(), map, grid_x, grid_y)
		tbl_player[#tbl_player+1] = player

		map:add_avatar(player, player.x, player.y)
	end

	for _, player in ipairs(tbl_player) do
		player:clear_aoi()
	end

	for idx, v in ipairs(t) do
		local player = assert(tbl_player[idx])
		if v.move_to_grid and v.move_to_grid[1] and v.move_to_grid[2] then
			local move_to_grid_x = assert(v.move_to_grid[1])
			local move_to_grid_y = assert(v.move_to_grid[2])
			local pos_x, pos_y = gen_player_pos(map, move_to_grid_x, move_to_grid_y)
			map:mov_avatar(player, player.x, player.y, pos_x, pos_y)
		end
	end

	for avatar_id, v in ipairs(t) do
		check_aoi_list(tbl_player, tbl_player[avatar_id], v.chk_aoi)
	end
end

local function test_map_add_avatar(width, height)
	local add_avatar = check_add_avatar
	local mov_avatar = check_mov_avatar
	local del_avatar = check_del_avatar
	local mov_avatar_id = 0

	-- test case 1 corners
	--[[
	left top
	[1-1(01)] [2-1(02)] [3-1(03)] [4-1(04)]
	[1-2(05)] [2-2(06)] [3-2(07)] [4-2(08)]
	[1-3(09)] [2-3(10)] [3-3(11)] [4-3(12)]
	[1-4(13)] [2-4(14)] [3-4(15)] [4-4(16)]
	avatar(11) move to [3-3] from [2-2]
	--]]
	mov_avatar_id = 11
	test_aoi(width, height, {
		[1] = { grid = {1, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[2] = { grid = {2, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[3] = { grid = {3, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[4] = { grid = {4, 1}, move_to_grid = {}, chk_aoi = {} },
		[5] = { grid = {1, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[6] = { grid = {2, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[7] = { grid = {3, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[8] = { grid = {4, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[9] = { grid = {1, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[10] = { grid = {2, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[11] = { grid = {3, 3}, move_to_grid = {2, 2}, chk_aoi = {} },
		[12] = { grid = {4, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[13] = { grid = {1, 4}, move_to_grid = {}, chk_aoi = {} },
		[14] = { grid = {2, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[15] = { grid = {3, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[16] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
	})

	--[[
	right top
	[3-1(01)] [4-1(02)] [5-1(03)] [6-1(04)] 
	[3-2(05)] [4-2(06)] [5-2(07)] [6-2(08)] 
	[3-3(09)] [4-3(10)] [5-3(11)] [6-3(12)] 
	[3-4(13)] [4-4(14)] [5-4(15)] [6-4(16)]
	avatar(10) move to [5-2] from [4-3]
	--]]
	mov_avatar_id = 10
	test_aoi(width, height, {
		[1] = { grid = {3, 1}, move_to_grid = {}, chk_aoi = {} },
		[2] = { grid = {4, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[3] = { grid = {5, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[4] = { grid = {6, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[5] = { grid = {3, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[6] = { grid = {4, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[7] = { grid = {5, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[8] = { grid = {6, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[9] = { grid = {3, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[10] = { grid = {4, 3}, move_to_grid = {5, 2}, chk_aoi = {} },
		[11] = { grid = {5, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[12] = { grid = {6, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[13] = { grid = {3, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[14] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[15] = { grid = {5, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[16] = { grid = {6, 4}, move_to_grid = {}, chk_aoi = {} },
	})

	--[[
	left bottom
	[1-3(01)] [2-3(02)] [3-3(03)] [4-3(04)]  
	[1-4(05)] [2-4(06)] [3-4(07)] [4-4(08)]  
	[1-5(09)] [2-5(10)] [3-5(11)] [4-5(12)]  
	[1-6(13)] [2-6(14)] [3-6(15)] [4-6(16)]
	avatar(07) move to [2-5] from [3-4]
	--]]
	mov_avatar_id = 7
	test_aoi(width, height, {
		[1] = { grid = {1, 3}, move_to_grid = {}, chk_aoi = {} },
		[2] = { grid = {2, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[3] = { grid = {3, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[4] = { grid = {4, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[5] = { grid = {1, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[6] = { grid = {2, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[7] = { grid = {3, 4}, move_to_grid = {2, 5}, chk_aoi = {} },
		[8] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[9] = { grid = {1, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[10] = { grid = {2, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[11] = { grid = {3, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[12] = { grid = {4, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[13] = { grid = {1, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[14] = { grid = {2, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[15] = { grid = {3, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[16] = { grid = {4, 6}, move_to_grid = {}, chk_aoi = {} },
	})


	--[[
	right bottom
	[3-3(01)] [4-3(02)] [5-3(03)] [6-3(04)] 
	[3-4(05)] [4-4(06)] [5-4(07)] [6-4(08)] 
	[3-5(09)] [4-5(10)] [5-5(11)] [6-5(12)] 
	[3-6(13)] [4-6(14)] [5-6(15)] [6-6(16)] 
	avatar(06) move to [5-5] from [4-4]
	--]]
	mov_avatar_id = 7
	test_aoi(width, height, {
		[1] = { grid = {1, 3}, move_to_grid = {}, chk_aoi = {} },
		[2] = { grid = {2, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[3] = { grid = {3, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[4] = { grid = {4, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[5] = { grid = {1, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[6] = { grid = {2, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[7] = { grid = {3, 4}, move_to_grid = {2, 5}, chk_aoi = {} },
		[8] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[9] = { grid = {1, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[10] = { grid = {2, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[11] = { grid = {3, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[12] = { grid = {4, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[13] = { grid = {1, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[14] = { grid = {2, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[15] = { grid = {3, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[16] = { grid = {4, 6}, move_to_grid = {}, chk_aoi = {} },
	})

	-- test case 2 border

	--[[
	left
	[1-2(01)] [2-2(02)] [3-2(03)] [4-2(04)]
	[1-3(05)] [2-3(06)] [3-3(07)] [4-3(08)]
	[1-4(09)] [2-4(10)] [3-4(11)] [4-4(12)]
	[1-5(13)] [2-5(14)] [3-5(15)] [4-5(16)]
	avatar(11) move to [2-4] from [3-4]
	--]]
	mov_avatar_id = 11
	test_aoi(width, height, {
		[1] = { grid = {1, 2}, move_to_grid = {}, chk_aoi = {} },
		[2] = { grid = {2, 2}, move_to_grid = {}, chk_aoi = {} },
		[3] = { grid = {3, 2}, move_to_grid = {}, chk_aoi = {} },
		[4] = { grid = {4, 2}, move_to_grid = {}, chk_aoi = {} },
		[5] = { grid = {1, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[6] = { grid = {2, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[7] = { grid = {3, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[8] = { grid = {4, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[9] = { grid = {1, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[10] = { grid = {2, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[11] = { grid = {3, 4}, move_to_grid = {2, 4}, chk_aoi = {} },
		[12] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[13] = { grid = {1, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[14] = { grid = {2, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[15] = { grid = {3, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[16] = { grid = {4, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
	})

	-- top
	--[[
	[2-1(01)] [3-1(02)] [4-1(03)] [5-1(04)]
	[2-2(05)] [3-2(06)] [4-2(07)] [5-2(08)]
	[2-3(09)] [3-3(10)] [4-3(11)] [5-3(12)]
	[2-4(13)] [3-4(14)] [4-4(15)] [5-4(16)]
	avatar(11) move to [4-2] from [4-3]
	--]]
	mov_avatar_id = 11
	test_aoi(width, height, {
		[1] = { grid = {2, 1}, move_to_grid = {}, chk_aoi = {} },
		[2] = { grid = {3, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[3] = { grid = {4, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[4] = { grid = {5, 1}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[5] = { grid = {2, 2}, move_to_grid = {}, chk_aoi = {} },
		[6] = { grid = {3, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[7] = { grid = {4, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[8] = { grid = {5, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[9] = { grid = {2, 3}, move_to_grid = {}, chk_aoi = {} },
		[10] = { grid = {3, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[11] = { grid = {4, 3}, move_to_grid = {4, 2}, chk_aoi = {} },
		[12] = { grid = {5, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[13] = { grid = {2, 4}, move_to_grid = {}, chk_aoi = {} },
		[14] = { grid = {3, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[15] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[16] = { grid = {5, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
	})

	-- right
	--[[
	[3-2(01)] [4-2(02)] [5-2(03)] [6-2(04)] 
	[3-3(05)] [4-3(06)] [5-3(07)] [6-3(08)] 
	[3-4(09)] [4-4(10)] [5-4(11)] [6-4(12)] 
	[3-5(13)] [4-5(14)] [5-5(15)] [6-5(16)] 
	avatar(10) move to [5-4] from [4-4]
	--]]
	mov_avatar_id = 10
	test_aoi(width, height, {
		[1] = { grid = {3, 2}, move_to_grid = {}, chk_aoi = {} },
		[2] = { grid = {4, 2}, move_to_grid = {}, chk_aoi = {} },
		[3] = { grid = {5, 2}, move_to_grid = {}, chk_aoi = {} },
		[4] = { grid = {6, 2}, move_to_grid = {}, chk_aoi = {} },
		[5] = { grid = {3, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[6] = { grid = {4, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[7] = { grid = {5, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[8] = { grid = {6, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[9] = { grid = {3, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[10] = { grid = {4, 4}, move_to_grid = {5, 4}, chk_aoi = {} },
		[11] = { grid = {5, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[12] = { grid = {6, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[13] = { grid = {3, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[14] = { grid = {4, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[15] = { grid = {5, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[16] = { grid = {6, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
	})

	-- bottom
	--[[
	[2-3(01)] [3-3(02)] [4-3(03)] [5-3(04)]
	[2-4(05)] [3-4(06)] [4-4(07)] [5-4(08)]
	[2-5(09)] [3-5(10)] [4-5(11)] [5-5(12)]
	[2-6(13)] [3-6(14)] [4-6(15)] [5-6(16)]
	avatar(6) move to [3-5] from [3-4]
	--]]
	mov_avatar_id = 6
	test_aoi(width, height, {
		[1] = { grid = {2, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[2] = { grid = {3, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[3] = { grid = {4, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[4] = { grid = {5, 3}, move_to_grid = {}, chk_aoi = {} },
		[5] = { grid = {2, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[6] = { grid = {3, 4}, move_to_grid = {3, 5}, chk_aoi = {} },
		[7] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[8] = { grid = {5, 4}, move_to_grid = {}, chk_aoi = {} },
		[9] = { grid = {2, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[10] = { grid = {3, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[11] = { grid = {4, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[12] = { grid = {5, 5}, move_to_grid = {}, chk_aoi = {} },
		[13] = { grid = {2, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[14] = { grid = {3, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[15] = { grid = {4, 6}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[16] = { grid = {5, 6}, move_to_grid = {}, chk_aoi = {} },
	})

	-- test case 3 middle
	--[[
	[2-2(01)] [3-2(02)] [4-2(03)] [5-2(04)]
	[2-3(05)] [3-3(06)] [4-3(07)] [5-3(08)]
	[2-4(09)] [3-4(10)] [4-4(11)] [5-4(12)]
	[2-5(13)] [3-5(14)] [4-5(15)] [5-5(16)]
	avatar(6) move to [4-4] from [3-3]
	--]]
	mov_avatar_id = 6
	test_aoi(width, height, {
		[1] = { grid = {2, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[2] = { grid = {3, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[3] = { grid = {4, 2}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[4] = { grid = {5, 2}, move_to_grid = {}, chk_aoi = {} },
		[5] = { grid = {2, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[6] = { grid = {3, 3}, move_to_grid = {4, 4}, chk_aoi = {} },
		[7] = { grid = {4, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[8] = { grid = {5, 3}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[9] = { grid = {2, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, del_avatar}} },
		[10] = { grid = {3, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[11] = { grid = {4, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, mov_avatar}} },
		[12] = { grid = {5, 4}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[13] = { grid = {2, 5}, move_to_grid = {}, chk_aoi = {} },
		[14] = { grid = {3, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[15] = { grid = {4, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
		[16] = { grid = {5, 5}, move_to_grid = {}, chk_aoi = {{mov_avatar_id, add_avatar}} },
	})

end

test_map_add_avatar(600, 600)
test_map_add_avatar(501, 501)
