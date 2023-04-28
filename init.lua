--[[

The MIT License (MIT)
Copyright (C) 2023 Acronymmk

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

]]

local mod_storage = minetest.get_mod_storage()

local saved_messages = mod_storage:get_string("saved_messages")
local message_list = {}
for line in saved_messages:gmatch("[^\n]+") do
  table.insert(message_list, line)
end

local function register_message(message)
  message = message:gsub("%[", "("):gsub("%]", ")"):gsub("%.", ",")
  table.insert(message_list, "# "..os.date("%Y-%m-%d %H:%M:%S").." | " .. message)
  if #message_list > 500 then
    table.remove(message_list, 1)
  end
end

minetest.register_on_shutdown(function()
  local saved_messages = table.concat(message_list, "\n")
  mod_storage:set_string("saved_messages", saved_messages)
end)

minetest.register_on_chat_message(function(player_name, message)
  register_message(player_name..": "..message)
end)

minetest.register_on_joinplayer(function(player)
  local player_name = player:get_player_name()
  register_message("*** Server: "..player_name.." joined the game")
end)

minetest.register_on_leaveplayer(function(player)
  local player_name = player:get_player_name()
  register_message("*** Server: "..player_name.." left the game")
end)

minetest.register_on_shutdown(function()
  register_message("*** Server shutting down!")
end)

minetest.after(1, function()
  register_message("*** Server started!")
end)

minetest.register_chatcommand("chatlog", {
  description = "Show the last 500 registered messages",
  func = function(player_name)
    local formspec = "size[10,10]"
    formspec = formspec .. "label[0,0;" .. "# "..minetest.colorize("orange", "CHAT LOGGER").." | Last 500 messages..." .. "]"
    formspec = formspec .. "box[-0.1,-0.1;10,0.7;black]"
    formspec = formspec .. "box[-0.1,0.7;10,8.55;#030303]"
    formspec = formspec .. "textarea[0.2,0.7;10.2,10;;;" .. table.concat(message_list, "\n") .. "]"
    formspec = formspec .. "field[0.2,9.7;3,1;search;;]"
    formspec = formspec .. "button[2.85,9.34;2,1.1;search_button;Search]"

    minetest.show_formspec(player_name, "last_messages", formspec)
  end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname == "last_messages" or formname == "search_results" then
    if fields.search then
      local keyword = fields.search:lower()
      local message_list_filtered = {}
      for _, line in ipairs(message_list) do
        if line:lower():find(keyword) then
          table.insert(message_list_filtered, line)
        end
      end
      local formspec = "size[10,10]"
      formspec = formspec .. "label[0,0;" .. "# "..minetest.colorize("orange", "CHAT LOGGER").." | Search results for '" .. keyword .. "':" .. "]"
      formspec = formspec .. "box[-0.1,-0.1;10,0.7;black]"
      formspec = formspec .. "box[-0.1,0.7;10,8.55;#030303]"
      formspec = formspec .. "textarea[0.2,0.7;10.2,10;;;" .. table.concat(message_list_filtered, "\n") .. "]"
      formspec = formspec .. "field[0.2,9.7;3,1;search;;]"
      formspec = formspec .. "button[2.85,9.34;2,1.1;search_button;Search]"
      minetest.show_formspec(player:get_player_name(), "search_results", formspec)
      return true
    end
  end
end)
