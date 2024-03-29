--[[
Special characters:
$1, $2 and $3: slow, medium and fast
$0: pause
$v: variable
space: don't add the delay
110xxxx: multibyte character
${surface_name}: change to other surface. This allows to use several colors at the same time. 
                 The original one is "${default}".
$[color] or $[(r,g,b)]: name of a color (red, blue,...) predefined in dialog_box:set_color(color),
                        or RGB coordinates of some color.
--]]  

local game = ...

local dialog_box = {

  -- Dialog box properties.
  dialog = nil,                -- Dialog being displayed or nil.
  first = true,                -- Whether this is the first dialog of a sequence.
  style = nil,                 -- "box", "cutscene" or "empty".
  vertical_position = "auto",  -- "auto", "top" or "bottom".
  skip_mode = nil,             -- "none", "current", "all" or "unchanged".
  icon_index = nil,            -- Index of the 16x16 icon in hud/dialog_icons.png or nil.
  info = nil,                  -- Parameter passed to start_dialog().
  skipped = false,             -- Whether the player skipped the dialog.
  selected_answer = nil,       -- Selected answer (1 or 2) or nil if there is no question.
  animation_sprite = nil,       -- An optional sprite of some character (path: "dialogs/" .. dialog.animation_sprite; animation: dialog.animation).
  
  -- Displaying text gradually.
  next_line = nil,             -- Next line to display or nil.
  line_it = nil,               -- Iterator over of all lines of the dialog.
  lines = {},                  -- Array of the text of the 3 visible lines.
  line_surfaces = {},          -- Array of the 3 text surfaces.
  text_properties = {},        -- Array of properties to create the text surfaces.
  line_index = nil,            -- Line currently being shown.
  char_index = nil,            -- Next character to show in the current line.
  char_delay = nil,            -- Delay between two characters in milliseconds.
  full = false,                -- Whether the 3 visible lines have shown all content.
  need_letter_sound = false,   -- Whether a sound should be played with the next character.
  gradual = true,              -- Whether text is displayed gradually.

  -- Graphics.
  dialog_surface = nil,
  box_img = nil,
  icons_img = nil,
  end_lines_sprite = nil,
  box_dst_position = nil,      -- Destination coordinates of the dialog box.
  question_dst_position = nil, -- Destination coordinates of the question icon.
  icon_dst_position = nil,     -- Destination coordinates of the icon.
  animation_dst_position = nil,     -- Destination coordinates of the dialog talking animation.
}

-- Constants.
local nb_visible_lines = 3     -- Maximum number of lines in the dialog box.
local char_delays = {
  slow = 60,
  medium = 40,
  fast = 20  -- Default.
}
local letter_sound_delay = 100
local box_width = 268
local box_height = 60

-- Initializes the dialog box system.
function game:initialize_dialog_box()

  game.dialog_box = dialog_box

  -- Initialize dialog box data.
  dialog_box.line_surfaces.default = {}
  dialog_box.current_line_surface = dialog_box.line_surfaces.default
  -- Text properties used to initialize surfaces.
  local font, font_size = sol.language.get_dialog_font()
  dialog_box.text_properties = { 
    horizontal_alignment = "left",
    vertical_alignment = "top",
    rendering_mode = "antialiasing",
    font = font,
    font_size = font_size,
  }
  for i = 1, nb_visible_lines do
    dialog_box.lines[i] = ""
    dialog_box.line_surfaces.default[i] = sol.text_surface.create(dialog_box.text_properties)
  end
  
  dialog_box.dialog_surface = sol.surface.create(sol.video.get_quest_size())
  dialog_box.box_img = sol.surface.create("hud/dialog_box.png")
  dialog_box.icons_img = sol.surface.create("hud/dialog_icons.png")
  dialog_box.end_lines_sprite = sol.sprite.create("hud/dialog_box_message_end")
  game:set_dialog_style("box")
end

-- Exits the dialog box system.
function game:quit_dialog_box()

  if dialog_box ~= nil then
    if game:is_dialog_enabled() then
      sol.menu.stop(dialog_box)
    end
    game.dialog_box = nil
  end
end

-- Called by the engine when a dialog starts.
function game:on_dialog_started(dialog, info)

  dialog_box.dialog = dialog
  dialog_box.info = info
  dialog_box:set_color({255,255,255}) -- Reset color text to white.
  dialog_box.animation_sprite = nil
  if dialog.vertical_position then dialog_box.vertical_position = dialog.vertical_position end
  if dialog.animation and dialog.animation_sprite then -- Add animation sprite if necessary.
    dialog_box.animation_sprite = sol.sprite.create("dialogs/" .. dialog.animation_sprite)
    dialog_box.animation_sprite:set_animation(dialog.animation)
  end 
  sol.menu.start(game, dialog_box)
end

-- Called by the engine when a dialog finishes.
function game:on_dialog_finished(dialog)

  sol.menu.stop(dialog_box)
  dialog_box.dialog = nil
  dialog_box.info = nil
  dialog_box.animation_sprite = nil
  -- Delete the new surfaces and restore the default one.
  for k, _ in pairs(dialog_box.line_surfaces) do
    if k ~= "default" then dialog_box.line_surfaces[k] = nil end
  end
  dialog_box.current_line_surface = dialog_box.line_surfaces.default
  -- Call a custom function (it can be created on the game manager).
  if game.on_custom_dialog_finished then game:on_custom_dialog_finished() end 
end

-- Sets the style of the dialog box for subsequent dialogs.
-- style must be one of:
-- - "box" (default): Usual dialog box.
-- - "empty": No decoration.
function game:set_dialog_style(style)

  dialog_box.style = style
  
  if style == "box" then
    -- Make the dialog box slightly transparent.
    dialog_box.dialog_surface:set_opacity(230)
  end
end

-- Sets the vertical position of the dialog box for subsequent dialogs.
-- vertical_position must be one of:
-- - "auto" (default): Choose automatically so that the hero is not hidden.
-- - "top": Top of the screen.
-- - "bottom": Bottom of the screen.
function game:set_dialog_position(vertical_position)
  dialog_box.vertical_position = vertical_position
end

local function repeat_show_character()

  dialog_box:check_full()
  while not dialog_box:is_full()
      and dialog_box.char_index > #dialog_box.lines[dialog_box.line_index] do
    -- The current line is finished.
    dialog_box.char_index = 1
    dialog_box.line_index = dialog_box.line_index + 1
    dialog_box:check_full()
  end

  if not dialog_box:is_full() then
    dialog_box:add_character()
  else
    sol.audio.play_sound("message_end")
    if dialog_box:has_more_lines()
        or dialog_box.dialog.next ~= nil
        or dialog_box.selected_answer ~= nil then
      dialog_box.end_lines_sprite:set_animation("next")
      game:set_custom_command_effect("action", "next")
    else
      dialog_box.end_lines_sprite:set_animation("last")
      game:set_custom_command_effect("action", "return")
      -- Stop talking animation, if needed.
      if dialog_box.animation_sprite then 
        if dialog_box.animation_sprite:has_animation("stopped") then
          dialog_box.animation_sprite:set_animation("stopped")
        end 
      end
    end
    game:set_custom_command_effect("attack", nil)
  end
end

-- The first dialog of a sequence starts.
function dialog_box:on_started()

  -- Set the initial properties.
  -- Subsequent dialogs in the same sequence do not reset them.
  self.icon_index = nil
  self.skip_mode = "none"
  self.char_delay = char_delays["fast"]
  self.selected_answer = nil
  self.animation_sprite = nil
  
  -- Determine the position of the dialog box on the screen.
  local map = game:get_map()
  local camera_x, camera_y, camera_width, camera_height = map:get_camera_position()
  local top = false
  if self.vertical_position == "top" then
    top = true
  elseif self.vertical_position == "auto" then
    local hero_x, hero_y = map:get_entity("hero"):get_position()
    if hero_y >= camera_y + (camera_height / 2 + 10) then
      top = true
    end
  end

  -- Set the coordinates of graphic objects.
  local x = camera_width / 2 - 134
  local y = top and 32 or (camera_height - 96)

  if self.style == "empty" or self.style == "cutscene" then
    y = y + (top and -24 or 24)
  end

  self.box_dst_position = { x = x, y = y }
  self.question_dst_position = { x = x + 18, y = y + 27 }
  self.icon_dst_position = { x = x + 18, y = y + 22 }
  self.animation_dst_position = { x = x + 30, y = y + 30 }
  
  self:show_dialog()
end

-- The dialog box is being closed.
function dialog_box:on_finished()  
  -- Remove overriden command effects.
  game:set_custom_command_effect("action", nil)
  game:set_custom_command_effect("attack", nil)
end

-- A dialog starts (not necessarily the first one of its sequence).
function dialog_box:show_dialog()

  -- Initialize this dialog.
  local dialog = self.dialog

  local text = dialog.text
  if dialog_box.info ~= nil then
    -- There is a "$v" sequence to substitute.
    text = text:gsub("%$v", dialog_box.info)
  end
  -- Split the text in lines.
  text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
  self.line_it = text:gmatch("([^\n]*)\n")  -- Each line including empty ones.

  self.next_line = self.line_it()
  self.line_index = 1
  self.char_index = 1
  self.skipped = false
  self.full = false
  self.need_letter_sound = self.style ~= "empty"

  if dialog.skip ~= nil then
    -- The skip mode changes for this dialog.
    self.skip_mode = dialog.skip
  end

  if dialog.icon ~= nil then
    -- The icon changes for this dialog ("-1" means none).
    if dialog.icon == "-1" then
      self.icon_index = nil
    else
      self.icon_index = dialog.icon
    end
  end
  
  if dialog.animation and dialog.animation_sprite then -- Add animation sprite if necessary.
    self.animation_sprite = sol.sprite.create("dialogs/" .. dialog.animation_sprite)
    self.animation_sprite:set_animation(dialog.animation)
  end 

  if dialog.question == "1" then
    -- This dialog is a question.
    self.selected_answer = 1  -- The answer will be 1 or 2.
  end

  -- Start displaying text.
  self:show_more_lines()
end

-- Returns whether there are more lines remaining to display after the current
-- 3 lines.
function dialog_box:has_more_lines()
  return self.next_line ~= nil
end

-- Updates the result of is_full().
function dialog_box:check_full()
  if self.line_index >= nb_visible_lines
      and self.char_index > #self.lines[nb_visible_lines] then
    self.full = true
  else
    self.full = false
  end
end

-- Returns whether all 3 current lines of the dialog box are entirely
-- displayed.
function dialog_box:is_full()
  return self.full
end

-- Shows the next dialog of the sequence.
-- Closes the dialog box if there is no next dialog.
function dialog_box:show_next_dialog()

  local next_dialog_id
  if self.selected_answer ~= 2 then
    -- No question or first answer
    next_dialog_id = self.dialog.next
  else
    -- Second answer.
    next_dialog_id = self.dialog.next2
  end

  if next_dialog_id ~= nil and next_dialog_id ~= "_unknown" then
    -- Show the next dialog.
    self.first = false
    self.selected_answer = nil
    self.dialog = sol.language.get_dialog(next_dialog_id)
    self:show_dialog()
  else
    -- Finish the dialog, returning the answer or nil if there was no question.
    local status = self.selected_answer

    -- Conform to the built-in handling of shop items.
    if self.dialog.id == "_shop.question" then
      -- The engine expects a boolean answer after the "do you want to buy"
      -- shop item dialog.
      status = self.selected_answer == 1
    end

    game:stop_dialog(status)
  end
end

-- Starts showing a new group of 3 lines in the dialog.
-- Shows the next dialog (if any) if there are no remaining lines.
function dialog_box:show_more_lines()

  self.gradual = true
    
  if not self:has_more_lines() then
    self:show_next_dialog()
    return
  end

  -- Hide the action icon and change the sword icon.
  game:set_custom_command_effect("action", nil)
  if self.skip_mode ~= "none" then
    game:set_custom_command_effect("attack", "skip")
    game:set_custom_command_effect("action", "next")
  else
    game:set_custom_command_effect("attack", nil)
  end

  -- Prepare the 3 lines.
  for i = 1, nb_visible_lines do
    for _, line_surface in pairs(self.line_surfaces) do line_surface[i]:set_text("") end
	if self:has_more_lines() then
      self.lines[i] = self.next_line
      self.next_line = self.line_it()
    else
      self.lines[i] = ""
    end
  end
  self.line_index = 1
  self.char_index = 1

  if self.gradual then
    sol.timer.start(self, self.char_delay, repeat_show_character)
  end
end

-- Adds the next character to the dialog box.
-- If this is a special character (like $0, $v, etc.),
-- the corresponding action is performed.
function dialog_box:add_character()

  local line = self.lines[self.line_index]
  local current_char = line:sub(self.char_index, self.char_index)
  if current_char == "" then
    error("No remaining character to add on this line")
  end
  self.char_index = self.char_index + 1
  local additional_delay = 0
  local text_surface = self.current_line_surface[self.line_index]

  -- Special characters:
  -- - $1, $2 and $3: slow, medium and fast
  -- - $0: pause
  -- - $v: variable
  -- - space: don't add the delay
  -- - 110xxxx: multibyte character
  -- - $[color] or $[(r,g,b)]: name of a color (red, blue,...) predefined in dialog_box:set_color(color), or RGB coordinates of some color.
  -- - ${surface_name}: change to other surface. This allows to use several colors at the same time. The original one is "${default}".
  
  local special = false
  if current_char == "$" then
    -- Special character.

    special = true
    current_char = line:sub(self.char_index, self.char_index)
    self.char_index = self.char_index + 1

    if current_char == "0" then
      -- Pause.
      additional_delay = 1000

    elseif current_char == "1" then
      -- Slow.
      self.char_delay = char_delays["slow"]

    elseif current_char == "2" then
      -- Medium.
      self.char_delay = char_delays["medium"]

    elseif current_char == "3" then
      -- Fast.
      self.char_delay = char_delays["fast"]
	
    elseif  current_char == "[" then
	  -- Predefined color.
	  local next_char = line:sub(self.char_index, self.char_index)
	  if next_char == "(" then
	    -- The syntax is "$[(r,g,b)]". 
	    local right_position = line:find (")]", self.char_index, true)
	    local r,g,b = line:sub(self.char_index, right_position-1):match("%s*(%d+)%s*%,%s*(%d+)%s*%,%s*(%d+)%s*")
	    local color = {r,g,b}
	    self.char_index = right_position +2
	    self:set_color(color)
	  else
	    -- The syntax is "$[color]".
	    local right_position = line:find ("]", self.char_index, true)
	    local color = line:sub(self.char_index, right_position-1)
	    self.char_index = right_position +1
        self:set_color(color)
	  end

	elseif  current_char == "{" then
	  -- Change to other text surface. The syntax is "${surface_name}".
	  -- Get the name of the surface.
	  local right_position = line:find ("}", self.char_index, true)
	  local name = line:sub(self.char_index, right_position-1)
      self.char_index = right_position +1
	  -- Create the new surface if it does not exist.
	  if not self.line_surfaces[name] then
	    self.line_surfaces[name] = {}
	    for i = 1, nb_visible_lines do
		  self.line_surfaces[name][i] = sol.text_surface.create(dialog_box.text_properties)
        end
	  end
	  -- Fill with spaces in the current line of the new surface until the current position. 
	  local current_line = self.current_line_surface[self.line_index]
	  local new_line = self.line_surfaces[name][self.line_index]
	  local nb_spaces = #current_line:get_text() - #new_line:get_text()
	  if nb_spaces > 0 then
	    for i = 1, nb_spaces do new_line:set_text(new_line:get_text() .. " ") end
	  end
	  -- Change the current surface to the new surface.
	  self.current_line_surface = self.line_surfaces[name]
	 
    else
      -- Not a special char, actually.
      text_surface:set_text(text_surface:get_text() .. "$")
      special = false
    end
  end

  if not special then
    -- Normal character to be displayed.
    text_surface:set_text(text_surface:get_text() .. current_char)

    -- If this is a multibyte character, also add the next byte.
    local byte = current_char:byte()
    if byte >= 192 and byte < 224 then
      -- The first byte is 110xxxxx: the character is stored with
      -- two bytes (utf-8).
      current_char = line:sub(self.char_index, self.char_index)
      self.char_index = self.char_index + 1
      text_surface:set_text(text_surface:get_text() .. current_char)
    end

    if current_char == " " then
      -- Remove the delay for whitespace characters.
      additional_delay = -self.char_delay
    end
  end
   
  if not special and current_char ~= nil and self.need_letter_sound then
    -- Play a letter sound sometimes.
    sol.audio.play_sound("message_letter")
    self.need_letter_sound = false
    sol.timer.start(self, letter_sound_delay, function()
      self.need_letter_sound = true
    end)
  end

  if self.gradual then
    sol.timer.start(self, self.char_delay + additional_delay, repeat_show_character)
  end
end

-- Stops displaying gradually the current 3 lines, shows them immediately.
-- If the 3 lines were already finished, the next group of 3 lines starts
-- (if any).
function dialog_box:show_all_now()

  if self:is_full() then
    self:show_more_lines()
  else
    self.gradual = false
    -- Check the end of the current line.
    self:check_full()
    while not self:is_full() do

      while not self:is_full()
          and self.char_index > #self.lines[self.line_index] do
        self.char_index = 1
        self.line_index = self.line_index + 1
        self:check_full()
      end

      if not self:is_full() then
        self:add_character()
      end
      self:check_full()
    end
  end
end

function dialog_box:on_command_pressed(command)

  if command == "action" then

    -- Display more lines.
    if self:is_full() then
      self:show_more_lines()
    elseif self.skip_mode ~= "none" then
      self:show_all_now()
    end

  elseif command == "attack" then

    -- Attempt to skip the dialog.
    if self.skip_mode == "all" then
      self.skipped = true
      game:stop_dialog("skipped")
    elseif self:is_full() then
      self:show_more_lines()
    elseif self.skip_mode == "current" then
      self:show_all_now()
    end

  elseif command == "up" or command == "down" then

    if self.selected_answer ~= nil
        and not self:has_more_lines()
        and self:is_full() then
      sol.audio.play_sound("cursor")
      self.selected_answer = 3 - self.selected_answer  -- Switch between 1 and 2.
      self.question_dst_position.y = self.box_dst_position.y +
          (self.selected_answer == 1 and 27 or 40)
    end
  end

  -- Don't propagate the event to anything below the dialog box.
  return true
end

function dialog_box:on_draw(dst_surface)

  local x, y = self.box_dst_position.x, self.box_dst_position.y
  self.dialog_surface:clear()
  
  if self.style == "empty" then
    -- Draw a dark rectangle.
    dst_surface:fill_color({0, 0, 0}, x, y, 220, 60)
  else
    -- Draw the dialog box.
    self.box_img:draw_region(0, 0, box_width, box_height, self.dialog_surface, x, y)
  end

  -- Draw the text.
  local text_x
  if self.animation_sprite == nil then
    text_x = x + (self.icon_index == nil and 16 or 48)
  else
    text_x = x + 48 + 16
  end
  local text_y = y - 4
  for i = 1, nb_visible_lines do
    text_y = text_y + 13
    if self.selected_answer ~= nil
        and i == nb_visible_lines - 1
        and not self:has_more_lines() then
      -- The last two lines are the answer to a question.
      text_x = text_x + 24
    end
	for _, surface in pairs(self.line_surfaces) do
      surface[i]:draw(self.dialog_surface, text_x, text_y)
    end
  end

  -- Draw the icon.
  if self.icon_index ~= nil then
    local row, column = math.floor(self.icon_index / 10), self.icon_index % 10
    self.icons_img:draw_region(16 * column, 16 * row, 16, 16,
        self.dialog_surface,
        self.icon_dst_position.x, self.icon_dst_position.y)
    self.question_dst_position.x = x + 50
  elseif self.animation_sprite ~= nil then
    self.question_dst_position.x = x + 64
  else
    self.question_dst_position.x = x + 18
  end
  
  -- Draw the animation.
  if self.animation_sprite ~= nil then
    self.animation_sprite:draw(self.dialog_surface, self.animation_dst_position.x, self.animation_dst_position.y)
  end

  -- Draw the question arrow.
  if self.selected_answer ~= nil
      and self:is_full()
      and not self:has_more_lines() then
    self.box_img:draw_region(96, 60, 16, 12, self.dialog_surface,
        self.question_dst_position.x, self.question_dst_position.y)
  end

  -- Draw the end message arrow.
  if self:is_full() then
    self.end_lines_sprite:draw(self.dialog_surface, x + 126, y + 56)
  end

  -- Final blit.
  self.dialog_surface:draw(dst_surface)
end

-- Change color of the text. The parameter color may be a list with the rgb values of the color, or a predefined string.
function dialog_box:set_color(color)
  if type(color) == "string" then
    if color == "white" then color = {255,255,255}
    elseif color == "red" then color = {255,0,0}
    elseif color == "green" then color = {0,255,0}
    elseif color == "blue" then color = {50,200,255}
    elseif color == "yellow" then color = {200,200,0}
    elseif color == "pink" then color = {255,0,150}
    else error("Predefined color not found in dialog: " .. dialog_box.dialog.id)
	end
  end
  -- Change color.
  for i = 1, nb_visible_lines do self.current_line_surface[i]:set_color(color) end
end
	  