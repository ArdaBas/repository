--[[ Base script used to define chests.
The treasure must be determined in the map script using the function set_treasure.
The boolean "is_open" is saved by the engine in some savegame variable.

----- To set the treasure and dialog_id in the map script, use the method:
  entity:set_treasure(item_name, dialog_id) 
--]]


local entity = ...

local savegame_variable, is_open, treasure, dialog, bright

function entity:on_created()
  -- Get the sprite of the entity (that was chosen on the editor). If there is no sprite, the entity is removed.
  local sprite = self:get_sprite(); if sprite == nil then self:remove() end
  -- Load state "is_open" (the chest may have been opened before). Set the required animation open/closed.
  local map = self:get_map()
  local x,y,layer = self:get_position()
  savegame_variable = "chest_".. map:get_id() .."_".. x .."_".. y
  savegame_variable = string.gsub(savegame_variable, "/", "_") -- Remove slash (not allowed as name of savegame variable).
  is_open = map:get_game():get_value(savegame_variable)
  if is_open == nil then is_open = false end 
  if is_open then sprite:set_animation("open") end
  -- Set properties, and bright(in case the chest has a seal).
  self:set_traversable_by(false)
  self:set_size(16, 16); self:set_origin(8, 13)
  if (not is_open) and self:associated_hero_index() ~= 0 then self:set_bright() end
  -- If the chest is closed, add a collision test to notify the HUD when the hero is facing the chest (to display it).
  if (not is_open) then
    self:add_collision_test("facing", function()
      if self:get_game():get_hero():get_direction() ~= 1 then return end
	  local effect = self:get_game():get_command_effect("action")
	  local custom_effect = self:get_game():get_custom_command_effect("action")
	  if effect ~= nil or (custom_effect ~= "open" and custom_effect ~= nil) then return end
      self:get_game():set_custom_command_effect("action", "open")
	  sol.timer.stop_all(sprite) -- (Use timers on the sprite to avoid interferences with the timer of the bright.)
      sol.timer.start(sprite, 50, function() 
	    -- (We need the following "if" just in case the custom command effect has been changed by other entity.)
	    if self:get_game():get_custom_command_effect("action") == "open" then
	      self:get_game():set_custom_command_effect("action", nil) 
		end
	  end)
    end)
  end
end

-- Use this function on the map script to determine the treasure of the chest and the dialog_id.
function entity:set_treasure(item_name, dialog_id) 
  treasure = item_name; dialog = dialog_id
end

-- Make the chest shine each 2 seconds.
function entity:set_bright()
  bright = self:create_sprite("things/chest_bright")
  sol.timer.start(self, 2000, function() bright:set_animation("bright"); return true; end)
end

-- Return the index of the only hero that can open the chest, or 0 in case any hero can open it.
function entity:associated_hero_index()
  local name = self:get_sprite():get_animation_set()
  if name == "things/chest_cuspis" then return 1 end
  if name == "things/chest_robyne" then return 2 end
  if name == "things/chest_wizard" then return 3 end
  return 0
end

-- Open the chest when the action button is pressed in front of the chest, 
-- or show a custom dialog if the hero tries to open it from other direction.
function entity:on_interaction()
  if is_open then return end -- The chest was already open.
  local game = self:get_game(); local hero = game:get_hero()
  if hero:get_direction() ~= 1 then return end -- The hero is not in front.
  --if hero.custom_carry ~= nil then return end -- The hero is carrying something, so we do nothing.
  if self:get_game():get_command_effect("action") ~= nil 
    or self:get_game():get_custom_command_effect("action") ~= "open" then return end -- There is another action active.
  -- If the hero is the chosen one, open the chest.
  local hero_index = self:get_game():get_hero_manager().current_hero_index
  local index = self:associated_hero_index()
  if index == 0 or index == hero_index then self:open(); return end
  -- If the hero is not the chosen one, show dialog of sealed chest.
  self:get_game():start_dialog("_treasure.sealed", function()
	sol.audio.play_sound("wrong")
  end)
end

-- Function called when the chest is opened.
function entity:open()
  local map = self:get_map(); local hero = map:get_hero(); local game = self:get_game()
  hero:freeze()
  -- Open the chest, destroy the bright (if any), clear collision test, make a sound of opening.
  is_open = true
  sol.audio.play_sound("chest_open")
  self:get_sprite():set_animation("open")
  if bright ~= nil then self:remove_sprite(bright) end
  self:clear_collision_tests()
  -- Actualize savegame variable to save state. 
  game:set_value(savegame_variable, true)
  if treasure == nil then
    -- The chest is empty. Show a dialog (after a delay, to show when the chest is opened). 
    sol.timer.start(self, 250, function()
	  game:start_dialog("_treasure.nothing", function() 
	    hero:set_animation("surprised")
		sol.audio.play_sound("wrong") -- Make a sound.
	    sol.timer.start(self, 1000, function()
	      hero:set_animation("stopped"); hero:unfreeze()  
	    end)
	  end)
	end)
  else
    -- The chest has something. Make the hero brandish the treasure (after a delay). Obtain the item. 
    sol.timer.start(self, 250, function() 
	  sol.audio.play_sound("treasure")
	  local hx,hy,_ = hero:get_position()
	  local sprite = sol.sprite.create("entities/items") --self:create_sprite("entities/items")
	  sprite:set_animation(treasure)
	  -- We draw the item above the hero at each update (after the entity is drawn).
	  function entity:on_post_draw() map:draw_sprite(sprite,hx,hy-25) end
	  -- Start the brandish animation of the hero, and later start the dialog.
	  hero:set_animation("brandish") 
	  sol.timer.start(self, 2000, function()
	    game:start_dialog(dialog, function()
          entity.on_post_draw = nil; sprite = nil; -- Destroy the sprite (and the draw function).
		  hero:set_animation("stopped"); hero:unfreeze() 
		 -- OBTAIN ITEM HERE!!!
		 
		end)
	  end)
    end)
  end
end


	  