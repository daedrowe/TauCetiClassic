/*
 * Targeted social emotes. Opened with Ctrl+Shift+LMB on a living mob, or typed as '*hug Иванов'.
 * Both entries go through try_interact(), so the gate order is the same for either of them.
 */

// Shared between every interaction, but only spent when one is aimed at somebody: the emotes
// that predate the panel keep their own cooldown when used the old way, without a target.
#define INTERACTION_COOLDOWN_GROUP "interaction"
#define INTERACTION_COOLDOWN (4 SECONDS)

/datum/emote/human/interaction
	// English label and tooltip for the interaction panel.
	var/name
	var/description

	// 1 means contact (checked with Adjacent()), anything greater is checked with view().
	var/interaction_range = 1

	// Set on emotes that predate the panel: they still work as a plain '*wave' with no target.
	var/message_1p_solo
	var/message_3p_solo

	message_type = SHOWMSG_VISUAL
	required_stat = CONSCIOUS
	require_usable_hand = TRUE
	blocklist_traits = list(ELEMENT_TRAIT_ZOMBIE)

// Whether the target's body allows this interaction at all. Dispatched by the mob tree, not by type checks.
/datum/emote/human/interaction/proc/can_interact_with(mob/living/target)
	return TRUE

/datum/emote/human/interaction/proc/in_interaction_range(mob/user, mob/living/target)
	if(interaction_range <= 1)
		return user.Adjacent(target)

	return target in view(interaction_range, user)

/datum/emote/human/interaction/proc/has_free_hand(mob/user)
	for(var/slot in user.get_hand_slots())
		if(!slot)
			return TRUE

	return FALSE

// Own side -> distance -> target. The first failure wins, the target one never explains itself.
/datum/emote/human/interaction/proc/get_interaction_block_reason(mob/user, mob/living/target, intentional)
	if(target == user)
		return "Сейчас не получится."

	if(!target && !message_1p_solo)
		return "Укажите, к кому обращаетесь: *[key] Иванов."

	var/reason = get_block_reason(user, intentional)
	if(reason)
		return reason

	// No target means this is a pre-panel emote used the way it always was, so it keeps
	// the gate it always had: can_emote and nothing else.
	if(!target)
		return null

	if(LAZYACCESS(user.next_emote_use, INTERACTION_COOLDOWN_GROUP) > world.time)
		return "Вы не можете делать это так часто, передохните."

	if(user.incapacitated())
		return "Вы не можете сделать это в текущем состоянии."

	if(user.is_busy(show_warning = FALSE))
		return "Вы заняты другим делом."

	if(require_usable_hand && !has_free_hand(user))
		return "У вас заняты руки."

	if(!in_interaction_range(user, target))
		return "Слишком далеко."

	if(!can_interact_with(target))
		return "Сейчас не получится."

	return null

/datum/emote/human/interaction/proc/try_interact(mob/user, mob/living/target, intentional = TRUE)
	var/reason = get_interaction_block_reason(user, target, intentional)
	if(reason)
		if(intentional)
			to_chat(user, "<span class='notice'>[reason]</span>")
		return FALSE

	do_emote(user, key, intentional, target)
	if(target)
		LAZYSET(user.next_emote_use, INTERACTION_COOLDOWN_GROUP, world.time + INTERACTION_COOLDOWN)
	SEND_SIGNAL(user, COMSIG_MOB_EMOTE, key, intentional)
	return TRUE

/datum/emote/human/interaction/proc/get_interaction_candidates(mob/user)
	var/list/candidates = list()
	for(var/mob/living/L in view(interaction_range, user))
		if(L == user)
			continue
		if(!in_interaction_range(user, L))
			continue
		candidates += L

	return candidates

// Text entry: the rest of the line is a substring of the target's visible name.
/datum/emote/human/interaction/proc/try_interact_by_name(mob/user, target_name, intentional = TRUE)
	if(!target_name)
		return try_interact(user, null, intentional)

	var/list/matches = list()
	for(var/mob/living/L in get_interaction_candidates(user))
		if(findtext(L.name, target_name))
			matches += L

	if(!length(matches))
		if(intentional)
			to_chat(user, "<span class='notice'>Здесь нет никого с таким именем.</span>")
		return FALSE

	if(length(matches) > 1)
		if(intentional)
			var/list/names = list()
			for(var/mob/living/L as anything in matches)
				names += L.name
			to_chat(user, "<span class='notice'>Уточните, кто именно: [jointext(names, ", ")].</span>")
		return FALSE

	return try_interact(user, matches[1], intentional)

/datum/emote/human/interaction/get_emote_message_1p(mob/user, mob/living/target)
	if(!target)
		return "<i>[message_1p_solo]</i>"

	return "<i>[replacetext(message_1p, "%target%", "[target]")]</i>"

/datum/emote/human/interaction/get_emote_message_3p(mob/user, mob/living/target)
	if(!target)
		return message_3p_solo

	var/msg = ..()
	if(!msg)
		return null

	return replacetext(msg, "%target%", "[target]")

/datum/emote/human/interaction/send_emote_messages(mob/user, mob/living/target, msg_1p, msg_3p, deaf_impaired_msg, range, list/ignored_mobs = observer_list)
	var/msg_2p = target ? get_emote_message_2p(user, target) : null
	if(msg_2p)
		ignored_mobs = ignored_mobs + target
		show_target_message(user, target, msg_2p)

	return ..(user, target, msg_1p, msg_3p, deaf_impaired_msg, range, ignored_mobs)

/datum/emote/human/interaction/proc/show_target_message(mob/user, mob/living/target, msg_2p)
	if(interaction_range <= 1)
		target.show_message("<b>[user]</b> <i>[msg_2p]</i>", SHOWMSG_VISUAL, "<b>Кто-то</b> <i>[msg_2p]</i>", SHOWMSG_FEEL)
	else
		target.show_message("<b>[user]</b> <i>[msg_2p]</i>", SHOWMSG_VISUAL)

	if(!(target.sdisabilities & BLIND) && !target.blinded && !target.paralysis)
		target.show_runechat_message(user, null, get_emote_message_3p(user, target), null, SHOWMSG_VISUAL)


/*
 * Within arm's reach.
 */
/datum/emote/human/interaction/hug
	key = "hug"
	name = "Hug"
	description = "Wrap your arms around them."

	message_1p = "Вы обнимаете %target%."
	message_2p = "обнимает вас."
	message_3p = "обнимает %target%."

/datum/emote/human/interaction/handshake
	key = "handshake"
	name = "Handshake"
	description = "Shake their hand. They have to be able to answer."

	message_1p = "Вы жмёте руку %target%."
	message_2p = "жмёт вам руку."
	message_3p = "жмёт руку %target%."

/datum/emote/human/interaction/handshake/can_interact_with(mob/living/target)
	return target.stat == CONSCIOUS && target.is_usable_arm()

/datum/emote/human/interaction/headpat
	key = "headpat"
	name = "Headpat"
	description = "Pat them on the head."

	message_1p = "Вы гладите %target% по голове."
	message_2p = "гладит вас по голове."
	message_3p = "гладит %target% по голове."

/datum/emote/human/interaction/headpat/can_interact_with(mob/living/target)
	return target.is_usable_head()

/datum/emote/human/interaction/pat
	key = "pat"
	name = "Pat"
	description = "Pat them on the shoulder."

	message_1p = "Вы хлопаете %target% по плечу."
	message_2p = "хлопает вас по плечу."
	message_3p = "хлопает %target% по плечу."

/datum/emote/human/interaction/pat/can_interact_with(mob/living/target)
	return target.is_usable_arm()

/datum/emote/human/interaction/highfive
	key = "highfive"
	name = "High Five"
	description = "Slap your palm against theirs. They have to be able to answer."

	message_1p = "Вы даёте пять %target%."
	message_2p = "даёт вам пять."
	message_3p = "даёт пять %target%."
	message_impaired_reception = "Вы слышите хлопок."

	sound = list('sound/misc/clap_1.ogg', 'sound/misc/clap_2.ogg', 'sound/misc/clap_3.ogg', 'sound/misc/clap_4.ogg')
	soundless_for_mute = FALSE

/datum/emote/human/interaction/highfive/get_sound(mob/user, intentional)
	return pick(sound)

/datum/emote/human/interaction/highfive/can_interact_with(mob/living/target)
	return target.stat == CONSCIOUS && target.is_usable_arm()

/datum/emote/human/interaction/fistbump
	key = "fistbump"
	name = "Fistbump"
	description = "Bump your fist against theirs. They have to be able to answer."

	message_1p = "Вы стукаетесь кулаками с %target%."
	message_2p = "стукается с вами кулаками."
	message_3p = "стукается кулаками с %target%."

/datum/emote/human/interaction/fistbump/can_interact_with(mob/living/target)
	return target.stat == CONSCIOUS && target.is_usable_arm()

/datum/emote/human/interaction/kiss
	key = "kiss"
	name = "Kiss on the Cheek"
	description = "Kiss them on the cheek."

	message_1p = "Вы целуете %target% в щёку."
	message_2p = "целует вас в щёку."
	message_3p = "целует %target% в щёку."

	require_usable_hand = FALSE

/datum/emote/human/interaction/kiss/can_interact_with(mob/living/target)
	return target.is_usable_head()


/*
 * Across the room.
 */
/datum/emote/human/interaction/beckon
	key = "beckon"
	name = "Beckon"
	description = "Wave them over from a distance."

	message_1p = "Вы маните %target% рукой."
	message_2p = "манит вас рукой."
	message_3p = "манит %target% рукой."

	interaction_range = 7

/datum/emote/human/interaction/point
	key = "point"
	name = "Point"
	description = "Point at them."

	message_1p = "Вы указываете на %target%."
	message_2p = "указывает на вас."
	message_3p = "указывает на %target%."

	interaction_range = 7

/datum/emote/human/interaction/thumbsup
	key = "thumbsup"
	name = "Thumbs Up"
	description = "Show them a thumbs up."

	message_1p = "Вы показываете %target% большой палец."
	message_2p = "показывает вам большой палец."
	message_3p = "показывает %target% большой палец."

	interaction_range = 7

/datum/emote/human/interaction/cheer
	key = "cheer"
	name = "Cheer"
	description = "Cheer them on."

	message_1p = "Вы подбадриваете %target%."
	message_2p = "подбадривает вас."
	message_3p = "подбадривает %target%."

	interaction_range = 7

/datum/emote/human/interaction/applaud
	key = "applaud"
	name = "Applaud"
	description = "Applaud them."

	message_1p = "Вы аплодируете %target%."
	message_2p = "аплодирует вам."
	message_3p = "аплодирует %target%."
	message_impaired_reception = "Вы слышите аплодисменты."

	interaction_range = 7

	sound = list('sound/misc/clap_1.ogg', 'sound/misc/clap_2.ogg', 'sound/misc/clap_3.ogg', 'sound/misc/clap_4.ogg')
	soundless_for_mute = FALSE

/datum/emote/human/interaction/applaud/get_sound(mob/user, intentional)
	return pick(sound)


/*
 * Emotes that existed before the panel. Without a target they behave exactly as they always did,
 * which is also what keeps them safe in the radial emote panel: all three have an icon_state in
 * icons/misc/emotes.dmi and are swept into it.
 */
/datum/emote/human/interaction/wave
	key = "wave"
	name = "Wave"
	description = "Wave at them."

	message_1p = "Вы машете %target%."
	message_2p = "машет вам."
	message_3p = "машет %target%."

	message_1p_solo = "Вы машете рукой."
	message_3p_solo = "машет рукой."

	interaction_range = 7

/datum/emote/human/interaction/salute
	key = "salute"
	name = "Salute"
	description = "Salute them."

	message_1p = "Вы салютуете %target%."
	message_2p = "салютует вам."
	message_3p = "салютует %target%."

	message_1p_solo = "Вы салютуете."
	message_3p_solo = "салютует."

	interaction_range = 7

	sound = 'sound/misc/salute.ogg'
	soundless_for_mute = FALSE

/datum/emote/human/interaction/bow
	key = "bow"
	name = "Bow"
	description = "Bow to them."

	message_1p = "Вы кланяетесь %target%."
	message_2p = "кланяется вам."
	message_3p = "кланяется %target%."

	message_1p_solo = "Вы кланяетесь."
	message_3p_solo = "кланяется."

	interaction_range = 7
	require_usable_hand = FALSE

#undef INTERACTION_COOLDOWN_GROUP
#undef INTERACTION_COOLDOWN
