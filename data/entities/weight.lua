-- Portable entity that can push buttons.

local entity = ...
sol.main.load_file("entities/generic_portable")(entity)

entity.can_push_buttons = true

function entity:on_custom_created()
  self:set_size(16, 16); self:set_origin(8, 13)
end