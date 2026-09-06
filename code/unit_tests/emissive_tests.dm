/datum/unit_test/emissive_blocker_lifecycle
	name = "RENDERING: EMISSIVE BLOCKER LIFECYCLE"

/datum/unit_test/emissive_blocker_lifecycle/start_test()
	var/obj/item/item = new
	var/datum/component/emissive_blocker/component = item.GetComponent(/datum/component/emissive_blocker)
	if(!component)
		qdel(item)
		fail("Items must initialize their blocker even though they skip parent atom_init.")
		return FALSE
	var/atom/movable/emissive_blocker/blocker = component.blocker
	item.AddComponent(/datum/component/emissive_blocker)
	if(length(item.vis_contents) != 1)
		qdel(item)
		fail("Adding the component twice duplicated its visual child.")
		return FALSE
	item.appearance_flags |= RESET_COLOR
	qdel(component)
	if(length(item.vis_contents) || item.render_target || !QDELETED(blocker) || (item.appearance_flags & KEEP_TOGETHER) || !(item.appearance_flags & RESET_COLOR))
		qdel(item)
		fail("Removing a blocker must clean up only the render state it owns.")
		return FALSE
	qdel(item)

	var/atom/movable/owner = new
	owner.appearance_flags |= KEEP_TOGETHER
	owner.render_target = "emissive_test_[REF(owner)]"
	var/original_target = owner.render_target
	component = owner.AddComponent(/datum/component/emissive_blocker)
	qdel(component)
	if(owner.render_target != original_target || !(owner.appearance_flags & KEEP_TOGETHER) || length(owner.vis_contents))
		qdel(owner)
		fail("Removing a blocker changed a render target or flag owned by another system.")
		return FALSE

	owner.render_target = null
	component = owner.AddComponent(/datum/component/emissive_blocker)
	owner.render_target = original_target
	qdel(component)
	if(owner.render_target != original_target)
		qdel(owner)
		fail("Removing a blocker cleared a replacement render target.")
		return FALSE

	component = owner.AddComponent(/datum/component/emissive_blocker)
	blocker = component.blocker
	qdel(owner)
	if(!QDELETED(component) || !QDELETED(blocker))
		fail("Deleting the owner left its blocker alive.")
		return FALSE
	pass("Blockers initialize on items, deduplicate, and release only owned render state.")
	return TRUE

/datum/unit_test/emissive_airlock_cache
	name = "RENDERING: EMISSIVE AIRLOCK CACHE"

/datum/unit_test/emissive_airlock_cache/start_test()
	var/mutable_appearance/plain = get_airlock_overlay("lights_poweron", 'icons/obj/doors/airlocks/station2/overlays.dmi', FALSE)
	var/mutable_appearance/glowing = get_airlock_overlay("lights_poweron", 'icons/obj/doors/airlocks/station2/overlays.dmi', TRUE)
	if(plain == glowing || length(plain.overlays) || !length(glowing.overlays))
		fail("Glowing and ordinary airlock overlays must not share a cache entry.")
		return FALSE
	if(get_airlock_overlay("lights_poweron", 'icons/obj/doors/airlocks/station2/overlays.dmi', FALSE) != plain || get_airlock_overlay("lights_poweron", 'icons/obj/doors/airlocks/station2/overlays.dmi', TRUE) != glowing)
		fail("Repeated airlock overlay requests did not reuse their cached appearances.")
		return FALSE
	pass("Airlock glow masks stay separate from ordinary cached overlays.")
	return TRUE

/datum/unit_test/emissive_airlock_directions
	name = "RENDERING: EMISSIVE AIRLOCK DIRECTIONS"

/datum/unit_test/emissive_airlock_directions/start_test()
	var/list/cached = list()
	var/list/seen = list()
	for(var/direction in cardinal)
		var/mutable_appearance/glowing = get_airlock_overlay("lights_poweron", 'icons/obj/doors/airlocks/station2/overlays.dmi', TRUE, direction)
		var/mutable_appearance/mask = glowing.overlays[1]
		if(glowing.dir != direction || mask.dir != direction || (glowing in seen))
			fail("A rotated airlock reused another direction's glow or mask.")
			return FALSE
		cached["[direction]"] = glowing
		seen += glowing
	for(var/direction in cardinal)
		if(get_airlock_overlay("lights_poweron", 'icons/obj/doors/airlocks/station2/overlays.dmi', TRUE, direction) != cached["[direction]"])
			fail("Requesting another direction replaced an existing airlock cache entry.")
			return FALSE
	pass("Airlock glow and mask cache entries preserve all four directions.")
	return TRUE

/datum/unit_test/emissive_computer_states
	name = "RENDERING: EMISSIVE COMPUTER STATES"

/datum/unit_test/emissive_computer_states/start_test()
	var/obj/machinery/computer/robotics/computer = new
	var/obj/machinery/computer/robotics/other = new
	computer.stat = 0
	other.stat = 0
	computer.update_icon()
	other.update_icon()
	var/mutable_appearance/south_mask = computer.emissive_overlay
	var/list/errors = list()
	if(!south_mask || other.emissive_overlay != south_mask)
		errors += "Powered consoles did not reuse a screen mask."
	computer.set_dir(EAST)
	if(!computer.emissive_overlay || computer.emissive_overlay == south_mask || computer.emissive_overlay.dir != EAST || other.emissive_overlay != south_mask)
		errors += "Rotating one console changed or reused another direction's mask."
	computer.stat |= NOPOWER
	computer.update_icon()
	if(computer.emissive_overlay)
		errors += "An unpowered console kept its screen glow."
	computer.stat = BROKEN
	computer.update_icon()
	if(computer.emissive_overlay)
		errors += "A broken console kept its screen glow."
	computer.stat = 0
	computer.update_icon()
	if(!computer.emissive_overlay)
		errors += "Restoring a console did not restore its screen glow."
	computer.icon = 'icons/obj/objects.dmi'
	computer.update_emissive()
	if(computer.emissive_overlay)
		errors += "A foreign console icon reused computer.dmi's screen mask."
	qdel(computer)
	qdel(other)
	if(length(errors))
		fail(jointext(errors, " "))
		return FALSE
	pass("Console masks follow power, broken state, direction, and sprite ownership.")
	return TRUE

/datum/unit_test/emissive_airlock_light_states
	name = "RENDERING: AIRLOCK LIGHT STATE TRANSITIONS"

/datum/unit_test/emissive_airlock_light_states/start_test()
	var/obj/machinery/door/airlock/door = new
	var/list/errors = list()
	door.stat = 0
	door.lights = TRUE
	door.do_animate("opening")
	if(door.light_color != "#57e69c")
		errors += "Opening must use the green access light."
	door.density = FALSE
	door.update_icon()
	if(door.light_color != "#3aa7c2")
		errors += "An open airlock did not restore its steady light color."
	door.locked = TRUE
	door.update_icon()
	if(door.light_color != "#c23b23")
		errors += "An open bolted airlock did not use its red light."
	door.locked = FALSE
	door.emergency = TRUE
	door.update_icon()
	if(door.light_color != "#d1d11d")
		errors += "An open emergency airlock did not use its yellow light."
	door.emergency = FALSE
	door.do_animate("closing")
	if(door.light_color != "#57e69c")
		errors += "Closing must use the green access light."
	door.density = TRUE
	door.update_icon()
	if(door.light_color != "#3aa7c2")
		errors += "A closed airlock did not restore its steady light color."
	door.stat |= NOPOWER
	door.update_icon()
	if(door.light_range || door.light)
		errors += "An unpowered airlock kept its light source."
	qdel(door)
	if(length(errors))
		fail(jointext(errors, " "))
		return FALSE
	pass("Airlock lighting follows opening, open, bolts, emergency, closing, closed, and power loss.")
	return TRUE

/datum/unit_test/emissive_status_display_light
	name = "RENDERING: STATUS DISPLAY LIGHT LIFECYCLE"

/datum/unit_test/emissive_status_display_light/start_test()
	var/list/errors = list()
	var/obj/machinery/status_display/display = new
	display.stat = 0
	display.mode = 3
	display.set_picture("default")
	var/datum/light_source/original_light = display.light
	if(!original_light || !display.underlays.len)
		errors += "A lit status display has no glow or surrounding light."
	display.set_picture("default")
	display.update_display("-ETA-", "01:23")
	display.update_display("-ETA-", "01:22")
	if(display.light != original_light)
		errors += "Updating display content recreated its light source."
	if(display.underlays.len != 1)
		errors += "Updating display content duplicated its emissive mask."
	display.stat = NOPOWER
	display.update()
	if(display.light || display.light_range || display.underlays.len)
		errors += "An unpowered status display kept its glow or light: light=[!!display.light], range=[display.light_range], underlays=[display.underlays.len]."
	display.stat = 0
	display.update()
	if(!display.light || !display.underlays.len)
		errors += "Restoring power did not restore status display lighting."
	display.stat = BROKEN
	display.update()
	if(display.light || display.underlays.len)
		errors += "A broken status display kept its light."
	display.stat = 0
	display.update_display("", "")
	if(display.light || display.underlays.len)
		errors += "An empty status display kept its light."
	qdel(display)

	var/obj/machinery/ai_status_display/ai_display = new
	ai_display.stat = 0
	ai_display.mode = 1
	ai_display.update()
	original_light = ai_display.light
	ai_display.update()
	if(!original_light || ai_display.light != original_light)
		errors += "An AI display did not reuse its active light."
	if(ai_display.underlays.len != 1)
		errors += "Updating an AI display duplicated its emissive mask."
	ai_display.emotion = "Blank"
	ai_display.update()
	if(ai_display.light || ai_display.underlays.len)
		errors += "A blank AI display kept its glow or light."
	ai_display.emotion = "Neutral"
	ai_display.update()
	ai_display.stat = BROKEN
	ai_display.update()
	if(ai_display.light || ai_display.underlays.len)
		errors += "A broken AI display kept its glow or light."
	qdel(ai_display)
	if(length(errors))
		fail(jointext(errors, " "))
		return FALSE
	pass("Display lighting follows content and power without recreating an unchanged light source.")
	return TRUE
