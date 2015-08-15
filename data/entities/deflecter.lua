--[[
Script for an entity that can deflect arrows and other projectiles.
Entities are deflected certain angle, depending on the state of the deflecter.
Sprite animation names: "color_0", "color_1", "color_0_to_1", "color_1_to_0".
States 0 and 1 sets entity to angle of 45 and -45 degrees.
--]]

local entity = ...

local state = 0
local is_changing = false
entity.is_deflecter = true -- (Used to simplify other scripts.)
entity.can_save_state = true
local color = "blue" -- Possible values: "yellow", "blue".

function entity:on_created()
  self:set_traversable_by(false)
  self:get_sprite():set_animation(color .. "_" .. state)
  -- Add collision test for arrow detection.
  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    if other_entity.can_be_deflected then
      entity:deflect(other_entity)
    end
  end)
end

function entity:change_state()
  is_changing = true
  local sprite = self:get_sprite()
  local new_state = (state +1)%2
  sprite:set_animation(color .. "_" .. state .. "_to_" .. new_state)
  function sprite:on_animation_finished(animation)
    state = new_state
    sprite:set_animation(color .. "_" .. state)
    is_changing = false
  end
end

--[[ Change movement of some projectile entity. Its movement should be changed 
in the projectile script, using the event on_direction_changed().
--]]
function entity:deflect(projectile)
  local dir = projectile:get_direction()
  if (state + dir) % 2== 0 then dir = (dir -1)%4
  else dir = (dir +1)%4 end
  projectile:set_direction(dir)
end

--[[ To change direction of deflecters on the map, define on the map script:
for d in map:get_entities("")
  if d.is_deflecter then
    d:change_state()
  end
end
--]]
