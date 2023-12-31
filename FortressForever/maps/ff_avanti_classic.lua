IncludeScript("base_id");
IncludeScript("base_respawnturret");
-----------------------------------------------------------------------------
-- globals
FLAG_RETURN_TIME = 60;
INITIAL_ROUND_DELAY = 35;
TEAM_SWITCH_DELAY = 4
NUM_PHASES = 4
-----------------------------------------------------------------------------

-- sounds, right?
function precache()
	PrecacheSound("otherteam.flagstolen")
	PrecacheSound("misc.bloop")
end

-- startup
function startup()
	-- set up team limits
	local team = GetTeam( Team.kBlue )
	team:SetPlayerLimit( 0 )

	team = GetTeam( Team.kRed )
	team:SetPlayerLimit( 0 )

	team = GetTeam( Team.kYellow )
	team:SetPlayerLimit( -1 )

	team = GetTeam( Team.kGreen )
	team:SetPlayerLimit( -1 )

	
	SetTeamName( attackers, "Attackers" )
	SetTeamName( defenders, "Defenders" )
	
	
	local team = GetTeam(attackers)
	team:SetClassLimit(Player.kCivilian, -1)
	team:SetClassLimit(Player.kSniper, 1)
	team:SetClassLimit(Player.kEngineer, 3)

	team = GetTeam(defenders)
	team:SetClassLimit(Player.kCivilian, -1)
	team:SetClassLimit(Player.kScout, -1)
	team:SetClassLimit(Player.kMedic, -1)
	team:SetClassLimit(Player.kSniper, 1)
	team:SetClassLimit(Player.kEngineer, 3)

	-- start the timer for the points
	AddScheduleRepeating("addpoints", PERIOD_TIME, addpoints)

	setup_door_timer("start_gate", INITIAL_ROUND_DELAY)
	if INITIAL_ROUND_DELAY > 30 then AddSchedule( "dooropen30sec" , INITIAL_ROUND_DELAY - 30 , schedulemessagetoall, "Gates open in 30 seconds!" ) end
	if INITIAL_ROUND_DELAY > 10 then AddSchedule( "dooropen10sec" , INITIAL_ROUND_DELAY - 10 , schedulemessagetoall, "Gates open in 10 seconds!" ) end
	if INITIAL_ROUND_DELAY > 5 then AddSchedule( "dooropen5sec" , INITIAL_ROUND_DELAY - 5 , schedulemessagetoall, "5" ) end
	if INITIAL_ROUND_DELAY > 4 then AddSchedule( "dooropen4sec" , INITIAL_ROUND_DELAY - 4 , schedulemessagetoall, "4" ) end
	if INITIAL_ROUND_DELAY > 3 then AddSchedule( "dooropen3sec" , INITIAL_ROUND_DELAY - 3, schedulemessagetoall, "3" ) end
	if INITIAL_ROUND_DELAY > 2 then AddSchedule( "dooropen2sec" , INITIAL_ROUND_DELAY - 2, schedulemessagetoall, "2" ) end
	if INITIAL_ROUND_DELAY > 1 then AddSchedule( "dooropen1sec" , INITIAL_ROUND_DELAY - 1, schedulemessagetoall, "1" ) end
	
	-- sounds
	if INITIAL_ROUND_DELAY > 30 then AddSchedule( "dooropen30secsound" , INITIAL_ROUND_DELAY - 30 , schedulesound, "misc.bloop" ) end
	if INITIAL_ROUND_DELAY > 10 then AddSchedule( "dooropen10secsound" , INITIAL_ROUND_DELAY - 10 , schedulesound, "misc.bloop" ) end
	if INITIAL_ROUND_DELAY > 5 then AddSchedule( "dooropen5seccount" , INITIAL_ROUND_DELAY - 5 , schedulecountdown, 5 ) end
	if INITIAL_ROUND_DELAY > 4 then AddSchedule( "dooropen4seccount" , INITIAL_ROUND_DELAY - 4 , schedulecountdown, 4 ) end
	if INITIAL_ROUND_DELAY > 3 then AddSchedule( "dooropen3seccount" , INITIAL_ROUND_DELAY - 3 , schedulecountdown, 3 ) end
	if INITIAL_ROUND_DELAY > 2 then AddSchedule( "dooropen2seccount" , INITIAL_ROUND_DELAY - 2 , schedulecountdown, 2 ) end
	if INITIAL_ROUND_DELAY > 1 then AddSchedule( "dooropen1seccount" , INITIAL_ROUND_DELAY - 1 , schedulecountdown, 1 ) end

	cp1_flag.enabled = true
	for i,v in ipairs({"cp1_flag", "cp2_flag", "cp3_flag", "cp4_flag", "cp5_flag", "cp6_flag", "cp7_flag", "cp8_flag"}) do
		local flag = GetInfoScriptByName(v)
		if flag then
			flag:SetModel(_G[v].model)
			flag:SetSkin(teamskins[attackers])
			if i == 1 then
				flag:Restore()
			else
				flag:Remove()
			end
		end
	end	 
	
	flags_set_team( attackers )
	
	ATTACKERS_OBJECTIVE_ENTITY = GetEntityByName( "cp"..phase.."_flag" )
	UpdateTeamObjectiveIcon( GetTeam(attackers), ATTACKERS_OBJECTIVE_ENTITY )
end

-- Give everyone a full resupply, but strip secondary grenades and defender detpacks
function player_spawn( player_entity )
	local player = CastToPlayer( player_entity )

	player:AddHealth( 100 )
	player:AddArmor( 300 )

	player:AddAmmo( Ammo.kNails, 400 )
	player:AddAmmo( Ammo.kShells, 400 )
	player:AddAmmo( Ammo.kRockets, 400 )
	player:AddAmmo( Ammo.kCells, 400 )
	player:AddAmmo( Ammo.kDetpack, 1 )
	
	player:RemoveAmmo( Ammo.kManCannon, 1 )
	player:RemoveAmmo( Ammo.kGren2, 4 )
	
	-- wtf, scout or med on d? are you mental?
	if (player:GetClass() == Player.kScout or player:GetClass() == Player.kMedic) and (player:GetTeamId() == defenders) then
		local classt = "Scout"
		if player:GetClass() == Player.kMedic then classt = "Medic" end
		local id = player:GetId()
		AddSchedule("force_changemessage"..id, 2, schedulechangemessage, player, "No "..classt.."s on defense. Autoswitching to Soldier." )
		AddSchedule("force_change"..id, 2.5, forcechange, player)
	end
	
	if player:GetTeamId() == attackers then
		UpdateObjectiveIcon( player, ATTACKERS_OBJECTIVE_ENTITY )
	elseif player:GetTeamId() == defenders then
		UpdateObjectiveIcon( player, nil )
		player:RemoveAmmo( Ammo.kDetpack, 1 )
	end
end

function base_id_cap:oncapture(player, item)
	SmartSound(player, "yourteam.flagcap", "yourteam.flagcap", "otherteam.flagcap")
--SmartSound(player, "vox.yourcap", "vox.yourcap", "vox.enemycap")
	SmartSpeak(player, "CTF_YOUCAP", "CTF_TEAMCAP", "CTF_THEYCAP")
 	SmartMessage(player, "#FF_YOUCAP", "#FF_TEAMCAP", "#FF_OTHERTEAMCAP")

	local flag_item = GetInfoScriptByName( item )
	RemoveHudItem( player, flag_item:GetName() )

	-- turn off this flag
	for i,v in ipairs(self.item) do
		_G[v].enabled = nil
		local flag = GetInfoScriptByName(v)
		if flag then
			flag:Remove()
		end
	end

	if phase == NUM_PHASES then
		-- it's the last round. end and stuff
		phase = 1

		AddSchedule("switch_teams", TEAM_SWITCH_DELAY, switch_teams)
	else
		phase = phase + 1

		-- enable the next flag after a time
		AddSchedule("flag_start", ROUND_DELAY, flag_start, self.next)
		if ROUND_DELAY > 30 then AddSchedule("flag_30secwarn", ROUND_DELAY-30, flag_30secwarn) end
		if ROUND_DELAY > 10 then AddSchedule("flag_10secwarn", ROUND_DELAY-10, flag_10secwarn) end		
		
		-- clear objective icon
		ATTACKERS_OBJECTIVE_ENTITY = nil
		UpdateTeamObjectiveIcon( GetTeam(attackers), nil )
		UpdateTeamObjectiveIcon( GetTeam(defenders), nil )
	end

end

function switch_teams()
	if attackers == Team.kBlue then
		attackers = Team.kRed
		defenders = Team.kBlue
	else
		attackers = Team.kBlue
		defenders = Team.kRed
	end
	
	-- set all flag teams to new attackers
	flags_set_team( attackers )
	
	-- enable the first flag
	cp1_flag.enabled = true
	local flag = GetInfoScriptByName("cp1_flag")
	if flag then
		flag:Restore()
		flag:SetSkin(teamskins[attackers])
	end
	
	-- change objective icon
	ATTACKERS_OBJECTIVE_ENTITY = flag
	UpdateTeamObjectiveIcon( GetTeam(attackers), nil )
	UpdateTeamObjectiveIcon( GetTeam(defenders), nil )
	
	-- reset the timer on points
	AddScheduleRepeating("addpoints", PERIOD_TIME, addpoints)
	
	-- respawn the players
	RespawnAllPlayers()
	setup_door_timer("start_gate", INITIAL_ROUND_DELAY)
	
	-- run custom round reset stuff
	onroundreset()

	OutputEvent( "point_template", "ForceSpawn" )
end

-----------------------------------------------------------------------------
-- Scheduled functions that do stuff
-----------------------------------------------------------------------------

-- Sends a message to all after the determined time
function schedulechangemessage( player, message )
	if (player:GetClass() == Player.kScout or player:GetClass() == Player.kMedic) and (player:GetTeamId() == defenders) then
		BroadCastMessageToPlayer( player, message )
	end
end

-- force a scout/med to switch to soli if they haven't
function forcechange( player )
	if (player:GetClass() == Player.kScout or player:GetClass() == Player.kMedic) and (player:GetTeamId() == defenders) then
		ApplyToPlayer( player, { AT.kChangeClassSoldier, AT.kRespawnPlayers } )
	end
end

---------------------------------------------------------------------------
--Turrets
------------------------------------------------------------

respawnturret_attackers = base_respawnturret:new({ team = attackers })
respawnturret_defenders = base_respawnturret:new({ team = defenders })

---------------------
--Backpacks
---------------------
genpack = genericbackpack:new({
	health = 35,
	armor = 50,
	grenades = 20,
	nails = 50,
	shells = 300,
	rockets = 15,
	cells = 120,
	mancannons = 0,
	gren1 = 0,
	gren2 = 0,
	respawntime = 15,
	model = "models/items/backpack/backpack.mdl",
	materializesound = "Item.Materialize",
	touchsound = "Backpack.Touch"
})

function genpack:dropatspawn() return false 
end

genpack_grenpack = genericbackpack:new({
	health = 35,
	armor = 50,
	grenades = 20,
	nails = 50,
	shells = 300,
	rockets = 15,
	cells = 120,
	mancannons = 0,
	gren1 = 2,
	gren2 = 1,
	respawntime = 15,
	model = "models/items/backpack/backpack.mdl",
	materializesound = "Item.Materialize",
	touchsound = "Backpack.Touch"
})

function genpack_grenpack:dropatspawn() return false 
end

----------------------------------------------------
--Toggle Cap points
---------------------------------------------------
function cp1_cap:ontouch( trigger_entity )
	OutputEvent( "cp1_door", "Toggle" )
		
end
function cp2_cap:ontouch( trigger_entity )
	OutputEvent( "cp2_door", "Toggle" )
		
end
function cp3_cap:ontouch( trigger_entity )
	OutputEvent( "cp3_door", "Toggle" )
		
end
function cp4_cap:ontouch( trigger_entity )
	OutputEvent( "cp4_door", "Toggle" )
		
end

----------------------------------------------------
--Random schedule functions
---------------------------------------------------
-- Sends a message to all after the determined time
function schedulemessagetoall( message )
	BroadCastMessage( message )
end

-- Plays a sound to all after the determined time
function schedulesound( sound )
	BroadCastSound( sound )
end


function schedulecountdown( time )
	BroadCastMessage( ""..time.."" )
	SpeakAll( "AD_" .. time .. "SEC" )
end

function round_start(doorname)
	BroadCastMessage("Gates are now open!")
	OpenDoor(doorname)
	
	BroadCastSound( "otherteam.flagstolen" )
end

---------------------------------------
--Resetting round
------------------------------------
detpack_wall_open = nil

function onroundreset()
	-- close the door
	if detpack_wall_open then
		-- there's no "close".. wtf
		OutputEvent("detpack_hole", "Toggle")
		detpack_wall_open = nil
	end
	-- Reset The Turrets
	respawnturret_attackers = base_respawnturret:new({ team = attackers })
	respawnturret_defenders = base_respawnturret:new({ team = defenders })
	
	-- reset them limits
	team = GetTeam(defenders)
	team:SetClassLimit(Player.kCivilian, -1)
	team:SetClassLimit(Player.kScout, -1)
	team:SetClassLimit(Player.kMedic, -1)
	
	team = GetTeam(attackers)
	team:SetClassLimit(Player.kCivilian, -1)
	team:SetClassLimit(Player.kScout, 0)
	team:SetClassLimit(Player.kMedic, 0)
	
	-- switch them team names
	SetTeamName( attackers, "Attackers" )
	SetTeamName( defenders, "Defenders" )
	
	if INITIAL_ROUND_DELAY > 30 then AddSchedule( "dooropen30sec" , INITIAL_ROUND_DELAY - 30 , schedulemessagetoall, "Gates open in 30 seconds!" ) end
	if INITIAL_ROUND_DELAY > 10 then AddSchedule( "dooropen10sec" , INITIAL_ROUND_DELAY - 10 , schedulemessagetoall, "Gates open in 10 seconds!" ) end
	if INITIAL_ROUND_DELAY > 5 then AddSchedule( "dooropen5sec" , INITIAL_ROUND_DELAY - 5 , schedulemessagetoall, "5" ) end
	if INITIAL_ROUND_DELAY > 4 then AddSchedule( "dooropen4sec" , INITIAL_ROUND_DELAY - 4 , schedulemessagetoall, "4" ) end
	if INITIAL_ROUND_DELAY > 3 then AddSchedule( "dooropen3sec" , INITIAL_ROUND_DELAY - 3, schedulemessagetoall, "3" ) end
	if INITIAL_ROUND_DELAY > 2 then AddSchedule( "dooropen2sec" , INITIAL_ROUND_DELAY - 2, schedulemessagetoall, "2" ) end
	if INITIAL_ROUND_DELAY > 1 then AddSchedule( "dooropen1sec" , INITIAL_ROUND_DELAY - 1, schedulemessagetoall, "1" ) end
	
	-- sounds
	if INITIAL_ROUND_DELAY > 30 then AddSchedule( "dooropen30secsound" , INITIAL_ROUND_DELAY - 30 , schedulesound, "misc.bloop" ) end
	if INITIAL_ROUND_DELAY > 10 then AddSchedule( "dooropen10secsound" , INITIAL_ROUND_DELAY - 10 , schedulesound, "misc.bloop" ) end
	if INITIAL_ROUND_DELAY > 5 then AddSchedule( "dooropen5seccount" , INITIAL_ROUND_DELAY - 5 , schedulecountdown, 5 ) end
	if INITIAL_ROUND_DELAY > 4 then AddSchedule( "dooropen4seccount" , INITIAL_ROUND_DELAY - 4 , schedulecountdown, 4 ) end
	if INITIAL_ROUND_DELAY > 3 then AddSchedule( "dooropen3seccount" , INITIAL_ROUND_DELAY - 3 , schedulecountdown, 3 ) end
	if INITIAL_ROUND_DELAY > 2 then AddSchedule( "dooropen2seccount" , INITIAL_ROUND_DELAY - 2 , schedulecountdown, 2 ) end
	if INITIAL_ROUND_DELAY > 1 then AddSchedule( "dooropen1seccount" , INITIAL_ROUND_DELAY - 1 , schedulecountdown, 1 ) end
end

detpack_trigger = trigger_ff_script:new({})
function detpack_trigger:onexplode( trigger_entity )
	if IsDetpack( trigger_entity ) then
		BroadCastMessage("The detpack wall has been blown open!")
		BroadCastSound( "otherteam.flagstolen" )
		OutputEvent("detpack_hole", "Toggle")
		OutputEvent("break1", "PlaySound")
		detpack_wall_open = true			
	end
	return EVENT_ALLOWED
end

-- Don't want any body touching/triggering it except the detpack
function trigger_detpackable_door:allowed( trigger_entity ) return EVENT_DISALLOWED 
end


