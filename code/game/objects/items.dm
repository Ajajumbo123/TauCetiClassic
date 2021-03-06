/obj/item
	name = "item"
	icon = 'icons/obj/items.dmi'
	var/image/blood_overlay = null //this saves our blood splatter overlay, which will be processed not to go over the edges of the sprite
	var/abstract = 0
	var/item_state = null
	var/lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	var/righthand_file = 'icons/mob/inhands/items_righthand.dmi'
	var/r_speed = 1.0
	var/health = null
	var/burn_point = null
	var/burning = null
	var/hitsound = null
	var/wet = 0
	var/w_class = 3.0
	var/can_embed = 1
	var/slot_flags = 0		//This is used to determine on which slots an item can fit.
	pass_flags = PASSTABLE
//	causeerrorheresoifixthis
	var/obj/item/master = null

	var/flags_pressure = 0
	var/heat_protection = 0 //flags which determine which body parts are protected from heat. Use the HEAD, UPPER_TORSO, LOWER_TORSO, etc. flags. See setup.dm
	var/cold_protection = 0 //flags which determine which body parts are protected from cold. Use the HEAD, UPPER_TORSO, LOWER_TORSO, etc. flags. See setup.dm
	var/max_heat_protection_temperature //Set this variable to determine up to which temperature (IN KELVIN) the item protects against heat damage. Keep at null to disable protection. Only protects areas set by heat_protection flags
	var/min_cold_protection_temperature //Set this variable to determine down to which temperature (IN KELVIN) the item protects against cold damage. 0 is NOT an acceptable number due to if(varname) tests!! Keep at null to disable protection. Only protects areas set by cold_protection flags

	var/datum/action/item_action/action = null
	var/action_button_name //It is also the text which gets displayed on the action button. If not set it defaults to 'Use [name]'. If it's not set, there'll be no button.
	var/action_button_is_hands_free = 0 //If 1, bypass the restrained, lying, and stunned checks action buttons normally test for

	//Since any item can now be a piece of clothing, this has to be put here so all items share it.
	var/flags_inv //This flag is used to determine when items in someone's inventory cover others. IE helmets making it so you can't see glasses, etc.
	var/item_color = null
	var/body_parts_covered = 0 //see setup.dm for appropriate bit flags
	//var/heat_transfer_coefficient = 1 //0 prevents all transfers, 1 is invisible
	var/gas_transfer_coefficient = 1 // for leaking gas from turf to mask and vice-versa (for masks right now, but at some point, i'd like to include space helmets)
	var/permeability_coefficient = 1 // for chemicals/diseases
	var/siemens_coefficient = 1 // for electrical admittance/conductance (electrocution checks and shit)
	var/slowdown = 0 // How much clothing is slowing you down. Negative values speeds you up
	var/canremove = 1 //Mostly for Ninja code at this point but basically will not allow the item to be removed if set to 0. /N
	var/armor = list(melee = 0, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 0, rad = 0)
	var/list/materials = list()
	var/list/allowed = null //suit storage stuff.
	var/list/can_be_placed_into = list(
		/obj/structure/table,
		/obj/structure/rack,
		/obj/structure/closet,
		/obj/item/weapon/storage,
		/obj/structure/safe,
		/obj/machinery/disposal,
		/obj/machinery/r_n_d/destructive_analyzer,
//		/obj/machinery/r_n_d/experimentor,
		/obj/machinery/autolathe
	)
	var/uncleanable = 0
	var/toolspeed = 1

	var/obj/item/device/uplink/hidden/hidden_uplink = null // All items can have an uplink hidden inside, just remember to add the triggers.

	/* Species-specific sprites, concept stolen from Paradise//vg/.
	ex:
	sprite_sheets = list(
		TAJARAN = 'icons/cat/are/bad'
		)
	If index term exists and icon_override is not set, this sprite sheet will be used.
	*/
	var/list/sprite_sheets = null
	var/icon_override = null  //Used to override hardcoded clothing dmis in human clothing proc.

	/* Species-specific sprite sheets for inventory sprites
	Works similarly to worn sprite_sheets, except the alternate sprites are used when the clothing/refit_for_species() proc is called.
	*/
	var/list/sprite_sheets_obj = null

/obj/item/proc/check_allowed_items(atom/target, not_inside, target_self)
	if(((src in target) && !target_self) || ((!istype(target.loc, /turf)) && (!istype(target, /turf)) && (not_inside)) || is_type_in_list(target, can_be_placed_into))
		return 0
	else
		return 1

/obj/item/device
	icon = 'icons/obj/device.dmi'

/obj/item/Destroy()
	flags &= ~DROPDEL // prevent recursive dels
	if(ismob(loc))
		var/mob/m = loc
		m.drop_from_inventory(src)
	return ..()

/obj/item/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return
		if(3.0)
			if (prob(5))
				qdel(src)
				return
		else
	return

/obj/item/blob_act()
	return

//user: The mob that is suiciding
//damagetype: The type of damage the item will inflict on the user
//BRUTELOSS = 1
//FIRELOSS = 2
//TOXLOSS = 4
//OXYLOSS = 8
//Output a creative message and then return the damagetype done
/obj/item/proc/suicide_act(mob/user)
	return

/obj/item/verb/move_to_top()
	set name = "Move To Top"
	set category = "Object"
	set src in oview(1)

	if(!istype(src.loc, /turf) || usr.stat || usr.restrained() )
		return

	var/turf/T = src.loc

	src.loc = null

	src.loc = T

/obj/item/examine(mob/user)
	..()
	var/size
	switch(src.w_class)
		if(1.0)
			size = "tiny"
		if(2.0)
			size = "small"
		if(3.0)
			size = "normal-sized"
		if(4.0)
			size = "bulky"
		if(5.0)
			size = "huge"
		else

	var/open_span  = "[src.wet ? "<span class='wet'>" : ""]"
	var/close_span = "[src.wet ? "</span>" : ""]"
	var/wet_status = "[src.wet ? " wet" : ""]"

	to_chat(user, "[open_span]It's a[wet_status] [size] item.[close_span]")

/obj/item/attack_hand(mob/user)
	if (!user || anchored)
		return

	if(HULK in user.mutations)//#Z2 Hulk nerfz!
		if(istype(src, /obj/item/weapon/melee/))
			if(src.w_class < 4)
				to_chat(user, "\red \The [src] is far too small for you to pick up.")
				return
		else if(istype(src, /obj/item/weapon/gun/))
			if(prob(20))
				user.say(pick(";RAAAAAAAARGH! WEAPON!", ";HNNNNNNNNNGGGGGGH! I HATE WEAPONS!!", ";GWAAAAAAAARRRHHH!", "NNNNNNNNGGGGGGGGUUUUUNNNNHH!", ";AAAAAAARRRGH!" ))
			user.visible_message("\blue [user] crushes \a [src] with hands.", "\blue You crush the [src].")
			qdel(src)
			//user << "\red \The [src] is far too small for you to pick up."
			return
		else if(istype(src, /obj/item/clothing/))
			if(prob(20))
				to_chat(user, "\red [pick("You are not interested in [src].", "This is nothing.", "Humans stuff...", "A cat? A scary cat...",
				"A Captain? Let's smash his skull! I don't like Captains!",
				"Awww! Such lovely doggy! BUT I HATE DOGGIES!!", "A woman... A lying woman! I love womans! Fuck womans...")]")
			return
		else if(istype(src, /obj/item/weapon/book/))
			to_chat(user, "\red A book! I LOVE BOOKS!!")
		else if(istype(src, /obj/item/weapon/reagent_containers/food))
			if(prob(20))
				to_chat(user, "\red I LOVE FOOD!!")
		else if(src.w_class < 4)
			to_chat(user, "\red \The [src] is far too small for you to pick up.")
			return

	if(istype(src.loc, /obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = src.loc
		S.remove_from_storage(src)

	src.throwing = 0
	if(src.loc == user)
		//canremove==0 means that object may not be removed. You can still wear it. This only applies to clothing. /N
		if(!src.canremove)
			return
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.wear_suit && istype(H.wear_suit, /obj/item/clothing/suit))
				var/obj/item/clothing/suit/V = H.wear_suit
				V.attack_reaction(H, REACTION_ITEM_TAKEOFF)
			if(istype(src, /obj/item/clothing/suit/space)) // If the item to be unequipped is a rigid suit
				if(!user.delay_clothing_u_equip(src))
					return 0
			else
				user.remove_from_mob(src)
		else
			user.remove_from_mob(src)

	else
		if(isliving(src.loc))
			return
		user.SetNextMove(CLICK_CD_RAPID)

		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.wear_suit && istype(H.wear_suit, /obj/item/clothing/suit))
				var/obj/item/clothing/suit/V = H.wear_suit
				V.attack_reaction(H, REACTION_ITEM_TAKE)

	if(QDELETED(src) || freeze_movement) // remove_from_mob() may remove DROPDEL items, so...
		return

	src.pickup(user)
	add_fingerprint(user)
	user.put_in_active_hand(src)
	return


/obj/item/attack_paw(mob/user)
	if (!user || anchored)
		return

	if(isalien(user)) // -- TLE
		var/mob/living/carbon/alien/A = user

		if(!A.has_fine_manipulation || w_class >= 4)
			if(src in A.contents) // To stop Aliens having items stuck in their pockets
				A.drop_from_inventory(src)
			to_chat(user, "Your claws aren't capable of such fine manipulation.")
			return

	if (istype(src.loc, /obj/item/weapon/storage))
		for(var/mob/M in range(1, src.loc))
			if (M.s_active == src.loc)
				if (M.client)
					M.client.screen -= src
	src.throwing = 0
	if (src.loc == user)
		//canremove==0 means that object may not be removed. You can still wear it. This only applies to clothing. /N
		if(istype(src, /obj/item/clothing) && !src:canremove)
			return
		else
			user.remove_from_mob(src)
	else
		if(istype(src.loc, /mob/living))
			return

		user.next_move = max(user.next_move+2,world.time + 2)

	if(QDELETED(src) || freeze_movement) // no item - no pickup, you dummy!
		return

	src.pickup(user)
	user.put_in_active_hand(src)
	return


/obj/item/attack_ai(mob/user)
	if (istype(src.loc, /obj/item/weapon/robot_module))
		//If the item is part of a cyborg module, equip it
		if(!isrobot(user))
			return
		var/mob/living/silicon/robot/R = user
		R.activate_module(src)
		R.hud_used.update_robot_modules_display()

// Due to storage type consolidation this should get used more now.
// I have cleaned it up a little, but it could probably use more.  -Sayu
/obj/item/attackby(obj/item/weapon/W, mob/user, params)
	if(istype(W, /obj/item/weapon/storage))
		var/obj/item/weapon/storage/S = W
		if(S.use_to_pickup)
			if(S.collection_mode) //Mode is set to collect all items on a tile and we clicked on a valid one.
				if(isturf(src.loc))
					var/list/rejections = list()
					var/success = 0
					var/failure = 0

					for(var/obj/item/I in src.loc)
						if(I.type in rejections) // To limit bag spamming: any given type only complains once
							continue
						if(!S.can_be_inserted(I))	// Note can_be_inserted still makes noise when the answer is no
							rejections += I.type	// therefore full bags are still a little spammy
							failure = 1
							continue
						success = 1
						S.handle_item_insertion(I, 1)	//The 1 stops the "You put the [src] into [S]" insertion message from being displayed.
					if(success && !failure)
						to_chat(user, "<span class='notice'>You put everything in [S].</span>")
					else if(success)
						to_chat(user, "<span class='notice'>You put some things in [S].</span>")
					else
						to_chat(user, "<span class='notice'>You fail to pick anything up with [S].</span>")

			else if(S.can_be_inserted(src))
				S.handle_item_insertion(src)
	return FALSE

/obj/item/throw_at(atom/target, range, speed, mob/thrower, spin = TRUE, diagonals_first = FALSE, datum/callback/callback)
	callback = CALLBACK(src, .proc/after_throw, callback) // Replace their callback with our own.
	. = ..(target, range, speed, thrower, spin, diagonals_first, callback)

/obj/item/proc/after_throw(datum/callback/callback)
	if (callback) //call the original callback
		. = callback.Invoke()

/obj/item/proc/talk_into(mob/M, text)
	return

/obj/item/proc/moved(mob/user, old_loc)
	return

// apparently called whenever an item is removed from a slot, container, or anything else.
/obj/item/proc/dropped(mob/user)
	if(DROPDEL & flags)
		qdel(src)

// called just as an item is picked up (loc is not yet changed)
/obj/item/proc/pickup(mob/user)
	return

// called when this item is removed from a storage item, which is passed on as S. The loc variable is already set to the new destination before this is called.
/obj/item/proc/on_exit_storage(obj/item/weapon/storage/S)
	return

// called when this item is added into a storage item, which is passed on as S. The loc variable is already set to the storage item.
/obj/item/proc/on_enter_storage(obj/item/weapon/storage/S)
	return

// called when "found" in pockets and storage items. Returns 1 if the search should end.
/obj/item/proc/on_found(mob/finder)
	return

// called after an item is placed in an equipment slot
// user is mob that equipped it
// slot uses the slot_X defines found in setup.dm
// for items that can be placed in multiple slots
// note this isn't called during the initial dressing of a player
/obj/item/proc/equipped(mob/user, slot)
	return

//the mob M is attempting to equip this item into the slot passed through as 'slot'. Return 1 if it can do this and 0 if it can't.
//If you are making custom procs but would like to retain partial or complete functionality of this one, include a 'return ..()' to where you want this to happen.
//Set disable_warning to 1 if you wish it to not give you outputs.
/obj/item/proc/mob_can_equip(M, slot, disable_warning = 0)
	if(!slot) return 0
	if(!M) return 0

	if(ishuman(M))
		//START HUMAN
		var/mob/living/carbon/human/H = M
		if(!H.has_bodypart_for_slot(slot))
			return 0
		//fat mutation
		if(istype(src, /obj/item/clothing/under) || istype(src, /obj/item/clothing/suit))
			if(FAT in H.mutations)
				//testing("[M] TOO FAT TO WEAR [src]!")
				if(!(flags & ONESIZEFITSALL))
					if(!disable_warning)
						to_chat(H, "\red You're too fat to wear the [name].")
					return 0

		switch(slot)
			if(slot_l_hand)
				if(H.l_hand)
					return 0
				return 1
			if(slot_r_hand)
				if(H.r_hand)
					return 0
				return 1
			if(slot_wear_mask)
				if(H.wear_mask)
					return 0
				if( !(slot_flags & SLOT_MASK) )
					return 0
				return 1
			if(slot_back)
				if(H.back)
					return 0
				if( !(slot_flags & SLOT_BACK) )
					return 0
				return 1
			if(slot_wear_suit)
				if(H.wear_suit)
					return 0
				if( !(slot_flags & SLOT_OCLOTHING) )
					return 0
				return 1
			if(slot_gloves)
				if(H.gloves)
					return 0
				if( !(slot_flags & SLOT_GLOVES) )
					return 0
				return 1
			if(slot_shoes)
				if(H.shoes)
					return 0
				if( !(slot_flags & SLOT_FEET) )
					return 0
				return 1
			if(slot_belt)
				if(H.belt)
					return 0
				if(!H.w_uniform)
					if(!disable_warning)
						to_chat(H, "\red You need a jumpsuit before you can attach this [name].")
					return 0
				if( !(slot_flags & SLOT_BELT) )
					return
				return 1
			if(slot_glasses)
				if(H.glasses)
					return 0
				if( !(slot_flags & SLOT_EYES) )
					return 0
				return 1
			if(slot_head)
				if(H.head)
					return 0
				if( !(slot_flags & SLOT_HEAD) )
					return 0
				return 1
			if(slot_l_ear)
				if(H.l_ear)
					return 0
				if( w_class < 2	)
					return 1
				if( !(slot_flags & SLOT_EARS) )
					return 0
				if( (slot_flags & SLOT_TWOEARS) && H.r_ear )
					return 0
				return 1
			if(slot_r_ear)
				if(H.r_ear)
					return 0
				if( w_class < 2 )
					return 1
				if( !(slot_flags & SLOT_EARS) )
					return 0
				if( (slot_flags & SLOT_TWOEARS) && H.l_ear )
					return 0
				return 1
			if(slot_w_uniform)
				if(H.w_uniform)
					return 0
				if( !(slot_flags & SLOT_ICLOTHING) )
					return 0
				return 1
			if(slot_wear_id)
				if(H.wear_id)
					return 0
				if(!H.w_uniform)
					if(!disable_warning)
						to_chat(H, "\red You need a jumpsuit before you can attach this [name].")
					return 0
				if( !(slot_flags & SLOT_ID) )
					return 0
				return 1
			if(slot_l_store)
				if(H.l_store)
					return 0
				if(!H.w_uniform)
					if(!disable_warning)
						to_chat(H, "\red You need a jumpsuit before you can attach this [name].")
					return 0
				if(slot_flags & SLOT_DENYPOCKET)
					return 0
				if( w_class <= 2 || (slot_flags & SLOT_POCKET) )
					return 1
			if(slot_r_store)
				if(H.r_store)
					return 0
				if(!H.w_uniform)
					if(!disable_warning)
						to_chat(H, "\red You need a jumpsuit before you can attach this [name].")
					return 0
				if(slot_flags & SLOT_DENYPOCKET)
					return 0
				if( w_class <= 2 || (slot_flags & SLOT_POCKET) )
					return 1
				return 0
			if(slot_s_store)
				if(H.s_store)
					return 0
				if(!H.wear_suit)
					if(!disable_warning)
						to_chat(H, "\red You need a suit before you can attach this [name].")
					return 0
				if(!H.wear_suit.allowed)
					if(!disable_warning)
						to_chat(usr, "You somehow have a suit with no defined allowed items for suit storage, stop that.")
					return 0
				if( istype(src, /obj/item/device/pda) || istype(src, /obj/item/weapon/pen) || is_type_in_list(src, H.wear_suit.allowed) )
					return 1
				return 0
			if(slot_handcuffed)
				if(H.handcuffed)
					return 0
				if(!istype(src, /obj/item/weapon/handcuffs))
					return 0
				return 1
			if(slot_legcuffed)
				if(H.legcuffed)
					return 0
				if(!istype(src, /obj/item/weapon/legcuffs))
					return 0
				return 1
			if(slot_in_backpack)
				if (H.back && istype(H.back, /obj/item/weapon/storage/backpack))
					var/obj/item/weapon/storage/backpack/B = H.back
					if(B.contents.len < B.storage_slots && w_class <= B.max_w_class)
						return 1
				return 0
			if(slot_tie)
				if(!H.w_uniform)
					if(!disable_warning)
						to_chat(H, "<span class='warning'>You need a jumpsuit before you can attach this [name].</span>")
					return FALSE
				var/obj/item/clothing/under/uniform = H.w_uniform
				if(uniform.accessories.len && !uniform.can_attach_accessory(src))
					if (!disable_warning)
						to_chat(H, "<span class='warning'>You already have an accessory of this type attached to your [uniform].</span>")
					return FALSE
				if( !(slot_flags & SLOT_TIE) )
					return FALSE
				return TRUE
		return 0 //Unsupported slot
		//END HUMAN

	else if(ismonkey(M))
		//START MONKEY
		var/mob/living/carbon/monkey/MO = M
		switch(slot)
			if(slot_l_hand)
				if(MO.l_hand)
					return 0
				return 1
			if(slot_r_hand)
				if(MO.r_hand)
					return 0
				return 1
			if(slot_wear_mask)
				if(MO.wear_mask)
					return 0
				if( !(slot_flags & SLOT_MASK) )
					return 0
				return 1
			if(slot_back)
				if(MO.back)
					return 0
				if( !(slot_flags & SLOT_BACK) )
					return 0
				return 1
		return 0 //Unsupported slot

		//END MONKEY
	else if(isIAN(M))
		var/mob/living/carbon/ian/C = M
		switch(slot)
			if(slot_head)
				if(C.head)
					return FALSE
				if(istype(src, /obj/item/clothing/mask/facehugger))
					return TRUE
				if( !(slot_flags & SLOT_HEAD) )
					return FALSE
				return TRUE
			if(slot_mouth)
				if(C.mouth)
					return FALSE
				return TRUE
			if(slot_neck)
				if(C.neck)
					return FALSE
				if(istype(src, /obj/item/weapon/handcuffs))
					return TRUE
				if( !(slot_flags & SLOT_ID) )
					return FALSE
				return TRUE
			if(slot_back)
				if(C.back)
					return FALSE
				if(istype(src, /obj/item/clothing/suit/armor/vest))
					return TRUE
				if( !(slot_flags & SLOT_BACK) )
					return FALSE
				return TRUE
		return FALSE

/obj/item/verb/verb_pickup()
	set src in oview(1)
	set category = "Object"
	set name = "Pick up"

	if(!(usr)) //BS12 EDIT
		return
	if(!usr.canmove || usr.stat || usr.restrained() || !Adjacent(usr))
		return
	if((!istype(usr, /mob/living/carbon)) || (istype(usr, /mob/living/carbon/brain)))//Is humanoid, and is not a brain
		to_chat(usr, "\red You can't pick things up!")
		return
	if( usr.stat || usr.restrained() )//Is not asleep/dead and is not restrained
		to_chat(usr, "\red You can't pick things up!")
		return
	if(src.anchored) //Object isn't anchored
		to_chat(usr, "\red You can't pick that up!")
		return
	if(!usr.hand && usr.r_hand) //Right hand is not full
		to_chat(usr, "\red Your right hand is full.")
		return
	if(usr.hand && usr.l_hand) //Left hand is not full
		to_chat(usr, "\red Your left hand is full.")
		return
	if(!istype(src.loc, /turf)) //Object is on a turf
		to_chat(usr, "\red You can't pick that up!")
		return
	//All checks are done, time to pick it up!
	usr.UnarmedAttack(src)
	return


//This proc is executed when someone clicks the on-screen UI button. To make the UI button show, set the 'icon_action_button' to the icon_state of the image of the button in screen1_action.dmi
//The default action is attack_self().
//Checks before we get to here are: mob is alive, mob is not restrained, paralyzed, asleep, resting, laying, item is on the mob.
/obj/item/proc/ui_action_click()
	attack_self(usr)

/obj/item/proc/IsReflect(def_zone, hol_dir, hit_dir) //This proc determines if and at what% an object will reflect energy projectiles if it's in l_hand,r_hand or wear_suit
	return FALSE

/obj/item/proc/Get_shield_chance()
	return 0

/obj/item/proc/get_loc_turf()
	var/atom/L = loc
	while(L && !istype(L, /turf/))
		L = L.loc
	return loc

/obj/item/proc/eyestab(mob/living/carbon/M, mob/living/carbon/user)

	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(((H.head && H.head.flags & HEADCOVERSEYES) || (H.wear_mask && H.wear_mask.flags & MASKCOVERSEYES) || (H.glasses && H.glasses.flags & GLASSESCOVERSEYES)))
			// you can't stab someone in the eyes wearing a mask!
			to_chat(user, "\red You're going to need to remove the eye covering first.")
			return

	var/mob/living/carbon/monkey/Mo = M
	if(istype(Mo) && ( \
			(Mo.wear_mask && Mo.wear_mask.flags & MASKCOVERSEYES) \
		))
		// you can't stab someone in the eyes wearing a mask!
		to_chat(user, "\red You're going to need to remove the eye covering first.")
		return

	if(istype(M, /mob/living/carbon/alien) || istype(M, /mob/living/carbon/slime))//Aliens don't have eyes./N     slimes also don't have eyes!
		to_chat(user, "\red You cannot locate any eyes on this creature!")
		return

	user.attack_log += "\[[time_stamp()]\]<font color='red'> Attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>"
	M.attack_log += "\[[time_stamp()]\]<font color='orange'> Attacked by [user.name] ([user.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)])</font>"
	msg_admin_attack("[user.name] ([user.ckey]) attacked [M.name] ([M.ckey]) with [src.name] (INTENT: [uppertext(user.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)") //BS12 EDIT ALG

	src.add_fingerprint(user)
	//if((CLUMSY in user.mutations) && prob(50))
	//	M = user
		/*
		to_chat(M, "\red You stab yourself in the eye.")
		M.sdisabilities |= BLIND
		M.weakened += 4
		M.adjustBruteLoss(10)
		*/
	if(M != user)
		for(var/mob/O in (viewers(M) - user - M))
			O.show_message("\red [M] has been stabbed in the eye with [src] by [user].", 1)
		to_chat(M, "\red [user] stabs you in the eye with [src]!")
		to_chat(user, "\red You stab [M] in the eye with [src]!")
	else
		user.visible_message( \
			"\red [user] has stabbed themself with [src]!", \
			"\red You stab yourself in the eyes with [src]!" \
		)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/obj/item/organ/internal/eyes/IO = H.organs_by_name[O_EYES]
		IO.damage += rand(3,4)
		if(IO.damage >= IO.min_bruised_damage)
			if(H.stat != DEAD)
				if(IO.robotic <= 1) //robot eyes bleeding might be a bit silly
					to_chat(H, "\red Your eyes start to bleed profusely!")
			if(prob(50))
				if(H.stat != DEAD)
					to_chat(H, "\red You drop what you're holding and clutch at your eyes!")
					H.drop_item()
				H.eye_blurry += 10
				H.Paralyse(1)
				H.Weaken(4)
			if (IO.damage >= IO.min_broken_damage)
				if(H.stat != DEAD)
					to_chat(H, "\red You go blind!")
		var/obj/item/organ/external/BP = H.bodyparts_by_name[BP_HEAD]
		BP.take_damage(7)
	else
		M.take_bodypart_damage(7)
	M.eye_blurry += rand(3,4)
	return

/obj/item/clean_blood()
	. = ..()
	if(uncleanable)
		return
	if(blood_overlay)
		overlays.Remove(blood_overlay)
	if(istype(src, /obj/item/clothing/gloves))
		var/obj/item/clothing/gloves/G = src
		G.transfer_blood = 0


/obj/item/add_blood(mob/living/carbon/human/M)
	if (!..())
		return 0

	if(istype(src, /obj/item/weapon/melee/energy))
		return

	//if we haven't made our blood_overlay already
	if( !blood_overlay )
		generate_blood_overlay()

	//apply the blood-splatter overlay if it isn't already in there
	if(!blood_DNA.len)
		blood_overlay.color = blood_color
		overlays += blood_overlay

	//if this blood isn't already in the list, add it

	if(blood_DNA[M.dna.unique_enzymes])
		return 0 //already bloodied with this blood. Cannot add more.
	blood_DNA[M.dna.unique_enzymes] = M.dna.b_type
	return 1 //we applied blood to the item

var/global/list/items_blood_overlay_by_type = list()
/obj/item/proc/generate_blood_overlay()
	if(blood_overlay)
		return

	var/image/IMG = items_blood_overlay_by_type[type]
	if(IMG)
		blood_overlay = IMG
	else
		var/icon/ICO = new /icon(icon, icon_state)
		ICO.Blend(new /icon('icons/effects/blood.dmi', rgb(255, 255, 255)), ICON_ADD) // fills the icon_state with white (except where it's transparent)
		ICO.Blend(new /icon('icons/effects/blood.dmi', "itemblood"), ICON_MULTIPLY)   // adds blood and the remaining white areas become transparant
		IMG = image("icon" = ICO)
		items_blood_overlay_by_type[type] = IMG
		blood_overlay = IMG

/obj/item/proc/showoff(mob/user)
	for (var/mob/M in view(user))
		M.show_message("[user] holds up [src]. <a HREF=?src=\ref[M];lookitem=\ref[src]>Take a closer look.</a>",1)

/mob/living/carbon/verb/showoff()
	set name = "Show Held Item"
	set category = "Object"

	var/obj/item/I = get_active_hand()
	if(I && !I.abstract)
		I.showoff(src)
