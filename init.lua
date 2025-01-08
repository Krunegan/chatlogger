--[[

The MIT License (MIT)
Copyright (C) 2025 Flay Krunegan

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
local number_of_messages = tonumber(minetest.settings:get("chatlogger.number_of_messages")) or 100
local datetime_format = minetest.settings:get("chatlogger.datetime_format") or "%Y-%m-%d %H:%M:%S"
local message_id = tonumber(mod_storage:get_string("message_id")) or 0

local function get_formspec(message_list)
  local formspec = {
    "size[10,10]",
    "label[0,0;" .. "# " .. minetest.colorize("orange", "CHAT LOGGER") .. " | Last " .. number_of_messages .. " messages...]",
    "box[-0.1,-0.1;10,0.7;black]",
    "box[-0.1,0.7;10,8.55;#030303]",
    "textarea[0.2,0.7;10.2,10;;;" .. minetest.formspec_escape(table.concat(message_list, "\n")) .. "]",
    "field[0.2,9.7;3,1;search;;]",
    "button[2.85,9.34;2,1.1;search_button;Search]"
  }
  return table.concat(formspec)
end

local saved_messages = mod_storage:get_string("saved_messages")
local message_list = {}
for line in saved_messages:gmatch("[^\n]+") do
  table.insert(message_list, line)
end

local function save_messages()
  local saved_messages = table.concat(message_list, "\n")
  mod_storage:set_string("saved_messages", saved_messages)
  mod_storage:set_string("message_id", tostring(message_id))
end

local function register_message(message)
  message_id = message_id + 1
  message = message:gsub("%[", "("):gsub("%]", ")"):gsub("%.", ",")
  table.insert(message_list, "# "..message_id.." | "..os.date(datetime_format).." | " .. message)
  if #message_list > number_of_messages then
    table.remove(message_list, 1)
  end
  save_messages()
end

minetest.register_on_shutdown(function()
  register_message("*** Server shutting down!")
  save_messages()
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

minetest.after(1, function()
  register_message("*** Server started!")
end)

minetest.register_privilege("chatlogs", {
  description = "Access to chat logs",
  give_to_singleplayer = false,
})

minetest.register_chatcommand("chatlog", {
  description = "Show the last "..number_of_messages.." registered messages",
  func = function(player_name)
    local formspec = get_formspec(message_list)
    minetest.show_formspec(player_name, "last_messages", formspec)
  end,
})

minetest.register_chatcommand("logdel", {
  description = "Delete a message from the log by ID",
  privs = {chatlogs = true},
  params = "<id>",
  func = function(player_name, param)
    local id_to_delete = tonumber(param)
    if not id_to_delete then
      return false, "Invalid ID"
    end
    for i, line in ipairs(message_list) do
      if line:match("^# "..id_to_delete.." |") then
        local original_date = line:match("| (.-) |")
        message_list[i] = "# "..id_to_delete.." | "..original_date.." | this message was deleted at "..os.date(datetime_format)
        save_messages()
        return true, "Message deleted"
      end
    end
    return false, "Message ID not found"
  end,
})

minetest.register_chatcommand("logexport", {
  description = "Export the chat log to a file",
  privs = {chatlogs = true},
  func = function(player_name)
    local file_path = minetest.get_worldpath() .. "/chatlog.txt"
    local file = io.open(file_path, "w")
    if file then
      file:write(table.concat(message_list, "\n"))
      file:close()
      return true, "Chat log exported to " .. file_path
    else
      return false, "Failed to export chat log"
    end
  end,
})

minetest.register_chatcommand("logclear", {
  description = "Clear the chat log",
  privs = {chatlogs = true},
  func = function(player_name)
    message_list = {}
    save_messages()
    return true, "Chat log cleared"
  end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
  if formname == "last_messages" or formname == "search_results" then
    if fields.search then
      local keyword = fields.search:lower()
      local message_list_filtered = {}
      for _, line in ipairs(message_list) do
        if line:lower():find(keyword, 1, true) then
          table.insert(message_list_filtered, line)
        end
      end      
      local formspec = get_formspec(message_list_filtered)
      minetest.show_formspec(player:get_player_name(), "search_results", formspec)
      return true
    end
  end
end)
local mod_storage = minetest.get_mod_storage()
local number_of_messages = tonumber(minetest.settings:get("chatlogger.number_of_messages")) or 100
local needs_priv = minetest.settings:get_bool("chatlogger.needs_priv") or true
local datetime_format = minetest.settings:get("chatlogger.datetime_format") or "%Y-%m-%d %H:%M:%S"

local function get_formspec(message_list)
  local formspec = {
    "size[10,10]",
    "label[0,0;" .. "# " .. minetest.colorize("orange", "CHAT LOGGER") .. " | Last " .. number_of_messages .. " messages...]",
    "box[-0.1,-0.1;10,0.7;black]",
    "box[-0.1,0.7;10,8.55;#030303]",
    "textarea[0.2,0.7;10.2,10;;;" .. minetest.formspec_escape(table.concat(message_list, "\n")) .. "]",
    "field[0.2,9.7;3,1;search;;]",
    "button[2.85,9.34;2,1.1;search_button;Search]"
  }
  return table.concat(formspec)
end

local saved_messages = mod_storage:get_string("saved_messages")
local message_list = {}
for line in saved_messages:gmatch("[^\n]+") do
  table.insert(message_list, line)
end

local function register_message(message)
  message = message:gsub("%[", "("):gsub("%]", ")"):gsub("%.", ",")
  table.insert(message_list, "# "..os.date(datetime_format).." | " .. message)
  if #message_list > number_of_messages then
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

minetest.register_privilege("chatlogs", {
  description = "Access to chat logs",
  give_to_singleplayer = false,
})

minetest.register_chatcommand("chatlog", {
  description = "Show the last "..number_of_messages.." registered messages",
  privs = needs_priv and {chatlogs = true} or {},
  func = function(player_name)
    local formspec = get_formspec(message_list)
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
      local formspec = get_formspec(message_list_filtered)
      minetest.show_formspec(player:get_player_name(), "search_results", formspec)
      return true
    end
  end
end)
