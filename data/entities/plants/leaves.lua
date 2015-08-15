-- Falling leaves.
local entity = ...

function entity:on_created()
  local sprite = self:create_sprite("plants/leaves")
  self:set_traversable_by(true)
  sol.audio.play_sound("bush")
  sprite:set_animation("leaves")
  -- Destroy the entity when the animation has finished.
  function sprite:on_animation_finished(animation) entity:remove() end
end