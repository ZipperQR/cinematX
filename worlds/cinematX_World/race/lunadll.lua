package.path = package.path .. ";./worlds/cinematX_World/?.lua" .. ";./?.lua"
cinematX = loadSharedAPI("cinematX")
NPCID = loadSharedAPI("npcid")


do	

	racerActor = cinematX.getActorFromKey ("racer")
	raceStarted = false

	function onLoop ()		
		
		racerActor = cinematX.getActorFromKey ("racer")
		
		racerActor.shouldDespawn = false
		
		if (racerActor ~= nil) then
				
			-- Begin race when the player is in position
			if  (player.x >= racerActor:getX ()    and    raceStarted == false)  then
				raceStarted = true
				cinematX.runCoroutine (coroutine_racerPath)
			end
		end
	end

	
	function coroutine_racerPath ()
		triggerEvent("Race Start")
		racerActor:walk (5)
	
		cinematX.waitSeconds (1.0)
		racerActor:jump (8)
		
		while  (racerActor:getSpeedY() == 0)  do
			return coroutine.yield
		end
		
		cinematX.waitSeconds (0.1)
		racerActor:jump (9)	
		
		cinematX.waitSeconds (1.1)
		racerActor:jump (7)	
		
		cinematX.waitSeconds (1.0)
		racerActor:jump (4)	
		
		-- Now in water
	end
	
end


