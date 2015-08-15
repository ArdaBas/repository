-- Script for a hero dialog menu. This is a manager for the menus and dialogs with npc_heroes.

local menu = { 
  game, hm , npc, npc_initial_direction
}

-- Starts a dialog with some npc hero.
function menu:start(game, hm, npc)
  
  -- Freezes hero (the menu starts later). Initialize variables.
  local hero = game:get_hero()
  hero:freeze()
  self.game = game; self.hm = hm
  self.hm.set_dialog_enabled(true)
  self.npc = npc; self.npc_initial_direction = npc:get_direction()
  -- Change direction to face hero.
  npc:set_direction((hero:get_direction()+2)%4)
  -- Initialize the menu background, cursor, captions and colors.
  self.background = sol.surface.create("menus/options_dialog.png")
  self.background:set_opacity(216)
  self.state = "options"
  self.selector_sprite = sol.sprite.create("menus/pause_cursor")
  self.selector_position = 0
  self.hero_color_rgb = {{8, 100, 8}, {100, 8, 8}, {8, 8, 100}}
  
  self.options_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = self.hero_color_rgb[self.npc:get_index()],
	text_key = "options",
    font = "fixed8",
  }
  
  self.talk_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.talk",
    font = "fixed8",
  }  
  self.change_items_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.change_items",
    font = "fixed8",
  }
  self.ask_for_help_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.ask_for_help",
    font = "fixed8",
  }  
    self.leave_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.leave",
    font = "fixed8",
  }  
  
  -- Use a timer to start the menu a bit later than when the npc turned.
  sol.timer.start(game, 300, function() 
    -- Changes pause menu, pauses game, and dialog starts from on_paused() on game_manager.
    game:set_custom_pause_menu(menu)
    game:set_paused()
  end)
end

function menu:on_finished()
  sol.menu.stop(menu)
  self.hm:set_dialog_enabled(false)
  self.game:set_paused(false)
  menu.game:set_custom_pause_menu(nil)
  sol.timer.start(menu.game, 300, function() 
    menu.npc:set_direction(self.npc_initial_direction)    
    menu.game:get_hero():unfreeze()
  end)
end

function menu:on_command_pressed(command)

  --We are in the hero dialog menu.
  if command == "up" then
    sol.audio.play_sound("cursor")
    self.selector_position = (self.selector_position -1)%4
    return true

  elseif command == "down" then
    sol.audio.play_sound("cursor")
    self.selector_position = (self.selector_position +1)%4
    return true
	
  elseif command == "pause" then
    return false -- Close the menu.
	
  elseif command == "attack" or command == "action" then
    if self.selector_position == 0 then -- Talk.
    self.state = "talk"
    self.selector_position = 0
	sol.audio.play_sound("danger")
	return true 
    elseif self.selector_position == 1 then -- Change items.
	  self.state = "change_items"
	  self.selector_position = 0
	  return true
	elseif self.selector_position == 2 then -- Ask for help.
	  self.state = "ask_for_help_submenu"  
	  self.selector_position = 0
      return true
	elseif self.selector_position == 3 then -- Leave.
  	self.state = "exit_game"
	self.selector_position = 0
    return true
	end
  end
end

function menu:on_draw(dst_surface)

  -- Draw option submenu.
  local width, height = dst_surface:get_size()
  local x = width / 2
  local y = (height / 4) + 3
  self.background:draw_region( 0, 0, 176, 160, dst_surface, x - 88, height / 2 - 76)
  -- Draw the selection cursor for the options dialog.
  self.selector_sprite:set_animation("select_option")
  self.selector_sprite:draw(dst_surface, 86, 72 + 32*self.selector_position)
  self.options_caption:draw(dst_surface, x, y-4)
  self.talk_caption:draw(dst_surface, x, y + 24)
  self.change_items_caption:draw(dst_surface, x, y + 56)
  self.ask_for_help_caption:draw(dst_surface, x, y + 88)
  self.leave_caption:draw(dst_surface, x, y + 120)	

end



return menu
