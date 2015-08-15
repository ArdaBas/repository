-- Base class of each submenu.

local submenu_class = {}

function submenu_class:new(game)
  local o = { game = game }
  setmetatable(o, self)
  self.__index = self
  return o
end

function submenu_class:on_started()

  self.background_surfaces = sol.surface.create("inventory_menu.png", true)
  self.background_surfaces:set_opacity(216)
  self.options_dialog_surface = sol.surface.create("menus/options_dialog.png")
  self.options_dialog_state = "inventory_submenu"

  --self.game:set_custom_command_effect("action", nil)
  --self.game:set_custom_command_effect("attack", "save")
end

-- Sets the caption text.
-- The caption text can have one or two lines, with 20 characters maximum for each line.
-- If the text you want to display has two lines, use the '$' character to separate them.
-- A value of nil removes the previous caption if any.
function submenu_class:set_caption(text_key)
  --[[
  if text_key == nil then
    self.caption_text_1:set_text(nil)
    self.caption_text_2:set_text(nil)
  else
    local text = sol.language.get_string(text_key)
    local line1, line2 = text:match("([^$]+)%$(.*)")
    if line1 == nil then
      -- Only one line.
      self.caption_text_1:set_text(text)
      self.caption_text_2:set_text(nil)
    else
      -- Two lines.
      self.caption_text_1:set_text(line1)
      self.caption_text_2:set_text(line2)
    end
  end
  --]]
end

-- Draw the caption text previously set.
function submenu_class:draw_caption(dst_surface)
--[[
  local width, height = dst_surface:get_size()

  if self.caption_text_2:get_text():len() == 0 then
    self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 89)
  else
    self.caption_text_1:draw(dst_surface, width / 2, height / 2 + 83)
    self.caption_text_2:draw(dst_surface, width / 2, height / 2 + 95)
  end
  --]]
end

function submenu_class:next_submenu()

  sol.audio.play_sound("pause_closed")
  sol.menu.stop(self)
  local submenus = self.game.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
  submenu_index = (submenu_index % #submenus) + 1
  self.game:set_value("pause_last_submenu", submenu_index)
  sol.menu.start(self.game, submenus[submenu_index], false)
end

function submenu_class:previous_submenu()

  sol.audio.play_sound("pause_closed")
  sol.menu.stop(self)
  local submenus = self.game.pause_submenus
  local submenu_index = self.game:get_value("pause_last_submenu")
  submenu_index = (submenu_index - 2) % #submenus + 1
  self.game:set_value("pause_last_submenu", submenu_index)
  sol.menu.start(self.game, submenus[submenu_index], false)
end


-- The different options dialogs of the menus share this function.
function submenu_class:on_command_pressed(command)

  local handled = false

  if self.game:is_dialog_enabled() then
    -- Commands will be applied to the dialog box only.
    return false
  end
  
  if self.options_dialog_state == "inventory_submenu" then
    if command == "pause" then
    -- Stop the submenu and unpause the game.
    sol.menu.stop(self)
    self.game:set_paused(false)
	return true
    --
    elseif command == "attack" then
	-- Enable the options_dialog submenu and the select_cursor.
      sol.audio.play_sound("message_end")
      self.options_dialog_state = "options_submenu"
	  return true
    --[[  
      self.action_command_effect_saved = self.game:get_custom_command_effect("action")
      self.game:set_custom_command_effect("action", "validate")
      self.attack_command_effect_saved = self.game:get_custom_command_effect("attack")
      self.game:set_custom_command_effect("attack", "validate")
	]]--  
    end
  else
  -- The save popup is visible.
  --handled = true  -- Block all commands on the submenu.
--[[
    if command == "left" or command == "right" then
      -- Move the cursor.
      sol.audio.play_sound("cursor")
      if self.options_dialog_choice == 0 then
        self.options_dialog_choice = 1
        self.options_dialog_surface:set_animation("right")
      else
        self.options_dialog_choice = 0
        self.options_dialog_surface:set_animation("left")
      end
    elseif command == "action" or command == "attack" then
      -- Validate a choice.
      if self.options_dialog_state == 1 then
        -- After "Do you want to save?".
        self.options_dialog_state = 2
        if self.options_dialog_choice == 0 then
          self.game:save()
          sol.audio.play_sound("piece_of_heart")
        else
          sol.audio.play_sound("danger")
        end
        self.question_text_1:set_text_key("save_dialog.continue_question_0")
        self.question_text_2:set_text_key("save_dialog.continue_question_1")
        self.options_dialog_choice = 0
        self.options_dialog_surface:set_animation("left")
      else
        -- After "Do you want to continue?".
        sol.audio.play_sound("danger")
        self.options_dialog_state = 0
        self.game:set_custom_command_effect("action", self.action_command_effect_saved)
        self.game:set_custom_command_effect("attack", self.attack_command_effect_saved)
        if self.options_dialog_choice == 1 then
          sol.main.reset()
        end
      end
    end 
	--]]
  end

  return handled
end

function submenu_class:draw_background(dst_surface)

  local submenu_index = self.game:get_value("pause_last_submenu")
  local width, height = dst_surface:get_size()
  self.background_surfaces:draw_region(
      320 * (submenu_index - 1), 0, 320, 240,
      dst_surface, (width - 296) / 2, (height - 192) / 2)   
  -- Draw captions of the background.	  
  self.inventory_caption:draw(dst_surface, 160, 36)
end



return submenu_class
