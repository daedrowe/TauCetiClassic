#define DM_NOT_PLAYING   0
#define DM_PLAYING       1

#define DM_MIN_PLAYERS   1
#define DM_MAX_PLAYERS   8

#define DM_GAME_TIME     5 MINUTES
#define DM_AFK_TIMEOUT   5 MINUTES
#define DM_PLAYER_CHECK  10 SECONDS

/datum/deathmatch_lobby
	var/host
	var/list/players = list()
	var/datum/deathmatch_map/current_map
	var/playing = DM_NOT_PLAYING
	var/starting = FALSE
	var/list/spawn_points = list()
	var/afk_timer
	var/game_timer
	var/player_check_timer
	var/turf/arena_turf
	var/arena_z = 0

/datum/deathmatch_lobby/New(mob/dead/observer/player)
	..()
	if(!player)
		qdel(src)
		return
	host = player.ckey
	if(deathmatch_game.maps.len)
		current_map = deathmatch_game.maps[1]
	add_player(player)
	afk_timer = addtimer(CALLBACK(src, PROC_REF(afk_close)), DM_AFK_TIMEOUT, TIMER_STOPPABLE)

/datum/deathmatch_lobby/Destroy(force, ...)
	deltimer(afk_timer)
	deltimer(game_timer)
	deltimer(player_check_timer)
	for(var/ckey in players)
		return_to_ghost(ckey)
	cleanup_arena()
	players = null
	current_map = null
	spawn_points = null
	return ..()

/// Join entry point. Takes a mob (observer or living); other lobby procs take ckey.
/datum/deathmatch_lobby/proc/add_player(mob/player)
	if(!player || !player.client || players.len >= DM_MAX_PLAYERS)
		return FALSE
	var/ckey = player.ckey
	if(ckey in players)
		return FALSE
	players[ckey] = list(
		"mob" = player,
		"loadout" = deathmatch_game.loadouts.len ? deathmatch_game.loadouts[1] : null,
		"ready" = playing == DM_PLAYING,
	)
	if(playing == DM_PLAYING)
		to_chat(player, "<span class='notice'>Вы присоединились к матчу (хост: [host]).</span>")
		announce("<b>[ckey]</b> влетел в матч!")
		spawn_player(ckey)
	else
		to_chat(player, "<span class='notice'>Вы присоединились к лобби дезматча (хост: [host]).</span>")
		announce("<b>[ckey]</b> присоединился к лобби.")
	return TRUE

/datum/deathmatch_lobby/proc/remove_player(ckey)
	if(!(ckey in players))
		return
	if(playing == DM_PLAYING)
		handle_player_death(ckey)
		return
	var/list/player_info = players[ckey]
	var/mob/player_mob = player_info["mob"]
	if(player_mob)
		UnregisterSignal(player_mob, list(COMSIG_MOB_DIED, COMSIG_PARENT_QDELETING))
	players -= ckey
	announce("<b>[ckey]</b> покинул лобби.")
	if(ckey == host)
		if(players.len)
			host = players[1]
			announce("<b>[host]</b> стал новым хостом.")
		else
			deathmatch_game.remove_lobby(host)

/datum/deathmatch_lobby/proc/toggle_ready(ckey)
	if(ckey in players)
		players[ckey]["ready"] = !players[ckey]["ready"]

/datum/deathmatch_lobby/proc/set_map(datum/deathmatch_map/new_map)
	if(!playing)
		current_map = new_map

/datum/deathmatch_lobby/proc/set_loadout(ckey, datum/outfit/deathmatch/loadout_datum)
	if(ckey in players)
		players[ckey]["loadout"] = loadout_datum

/datum/deathmatch_lobby/proc/start_game()
	if(playing || starting || players.len < DM_MIN_PLAYERS || !current_map)
		return FALSE
	for(var/ckey in players)
		if(!players[ckey]["ready"])
			return FALSE
	if(deathmatch_game.arena_in_use)
		var/list/host_info = players[host]
		var/mob/host_mob = host_info?["mob"]
		to_chat(host_mob, "<span class='warning'>Арена занята другим матчем. Подождите его окончания!</span>")
		return FALSE
	starting = TRUE
	deltimer(afk_timer)
	afk_timer = null
	if(!load_arena_map())
		starting = FALSE
		return FALSE
	spawn_all_players()
	starting = FALSE
	playing = DM_PLAYING
	game_timer = addtimer(CALLBACK(src, PROC_REF(game_timeout)), DM_GAME_TIME, TIMER_STOPPABLE)
	player_check_timer = addtimer(CALLBACK(src, PROC_REF(check_players_alive)), DM_PLAYER_CHECK, TIMER_STOPPABLE)
	announce("<span class='boldnotice'>МАТЧ НАЧИНАЕТСЯ!</span>")
	log_game("Deathmatch game [host] started with [players.len] players on map [current_map.name].")
	return TRUE

/datum/deathmatch_lobby/proc/load_arena_map()
	if(!current_map || !current_map.map_path)
		log_game("Deathmatch load_arena_map: no map selected")
		return FALSE
	arena_z = deathmatch_game.allocate_arena_z(current_map.name)
	if(!arena_z)
		log_game("Deathmatch load_arena_map: failed to allocate z-level")
		return FALSE
	arena_turf = locate(round(world.maxx / 2), round(world.maxy / 2), arena_z)
	if(!arena_turf)
		log_game("Deathmatch load_arena_map: failed to locate arena_turf on z=[arena_z]")
		return FALSE
	var/datum/map_template/map_template_datum = new
	map_template_datum.mappath = current_map.map_path
	map_template_datum.name = current_map.name
	if(!map_template_datum.load(arena_turf, centered = TRUE))
		log_game("Deathmatch load_arena_map: map load failed for [current_map.map_path]")
		cleanup_arena()
		return FALSE
	if(landmarks_list["Gladiator"])
		for(var/obj/effect/landmark/spawn_landmark in landmarks_list["Gladiator"])
			var/turf/spawn_turf = get_turf(spawn_landmark)
			if(spawn_turf && spawn_turf.z == arena_z)
				spawn_points += spawn_landmark
		landmarks_list["Gladiator"] -= spawn_points
	log_game("Deathmatch load_arena_map: z=[arena_z], spawn_points=[spawn_points.len], players=[players.len]")
	if(spawn_points.len < players.len)
		cleanup_arena()
		return FALSE
	return TRUE

/datum/deathmatch_lobby/proc/spawn_all_players()
	var/list/available_spawns = spawn_points.Copy()
	for(var/ckey in players)
		if(!spawn_player(ckey, available_spawns))
			players -= ckey

/// Spawns a single player on the arena. `available_spawns` is an optional consumed list for bulk spawns; late-joiners pick randomly from spawn_points.
/datum/deathmatch_lobby/proc/spawn_player(ckey, list/available_spawns = null)
	var/list/player_info = players[ckey]
	if(!player_info)
		return FALSE
	var/mob/current_mob = player_info["mob"]
	var/client/C = current_mob?.client
	if(!C)
		return FALSE
	var/obj/effect/landmark/spawn_point
	if(available_spawns)
		spawn_point = pick_n_take(available_spawns)
	else if(spawn_points.len)
		spawn_point = pick(spawn_points)
	var/turf/spawn_turf = spawn_point ? get_turf(spawn_point) : arena_turf
	var/mob/living/carbon/human/human_player = new(spawn_turf)
	human_player.gender = C.prefs.gender
	human_player.real_name = C.prefs.real_name || ckey
	human_player.name = human_player.real_name
	var/datum/outfit/deathmatch/loadout_datum = player_info["loadout"]
	human_player.equipOutfit(loadout_datum ? loadout_datum.type : /datum/outfit/deathmatch/assistant)
	if(isliving(current_mob) && !QDELING(current_mob))
		current_mob.ghostize(can_reenter_corpse = FALSE)
	human_player.key = C.key
	if(human_player.mind)
		human_player.mind.skills.add_available_skillset(/datum/skillset/max)
		human_player.mind.skills.maximize_active_skills()
	player_info["mob"] = human_player
	RegisterSignal(human_player, COMSIG_MOB_DIED, PROC_REF(on_player_death))
	RegisterSignal(human_player, COMSIG_PARENT_QDELETING, PROC_REF(on_player_deleted))
	to_chat(human_player, "<span class='boldnotice'>ДЕЗМАТЧ! Вы на карте \"[current_map.name]\". Убейте всех, чтобы победить!</span>")
	human_player.playsound_local(null, 'sound/lobby/Thunderdome.ogg', VOL_MUSIC, vary = FALSE, frequency = null, ignore_environment = TRUE)
	return TRUE

/datum/deathmatch_lobby/proc/on_player_death(mob/living/carbon/human/victim)
	SIGNAL_HANDLER
	if(QDELING(src))
		return
	var/victim_ckey = find_ckey_by_mob(victim)
	if(victim_ckey)
		INVOKE_ASYNC(src, PROC_REF(handle_player_death), victim_ckey)

/datum/deathmatch_lobby/proc/on_player_deleted(mob/living/victim)
	SIGNAL_HANDLER
	if(QDELING(src))
		return
	var/victim_ckey = find_ckey_by_mob(victim)
	if(victim_ckey)
		INVOKE_ASYNC(src, PROC_REF(handle_player_death), victim_ckey, TRUE)

/datum/deathmatch_lobby/proc/find_ckey_by_mob(mob/target_mob)
	for(var/ckey in players)
		if(players[ckey]["mob"] == target_mob)
			return ckey
	return null

/datum/deathmatch_lobby/proc/handle_player_death(ckey, skip_unregister = FALSE)
	if(!(ckey in players))
		return
	var/list/player_info = players[ckey]
	var/mob/living/player_body = player_info["mob"]
	if(player_body && !skip_unregister && !QDELING(player_body))
		UnregisterSignal(player_body, list(COMSIG_MOB_DIED, COMSIG_PARENT_QDELETING))
	players -= ckey
	if(player_body && !QDELING(player_body) && player_body.client)
		player_body.ghostize(can_reenter_corpse = FALSE)
	announce("<span class='danger'><b>[ckey]</b> ПОГИБ! Осталось [players.len] игроков.</span>")
	if(playing == DM_PLAYING && players.len <= 1)
		end_game()

/datum/deathmatch_lobby/proc/end_game()
	deltimer(game_timer)
	deltimer(player_check_timer)
	game_timer = null
	player_check_timer = null
	var/winner_name = "Никто"
	if(players.len)
		var/first_ckey = players[1]
		var/mob/winner_mob = players[first_ckey]["mob"]
		winner_name = winner_mob ? winner_mob.real_name : first_ckey
	announce("<span class='boldnotice'>МАТЧ ОКОНЧЕН! Победитель: [winner_name]!</span>")
	log_game("Deathmatch game [host] ended. Winner: [winner_name].")
	for(var/ckey in players)
		return_to_ghost(ckey)
	players.Cut()
	playing = DM_NOT_PLAYING
	deathmatch_game.remove_lobby(host)

/datum/deathmatch_lobby/proc/game_timeout()
	if(playing == DM_PLAYING)
		announce("<span class='danger'>Время вышло! Матч окончен ничьей!</span>")
		end_game()

/datum/deathmatch_lobby/proc/return_to_ghost(ckey)
	if(!(ckey in players))
		return
	var/list/player_info = players[ckey]
	var/mob/living/player_body = player_info["mob"]
	if(player_body && !QDELING(player_body))
		UnregisterSignal(player_body, list(COMSIG_MOB_DIED, COMSIG_PARENT_QDELETING))
		if(player_body.client)
			player_body.ghostize(can_reenter_corpse = FALSE)
		qdel(player_body)

/datum/deathmatch_lobby/proc/cleanup_arena()
	if(spawn_points)
		spawn_points.Cut()
	arena_turf = null
	if(arena_z > 0)
		for(var/turf/turf_tile in block(locate(1, 1, arena_z), locate(world.maxx, world.maxy, arena_z)))
			for(var/atom/movable/movable_atom in turf_tile)
				if(ismob(movable_atom))
					var/mob/mob_atom = movable_atom
					if(mob_atom.client)
						continue
				qdel(movable_atom)
			turf_tile.ChangeTurf(/turf/environment/space)
		arena_z = 0
		deathmatch_game.release_arena_z()

/datum/deathmatch_lobby/proc/check_players_alive()
	if(playing != DM_PLAYING)
		return
	var/list/dead_players = list()
	for(var/ckey in players)
		var/list/player_info = players[ckey]
		var/mob/living/player_body = player_info["mob"]
		if(!player_body || QDELING(player_body) || player_body.stat == DEAD || !player_body.key)
			dead_players += ckey
	for(var/dead_ckey in dead_players)
		handle_player_death(dead_ckey, skip_unregister = TRUE)
	if(playing == DM_PLAYING && players.len)
		player_check_timer = addtimer(CALLBACK(src, PROC_REF(check_players_alive)), DM_PLAYER_CHECK, TIMER_STOPPABLE)

/datum/deathmatch_lobby/proc/afk_close()
	announce("<span class='warning'>Лобби закрыто из-за неактивности.</span>")
	deathmatch_game.remove_lobby(host)

/datum/deathmatch_lobby/proc/announce(msg)
	for(var/ckey in players)
		var/mob/player_mob = players[ckey]["mob"]
		if(player_mob)
			to_chat(player_mob, "ДЕЗМАТЧ: [msg]")

/datum/deathmatch_lobby/Topic(href, href_list)
	if(!usr?.client)
		return
	if(href_list["join"])
		if(deathmatch_game.find_player_lobby(usr.ckey))
			to_chat(usr, "<span class='warning'>Вы уже в лобби дезматча!</span>")
		else
			add_player(usr)
		deathmatch_game.tgui_interact(usr)
	return

#undef DM_NOT_PLAYING
#undef DM_PLAYING
#undef DM_MIN_PLAYERS
#undef DM_MAX_PLAYERS
#undef DM_GAME_TIME
#undef DM_AFK_TIMEOUT
#undef DM_PLAYER_CHECK
