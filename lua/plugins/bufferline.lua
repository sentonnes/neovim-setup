return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      -- Increase how much horizontal space each tab is allowed so full
      -- filenames aren't cut off with an ellipsis.
      max_name_length = 30,
      tab_size = 24,
      truncate_names = false, -- don't truncate tab names at all

      -- Hide the 'x' close icon on each tab
      show_buffer_close_icons = false,
      show_close_icon = false,

      -- Colorize filetype icons
      color_icons = true,

      -- Keep the bufferline visible even with only one buffer open
      always_show_bufferline = true,

      -- Disable all mouse click behaviour on tabs
      close_command = false,
      right_mouse_command = false,
      left_mouse_command = false,
      middle_mouse_command = false,
    },
  },
}
