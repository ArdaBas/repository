local entity = ...

entity.can_save_state = true
entity.moved_on_platform = true
entity.can_push_buttons = true

local pos_x, pos_y
local pushing = false

function entity:on_created()
  self:set_size(16, 16)
  self:set_traversable_by("hero", false)
  self:set_traversable_by("custom_entity", true) --To allow pushing block into pit.
  pos_x, pos_y, _ = self:get_position()
  self:set_modified_ground("wall") -- Not traversable by other entities.

  -- Collision test to push.
  self:add_collision_test("facing", function(self, other)  
    if other:get_type() == "hero" and not pushing then
      if other:get_animation() == "pushing" then
	    self:set_modified_ground("empty") -- Remove "wall" ground to allow movement. 
		-- Do nothing if the block is against the wall (this avoids some problem).
		local dir = other:get_direction()
		local angle = dir*math.pi/2
		if self:test_obstacles(math.cos(angle), -math.sin(angle)) then return end
		-- Push the block.
		pushing = true
        other:freeze()
		sol.audio.play_sound("hero_pushes")
        other:set_animation("pushing")
        local m = sol.movement.create("path")
        m:set_ignore_obstacles(false)
        m:set_path({2*dir,2*dir})
        m:start(self)
      end
    end
  end)
  
  -- Collision test to avoid pushing over other heroes.
  self:add_collision_test("overlapping", function(self, other)
	if not pushing then return end
    if other:get_type() == "custom_entity" and (not other.is_block_traversable) then
	  self:on_obstacle_reached()
	end
  end)
  
end

-- Function to make the block go back. Used if an obstacle (or npc_hero) is reached.
function entity:on_obstacle_reached()
  self:stop_movement()
  local hero = self:get_game():get_hero()
  hero:set_animation("stopped") -- Avoids problem of bouncing between wall and hero forever.
  sol.audio.play_sound("door_open")
  local m = sol.movement.create("straight")
  local dir = self:get_direction4_to(pos_x,pos_y)
  local dist = self:get_distance(pos_x, pos_y)
  m:set_max_distance(dist)
  m:set_angle(dir*math.pi/2)
  m:start(self)
end

function entity:on_movement_finished()
  self:snap_to_grid()
  local hero = self:get_game():get_hero()
  pos_x, pos_y, _ = self:get_position()
  hero:set_animation("stopped") -- Avoids problem of bouncing between wall and hero forever.
  hero:unfreeze()
  self:set_modified_ground("wall") -- Not traversable by other entities (this was changed to allow movement).
  pushing = false
end 



