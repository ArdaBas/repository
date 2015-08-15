
local entity = ...

function entity:on_created()
  local sprite = self:get_sprite()
  if not sprite then self:remove() end -- Remove tree if there is no sprite.
  local animation = sprite:get_animation()
  local collision_dist
  if animation == "tree" then -- The tree is small.
    self:set_size(32, 32); self:set_origin(16, 24); collision_dist = 32
  else -- The tree is big.
    self:set_size(48, 48); self:set_origin(24, 24); collision_dist = 44
  end
  self:set_traversable_by(false)
  self:add_collision_test_sword(collision_dist) -- Throw leaves when hit by sword.
end

function entity:add_collision_test_sword(collision_dist)
  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    -- Do nothing if the animation is not "sword", or if the sword is not close enough.
    if other_sprite == nil then return end
    if other_sprite:get_animation() ~= "sword" then return end
	if other_entity:get_direction4_to(self) ~= other_sprite:get_direction() then return end
    if entity:get_distance(other_entity) > collision_dist then return end
    -- Throw leaves.
    entity:clear_collision_tests()
    local x,y,z = self:get_position(); local ox,oy,_ = other_entity:get_position()
    x = math.floor((x+ox)/2); y = math.floor((y+oy)/2)
    local leaves = self:get_map():create_custom_entity({direction=0,layer=z,x=x,y=y,model="plants/leaves"})
    function leaves:on_removed() entity:add_collision_test_sword(collision_dist) end
  end)
end




