local entity = ...

--[[ Crystal entity that can be activated by the sword or arrows.
When hit, the function entity:on_activated(state) is called if it is defined.
You need to define that function in the map script!!!
Animations usually take names: "start_0", "end_0", "0", "start_1", "end_1", "1".
--]]

local state = 0 -- Initial state (usually takes values 0 and 1).
local is_changing = false
entity.can_save_state = true

function entity:on_created()
  -- Set properties. Get the sprite of the entity (chosen on the editor).
  self:set_traversable_by(false)
  -- Cut the entity when the sword hits it.
  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    if other_sprite == nil or is_changing then return end
    -- Do nothing if the entity is not a "sword" (and if the sword is not close enough), or "arrow".
    if other_sprite:get_animation() == "sword" then
      if entity:get_distance(other_entity) > 28 then return end
      -- Change animation and state. Make sound.
      entity:change_state()
	elseif other_sprite:get_animation_set() == "entities/arrow" then
	  if not other_entity.has_activated_crystal then
	    other_entity.has_activated_crystal = true
	    entity:change_state()
	  end
	end
  end)
end

-- Change to the next state of the crystal. Call entity:on_activated(state) if defined.
function entity:change_state()
  is_changing = true
  sol.audio.play_sound("crystal")
  -- Call function entity:on_activated(state) if defined on map script.
  if entity.on_activated then entity:on_activated(state) end
  -- Start animations.
  local sprite = self:get_sprite()  
  sprite:set_animation("end_" .. state)
  function sprite:on_animation_finished(animation)
    state = (state +1) % 2
    sprite:set_animation("start_" .. state)
    function sprite:on_animation_finished(animation)
      sprite:set_animation("" .. state)
      is_changing = false  
    end
  end
  -- Make bright.
  local bright = self:create_sprite("things/chest_bright")
  bright:set_animation("bright")
  function bright:on_animation_finished(animation) entity:remove_sprite(bright) end  
end
