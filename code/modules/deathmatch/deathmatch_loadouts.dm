/datum/outfit/deathmatch
	name = null
	var/display_name = ""
	var/desc = ""

/datum/outfit/deathmatch/assistant
	name = "Дезматч: Ассистент"
	display_name = "Ассистент"
	desc = "Серый комбинезон и тулбокс. Классика."
	uniform = /obj/item/clothing/under/color/grey
	shoes = /obj/item/clothing/shoes/black
	back = /obj/item/weapon/storage/backpack
	r_hand = /obj/item/weapon/melee/baton
	l_hand = /obj/item/weapon/storage/toolbox/mechanical
	gloves = /obj/item/clothing/gloves/black
	suit = /obj/item/clothing/suit/armor/vest/durathread
	l_pocket = /obj/item/weapon/legcuffs/bola

/datum/outfit/deathmatch/security
	name = "Дезматч: Охранник"
	display_name = "Охранник"
	desc = "Бронежилет, шлем, дубинка и дробовик."
	uniform = /obj/item/clothing/under/rank/security
	shoes = /obj/item/clothing/shoes/boots
	gloves = /obj/item/clothing/gloves/black
	suit = /obj/item/clothing/suit/armor/riot
	head = /obj/item/clothing/head/helmet/riot
	l_hand = /obj/item/weapon/melee/baton
	r_hand = /obj/item/weapon/gun/projectile/shotgun/combat
	belt = /obj/item/weapon/storage/belt/security
	backpack_contents = list(/obj/item/ammo_box/magazine/internal/shotcom = 3)

/datum/outfit/deathmatch/operative
	name = "Дезматч: Оперативник"
	display_name = "Оперативник"
	desc = "Снаряжение синдиката — арбалет и энерго-меч."
	uniform = /obj/item/clothing/under/syndicate
	shoes = /obj/item/clothing/shoes/boots/combat
	gloves = /obj/item/clothing/gloves/combat
	suit = /obj/item/clothing/suit/armor/tactical
	glasses = /obj/item/clothing/glasses/thermal
	l_hand = /obj/item/weapon/gun/energy/crossbow
	r_pocket = /obj/item/weapon/melee/energy/sword
	back = /obj/item/weapon/storage/backpack

/datum/outfit/deathmatch/engineer
	name = "Дезматч: Инженер"
	display_name = "Инженер"
	desc = "Каска, огнетушитель и сварочный аппарат."
	uniform = /obj/item/clothing/under/rank/engineer
	shoes = /obj/item/clothing/shoes/orange
	gloves = /obj/item/clothing/gloves/yellow
	suit = /obj/item/clothing/suit/bomb_suit
	head = /obj/item/clothing/head/bomb_hood
	glasses = /obj/item/clothing/glasses/meson
	back = /obj/item/weapon/storage/backpack/industrial
	l_hand = /obj/item/weapon/weldingtool/largetank
	r_hand = /obj/item/weapon/fireaxe

/datum/outfit/deathmatch/doctor
	name = "Дезматч: Доктор"
	display_name = "Доктор"
	desc = "Халат, циркулярка и ретрактор."
	uniform = /obj/item/clothing/under/rank/medical
	shoes = /obj/item/clothing/shoes/white
	suit = /obj/item/clothing/suit/armor/vest
	gloves = /obj/item/clothing/gloves/latex
	l_hand = /obj/item/weapon/circular_saw
	r_hand = /obj/item/weapon/retractor
	back = /obj/item/weapon/storage/firstaid/tactical
	belt = /obj/item/weapon/storage/pouch/medical_supply/combat

/datum/outfit/deathmatch/gladiator
	name = "Дезматч: Гладиатор"
	display_name = "Гладиатор"
	desc = "Шлем гладиатора и энергетический меч."
	uniform = /obj/item/clothing/under/gladiator
	head = /obj/item/clothing/head/helmet/gladiator
	shoes = /obj/item/clothing/shoes/boots
	gloves = /obj/item/clothing/gloves/combat
	l_hand = /obj/item/weapon/melee/energy/sword
	suit = /obj/item/clothing/suit/armor/vest

/datum/outfit/deathmatch/gladiator/post_equip(mob/living/carbon/human/human_target, visuals_only)
	var/obj/item/weapon/melee/energy/sword/energy_sword = locate() in human_target
	if(energy_sword)
		energy_sword.attack_self(human_target)

/datum/outfit/deathmatch/arena
	name = "Дезматч: Арена"
	display_name = "Боец арены"
	desc = "Чёрный комбинезон и ботинки."
	uniform = /obj/item/clothing/under/color/black
	shoes = /obj/item/clothing/shoes/boots
	gloves = /obj/item/clothing/gloves/combat
	glasses = /obj/item/clothing/glasses/aviator_black

/datum/outfit/deathmatch/hos
	name = "Дезматч: Глава СБ"
	display_name = "Глава СБ"
	desc = "Полное снаряжение Главы Безопасности."
	uniform = /obj/item/clothing/under/rank/head_of_security
	shoes = /obj/item/clothing/shoes/boots
	gloves = /obj/item/clothing/gloves/black
	glasses = /obj/item/clothing/glasses/sunglasses/hud/sechud
	suit = /obj/item/clothing/suit/armor/hos
	head = /obj/item/clothing/accessory/armor/dermal
	belt = /obj/item/weapon/storage/belt/security
	l_hand = /obj/item/weapon/gun/energy/gun/hos
	r_pocket = /obj/item/weapon/melee/baton
	l_pocket = /obj/item/weapon/handcuffs
	back = /obj/item/weapon/storage/backpack/security

/datum/outfit/deathmatch/captain
	name = "Дезматч: Капитан"
	display_name = "Капитан"
	desc = "Капитанский лазер, сабля и бронежилет."
	uniform = /obj/item/clothing/under/rank/captain
	shoes = /obj/item/clothing/shoes/brown
	head = /obj/item/clothing/head/caphat
	glasses = /obj/item/clothing/glasses/sunglasses
	suit = /obj/item/clothing/suit/armor/vest
	l_hand = /obj/item/weapon/gun/energy/laser/selfcharging/captain
	r_hand = /obj/item/weapon/melee/energy/sword
	gloves = /obj/item/clothing/gloves/combat
	back = /obj/item/weapon/storage/backpack

/datum/outfit/deathmatch/captain/post_equip(mob/living/carbon/human/human_target, visuals_only)
	var/obj/item/weapon/melee/energy/sword/energy_sword = locate() in human_target
	if(energy_sword)
		energy_sword.attack_self(human_target)

/datum/outfit/deathmatch/detective
	name = "Дезматч: Детектив"
	display_name = "Детектив"
	desc = "Револьвер, плащ и шляпа."
	uniform = /obj/item/clothing/under/det
	suit = /obj/item/clothing/suit/storage/det_suit
	shoes = /obj/item/clothing/shoes/brown
	head = /obj/item/clothing/head/det_hat
	glasses = /obj/item/clothing/glasses/sunglasses/noir
	gloves = /obj/item/clothing/gloves/black
	l_hand = /obj/item/weapon/gun/projectile/revolver/detective
	back = /obj/item/weapon/storage/backpack
	backpack_contents = list(/obj/item/ammo_box/speedloader/c38 = 3)

/datum/outfit/deathmatch/cmo
	name = "Дезматч: Главврач"
	display_name = "Главврач"
	desc = "Шприцемёт, продвинутая аптечка и химикаты."
	uniform = /obj/item/clothing/under/rank/chief_medical_officer
	suit = /obj/item/clothing/suit/storage/labcoat/cmo
	shoes = /obj/item/clothing/shoes/white
	gloves = /obj/item/clothing/gloves/latex
	glasses = /obj/item/clothing/glasses/hud/health
	l_hand = /obj/item/weapon/gun/syringe
	r_hand = /obj/item/weapon/storage/firstaid/adv
	back = /obj/item/weapon/storage/backpack/medic
	backpack_contents = list(
		/obj/item/weapon/reagent_containers/glass/bottle/inaprovaline = 1,
		/obj/item/weapon/reagent_containers/syringe = 3,
	)

/datum/outfit/deathmatch/nukeop
	name = "Дезматч: Ядерный Оперативник"
	display_name = "Ядерный Оперативник"
	desc = "Снаряжение ядерного оперативника. C-20r и скафандр."
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/space/rig/syndi
	head = /obj/item/clothing/head/helmet/space/rig/syndi
	shoes = /obj/item/clothing/shoes/boots/combat
	gloves = /obj/item/clothing/gloves/combat
	glasses = /obj/item/clothing/glasses/night
	l_hand = /obj/item/weapon/gun/projectile/automatic/c20r
	back = /obj/item/weapon/storage/backpack
	backpack_contents = list(/obj/item/ammo_box/magazine/c20r = 3)
	belt = /obj/item/weapon/storage/belt/military

/datum/outfit/deathmatch/miner
	name = "Дезматч: Шахтёр"
	display_name = "Шахтёр"
	desc = "Шахтёрский скафандр, бур и дубинка."
	uniform = /obj/item/clothing/under/rank/miner
	suit = /obj/item/clothing/suit/space/rig/mining
	head = /obj/item/clothing/head/helmet/space/rig/mining
	shoes = /obj/item/clothing/shoes/boots
	gloves = /obj/item/clothing/gloves/black
	glasses = /obj/item/clothing/glasses/meson
	l_hand = /obj/item/weapon/pickaxe/drill
	r_hand = /obj/item/weapon/melee/classic_baton
	back = /obj/item/weapon/storage/backpack/industrial
