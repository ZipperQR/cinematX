package.path = package.path .. ";./worlds/cinematX_World/?.lua" .. ";./?.lua"
cinematX = loadSharedAPI("cinematX")
NPCID = loadSharedAPI("npcid")


do	
	function onLoop ()		
		
		bobActor = cinematX.getActorFromKey ("bob")
		tntActor = cinematX.getActorFromKey ("tnt")
	
		wallLayer = findlayer("DoomWall");
		
		bobActor.shouldDespawn = false
		tntActor.shouldDespawn = false
		
		if (wallLayer ~= nil) then
			--wallLayer.speedX = 0;				
			
			if (bobActor ~= nil) then
				wallLayer.speedX = math.max(-0.5, 0.02*(player.x-bobActor:getX())) + 1.5;				

			end
			
			earthquake (4 - wallLayer.speedX/3)
		
			if (tntActor ~= nil) then
				if (tntActor.isDead == false) then
					wallLayer.speedX = 0;
					earthquake (0)
				end
			end
		
		end
	end

end

