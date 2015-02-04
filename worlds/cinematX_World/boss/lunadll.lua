package.path = package.path .. ";./worlds/cinematX_World/?.lua" .. ";./?.lua"
cinematX = loadSharedAPI("cinematX")
NPCID = loadSharedAPI("npcid")

-- Un-comment this line if lunaworld.lua is being used
--local lunaworld = require ("lunaworld")

--***************************************************************************************
--                                                                                      *
-- CONSTANTS AND ENUMS																	*
--                                                                                      *
--***************************************************************************************
do

	-- NPC ID enums
	NPCID_BROADSWORD = NPCID.LUIGI
	NPCID_CALLEOCA = NPCID.TOAD_B
	NPCID_DONUTGEN = NPCID.RINKAGEN
	NPCID_SHOCKWAVEGEN = NPCID.SPARK
	NPCID_COLLISIONA = NPCID.BOBOMB_SMB3
	NPCID_COLLISIONB = NPCID.ACTIVEBOBOMB_SMB3

	shockwaveGenLActor = nil
	shockwaveGenRActor = nil		
	broadswordActor = nil
	collisionActor = nil

	shockwavesOff = true
	
	
	-- Sound IDs
	SOUNDID_DRAWSWORD = "sword1.wav"
	SOUNDID_SLICE = "sword2.wav"
	VOICEID_CAL_01 = "voice_calleoca_01.wav"
	VOICEID_CAL_02 = "voice_calleoca_02.wav"
	VOICEID_CAL_03 = "voice_calleoca_03.wav"

	
	-- Individual NPC animation settings
	animData_Broadsword = {}
	animData_Broadsword[cinematX.ANIMSTATE_NUMFRAMES] = 32
	animData_Broadsword[cinematX.ANIMSTATE_IDLE] = "0-0"
	animData_Broadsword[cinematX.ANIMSTATE_TALK] = "1-2"
	animData_Broadsword[cinematX.ANIMSTATE_WALK] = "4-5"
	animData_Broadsword[cinematX.ANIMSTATE_RUN] = "4-5"
	animData_Broadsword[cinematX.ANIMSTATE_JUMP] = "7-7"
	animData_Broadsword[cinematX.ANIMSTATE_FALL] = "9-9"
	animData_Broadsword[cinematX.ANIMSTATE_DEFEAT] = "21-21"
	animData_Broadsword[cinematX.ANIMSTATE_ATTACK1] = "11-11"
	animData_Broadsword[cinematX.ANIMSTATE_ATTACK2] = "13-15"
	animData_Broadsword[cinematX.ANIMSTATE_ATTACK3] = "17-17"
	animData_Broadsword[cinematX.ANIMSTATE_ATTACK4] = "19-19"
	animData_Broadsword[cinematX.ANIMSTATE_ATTACK5] = "23-23"
	animData_Broadsword[cinematX.ANIMSTATE_ATTACK6] = "25-25"
	animData_Broadsword[cinematX.ANIMSTATE_ATTACK7] = "27-30"
end






--***************************************************************************************
-- 																						*
-- LOAF FUNCTIONS																		*
-- 																						*
--***************************************************************************************

--cinematX.levelStartScene = cutscene_TestBreak
--cinematX.sectionStartScene[1] = cutscene_BossIntro


do
	--[[
	function onLoad ()
		cinematX.levelStartScene = cutscene_TestBreak
	end
	--]]

	function onLoadSection0 ()
	end
	
	
	function onLoadSection1 ()
		cinematX.runCutscene (cutscene_bossIntro)
		
	end
end




--***************************************************************************************
-- 																						*
-- LOOP FUNCTIONS																		*
-- 																						*
--***************************************************************************************

do

	function bossOnLoop ()
		runAnimation (0, 300,300, 0)
		runAnimation (0, 300,300, 1)
		runAnimation (0, 300,300, 1065353216)
		
		-- Get references
		shockwaveGenLActor = cinematX.getActorFromKey ("shockleft")
		shockwaveGenRActor = cinematX.getActorFromKey ("shockright")
		broadswordActor = cinematX.getActorFromKey ("broadsword")
		collisionActor = cinematX.getActorFromKey ("broadsword_hitbox")
	
		if (broadswordActor ~= nil) then
			broadswordActor:overrideAnimation (animData_Broadsword)
			broadswordActor.shouldDespawn = false
			
			runAnimation (0, 300,300, 0)--broadswordActor:getX(), broadswordActor:getY(), 0)
			
			
			-- Shockwave generators
			if (shockwaveGenLActor ~= nil) then
				shockwaveGenLActor:setX (broadswordActor:getX()-64) 
				shockwaveGenLActor:setY (broadswordActor:getY()+32) 
				
				if  (shockwavesOff == true)  then
					shockwaveGenLActor.smbxObjRef:mem (0x6C, FIELD_FLOAT, 0)
				elseif  (shockwaveGenLActor.smbxObjRef:mem (0x6C, FIELD_FLOAT) < 100)  then
					shockwaveGenLActor.smbxObjRef:mem (0x6C, FIELD_FLOAT, 100)
				end
			end	

			if (shockwaveGenRActor ~= nil) then
				shockwaveGenRActor:setX (broadswordActor:getX()+64) 
				shockwaveGenRActor:setY (broadswordActor:getY()+32) 
				
				if  (shockwavesOff == true)  then
					shockwaveGenRActor.smbxObjRef:mem (0x6C, FIELD_FLOAT, 0)
				elseif  (shockwaveGenRActor.smbxObjRef:mem (0x6C, FIELD_FLOAT) < 100)  then
					shockwaveGenRActor.smbxObjRef:mem (0x6C, FIELD_FLOAT, 100)
				end
			end	
			

			-- Snap the collision dummy A to Broadsword
			if (collisionActor ~= nil) then
				collisionActor:setX (broadswordActor:getX()) 
				collisionActor:setY (broadswordActor:getY())

				-- Reset the collision actor when taking damage
				if (collisionActor.smbxObjRef.id == NPCID_COLLISIONB) then
					
					cinematX.bossHP = cinematX.bossHP - 1
					playSFX ("voice_hurt1.wav")

					if battlePhase == 3  then
						battleFrame = battleFrame + 30
					end


					-- Speed up the music toward the end
					--if (cinematX.bossHP == 2) then
					--	playMusic (19)
					--end
					
					collisionActor.smbxObjRef:mem (0xE2, FIELD_WORD, NPCID_COLLISIONA)
				end
				
				-- If the boss is out of health, begin the win sequence and lead into the post-battle cutscene
				if (cinematX.bossHP <= 0  and  battlePhase ~= 30) then
					collisionActor.smbxObjRef:mem (0x46, FIELD_WORD, 0xFFFF)
					battlePhase = 30
					battleFrame = 0
					MusicStopFadeOut (1000)
				end
			end
		end
		
		
		-- OLD METHOD
		--[[
			
		else
			windowDebug ("ERROR")
		end
		
		-- Quickly reset the collision dummy B and reduce the boss HP counter
		if (collisionBNPC ~= nil) then
			--bossHP = bossHP - 1
			playSFX ("voice_hurt1.wav")

			if battlePhase == 3  then
				battleFrame = battleFrame + 30
			end


			-- Speed up the music toward the end
			if (bossHP == 2) then
				playMusic (19)

			end
			collisionBNPC:mem (0xE2, FIELD_WORD, NPCID_COLLISIONA)
		end

		-- Snap the rinka generator to Broadsword
		if (donutGenNPC ~= nil) then
			donutGenNPC.x = broadswordNPC.x
			donutGenNPC.y = broadswordNPC.y
		end


		-- Turn all rinkas into _____
		allNPCs = findnpcs(210,player.section)
		for k,v in pairs(allNPCs) do
			v.speedY = -8
			v:mem (0xE2, FIELD_WORD, 30)
			if (v:mem (0x136, FIELD_WORD) == FFFF) then
				v.speedX = 4 * getNPCRelativeDirX (v)
			end
		end
		--]]
		
	end
	
	function onLoop ()		
		bossOnLoop ()
	end



	function onLoopSection0 ()

	end

end



--***************************************************************************************
-- 																						*
-- OTHER IMPORTANT FUNCTIONS															*
-- 																						*
--***************************************************************************************
do
		
end




--***************************************************************************************
-- 																						*
-- COROUTINE SEQUENCES																	*
-- 																						*
--***************************************************************************************
do 

	function cutscene_bossIntro ()
		-- Player character walks in, Broadsword is facing away
		cinematX.playerActor:walk (1)
		cinematX.waitSeconds (2)
		
		-- Broadsword turns to face the player
		broadswordActor:setDirection (DIR_LEFT)
		cinematX.waitSeconds (1)
		
		cinematX.playerActor:walk (0)		
		cinematX.waitSeconds (1)
		
		--playMusic (17)
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "A-ha! 'Twas a good show, "..cinematX.playerNameASXT()..", but I       emerge the victor!", 30, 30, "voice_talk1.wav")  
		cinematX.waitForDialog ()

		cinematX.startDialog  (nil, cinematX.playerNameASXT(), "B-but we really need that leek!            Best two out of three?", 30, 30, "")
		cinematX.waitForDialog ()
		  
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "Tsk, tsk, tsk! Nobody likes a sore loser,  my dear!", 30, 30, "")
		cinematX.waitForDialog ()

		-- Broadsword begins walking away, stops and turns back around
		cinematX.configDialog (false, false, 1)	
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "But I am still feeling a tad sporting...", 160, 100, "")

		broadswordActor:walk (2)
		cinematX.waitSeconds (1)
		  
		broadswordActor:walk (0)
		cinematX.waitSeconds (1)
		  
		-- Broadsword challenges the player to a duel
		broadswordActor:setDirection (DIR_LEFT)
		
		cinematX.configDialog (true, true, 1)	
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "Very well! If this preposterous produce    means that much to you, then come and have  a go!", 30, 30, "")
		cinematX.waitForDialog ()
		  
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "Best moi in a duel and the colossal        cabbage is yours!", 30, 30, "")
		cinematX.waitForDialog ()

		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "But I shant take this challenge lightly,   so don't hold back yourself!", 30, 30, "voice_talk4.wav")
		cinematX.waitForDialog ()
		  
		  
		-- Sword slice animation
		cinematX.configDialog (false, false, 1)
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "EN GARDE!", 160, 160, "voice_talk5.wav")	
		cinematX.waitSeconds (0.6)
		  
		playSFX (SOUNDID_DRAWSWORD)
		broadswordActor:setX (broadswordActor:getX() - 8)
		broadswordActor:setAnimState (cinematX.ANIMSTATE_ATTACK1)
		cinematX.waitSeconds (1)
		  
		playSFX (SOUNDID_SLICE)
		broadswordActor:setX (broadswordActor:getX() - 16)
		broadswordActor:setAnimState (cinematX.ANIMSTATE_ATTACK2)
		cinematX.waitSeconds (1)
		  
		broadswordActor:setX (broadswordActor:getX() + 32)
		broadswordActor:setAnimState (cinematX.ANIMSTATE_IDLE)
		cinematX.waitSeconds (1.5)


		-- Begin battle
		cinematX.endDialogLine ()
		cinematX.playerInputActive = true  

		cinematX.endCutscene ()
		cinematX.changeSceneMode (cinematX.SCENESTATE_BATTLE)
		--collisionANPC:mem (0x46, FIELD_WORD, 0)

		--battleCoroutine ()
		cinematX.runCoroutine (battleCoroutine)
	end

	
	
	function getNPCWallClosest (myActor)
		local currentSection = Section (1)
		local leftX = currentSection.boundary.left
		local rightX = currentSection.boundary.right
		
		local centerX = 0.5*(leftX + rightX)

		if myActor:getX () < centerX then
			wallX = leftX
		else
			wallX = rightX
		end

		return wallX
	end

	
	function getNPCWallFacing (myActor)
		local currentSection = Section (1)
		local leftX = currentSection.boundary.left
		local rightX = currentSection.boundary.right
		
		if myActor:getDirection () == DIR_LEFT then
			wallX = leftX
		else
			wallX = rightX
		end

		return wallX
	end

	
	
	function battleCoroutine ()
		MusicOpen ("Tales of Graces - Battle Theme 5.mp3")
		MusicPlay ()
		
		battleFrame = 0
		battlePhase = 0
		bossAttackPattern = 0
		
		while (true) do
			--battleFrame = battleFrame + 1
			
			--windowDebug ("TEST")
			cinematX.waitSeconds (0)
			
			-- Determine where the boss is relative to the player
			local sectionBounds = Section(player.section).boundary
			local roomCenterX = 0.5 * (sectionBounds.left + sectionBounds.right)
			
			local closestWallX = getNPCWallClosest (broadswordActor)
			local facingWallX = getNPCWallFacing (broadswordActor)
			
			local dirToPlayerX = broadswordActor:dirToActorX (cinematX.playerActor)
			local dirToCenterX = broadswordActor:dirToX (roomCenterX)
			
			local distToPlayerX = broadswordActor:distanceActorX (cinematX.playerActor)
			local distToWallClosest = broadswordActor:distanceX (closestWallX)
			local distToWallFacing = broadswordActor:distanceX (facingWallX)
		  
			
			-- CLAMP BROADSWORD TO THE SECTION BOUNDS
			if  (broadswordActor:getX () > sectionBounds.right-32) then
				broadswordActor:setX (sectionBounds.right-32)
			end
			if  (broadswordActor:getX () < sectionBounds.left) then
				broadswordActor:setX (sectionBounds.left)
			end
			
			
			-- PHASE 1: DEFEND & MOVE AROUND -------------------------------------------------------------------
			if battlePhase == 0 then
				battleFrame = battleFrame + 1			
				
				shockwavesOff = true
				
				-- After 160 frames, move on to the next phase of the attack pattern
				if battleFrame >= 240  and  broadswordActor:getSpeedY () == 0  then
				  
					broadswordActor:stopFollowing ()
					
					bossAttackPattern = bossAttackPattern + 1
					if (bossAttackPattern % 2 == 1) then
						playSFX ("voice_attack1.wav")
						battlePhase = 1
					else
						playSFX ("voice_attack2.wav")
						battlePhase = 2
					end
					battleFrame = 0

				  
				elseif broadswordActor:getSpeedY () == 0  then
					if broadswordActor:getAnimState () == cinematX.ANIMSTATE_ATTACK7 then
						broadswordActor:setAnimState (cinematX.ANIMSTATE_IDLE)
					end
					
					
					if     distToWallClosest > 128  then  
						if     distToPlayerX > 160 then
							broadswordActor:lookAtPlayer ()
							broadswordActor:walkForward (5)

						elseif distToPlayerX < 160 then
							broadswordActor:jump (math.random(4,6))
							broadswordActor:lookAtPlayer ()
							broadswordActor:walkForward (-6)

						end
					else
						broadswordActor:walk (dirToCenterX * 6)						
						broadswordActor:jump (10)
						broadswordActor:walk (dirToCenterX * 6)						
						broadswordActor:setAnimState (cinematX.ANIMSTATE_ATTACK7)
						playSFX ("sword2.wav")
					end
				end
			
			
			-- PHASE 2: DASH ATTACK ------------------------------------------------------------------------------
			elseif battlePhase == 1 then
			
				battleFrame = battleFrame + 1
			
				-- Unsheath sword and hack away
				if battleFrame     <  60 then
					broadswordActor:walk (0)					
					broadswordActor:setSpeedY (math.max (0, broadswordActor:getSpeedY ()))
					broadswordActor:setAnimState (cinematX.ANIMSTATE_ATTACK1)
					broadswordActor:lookAtPlayer ()
				
				elseif battleFrame == 60 then
					playSFX (SOUNDID_SLICE)
				
				elseif battleFrame < 100 then
					broadswordActor:setAnimState (cinematX.ANIMSTATE_ATTACK2)
					broadswordActor:walkForward (8)
	
					if distToWallFacing < 100 then
						battleFrame = 100
					end
				
				else
					battlePhase = 3
					battleFrame = 0
				end
		  

			-- PHASE 3: POGO ------------------------------------------------------------------------------
			elseif battlePhase == 2  then
			
				-- Disable the shockwave generators
				if battleFrame ~= 120 then
					shockwavesOff = true
				end

				
				-- Jump high
				if battleFrame < 4 then
					broadswordActor:setAnimState (cinematX.ANIMSTATE_ATTACK5)
					broadswordActor:followActor (cinematX.playerActor, 4, 1, false)

					if broadswordActor:getSpeedY () == 0  then
						broadswordActor:jump (11)
						if (battleFrame > 0) then
							playSFX ("boing.wav")
						end
						battleFrame = battleFrame + 1
					end
				
				-- Hold in the air
				elseif battleFrame == 4 then
					playSFX (11)
					battleFrame = battleFrame + 1
					
				elseif battleFrame < 60 then
					battleFrame = battleFrame + 1
					broadswordActor:walk(0)
					
					if broadswordActor:getSpeedY () > 0  then
						broadswordActor:setSpeedY (0)
					end
				  
				-- Stab down
				elseif battleFrame == 60 then	  
					playSFX (22)
					battleFrame = battleFrame + 1
				  
				elseif battleFrame < 120 then
					if broadswordActor:getY() < Section(player.section).boundary.bottom-225  then
						broadswordActor:setAnimState (cinematX.ANIMSTATE_ATTACK6)
						broadswordActor:setSpeedY (64)
					else
						shockwavesOff = false
						battleFrame = 120
						broadswordActor:stopFollowing ()
					end
				
				else 
					battlePhase = 3
					battleFrame = 0
				end
			--]]
			
			-- PHASE 4: VULNERABLE ---------------------------------------------------------------------
			elseif battlePhase == 3  then
				shockwavesOff = true
				
				battleFrame = battleFrame + 1
				broadswordActor:walk (0)
			
				if     battleFrame < 240 then
					broadswordActor:setAnimState (cinematX.ANIMSTATE_DEFEAT)
				else
					broadswordActor:jump (4)
					broadswordActor:walk (dirToCenterX * -4)
					battlePhase = 0
					battleFrame = 0
				end	


			-- PHASE 30: DEFEAT SEQUENCE ------------------------------------------------------------------------------
			elseif battlePhase == 30  then
				battleFrame = battleFrame + 1

				if     battleFrame   ==   1 then
					broadswordActor:setAnimState (cinematX.ANIMSTATE_DEFEAT)
					playSFX ("voice_defeat.wav")
					playMusic (20)

				elseif battleFrame   == 120 then
					break;
				end
			end
		  
		end
		
		cinematX.runCutscene (cutscene_AfterBattle)
	end



	function cutscene_AfterBattle ()  		
		--playerActor:setX (Section(player.section).boundary.left + 200)
		--broadswordActor:setX (Section(player.section).boundary.right - 600)
				
 		cinematX.waitSeconds (1)
		cinematX.configDialog (true, true, 1)	
		
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "I daresay, that was a most exhilarating    scuffle! Bravo!", 30, 30, "voice_talk1.wav")
		cinematX.waitForDialog ()
		
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "As per our wager, the titanic tomato is    now yours. Treasure it always!", 30, 30, "")
		cinematX.waitForDialog ()
		
		broadswordActor:jump (6)
		cinematX.waitSeconds (0.3)
		triggerEvent("Reveal Leek")
		
		cinematX.waitSeconds (1.5)

		broadswordActor:setDirection (DIR_RIGHT)
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "And with that, I must take my leave. There is still much adventuring to do! Cheerio!", 30, 30, "voice_talk3.wav")
		cinematX.waitForDialog ()
		
		broadswordActor:walkForward (2)
		cinematX.waitSeconds (1)
		
		broadswordActor:walk (0)
		broadswordActor:setDirection (DIR_LEFT)
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "Ah, one more thing.", 30, 30, "voice_talk4.wav")
		cinematX.waitForDialog ()
		
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "My brothers are...", 30, 30, "")
		cinematX.waitForDialog ()
				
		cinematX.waitSeconds (1)
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "...", 30, 30, "")
		cinematX.waitForDialog ()
		
		broadswordActor:setDirection (DIR_RIGHT)		
		cinematX.startDialog  (broadswordActor, "Uncle Broadsword", "Ah, what am I doing? Spoilers, Augustus!   Spoilers!", 30, 30, "")
		cinematX.waitForDialog ()

		broadswordActor:walk (2)
		cinematX.waitSeconds (2)
		
		cinematX.endCutscene ()
	end
end	

