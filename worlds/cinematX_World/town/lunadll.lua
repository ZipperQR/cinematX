package.path = package.path .. ";./worlds/cinematX_World/?.lua" ..  ";./town/?.lua" .. ";./?.lua"
cinematX = loadSharedAPI("cinematX")
cinematX.config (true, false)
NPCID = loadSharedAPI("npcid")


--***************************************************************************************
--                                                                                      *
-- CONSTANTS AND ENUMS																	*
--                                                                                      *
--***************************************************************************************
do

	-- NPC ID enums
	NPCID_CALLEOCA = 94

	-- Sound IDs
	VOICEID_CAL_01 = "voice_calleoca_01.wav"
	VOICEID_CAL_02 = "voice_calleoca_02.wav"
	VOICEID_CAL_03 = "voice_calleoca_03.wav"

	-- Individual NPC animation settings
	animData_Calleoca = {}
	animData_Calleoca [cinematX.ANIMSTATE_NUMFRAMES] = 40
	animData_Calleoca [cinematX.ANIMSTATE_IDLE] = "4-9"
	animData_Calleoca [cinematX.ANIMSTATE_TALK] = "15-15"
	animData_Calleoca [cinematX.ANIMSTATE_WALK] = "16-17"
	animData_Calleoca [cinematX.ANIMSTATE_RUN] = "20-23"
	animData_Calleoca [cinematX.ANIMSTATE_JUMP] = "26-26"
	animData_Calleoca [cinematX.ANIMSTATE_FALL] = "32-32"
end


	function onLoad ()
		cinematX.defineQuest ("test", "Test Quest", "Test the quest the quest the test system")
	end


	function onLoadSection1 ()
		cinematX.runCutscene (cutscene_Calleoca)
		
	end



--***************************************************************************************
-- 																						*
-- LOOP FUNCTIONS																		*
-- 																						*
--***************************************************************************************

do	
	function onLoop ()		
		calleocaActor = cinematX.getActorFromKey ("calleoca")
		bulletgenActor = cinematX.getActorFromKey ("bulletgen")
		
		
		if calleocaActor ~= nil then	
			calleocaActor:overrideAnimation (animData_Calleoca)
			--calleocaActor.helloVoice = VOICEID_CAL_01
			--calleocaActor.goodbyeVoice = VOICEID_CAL_02
			calleocaActor.shouldDespawn = false
			calleocaActor.shouldFacePlayer = true
		end
	end


end
--]]




--***************************************************************************************
-- 																						*
-- COROUTINE SEQUENCES																	*
-- 																						*
--***************************************************************************************
do 
	function cutscene_Calleoca()
		cinematX.toConsoleLog ("Lunadll scene called")

		-- Disable interactions with Calleoca
		calleocaActor.isInteractive = false
		
		-- Configure dialogue
		cinematX.setDialogSkippable (true)
		cinematX.setDialogInputWait (true)
		
		cinematX.waitSeconds (0.5)
		
		
		-- Calleoca speaks
		cinematX.startDialog  (calleocaActor, "Calleoca", "Hey, sis! I'mma follow you around a bit,  hope you don't mind!", 30, 30, "")
		cinematX.waitForDialog ()
		
		-- Calleoca starts following the player
		calleocaActor:followActor (cinematX.playerActor, 8, 48)
		calleocaActor.shouldFacePlayer = true
		
		-- End cutscene
		--playSFX (VOICEID_CAL_03)
		cinematX.endCutscene ()
	end

	
	function cutscene_Welcome ()
		
		goopaActor = cinematX.getActorFromKey("goopa1")
		goopaActorName = cinematX.getActorName_Key("goopa1")
	
		-- Configure dialogue
		cinematX.setDialogSkippable (true)
		cinematX.setDialogInputWait (true)
	
		cinematX.startDialog  (goopaActor, goopaActorName, "Welcome to our humble village! Please     enjoy your stay!", 140, 120, "")
		cinematX.waitForDialog ()
	
		cinematX.endCutscene ()
	end
	
	
	
	function cutscene_TestQuest ()	
		cinematX.setDialogSkippable (true)
		cinematX.setDialogInputWait (true)
	
		--cinematX.waitSeconds (1)
		
		if  	(cinematX.isQuestStarted("test") == false)   then
			windowDebug ("Test A")
			cinematX.startQuestion  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa4"), "Can you do me a favor?", 140, 120, "")
			cinematX.waitForDialog ()
			
			if  (cinematX.getResponse() == true)  then
				cinematX.beginQuest ("test")
				cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa4"), "Go talk to my bro, "..cinematX.getActorName_Key("goopa5")..".", 140, 120, "")
				cinematX.waitForDialog ()
				cinematX.resetNPCMessageNew_Key ("goopa4")
				cinematX.resetNPCMessageNew_Key ("goopa5")
			else
				cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa4"), "Well, fine then! Be that way, jerk!", 140, 120, "")
				cinematX.waitForDialog ()
			end
		
		elseif 	(cinematX.isQuestFinished("test") == false)   then
			windowDebug ("Test B")
			cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa4"), "Go talk to my bro, "..cinematX.getActorName_Key("goopa5")..".", 140, 120, "")		
			cinematX.waitForDialog ()
		
		else
			windowDebug ("Test C")
			cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa4"), "You completed the quest, now you can rest!", 140, 120, "")			
			cinematX.waitForDialog ()
		end
			
		cinematX.endCutscene ()
	end
	

	function cutscene_TestQuest2 ()
		cinematX.setDialogSkippable (true)
		cinematX.setDialogInputWait (true)
	
		--cinematX.waitSeconds (1)
		
		if 		(cinematX.isQuestFinished ("test"))  then
			cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa5"), "You don't need to talk to me anymore.", 140, 120, "")
			cinematX.waitForDialog ()
		
		elseif  (cinematX.isQuestStarted ("test"))  then
			cinematX.finishQuest ("test")
			cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa5"), "Quest complete! Yaaaay!", 140, 120, "")
			cinematX.waitForDialog ()
			cinematX.resetNPCMessageNew_Key ("goopa4")
			cinematX.resetNPCMessageNew_Key ("goopa5")
			cinematX.resetNPCMessageNew_Key ("goopa6")
			
		else
			cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa5"), "Talk to my broski, "..cinematX.getNPCName_Key("goopa4")..", first.", 140, 120, "")
			cinematX.waitForDialog ()
		end
			
		cinematX.endCutscene ()
	end	
	
	
	
	function cutscene_TestQuest3 ()
		cinematX.setDialogSkippable (true)
		cinematX.setDialogInputWait (true)
	
		--cinematX.waitSeconds (1)
		
		if  	(cinematX.isQuestFinished("test") == true)   then
			cinematX.startQuestion  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa6"), "Would you like to reset the quest?", 140, 120, "")
			cinematX.waitForDialog ()
			
			if  (cinematX.getResponse() == true)  then
				cinematX.initQuest ("test")
				cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa6"), "Done, you may now test the quest again.", 140, 120, "")
				cinematX.waitForDialog ()
				cinematX.resetNPCMessageNew_Key ("goopa4")
				cinematX.resetNPCMessageNew_Key ("goopa5")
				cinematX.resetNPCMessageNew_Key ("goopa6")
			end
		
		else
			cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa6"), "Please finish the quest before talking to me.", 140, 120, "")			
			cinematX.waitForDialog ()
		end
			
		cinematX.endCutscene ()
	end
	
	
end

