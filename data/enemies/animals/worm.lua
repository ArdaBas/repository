local enemy = ...

function enemy:on_created()
  -- Set properties.
  self:set_life(3); self:set_damage(1); self:set_hurt_style("normal")
  self:set_pushed_back_when_hurt(false)
  self:set_push_hero_on_sword(true)
  local sprite = self:create_sprite("animals/worm")
  sprite:set_animation("walking")
  self:set_size(24, 24); self:set_origin(12, 12)
end
  
-- This function is called by the engine if the enemy is restarted (for instance, when starting or when hurt).
function enemy:on_restarted()
  self:go_to_hero()
end
  
function enemy:go_to_hero()
  local sprite = self:get_sprite()
  local m = sol.movement.create("target")
  m:set_target(self:get_map():get_hero())
  m:set_speed(60)
  function m:on_finished() enemy:go_to_hero() end
  function m:on_obstacle_reached() enemy:go_to_hero() end
  -- Actualize sprite direction. (Tail is actualized automatically.)
  function m:on_position_changed() sprite:set_direction(m:get_direction4()) end
  m:start(self)
end

