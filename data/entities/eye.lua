--[[ Base script used to define color eye monsters. The color is stored in "entity.color".
]]

local entity = ...

function entity:on_created()

  -- Get the sprite of the entity (that was chosen on the editor). If there is no sprite, the entity is removed.
  local sprite = self:get_sprite(); if sprite == nil then self:remove() end
  -- Set properties and get position.
  self:set_traversable_by(false)
  self:set_size(16, 16); self:set_origin(8, 13)
  -- Get the color of the eye: it must coincide with the name of the default animation. Set looking animation.
  self.color = self:get_sprite():get_animation()
  self:get_sprite():set_animation("looking")
  -- If there is no key of the same color, make the eye blind; otherwise, start checking.
  entity:start_looking() 
  
end

-- Start looking for keys.
function entity:start_looking()
  local keys_list = entity:get_keys(self.color) 
  local closest_key
  sol.timer.start(self, 50, function() 
	closest_key = entity:get_closest(keys_list)
    entity:look_to(closest_key)
	return true
  end)  
end

-- Return a list of keys on the map of certain color. This function is also invoked for every "eye" when a key is created on a map.
function entity:get_keys(color)
  local keys = {}
  for other in self:get_map():get_entities("") do 
	if other:get_type() == "custom_entity" then
	  if other:get_model() == "key" and other.color == self.color then table.insert(keys, other) end 
	end
  end
  return keys  
end

-- Return the closest key of the same color, or nil if there is no key of the same color.
function entity:get_closest(list)
  local closest
  for _,c in ipairs(list) do
    if closest == nil then closest = c 
    elseif entity:get_distance(c) < entity:get_distance(closest) then closest = c end
  end
  return closest
end

-- Stop looking for keys.
function entity:stop_looking() sol.timer.stop_all(entity)  end
-- Look to other entity.
function entity:look_to(other_entity) if other_entity ~= nil then self:set_direction(entity:get_direction8_to(other_entity)) end end
-- Destroys timers and set the "blind" animation.
function entity:set_blind() sol.timer.stop_all(entity); self:set_animation("blind") end
-- Get a list with the doors of the same color.
function entity:get_doors()
end

-- Close associated doors of the same color.
function entity:close_doors()
end

-- Open associated doors of the same color.
function entity:open_doors()
end
--]]





	  
	  
	  
