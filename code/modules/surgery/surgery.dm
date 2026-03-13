/* SURGERY STEPS */
/datum/surgery_step
	var/priority = 0	//steps with higher priority would be attempted first

	//type path referencing tools that can be used for this step, and how well are they suited for it
	var/list/allowed_tools = null
	// type paths referencing mutantraces that this step applies to.
	var/list/allowed_species = list("exclude", IPC)

	//duration of the step
	var/min_duration = 0
	var/max_duration = 0

	//evil infection stuff that will make everyone hate me
	var/can_infect = 0
	//How much blood this step can get on surgeon. 1 - hands, 2 - full body.
	var/blood_level = 0

	//Cloth check
	var/clothless = 1
	var/required_skills = list(/datum/skill/surgery = SKILL_LEVEL_TRAINED)
	var/skills_speed_bonus = -0.30 // -30% for each surplus level

// returns how well tool is suited for this step
/datum/surgery_step/proc/tool_quality(obj/item/tool)
	for(var/T in allowed_tools)
		if(istype(tool, T))
			return allowed_tools[T]
	return FALSE

// Checks if this step applies to the mutantrace of the user.
/datum/surgery_step/proc/is_valid_mutantrace(mob/living/carbon/human/target)
	if(ishuman(target) && allowed_species)
		if(("exclude" in allowed_species) == (target.get_species() in allowed_species))
			return FALSE
	return TRUE

// checks whether this step can be applied with the given user and target
/datum/surgery_step/proc/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return FALSE

/datum/surgery_step/proc/prepare_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return TRUE

// does stuff to begin the step, usually just printing messages. Moved germs transfering and bloodying here too
/datum/surgery_step/proc/begin_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/BP = target.get_bodypart(target_zone)
	if(can_infect && BP)
		spread_germs_to_organ(BP, user, tool)
	if(ishuman(user) && prob(60))
		var/mob/living/carbon/human/H = user
		if(blood_level)
			H.bloody_hands(target, 0)
		if(blood_level > 1)
			H.bloody_body(target, 0)
	return

// does stuff to end the step, which is normally print a message + do whatever this step changes
/datum/surgery_step/proc/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return

// stuff that happens when the step fails
/datum/surgery_step/proc/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return null

/proc/spread_germs_to_organ(obj/item/organ/external/BP, mob/living/carbon/human/user, obj/item/tool)
	if(!istype(user) || !istype(BP))
		return

	var/germ_level = 0
	if(user.gloves)
		germ_level += user.gloves.germ_level
	else
		germ_level += user.germ_level

	if(tool.blood_DNA && tool.blood_DNA.len) //germs from blood-stained tools
		germ_level += GERM_LEVEL_AMBIENT * 0.25

	if(HAS_TRAIT(tool, TRAIT_XENO_FUR))
		germ_level += GERM_LEVEL_AMBIENT * 0.25

	if(ishuman(user) && !user.is_skip_breathe() && !user.wear_mask) //wearing a mask helps preventing people from breathing germs into open incisions
		germ_level += user.germ_level * 0.25

	BP.germ_level = max(germ_level, BP.germ_level)
	if(BP.germ_level)
		BP.owner.bad_bodyparts |= BP

/proc/checks_for_surgery(mob/living/carbon/M, mob/living/user, check_covering = TRUE)
	if(!user.Adjacent(M))
		return FALSE
	if(!can_operate(M, user))
		return FALSE
	if(!istype(M))
		return FALSE
	if(user.a_intent == INTENT_HARM)	//check for Hippocratic Oath
		return FALSE
	if(user.is_busy(null)) // No target so we allow multiple players to do surgeries on one pawn.
		return FALSE
	if(ishuman(M) && check_covering)
		return check_human_covering(M, user)
	return TRUE

/proc/get_human_covering(mob/living/carbon/human/T)
	var/covered
	for(var/obj/item/I in list(T.wear_suit, T.w_uniform, T.gloves, T.glasses, T.head, T.wear_mask, T.shoes))
		if(I && I.body_parts_covered)
			covered |= I.body_parts_covered
	return covered

/proc/check_covered_bodypart(mob/living/carbon/human/T, covered)
	for(var/obj/item/I in list(T.wear_suit, T.w_uniform, T.gloves, T.glasses, T.head, T.wear_mask, T.shoes))
		if(I && I.body_parts_covered & covered)
			return TRUE
	return FALSE

/proc/check_human_covering(mob/living/carbon/human/T, mob/living/user, covered)
	var/static/list/zone_by_clothing_part = list(
		BP_CHEST = UPPER_TORSO,
		BP_GROIN = LOWER_TORSO,
		BP_L_LEG = LEG_LEFT,
		BP_R_LEG = LEG_RIGHT,
		BP_L_ARM = ARM_LEFT,
		BP_R_ARM = ARM_RIGHT,
		BP_HEAD = HEAD,
		O_MOUTH = FACE,
		O_EYES = EYES,
	)

	var/zone = zone_by_clothing_part[user.get_targetzone()]
	if(!zone)
		return TRUE

	return !check_covered_bodypart(T, zone)

/proc/has_medical_hud(mob/living/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/clothing/glasses/G = H.glasses
	if(!G || !G.hud_types)
		return FALSE
	if((DATA_HUD_MEDICAL in G.hud_types) || (DATA_HUD_MEDICAL_ADV in G.hud_types))
		return TRUE
	return FALSE

/proc/clear_surgery_hud_hints(mob/living/user)
	if(!user.surgery_hud_images)
		return
	if(user.client)
		for(var/image/I in user.surgery_hud_images)
			user.client.images -= I
	user.surgery_hud_images = null

/proc/show_surgery_hud_hints(mob/living/user, mob/living/carbon/human/target, target_zone)
	clear_surgery_hud_hints(user)

	if(!has_medical_hud(user))
		return
	if(!ishuman(target))
		return

	// Collect all items nearby: surgeon's hands, adjacent turfs (floor, tables)
	var/list/nearby_items = list()
	if(user.l_hand)
		nearby_items += user.l_hand
	if(user.r_hand)
		nearby_items += user.r_hand
	for(var/turf/T in range(1, target))
		for(var/obj/item/I in T.contents)
			nearby_items += I
			// Check inside storage containers (surgical trays, bags, etc.)
			if(istype(I, /obj/item/weapon/storage))
				for(var/obj/item/SI in I.contents)
					nearby_items += SI
		// Also check items on tables/surfaces
		for(var/obj/structure/table/table in T.contents)
			for(var/obj/item/I in table.contents)
				nearby_items += I
				if(istype(I, /obj/item/weapon/storage))
					for(var/obj/item/SI in I.contents)
						nearby_items += SI

	// Collect applicable tool types from surgery steps
	var/list/tool_data = list() // assoc list: tool_type = quality

	for(var/datum/surgery_step/S in surgery_steps)
		var/step_usable = FALSE
		try
			step_usable = S.can_use(user, target, target_zone, null)
		catch
			continue
		if(!step_usable || !S.is_valid_mutantrace(target))
			continue
		if(!S.allowed_tools)
			continue
		for(var/tool_type in S.allowed_tools)
			var/quality = S.allowed_tools[tool_type]
			if(!tool_data[tool_type] || tool_data[tool_type] < quality)
				tool_data[tool_type] = quality

	if(!tool_data.len)
		return

	// Filter: only keep tool types that have a matching nearby item
	var/list/available_tools = list() // tool_type = obj/item reference (for icon)
	for(var/tool_type in tool_data)
		for(var/obj/item/I in nearby_items)
			if(istype(I, tool_type))
				available_tools[tool_type] = I
				break

	if(!available_tools.len)
		return

	user.surgery_hud_images = list()
	var/icon_count = available_tools.len
	var/start_x = -((icon_count - 1) * 10) / 2 // center the row of icons

	var/i = 0
	for(var/tool_type in available_tools)
		var/obj/item/real_tool = available_tools[tool_type]
		// Use the actual item's icon for more accurate representation
		var/image/hint = image(icon = real_tool.icon, loc = target, icon_state = real_tool.icon_state, layer = EMOTE_LAYER)
		hint.pixel_y = 34
		hint.pixel_x = start_x + (i * 20)
		hint.plane = ABOVE_LIGHTING_PLANE
		hint.transform = hint.transform.Scale(0.6, 0.6)
		hint.transform = hint.transform.Turn(-90)

		user.surgery_hud_images += hint
		user.client?.images += hint
		i++

/proc/do_surgery(mob/living/carbon/M, mob/living/user, obj/item/tool)
	checks_for_surgery(M, user, FALSE)
	var/target_zone = user.get_targetzone()
	var/covered
	if(ishuman(M))
		covered = get_human_covering(M)

	var/skillcheck = list(/datum/skill/surgery = SKILL_LEVEL_TRAINED)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.species.flags[IS_SYNTHETIC])
			skillcheck = list(/datum/skill/engineering = SKILL_LEVEL_TRAINED)

	if(!handle_fumbling(user, M, SKILL_TASK_AVERAGE, skillcheck, "<span class='notice'>You fumble around figuring out how to operate [M].</span>"))
		return

	for(var/datum/surgery_step/S in surgery_steps)
		//check, if target undressed for clothless operations
		if(S.clothless && ishuman(M) && !check_human_covering(M, user, covered))
			return FALSE

		//check if tool is right or close enough and if this step is possible
		if(S.tool_quality(tool) && S.can_use(user, M, target_zone, tool) && S.is_valid_mutantrace(M))
			if(!S.prepare_step(user, M, target_zone, tool))	//for some kind of checks
				return TRUE

			S.begin_step(user, M, target_zone, tool)		//...start on it
			var/step_duration = rand(S.min_duration, S.max_duration)

			//We had proper tools! (or RNG smiled.) and User did not move or change hands.
			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				if(!HAS_TRAIT(H, TRAIT_NO_PAIN) && !HAS_TRAIT(H, TRAIT_IMMOBILIZED))
					H.adjustHalLoss(25)
				if(prob(H.traumatic_shock) && !H.incapacitated(NONE))
					to_chat(user, "<span class='warning'>The patient is writhing in pain, this interferes with the operation!</span>")
					S.fail_step(user, H, target_zone, tool) //patient movements due to pain interfere with surgery
			if(user.mood_prob(S.tool_quality(tool)) && tool.use_tool(M,user, step_duration, volume=100, required_skills_override = S.required_skills, skills_speed_bonus = S.skills_speed_bonus) && user.get_targetzone() && target_zone == user.get_targetzone())
				S.end_step(user, M, target_zone, tool)		//finish successfully
			else if(tool.loc == user && user.Adjacent(M))		//or (also check for tool in hands and being near the target)
				S.fail_step(user, M, target_zone, tool)		//malpractice~
			else	// this failing silently was a pain.
				to_chat(user, "<span class='warning'>You must remain close to your patient to conduct surgery.</span>")

			if(ishuman(M))
				var/mob/living/carbon/human/H = M
				H.update_surgery()										//shows surgery results
				show_surgery_hud_hints(user, H, target_zone)
			return	TRUE	  												//don't want to do weapony things after surgery
	return FALSE

/proc/sort_surgeries()
	var/gap = surgery_steps.len
	var/swapped = 1
	while (gap > 1 || swapped)
		swapped = 0
		if(gap > 1)
			gap = round(gap / 1.247330950103979)
		if(gap < 1)
			gap = 1
		for(var/i = 1; gap + i <= surgery_steps.len; i++)
			var/datum/surgery_step/l = surgery_steps[i]		//Fucking hate
			var/datum/surgery_step/r = surgery_steps[gap+i]	//how lists work here
			if(l.priority < r.priority)
				surgery_steps.Swap(i, gap + i)
				swapped = 1

/datum/surgery_status
	var/plastic_new_name = null
	var/plasticsur = 0
	var/eyes = 0
	var/face = 0
	var/appendix = 0
	var/ribcage = 0
	var/skull = 0
	var/brain_cut = 0
	var/brain_fix = 0
	var/list/bodyparts = list() // Holds info about removed bodyparts

/datum/surgery_step/ipc
	can_infect = FALSE
	allowed_species = list(IPC)
	required_skills = list(/datum/skill/engineering = SKILL_LEVEL_TRAINED, /datum/skill/surgery = SKILL_LEVEL_NOVICE)
	skills_speed_bonus = -0.2
