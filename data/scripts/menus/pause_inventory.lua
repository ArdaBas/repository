local submenu = require("scripts/menus/pause_submenu")
local inventory_submenu = submenu:new()

-- There is a 4x4=16 weapon_submenu and a 4x4=16 item_submenu. This makes a 8x4=32 inventory_submenu for each character.
-- The self.cursor_row and self.cursor_column values from 0 to 7. The variable "pause_inventory_last_item_index" from 0 to 31)
-- The 3 item lists are stored in the item_list array.

local item_list = {} 
local counter_list = {}
item_list[1] = { 
  "feather", "bow","sword","feather","feather","feather",
  "feather","feather","feather","feather","feather","sword",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing","nothing","nothing"
}
item_list[2] = {
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing","nothing","nothing"
}
item_list[3] = {
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing",
  "nothing","nothing","nothing","nothing","nothing","nothing","nothing","nothing"
}
counter_list[1] = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,    nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,   nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}
counter_list[2] = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,    nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,   nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}
counter_list[3] = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,    nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,   nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil}


function inventory_submenu:on_started()

  submenu.on_started(self)
  
  -- Initialize secondary menu surfaces, hero sprites and colors.
  self.switch_character_dialog_surface = sol.surface.create("menus/switch_character_dialog.png")
   self.sprite_hero = {}; for i=1,3 do self.sprite_hero[i] = sol.sprite.create(self.game:get_hero_manager().hero_tunic_sprites[i]) end
  for k=1,3 do self.sprite_hero[k]:set_direction(3); self.sprite_hero[k]:set_animation("stopped") end
  self.hero_color = {"green", "pink", "blue", "gray"}
  self.hero_color_rgb = {{8, 100, 8}, {100, 8, 8}, {8, 8, 100}}
  
  -- Initialize cursors and items.
  self.cursor_sprite = sol.sprite.create("menus/pause_cursor")
  self.selector_sprite = sol.sprite.create("menus/pause_cursor")
  self.item_names = {}
  self.sprites = {}
  self.counters = {}
  self.captions = {}

  for k = 1, 32 do
    -- Get the item, its possession state and amount.
	local item = self.game:get_item(item_list[self:get_hero_index()][k])	
  
    if item:has_amount() then
      -- Show a counter in this case.
      local amount = counter_list[self:get_hero_index()][k]    ---------------item:get_amount()
      local maximum = item:get_max_amount()

      self.counters[k] = sol.text_surface.create{
        horizontal_alignment = "center", 
        vertical_alignment = "top",
        text = counter_list[self:get_hero_index()][k],
        font = (amount == maximum) and "green_digits" or "white_digits",
      }
	else
	  self.counters[k] = nil
    end
    -- Initialize the sprite and the caption string.
    self.sprites[k] = sol.sprite.create("entities/items")
	self.sprites[k]:set_animation(item_list[self:get_hero_index()][k])	
  end

  -- Initialize the cursors.
  local index = self.game:get_value("pause_inventory_last_item_index") or 0
  local row = math.floor(index / 8)
  local column = index % 8
  self:set_cursor_position(row, column)
  self.selector_position = 0
  
  -- Shows the info of the item.
  -- self:show_info_message() ----------------------------------------------- PARA MAS TARDE
  
  -- Initialize the sprites of the left and right item backgrounds and their initial color.
  self.left_color_index = 4
  self.right_color_index = self:get_hero_index() 
  self.left_inventory_background = sol.sprite.create("menus/inventory_color_background")
  self.right_inventory_background = sol.sprite.create("menus/inventory_color_background")
  
  -- Option submenu captions. 
  self.inventory_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = self.hero_color_rgb[self:get_hero_index()],
	text_key = "inventory",
    font = "Viner Hand Itc",
  }
  
  self.options_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = self.hero_color_rgb[self:get_hero_index()],
	text_key = "options",
    font = "Viner Hand Itc",
  }
  
  self.continue_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.continue",
    font = "fixed8",
  }  
  
  self.switch_character_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.switch_character",
    font = "fixed8",
  }
  
  self.save_game_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.save_game",
    font = "fixed8",
  }  
  
    self.exit_game_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = {8, 8, 8},
	text_key = "options.exit_game",
    font = "fixed8",
  }  
  
  self.switch_character_menu_caption = sol.text_surface.create{
    horizontal_alignment = "center",
    vertical_alignment = "middle",
    color = self.hero_color_rgb[self:get_hero_index()],
	text_key = "options.switch_character_menu",
    font = "Viner Hand Itc",
  }
  


  
end

function inventory_submenu:on_finished()

  if self.is_assigning_item then
    self:finish_assigning_item()
  end

  if self.game.hud ~= nil then
    self.game.hud.item_icon_1.surface:set_opacity(255)
    self.game.hud.item_icon_2.surface:set_opacity(255)
  end
end

function inventory_submenu:set_cursor_position(row, column) 

  self.cursor_row = row
  self.cursor_column = column

  local index = row * 8 + column
  self.game:set_value("pause_inventory_last_item_index", index)

  -- Update the caption text and the action icon.
  local item_name = item_list[self:get_hero_index()][index + 1]
  local item = self.game:get_item(item_name)
  local variant = item and item:get_variant() or 0

  local item_icon_opacity = 128
  if variant > 0 then
    self:set_caption("inventory.caption.item." .. item_name .. "." .. variant)
    self.game:set_custom_command_effect("action", "info")
    if item:is_assignable() then
      item_icon_opacity = 255
    end
  else
    self:set_caption(nil)
    self.game:set_custom_command_effect("action", nil)
  end
  --self.game.hud.item_icon_1.surface:set_opacity(item_icon_opacity)
  --self.game.hud.item_icon_2.surface:set_opacity(item_icon_opacity) 
  
  -- Shows the info of the item.
  -- self:show_info_message() ----------------------------------------------- PARA MAS TARDE
  
end

function inventory_submenu:get_selected_index()
  return self.cursor_row * 8 + self.cursor_column
end


function inventory_submenu:on_command_pressed(command)
  
  local handled = submenu.on_command_pressed(self, command)
  -- If handled == true, the menu has been closed, and we end this function.
  if handled then return true end
  
  if self.options_dialog_state == "inventory_submenu" then
  -- The options_dialog submenu is closed, so we are in the inventory submenu.
    if command == "action" then
      self:next_submenu()
      return true   
    elseif command == "item_1" then
      self:assign_item(1)
      return true
    elseif command == "item_2" then
      self:assign_item(2)
	  return true
    elseif command == "left" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position(self.cursor_row, (self.cursor_column - 1)%8 )
	  return true
    elseif command == "right" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position(self.cursor_row, (self.cursor_column + 1)%8 )
	  return true
    elseif command == "up" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row + 3) % 4, self.cursor_column)
	  return true
    elseif command == "down" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row + 1) % 4, self.cursor_column)
	  return true
    end
	return false
  
  
  elseif self.options_dialog_state == "options_submenu" then
  -- We are in the options_dialog submenu.
    if command == "up" then
      sol.audio.play_sound("cursor")
      self.selector_position = (self.selector_position -1)%4
      return true

    elseif command == "down" then
      sol.audio.play_sound("cursor")
      self.selector_position = (self.selector_position +1)%4
      return true
	
	elseif command == "attack" or command == "action" then
      if self.selector_position == 0 then -- Continue.
	    self.options_dialog_state = "inventory_submenu"
	    self.selector_position = 0
		sol.audio.play_sound("danger")
		return true
	  elseif self.selector_position == 1 then -- Switch character.
	    self.options_dialog_state = "switch_character_submenu"
		self.selector_position = 0
	    return true
	  elseif self.selector_position == 2 then -- Save game.
	    self.options_dialog_state = "save_game_submenu" 
		self.selector_position = 0
	    return true
	  elseif self.selector_position == 3 then -- Exit game.
	  	self.options_dialog_state = "exit_game"
		self.selector_position = 0
	    return true
	  end

	elseif command == "pause" then
      -- Go back from some submenu to the inventory submenu and reset some constants.
  	  self.options_dialog_state = "inventory_submenu"
	  self.selector_position = 0
	  sol.audio.play_sound("danger")
	  return true
    end
	
		
  elseif self.options_dialog_state == "switch_character_submenu" then
    -- We are in the switch_character_dialog submenu.
    if command == "left" then
	  self.selector_position = (self.selector_position - 1)%3
	  sol.audio.play_sound("cursor")
      return true	
	elseif command == "right" then
	  self.selector_position = (self.selector_position + 1)%3
	  sol.audio.play_sound("cursor")
      return true	  
	elseif command == "attack" or command == "action" then
	  self:switch_hero(self.selector_position + 1)
	  -- Change items and counters to display and right color background.
	  self.right_color_index = self:get_hero_index()
	  for k = 1, 32 do self.sprites[k]:set_animation(item_list[self.selector_position + 1][k]) end
	  for k = 1, 32 do self.counters[k] = counter_list[self.selector_position + 1][k] end
	  -- Reset some variables.
	  self.selector_position = 0
      self.options_dialog_state = "inventory_submenu"
      sol.audio.play_sound("message_end")
      -- Change color of submenu titles.
      self.inventory_caption:set_color(self.hero_color_rgb[self:get_hero_index()])
	  self.options_caption:set_color(self.hero_color_rgb[self:get_hero_index()])
	  self.switch_character_menu_caption:set_color(self.hero_color_rgb[self:get_hero_index()])
	  self.swap_items_menu_caption:set_color(self.hero_color_rgb[self:get_hero_index()])
	  --------------------------------------------------------------------- FALTARAN MAS EN EL FUTURO
	  return true
	elseif command == "pause" then
      -- Go back from some submenu to the inventory submenu and reset some constants.
  	  self.options_dialog_state = "inventory_submenu"
	  self.selector_position = 0
	  sol.audio.play_sound("danger")
      return true	  
    end

  elseif self.options_dialog_state == "swap_items_submenu" then
  -- We are in the swap_items_dialog submenu.
    if command == "left" then
	  self.selector_position = (self.selector_position - 1)%3
	  sol.audio.play_sound("cursor")
      return true	
	elseif command == "right" then
	  self.selector_position = (self.selector_position + 1)%3
	  sol.audio.play_sound("cursor")
      return true	  
	elseif command == "attack" or command == "action" then
	  -- Do not allow to swap items with the hero himself.
	  if self.selector_position + 1 == self:get_hero_index() then
	    sol.audio.play_sound("danger")
	    return true
	  end
	  -- Draw items of the secondary character on the left, and restart some variables.
	  for i = 0, 3 do for j = 0, 3 do self.sprites[j+1+i*8]:set_animation(item_list[self.selector_position + 1][j+5+i*8]) end  end
	  for i = 0, 3 do for j = 0, 3 do self.counters[j+1+i*8] = counter_list[self.selector_position + 1][j+5+i*8] end end
	  self.left_color_index = self.selector_position +1
	  self.selector_position = 0
      self.options_dialog_state = "swapping_items"
      sol.audio.play_sound("message_end")	  
	  return true
	  ---------------------------------------------------------- NO HAY QUE DEJAR QUE SE INTERCAMBIE UN ITEM CONSIGO MISMO !!!!!!!!!!!!!! ARREGLAR!
	elseif command == "pause" then
	  -- Go back from some submenu to the inventory submenu and reset some constants.
	  self.options_dialog_state = "inventory_submenu"
	  self.selector_position = 0
	  sol.audio.play_sound("danger")
	  return true
    end
  
  elseif self.options_dialog_state == "save_game_submenu" then
	self.game:save()
	self.options_dialog_state = "inventory_submenu"
	self.selector_position = 0
	sol.audio.play_sound("message_end")
	return true
	--[[-- Start the dialog to save the game.
    self.game:start_dialog("pause.save", function()
	  game:set_paused(false)
	end)]]
  
  elseif self.options_dialog_state == "exit_game" then
    -- PREGUNTAR SI GUARDAR ANTES DE SALIR!!!
    sol.main.exit()
  
  
  -- QUITAR LA OPCION SIGUIENTE!!!!!!!!!!!!
  elseif self.options_dialog_state == "swapping_items" then
  -- We are swapping items in the inventory submenu.
    if command == "left" then
      sol.audio.play_sound("cursor")
	  -- Cases depending on whether there is a selected swapping_item or not.
	  if self.swapping_position ~= nil then
	    self:set_cursor_position(self.cursor_row, (self.cursor_column - 1)%4 + 4 * math.floor(self.cursor_column/4) )
	    return true
	  else
	    self:set_cursor_position(self.cursor_row, (self.cursor_column - 1)%8 )
	    return true
	  end
    elseif command == "right" then
      sol.audio.play_sound("cursor")
	  -- Cases depending on whether there is a selected swapping_item or not.
	  if self.swapping_position ~= nil then
	    self:set_cursor_position(self.cursor_row, (self.cursor_column + 1)%4 + 4 * math.floor(self.cursor_column/4) )
	    return true
	  else
	    self:set_cursor_position(self.cursor_row, (self.cursor_column + 1)%8 )
	    return true
      end		
    elseif command == "up" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row + 3) % 4, self.cursor_column)
	  return true
    elseif command == "down" then
      sol.audio.play_sound("cursor")
      self:set_cursor_position((self.cursor_row + 1) % 4, self.cursor_column)
	  return true
    elseif command == "attack" or command == "action" then
	  if self.swapping_position == nil then
	    -- If we do not have a selected item, select it the swap.
	    self.swapping_position = self:get_selected_index()		
		self:set_cursor_position(math.floor(self.swapping_position/8), ((self.swapping_position%8) + 4)%8 )
		sol.audio.play_sound("message_end")
	  else
	    -- If we already have a selected item, swap the items.
		local second_swapping_position = self:get_selected_index() 
		local second_item_name = item_list[self.left_color_index][second_swapping_position +1]
		local second_item_counter = counter_list[self.left_color_index][second_swapping_position +1]
		local second_item_sprite = self.sprites[second_swapping_position +1]
		local second_item_counter = self.counters[second_swapping_position +1]
		item_list[self.left_color_index][second_swapping_position +5] = item_list[self.right_color_index][self.swapping_position +1]
		counter_list[self.left_color_index][second_swapping_position +5] = counter_list[self.right_color_index][self.swapping_position +1]
		item_list[self.right_color_index][self.swapping_position +1] = second_item_name
		counter_list[self.right_color_index][self.swapping_position +1] = second_item_counter
		self.sprites[second_swapping_position +1] = self.sprites[self.swapping_position +1]
		self.counters[second_swapping_position +1] = self.counters[self.swapping_position +1]
		self.sprites[self.swapping_position +1] = second_item_sprite
		self.counters[self.swapping_position +1] = second_item_counter
	    -- FALTA reproducir animacion de intercambio de items. -------------------------------------------------------------------- !!!!!!!!!!!!!!
		self.swapping_position = nil
		self.options_dialog_state = "swapping_items"
		sol.audio.play_sound("message_end")
      end
    elseif command == "pause" then  
	  if self.swapping_position == nil then
	    -- There is no selected item to swap. Restore background colors, sprite animations and counters on the left.
		-- Go back to "inventory_submenu" state, and reset some variables.
		for i = 0, 3 do for j = 0, 3 do self.sprites[j+1+i*8]:set_animation(item_list[self:get_hero_index()][j+1+i*8]) end  end
		for i = 0, 3 do for j = 0, 3 do self.counters[j+1+i*8] = counter_list[self:get_hero_index()][j+1+i*8] end end  
		self.options_dialog_state = "inventory_submenu"
		self.left_color_index = 4
		sol.audio.play_sound("danger")
		self.swapping_position = nil
		return true 	
	  else 
	    -- There is a selected item to swap. Stay in the "swapping_state" and unselect selected item.
	    sol.audio.play_sound("danger")
	    self.swapping_position = nil
        return true 			
	  end
    end
-----------------------------
  end
  
  return handled
end

function inventory_submenu:on_draw(dst_surface)
 
  self:draw_background(dst_surface)
  self:draw_caption(dst_surface)
    
  -- Draw the left and right inventory color backgrounds on the background_surfaces.
  self.left_inventory_background:set_animation(self.hero_color[self.left_color_index])
  self.right_inventory_background:set_animation(self.hero_color[self.right_color_index])
  self.left_inventory_background:draw(self.background_surfaces, 8, 24)
  self.right_inventory_background:draw(self.background_surfaces, 152, 24)

  -- Draw each inventory item.
  local quest_width, quest_height = dst_surface:get_size()
  local initial_x = 28 + (quest_width - 296) / 2 
  local initial_y = 49 + (quest_height - 192) / 2
  local y = initial_y
  local k = 0

  for i = 0, 3 do
    local x = initial_x
    for j = 0, 7 do
      k = k + 1
	  local item = self.game:get_item(self.sprites[k]:get_animation())
	  if j == 4 then x = x + 16 end 
      self.sprites[k]:draw(dst_surface, x, y)
      if self.counters[k] ~= nil then
        self.counters[k]:draw(dst_surface, x + 8, y)
      end
      x = x + 32
    end
    y = y + 32
  end

  -- Draw the item cursor.
  x = initial_x + 32 * self.cursor_column
  y = initial_y -5 + 32 * self.cursor_row  
  if self.cursor_column > 3 then x = x + 16 end 
  self.cursor_sprite:draw(dst_surface, x, y)
  
  -- Draw the item being assigned if any.
  if self.is_assigning_item then
    self.item_assigned_sprite:draw(dst_surface)
	self.current_item_assigned_sprite:draw(dst_surface)
  end

  -- Draw the options dialog.
  self:draw_options_dialog(dst_surface)
end

-- Shows a message describing the item currently selected.
-- The player is supposed to have this item.
function inventory_submenu:show_info_message()
--[[
  local item_name = item_list[self:get_selected_index() + 1]
  local variant = self.game:get_item(item_name):get_variant()
  local map = self.game:get_map()

  -- Position of the dialog (top or bottom).
  if self.cursor_row >= 2 then
    self.game:set_dialog_position("top")  -- Top of the screen.
  else
    self.game:set_dialog_position("bottom")  -- Bottom of the screen.
  end

  self.game:set_custom_command_effect("action", nil)
  self.game:set_custom_command_effect("attack", nil)
  self.game:start_dialog("_item_description." .. item_name .. "." .. variant, function()
    self.game:set_custom_command_effect("action", "info")
    self.game:set_custom_command_effect("attack", "save")
    self.game:set_dialog_position("auto")  -- Back to automatic position.
  end)
--]]
end

-- Interchanges the selected item with the one of the slot (1 or 2).
-- The operation does not take effect immediately: the item picture is thrown to
-- its destination icon, then the assignment is done. Nothing is done if there is no item.
function inventory_submenu:assign_item(slot)

  -- If another item is being assigned, do nothing.
  if self.is_assigning_item then
	return
  else
    self.is_assigning_item = true
  end

  -- Memorize the slots to interchange.
  self.item_assigned_destination = slot
  self.item_assigned_index = self:get_selected_index()
  local item_name = item_list[self:get_hero_index()][self.item_assigned_index + 1]
  local item = self.game:get_item(item_name)
   
  -- If this item is not assignable, do nothing.
  if not item:is_assignable() then
    self.is_assigning_item = nil
    return
  end
  
  -- Change nil values of slots into "nothing".                 
  local current_item = self.game:get_item_assigned(slot)
  if current_item == nil then 
    current_item = self.game:get_item("nothing")  
    self.game:set_item_assigned(slot, current_item)
  end
  
    -- Take the item and the sprite for the animation.  
  self.item_assigned = item
  self.item_assigned_sprite = sol.sprite.create("entities/items")
  self.item_assigned_sprite:set_animation(item_name)
  self.item_assigned_sprite:set_direction(item:get_variant() - 1)
  local current_item_name = current_item:get_name()
  self.current_item_assigned = current_item
  self.current_item_assigned_sprite = sol.sprite.create("entities/items")
  self.current_item_assigned_sprite:set_animation(current_item_name)
  self.current_item_assigned_sprite:set_direction(current_item:get_variant() - 1)
  
  -- If both positions have "nothing", do nothing.
  if item_name == "nothing" and current_item_name == "nothing" then
    self.is_assigning_item = nil
    return
  end
  
  -- Play the sound.
  sol.audio.play_sound("throw")
  
  -- Compute the movement.                       -------------------------------------------- ARREGLAR MAS TARDE!!!!!!!! (LAS CONSTANTES!)
  local x1 = 60 + 32 * self.cursor_column
  local y1 = 75 + 32 * self.cursor_row
  local x2 = (slot == 1) and 20 or 72
  local y2 = 46
  
   -- Move down the current_item_assigned.
  self.current_item_assigned_sprite:set_animation(current_item:get_name())
  self.current_item_assigned_sprite:set_direction(item:get_variant() - 1)
  self.current_item_assigned_sprite:set_xy(x2, y2)
  local movement2 = sol.movement.create("target")
  movement2:set_target(x1, y1)
  movement2:set_speed(500)
  movement2:start(self.current_item_assigned_sprite  ) --, function()
 
  -- Move up the assigned_item, and ends assigning when this movement finishes.
  self.item_assigned_sprite:set_animation(item_name)
  self.item_assigned_sprite:set_direction(item:get_variant() - 1)
  self.item_assigned_sprite:set_xy(x1, y1)
  local movement = sol.movement.create("target")
  movement:set_target(x2, y2)
  movement:set_speed(500)
  movement:start(self.item_assigned_sprite, function()
    self:finish_assigning_item()
  end)
end


-- Stops assigning the item right now.
-- This function is called when we want to assign the item without waiting for its throwing movement to end,
-- for example when the inventory submenu is being closed.
function inventory_submenu:finish_assigning_item()

  local slot = self.item_assigned_destination
  local current_item = self.game:get_item_assigned(slot)
  local current_item_name = current_item:get_name()
  self.game:set_item_assigned(slot, self.item_assigned)
  local k = self.item_assigned_index + 1
  item_list[self:get_hero_index()][k] = current_item_name
  self.sprites[k]:set_animation(current_item_name)
  -- Change counter in position of the item_assigned.
  if current_item:has_amount() then
    self.counters[k] = sol.text_surface.create{
          horizontal_alignment = "center",
          vertical_alignment = "top",
          text = current_item:get_amount(),
          font = (amount == maximum) and "green_digits" or "white_digits",
    }	
  else
    self.counters[k] = nil
  end
  
  -- Delete some variables, including is_assigning_item (it becomes false).
  if self.item_assigned_sprite ~= nil then
    self.item_assigned_sprite:stop_movement()
  end
  if self.current_item_assigned_sprite ~= nil then
    self.item_assigned_sprite:stop_movement()
  end
  self.item_assigned_sprite = nil
  self.item_assigned = nil
  self.current_item_assigned_sprite = nil
  self.current_item_assigned = nil
  self.is_assigning_item = nil
end

function inventory_submenu:draw_options_dialog(dst_surface)

  if self.options_dialog_state == "options_submenu" then
	-- Draw option submenu.
    local width, height = dst_surface:get_size()
    local x = width / 2
    local y = (height / 4) + 3
    self.options_dialog_surface:draw_region( 0, 0, 176, 160, dst_surface, x - 88, height / 2 - 76)
	self.options_caption:draw(dst_surface, x, y-4)
	self.continue_caption:draw(dst_surface, x, y + 24)
	self.switch_character_caption:draw(dst_surface, x, y + 56)
	self.save_game_caption:draw(dst_surface, x, y + 88)
	self.exit_game_caption:draw(dst_surface, x, y + 120)	
	-- Draw the selection cursor for the options dialog.
	self.selector_sprite:set_animation("select_option")
	self.selector_sprite:draw(dst_surface, 86, 72 + 32*self.selector_position)
	
  elseif self.options_dialog_state == "switch_character_submenu" then
    -- Draw the switch_character submenu, to select character.
	local width, height = dst_surface:get_size()
	local x = width / 2
    local y = height / 2 
	self.switch_character_dialog_surface:draw_region(0, 0, 152, 104, dst_surface, x-76, y/2 )
    self.selector_sprite:set_animation("select_character")
	self.selector_sprite:draw(dst_surface, x -68 + self.selector_position * 48, y -4)
	for k = 1, 3 do 	   
	  if k == self.selector_position+1 and self.sprite_hero[k]:get_animation() == "stopped" then 
	    self.sprite_hero[k]:set_animation("walking") 
	  elseif k ~= self.selector_position+1 and self.sprite_hero[k]:get_animation() == "walking" then 
	    self.sprite_hero[k]:set_animation("stopped") 
	  end
	  self.sprite_hero[k]:draw(dst_surface, x-49 + (k-1) * 48, y + 26)
	end	
    if self.options_dialog_state == "switch_character_submenu" then
	  self.switch_character_menu_caption:draw(dst_surface, x, y - 32)
	elseif self.options_dialog_state == "swap_items_submenu" then
	  self.swap_items_menu_caption:draw(dst_surface, x, y - 32)
	end
	
  elseif self.options_dialog_state == "swap_items_submenu" then
    -- Draw the swap_items submenu, to select character for swapping.
	local width, height = dst_surface:get_size()
	local x = width / 2
    local y = height / 2 
	self.switch_character_dialog_surface:draw_region(0, 0, 152, 104, dst_surface, x-76, y/2 )
    self.selector_sprite:set_animation("select_character")
	self.selector_sprite:draw(dst_surface, x -68 + self.selector_position * 48, y -4)
	for k = 1, 3 do 	   
	  if k == self:get_hero_index() then
	    self.sprite_hero[k]:set_animation("black") 
	  elseif k == self.selector_position+1 and self.sprite_hero[k]:get_animation() ~= "walking" then 
	    self.sprite_hero[k]:set_animation("walking") 
	  elseif k ~= self.selector_position+1 and self.sprite_hero[k]:get_animation() ~= "stopped" then 
	    self.sprite_hero[k]:set_animation("stopped") 
	  end
	  self.sprite_hero[k]:draw(dst_surface, x-49 + (k-1) * 48, y + 26)
	end	
    if self.options_dialog_state == "switch_character_submenu" then
	  self.switch_character_menu_caption:draw(dst_surface, x, y - 32)
	elseif self.options_dialog_state == "swap_items_submenu" then
	  self.swap_items_menu_caption:draw(dst_surface, x, y - 32)
	end	
	
  elseif self.options_dialog_state == "swapping_items" and self.swapping_position ~= nil then
    -- Draw the selector on the swapping item. 
	self.selector_sprite:set_animation("swapping_item")
    local quest_width, quest_height = dst_surface:get_size()
    local x = 14 + (quest_width - 296) / 2 
    local y = 30 + (quest_height - 192) / 2
	if self:get_position_side(self.swapping_position) == 1 then x = x + 144 end
	self.selector_sprite:draw(dst_surface, x + 32*(self.swapping_position%4), y + 32*math.floor(self.swapping_position/8) )
	-- 1. intercambiar objetos en las item_list y counter_list + actualizar las de self.sprites y self.counters
	-- 2. hacerlo todo con movimiento de intercambio (objeto volador)!!!
	
  end
		  
end

function inventory_submenu:switch_hero(hero_index)
--[[
  local hero = self.game:get_hero()  
  if hero_index == 1 then
    hero:set_tunic_sprite_id("npc/cuspis")
  elseif hero_index == 2 then
    hero:set_tunic_sprite_id("npc/robyne")
  elseif hero_index == 3 then
    hero:set_tunic_sprite_id("npc/wizard_blue")
  end
--]]
end 

-- Returns index associated to the current hero.
function inventory_submenu:get_hero_index()
  return self.game:get_hero_manager().current_hero_index  
end 

-- Returns the position of an empty slot in the left or right inventory item, or nil if there is not an empty slot.
-- The parameter side must take the values 0 for the left side and 1 for the right side.
function inventory_submenu:get_empty_position(side)
  local t, pos
  if side == 0 then t = 0
  elseif side == 1 then t = 4
  else return nil end
  
  for i = 0, 3 do
    for j = 0, 3 do
      pos = i*8 + j + 1 + t
	if self.sprites[pos].get_animation() == "empty" then return pos	end
	end
  end

  return nil
end

-- Returns 0 or 1 depending on the side left or right of the cursor. The parameter cursor_position takes values from 0 to 31.
function inventory_submenu:get_position_side(cursor_position)
  if (cursor_position % 8) < 4 then return 0
  else return 1 end
end  
  
  
  
return inventory_submenu
