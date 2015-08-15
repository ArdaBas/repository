--[[ Base script used to define destructible entities (like pots) which are compatible with the system of the game. 
The custom entity creates a normal destructible, adding some properties for compatibility with the game. 
When the normal destructible is carried or destroyed, the custom entity is destroyed.
--]]


local entity = ...

local destructible
entity.can_save_state = true

-- Function to create a custom destructible. Use the following syntax:
-- prop = {x = x, y = y, layer = layer, name = name, sprite_name = sprite_name}
function entity:on_created()
  -- Get the sprite of the entity (that was chosen on the editor). If there is no sprite, the entity is removed.
  local map = self:get_map()
  local sprite = self:get_sprite(); if sprite == nil then self:remove() end  
  -- Create the associated normal destructible. 
  local x,y,layer = self:get_position()
  local animation_set = sprite:get_animation_set()
  local animation = sprite:get_animation()
  local direction = sprite:get_direction()
  destructible = map:create_destructible({layer=layer, x=x, y=y, sprite=animation_set})
  -- Disable the entity (only the normal destructible is shown), but it still exists.
  self:set_enabled(false)
  -- In case the normal destructible is destroyed, the entity is destroyed too.
  -- The function entity:on_removed() is deleted before to avoid recursive calls of both remove functions.
  function destructible:on_removed() 
    function entity:on_removed() end
    entity:remove() 
  end
end


-- The function destructible:on_removed() is deleted before to avoid recursive calls of both remove functions.
function entity:on_removed()
  function destructible:on_removed() end
  destructible:remove()
end

