-- Entity tile that makes an item fall on it, usually a key.
--[[ Usage: in the map script, associate a savegame variable and some properties:
	properties = {savegame_variable = ..., model = ..., sprite_name =..., falling_animation = ..., animation = ... } 
	entity:assign_item(properties)
The sprite_name variable may be nil (that is the case when the custom entity script creates the sprite).	
--]]

local entity = ...

function entity:on_created()
end

-- Called from the map script to assign the item that will fall.
function entity:assign_item(properties)
  entity.item_properties = properties -- Get list of properties of the item.
end

-- Returns boolean. True if the item exists in some of the current maps.
function entity:item_exists()
  -- Return false if there is no savegame variable. 
  if entity.item_properties.savegame_variable == nil then return false end
  -- Check if the entity exists in the current map.
  local map = self:get_map()
  for e in map:get_entities("") do
    if e:get_type() == "custom_entity" then
      if e.savegame_variable == entity.item_properties.savegame_variable then
	    return true
	  end
    end
  end
  -- Check if the entity exists in some saved map.
  local game = self:get_game()
  for _, map_info in pairs(game.active_maps) do
    for _, entity_properties in pairs(map_info) do
	  if entity_properties.extra_properties ~= nil then
        if entity_properties.extra_properties.savegame_variable == entity.item_properties.savegame_variable then
		  return true
		end
	  end
    end
  end
  -- Return false if the entity is not in the current maps.
  return false
end

-- If the item does not exist in some of the current maps, make it fall.
function entity:activate()
  if not self:item_exists() then
    self:item_fall()
  end
end

-- Create item and make it fall over the keyfall entity.
function entity:item_fall()
  -- Create shadow.
  local x,y,layer = self:get_position()
  local prop = entity.item_properties; local map = self:get_map()
  local shadow = map:create_custom_entity({direction=0, layer=layer, x=x, y=y})
  shadow:create_sprite("entities/shadow"); shadow:bring_to_back()
  -- Create item falling.
  local item = map:create_custom_entity({direction=0, layer=2, x=x, y=y-96, model = prop.model})
  item.savegame_variable = prop.savegame_variable -- This string is saved between maps for the falling item.
  local sprite = item:get_sprite()
  if not sprite then sprite = item:create_sprite(prop.sprite_name) end
  sprite:set_animation(prop.falling_animation)
  if sprite:get_num_directions() == 4 then item:set_direction(3) end
  item.state = "falling"; item:disable_teletransporters()
  -- Start falling.
  local m = sol.movement.create("straight")
  m:set_speed(150); m:set_angle(3*math.pi/2)
  m:set_max_distance(96); m:set_ignore_obstacles(true)
  m:start(item)
  function m:on_finished() 
    sol.audio.play_sound(item.sound) -- Bounce sound.
    m = sol.movement.create("straight")
    m:set_speed(60); m:set_angle(math.pi/2)
    m:set_max_distance(16); m:set_ignore_obstacles(true)
    m:start(item)
    function m:on_finished() 
	  m = sol.movement.create("straight")
      m:set_speed(60); m:set_angle(3*math.pi/2)
      m:set_max_distance(16); m:set_ignore_obstacles(true)
      m:start(item)
	  function m:on_finished() 
        sol.audio.play_sound(item.sound) -- Bounce sound.
        shadow:remove(); sprite:set_animation(prop.animation)
	    item:set_position(x,y,layer) -- Set to low layer.
	    item.state = "on_ground"; item:check_hero_to_lift()
		item:enable_teletransporters()
	  end
	end
  	
  end
  
  --- IMPEDIR IRSE SI ESTA CALLENDO!!!!
  
end





