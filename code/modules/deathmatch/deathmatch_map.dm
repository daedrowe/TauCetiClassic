/**
 * # Deathmatch Maps
 *
 * Map datums defining available deathmatch arenas.
 * REUSES existing post_round_arena maps from TauCeti Classic.
 * These maps already have "Gladiator" spawn point landmarks built in.
 */

/datum/deathmatch_map
	/// Map name
	var/name = "Unknown"
	/// Map description
	var/desc = ""
	/// Path to the .dmm file
	var/map_path = null
	/// Maximum number of players
	var/max_players = 8
	/// Minimum number of players
	var/min_players = 2

// ==========================================
// REUSING existing post_round_arena maps
// ==========================================

/datum/deathmatch_map/cult
	name = "Культ"
	desc = "Маленькая тёмная арена в стиле культистов. Тесный бой."
	map_path = "maps/templates/post_round_arena/ultra_small_cult.dmm"
	max_players = 4
	min_players = 2

/datum/deathmatch_map/classic
	name = "Классическая"
	desc = "Классическая небольшая арена. Стандартный бой."
	map_path = "maps/templates/post_round_arena/small_classic.dmm"
	max_players = 8
	min_players = 2

/datum/deathmatch_map/alien
	name = "Чужие"
	desc = "Арена в стиле чужих. Странная атмосфера."
	map_path = "maps/templates/post_round_arena/small_alien.dmm"
	max_players = 8
	min_players = 2

/datum/deathmatch_map/medbay
	name = "Медотсек"
	desc = "Средняя арена в медицинском стиле. Много укрытий."
	map_path = "maps/templates/post_round_arena/medium_medbay.dmm"
	max_players = 8
	min_players = 2

/datum/deathmatch_map/four_biomes
	name = "Четыре Биома"
	desc = "Большая арена с четырьмя разными биомами. Разнообразный бой."
	map_path = "maps/templates/post_round_arena/medium_four_biomes.dmm"
	max_players = 8
	min_players = 2
