-- Portable entity that can push buttons.

local entity = ...
sol.main.load_file("entities/generic_portable")(entity)

entity.is_independent = true
entity.unique_id = "independent_weight"
entity.can_push_buttons = true

function entity:on_custom_created()

end