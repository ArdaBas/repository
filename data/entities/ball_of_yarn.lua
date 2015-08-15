
local entity = ...
sol.main.load_file("entities/generic_portable")(entity)

local ball, yarn

-- This function is called after the on_created function of the generic_portable entity.
function entity:on_custom_created()
  self:set_size(16, 16); self:set_origin(8, 13); self:set_direction(0)
  -- Create sprites (if necessary).
  ball = self:get_sprite(); if ball == nil then ball = self:create_sprite("things/ball_of_yarn") end
  ball:set_animation("stopped")
  yarn = self:create_sprite("things/ball_of_yarn"); yarn:set_animation("yarn"); yarn:set_direction(entity:get_direction())
  -- Function to initialize yarn (the tail) to be drawn at the correct position.
  local function actualize_yarn()
    local direction = entity:get_direction(); local x,y = ball:get_xy()
    if direction == 0 then yarn:set_xy(x-8,y)
    elseif direction == 1 then yarn:set_xy(x,y+8)
    elseif direction == 2 then yarn:set_xy(x+8,y)
    elseif direction == 3 then yarn:set_xy(x,y-8) end
	if self.state == "on_ground" and yarn:get_animation() ~= "yarn" then yarn:set_animation("yarn") end
	if self.state == "carried" and yarn:get_animation() ~= "yarn_carried" then yarn:set_animation("yarn_carried") end
	if self.state == "falling" and yarn:get_animation() ~= "yarn_falling" then yarn:set_animation("yarn_falling") end
	if self.state == "lifting" and yarn:get_animation() ~= "yarn_carried" then yarn:set_animation("yarn_carried") end
  end
  -- Initialize and actualize yarn position when necessary.
  actualize_yarn()
  function yarn:on_direction_changed(animation, direction) actualize_yarn() end
  -- Move the secondary sprite yarn. This function is called from the main script, when the entity is falling and the position of the sprite changes. 
  function entity.on_custom_position_changed() 
    actualize_yarn() 
	if self.state == "lifting" and ball:get_animation() == "roll" then ball:set_animation("stopped") end
  end
end

-- Functions to recover the ball or the yarn.
function entity:get_ball() return ball end
function entity:get_yarn() return yarn end
