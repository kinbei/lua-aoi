-- local create_map_grid = require "mapgrid"

local mapmgr = {}

local MAP_GRID_WIDTH = 100
local MAP_GRID_HEIGHT = 100
local LOD_GRID = 1
local LOD_SCREEN = 2
local LOD_LITTLEMAP = 3

local function create_map_grid(left, top, right, bottom)
	-- todo
	return { left = left, top = top, right = right, bottom = bottom }
end

--[[
avatar: shoule be provide the functions below:
get_aoi_x()
get_aoi_y()
get_avatar_id()
gen_del_avatar_event()
gen_add_avatar_event()
gen_mov_avatar_event()
--]]

-- return the grid according to the x, y coordinates
local function get_map_grid(self, x, y)
	if x >= self.width or y >= self.height then
		return nil
	end
	local idx_x = math.floor(x/MAP_GRID_WIDTH)
	local idx_y = math.floor(y/MAP_GRID_HEIGHT)
	return self.map_grid[idx_x][idx_y], idx_x, idx_y
end


local function broadcast_grid(self, avatar, event)
	local map_grid = self.get_map_grid(avatar.get_aoi_x(), avatar.get_aoi_y())
	if map_grid ~= nil then
		return
	end
	map_grid.broadcast(avatar, event)
end

local function broadcast_screen(self, avatar, event)
	local map_grid, idx_x, idx_y = self.get_map_grid(avatar.get_aoi_x(), avatar.get_aoi_y())
	if map_grid ~= nil then
		return
	end
	self.map_grid[idx_x][idx_y].broadcast(avatar, event)

	local xb = math.max(idx_x - 1, 1)
	local xe = math.min(idx_x + 1, self.xcount)
	local yb = math.max(idx_y - 1, 1)
	local ye = math.min(idx_y + 1, self.ycount)

	for x = xb, xe do
		for y = yb, ye do
			if not ( x == idx_x and y == idx_y ) then
				self.map_grid[x][y].broadcast(avatar, event)
			end
		end
	end
end

local function broadcast_littlemap(self, avatar, event)
	for _, v in ipairs(self.map_grid) do
		for _, map_grid in ipairs(v) do
			map_grid.broadcast(avatar, event)
		end
	end
end

local broadcast_func = {}
broadcast_func[LOD_GRID] = broadcast_grid
broadcast_func[LOD_SCREEN] = broadcast_screen
broadcast_func[LOD_LITTLEMAP] = broadcast_littlemap

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
				xbegin + 1, 
				ybegin + 1,
				math.min(xbegin + MAP_GRID_WIDTH,  self.width),
				math.min(ybegin + MAP_GRID_HEIGHT, self.height)
			)
		end
	end

	self.id = map_id
end

local function broadcast(self, avatar, event, event_lod)
	if not self.init then
		return
	end
	broadcast_func[event_lod](self, avatar, event)
end

-- For debug
local function dump_map_grid(self)
	print("Dump map grid")
	print("-----------------------------")
	local r
	for i = 1, self.ycount do
		r = ""
		for j = 1, self.xcount do
			local grid = self.map_grid[j][i]
			r = r .. string.format("[%d-%d (%03d,%03d)-(%03d,%03d)] ", j, i, grid.left, grid.top, grid.right, grid.bottom)
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

function mapmgr.create_map()
	local map = {}
	map.id = 0
	map.width = 0
	map.height = 0
	map.map_grid = {}

	-- The count of map grid
	map.xcount = 0
	map.ycount = 0

	-- Functions
	map.init = init
	map.broadcast = broadcast

	-- For debug
	map.dump_map_grid = dump_map_grid
	return map
end
return mapmgr
