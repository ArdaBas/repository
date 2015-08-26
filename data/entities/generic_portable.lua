--[[ Base script used to define entities that can be lifted but not destroyed when thrown. When the custom entity can be lifted, we save a reference to it in hero.custom_lift.
To start lifting a custom entity, call the method "lift()" of the entity to lift, in case it is defined. Similar with hero.custom_carry, entity:set_carried(hero_entity), etc.
To call this script from another,  use: "sol.main.load_file("entities/generic_portable")(entity)" and define a method entity:on_custom_created()  for the initialization, if necessary. 
The state, "on_ground", "lifting", "carried", "falling", can be recovered with entity.state.
--]]

local entity = ...

entity.unique_id = nil
entity.is_independent = nil
entity.can_push_buttons = nil
entity.can_save_state = true
entity.moved_on_platform = true
entity.state = "on_ground"
entity.associated_hero_index = nil
entity.sound = "item_fall" -- Default id of the bouncing sound.
entity.is_portable = true -- USE THIS TO SIMPLIFY ALL THE SCRIPTS!!!
entity.action_effect = "custom_lift"

local game = entity:get_game()
local map = entity:get_map()

-- Variables to recover initial information.
local temp_starting_animation
local temp_moved_on_platform
local temp_can_push_buttons

function entity:on_created()
  -- Properties.
  entity:set_drawn_in_y_order(true)
  if entity.on_custom_created then entity:on_custom_created() end -- Define this in other scripts!!!
  self:set_can_traverse_ground("hole", true)
  self:set_can_traverse_ground("deep_water", true)
  self:set_can_traverse_ground("lava", true)
  self:set_can_traverse("jumper", true)
  -- Interaction properties for the HUD.
  game:set_interaction_enabled(entity, true)
  -- Starts checking the ground, once per second.
  entity:start_checking_ground()
  -- Collision test to let other npc_hero catch the entity on the air.
  game:add_collision_test(entity, "collision_falling","overlapping", function(self, other_entity)
    if self.state ~= "falling" then return end
    if other_entity.is_npc_hero and other_entity.custom_carry == nil and self:get_distance(other_entity) < 8 then
      sol.timer.stop_all(self)
      game:set_interaction_enabled(entity, false)
      game:clear_interaction()
      self.shadow:remove()
      sol.audio.play_sound("lift")
      local hero = game:get_hero(); hero:set_invincible(false); hero:unfreeze()
      self.associated_hero_index = other_entity:get_index()
      other_entity.custom_carry = self; self:set_carried(other_entity)
      self.state = "carried"
      -- Recover initial values.
      if temp_starting_animation then self:get_sprite():set_animation(temp_starting_animation) end -- Restore the initial animation, if necessary.
      if temp_can_push_buttons then self.can_push_buttons = true end -- Allow to push buttons again, if necessary.
      if temp_moved_on_platform then self.moved_on_platform = true end -- Allow to be moved on platforms again, if necessary.
    end
  end)
end

-- On interaction, lift the entity.
function entity:on_custom_interaction()
  game:set_interaction_enabled(entity, false)
	game:set_custom_command_effect("action", nil) -- Change the custom action effects.
	game:set_custom_command_effect("attack", "custom_carry")
  self:lift()
end 
 
-- Start lifting the object.
function entity:lift()
  local hero = map:get_hero()
  self.state = "lifting"; hero:freeze(); hero:set_invincible(true)
  entity:on_position_changed() -- Notify the entity (to move secondary sprites, etc).
  -- Get the index of the hero who is lifting. Associate the entity to the hero. Stop saving between maps.
  entity.associated_hero_index = game.hero_manager.current_hero_index
  hero.custom_carry  = entity; hero.custom_lift = nil
  -- Show the hero lifting animation.
  sol.audio.play_sound("lift")
  hero:set_animation("lifting", function() 
	  hero:set_animation("stopped")
	  hero:unfreeze(); hero:set_invincible(false)
	  self:set_carried(hero)
  end)
  -- Move the entity while lifting. (If direction is "up", the item must be drawn behind the hero, so the position is different.)
  local i = 0; local hx, hy, hz = hero:get_position(); local dir = hero:get_direction()
  local dx, dy = math.cos(dir*math.pi/2), -math.sin(dir*math.pi/2)
  if dir ~= 1 then self:set_position(hx, hy +2, hz) else self:set_position(hx, hy, hz) end
  local sprite = self:get_sprite(); sprite:set_xy(dx*14, -6); entity:set_direction(dir)
  entity:on_position_changed() -- Notify the entity (to move secondary sprites, etc).
  sol.timer.start(entity, math.floor(100), function()
    i = i+1
    if i == 1 then 
      sprite:set_xy(dx*16, -8)
    elseif i == 2 then 
      sprite:set_xy(dx*16, -16)
    else 
      sprite:set_xy(0, -20)
      if dir == 1 then self:set_position(hx, hy +2, hz) end 
    end
    entity:on_position_changed() -- Notify the entity (to move secondary sprites, etc).
    return i < 3
  end)
end

-- The hero or some npc_hero is displayed carrying this entity. 
function entity:set_carried(hero_entity)
  -- Change state and get the associated index. Change animation set of the hero_entity.
  self.associated_hero_index = hero_entity:get_index()
  hero_entity.custom_carry = entity
  self.state = "carried"
  hero_entity:set_carrying(true)
  -- Display the entity correctly.
  self:stop_movement()
  self:bring_to_front(); self:get_sprite():set_xy(0, -20)
  local x,y,z = hero_entity:get_position(); self:set_position(x,y+2,z)
  entity:on_position_changed() -- Notify the entity (to move secondary sprites, etc).
end

function entity:throw()
  -- Set variables. (Take animation and direction before freezing the hero.)
  local hero = game:get_hero(); local sprite = self:get_sprite()
  local animation = hero:get_animation(); local direction = hero:get_direction()
  hero:freeze(); hero:set_invincible(true)
  game.save_between_maps:disable_teletransporters(map)
  self.on_pre_draw = nil -- Delete function to follow hero.
  hero.custom_carry = nil; self.associated_hero_index = nil; self.state = "falling"; self:set_direction(direction)
  -- If the entity can push buttons, disable it until it falls. (Enable it later.) The same if moved with platforms.
  local temp_can_push_buttons = self.can_push_buttons; self.can_push_buttons = nil
  local temp_moved_on_platform = self.moved_on_platform; self.moved_on_platform = nil
  -- Change animation set of hero to stop carrying. Start animation throw of the hero.
  hero:set_carrying(false); hero:set_animation("throw", function() 
    hero:set_animation("stopped"); hero:set_invincible(false); hero:unfreeze()
  end)
  game:set_custom_command_effect("action", nil); game:set_custom_command_effect("attack", nil)
  local dx, dy = 0, 0; if animation == "walking" then dx, dy = math.cos(direction*math.pi/2), -math.sin(direction*math.pi/2) end
  -- Set position on hero position and the sprite above of the entity.
  local hx,hy,hz = hero:get_position(); self:set_position(hx,hy,hz); sprite:set_xy(0,-22)
  -- Create a custom_entity for shadow (this one is drawn below).
  self.shadow = map:create_custom_entity({direction=0,layer=hz,x=hx,y=hy})    
  self.shadow:create_sprite("things/ground_effects")
  self.shadow:get_sprite():set_animation("shadow_small")
  self.shadow:bring_to_back()
  -- Set falling animation if any.
  if sprite:has_animation("falling") then 
    temp_starting_animation = sprite:get_animation()
    sprite:set_animation("falling") 
  end
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
      i = i+1; self.shadow:set_position(entity:get_position())
      entity:on_position_changed() -- Notify the entity (to move secondary sprites, etc).
      if i < 2*x_m then sprite:set_xy(0, h2 + f1(i))
      elseif i <= x_f then sprite:set_xy(0, h2 + f2(i))
      -- Call the callback and stop the timer. 
      else
        self:check_on_ground() -- Check for bad ground.
        if prop.callback ~= nil and self:exists() then -- Check if the entity exists (it can be removed on holes, water and lava).
          prop:callback() 
        end    
        return false
      end
      return true
    end)
    -- Move the shadow if necessary. Make the entity stop if its shadow collisions with some obstacle.
    if animation == "walking" then
      local m = sol.movement.create("straight"); m:set_angle(direction*math.pi/2)
      m:set_speed(speed); m:set_max_distance(x_f); m:set_smooth(false)
      function m:on_obstacle_reached() m:stop(); is_obstacle_reached = true end
      m:start(entity)
    end
  end

  -- Give inertia when thrown from moving platforms.
  local function make_inertia()   
    for other in map:get_entities("") do
      if other.get_inertia then
        if other:is_on_platform(hero) then
          local direction, speed, is_moving  = other:get_inertia()
          if not is_moving then return end
          local ddx, ddy = math.cos(direction*math.pi/2), -math.sin(direction*math.pi/2)
          local sx, sy, sz
          sol.timer.start(entity, math.floor(1000/speed), function()
            if entity.state ~= "falling" then return false end
            sx, sy, sz = self.shadow:get_position()
            if not self.shadow:test_obstacles(ddx, ddy, sz) then
              self.shadow:set_position(sx + ddx, sy + ddy, sz)
              local x,y,z = entity:get_position()
              x = x+ddx; y = y+ddy
              entity:set_position(x,y,z)
            else return false end
            return true
          end)
        end
      end
    end 
  end
  
  -- Function called when the entity has fallen.
  local function finish_bounce()
    self.shadow:remove() 
    sprite:set_xy(0,0); self.state = "on_ground"
    game:set_interaction_enabled(entity, true) -- Start checking the hero again.
    game:clear_interaction() -- Restart hero interaction.
    if temp_starting_animation then sprite:set_animation(temp_starting_animation) end -- Restore the initial animation, if necessary.
    entity:on_position_changed() -- Notify the entity (to move secondary sprites, etc).
    if temp_moved_on_platform then entity.moved_on_platform = true end -- Allow to be moved on platforms again, if necessary.
    if temp_can_push_buttons then self.can_push_buttons = true end -- Allow to push buttons again, if necessary.
    entity:start_checking_ground() -- Restart the timer to check ground once per second.
  end
  
  -- Start movement of the shadow. Throw the entity away in the direction of the hero and start checking the hero. Start shift of inertia.
  bounce({max_distance_x = 80, max_height_on_x = 30, max_height_y = 8, speed_pixels_per_second = 200,
  callback = function() bounce({max_distance_x = 16, max_height_on_x = 8, max_height_y = 4, speed_pixels_per_second = 100,
  callback = function() bounce({max_distance_x = 4, max_height_on_x = 2, max_height_y = 2, speed_pixels_per_second = 60,
  callback = finish_bounce }) end }) end })
  make_inertia()
end

-- Used to update direction/state when following the hero. Calls on_custom_position_changed if defined.
function entity:on_position_changed()
  if entity.associated_hero_index then
    local hero_entity = game.hero_manager:get_hero_entity(entity.associated_hero_index)
    self:set_direction(hero_entity:get_direction())
  end
  if self.on_custom_position_changed then self:on_custom_position_changed() end
end

-- Check for bad ground (water, hole and lava) and also for empty ground. (Used on each bounce when thrown.)
function entity:check_on_ground()
  local x, y, layer = self:get_position()
  local ground = map:get_ground(x, y, layer)
  if ground == "empty" and layer > 0 then 
    -- Fall to lower layer and check ground again.
     self:set_position(x, y, layer-1)
     self:check_on_ground() -- Check again new ground.
  elseif ground == "hole" then  
    -- Create falling animation centered correctly on the 8x8 grid.
    x = math.floor(x/8)*8 + 4; if map:get_ground(x, y, layer) ~= "hole" then x = x + 4 end
    y = math.floor(y/8)*8 + 4; if map:get_ground(x, y, layer) ~= "hole" then y = y + 4 end
    local fall_on_hole = map:create_custom_entity({x = x, y = y, layer = layer, direction = 0})
    local sprite = fall_on_hole:create_sprite("things/ground_effects")
    sprite:set_animation("hole_fall")
    self.shadow:remove(); self:remove()
    function sprite:on_animation_finished() fall_on_hole:remove() end
    sol.audio.play_sound("falling_on_hole")
  elseif ground == "deep_water" then
    -- Sink in water.
    local water_splash = map:create_custom_entity({x = x, y = y, layer = layer, direction = 0})    
    local sprite = water_splash:create_sprite("things/ground_effects")
    sprite:set_animation("water_splash")
    self.shadow:remove(); self:remove()
    function sprite:on_animation_finished() water_splash:remove() end
    sol.audio.play_sound("splash")
  elseif ground == "lava" then
    -- Sink in lava.
    local lava_splash = map:create_custom_entity({x = x, y = y, layer = layer, direction = 0})    
    local sprite = lava_splash:create_sprite("things/ground_effects")
    sprite:set_animation("lava_splash")
    self.shadow:remove(); self:remove()
    function sprite:on_animation_finished() lava_splash:remove() end
    sol.audio.play_sound("splash")
  elseif self.state == "falling" then -- Used for bounces, when the entity is thrown.
    sol.audio.play_sound(self.sound) -- Bouncing sound.
  end
end

-- Start a timer to check ground once per second (useful if the ground moves or changes type!!!).
function entity:start_checking_ground()
  sol.timer.start(self, 1000, function()
    if entity.state == "on_ground" then entity:check_on_ground() end
    return true
  end)
end

-- Function to get the information to save between maps.
function entity:get_saved_info()
  local properties = {associated_hero_index=self.associated_hero_index, state = self.state}
  -- Use the function entity.get_more_saved_info to get more extra information!!!
  if entity.get_more_saved_info then properties = entity:get_more_saved_info(properties) end
  return properties
end

-- Function to recover the saved information between maps.
function entity:set_saved_info(properties)
  self.associated_hero_index = properties.associated_hero_index
  self.state = properties.state
  if self.state == "carried" then
    local hero_entity = game.hero_manager:get_hero_entity(self.associated_hero_index)
    self:set_carried(hero_entity)
  end
  -- Use the function entity.set_more_saved_info to set more extra information!!!
  if entity.set_more_saved_info then entity:set_more_saved_info(properties) end
end
