local AVATAR_TYPE_PLAYER = 1

local function get_avatar_id(self)
	return self.avatar_id
end

local function gen_del_avatar_event(self)
	return {
		avatar_id = self.avatar_id,
		nickname = self.nickname
	}
end

local function gen_add_avatar_event(self)
	return {
		avatar_id = self.avatar_id,
		nickname = self.nickname
	}
end

local function gen_mov_avatar_event(self)
	return {
		avatar_id = self.avatar_id,
	}
end

local function need_aoi_process()
	return true
end

local function push_aoi(self, event)
	self.aoi_list[#self.aoi_list + 1] = event
end

local function get_avatar_type()
	return AVATAR_TYPE_PLAYER
end

local function clear_aoi(self)
	self.aoi_list = {}
end

local function gen_player_pos(map, grid_x, grid_y)
	assert(map.map_grid[grid_x])
	local grid = assert(map.map_grid[grid_x][grid_y])
	local x = math.random(grid.left, grid.right)
	local y = math.random(grid.top, grid.bottom)
	return x, y
end

local function create(avatar_id, map, grid_x, grid_y)
	local player = {}

	-- 
	player.avatar_id = avatar_id
	player.nickname = string.format("player%d", avatar_id)
	player.x, player.y = gen_player_pos(map, grid_x, grid_y)
	player.grid_x = grid_x
	player.grid_y = grid_y
	player.aoi_list = {}

	-- Functions for player
	player.get_avatar_id = get_avatar_id
	player.gen_del_avatar_event = gen_del_avatar_event
	player.gen_add_avatar_event = gen_add_avatar_event
	player.gen_mov_avatar_event = gen_mov_avatar_event
	player.need_aoi_process = need_aoi_process
	player.push_aoi = push_aoi
	player.get_avatar_type = get_avatar_type

	--
	player.clear_aoi = clear_aoi
	return player
end

return create
