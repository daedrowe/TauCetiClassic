/obj/item/weapon/implant/hemoadaptive
	name = "hemoadaptive marrow stimulator"
	cases = list("хемоадаптивный стимулятор", "хемоадаптивного стимулятора", "хемоадаптивному стимулятору", "хемоадаптивный стимулятор", "хемоадаптивным стимулятором", "хемоадаптивном стимуляторе")
	desc = "Экспериментальный имплант, стимулирующий костный мозг для перестройки антигенной структуры крови. Процесс крайне болезненный."
	icon_state = "implant"
	legal = FALSE
	var/converting = FALSE
	var/cooldown_time = 0

/datum/action/item_action/implant/hemoadaptive
	name = "Активировать хемоадаптивный стимулятор"

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
	var/target_type = tgui_input_list(H, "Выберите целевую группу крови:", "Хемоадаптивный стимулятор", blood_types)
	if(!target_type)
		return
	if(target_type == H.dna.b_type)
		to_chat(H, "<span class='notice'>Это уже ваша текущая группа крови.</span>")
		return

	converting = TRUE
	to_chat(H, "<span class='boldwarning'>Стимулятор активирован. Процесс перестройки организма запущен...</span>")
	to_chat(H, "<span class='userdanger'>Вы чувствуете, как нечто раздирает ваши кости изнутри!</span>")
	H.emote("scream")

	// 3 minute conversion process, damage every 10 seconds (18 ticks)
	var/ticks = 0
	var/max_ticks = 18
	while(ticks < max_ticks && converting && implanted_mob && !QDELETED(src))
		sleep(10 SECONDS)
		ticks++

		if(!implanted_mob || QDELETED(src))
			converting = FALSE
			return

		H = implanted_mob
		if(!ishuman(H) || H.stat == DEAD)
			converting = FALSE
			to_chat(H, "<span class='warning'>Процесс конвертации прерван.</span>")
			return

		// Pain and damage (Reduced for implant)
		H.adjustCloneLoss(1.5)
		H.adjustToxLoss(1)
		H.radiation += 1

		if(prob(20))
			H.emote("scream")
		if(prob(10))
			H.vomit()
		if(prob(5))
			to_chat(H, "<span class='userdanger'>Болезненные спазмы пронзают ваше тело!</span>")
			H.Weaken(2)

		// Progress messages
		switch(ticks)
			if(6)
				to_chat(H, "<span class='warning'>Вы чувствуете странную пульсацию в венах...</span>")
			if(12)
				to_chat(H, "<span class='warning'>Процесс перестройки близится к завершению...</span>")

	if(!implanted_mob || QDELETED(src) || !ishuman(implanted_mob))
		converting = FALSE
		return

	H = implanted_mob
	// Apply blood type change
	H.dna.b_type = target_type
	H.fixblood(FALSE)

	converting = FALSE
	cooldown_time = world.time + 5 MINUTES

	to_chat(H, "<span class='warning'>Процесс завершён. Боль постепенно отступает.</span>")
	to_chat(H, "<span class='warning'>Вы чувствуете себя истощённым...</span>")
