local world_control  =  {}

local nakama = require("nakama")

local  nb_players  =  0

--before the starting round be sure to give the characters correct spawn positions

-- Custom operation codes. Nakama specific codes are <= 0.
local OpCodes = {

    PREVIOUS_PRESENCES = 1,
	  NEW_PRESENCE = 2,
    READY_PRESENCE = 3,
    START_ROUND = 4,
    UPDATE_POSITION = 5,
    TRANSFORMATION = 6,
    SHOOT = 7,
}

-- Command pattern table for boiler plate updates that uses data and state.
local commands = {}

-- Updates the position in the game state
commands[OpCodes.UPDATE_POSITION] = function(data, state)
    local id = data.id
    local position = data.pos
    if state.positions[id] ~= nil then
        state.positions[id] = position
    end
end


function world_control.match_init(context  ,params)
  local state  = {
    presences  =  {},
    nicknames  =  {},
    victories  = {},
    game_states = {},
    colors =   {},
    positions = {},
    transformations = {}
  }
  local tick_rate =  10
  local label =  params.type
  return state,  tick_rate, label
end

function world_control.match_join_attempt(context ,dispatcher, tick, state, presence, metadata)

  if state.presences[presence.user_id] ~= nil then
    return state, false,  "user  already logged in!"
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
    state.colors[presence.user_id]  = nil
    state.victories[presence.user_id]  = nil
    state.game_states[presence.user_id] = nil
    state.nicknames[presence.user_id] = nil
    state.presences[presence.user_id]  =  nil
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

        --just for tests
        if op_code == OpCodes.UPDATE_POSITION then
          local encoded  = update_position(decoded)
          dispatcher.broadcast_message(OpCodes.UPDATE_POSITION,encoded)
        end

        if op_code == OpCodes.TRANSFORMATION then
          local encoded  = transformation(decoded)
          dispatcher.broadcast_message(OpCodes.TRANSFORMATION,encoded)
        end

        if op_code == OpCodes.SHOOT then
          local encoded  = shoot(decoded)
          dispatcher.broadcast_message(OpCodes.SHOOT,encoded)
        end

        --end of tests

        if op_code == OpCodes.READY_PRESENCE then
          local encoded  = encode_ready_presence(state,decoded)
          dispatcher.broadcast_message(OpCodes.READY_PRESENCE,encoded)

          encoded =  nil
          if is_everyone_ready(state) and (nb_players > 1) then
            local seeker_id = pick_seeker(state)
            local data = {id = seeker_id}
            dispatcher.broadcast_message(OpCodes.START_ROUND,nakama.json_encode(data))
          end
        end

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

--chooses a random player to be the seeker
function pick_seeker(state)

  math.randomseed(os.time())
  local seeker = math.random(1,nb_players)
  local i = 1

  for k,_ in pairs(state.presences) do
    if i == seeker then
        return k
    else
        i = i + 1
    end
  end

end

--just for tests  remove later
function update_position(decoded)
  return nakama.json_encode(decoded)
end

function transformation(decoded)
  return nakama.json_encode(decoded)
end

function shoot(decoded)
  return nakama.json_encode(decoded)
end
--[==[
--]==]

return world_control
