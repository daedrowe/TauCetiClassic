/datum/component/ember_blocker
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/atom/movable/ember_blocker/blocker
	var/assigned_render_target
	var/added_keep_together = FALSE

/datum/component/ember_blocker/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/ember_blocker/RegisterWithParent()
	var/atom/movable/owner = parent
	added_keep_together = !(owner.appearance_flags & KEEP_TOGETHER)
	owner.appearance_flags |= KEEP_TOGETHER
	if(!owner.render_target)
		assigned_render_target = "ember_blocker_[REF(src)]"
		owner.render_target = assigned_render_target
	blocker = new
	blocker.render_source = owner.render_target
	owner.vis_contents += blocker

/datum/component/ember_blocker/UnregisterFromParent()
	clear_blocker()

/datum/component/ember_blocker/Destroy()
	clear_blocker()
	return ..()

/datum/component/ember_blocker/proc/clear_blocker()
	if(!blocker)
		return
	var/atom/movable/owner = parent
	owner.vis_contents -= blocker
	if(added_keep_together)
		owner.appearance_flags &= ~KEEP_TOGETHER
	if(assigned_render_target && owner.render_target == assigned_render_target)
		owner.render_target = null
	QDEL_NULL(blocker)
	assigned_render_target = null

/atom/movable/ember_blocker
	name = "ember blocker"
	plane = LIGHTING_EMBER_MASK_PLANE
	layer = FLOAT_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = KEEP_APART | KEEP_TOGETHER | RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | PIXEL_SCALE
	vis_flags = VIS_INHERIT_LAYER | VIS_INHERIT_ID
	color = COLOR_BLACK
