local entity = ...

function entity:on_created()
  self:set_traversable_by(false)
  self:set_size(16, 16); self:set_origin(8, 13)
  self:get_sprite():set_animation("walking")

-- ADD COLLISION TEST FOR BOMB EXPLOSSIONS!!!

end