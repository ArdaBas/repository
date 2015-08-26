
local entity = ...

entity.can_save_state = true

-- Platform: entity which moves in either horizontally or vertically (depending on direction) and carries the hero on it.

local speed = 50
local time_stopped = 1000
local direction, dx, dy, is_moving = false

function entity:on_created()
  --self:create_sprite("entities/platform")
  self:set_size(32, 32)
  self:set_origin(16, 16)
  self:set_can_traverse("jumper", true)
  self:set_can_traverse_ground("hole", true)
  self:set_can_traverse_ground("deep_water", true)
  self:set_can_traverse_ground("traversable", true)
  self:set_can_traverse_ground("shallow_water", true)
  self:set_can_traverse_ground("wall", false)
  self:set_modified_ground("traversable")
  
  direction = self:get_sprite():get_direction()
  dx, dy = 0, 0 --Variables for the translation.
  if direction == 0 then dx = 1
  elseif direction == 1 then dy = -1
  elseif direction == 2 then dx = -1
  elseif direction == 3 then dy = 1
  end
  local m = sol.movement.create("path")
  m:set_path{direction * 2}; m:set_speed(speed); m:set_loop(true); m:start(self)
  is_moving = true
  
  self:add_collision_test("facing", function(platform, other)
    if other:get_type() == "wall" and other:get_type() ~= "jumper" then
      self:on_obstacle_reached(m)
    end
  end)

end

function entity:on_obstacle_reached(movement)
  --Make the platform turn back.
  movement:stop(); is_moving = false
  movement = sol.movement.create("path")    
  direction = (direction+2)%4
  self:get_sprite():set_direction(direction)
  movement:set_path{direction * 2}
  movement:set_speed(speed)
  movement:set_loop(true)
  dx = -dx; dy = -dy
  sol.timer.start(self, time_stopped, function() movement:start(self); is_moving = true end)
end

function entity:on_position_changed()
  -- Move the movable entities located over the platform. 
  local movable_entities = entity:get_movable_entities()
  local x, y, z = self:get_position()
  for _, something  in pairs(movable_entities) do
    if self:is_on_platform(something) then    
	    local sx, sy, sz = something:get_position()
      -- If the other entity is on the border of the platform and not walking, move it some pixels towards the center.
      local needs_centering = false
      if something:get_type() == "hero" then 
        if something:get_animation() ~= "walking" then 
          needs_centering = true 
        end 
      elseif something:get_sprite() then
        if something:get_sprite():get_animation() ~= "walking" then
          needs_centering = true
        end
      end
      if needs_centering then
        local bx, by, w, h = entity:get_bounding_box()
        if sx == bx or sx == bx+1 then sx = bx+2 elseif sx == bx+w or sx == bx+w-1 then sx = bx+w-2 end 
        if sy == by or sy == by+1 then sy = by+2 elseif sy == by+h or sy == by+h-1 then sy = by+h-2 end
        something:set_position(sx, sy, sz)
      end
      -- Move the entity with the platform.
      sx, sy, sz = something:get_position()
      if not something:test_obstacles(dx, dy, sz) then something:set_position(sx + dx, sy + dy, sz) end
    end
  end
end

function entity:is_on_platform(other_entity)
  --Returns true if other_entity is on the platform.
  if other_entity.is_portable and other_entity.state ~= "on_ground" then return false end
  local ox, oy, ol = other_entity:get_position()
  local ex, ey, el = self:get_position()
  if ol ~= el then return false end
  local sx, sy = self:get_size()
  if math.abs(ox - ex) <= sx/2 and math.abs(oy - ey) <= sy/2 then return true end
  return false
end

function entity:get_movable_entities()
  --Return the list of entities on the map that can be moved by the platform. 
  local movable_entities = {}
  local hero = self:get_game():get_hero(); table.insert(movable_entities, hero) 
  for other in self:get_map():get_entities("") do
    if other.moved_on_platform then table.insert(movable_entities, other) end
  end	
  return movable_entities
end

-- Return direction, speed, and boolean is_moving. To use as inertia of thrown items.
function entity:get_inertia() return direction, speed, is_moving end

