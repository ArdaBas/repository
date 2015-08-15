
local flow = ...


local refresh_time = 40

local direction, fx, fy, fl, dx, dy
local map = flow:get_map()
local hero = map:get_hero()

function flow:on_created()
  self:set_size(8, 8)
  direction = self:get_sprite():get_direction()
  fx, fy, fl = self:get_position()
  dx, dy = 0, 0 --Variables for the translation.
  if direction == 0 then dx = 1
  elseif direction == 1 then dy = -1
  elseif direction == 2 then dx = -1
  elseif direction == 3 then dy = 1
  end
  self:start()
end

function flow:start()
  sol.timer.start(self, refresh_time, function() 
    local movable_entities =  self:get_movable_entities()
    for _,other_entity in pairs(movable_entities) do
	  --if self:overlaps(other_entity) then 
	    self:move_entity(other_entity) 
	  --end
    end
	--self:move_entity(hero)
	return true -- Repeat the timer.
  end)
end

function flow:get_movable_entities()
  --Return the list of entities on the map that can be moved by the flow. 
  local movable_entities = {}
  table.insert(movable_entities, hero)
  for other_hero in self:get_map():get_entities("npc_hero_") do table.insert(movable_entities, other_hero) end
  -----------------INSERT OTHER MOVABLE ENTITIES HERE!!!! -----------------------
  return movable_entities
end

function flow:move_entity(entity)
  -- Move an entity one pixel in the same direction of the flow. 
  local hx, hy, hl = entity:get_position()
  if not entity:test_obstacles(dx, dy, hl) then entity:set_position(hx + dx, hy + dy, hl) end
end

--[[
function flow:is_on_flow(other_entity)

  --Returns true if other_entity is on the platform. 
  local ox, oy, ol = other_entity:get_position()
  local ex, ey, el = self:get_position()
  if ol ~= el then return false end
  local sx, sy = self:get_size()
  if math.abs(ox - ex) < sx/2 -1 and math.abs(oy - ey) < sy/2 -1 then return true end
  return false

  return self:overlaps(other_entity)
end
--]]





--[[
-- Check heroes, npc_heroes, and enemies that collision with the flow and moves them.
function flow:push_colliding_entities()
  -- Do nothing if the game is suspended (e.g., in the changing map transition).
  if flow:get_game():is_suspended() then 
    sol.timer.start(map, 150, function() flow:push_colliding_entities() end)
    return 
  end
  
  --for entity in map:get_entities("hero") do  
  npc = map:get_entity("npc_hero_2")
  if npc ~= nil then
   movement:start(npc)
  end
  --end
  sol.timer.start(map, 1000, function() flow:push_colliding_entities() end)
end


function flow:set_properties(prop)
end
--]]


