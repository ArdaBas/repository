
--WARNING: custom_interactions.lua required!!!

--[[ 
Save the position and direction of certain entities when changing between maps in case some npc_hero is 
on the map (this is done only for enemies and some of the custom_entities!!!).
To allow saving state/position and some other info. To use it, set the property custom_entity.can_save_state = true

In case the state of the entity is complex, two methods should be included in the script of the entity:
entity:get_saved_info() -- Return a list with the info of the extra properties to save.
entity:set_saved_info(properties) -- Load a list with info of the extra properties to load.
In case these methods are empty, only the position and direction of the entity will be saved.

There are some functions used to disable all teletransporters when some generic_portable entity is 
thrown, or when the hero is jumping.

To make some entities unique (they appear only in one of the current maps), give a value to "entity.unique id"

To make an entity independent, so that it preserves its position in any map, set entity.is_independent = true,
and also give a value to entity.unique id (this is necessary). Independent entities are unique. To decide if an
independent entity will change map (following the hero), define a boolean function called
entity:can_change_map_now(). (This is not necessary if the independent entity is carried by the hero!!!)
--]]

local save_between_maps = {}

-- Function called when the player goes to another map. Save the state of the entities left in the map,
-- but only in case some npc_hero is left on the map too. The info is stored temporarily in "game.active_maps".
function save_between_maps:save_map(map, some_hero_remains) 
  local game = map:get_game(); local hero = game:get_hero()
  local map_info = {}
  -- Save carried entity, if any. This includes independent entities.
  if hero.custom_carry then
    self.custom_carry = self:get_entity_info(hero.custom_carry)
  end
  -- Save remaining entities (not carried by the hero).
  self.following_entities = {}
  for entity in map:get_entities("") do
    -- Save independent entities left on the map.
    if entity.is_independent and hero.custom_carry ~= entity then
      local is_changing_map = false
      if entity.can_change_map_now then is_changing_map = entity:can_change_map_now() end
      local entity_properties = self:get_entity_info(entity)
      if not entity.unique_id then error("Variable entity.unique_id not defined.") end
      if entity_properties then 
        if is_changing_map then
          self.following_entities[entity.unique_id] = entity_properties
        else
          game.independent_entities[entity.unique_id] = entity_properties
        end
      end
    elseif some_hero_remains then
    -- Save entities left on the map, but only in case some npc hero remains. 
      if hero.custom_carry ~= entity and (not entity.is_independent) then
        local entity_properties = self:get_entity_info(entity)
        if entity_properties then 
          table.insert(map_info, entity_properties)
        end
      end  
    end
  end
  -- Save or forget the information of saved entities.
  if some_hero_remains then
    game.active_maps[map:get_id()] = map_info
  else
    self:forget_map(map)
  end
end

-- Return a list with the info from a custom entity or enemy.
function save_between_maps:get_entity_info(entity)
  local entity_properties
  if entity:get_type() == "custom_entity" and entity.can_save_state or entity.is_independent then
	  --Save type, position and direction.
    entity_properties = {}
	  local x,y,layer = entity:get_position()
    local name = entity:get_name()
    local sprite = entity:get_sprite()
    local animation_set = sprite:get_animation_set()
    local model = entity:get_model()
    local direction = sprite:get_direction()
    entity_properties.properties = {x = x, y = y, layer = layer, name = name, sprite = animation_set, model = model, 
        direction = direction, entity_type = "custom_entity"}
  elseif entity:get_type() == "enemy" then
    --Save type, position and direction.
    entity_properties = {}
    local breed= entity:get_breed()
    local x,y,layer = entity:get_position()
    local name = entity:get_name()
    local sprite = entity:get_sprite()
    local animation_set = sprite:get_animation_set()
    local direction = sprite:get_direction()
    entity_properties.properties = {x = x, y = y, layer = layer, name = name, breed = breed, direction = direction,  entity_type = "enemy"}
  end
  if entity_properties then
    if entity.get_saved_info ~= nil then entity_properties.extra_properties = entity:get_saved_info() end
    entity_properties.unique_id = entity.unique_id -- Get  unique id, if any.
    if entity.is_independent then entity_properties.map = entity:get_map():get_id() end -- Get map for independent entities.
  end
  return entity_properties
end

-- Create entity on the map with the saved info.
function save_between_maps:create_entity(map, info)
  local entity
  if info.properties.entity_type == "custom_entity" then
    entity = map:create_custom_entity(info.properties)
    
	elseif info.properties.entity_type == "enemy" then
    entity = map:create_enemy(info.properties)
	end
  if info.extra_properties then entity:set_saved_info(info.extra_properties) end
  entity.unique_id = info.unique_id -- Set entity unique id, if any.
  return entity
end

-- Start the map with the saved information. This includes entities being carried by the hero.
function save_between_maps:load_map(map)
  local game = map:get_game(); local hero = map:get_hero()
  -- Restart interaction state.
  game:clear_interaction()
  -- Load the current map (only if it was saved before).
  local map_info = game.active_maps[map:get_id()]
  if map_info then
    -- Delete the entities of the map that can be saved.
    for entity in map:get_entities("") do
      if entity.can_save_state and entity ~= hero.custom_carry then entity:remove() end
    end
    -- Create the entities of the saved map.
    for _, entity_info in pairs(map_info) do
      save_between_maps:create_entity(map, entity_info)
    end
  end  
  -- Create carried entity for the current hero, if any.
  local info = self.custom_carry
  if info then
    local portable = save_between_maps:create_entity(map, info)
    hero.custom_carry = portable
    game:set_interaction_enabled(portable, false)
    self.custom_carry = nil
  end
  -- Create independent entities left on this map.
  for unique_id, entity_info in pairs(game.independent_entities) do
    if entity_info.map == map:get_id() then
      save_between_maps:create_entity(map, entity_info)
      game.independent_entities[unique_id] = nil -- Destroy the info.
    end
  end  
  -- Create independent entities that are following the hero (excluding carried entities).
  if self.following_entities then
    for _, entity_info in pairs(self.following_entities) do
      local x, y, layer = hero:get_position()
      entity_info.properties.x = x; entity_info.properties.y = y; entity_info.properties.layer = layer
      save_between_maps:create_entity(map, entity_info)
    end
    self.following_entities = nil
  end
end


-- Returns boolean. True if the entity of this unique_id exists in some of the current maps.
function save_between_maps:entity_exists(game, unique_id)
  -- Check if the entity exists in the current map.
  local map = game:get_map()
  for e in map:get_entities("") do
    if e.unique_id == unique_id then return true end
  end
  -- Check again for carried entities and followers (that may have not been created yet).
  if self.custom_carry then if self.custom_carry.unique_id == unique_id then return true end end
  if self.following_entities then
    for _, follower in pairs(self.following_entities) do
      if follower.unique_id == unique_id then return true end
    end
  end
  -- Check if the entity exists in some saved map.
  for _, map_info in pairs(game.active_maps) do
    for _, entity_properties in pairs(map_info) do
      if entity_properties.unique_id == unique_id then return true end
    end
  end
  -- Check if the entity exists in some other map.
  for _, entity_info in pairs(game.independent_entities) do
      if entity_info.unique_id == unique_id then return true end
  end
  -- Return false if the entity is not in the current maps.
  return false
end


-- Destroy saved info of the map.
function save_between_maps:forget_map(map)
  local game = map:get_game()
  game.active_maps[map:get_id()] = nil 
end

-- Disable all active teletransporters in the map. This is called when some entity starts falling, or if the hero starts jumping.
function save_between_maps:disable_teletransporters(map)
  -- Get enabled teletransporters and disable them temporarily, during 1 second approximately.
  if not map.enabled_teletransporters then map.enabled_teletransporters = {} end
  for e in map:get_entities("") do
    if e:get_type() == "teletransporter" and e:is_enabled() then
      e:set_enabled(false)
      table.insert(map.enabled_teletransporters, e) 
    end
  end
  local timer = map.disabling_teletransporters_timer
  if timer then
    -- Restart remaining time of the timer.
    timer:set_remaining_time(1050)
  else
    -- Create timer to reactivate teletransporters.
    map.disabling_teletransporters_timer = sol.timer.start(map, 1050, function()
      for _, e in pairs(map.enabled_teletransporters) do
        e:set_enabled(true)
      end
      map.enabled_teletransporters = nil
      map.disabling_teletransporters_timer = nil
    end)
  end
end


return save_between_maps
