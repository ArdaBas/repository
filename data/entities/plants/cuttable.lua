--[[ Base script used to define cuttable entities (as solid flowers) which are compatible with the system of the game.--]]


local entity = ...

entity.can_save_state = true

-- Function to create a custom cuttable. Use the following syntax:
-- prop = {x = x, y = y, layer = layer, name = name, sprite_name = sprite_name}
function entity:on_created()
  -- Set properties.
  local map = self:get_map()
  self:set_traversable_by(false)
  -- Cut the entity when the sword hits it.
  entity:add_collision_test("sprite", function(entity, other_entity, sprite, other_sprite)
    -- Do nothing if the animation set is not of the sword, or if the sword is not close enough.
    if other_sprite == nil then return end
    local animation_set = other_sprite:get_animation_set()
    local sword_id = map:get_hero():get_sword_sprite_id()
    if animation_set ~= sword_id then return end
    if entity:get_distance(other_entity) > 20 then return end -- Set a max distance to cut.
    entity:cut() -- Cut the plant.
  end)
end

function entity:cut()
	-- Cut the entity.
	self:clear_collision_tests()
	local x,y,z = self:get_position()
	self:get_map():create_custom_entity({direction=0,layer=z,x=x,y=y,model="plants/leaves"})
	self:drop_pickable()
	self:remove()
end

function entity:drop_pickable()
  local prop = {}
  prop.name = entity:get_sprite():get_animation_set()
  prop.x, prop.y, prop.layer = entity:get_position()
  local map = self:get_map()
  if prop.name == "plants/plant_red" then  prop.treasure_name = "heart" end -- Drop a heart.
  map:create_pickable(prop)
end




