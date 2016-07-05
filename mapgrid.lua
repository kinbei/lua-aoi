local AVATAR_TYPE_PLAYER = 1

local function broadcast(self, avatar, event)
	for _, v in pairs(self.all_avatar) do
		if v:need_aoi_process() then
			if v:get_avatar_id() ~= avatar:get_avatar_id() then
				v:push_aoi(event)
			end
		end
	end
end

local function add_avatar(self, avatar)
	assert( self.all_avatar[avatar:get_avatar_id()] == nil )
	self.all_avatar[avatar:get_avatar_id()] = avatar
	if avatar:get_avatar_type() == AVATAR_TYPE_PLAYER then
		self.player_count = self.player_count + 1
	end
end

local function del_avatar(self, avatar)
	assert(avatar)
	assert( self.all_avatar[avatar:get_avatar_id()] )
	self.all_avatar[avatar:get_avatar_id()] = nil
	if avatar:get_avatar_type() == AVATAR_TYPE_PLAYER then
		self.player_count = self.player_count - 1
	end
end

local function create(idx_x, idx_y, left, top, right, bottom)
	local grid = {}

	grid.x = idx_x
	grid.y = idx_y
	grid.left = left
	grid.top = top
	grid.right = right
	grid.bottom = bottom
	
	grid.all_avatar = {} --> [avatar_id] = avatar
	grid.player_count = 0

	-- Functions
	grid.broadcast = broadcast
	grid.add_avatar = add_avatar
	grid.del_avatar = del_avatar

	return grid
end

return create
