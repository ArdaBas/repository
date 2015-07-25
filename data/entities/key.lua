--[[ Base script used to define color keys. (The color of the key is the name of the animation of the sprite.)
--]]

local entity = ...
sol.main.load_file("entities/generic_portable")(entity)

-- This function is called after the on_created function of the generic_portable entity.
function entity:on_custom_created()
  self:set_size(16,8); self:set_origin(8,5)
  self.sound = "key_fall" -- Change the default bouncing sound.
end
