package.path = package.path .. ";./worlds/cinematX_World/?.lua" .. ";./?.lua"
cinematX = loadSharedAPI("cinematX")
cinematX.config (true, false)
NPCID = loadSharedAPI("npcid")

do
	-- Individual NPC animation settings
	animData_Calleoca = {}
	animData_Calleoca [cinematX.ANIMSTATE_NUMFRAMES] = 40
	animData_Calleoca [cinematX.ANIMSTATE_IDLE] = "4-9"
	animData_Calleoca [cinematX.ANIMSTATE_TALK] = "15-15"
	animData_Calleoca [cinematX.ANIMSTATE_WALK] = "16-17"
	animData_Calleoca [cinematX.ANIMSTATE_RUN] = "20-23"
	animData_Calleoca [cinematX.ANIMSTATE_JUMP] = "26-26"
	animData_Calleoca [cinematX.ANIMSTATE_FALL] = "32-32"

	NPCID_CALLEOCA = 101




	function onLoad ()
	end

	raceStarted = false
	racerActor = cinematX.getActorFromKey ("racer")
	raceEndX = Section (player.section).boundary.right-512
	
	function onLoop ()				
		racerActor = cinematX.getActorFromKey ("racer")
		raceEndX = Section(player.section).boundary.right-512
		
		racerActor.shouldDespawn = false
		
		if (racerActor ~= nil) then
			racerActor:overrideAnimation (animData_Calleoca)
				
			-- Begin race when the player is in position
			if  (cinematX.playerActor:getX () >= racerActor:getX ()    and    raceStarted == false)  then
				raceStarted = true
				cinematX.beginRace (racerActor, racerActor:getX (), raceEndX, 
									coroutine_racerPath, coroutine_LoseRace, coroutine_WinRace)
			end
		end
	end

	
	function coroutine_racerPath ()
		triggerEvent("Race Start")
		racerActor:walkToX (raceEndX, 5)
	
		cinematX.waitSeconds (1.0)
		racerActor:jump (8)
				
		cinematX.waitSeconds (1.2)
		racerActor:jump (9)	
		
		cinematX.waitSeconds (1.1)
		racerActor:jump (8)	
		
		cinematX.waitSeconds (1.0)
		racerActor:jump (4)	
		
		cinematX.waitSeconds (0.5)--1.0)
		racerActor:walk (0)

		-- Now in water
		--racerActor:jump (4)	
	end
	
	
	function coroutine_WinRace ()
		triggerEvent ("Win Race")
		cinematX.changeSceneMode (cinematX.SCENESTATE_PLAY)
	end
	
	function coroutine_LoseRace ()
		player:kill()
	end
end


