/proc/emissive_appearance(icon, icon_state = "", layer = FLOAT_LAYER, dir = null)
	var/mutable_appearance/emissive = mutable_appearance(icon, icon_state, layer)
	if(!isnull(dir))
		emissive.dir = dir
	emissive.appearance_flags |= KEEP_APART
	emissive.add_overlay(emissive_mask_appearance(icon, icon_state, dir = dir))
	return emissive

/proc/emissive_mask_appearance(icon, icon_state = "", layer = FLOAT_LAYER, dir = null)
	var/mutable_appearance/mask = mutable_appearance(icon, icon_state, layer, EMISSIVE_MASK_PLANE)
	if(!isnull(dir))
		mask.dir = dir
	mask.appearance_flags = RESET_COLOR | KEEP_APART
	var/static/list/mask_color = list(0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,255, 1,1,1,0)
	mask.color = mask_color
	return mask
