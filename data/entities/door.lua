--[[ Base script used to define color doors. The color is stored in "entity.color".
--]]

local entity = ...
local is_open = true

function entity:on_created()
  -- Get the sprite of the entity (that was chosen on the editor). If there is no sprite, the entity is removed.
  local sprite = self:get_sprite(); if sprite == nil then self:remove() end
  -- Set properties.
  self:set_traversable_by(true); sprite:set_animation("open")
  -- Set behaviour after the opening and closing animations.
  function sprite:on_animation_finished(animation)
    if animation == "opening" then   
      sol.audio.play_sound("door_open"); sprite:set_animation("open")
	  sol.timer.stop_all(entity)
    elseif animation == "closing" then   
	  sol.audio.play_sound("door_closed"); sprite:set_animation("closed")
	  sol.timer.stop_all(entity) 	
    end
  end
end

-- Return boolean.
function entity:is_open() return is_open end
  
function entity:open()
  local animation = self:get_sprite():get_animation()
  if is_open or animation == "open" or animation == "opening" then return end
  is_open = true
  entity:set_traversable_by(true)
  local frame
  local sprite = self:get_sprite()
  if sprite:get_animation() == "closing" then frame = sprite:get_frame() end
  sprite:set_animation("opening")
  if frame then sprite:set_frame(4-frame) end
end

function entity:close()
  local animation = self:get_sprite():get_animation()
  if not is_open or animation == "closed" or animation == "closing" then return end
  is_open = false
  local hero = self:get_map():get_hero()
  entity:set_traversable_by(false)
  local sprite = self:get_sprite(); local direction = self:get_direction()
  local frame
  if sprite:get_animation() == "opening" then frame = sprite:get_frame() end
  sprite:set_animation("closing")
  if frame then sprite:set_frame(4-frame) end
    
  local t, dx, dy = 0, -math.cos(direction*math.pi/2), math.sin(direction*math.pi/2)
  local function push_entity(other)
    -- Push a bit the other entity.
    local x, y, z = other:get_position(); other:set_position(x + dx, y + dy, z) 
  end
  
  sol.timer.start(entity, 10, function()
    t = t + 10
	-- Moves the hero if overlapping.
    if entity:overlaps(hero) then 
	  local x, y, z = hero:get_position(); hero:set_position(x + dx, y + dy, z) 
	end
	-- Moves other entities if overlapping, except for carried items.
    for other in self:get_map():get_entities("") do
	  if other:get_type() == "custom_entity"  then
	    if entity:overlaps(other) and other ~= entity and other.state ~= "carried" and other:get_model() ~= "keyhole" then
          push_entity(other)
	    end
	  elseif other:get_type() == "enemy" and entity:overlaps(other) then
	    push_entity(other)
	  end
    end
	-- Finish the pushing.
	if t < 1000 then return true end
  end)

end

-- Make the door shake a bit. (Move the sprite.)
function entity:shake()
  local sprite = self:get_sprite()
  local a = sprite:get_direction()*math.pi/2 -- Angle.
  local dx, dy = math.cos(a), -math.sin(a)
  sprite:set_xy(dx,dy)
  sol.audio.play_sound("chest_open")
  sol.timer.start(entity, 200, function()
    sprite:set_xy(0, 0)
  end)
end

