local nakama  =  require("nakama")


--matches criteria
local limit = 10
local authoritative = nil
local public = "public"

local  function get_world_id(_,_)
  local  matches = nakama.match_list()
  local current_match = matches[1]

  if current_match ==  nil  then
    return nakama.match_create("world_control",{})
  else
    return current_match.match_id
  end
end


--cree un match prive en notant son label : utilite dans le filtrage!
local function create_private_match(_,_)

  return nakama.match_create("world_control",{type  =  "private"})
end

--rejoindre un match prive en envoyant l'id unique du match
local function join_private_match(_,params)
  local data = nakama.json_decode(params)
  local world_id = data.world_id
  return nakama.match_get(world_id)
end

--utiliser le matchmaker en creant un match si besoin et en se referant au matchs note public
local function join_matchmaker(_,_)
  local  matches = nakama.match_list(limit, authoritative, public) --liste des matches publié sur le serveur
  local current_match = matches[1] --choisir le match voulu,  plus tard plus complexe(privé, random)

  --basique :  si un match existe donc (le premier de la liste) on retourne son id pour interagir avec
  --sinon on en créé un nouveau sur le serveur avec le script world_control
  if current_match ==  nil  then
    return nakama.match_create("world_control",{type = "public"})
  else
    return current_match.match_id
  end
  end

nakama.register_rpc(join_private_match,"join_private_match")
nakama.register_rpc(join_matchmaker,"join_matchmaker")
nakama.register_rpc(create_private_match,"create_private_match") --creation de match prive
nakama.register_rpc(get_world_id,"get_world_id") --enregistrer une fonction que les clients appellent puis la définir en haut pour que le serveur l'execute
