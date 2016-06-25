local DEFINE = require "define"
local create_map_grid = require "map_grid"

local MAP_GRID_WIDTH = 100
local MAP_GRID_HEIGHT = 100

local LOD_GRID = 1
local LOD_SCREEN = 2
local LOD_LITTLEMAP = 3

local function create_map_grid(x, y, width, height)
	-- todo
	return {}
end

--[[
avatar: shoule be provide the functions below:
get_aoi_x()
get_aoi_y()
get_avatar_id()
gen_del_avatar_event()
gen_del_avatar_event()
--]]

local function get_neighbor_grid(idx_x, idx_y, grid_count_x, grid_count_y)
	local result = {}

	local xb = math.max(idx_x - 1, 0)
	local xe = math.min(idx_x + 1, grid_count_x)
	local yb = math.max(idx_y - 1, 0)
	local ye = math.min(idx_y + 1, grid_count_y)

	for x = xb, xe do
		for y = yb, ye do
			if not ( x == idx_x and y == idx_y ) then
				result[#result+1] = { idx_x = x, idx_y = y }
			end
		end
	end

	return result
end

local function get_rect(x, y, max_x, max_y, distance)
	return { top = math.max(0, x - distance), left = math.max(0, y - distance), right = math.min(x + distance, max_x), bottom = math.min(y + distance, max_y) }
end

local function init(self, map_id, width, height)
	assert( self.is_init == false )
	self.width = width
	self.height = height

	local xcount = 0
	local ycount = 0
	for x = 0, self.width - 1, MAP_GRID_WIDTH do
		ycount = 0
		for y = 0, self.height - 1, MAP_GRID_HEIGHT do
			self.map_grid[xcount] = self.map_grid[idx_x] or {}
			self.map_grid[xcount][ycount] = create_map_grid(x, y, math.min(MAP_GRID_WIDTH, self.width - x), math.min(MAP_GRID_HEIGHT, self.height - y))
			xcount = xcount + 1
		end
		ycount = ycount + 1
	end

	-- Get xcount, ycount of all the map grid in the scratchable latex of the grid
	xcount = xcount - 1
	ycount = ycount - 1
	for x = 0, xcount do
		for y = 0, ycount do
			self.neighbor_map_grid[x] = self.neighbor_map_grid[x] or {}
			self.neighbor_map_grid[x][y] = get_neighbor_map_grid(x, y, xcount, ycount)
		end
	end

	self.is_init = true
	self.id = map_id
end

local function get_map_grid(self, x, y)
	if x >= self.width or y >= self.height then
		return nil
	end
	local idx_x = math.floor(x/MAP_GRID_WIDTH)
	local idx_y = math.floor(y/MAP_GRID_HEIGHT)
	return self.map_grid[idx_x][idx_y], idx_x, idx_y
end

---
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
	self.map_grid[v.idx_x][v.idx_y].broadcast(avatar, event)
	for _, v in ipairs(self.neighbor_map_grid[idx_x][idx_y]) do
		self.map_grid[v.idx_x][v.idx_y].broadcast(avatar, event)
	end
end

local function broadcast_littlemap(self, avatar, event)
	for x, v in ipairs(self.map_grid) do
		for y, map_grid in ipairs(v) do
			map_grid.broadcast(avatar, event)
		end
	end
end
---
local broadcast_func = {}
broadcast_func[LOD_GRID] = broadcast_grid
broadcast_func[LOD_SCREEN] = broadcast_screen
broadcast_func[LOD_LITTLEMAP] = broadcast_littlemap

local function broadcast(self, avatar, event, event_lod)
	if not self.init then
		return
	end
	broadcast_func[event_lod](self, avatar, event)
end

local function add_avatar(self, avatar)
	if not self.init then
		return
	end
	broadcast_screen(self, avatar, avatar.gen_add_avatar_event())
end

local function del_avatar(self, avatar)
	if not self.init then
		return
	end
	broadcast_screen(self, avatar, avatar.gen_del_avatar_event())
end

local function isinrange(begin_x, begin_y, end_x, end_y, x, y)
	if x >= begin_x and x <= end_x and y >= begin_y and y <= end_y then
		return true
	else
		return false
	end
end

local function get_neighbor_map_grid(x, y)
	
end

local function mov_avatar(self, avatar, destx, desty)
	if not self.init then
		return
	end

	local bgrid, bidx_x, bidx_y = self.get_map_grid(avatar.get_aoi_x(), avatar.get_aoi_y())
	local egrid, eidx_x, eidx_y = self.get_map_grid(destx, desty)

	local add_grid = {}
	local del_grid = {}
	local mov_grid = {}

	for x = bidx_x - 2, bidx_x + 2 do
		for y = bidx_y - 2, bidx_y + 2 do
			
		end
	end

end

local function create_map()
	local map = {}
	map.id = 0
	map.player_count = 0
	map.is_init = false
	map.width = 0
	map.height = 0
	map.map_grid = {}
	map.neighbor_map_grid = {}
	map.all_avatar = {} -- avatar_id --> avatar

	-- functions
	map.init = init
	map.broadcast = broadcast
	map.add_avatar = add_avatar
	map.del_avatar = del_avatar
	map.mov_avatar = mov_avatar
	return map
end

