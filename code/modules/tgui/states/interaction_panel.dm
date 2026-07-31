/**
 * tgui state: interaction_panel_state
 *
 * Delegates to the panel itself: the window lives as long as its target
 * stays in the initiator's view.
 */

var/global/datum/tgui_state/interaction_panel/interaction_panel_state = new

/datum/tgui_state/interaction_panel/can_use_topic(src_object, mob/user)
	var/datum/interaction_panel/panel = src_object
	if(!istype(panel))
		return UI_CLOSE

	return panel.get_ui_status(user)
