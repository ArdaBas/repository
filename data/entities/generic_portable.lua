--[[ Base script used to define entities that can be lifted but not destroyed when thrown. When the custom entity can be lifted, we save a reference to it in hero.custom_lift.
To start lifting a custom entity, call the method "lift()" of the entity to lift, in case it is defined. Similar with hero.custom_carry, entity:set_carried(hero_entity), etc.
To call this script from another,  use: "sol.main.load_file("entities/generic_portable")(entity)" and define a method entity:on_custom_created()  for the initialization, if necessary. 
The state, "on_ground", "lifting", "carried", "falling", can be recovered with entity.state.
--]]

local entity = ...

entity.can_save_state = true
entity.moved_on_platform = true
entity.state = "on_ground"
entity.associated_hero_index = nil
entity.sound = "item_fall" -- Default id of the bouncing sound.

function entity:on_created()
  entity:set_drawn_in_y_order(true)
  -- Start checking if the hero is close enough to lift it.
  entity:check_hero_to_lift()
  if entity.on_custom_created then entity:on_custom_created() end -- Define this in other scripts!!!
end

-- Starts lifting the object. This method is called when the action button is pressed close to this entity.
function entity:lift()
  local game = self:get_game(); local hero = self:get_map():get_hero()
  self.state = "lifting"; hero:freeze(); hero:set_invincible(true)
  if entity.on_custom_position_changed then  entity:on_custom_position_changed() end -- Notify the entity (to move secondary sprites, etc).
  -- Stop the timer to check the hero. 
  sol.timer.stop_all(entity)
  -- Get the index of the hero who is lifting. Associate the entity to the hero. Stop saving between maps.
  entity.associated_hero_index = self:get_game():get_hero_manager().current_hero_index
  hero.custom_carry  = entity; hero.custom_lift = nil; self.can_save_state = false
  -- Show the hero lifting animation.
  sol.audio.play_sound("lift")
  hero:set_animation("lifting", function() 
	hero:set_animation("stopped")
	game:set_custom_command_effect("action", "custom_carry") -- Change the custom action effects.
	game:set_custom_command_effect("attack", "custom_carry")
	hero:unfreeze(); hero:set_invincible(false)
	self:set_carried(hero); entity.moved_on_platform = false
  end)
  -- Move the entity while lifting. (If direction is "up", the item must be drawn behind the hero, so the position is different.)
  local i = 0; local hx, hy, hz = hero:get_position(); local dir = hero:get_direction()
  local dx, dy = math.cos(dir*math.pi/2), -math.sin(dir*math.pi/2)
  if dir ~= 1 then self:set_position(hx, hy +2, hz) else self:set_position(hx, hy, hz) end
  local sprite = self:get_sprite(); sprite:set_xy(dx*14, -6); entity:set_direction(dir)
  if entity.on_custom_position_changed then  entity:on_custom_position_changed() end -- Notify the entity (to move secondary sprites, etc).
  sol.timer.start(entity, math.floor(100), function()
    i = i+1; if i == 1 then sprite:set_xy(dx*16, -8)
	elseif i == 2 then sprite:set_xy(dx*16, -16)
	else sprite:set_xy(0, -20); if dir == 1 then self:set_position(hx, hy +2, hz) end end
	if entity.on_custom_position_changed then  entity:on_custom_position_changed() end -- Notify the entity (to move secondary sprites, etc).
	return i < 3
  end)
end

-- The hero or some npc_hero is displayed carrying this entity. 
function entity:set_carried(hero_entity)
  -- Change state and get the associated index. Change animation set of the hero_entity.
  self.state = "carried"; entity.associated_hero_index = hero_entity:get_index()
  if entity.on_custom_position_changed then  entity:on_custom_position_changed() end -- Notify the entity (to move secondary sprites, etc).
  local game = self:get_game(); local hero = game:get_hero()
  hero_entity:set_carrying(true)
  -- Display the entity correctly.
  self:bring_to_front(); self:get_sprite():set_xy(0, -20)
  local x,y,z = hero_entity:get_position(); entity:set_position(x,y+2,z)
  -- Change position to follow the hero.
  function entity:on_pre_draw() entity:actualize_position() end
end

function entity:throw()
  -- Set variables. (Take animation and direction before freezing the hero.)
  local game = self:get_game(); local hero = game:get_hero(); local sprite = self:get_sprite()
  local animation = hero:get_animation(); local direction = hero:get_direction()
  hero:freeze(); hero:set_invincible(true); entity:disable_teletransporters()
  self.on_pre_draw = nil -- Delete function to follow hero.
  hero.custom_carry = nil; self.associated_hero_index = nil; self.state = "falling"; self:set_direction(direction)
  -- If the entity can push buttons, disable it until it falls.
  local can_push_buttons = self.can_push_buttons 
  if can_push_buttons then self.can_push_buttons = false end
  -- Change animation set of hero to stop carrying. Start animation throw of the hero.
  hero:set_carrying(false); hero:set_animation("throw", function() 
    hero:set_animation("stopped"); hero:set_invincible(false); hero:unfreeze()
  end)
  game:set_custom_command_effect("action", nil); game:set_custom_command_effect("attack", nil)
  local dx, dy = 0, 0; if animation == "walking" then dx, dy = math.cos(direction*math.pi/2), -math.sin(direction*math.pi/2) end
  -- Set position on hero position and the sprite above of the entity.
  local hx,hy,hz = hero:get_position(); self:set_position(hx,hy,hz); sprite:set_xy(0,-22)
  -- Create a custom_entity for shadow (this one is drawn below).
  local shadow = self:get_map():create_custom_entity({direction=0,layer=hz,x=hx,y=hy})
  shadow:create_sprite("entities/shadow"); shadow:bring_to_back()
  -- Set falling animation if any.
  local starting_animation
  if sprite:has_animation("falling") then  starting_animation = sprite:get_animation(); sprite:set_animation("falling") end
  
  -- Function to bounce when entity is thrown. Parameters of list "prop" are given in pixels (the speed in pixels per second).
  -- Call: bounce({max_distance_x =..., max_height_on_x =..., max_height_y =..., speed_pixels_per_second =..., callback =...})
  local function bounce(prop)
    -- Start moving the entity.
	local x,y,z; local sx, sy = sprite:get_xy(); local speed = prop.speed_pixels_per_second
	local x_f, x_m, h, i = prop.max_distance_x, prop.max_height_on_x, prop.max_height_y, 0
	local a = -h/(x_m^2); local b = -2*a*x_m; local h2 =  sy
	local function f1(x) return -math.floor(a*x^2+b*x) end
	local function f2(x) return -math.floor((h2/math.max(x_f-2*x_m, 1))*(x-2*x_m)) end
	local is_obstacle_reached = false
	sol.timer.start(entity, math.floor(1000/speed), function()
	  i = i+1; shadow:set_position(entity:get_position())
	  if entity.on_custom_position_changed then  entity:on_custom_position_changed() end -- Notify the entity (to move secondary sprites, etc).
	  if i < 2*x_m then sprite:set_xy(0, h2 + f1(i))
	  elseif i <= x_f then sprite:set_xy(0, h2 + f2(i))
	  -- Call the callback and stop the timer. 
	  else 
	    if prop.callback ~= nil then prop:callback() end; sol.audio.play_sound(self.sound); return false
	  end
	  return true
	end)
	-- Move the shadow if necessary. Make the entity stop if its shadow collisions with some obstacle.
    if animation == "walking" then
	  local m = sol.movement.create("straight"); m:set_angle(direction*math.pi/2); 
	  m:set_speed(speed); m:set_max_distance(x_f); m:set_smooth(false)
      function m:on_obstacle_reached() m:stop(); is_obstacle_reached = true end
	  m:start(entity)
	end
	-- Make sounds, check ground for water,...
	--...
  end
  -- Give inertia when thrown from moving platforms.
  local function make_inertia()   
	for other in self:get_map():get_entities("") do
	  if other.get_inertia then
	    if other:is_on_platform(hero) then
          local direction, speed,  is_moving  = other:get_inertia()
		  if not is_moving then return end
		  local ddx, ddy = math.cos(direction*math.pi/2), -math.sin(direction*math.pi/2); local sx, sy, sz
		  sol.timer.start(entity, math.floor(1000/speed), function()
		   if not shadow:test_obstacles(ddx, ddy, z) then
		     sx, sy, sz = shadow:get_position()
		     shadow:set_position(sx + ddx, sy + ddy, sz) 
			 x = x+ddx; y = y+ddy
		  else return false end
		  return true
		  end)
		end
	  end
    end 
  end

  -- Function called when the entity has fallen.
  local function finish_bounce()
  
    shadow:remove(); sprite:set_xy(0,0);  self.state = "on_ground"
	entity:clear_collision_tests(); entity:check_hero_to_lift() -- Start checking the hero again.
	entity.can_save_state = true; entity.moved_on_platform = true
	if starting_animation then sprite:set_animation(starting_animation) end -- Restore the initial animation, if necessary.
	if entity.on_custom_position_changed then  entity:on_custom_position_changed() end -- Notify the entity (to move secondary sprites, etc).
	entity:enable_teletransporters()
	if can_push_buttons then self.can_push_buttons = true end -- Allow to push buttons again, if necessary.
  end
  -- Collision test to let other npc_hero catch the entity in the air.
  entity:add_collision_test("overlapping", function(self, other_entity) 
    if other_entity.is_npc_hero and other_entity.custom_carry == nil and entity:get_distance(other_entity) < 8 then
	  entity:clear_collision_tests(); sol.timer.stop_all(entity); 
	  shadow:remove(); hero:set_invincible(false); hero:unfreeze()
	  entity.associated_hero_index = other_entity:get_index(); other_entity.custom_carry = entity; entity:set_carried(other_entity)
	  if starting_animation then sprite:set_animation(starting_animation) end -- Restore the initial animation, if necessary.
	  entity:enable_teletransporters();  self.state = "carried"
	  if can_push_buttons then self.can_push_buttons = true end -- Allow to push buttons again, if necessary.
	end
  end)

  -- Start movement of the shadow. Throw the entity away in the direction of the hero and start checking the hero. Start shift of inertia.
  bounce({max_distance_x = 80, max_height_on_x = 30, max_height_y = 8, speed_pixels_per_second = 200,
  callback = function() bounce({max_distance_x = 16, max_height_on_x = 8, max_height_y = 4, speed_pixels_per_second = 100,
  callback = function() bounce({max_distance_x = 4, max_height_on_x = 2, max_height_y = 2, speed_pixels_per_second = 60,
  callback = finish_bounce }) end }) end })
  make_inertia()
end

-- Used to actualize position to follow the hero.
function entity:actualize_position()
  local hero_entity = self:get_game():get_hero_manager():get_hero_entity(entity.associated_hero_index)
  local x,y,z = hero_entity:get_position(); self:set_position(x,y+2,z) -- Use this position to be drawn over the hero (draw in y order).
  local direction = hero_entity:get_direction(); self:set_direction(direction)
end

-- Returns boolean: true if hero is facing npc_hero in the same layer and close.
function entity:is_facing_hero()
  local map = self:get_map()
  local hero = map:get_hero()
  local hero_x, hero_y, hero_z = hero:get_position()
  local npc_x, npc_y, npc_z = self:get_position()
  local has_good_direction = hero:get_direction4_to(entity) == hero:get_direction()
  local is_close = (math.abs(hero_x - npc_x) < 10 and math.abs(hero_y - npc_y) < 18) 
                          or (math.abs(hero_x - npc_x) < 18 and math.abs(hero_y - npc_y) < 10)
  return has_good_direction and is_close and hero_z == npc_z
end

-- Check if the hero close enough to lift the entity, and notify the HUD. Save a reference to this item in hero.custom_lift.
function entity:check_hero_to_lift()
  -- If the state has changed (the entity is not on the ground), stop checking.
  if self.state ~= "on_ground" then return end
  local game = self:get_game()
  local hero = game:get_hero()
  -- If hero is close and no action active, show in the HUD that the item can be lifted and 
  -- save a reference to this entity in hero.custom_lift.
  if self:is_facing_hero() and game:get_custom_command_effect("action") == nil then
    game:set_custom_command_effect("action", "custom_lift"); hero.custom_lift = entity
  -- If the hero move away from this entity, remove the custom effect "custom lift" if necessary.
  elseif (not self:is_facing_hero()) and hero.custom_lift == entity then
	game:set_custom_command_effect("action", nil); hero.custom_lift = nil
  end
  -- Restart the check function.
  sol.timer.start(entity, 50, function() entity:check_hero_to_lift() end)
end

-- Function to get the information to save between maps.
function entity:get_saved_info()
  local properties = {associated_hero_index=entity.associated_hero_index, state = state, savegame_variable = entity.savegame_variable}
end
-- Function to recover the saved information between maps.
function entity:set_saved_info(properties)
  entity.associated_hero_index = properties.associated_hero_index
  self.state = properties.state
  if self.state == "carried" then entity:start_carry() end
  entity.savegame_variable = properties.savegame_variable 
end

-- Disable all active teletransporters in the map. This is called when this entity begins falling, to avoid changing map, 
-- which would not save position of the entity (and therefore it would disappear). 
function entity:disable_teletransporters()
  local map = self:get_map()
  if map.falling_entities_number == nil then 
    map.falling_entities_number = 1; self.teletransporters = {}
	for other in map:get_entities("") do
	  if other:get_type() == "teletransporter" and other:is_enabled() then
	    other:set_enabled(false); table.insert(self.teletransporters, other) 
	  end
	end
  else map.falling_entities_number = map.falling_entities_number +1 end
end
-- Enable teletransporters in the map. This only affect the ones that were disabled when this entity started to fall.
-- If there are more entities falling, the teletransporters are not activated.
function entity:enable_teletransporters()
  local map = self:get_map()
  map.falling_entities_number = map.falling_entities_number -1
  if map.falling_entities_number == 0 then
    for _,other in pairs(self.teletransporters) do other:set_enabled(true) end
	self.teletransporters = nil; map.falling_entities_number = nil
  end
end


