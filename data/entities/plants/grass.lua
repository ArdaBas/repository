local entity = ...

local pos_x, pos_y, pos_z, grass
local entities_above = {}
-- Lists of the form {other_entity, sprite} are stored in the list above. This is done for the entities above the grass.

--[[ CHANGE COLLIISION TEST TO TYPE "ORIGIN" WHEN THE BUG IS FIXED (IT DOES NOT WORK!)
--]]

function entity:on_created()
  self:set_size(16, 16); self:set_origin(8, 8)
  local layer
  pos_x, pos_y, pos_z = self:get_position()
  -- The grass entity is shifted in the y coordinate to display the grass above (using the draw on y order).
  grass = self:get_map():create_custom_entity({direction=0, x=pos_x, y=pos_y+18, layer=pos_z})
  grass:set_drawn_in_y_order(true)
  -- Create collision test to create moving grass when the hero or other entities walk over grass.
  -- If an entity is above, add it to the list.
  self:add_collision_test(function(self, other) 
      local x,y,z = other:get_position()
	  if z == pos_z and self:overlaps(x,y) then return true end 
    end, function(self, other)
    if other:get_type() == "custom_entity" or other == self:get_map():get_hero() then
	  self:add_entity(other)
	end
  end)
  -- Use a timer to draw the grass of the entities above.
  sol.timer.start(self, 50, function() 
    self:actualize_grass()
	return true
  end)
end

-- Add an entity to the list of entities above the grass and create its associated grass.
function entity:add_entity(other)
  local is_in_list = false
  for k, v in pairs(entities_above) do
    if v.other == other then is_in_list = true end
  end
  if not is_in_list then
    local sprite = grass:create_sprite("plants/grass")
	local x, y, _ = other:get_position()
	sprite:set_xy(x-pos_x, y-pos_y-18)
    table.insert(entities_above, {other = other, sprite = sprite}) 
  end
end

-- Remove an entity to the list of entities, and the sprite of its grass.
function entity:remove_entity(other)
  for k, v in pairs(entities_above) do
    if v.other == other then
	  grass:remove_sprite(v.sprite); table.remove(entities_above, k) 
	end
  end
end

-- Make moving grass for entities above.
function entity:actualize_grass()
  for _, e in pairs(entities_above) do
    -- First, remove from the list the entities that are not above and delete the associated grass.
	local x, y, _ = e.other:get_position()
    if not self:overlaps(x, y) then 
	  self:remove_entity(e.other)
	else
	  -- Actualize grass position for each entity. 
      e.sprite:set_xy(x-pos_x, y-pos_y-18)
	  -- Draw grass to the left or right depending on the position.
	  if ((pos_x-x) + (pos_y-y))%8 < 4 then e.sprite:set_animation("left")
      else e.sprite:set_animation("right") end 
	end
  end
end

