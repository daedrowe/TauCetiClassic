/atom/movable/screen/alert/status_effect/swarm_gift
	name = "Подарок роя"
	desc = "Рой дарит вам повышенную эффективность, а также приглушенные звуки переработки. Процветайте и размножайтесь!"
	icon_state = "swarm_gift"

/atom/movable/screen/alert/status_effect/swarm_gift/Click()
	if(!mob_viewer)
		return
	if(!mob_viewer.ckey)
		return
	if(mob_viewer.incapacitated())
		return
	var/datum/faction/replicators/FR = get_or_create_replicators_faction()
	var/datum/replicator_array_info/RAI = FR.ckey2info[mob_viewer.ckey]
	if(!RAI)
		return
	if(RAI.next_music_start >= world.time)
		return
	RAI.next_music_start = world.time + REPLICATOR_MUSIC_LENGTH

	mob_viewer.playsound_local(null, 'sound/music/storm_resurrection.ogg', VOL_MUSIC, null, null, CHANNEL_MUSIC, vary = FALSE, frequency = null, ignore_environment = TRUE)


/datum/status_effect/swarm_gift
	id = "swarm_gift"
	alert_type = /atom/movable/screen/alert/status_effect/swarm_gift

/datum/status_effect/swarm_gift/on_creation(mob/living/new_owner, duration)
	. = ..()
	if(!.)
		return
	src.duration = world.time + duration

/datum/status_effect/swarm_gift/on_apply()
	owner.sight |= SEE_TURFS|SEE_MOBS|SEE_OBJS
	return isreplicator(owner)

/datum/status_effect/swarm_gift/on_remove()
	owner.sight &= ~(SEE_TURFS | SEE_MOBS | SEE_OBJS)
	return isreplicator(owner)

/atom/movable/screen/alert/status_effect/swarms_gift
	name = "Дар роя"
	desc = "Императрице выгодно, чтобы вы были здоровы. Она помогает вам регенерировать."
	icon_state = "alien_help"
	alerttooltipstyle = "alien"

/datum/status_effect/life_support
	id = "life_support"
	duration = -1
	tick_interval = 10
	alert_type = /atom/movable/screen/alert/status_effect/life_support
	var/last_dead_time

/datum/status_effect/life_support/proc/update_time_of_death()
	if(last_dead_time)
		var/delta = world.time - last_dead_time
		var/new_timeofdeath = owner.timeofdeath + delta
		owner.timeofdeath = new_timeofdeath
		owner.tod = worldtime2text()
		last_dead_time = null
	if(owner.stat == DEAD)
		last_dead_time = world.time

/datum/status_effect/life_support/on_creation(mob/living/new_owner, set_duration)
	. = ..()
	update_time_of_death()

/datum/status_effect/life_support/tick()
	update_time_of_death()

/datum/status_effect/life_support/on_remove()
	update_time_of_death()
	return ..()

/datum/status_effect/life_support/be_replaced()
	update_time_of_death()
	return ..()

/atom/movable/screen/alert/status_effect/life_support
	name = "Искусственное жизнеобеспечение"
	desc = "Машины поддерживают циркуляцию вашей крови и вентиляцию легких. Ваше клеточное разрушение после смерти приостановлено."
	icon_state = "asleep"

/atom/movable/screen/alert/status_effect/alertness
	name = "Настороженность"
	desc = "Люди используют болы, следует быть осторожнее. Ваши рефлексы повышены."
	icon_state = "alertness"

/datum/status_effect/alertness
	id = "alertness"
	alert_type = /atom/movable/screen/alert/status_effect/alertness
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/alertness/on_creation(mob/living/new_owner, duration)
	. = ..()
	if(!.)
		return
	src.duration = world.time + duration
