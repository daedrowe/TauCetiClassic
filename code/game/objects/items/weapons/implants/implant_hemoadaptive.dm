/obj/item/weapon/implant/hemoadaptive
	name = "hemoadaptive marrow stimulator"
	cases = list("хемоадаптивный стимулятор", "хемоадаптивного стимулятора", "хемоадаптивному стимулятору", "хемоадаптивный стимулятор", "хемоадаптивным стимулятором", "хемоадаптивном стимуляторе")
	desc = "Экспериментальный имплант, стимулирующий костный мозг для перестройки антигенной структуры крови. Процесс крайне болезненный."
	icon_state = "implant"
	legal = FALSE
	var/converting = FALSE
	var/cooldown_time = 0

	item_action_types = list(/datum/action/item_action/implant/hemoadaptive)

/datum/action/item_action/implant/hemoadaptive
	name = "Активировать хемоадаптивный стимулятор"

/datum/action/item_action/implant/hemoadaptive/Activate()
	var/obj/item/weapon/implant/hemoadaptive/I = target
	I.use_implant()

/obj/item/weapon/implant/hemoadaptive/inject(mob/living/carbon/C, def_zone, safe_inject)
	. = ..()
	add_item_actions(C)

/obj/item/weapon/implant/hemoadaptive/activate()
	. = ..()
	if(!implanted_mob || !ishuman(implanted_mob))
		return
	if(converting)
		to_chat(implanted_mob, "<span class='warning'>Стимулятор уже работает! Подождите завершения процесса.</span>")
		return
	if(world.time < cooldown_time)
		to_chat(implanted_mob, "<span class='warning'>Стимулятор перезаряжается. Подождите.</span>")
		return

	var/list/blood_types = list(
		BLOOD_O_PLUS, BLOOD_O_MINUS,
		BLOOD_A_PLUS, BLOOD_A_MINUS,
		BLOOD_B_PLUS, BLOOD_B_MINUS,
		BLOOD_AB_PLUS, BLOOD_AB_MINUS
	)

	var/mob/living/carbon/human/H = implanted_mob
	var/target_type = pick(blood_types)
	if(target_type == H.dna.b_type)
		target_type = pick(blood_types - H.dna.b_type)

	converting = TRUE
	to_chat(H, "<span class='boldwarning'>Стимулятор активирован. Процесс перестройки организма запущен...</span>")
	to_chat(H, "<span class='userdanger'>Вы чувствуете, как нечто раздирает ваши кости изнутри!</span>")
	H.emote("scream")

	var/ticks = 0
	var/max_ticks = 10
	while(ticks < max_ticks && converting && implanted_mob && !QDELETED(src))
		sleep(5 SECONDS)
		ticks++

		if(!implanted_mob || QDELETED(src))
			converting = FALSE
			return

		H = implanted_mob
		if(!ishuman(H) || H.stat == DEAD)
			converting = FALSE
			to_chat(H, "<span class='warning'>Процесс конвертации прерван.</span>")
			return

		H.adjustBruteLoss(3)
		H.adjustHalLoss(10)

		if(prob(20))
			H.emote("scream")
		if(prob(10))
			H.vomit()

		switch(ticks)
			if(6)
				to_chat(H, "<span class='warning'>Вы чувствуете странную пульсацию в венах...</span>")
			if(8)
				to_chat(H, "<span class='warning'>Процесс перестройки близится к завершению...</span>")

	if(!implanted_mob || QDELETED(src) || !ishuman(implanted_mob))
		converting = FALSE
		return

	H = implanted_mob
	H.dna.b_type = target_type
	
	var/list/transplanted_SE
	for(var/obj/item/organ/external/BP in H.bodyparts)
		if(BP.stored_SE)
			transplanted_SE = BP.stored_SE
			break
	
	if(transplanted_SE)
		H.dna.SE = transplanted_SE.Copy()
		H.dna.UpdateSE()
		domutcheck(H)

	H.fixblood(FALSE)

	converting = FALSE
	cooldown_time = world.time + 5 MINUTES

	to_chat(H, "<span class='warning'>Процесс завершён. Боль постепенно отступает.</span>")
	to_chat(H, "<span class='warning'>Вы чувствуете себя истощённым...</span>")
