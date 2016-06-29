local mapmgr = require "map"

local map
local add_avatar_flag = false

map = mapmgr.create_map()
map:init(1, 600, 600)
map:dump_map_grid()

local player1 = {}
function player1:get_avatar_id()
	return 1
end
function player1:gen_del_avatar_event()
	return {}
end
function player1:gen_add_avatar_event()
	return {}
end
function player1:gen_mov_avatar_event()
	return {}
end
function player1:need_aoi_process()
	return true
end
function player1:push_aoi()
	assert(event)
	assert(event.name == "player2")
	assert(event.avatar_id == 2)
	add_avatar_flag = true
end
player1.x = 100
player1.y = 200
map:add_avatar( player1, player1.x, player1.y )

----
local player2 = {}
function player2:get_avatar_id()
	return 2
end
function player2:gen_del_avatar_event()
	return {}
end
function player2:gen_add_avatar_event()
	return {
		name = "player2",
		avatar_id = self:get_avatar_id()
	}
end
function player2:gen_mov_avatar_event()
	return {}
end
function player2:need_aoi_process()
	return true
end
function player2:push_aoi()
end
player2.x = 101
player2.y = 201
map:add_avatar( player2, player2.x, player2.y )
assert( add_avatar_flag )
