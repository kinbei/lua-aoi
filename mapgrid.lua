local function create_map_grid()  
  local map_grid = {}
  
  map_grid.left_top_x  = 0
  map_grid.left_top_y  = 0
  map_grid.right_bottom_x = 0
  map_grid.right_bottom_y = 0

  map_grid.index_x = 0
  map_grid.index_y = 0

  map_grid.neighbor_grids = {}

  map_grid.all_avatar = {}

  map_grid.player_count = 0

  function map_grid:init(top_x, top_y, width, height, index_x, index_y)
    self.left_top_x  = top_x
    self.left_top_y  = top_y
    self.right_bottom_x = top_x + width - 1
    self.right_bottom_y = top_y + height - 1
    self.index_x = index_x
    self.index_y = index_y
  end
  
  function map_grid:get_info()
    return string.format( "(%d,%d)-(%d,%d,%d,%d)[player-count:%d]", map_grid.index_x, map_grid.index_y, map_grid.left_top_x,map_grid.left_top_y,map_grid.right_bottom_x,map_grid.right_bottom_y, map_grid.player_count )
  end
    
  function map_grid:add_neighbor_map_grid( grid )
    local index_x = grid.index_x
    local index_y = grid.index_y
    
    if self.neighbor_grids[index_x] == nil then
      self.neighbor_grids[index_x] = {}
    end
    
    self.neighbor_grids[index_x][index_y] = grid
  end
  
  function map_grid:get_neighbor_grids()
    local grids = {}
    for k1, _ in pairs(self.neighbor_grids) do
      for k2, grid in pairs(self.neighbor_grids[k1]) do
        if grids[k1] == nil then
          grids[k1] = {}
        end
        
        grids[k1][k2] = grid
      end
    end
    
    return grids
  end
  
  function map_grid.add_avatar(avatar)   
    self.all_avatar[ avatar.get_avatar_id() ] = avatar
    
    if avatar.get_avatar_type() == DEFINE.AVATAR_TYPE_PLAYER then
      self.player_count = map_grid.player_count + 1
    end
  end
  
  function map_grid:del_avatar(avatar)   
    map_grid.all_avatar[ avatar.get_avatar_id() ] = nil
    
    if avatar.get_avatar_type() == DEFINE.AVATAR_TYPE_PLAYER and map_grid.player_count >= 1 then
      map_grid.player_count = map_grid.player_count - 1
    end
  end
  
  function map_grid:put_aoi_list( avatar, gen_event_fun )
    if avatar.get_avatar_type() ~= DEFINE.AVATAR_TYPE_PLAYER then 
      return 
    end
    
    for _, v in pairs(self.all_avatar) do
      if not v.get_is_hiding() then
        if v.get_avatar_id() ~= avatar.get_avatar_id() then
          avatar.put_aoi_list( gen_event_fun(v) )
        end
      end
    end
  end
  
  function map_grid:broadcast_event(avatar, event_data)
    for _, v in pairs(self.all_avatar) do
      if v.get_avatar_type() == DEFINE.AVATAR_TYPE_PLAYER then 
        if v.get_avatar_id() ~= avatar.get_avatar_id() then
          v.put_aoi_list( event_data )
        end      
      end
    end
  end
    
  return map_grid
end

return create_map_grid