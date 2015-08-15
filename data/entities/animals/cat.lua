
local entity = ...

entity.can_push_buttons = true

local target
local detection_distance = 64
local waiting_distance = 32 -- Used to wait when the ball of yarn is carried.
local state = "wait" -- Possible values: "wait", "follow", "play".

function entity:on_created()
  -- Initialize state. 
  self:set_size(16, 16); self:set_origin(8, 13); 
  local sprite = self:get_sprite()
  sprite:set_animation("sit"); self:set_direction(3)
  self:set_drawn_in_y_order(true)
  self:check(); self:check_hero_lift()
end

-- Start looking for balls of yarn and mice. Mice have priority over balls.
function entity:check()
  local yarn_balls, mice, closest_ball, closest_mouse
  sol.timer.start(self, 100, function() 
    yarn_balls, mice = self:get_balls_and_mice()
    closest_ball = self:get_closest(yarn_balls)
    closest_mouse = self:get_closest(mice)
	-- Turn direction towards target if close and waiting.
	if target ~= nil and state == "wait" then
	  if self:get_distance(target) < detection_distance then
	    local direction = self:get_direction4_to(target); self:set_direction(direction)
	  end
	end
	-- Check mice.
	if closest_mouse  then
	  if self:get_distance(closest_mouse) < detection_distance then
	    if target ~= closest_mouse or state == "wait" then
	      target = closest_mouse; self:follow_target() -- Follow mice.
		  if math.random() < 0.5 then sol.audio.play_sound("cat") end -- Meow!
		end
		return true
	  end
	end
	-- Check balls.
	if closest_ball then
	  if self:get_distance(closest_ball) < detection_distance then
	    if (self:get_distance(closest_ball) >= waiting_distance or closest_ball.state == "on_ground") 
		        and (target ~= closest_ball or state == "wait") then
	      target = closest_ball; self:follow_target() -- Follow ball.
		elseif self:get_distance(closest_ball) < waiting_distance and closest_ball.state ~= "on_ground" and state ~= "wait" then
		  -- Wait until the ball is on ground.
		  target = closest_ball; self:wait()
		  if math.random() < 0.5 then sol.audio.play_sound("cat") end -- Meow!
        end
		return true
      end
    end	
    if state ~= "wait" then
	  -- Wait until there is a target close. (Restart everything.)
	  self:restart(); return false
	end
	return true -- Restart loop.
  end)  
end

-- Restart state. Used after touching a ball or killing a mouse, to start checking again.
function entity:restart()
  sol.timer.stop_all(self);  self:stop_movement(); self:clear_collision_tests(); state = "wait"
  local sprite = self:get_sprite(); sprite:set_animation("sit")
  -- Restart in half second.
  sol.timer.start(self, 500, function() 
    entity:check(); entity:check_hero_lift()
  end)
end

-- Wait.
function entity:wait()
  state = "wait"
  self:clear_collision_tests()
  local sprite =  self:get_sprite()
  self:stop_movement(); sprite:set_animation("sit")
end

-- Follow the ball.
function entity:follow_target()
  -- Move towards the ball.
  state = "follow"
  local ball = target; local sprite = self:get_sprite()
  local m = sol.movement.create("target"); m:set_target(ball); m:set_speed(50)
  function m:on_position_changed() sprite:set_direction(m:get_direction4()) end
  m:start(self); sprite:set_animation("walking")
  -- Create collision test (the previous ones are destroyed).
  self:clear_collision_tests()
  if target:get_type() == "custom_entity" then
    if target:get_model() == "ball_of_yarn" then
      self:add_ball_collision_test()
	end
  elseif target:get_type() == "enemy" then
    if target:get_breed() == "animals/mouse" then
      self:add_mouse_collision_test()
	end
  end
end

function entity:add_ball_collision_test()
  local sprite = self:get_sprite()
  local function shifts(direction) -- Function used later in the collision test.
    local dx, dy = 0, 0
	if direction == 0 then dx = -16 elseif direction == 2 then dx = 16 end
	if direction == 1 then dy = 20 elseif direction == 3 then dy = -8 end
	return dx, dy
  end
  -- Define collision test.
  self:add_collision_test("overlapping", function(self, other)
	if other:get_type() == "custom_entity" and other == target then 
	  if other:get_model() == "ball_of_yarn" and other.state == "on_ground" then
	    -- Stop movement and collision tests. Change state.
	    self:stop_movement(); self:clear_collision_tests(); state = "play"
	    -- Restore the custom action command (to avoid trying to lift now).
	    local game = self:get_game(); local hero = game:get_hero()
	    if game:get_custom_command_effect("action") == "custom_lift" and hero.custom_lift == self then
	      game:set_custom_command_effect("action", nil); hero.custom_lift = nil
	    end
	    -- Get shift to move sprite to display in front of the ball.
	    -- If there is no space in that direction (some wall), change to other direction.
	    local dir = self:get_direction4_to(other)
	    local dx, dy = shifts(dir)
	    if self:test_obstacles(dx, dy) then 
	      dir = (dir+2)%4; dx, dy = shifts(dir) 
	      if self:test_obstacles(dx, dy) then 
		    dir = (dir+1)%4; dx, dy = shifts(dir)
	        if self:test_obstacles(dx, dy) then 
			  dir = (dir+2)%4; dx, dy = shifts(dir) 
			  if self:test_obstacles(dx, dy) then self:restart(); return end
			end
		  end
	    end
	    self:set_direction(dir)
	    -- Change position.
	    local bx, by, _ = other:get_position()
	    self:set_position(bx + dx , by + dy) -- This does not give problems since ball and cat have same size.
	    sprite:set_animation("touch") -- Touch the ball.
	    -- Roll the ball towards the cat, with the yarn towards it.
	    local sprite2 = other:get_sprite()
	    sprite2:set_animation("roll"); other:set_direction(dir); other:get_ball():set_direction((dir+2)%4)
	    -- Restart animation of the ball after rolling, if necessary.
	    function sprite2:on_animation_finished(animation) 
		  if other.state == "on_ground" and target == other and sprite:get_animation() == "touch" then sprite2:set_animation("roll")
	      else sprite2:set_animation("stopped") end
        end
      end	
	end
  end)
end

function entity:add_mouse_collision_test()
  -- Define collision test.
  self:add_collision_test("overlapping", function(self, other)
	if other:get_type() == "enemy" and other == target then
	  if other:get_breed() == "animals/mouse" then 
	    other:set_life(0) -- Kill the mouse
		self:restart()
	  end	
	end
  end)
end

-- Return the lists of balls of yarn and mice on the map.
function entity:get_balls_and_mice()
  local yarn_balls = {}; local mice = {}
  for other in self:get_map():get_entities("") do 
	if other:get_type() == "custom_entity" then
	  if other:get_model() == "ball_of_yarn" then table.insert(yarn_balls, other) end
	end
    if other:get_type() == "enemy" then
	  if other:get_breed() == "animals/mouse" then table.insert(mice, other) end
	end
  end
  return yarn_balls, mice 
end

-- Return the closest entity of the list, or nil if the list is empty.
function entity:get_closest(list)
  local closest
  for _, x in pairs(list) do
    if closest == nil then closest = x
	elseif self:get_distance(x) < self:get_distance(closest) then closest = x end 
  end	
  return closest
end

-- Returns boolean if the hero is close and facing this entity.
function entity:is_facing_hero()
  local hero =  self:get_map():get_hero()
  local hx, hy, hz = hero:get_position(); local cx, cy, cz = self:get_position()
  local has_good_direction = hero:get_direction4_to(self) == hero:get_direction()
  local is_close = (math.abs(hx - cx) < 10 and math.abs(hy - cy) < 24) 
                          or (math.abs(hx - cx) < 24 and math.abs(hy - cy) < 10)
  return has_good_direction and is_close and hz == cz
end

-- Notifies the HUD and game_manager if the hero is close and can try to lift the cat.
function entity:check_hero_lift()
  --  The loop will be restarted.
  sol.timer.start(entity, 50, function() self:check_hero_lift() end)
  -- If the cat is playing with ball, the HUD is not activated.
  if state == "play" then return end
  -- If hero is close and no action active, show in the HUD that the item can be lifted and save a reference to this entity in hero.custom_lift.
  local game = self:get_game(); local hero = game:get_hero()
  if self:is_facing_hero() and game:get_custom_command_effect("action") == nil then
    game:set_custom_command_effect("action", "custom_lift"); hero.custom_lift = self
  -- If the hero move away from this entity, remove the custom effect "custom lift" if necessary.
  elseif (not self:is_facing_hero()) and hero.custom_lift == self then
	game:set_custom_command_effect("action", nil); hero.custom_lift = nil
  end
end

-- This method is called when the action button is pressed close to this entity. If the hero tries to lift the cat, it gets scared.
function entity:lift()
  sol.audio.play_sound("wrong")
  local game = self:get_game(); local hero = self:get_map():get_hero()
  hero:freeze(); hero:set_invincible(true)
  game:set_custom_command_effect("action", nil)
  sol.timer.stop_all(self); self:stop_movement()
  local sprite = self:get_sprite(); sprite:set_animation("scared")
  sol.timer.start(self, 1000, function() 
    hero:unfreeze(); hero:set_invincible(false)
    self:restart()
  end)
end

