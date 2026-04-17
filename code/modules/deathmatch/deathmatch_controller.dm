// Arena must sit above all game z-levels (station, centcom, mining, etc).
// If fewer than this many levels exist at allocation time, pad with an empty one first.
#define DEATHMATCH_MIN_ZLEVEL_PAD 6

var/global/datum/deathmatch_controller/deathmatch_game
var/global/list/datum/deathmatch_lobby/deathmatch_lobbies = list()

#define DM_LOBBY_COOLDOWN 30 SECONDS

/datum/deathmatch_controller
	var/list/datum/deathmatch_map/maps = list()
	var/list/loadouts = list()
	var/shared_arena_z = 0
	var/arena_in_use = FALSE
	var/list/lobby_cooldowns = list()

/datum/deathmatch_controller/New()
	..()
	for(var/map_type in subtypesof(/datum/deathmatch_map))
		var/datum/deathmatch_map/map_datum = new map_type
		maps += map_datum
	for(var/loadout_type in subtypesof(/datum/outfit/deathmatch))
		var/datum/outfit/deathmatch/loadout_datum = new loadout_type
		if(loadout_datum.name)
			loadouts += loadout_datum

/datum/deathmatch_controller/proc/create_lobby(mob/dead/observer/host)
	if(!host || !host.client)
		return
	var/ckey = host.ckey
	if(deathmatch_lobbies[ckey] || find_player_lobby(ckey))
		to_chat(host, "<span class='warning'>Вы уже в лобби дезматча!</span>")
		return
	var/last_created = lobby_cooldowns[ckey]
	if(last_created && (world.time - last_created) < DM_LOBBY_COOLDOWN)
		var/remaining = round((DM_LOBBY_COOLDOWN - (world.time - last_created)) / 10)
		to_chat(host, "<span class='warning'>Подождите ещё [remaining] сек. перед созданием нового лобби.</span>")
		return
	// Reserve slot before new() to prevent rapid-click race (new() may sleep internally)
	deathmatch_lobbies[ckey] = "pending"
	var/datum/deathmatch_lobby/lobby = new(host)
	if(!lobby || QDELING(lobby))
		deathmatch_lobbies -= ckey
		return
	deathmatch_lobbies[ckey] = lobby
	lobby_cooldowns[ckey] = world.time
	to_chat(host, "<span class='notice'>Вы создали лобби дезматча!</span>")
	notify_ghosts("Создано лобби Дезматча!", enter_link="<a href='byond://?src=\ref[lobby];join=1'>\[Подключиться\]</a>", source = host, header = "Дезматч")
	return lobby

/datum/deathmatch_controller/proc/remove_lobby(ckey)
	var/datum/deathmatch_lobby/lobby = deathmatch_lobbies[ckey]
	deathmatch_lobbies -= ckey
	if(istype(lobby))
		qdel(lobby)

/datum/deathmatch_controller/proc/find_player_lobby(ckey)
	for(var/host_key in deathmatch_lobbies)
		var/datum/deathmatch_lobby/lobby = deathmatch_lobbies[host_key]
		if(!istype(lobby))
			continue
		if(lobby.players[ckey])
			return lobby
	return null

/datum/deathmatch_controller/proc/allocate_arena_z(map_name)
	if(arena_in_use)
		return 0
	if(shared_arena_z <= 0)
		if(SSmapping.z_list.len < DEATHMATCH_MIN_ZLEVEL_PAD)
			SSmapping.add_new_zlevel("Empty Area DM Pad", list(ZTRAIT_SPACE = TRUE))
		var/datum/space_level/zlevel_result = SSmapping.add_new_zlevel("Deathmatch Arena", list(ZTRAIT_DEATHMATCH = TRUE))
		shared_arena_z = zlevel_result?.z_value || 0
	arena_in_use = TRUE
	return shared_arena_z

/datum/deathmatch_controller/proc/release_arena_z()
	arena_in_use = FALSE

/proc/get_deathmatch_game()
	if(!global.deathmatch_game)
		global.deathmatch_game = new /datum/deathmatch_controller()
	var/datum/deathmatch_controller/result = global.deathmatch_game
	return result

/datum/deathmatch_controller/tgui_state(mob/user)
	return global.always_state

/datum/deathmatch_controller/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, null)
	if(!ui)
		ui = new(user, src, "DeathmatchPanel")
		ui.set_autoupdate(FALSE)
		ui.open()

/datum/deathmatch_controller/tgui_data(mob/user)
	. = ..()
	var/ckey = user.ckey
	var/datum/deathmatch_lobby/my_lobby = find_player_lobby(ckey)

	var/list/map_data = list()
	for(var/datum/deathmatch_map/map_datum in maps)
		map_data += list(list(
			"name" = map_datum.name,
			"desc" = map_datum.desc,
			"max_players" = map_datum.max_players,
			"ref" = "\ref[map_datum]",
		))
	.["maps"] = map_data

	var/list/loadout_data = list()
	for(var/datum/outfit/deathmatch/loadout_datum in loadouts)
		loadout_data += list(list(
			"name" = loadout_datum.display_name,
			"desc" = loadout_datum.desc,
			"ref" = "\ref[loadout_datum]",
		))
	.["loadouts"] = loadout_data

	var/list/lobby_list = list()
	var/list/active_list = list()
	for(var/host_key in deathmatch_lobbies)
		var/datum/deathmatch_lobby/lobby = deathmatch_lobbies[host_key]
		if(!istype(lobby))
			continue
		if(!lobby.playing)
			lobby_list += list(list(
				"host" = host_key,
				"map" = lobby.current_map?.name || "Не выбрана",
				"players" = lobby.players.len,
				"max_players" = lobby.current_map?.max_players || 0,
				"ref" = "\ref[lobby]",
			))
		else
			active_list += list(list(
				"host" = host_key,
				"map" = lobby.current_map?.name || "?",
				"players" = lobby.players.len,
				"ref" = "\ref[lobby]",
			))
	.["lobbies"] = lobby_list
	.["active"] = active_list

	if(my_lobby)
		.["in_lobby"] = TRUE
		.["lobby_host"] = my_lobby.host
		.["is_host"] = (ckey == my_lobby.host)
		.["lobby_playing"] = my_lobby.playing
		.["lobby_map"] = my_lobby.current_map?.name || "Не выбрана"
		.["lobby_map_desc"] = my_lobby.current_map?.desc || ""
		var/list/players_data = list()
		for(var/player_ckey in my_lobby.players)
			var/list/player_info = my_lobby.players[player_ckey]
			var/datum/outfit/deathmatch/player_loadout = player_info["loadout"]
			players_data += list(list(
				"ckey" = player_ckey,
				"loadout" = player_loadout?.display_name || "—",
				"ready" = player_info["ready"],
				"is_host" = (player_ckey == my_lobby.host),
			))
		.["lobby_players"] = players_data
		var/list/my_info = my_lobby.players[ckey]
		var/datum/outfit/deathmatch/my_loadout_datum = my_info["loadout"]
		.["my_loadout"] = my_loadout_datum?.display_name
		.["my_ready"] = my_info["ready"]
	else
		.["in_lobby"] = FALSE

/datum/deathmatch_controller/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	var/ckey = user.ckey
	switch(action)
		if("create_lobby")
			if(!istype(user, /mob/dead/observer))
				to_chat(user, "<span class='warning'>Только наблюдатели могут создавать лобби!</span>")
				return TRUE
			create_lobby(user)
			return TRUE
		if("join_lobby")
			var/datum/deathmatch_lobby/lobby = locate(params["ref"])
			if(!istype(lobby))
				to_chat(user, "<span class='warning'>Лобби не найдено!</span>")
				return TRUE
			lobby.add_player(user)
			return TRUE
		if("leave_lobby")
			var/datum/deathmatch_lobby/lobby = find_player_lobby(ckey)
			if(lobby)
				lobby.remove_player(ckey)
			return TRUE
		if("toggle_ready")
			var/datum/deathmatch_lobby/lobby = find_player_lobby(ckey)
			if(lobby)
				lobby.toggle_ready(ckey)
			return TRUE
		if("set_loadout")
			var/datum/outfit/deathmatch/loadout_datum = locate(params["ref"])
			if(istype(loadout_datum))
				var/datum/deathmatch_lobby/lobby = find_player_lobby(ckey)
				if(lobby)
					lobby.set_loadout(ckey, loadout_datum)
			return TRUE
		if("set_map")
			var/datum/deathmatch_map/map_datum = locate(params["ref"])
			if(istype(map_datum))
				var/datum/deathmatch_lobby/lobby = find_player_lobby(ckey)
				if(lobby && ckey == lobby.host)
					lobby.set_map(map_datum)
			return TRUE
		if("start_game")
			var/datum/deathmatch_lobby/lobby = find_player_lobby(ckey)
			if(lobby && ckey == lobby.host)
				lobby.start_game()
			else
				to_chat(user, "<span class='warning'>Только хост может начать матч!</span>")
			return TRUE
		if("spectate")
			var/datum/deathmatch_lobby/lobby = locate(params["ref"])
			if(!istype(lobby) || !lobby.playing || !lobby.arena_turf)
				return TRUE
			if(isobserver(user))
				user.forceMove(get_turf(lobby.arena_turf))
			return TRUE
