
--[[ 
Save the position and direction of certain entities when changing between maps in case some npc_hero is 
on the map (this is done only for enemies and some of the custom_entities!!!).
To allow saving state, set the property custom_entity.can_save_state = true

In case the state of the entity is complex, two methods should be included in the script of the entity:
entity:get_saved_info() -- Return a list with the info of the extra properties to save.
entity:set_saved_info(properties) -- Load a list with info of the extra properties to load.
In case these methods are empty, only the position and direction of the entity will be saved.

There are some functions used to disable all teletransporters when some generic_portable entitiy is 
thrown, or when the hero is jumping. 
--]]

local save_between_maps = {}

-- Function called when the player goes to another map. Save the state of the entities in case some npc_hero
-- is left on the map. The info is stored temporarily in "game.active_maps".
function save_between_maps:save_map(map)
  
  local game = map:get_game()
  local map_info = {}
  for entity in map:get_entities("") do
     
    if entity:get_type() == "custom_entity" and entity.can_save_state == true then	
	  --Save type, position and direction.
	  local entity_properties = {}
	  local x,y,layer = entity:get_position()
	  local name = entity:get_name()
	  local sprite = entity:get_sprite()
	  local animation_set = sprite:get_animation_set()
	  local model = entity:get_model()
	  local direction = sprite:get_direction()
	  --local animation = sprite:get_animation()
	  entity_properties.properties = {x = x, y = y, layer = layer, name = name, sprite = animation_set, model = model, direction = direction, entity_type = "custom_entity"}
	  if entity.get_saved_info ~= nil then entity_properties.extra_properties = entity:get_saved_info() end
	  table.insert(map_info, entity_properties)
	
	elseif entity:get_type() == "enemy" and entity.can_save_state == true then
	  --Save type, position and direction.
	  local entity_properties = {}
	  local breed= entity:get_breed()
	  local x,y,layer = entity:get_position()
	  local name = entity:get_name()
	  local sprite = entity:get_sprite()
	  local animation_set = sprite:get_animation_set()
	  local direction = sprite:get_direction()
	  entity_properties.properties = {x = x, y = y, layer = layer, name = name, breed = breed, direction = direction,  entity_type = "enemy"}
	  if entity.get_saved_info ~= nil then entity_properties.extra_properties = entity:get_saved_info() end
	  table.insert(map_info, entity_properties)
	  
	end
  end
  -- Save the list with the map info.
  game.active_maps[map:get_id()] = map_info

end

function save_between_maps:load_map(map)

  -- Load the current map (only if it was saved before).
  local game = map:get_game()
  local map_info = game.active_maps[map:get_id()]
  if map_info == nil then return end
  -- Delete the entities of the map that can be saved.
  for entity in map:get_entities("") do
    if entity.can_save_state == true then
      entity:remove()
	end
  end
  -- Create the entities of the saved map.
  for _,entity_properties in pairs(map_info) do
    if entity_properties.properties.entity_type == "custom_entity" then	
      map:create_custom_entity(entity_properties.properties)
	elseif entity_properties.properties.entity_type == "enemy" then
      map:create_enemy(entity_properties.properties)
	end
	if entity_properties.extra_properties ~= nil then entity:set_saved_info(entity_properties.extra_properties) end
  end

end

function save_between_maps:forget_map(map)
  local game = map:get_game()
  game.active_maps[map:get_id()] = nil 
end

-- Disable all active teletransporters in the map. This is called when some entity starts falling, or if the hero starts jumping.
function save_between_maps:disable_teletransporters(map)
  if map.falling_entities_number == nil then 
    map.falling_entities_number = 1
    self.teletransporters = {}
	  for other in map:get_entities("") do
	    if other:get_type() == "teletransporter" and other:is_enabled() then
	      other:set_enabled(false); table.insert(self.teletransporters, other) 
	    end
	  end
  else map.falling_entities_number = map.falling_entities_number +1
  end
end
-- Enable all active teletransporters in the map. This is called when some entity ends falling, or if the hero ends jumping.
function save_between_maps:enable_teletransporters(map)
  map.falling_entities_number = map.falling_entities_number -1
  if map.falling_entities_number == 0 then
    for _,other in pairs(self.teletransporters) do other:set_enabled(true) end
	self.teletransporters = nil; map.falling_entities_number = nil
  end
end


return save_between_maps

