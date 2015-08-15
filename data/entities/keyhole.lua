-- Script for key locks of certain color.
local entity = ...

entity.can_interact = true -- Change this to disable door interaction temporarily (used with locks hidden under doors).

-- Dialog ids.
local dialog_locked = "_dialog_locked"
local dialog_wrong_key = "_dialog_wrong_key"

function entity:on_created()
  -- Properties.
  self:set_traversable_by(false)
  -- Add collision test to be opened by keys of the same color.
  entity:add_collision_test("facing", function(self, other)
    if not entity.can_interact then return end
    -- Do nothing if the facing entity is not the hero or if the carried item is not a key of the same color as the lock.
	local game = self:get_game()
	if game:is_dialog_enabled() then return end
	local hero = game:get_hero()
	if other ~= hero then return end
	if hero:get_animation() ~= "walking" then return end -- Necessary to avoid some problems.
	local item = hero.custom_carry
	local colorlock = self:get_sprite():get_animation()
    if item == nil then 
	  game:start_dialog(dialog_locked, colorlock)
  	  return 
	end
	if item:get_model() ~= "key" then return end
	local colorkey = item:get_sprite():get_animation()
	if colorlock ~= colorkey then
	  game:start_dialog(dialog_wrong_key, colorlock)
	  return 
	end
	-- Here, the item is a key and the color coincides. First, stop carrying the key and clear collision test. 
	hero:set_carrying(false); hero.custom_carry = nil
    item.on_pre_draw = nil -- Delete function to follow hero.
    item.associated_hero_index = nil; item.state = "falling"
    game:set_custom_command_effect("action", nil)
    game:set_custom_command_effect("attack", nil)
	entity:clear_collision_tests()
	-- Make the key fly towards the lock (keyhole) and, then destroy both of them.
	local x,y,z = entity:get_position()
	local ox,oy = entity:get_origin()
	local w,h = entity:get_size()
	item:set_position(x-ox+w/2, y+oy+h/2, z); item:bring_to_front()
	item:get_sprite():set_animation(colorkey .. "_falling")
	local m = sol.movement.create("straight")
    m:set_speed(100); m:set_angle(math.pi/2)
    m:set_max_distance(32); m:set_ignore_obstacles(true)
    m:start(item)
	sol.audio.play_sound("open_lock")
	function m:on_finished()
	  sol.audio.play_sound("door_open")
	  item:remove(); entity:remove()
	end
	
  end)
end

