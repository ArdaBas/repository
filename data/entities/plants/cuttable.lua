--[[ Base script used to define cuttable entities (as solid flowers) which are compatible with the system of the game.--]]


local entity = ...

entity.can_save_state = true

local is_not_cut = true

-- Function to create a custom cuttable. Use the following syntax:
-- prop = {x = x, y = y, layer = layer, name = name, sprite_name = sprite_name}
function entity:on_created()
  -- Get the sprite of the entity (that was chosen on the editor). If there is no sprite, the entity is removed.
  local map = self:get_map()
  local sprite = self:get_sprite(); if sprite == nil then self:remove() end  
  -- Set properties.
  self:set_traversable_by(false)
  -- Cut the entity when the sword hits it.
  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    -- Do nothing if the animation is not "sword", or if the sword is not close enough.
    if other_sprite == nil then return end
    if other_sprite:get_animation() ~= "sword" then return end
	if entity:get_distance(other_entity) > 28 then return end
	-- Cut the entity.
	entity:clear_collision_tests()
	local x,y,z = self:get_position()
	map:create_custom_entity({direction=0,layer=z,x=x,y=y,model="plants/leaves"})
	entity:drop_pickable()
	self:remove()
  end)
end

function entity:drop_pickable()
  local prop = {}
  prop.name = entity:get_sprite():get_animation_set()
  prop.x, prop.y, prop.layer = entity:get_position()
  local map = self:get_map()
  if prop.name == "plants/plant_red" then  prop.treasure_name = "heart" end -- Drop a heart.
  map:create_pickable(prop)
end




