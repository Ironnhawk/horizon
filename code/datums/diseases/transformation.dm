/datum/disease/transformation
	name = "Transformation"
	max_stages = 5
	spread_text = "Acute"
	spread_flags = DISEASE_SPREAD_SPECIAL
	cure_text = "A coder's love (theoretical)."
	agent = "Shenanigans"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/alien)
	severity = DISEASE_SEVERITY_BIOHAZARD
	stage_prob = 5
	visibility_flags = HIDDEN_SCANNER|HIDDEN_PANDEMIC
	disease_flags = CURABLE
	var/list/stage1 = list("You feel unremarkable.")
	var/list/stage2 = list("You feel boring.")
	var/list/stage3 = list("You feel utterly plain.")
	var/list/stage4 = list("You feel white bread.")
	var/list/stage5 = list("Oh the humanity!")
	var/new_form = /mob/living/carbon/human
	var/bantype
	var/transformed_antag_datum //Do we add a specific antag datum once the transformation is complete?

/datum/disease/transformation/Copy()
	var/datum/disease/transformation/D = ..()
	D.stage1 = stage1.Copy()
	D.stage2 = stage2.Copy()
	D.stage3 = stage3.Copy()
	D.stage4 = stage4.Copy()
	D.stage5 = stage5.Copy()
	D.new_form = D.new_form
	return D


/datum/disease/transformation/stage_act(delta_time, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if (length(stage1) && DT_PROB(stage_prob, delta_time))
				to_chat(affected_mob, pick(stage1))
		if(2)
			if (length(stage2) && DT_PROB(stage_prob, delta_time))
				to_chat(affected_mob, pick(stage2))
		if(3)
			if (length(stage3) && DT_PROB(stage_prob * 2, delta_time))
				to_chat(affected_mob, pick(stage3))
		if(4)
			if (length(stage4) && DT_PROB(stage_prob * 2, delta_time))
				to_chat(affected_mob, pick(stage4))
		if(5)
			do_disease_transformation(affected_mob)


/datum/disease/transformation/proc/do_disease_transformation(mob/living/affected_mob)
	if(istype(affected_mob, /mob/living/carbon) && affected_mob.stat != DEAD)
		if(length(stage5))
			to_chat(affected_mob, pick(stage5))
		if(QDELETED(affected_mob))
			return
		if(affected_mob.notransform)
			return
		affected_mob.notransform = 1
		for(var/obj/item/W in affected_mob.get_equipped_items(TRUE))
			affected_mob.dropItemToGround(W)
		for(var/obj/item/I in affected_mob.held_items)
			affected_mob.dropItemToGround(I)
		var/mob/living/new_mob = new new_form(affected_mob.loc)
		if(istype(new_mob))
			if(bantype && is_banned_from(affected_mob.ckey, bantype))
				replace_banned_player(new_mob)
			new_mob.set_combat_mode(TRUE)
			if(affected_mob.mind)
				affected_mob.mind.transfer_to(new_mob)
			else
				new_mob.key = affected_mob.key
		if(transformed_antag_datum)
			new_mob.mind.add_antag_datum(transformed_antag_datum)
		new_mob.name = affected_mob.real_name
		new_mob.real_name = new_mob.name
		qdel(affected_mob)

/datum/disease/transformation/proc/replace_banned_player(mob/living/new_mob) // This can run well after the mob has been transferred, so need a handle on the new mob to kill it if needed.
	set waitfor = FALSE

	var/list/mob/dead/observer/candidates = pollCandidatesForMob("Do you want to play as [affected_mob.real_name]?", bantype, bantype, 50, affected_mob)
	if(LAZYLEN(candidates))
		var/mob/dead/observer/C = pick(candidates)
		to_chat(affected_mob, SPAN_USERDANGER("Your mob has been taken over by a ghost! Appeal your job ban if you want to avoid this in the future!"))
		message_admins("[key_name_admin(C)] has taken control of ([key_name_admin(affected_mob)]) to replace a jobbanned player.")
		affected_mob.ghostize(0)
		affected_mob.key = C.key
	else
		to_chat(new_mob, SPAN_USERDANGER("Your mob has been claimed by death! Appeal your job ban if you want to avoid this in the future!"))
		new_mob.death()
		if (!QDELETED(new_mob))
			new_mob.ghostize(can_reenter_corpse = FALSE)
			new_mob.key = null

/datum/disease/transformation/jungle_fever
	name = "Jungle Fever"
	cure_text = "Death."
	cures = list(/datum/reagent/medicine/adminordrazine)
	spread_text = "Monkey Bites"
	spread_flags = DISEASE_SPREAD_SPECIAL
	viable_mobtypes = list(/mob/living/carbon/human)
	permeability_mod = 1
	cure_chance = 0.5
	disease_flags = CAN_CARRY|CAN_RESIST
	desc = "Monkeys with this disease will bite humans, causing humans to mutate into a monkey."
	severity = DISEASE_SEVERITY_BIOHAZARD
	stage_prob = 2
	visibility_flags = NONE
	agent = "Kongey Vibrion M-909"
	new_form = /mob/living/carbon/human/species/monkey
	bantype = ROLE_MONKEY


	stage1 = list()
	stage2 = list()
	stage3 = list()
	stage4 = list(SPAN_WARNING("Your back hurts."), SPAN_WARNING("You breathe through your mouth."),
					SPAN_WARNING("You have a craving for bananas."), SPAN_WARNING("Your mind feels clouded."))
	stage5 = list(SPAN_WARNING("You feel like monkeying around."))

/datum/disease/transformation/jungle_fever/do_disease_transformation(mob/living/carbon/affected_mob)
	if(affected_mob.mind && !IS_INFECTED_MONKEY(affected_mob.mind))
		affected_mob.mind.add_antag_datum(/datum/antagonist/monkey)
		affected_mob.monkeyize()
		ADD_TRAIT(affected_mob, TRAIT_VENTCRAWLER_ALWAYS, type)


/datum/disease/transformation/jungle_fever/stage_act(delta_time, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(2)
			if(DT_PROB(1, delta_time))
				to_chat(affected_mob, SPAN_NOTICE("Your [pick("back", "arm", "leg", "elbow", "head")] itches."))
		if(3)
			if(DT_PROB(2, delta_time))
				to_chat(affected_mob, SPAN_DANGER("You feel a stabbing pain in your head."))
				affected_mob.add_confusion(10)
		if(4)
			if(DT_PROB(1.5, delta_time))
				affected_mob.say(pick("Eeek, ook ook!", "Eee-eeek!", "Eeee!", "Ungh, ungh."), forced = "jungle fever")


/datum/disease/transformation/jungle_fever/cure()
	affected_mob.mind.remove_antag_datum(/datum/antagonist/monkey)
	..()

/datum/disease/transformation/jungle_fever/monkeymode
	visibility_flags = HIDDEN_SCANNER|HIDDEN_PANDEMIC
	disease_flags = CAN_CARRY //no vaccines! no cure!

/datum/disease/transformation/jungle_fever/monkeymode/after_add()
	if(affected_mob && !IS_MONKEY_LEADER(affected_mob.mind))
		visibility_flags = NONE



/datum/disease/transformation/robot

	name = "Robotic Transformation"
	cure_text = "An injection of copper."
	cures = list(/datum/reagent/copper)
	cure_chance = 2.5
	agent = "R2D2 Nanomachines"
	desc = "This disease, actually acute nanomachine infection, converts the victim into a cyborg."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list()
	stage2 = list("Your joints feel stiff.", SPAN_DANGER("Beep...boop.."))
	stage3 = list(SPAN_DANGER("Your joints feel very stiff."), "Your skin feels loose.", SPAN_DANGER("You can feel something move...inside."))
	stage4 = list(SPAN_DANGER("Your skin feels very loose."), SPAN_DANGER("You can feel... something...inside you."))
	stage5 = list(SPAN_DANGER("Your skin feels as if it's about to burst off!"))
	new_form = /mob/living/silicon/robot
	infectable_biotypes = MOB_ORGANIC|MOB_UNDEAD|MOB_ROBOTIC
	bantype = "Cyborg"


/datum/disease/transformation/robot/stage_act(delta_time, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(3)
			if (DT_PROB(4, delta_time))
				affected_mob.say(pick("Beep, boop", "beep, beep!", "Boop...bop"), forced = "robotic transformation")
			if (DT_PROB(2, delta_time))
				to_chat(affected_mob, SPAN_DANGER("You feel a stabbing pain in your head."))
				affected_mob.Unconscious(40)
		if(4)
			if (DT_PROB(10, delta_time))
				affected_mob.say(pick("beep, beep!", "Boop bop boop beep.", "kkkiiiill mmme", "I wwwaaannntt tttoo dddiiieeee..."), forced = "robotic transformation")


/datum/disease/transformation/xeno

	name = "Xenomorph Transformation"
	cure_text = "Spaceacillin & Glycerol"
	cures = list(/datum/reagent/medicine/spaceacillin, /datum/reagent/glycerol)
	cure_chance = 2.5
	agent = "Rip-LEY Alien Microbes"
	desc = "This disease changes the victim into a xenomorph."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list()
	stage2 = list("Your throat feels scratchy.", SPAN_DANGER("Kill..."))
	stage3 = list(SPAN_DANGER("Your throat feels very scratchy."), "Your skin feels tight.", SPAN_DANGER("You can feel something move...inside."))
	stage4 = list(SPAN_DANGER("Your skin feels very tight."), SPAN_DANGER("Your blood boils!"), SPAN_DANGER("You can feel... something...inside you."))
	stage5 = list(SPAN_DANGER("Your skin feels as if it's about to burst off!"))
	new_form = /mob/living/carbon/alien/humanoid/hunter
	bantype = ROLE_ALIEN


/datum/disease/transformation/xeno/stage_act(delta_time, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(3)
			if(DT_PROB(2, delta_time))
				to_chat(affected_mob, SPAN_DANGER("You feel a stabbing pain in your head."))
				affected_mob.Unconscious(40)
		if(4)
			if(DT_PROB(10, delta_time))
				affected_mob.say(pick("You look delicious.", "Going to... devour you...", "Hsssshhhhh!"), forced = "xenomorph transformation")


/datum/disease/transformation/slime
	name = "Advanced Mutation Transformation"
	cure_text = "frost oil"
	cures = list(/datum/reagent/consumable/frostoil)
	cure_chance = 55
	agent = "Advanced Mutation Toxin"
	desc = "This highly concentrated extract converts anything into more of itself."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("You don't feel very well.")
	stage2 = list("Your skin feels a little slimy.")
	stage3 = list(SPAN_DANGER("Your appendages are melting away."), SPAN_DANGER("Your limbs begin to lose their shape."))
	stage4 = list(SPAN_DANGER("You are turning into a slime."))
	stage5 = list(SPAN_DANGER("You have become a slime."))
	new_form = /mob/living/simple_animal/slime/random


/datum/disease/transformation/slime/stage_act(delta_time, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(1)
			if(ishuman(affected_mob) && affected_mob.dna)
				if(affected_mob.dna.species.id == "slime" || affected_mob.dna.species.id == "stargazer" || affected_mob.dna.species.id == "lum")
					stage = 5
		if(3)
			if(ishuman(affected_mob))
				var/mob/living/carbon/human/human = affected_mob
				if(human.dna.species.id != "slime" && affected_mob.dna.species.id != "stargazer" && affected_mob.dna.species.id != "lum")
					human.set_species(/datum/species/jelly/slime)


/datum/disease/transformation/corgi
	name = "The Barkening"
	cure_text = "Death"
	cures = list(/datum/reagent/medicine/adminordrazine)
	agent = "Fell Doge Majicks"
	desc = "This disease transforms the victim into a corgi."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("BARK.")
	stage2 = list("You feel the need to wear silly hats.")
	stage3 = list(SPAN_DANGER("Must... eat... chocolate...."), SPAN_DANGER("YAP"))
	stage4 = list(SPAN_DANGER("Visions of washing machines assail your mind!"))
	stage5 = list(SPAN_DANGER("AUUUUUU!!!"))
	new_form = /mob/living/simple_animal/pet/dog/corgi


/datum/disease/transformation/corgi/stage_act(delta_time, times_fired)
	. = ..()
	if(!.)
		return
	switch(stage)
		if(3)
			if (DT_PROB(4, delta_time))
				affected_mob.say(pick("YAP", "Woof!"), forced = "corgi transformation")
		if(4)
			if (DT_PROB(10, delta_time))
				affected_mob.say(pick("Bark!", "AUUUUUU"), forced = "corgi transformation")


/datum/disease/transformation/morph
	name = "Gluttony's Blessing"
	cure_text = "Nothing"
	cures = list(/datum/reagent/consumable/nothing)
	agent = "Gluttony's Blessing"
	desc = "A 'gift' from somewhere terrible."
	stage_prob = 10
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("Your stomach rumbles.")
	stage2 = list("Your skin feels saggy.")
	stage3 = list(SPAN_DANGER("Your appendages are melting away."), SPAN_DANGER("Your limbs begin to lose their shape."))
	stage4 = list(SPAN_DANGER("You're ravenous."))
	stage5 = list(SPAN_DANGER("You have become a morph."))
	new_form = /mob/living/simple_animal/hostile/morph
	infectable_biotypes = MOB_ORGANIC|MOB_MINERAL|MOB_UNDEAD //magic!
	transformed_antag_datum = /datum/antagonist/morph

/datum/disease/transformation/gondola
	name = "Gondola Transformation"
	cure_text = "Condensed Capsaicin, ingested or injected." //getting pepper sprayed doesn't help
	cures = list(/datum/reagent/consumable/condensedcapsaicin) //beats the hippie crap right out of your system
	cure_chance = 55
	stage_prob = 2.5
	agent = "Tranquility"
	desc = "Consuming the flesh of a Gondola comes at a terrible price."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list("You seem a little lighter in your step.")
	stage2 = list("You catch yourself smiling for no reason.")
	stage3 = list(SPAN_DANGER("A cruel sense of calm overcomes you."), SPAN_DANGER("You can't feel your arms!"), SPAN_DANGER("You let go of the urge to hurt clowns."))
	stage4 = list(SPAN_DANGER("You can't feel your arms. It does not bother you anymore."), SPAN_DANGER("You forgive the clown for hurting you."))
	stage5 = list(SPAN_DANGER("You have become a Gondola."))
	new_form = /mob/living/simple_animal/pet/gondola


/datum/disease/transformation/gondola/stage_act(delta_time, times_fired)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(2)
			if(DT_PROB(2.5, delta_time))
				affected_mob.emote("smile")
			if(DT_PROB(10, delta_time))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
		if(3)
			if(DT_PROB(2.5, delta_time))
				affected_mob.emote("smile")
			if(DT_PROB(10, delta_time))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
		if(4)
			if(DT_PROB(2.5, delta_time))
				affected_mob.emote("smile")
			if(DT_PROB(10, delta_time))
				affected_mob.reagents.add_reagent_list(list(/datum/reagent/pax = 5))
			if(DT_PROB(1, delta_time))
				var/obj/item/held_item = affected_mob.get_active_held_item()
				if(held_item)
					to_chat(affected_mob, SPAN_DANGER("You let go of what you were holding."))
					affected_mob.dropItemToGround(held_item)
