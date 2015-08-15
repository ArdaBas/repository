local enemy = ...

local state = "walk"
local tail

function enemy:on_created()
  -- Set properties.
  self:set_life(10); self:set_damage(4); self:set_hurt_style("normal")
  self:set_pushed_back_when_hurt(false); self:set_push_hero_on_sword(false)
  self:set_traversable(true)
  local sprite = self:create_sprite("animals/mouse_boss")
  sprite:set_animation("stopped"); sprite:set_direction(3)
  self:set_size(24, 24); self:set_origin(12, 12)
  -- Create tail sprite.
  local x,y,z = self:get_position()
  tail = self:get_map():create_custom_entity({direction=3,x=x,y=y,layer=z,width=16,height=16})
  local tail_sprite = tail:create_sprite("animals/mouse_boss")
  tail_sprite:set_animation("tail")
  function tail_sprite:actualize_direction(dir)
    tail_sprite:set_direction(dir)
    if dir == 0 then tail_sprite:set_xy(-24,0)
    elseif dir == 2 then tail_sprite:set_xy(24,0)
    elseif dir == 1 then tail_sprite:set_xy(0,24)
    else tail_sprite:set_xy(0,-24) end
  end
  tail_sprite:actualize_direction(3) -- Initialize tail direction.
  -- Changes position/direction of tail sprite when necessary.
  function sprite:on_direction_changed(animation, dir) tail_sprite:actualize_direction(dir) end
  function enemy:on_position_changed(x, y, layer) tail:set_position(x, y, layer) end
end

-- This function is called by the engine if the enemy is restarted (for instance, when starting or when hurt).
function enemy:on_restarted()
  -- Do nothing in case the enemy is pre-attacking (restart is invoked when enemy is hurt before the attack).
  if state == "pre-attack" then return end
  -- Restart.
  state = "walk"
  self:check(); self:go_random()
end


function enemy:on_dying()
  self:stop_movement() -- Destroy the tail when dying.
  tail:remove() 
  local x,y,z = self:get_position()
  local worm = self:get_map():create_enemy({direction=0,x=x,y=y,layer=z,breed="animals/worm"})
  -- Notify map that this boss is dead.
  function worm:on_dead()
    self:get_map():notify_dead_mouse()
  end
end  


function enemy:check()
  -- Attack when aligned with the hero.
  if state == "walk" then
    local x,y,_ = self:get_position()
    local hx,hy,_ = self:get_map():get_hero():get_position()
    if math.abs(x-hx) < 7 or math.abs(y-hy) < 7 then self:attack() end 
  end
  sol.timer.start(self, 100, function() self:check() end)
end

function enemy:go_random()
  local sprite = self:get_sprite()
  sprite:set_animation("walking")
  local m = sol.movement.create("random")
  m:set_speed(50)
  function m:on_finished() enemy:go_random() end
  function m:on_obstacle_reached() enemy:go_random() end
  -- Actualize sprite direction. (Tail is actualized automatically.)
  function m:on_position_changed() sprite:set_direction(m:get_direction4()) end
  m:start(self)
end


function enemy:attack()
  state = "pre-attack"  
  self:stop_movement()
  local dir = self:get_direction4_to(self:get_map():get_hero())
  self:get_sprite():set_direction(dir)
  self:get_sprite():set_animation("run")
  sol.audio.play_sound("mouse")
  sol.timer.start(self:get_map(), 1000, function()
    state = "attack"
    self:get_sprite():set_animation("run") -- (The animation may have been changed when hurt.)
    self:get_sprite():set_direction(dir)
    local m = sol.movement.create("straight")
	m:set_angle(dir*math.pi/2); m:set_speed(400)
    function m:on_finished() enemy:unconscious() end
	-- Make quake if collision with wall.
    function m:on_obstacle_reached()
	  enemy:unconscious() 
	  sol.audio.play_sound("quake") 
	  -- Create falling rock above the hero.
	  local x,y,_ = enemy:get_map():get_hero():get_position()
	  enemy:get_map():create_enemy({x=x, y=y ,layer=2, direction=0, breed="projectiles/falling_rock"})
	end
    m:start(self)
  end)
end

-- Used when collision with wall or if other enemy has collided with this.
function enemy:unconscious()
  -- Reset.
  self:stop_movement(); sol.timer.stop_all(self); state = "walk"
  -- Show groggy animation.
  local sprite = self:get_sprite()
  sprite:set_animation("unconscious")
  -- Start quake effect.
  local dir = sprite:get_direction()
  local map = self:get_map()
  local length = 300
  self:quake(map, dir, length)
  -- Restart in few seconds.
  sol.timer.start(self, 2000, function() 
    self:go_random(); self:check()
  end)
end

function enemy:quake(map, direction, length)
  local speed = 700
  local hx, hy, _ = map:get_hero():get_position()
  local w, h = map:get_size()
  local x, y, dx, dy
  if direction%2 == 0 then x = w/2; y = hy; dx = 8; dy = 0
  else x = hx; y = h/2; dx = 0; dy = 8 end
  map:move_camera(x+dx, y+dy, speed, function() 
	map:move_camera(x-dx, y-dy, speed, function()
	  self:quake(map, direction, length)
	end, 0, length)
  end, 0, length)
end


