--[[ Base script used to define color keys. The color is the name of the animation.
--]]

local entity = ...
sol.main.load_file("entities/generic_portable")(entity)
entity.unique_id = "first_key"

local color

-- This function is called after the on_created function of the generic_portable entity.
function entity:on_custom_created()
  self.sound = "key_fall" -- Change the default bouncing sound.
  color = self:get_sprite():get_animation()
  --self.color = self:get_sprite():get_animation() -- NOT NECESSARY! (better get the animation)
  --self:restart_eyes(self.color)
end

-- Return color of the key.
function entity:get_color() return color end
-- Change color of the key.
function entity:set_color(new_color) color = new_color; self:get_sprite():set_animation(color) end

-- Function to get still more information to save between maps.
function entity:get_more_saved_info(properties) properties.color = color; return properties end
-- Function to recover still more saved information between maps.
function entity:set_more_saved_info(properties) self:set_color(properties.color) end

--[[
-- Restart eye enemies (the function is refreshed).
function entity:restart_eyes(color)
  for other in self:get_map():get_entities("") do 
	  if other:get_type() == "custom_entity" then
	    if other:get_model() == "eye" and other.color == self.color then other:stop_looking(); other:start_looking() end 
	  end
  end
end

-- When removed, restart eyes.
function entity:on_removed() entity:restart_eyes(self.color) end
--]]
