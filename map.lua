local create_map_grid = require "mapgrid"

local MAP_GRID_WIDTH = 100
local MAP_GRID_HEIGHT = 100

local debug = function(fmt, ...) print(string.format(fmt, ...)) end
local dassert = assert

--[[
map_grid shoule be provide the functions below:
broadcast(avatar, event)

avatar shoule be provide the functions below:
get_avatar_id()
gen_del_avatar_event()
gen_add_avatar_event()
gen_mov_avatar_event()
need_aoi_process()
push_aoi()
--]]

-- return the grid according to the x, y coordinates
local function get_map_grid(self, x, y)	
	assert(x)
	assert(y)
	if x > self.width or y > self.height then
		return nil
	end
	local idx_x = math.ceil(x/MAP_GRID_WIDTH)
	local idx_y = math.ceil(y/MAP_GRID_HEIGHT)
	return self.map_grid[idx_x][idx_y]
end

local function broadcast_grid(self, x, y, avatar, event)
	assert(self.map_grid[x] and self.map_grid[x][y])
	if self.map_grid[x][y] == nil then
		return
	end
	self.map_grid[x][y]:broadcast(avatar, event)
end

local function broadcast_screen(self, x, y, avatar, event)
	if self.map_grid[x][y] == nil then
		return
	end
	self.map_grid[x][y]:broadcast(avatar, event)

	local xb = math.max(x - 1, 1)
	local xe = math.min(x + 1, self.xcount)
	local yb = math.max(y - 1, 1)
	local ye = math.min(y + 1, self.ycount)

	for i = xb, xe do
		for j = yb, ye do
			if not ( i == x and j == y ) then
				self.map_grid[i][j]:broadcast(avatar, event)
			end
		end
	end
end

local function broadcast_screen_new_player(self, avatar, x, y)
	if self.map_grid[x][y] == nil then
		return
	end
	
	local xb = math.max(x - 1, 1)
	local xe = math.min(x + 1, self.xcount)
	local yb = math.max(y - 1, 1)
	local ye = math.min(y + 1, self.ycount)

	for i = xb, xe do
		for j = yb, ye do
			for avatar_id, a in pairs(self.map_grid[i][j].all_avatar) do
				avatar:push_aoi(a:gen_add_avatar_event())
			end
		end
	end
end

local function broadcast_littlemap(self, avatar, event)
	for _, v in ipairs(self.map_grid) do
		for _, map_grid in ipairs(v) do
			map_grid:broadcast(avatar, event)
		end
	end
end

local function init(self, map_id, width, height)
	assert(self.id == 0)
	self.width = width
	self.height = height

	-- Calc the count of map grid
	self.xcount = self.width / MAP_GRID_WIDTH
	if ( self.width % MAP_GRID_WIDTH ) > 0 then
		self.xcount = self.xcount + 1
	end
	self.ycount = self.height / MAP_GRID_HEIGHT
	if ( self.height % MAP_GRID_HEIGHT ) > 0 then
		self.ycount = self.ycount + 1
	end

	for x = 1, self.xcount do
		self.map_grid[x] = self.map_grid[x] or {}
		local xbegin = (x - 1)*MAP_GRID_WIDTH

		for y = 1, self.ycount do
			local ybegin = (y - 1)*MAP_GRID_HEIGHT
			self.map_grid[x][y] = create_map_grid(
				x,
				y,
				xbegin + 1, 
				ybegin + 1,
				math.min(xbegin + MAP_GRID_WIDTH,  self.width),
				math.min(ybegin + MAP_GRID_HEIGHT, self.height)
			)
		end
	end

	self.id = map_id
end

local function add_avatar(self, avatar, x, y)
	local grid = assert( get_map_grid(self, x, y) )
	broadcast_screen_new_player(self, avatar, grid.x, grid.y)
	broadcast_screen(self, grid.x, grid.y, avatar, avatar:gen_add_avatar_event())
	grid:add_avatar(avatar)
end

local function del_avatar(self, avatar, x, y)
	local grid = assert( get_map_grid(self, x, y) )
	grid:del_avatar(avatar)
	broadcast_screen(self, grid.x, grid.y, avatar, avatar:gen_del_avatar_event())
end

local function isinrange(x, y, left, top, right, bottom)
	if x >= left and x <= right and y >= top and y <= bottom then
		return true
	else
		return false
	end
end

local function get_rect(x, y, xcount, ycount, distance)
	return math.max(0, x - distance), math.max(0, y - distance), math.min(x + distance, xcount), math.min(y + distance, ycount)
end

local function mov_avatar(self, avatar, source_x, source_y, dest_x, dest_y)
	local source_grid = assert( get_map_grid(self, source_x, source_y) )
	local dest_grid = assert( get_map_grid(self, dest_x, dest_y) )

	-- The source grid and dest grid must be adjacent to each other
	assert( (math.abs(source_grid.x - dest_grid.x) == 1) or (math.abs(source_grid.y - dest_grid.y) == 1) )
	
	if source_grid ~= dest_grid then
		source_grid:del_avatar(avatar)
		dest_grid:add_avatar(avatar)
	end

	for x = math.max(source_grid.x - 2, 1), math.min(source_grid.x + 2, self.xcount) do
		for y = math.max(source_grid.y - 2, 1), math.min(source_grid.y + 2, self.ycount) do
			-- debug("grid(%d-%d) (%d,%d,%d,%d)", x, y, get_rect(source_grid.x, source_grid.y, self.xcount, self.ycount, 1))
			-- debug("            (%d,%d,%d,%d)", get_rect(dest_grid.x, dest_grid.y, self.xcount, self.ycount, 1))
			if isinrange(x, y, get_rect(source_grid.x, source_grid.y, self.xcount, self.ycount, 1)) and 
			   isinrange(x, y, get_rect(dest_grid.x, dest_grid.y, self.xcount, self.ycount, 1)) then
				broadcast_grid(self, x, y, avatar, avatar:gen_mov_avatar_event())
			elseif isinrange(x, y, get_rect(source_grid.x, source_grid.y, self.xcount, self.ycount, 1)) then
				broadcast_grid(self, x, y, avatar, avatar:gen_del_avatar_event())
			elseif isinrange(x, y, get_rect(dest_grid.x, dest_grid.y, self.xcount, self.ycount, 1)) then
				broadcast_grid(self, x, y, avatar, avatar:gen_add_avatar_event())
			end
		end
	end
end

-- For debug
local function dump(self)
	print("Dump map grid")
	print("-----------------------------")
	local r
	for i = 1, self.ycount do
		r = ""
		for j = 1, self.xcount do
			local grid = self.map_grid[j][i]
			-- r = r .. string.format("[%d-%d (%03d,%03d)-(%03d,%03d)] ", j, i, grid.left, grid.top, grid.right, grid.bottom)
			r = r .. string.format("[%d-%d] ", j, i)
			--[[
			print(string.format("assert( map.map_grid[%d][%d].left == %d )", j, i, grid.left))
			print(string.format("assert( map.map_grid[%d][%d].top == %d )", j, i, grid.top))
			print(string.format("assert( map.map_grid[%d][%d].right == %d )", j, i, grid.right))
			print(string.format("assert( map.map_grid[%d][%d].bottom == %d )", j, i, grid.bottom))
			--]]
		end
		print(r)
	end
	print("-----------------------------")
end

local function create(map_id, width, height)
	local map = {}
	map.id = 0
	map.width = 0
	map.height = 0
	map.map_grid = {}

	-- The count of map grid
	map.xcount = 0
	map.ycount = 0

	-- Functions
	map.broadcast = broadcast
	map.broadcast_grid = broadcast_grid
	map.broadcast_screen = broadcast_screen
	map.broadcast_littlemap = broadcast_littlemap
	map.add_avatar = add_avatar
	map.del_avatar = del_avatar
	map.mov_avatar = mov_avatar

	-- For debug
	map.dump = dump

	-- init
	init(map, map_id, width, height)
	return map
end
return create
