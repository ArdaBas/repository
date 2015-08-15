--[[ Base script used to define color keys. The color is the name of the animation.
--]]

local entity = ...
sol.main.load_file("entities/generic_portable")(entity)

-- This function is called after the on_created function of the generic_portable entity.
function entity:on_custom_created()
  self:set_size(16,16); self:set_origin(8,5)
  --self.color = self:get_sprite():get_animation() -- NOT NECESSARY! (better get the animation)
  --self:restart_eyes(self.color)
  self.sound = "key_fall" -- Change the default bouncing sound.
end

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