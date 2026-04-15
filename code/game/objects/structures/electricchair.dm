
/obj/structure/stool/bed/chair/e_chair
	name = "electric chair"
	desc = "Looks absolutely SHOCKING!"
	icon_state = "echair0"
	var/on = 0
	var/obj/item/assembly/shock_kit/part = null
	var/last_time = 1.0
	/// Whether the chair is in electrotherapy (cult deconversion) mode
	var/therapy_mode = FALSE
	var/list/roles_to_deconvert = list(SHADOW_THRALL, CULTIST)
	var/on_cooldown = FALSE

/obj/structure/stool/bed/chair/e_chair/atom_init()
	. = ..()
	add_overlay(image('icons/obj/objects.dmi', src, "echair_over", MOB_LAYER + 1, dir))

/obj/structure/stool/bed/chair/e_chair/attackby(obj/item/weapon/W, mob/user)
	if(iswrenching(W))
		var/obj/structure/stool/bed/chair/C = new /obj/structure/stool/bed/chair(loc)
		playsound(src, 'sound/items/Ratchet.ogg', VOL_EFFECTS_MASTER)
		C.set_dir(dir)
		if(part)
			part.loc = loc
			part.master = null
			part = null
		qdel(src)
		return
	if(istype(W, /obj/item/device/multitool))
		therapy_mode = !therapy_mode
		on = 0
		icon_state = "echair0"
		playsound(src, 'sound/items/screwdriver2.ogg', VOL_EFFECTS_MASTER)
		user.visible_message(
			"<span class='notice'>[user] перенастраивает [src] в режим [therapy_mode ? "электротерапии" : "электрического стула"].</span>",
			"<span class='notice'>Вы переключаете [src] в режим [therapy_mode ? "электротерапии" : "электрического стула"].</span>"
		)
		name = therapy_mode ? "electrotherapy chair" : initial(name)
		desc = therapy_mode ? "Latest development in the field of brainwashing. This thing is almost guaranteed to bring back loyalty to your crew!" : initial(desc)
		return
	return

/obj/structure/stool/bed/chair/e_chair/AltClick(mob/user)
	if(therapy_mode)
		if(!user.Adjacent(src))
			return
		if(!buckled_mob)
			var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
			s.set_up(5, 1, get_turf(src))
			s.start()
			return
		deconvert(user, buckled_mob)
	else
		rotate()

/obj/structure/stool/bed/chair/e_chair/proc/deconvert(mob/user, mob/living/carbon/human/target)
	if(!ishuman(target) || on_cooldown)
		return
	target.electrocute_act(50)
	if(target.mind)
		for(var/role in roles_to_deconvert)
			var/datum/role/R = target.mind.GetRole(role)
			if(!R)
				continue
			if(prob(90))
				R.Deconvert()
		if(prob(50))
			target.adjustBrainLoss(rand(30, 90))
		if(prob(50))
			var/obj/item/organ/internal/brain/IO = target.organs_by_name[O_BRAIN]
			if(istype(IO))
				IO.damage += rand(10, 50)
		if(prob(50))
			target.ear_deaf += 20
		if(prob(50))
			target.eye_blind += 20

		playsound(src, 'sound/items/surgery/defib_zap.ogg', VOL_EFFECTS_MASTER)
		on_cooldown = TRUE
		addtimer(CALLBACK(src, PROC_REF(reset_cooldown)), 1 MINUTE, TIMER_UNIQUE)

/obj/structure/stool/bed/chair/e_chair/proc/reset_cooldown()
	if(on_cooldown)
		on_cooldown = FALSE
		visible_message("<span class='notice'>[bicon(src)] [src] has recharged.</span>")
		var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
		s.set_up(5, 1, get_turf(src))
		s.start()

/obj/structure/stool/bed/chair/e_chair/verb/toggle()
	set name = "Toggle Electric Chair"
	set category = "Object"
	set src in oview(1)

	if(therapy_mode)
		to_chat(usr, "<span class='warning'>Этот стул настроен на терапию, а не на казни.</span>")
		return

	if(on)
		on = 0
		icon_state = "echair0"
	else
		on = 1
		icon_state = "echair1"
	to_chat(usr, "<span class='notice'>You switch [on ? "on" : "off"] [src].</span>")
	return

/obj/structure/stool/bed/chair/e_chair/rotate()
	..()
	cut_overlays()
	add_overlay(image('icons/obj/objects.dmi', src, "echair_over", MOB_LAYER + 1, dir))	//there's probably a better way of handling this, but eh. -Pete
	return

/obj/structure/stool/bed/chair/e_chair/proc/shock()
	if(!on || therapy_mode)
		return
	if(last_time + 50 > world.time)
		return
	last_time = world.time

	// special power handling
	var/area/A = get_area(src)
	if(!isarea(A))
		return
	if(!A.powered(STATIC_EQUIP))
		return
	A.use_power(STATIC_EQUIP, 5000)
	var/light = A.power_light
	A.updateicon()

	flick("echair1", src)
	var/datum/effect/effect/system/spark_spread/s = new /datum/effect/effect/system/spark_spread
	s.set_up(12, 1, src)
	s.start()
	if(buckled_mob)
		buckled_mob.burn_skin(85)
		to_chat(buckled_mob, "<span class='danger'>You feel a deep shock course through your body!</span>")
		sleep(1)
		buckled_mob.burn_skin(85)
		buckled_mob.Stun(600)
	visible_message("<span class='danger'>The electric chair went off!</span>", "<span class='danger'>You hear a deep sharp shock!</span>")

	A.power_light = light
	A.updateicon()
	return
