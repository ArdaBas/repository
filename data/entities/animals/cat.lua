
local entity = ...

entity.can_push_buttons = true
entity.moved_on_platform = true
entity.is_independent = true
entity.unique_id = "independent_cat"
entity.can_save_state = true

local target
local detection_distance = 64 -- Used to detect balls of yarn and mice.
local waiting_distance = 32 -- Used to wait when the ball of yarn is carried.
local state = "wait" -- Possible values: "wait", "follow", "play".

local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  -- Initialize state. 
  local sprite = self:get_sprite()
  sprite:set_animation("sit")
  self:set_drawn_in_y_order(true)
  self:check()
  -- Traversing properties.
  self:set_can_traverse_ground("hole", false)
  self:set_can_traverse_ground("deep_water", false)
  self:set_can_traverse_ground("lava", false)
  -- Notify the hud.
  self.action_effect = "custom_lift"
  game:set_interaction_enabled(entity, true)
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
  sol.timer.stop_all(self); self:stop_movement()
  game:clear_collision_tests(self)
  state = "wait"
  local sprite = self:get_sprite(); sprite:set_animation("sit")
  -- Restart in half second.
  sol.timer.start(self, 500, function() 
    entity:check()
    game:set_interaction_enabled(entity, true)
  end)
end

-- Wait.
function entity:wait()
  state = "wait"
  game:clear_collision_tests(self)
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
  game:clear_collision_tests(self)
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
  game:add_collision_test(entity, "collision_ball", "overlapping", function(self, other)
	if other:get_type() == "custom_entity" and other == target then 
	  if other:get_model() == "ball_of_yarn" and other.state == "on_ground" then
	    -- Stop movement and collision tests. Change state.
	    self:stop_movement()
      game:clear_collision_tests(self)
      state = "play"
	    -- Restore the custom action command (to avoid trying to lift now).
	    local hero = game:get_hero()
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
  game:add_collision_test(entity, "mouse_collision", "overlapping", function(self, other)
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
  for other in map:get_entities("") do 
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
  local hero =  game:get_hero()
  local hx, hy, hz = hero:get_position(); local cx, cy, cz = self:get_position()
  local has_good_direction = hero:get_direction4_to(self) == hero:get_direction()
  local is_close = (math.abs(hx - cx) < 10 and math.abs(hy - cy) < 24) 
                          or (math.abs(hx - cx) < 24 and math.abs(hy - cy) < 10)
  return has_good_direction and is_close and hz == cz
end

-- This method is called when the action button is pressed close to this entity. If the hero tries to lift the cat, it gets scared.
function entity:on_custom_interaction()
  game:set_interaction_enabled(entity, false)
  game:clear_interaction() -- ??
  sol.audio.play_sound("wrong")
  local hero = game:get_hero()
  game:set_custom_command_effect("action", nil)
  sol.timer.stop_all(self); self:stop_movement()
  local sprite = self:get_sprite(); sprite:set_animation("scared")
  sol.timer.start(self, 1000, function()
    self:restart()
  end)
end

-- Return true if the cat is following a ball of yarn carried by the hero.
function entity:can_change_map_now()
  local hero = game:get_hero()
  if not hero.custom_carry then return false end
  return (self:get_distance(hero) < detection_distance) and  (hero.custom_carry:get_model() == "ball_of_yarn")
end

function entity:on_position_changed()
  -- Look for empty ground to fall to lower layers.
  local x, y, layer = self:get_position() 
  local ground = map:get_ground(x, y, layer)
  if ground == "empty" and layer > 0 then
    self:set_position(x, y, layer-1)
    sol.audio.play_sound("hero_lands")
    self:restart()
  end
end


--[[
-- Function to get the information to save between maps.
function entity:get_saved_info()
  local properties = {color = self.color}
  return properties
end

-- Function to recover the saved information between maps.
function entity:set_saved_info(properties)
  self.color = properties.color
end
--]]
