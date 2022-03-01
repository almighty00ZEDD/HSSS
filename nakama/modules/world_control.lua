local world_control  =  {}

local nakama = require("nakama")

local  nb_players  =  0
local active_round = false
local active_players = 0

--changes the label when needed so the filter ine the matchmaker can avoid mistakes
--this script controls both private and public so this is a way to stay in context
local original_labe = nil
local full_match = "full"
-- Custom operation codes. Nakama specific codes are <= 0.
local OpCodes = {

    PREVIOUS_PRESENCES = 1,
	  NEW_PRESENCE = 2,
    READY_PRESENCE = 3,
    START_ROUND = 4,
    UPDATE_POSITION = 5,
    TRANSFORMATION = 6,
    SHOOT = 7,
    DEATH  = 8,
    DECLARE_WINNER = 9,
    ALL_OTHERS_LEFT = 10,
}


function world_control.match_init(context  ,params)
  local state  = {
    presences  =  {},
    nicknames  =  {},
    victories  = {},
    game_states = {},
    colors =   {},
    positions = {},
    dead =  {},
  }
  local tick_rate =  10
  local label =  params.type
  original_label = label
  return state,  tick_rate, label
end

function world_control.match_join_attempt(context ,dispatcher, tick, state, presence, metadata)

  if state.presences[presence.user_id] ~= nil then
    return state, false,  "user  already logged in!"
  end

  if nb_players ==  3  then
    label =  full_match
  end

  if nb_players ==  4  then
    return  state, false,  "the match is currently full !"
  end

  return state, true
end

function  world_control.match_join(context ,dispatcher, tick, state, presences)
  for _,presence in ipairs(presences)  do
    state.presences[presence.user_id]  =  presence

    state.positions[presence.user_id] = {
            ["x"] = 0,
            ["y"] = 0
        }
  end

  nb_players = nb_players + 1

  return state
end

function  world_control.match_leave(context ,dispatcher, tick, state, presences)
  for _,presence in ipairs(presences)  do

    label  =  original_label

    --can't play alone
    if (state.game_states[presence.user_id] == "plays") and (active_players  ==  2) then
      back_to_lobby(state,"connected")
      clear_round_data(state)
      dispatcher.broadcast_message(OpCodes.ALL_OTHERS_LEFT,nil)

    --a player left but there's others
    elseif (state.game_states[presence.user_id] == "plays") and (active_players > 2) then
      active_players = active_players - 1
    end

    state.colors[presence.user_id]  = nil
    state.victories[presence.user_id]  = nil
    state.game_states[presence.user_id] = nil
    state.nicknames[presence.user_id] = nil
    state.presences[presence.user_id]  =  nil
    state.positions[presence.user_id]  =  nil
    state.dead[presence.user_id]  =  nil
  end

  nb_players = nb_players - 1

  return state
end

function world_control.match_loop(context,  dispatcher, tick, state,  messages)

  for _, message in ipairs(messages) do
        local op_code = message.op_code
        local decoded = nakama.json_decode(message.data)

        if op_code == OpCodes.PREVIOUS_PRESENCES then
            local encoded = encode_previous_presences(state)
            dispatcher.broadcast_message(OpCodes.PREVIOUS_PRESENCES, encoded, {message.sender})
        end

        if op_code == OpCodes.NEW_PRESENCE then
          local encoded  = encode_new_presence(state,decoded)
          dispatcher.broadcast_message(OpCodes.NEW_PRESENCE,encoded)
        end

        if op_code == OpCodes.UPDATE_POSITION then
          update_position(state,decoded)
        end

        if op_code == OpCodes.DEATH then
          active_players =  active_players - 1
          state.dead[decoded.id] = 1

          if active_players == 1 then

            local winner_id

            for k,_ in pairs(state.presences) do
              if (state.game_states[k] == "plays") and (state.dead[k]  ==  nil) then
                state.victories[k] = state.victories[k]  + 1
                winner_id = k
              end
            end

            back_to_lobby(state,"connected")
            clear_round_data(state)

            local data = {
                  id  =  winner_id,
                  ["victories"] = state.victories,
              }

            encoded = nakama.json_encode(data)
            dispatcher.broadcast_message(OpCodes.DECLARE_WINNER,encoded)
          end
        end

        if (op_code > 5) and (op_code < 9) then
          local encoded  = diffuse(decoded)
          dispatcher.broadcast_message(op_code,encoded)
        end

        if op_code == OpCodes.READY_PRESENCE then
          local encoded  = encode_ready_presence(state,decoded)
          dispatcher.broadcast_message(OpCodes.READY_PRESENCE,encoded)

          encoded =  nil
          if is_everyone_ready(state) and (nb_players > 1) then
            active_players = tag_players(state,"plays")
            active_round = true
            math.randomseed(os.time())
            local _seed  =  math.random(0,60)
            local data = {seed = _seed}
            encoded = nakama.json_encode(data)
            dispatcher.broadcast_message(OpCodes.START_ROUND,encoded)
          end
        end
      end

  if active_round then
    local encoded = diffuse_positions(state)
    dispatcher.broadcast_message(OpCodes.UPDATE_POSITION,encoded)
  end

  return state
end

function world_control.match_terminate(context,  dispatcher, tick, state,  grace_seconds)
  return state
end


function world_control.match_signal(context, dispatcher, tick, state, data)
  return state, data
end



-- additional fonctions for "clean code" matters



function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

--assign a color (color code) to the new joiner
--but before that it must check for a valid and available one
function  assign_color(colors)

  color =  0
  for i = 1 , 4 do
      done  = true
      for k,v in pairs(colors) do
          if v == i  then
              done  =  false
          end
        end

        if done then
          color  =  i
          break
        end
      end

      return color
end

--makes a "ready to send"  json which contains the informations of the active players in this match
function encode_previous_presences(state)

  local data = {
        ["presences"] = state.presences,
        ["nicknames"] = state.nicknames,
        ["victories"] = state.victories,
        ["game_states"] = state.game_states,
        ["colors"] = state.colors
    }

    return nakama.json_encode(data)

end

--makes a "ready to send"  json which contains the updated victories of the players
function encode_victories(state)
  local data = {
        ["victories"] = state.victories,
    }
    return nakama.json_encode(data)
end

--makes a "ready to send" json containing the informations on the new player who joined
function encode_new_presence(state,decoded)

  local _id = decoded.id
  local _nickname = decoded.nickname
  state.nicknames[_id] = _nickname
  state.victories[_id] = 0
  state.game_states[_id]  = "connected"

  state.colors[_id] = assign_color(state.colors)


  local data = {
        ["presence"] = state.presences[_id],
        color  = state.colors[_id],
        nickname = _nickname,
        id = _id,
    }

  return nakama.json_encode(data)

end


--makes a "ready to use" json containing the id of the player who is ready
function encode_ready_presence(state, decoded)
  local _id = decoded.id

  state.game_states[_id] = "Ready"

  local data =  {id = _id}

  return nakama.json_encode(data)

end

--checks if everyone is ready to start a round
function is_everyone_ready(state)
  local res  =  true

  for k,v in pairs(state.game_states) do
      if not(v == "Ready") then
        res = false
      end
  end

  return res
end

--tags the players who are playing in the round so the new joiners will know they have to wait
function  tag_players(state,tag)
  local nb = 0

  for k,v in pairs(state.presences) do
    state.game_states[k]  = tag
    nb = nb +1
  end

  return nb
end

function back_to_lobby(state,tag)

  for k,v in pairs(state.presences) do
    if state.game_states[k] == "plays" then
      state.game_states[k]  = tag
    end
  end

end


--updates the positions server side to send them in each tick
function update_position(state,decoded)
  state.positions[decoded.id] = decoded.pos
end

--less frequent messages from the client designed to only be relayed to the others without
--any alteration on the server
function diffuse(decoded)
  return nakama.json_encode(decoded)
end


--the positions are sent every tick and are very frequent
--it's better to burn some octets in memory to save some processing energy
function diffuse_positions(state)

  local data = {
        ["positions"] = state.positions
    }

  return nakama.json_encode(data)

end

--clears the  round data in state

function clear_round_data(state)

  active_round = false
  active_players = 0

  for k,_ in pairs(state.presences) do
    state.dead[k] = nil
    state.positions[k] = {
            ["x"] = 0,
            ["y"] = 0
        }
  end
end
--[==[
--]==]

return world_control
