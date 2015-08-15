
local wind = ...


local speed = 20

local direction, dx, dy

function wind:on_created()
  self:set_size(8, 8)
  direction = self:get_sprite():get_direction()
  dx, dy = 0, 0 --Variables for the translation.
  if direction == 0 then dx = 1
  elseif direction == 1 then dy = -1
  elseif direction == 2 then dx = -1
  elseif direction == 3 then dy = 1
  end
  self:start()
end

function wind:start()
  local m = sol.movement.create("path")
  m:set_path({0,4})
  m:set_speed(speed)
  m:set_loop(true)
  m:start(self)
  
end


function wind:on_position_changed()
  local movable_entities = self:get_movable_entities()
  for _,entity in pairs(movable_entities) do self:move_entity(entity) end
end


function wind:get_movable_entities()
  --Return the list of entities on the map that can be moved by the wind. 
  local movable_entities = {}
  local hero = self:get_game():get_hero()
  table.insert(movable_entities, hero)
  for other_hero in self:get_map():get_entities("npc_hero_") do table.insert(movable_entities, other_hero) end
  -----------------INSERT OTHER MOVABLE ENTITIES HERE!!!! -----------------------
  return movable_entities
end

function wind:move_entity(entity)
  -- Move an entity one pixel in the same direction of the wind. 
  local hx, hy, hl = entity:get_position()
  if not entity:test_obstacles(dx, dy, hl) then entity:set_position(hx + dx, hy + dy, hl) end
end



