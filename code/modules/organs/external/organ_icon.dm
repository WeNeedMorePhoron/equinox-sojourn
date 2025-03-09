var/global/list/limb_icon_cache = list()

/obj/item/organ/external/set_dir()
	return

/obj/item/organ/external/proc/compile_icon()
	cut_overlays()
	 // This is a kludge, only one icon has more than one generation of children though.
	for(var/obj/item/organ/external/organ in contents)
		if(organ.children && organ.children.len)
			for(var/obj/item/organ/external/child in organ.children)
				add_overlay(child.mob_icon)
		add_overlay(organ.mob_icon)

/obj/item/organ/external/proc/sync_colour_to_human(var/mob/living/carbon/human/human)
	skin_tone = null
	skin_col = null
	hair_col = null
	if(BP_IS_ROBOTIC(src))
		return
	if(!human.form) //TODO FIX THIS
		return //Do nothing because we have no idea what to do.
	if(form && human.form && form.name != human.form.name)
		return
	if(!isnull(human.s_tone) && (human.form.appearance_flags & HAS_SKIN_TONE | DEFAULT_APPEARANCE_FLAGS))
		skin_tone = human.s_tone
	if(human.form.appearance_flags & HAS_SKIN_COLOR)
		skin_col = human.skin_color
	hair_col = human.hair_color

/obj/item/organ/external/proc/sync_colour_to_dna()
	skin_tone = null
	skin_col = null
	hair_col = null
	if(BP_IS_ROBOTIC(src))
		return
	if(!isnull(dna.GetUIValue(DNA_UI_SKIN_TONE)) && (form.appearance_flags & HAS_SKIN_TONE))
		skin_tone = dna.GetUIValue(DNA_UI_SKIN_TONE)
	if(form.appearance_flags & HAS_SKIN_COLOR)
		skin_col = rgb(dna.GetUIValue(DNA_UI_SKIN_R), dna.GetUIValue(DNA_UI_SKIN_G), dna.GetUIValue(DNA_UI_SKIN_B))
	hair_col = rgb(dna.GetUIValue(DNA_UI_HAIR_R),dna.GetUIValue(DNA_UI_HAIR_G),dna.GetUIValue(DNA_UI_HAIR_B))

/obj/item/organ/external/proc/get_cache_key()
	var/part_key = ""

	if(!appearance_test.get_species_sprite)
		part_key += "forced"
	else
		if(BP_IS_ROBOTIC(src))
			part_key += "ROBOTIC"
		else if(status & ORGAN_MUTATED)
			part_key += "Mutated"
		else if(status & ORGAN_DEAD)
			part_key += "Dead"
		else
			part_key += "Normal"
		part_key += "[form.form_key]"

	if(!appearance_test.colorize_organ)
		part_key += "no_color"

	part_key += "[dna.GetUIState(DNA_UI_GENDER)]"
	part_key += "[skin_tone]"
	part_key += skin_col
	part_key += model

	if(!appearance_test.special_update)
		for(var/obj/item/organ/internal/eyes/I in internal_organs)
			part_key += I.get_cache_key()

	// EQUINOX EDIT START - integrates bodymarkings into the icon caching system
	for(var/M in markings)
		part_key += "[M][markings[M]["color"]]"
	// EQUINOX EDIT END /////

	return part_key

/obj/item/organ/external/head/sync_colour_to_human(var/mob/living/carbon/human/human)
	..()
	for(var/obj/item/organ/internal/eyes/eyes in owner.organ_list_by_process(OP_EYES))
		eyes.update_colour()

/obj/item/organ/external/head/removed_mob()
	update_icon(1)
	..()

/obj/item/organ/external/head/update_icon()

	..()
	if(!appearance_test.special_update)
		return mob_icon

	cut_overlays()
	if(!owner || !owner.species)
		return

	if(owner.species.has_process[OP_EYES])
		for(var/obj/item/organ/internal/eyes/eyes in owner.organ_list_by_process(OP_EYES))
			mob_icon.add_overlay(eyes.get_icon())

	if(owner.lip_style && (form && (form.appearance_flags & HAS_LIPS)))
		var/icon/lip_icon = new/icon(owner.form.face, "lips[owner.lip_style]")
		mob_icon.add_overlay(lip_icon)

	if(owner.f_style && !(owner.head && (owner.head.flags_inv & BLOCKHAIR)))
		var/datum/sprite_accessory/facial_hair_style = GLOB.facial_hair_styles_list[owner.f_style]
		if(facial_hair_style && (!facial_hair_style.species_allowed || (form.get_bodytype() in facial_hair_style.species_allowed)))
			var/mutable_appearance/facial = mutable_appearance(facial_hair_style.icon, facial_hair_style.icon_state)
			facial.color = owner.facial_color
			add_overlay(facial)
	if(owner.h_style && !(owner.head && (owner.head.flags_inv & BLOCKHEADHAIR)))
		var/datum/sprite_accessory/hair_style = GLOB.hair_styles_list[owner.h_style]
		if(hair_style && (!hair_style.species_allowed || (form.get_bodytype() in hair_style.species_allowed)))
			var/mutable_appearance/hair = mutable_appearance(hair_style.icon, hair_style.icon_state)
			hair.color = hair_col
			add_overlay(hair)

	return mob_icon

/obj/item/organ/external/update_icon(regenerate = 0)
	var/gender = "_m"

	overlays.Cut()	// Equinox edit - Clears out existing bodymarkings

	if(!appearance_test.get_species_sprite)
		icon = 'icons/mob/human_races/r_human.dmi'
	else
		if(src.force_icon)
			icon = src.force_icon
		else if(!form && !dna)
			icon = 'icons/mob/human_races/r_human_white.dmi'
		else if(BP_IS_ROBOTIC(src))
			icon = 'icons/mob/human_races/cyberlimbs/generic.dmi'
		else if(status & ORGAN_MUTATED)
			icon = form.deform
		else
			icon = form.base

	if(appearance_test.simple_setup)
		gender = owner.gender == FEMALE ? "_f" : "_m"
		icon_state = "[organ_tag][gender]"
	else
		if (dna && dna.GetUIState(DNA_UI_GENDER))
			gender = "_f"
		else if(owner && owner.gender == FEMALE)
			gender = "_f"
		if(!("[organ_tag][gender][is_stump()?"_s":""]" in icon_states(icon)))
			gender = ""

		icon_state = "[organ_tag][gender][is_stump()?"_s":""]"

	mob_icon = mutable_appearance(icon, icon_state)

	if(!is_stump())
		for(var/subicon in additional_limb_parts)
			var/subgender = gender
			if(!("[subicon][subgender]" in icon_states(icon)))
				subgender = ""
			if("[subicon][subgender]" in icon_states(icon))
				var/mutable_appearance/L = mutable_appearance(icon, "[subicon][subgender]")
				mob_icon.add_overlay(L)

	if(appearance_test.colorize_organ)
		if(status & ORGAN_DEAD)
			mob_icon.color = rgb(10, 50, 0, 0.7)
		if(skin_col)
			mob_icon.color *= skin_col
		else if(skin_tone)
			if(skin_tone >= 0)
				mob_icon.color += rgb(skin_tone, skin_tone, skin_tone)
			else
				mob_icon.color -= rgb(-skin_tone,  -skin_tone,  -skin_tone)

	// EQUINOX EDIT START - furry - apply bodymarkings
	for(var/M in markings)
		var/datum/sprite_accessory/marking/mark_style = markings[M]["datum"]
		var/mutable_appearance/mark_s = mutable_appearance(mark_style.icon, "[mark_style.icon_state]-[organ_tag]")
		var/mutable_appearance/mark_splice //temporary var to facilitate splicing together feet sprites into leg sprites where relevant

	// Horrible hackjob to botch together hands and feet into their parent limbs where relevant
		if(organ_tag == BP_L_LEG && (BP_L_FOOT in mark_style.body_parts))
			mark_splice = mutable_appearance(mark_style.icon, "[mark_style.icon_state]-l_foot")
		else if(organ_tag == BP_R_LEG && (BP_R_FOOT in mark_style.body_parts))
			mark_splice = mutable_appearance(mark_style.icon, "[mark_style.icon_state]-r_foot")
		else if(organ_tag == BP_L_ARM && (BP_L_HAND in mark_style.body_parts))
			mark_splice = mutable_appearance(mark_style.icon, "[mark_style.icon_state]-l_hand")
		else if(organ_tag == BP_R_ARM && (BP_R_HAND in mark_style.body_parts))
			mark_splice = mutable_appearance(mark_style.icon, "[mark_style.icon_state]-r_hand")

		if(mark_splice && mark_s)
			mark_s.add_overlay(mark_splice)

		if(mark_style.blend == ICON_ADD)
			mark_s.color = color_to_full_rgba_matrix(markings[M]["color"])
		else
			mark_s.color = markings[M]["color"]

		add_overlay(mark_s) //So when it's not on your body, it has icons
		alpha = nonsolid ? 180 : 255
		mob_icon.add_overlay(mark_s) //So when it's on your body, it has icons
		return mob_icon

/obj/item/organ/external/proc/get_icon()
	update_icon()
	return mob_icon
