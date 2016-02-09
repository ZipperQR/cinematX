--***************************************************************************************
--                                                                                      *
--  cinematX.lua                                                                        *
--  v0.8p                                                                               *
--  Documentation: http://engine.wohlnet.ru/pgewiki/CinematX.lua                        *
--  Discussion thread: http://talkhaus.raocow.com/viewtopic.php?f=36&t=15516            *
--                                                                                      *
--***************************************************************************************


local cinematX = {} --Package table
local graphX, textblox, mathX, eventu, npcconfig, colliders, inputs;
local libsLoaded = {}
local libsToLoad = {"graphX", "mathematX", "textblox", "eventu", "npcconfig", "colliders", "inputs"}
local libsMissingStr = ""


-- Dependency check
for k,v  in pairs(libsToLoad)  do
	local isLoaded = pcall(function() libsLoaded = loadSharedAPI(v) end)
	
	if  isLoaded == false  then
		if  libsMissingStr == ""  then
			libsMissingStr = v
		else
			libsMissingStr = libsMissingStr..", "..v
		end
	end
end

if  libsMissingStr ~= ""  then
	Text.windowDebug ("CINEMATX ERROR: Some dependencies were not found. \nPlease make sure the following libraries are in your LuaScriptsLib folder:\n\n"..libsMissingStr)
	return cinematX
end

-- If all dependencies are found, assign them to their proper vars
graphX = loadSharedAPI("graphX");
mathX = loadSharedAPI("mathematX");
textblox = loadSharedAPI("textblox");
eventu = loadSharedAPI("eventu");
npcconfig = loadSharedAPI("npcconfig");
colliders = loadSharedAPI("colliders");
inputs = loadSharedAPI("inputs");
 
--inputs.debug = true
 
 
function cinematX.onInitAPI() --Is called when the api is loaded by loadAPI.
	--register event handler
	--registerEvent(string apiName, string internalEventName, string functionToCall, boolean callBeforeMain)
   
	registerEvent(cinematX, "onLoad", "initLevel", true) --Register the init event
	registerEvent(cinematX, "onLoadSection", "initSection", false) --Register the init event
	--registerEvent(cinematX, "onLoad", "delayedInit", false) --Register the init event
	registerEvent(cinematX, "onLoop", "update", true) --Register the loop event
	registerEvent(cinematX, "onJump", "onJump", true) --Register the jump event
	registerEvent(cinematX, "onInputUpdate", "onInputUpdate", true) --Register the input event
	registerEvent(cinematX, "onKeyDown", "onKeyDown", true) --Register the input event
	registerEvent(cinematX, "onKeyUp", "onKeyUp", false) --Register the input event
	registerEvent(cinematX, "onCameraUpdate", "updateCamera", false) --Register the input event
end





--***************************************************************************************************
--                                                                                                  *
--            FILE MANAGEMENT                                                          				*
--                                                                                                  *
--***************************************************************************************************

-- Resource path
local resourcePath = "..\\..\\..\\LuaScriptsLib\\cinematX\\"
local resourcePathOver = "..\\..\\..\\LuaScriptsLib\\cinematX\\"




--***************************************************************************************************
--                                                                                                  *
--            NAMESPACES                                                               				*
--                                                                                                  *
--***************************************************************************************************

do
	cinematX.Scene = {}
	cinematX.Routine = {}
	cinematX.Dialog = {}
	cinematX.Anim = {}
	cinematX.Audio = {}
	cinematX.Actor = {}
	cinematX.Camera = {}
	cinematX.Transition = {}
	cinematX.Overlay = {}
	cinematX.UI = {} 
	cinematX.Race = {}
	cinematX.Boss = {}
	cinematX.Quest = {}
	cinematX.Debug = {}
end


--***************************************************************************************************
--                                                                                                  *
--            ALIASES                                                               				*
--                                                                                                  *
--***************************************************************************************************

do
	local legacyMetatable = {}
	
	local aliases = {
		cinematX.ANIMSTATE_IDLE   		= {"Anim", "IDLE"}, 		
		cinematX.raceEnemyActor 		= {"Race", "enemyActor"},
		cinematX.raceEnemyActor 		= {"Race", "enemyActor"},
		cinematX.raceEnemyActor 		= {"Race", "enemyActor"},
		cinematX.raceEnemyActor 		= {"Race", "enemyActor"}
	}
end


--***************************************************************************************************
--                                                                                                  *
--            ANIMATION			                                                                    *
--                                                                                                  *
--***************************************************************************************************

do
	---- ANIMATION STATE CONSTANTS ------------------------------
	
	local states = {"NUMFRAMES", "BLANK", "IDLE", 
					"TALK","TALK1","TALK2","TALK3","TALK4","TALK5","TALK6","TALK7", 
					"WALK", "RUN", "JUMP", "FALL", "DEFEAT", "HURT", "STUN", "GRAB", 
					"GRABWALK", "GRABRUN","GRABJUMP","GRABFALL",
					"ATTACK","ATTACK1","ATTACK2","ATTACK3","ATTACK4","ATTACK5","ATTACK6","ATTACK7",
					"CLIMB", "TOPPRESET"}

	for  k,v in pairs (states)  do
		cinematX.Anim[v] = k
	end
	
	
	---- ANIMATION DATA -----------------------------------------
	local function split(s,m)
		local t={} ; i=1
		for str in string.gmatch(s, "([^+"..m.."]+)") do
			t[i] = str
			i = i + 1
		end
		return t
	end
	 
	local function trim(s)
		return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
	end
	
	local function deriveAnimData (ad, fillState, sourceState)
		if  ad[fillState] == nil  then
			ad[fillState] = ad[sourceState];
		end
		
		return ad;
	end
	
	
	function cinematX.Anim.fillData (ad)
		ad = deriveAnimData (ad,	cinematX.Anim.TALK, 		cinematX.Anim.IDLE)
		
		ad = deriveAnimData (ad, 	cinematX.Anim.HURT, 		cinematX.Anim.IDLE)
		ad = deriveAnimData (ad, 	cinematX.Anim.DEFEAT, 		cinematX.Anim.HURT)
		ad = deriveAnimData (ad, 	cinematX.Anim.STUN, 		cinematX.Anim.HURT)
		
		ad = deriveAnimData (ad, 	cinematX.Anim.WALK, 		cinematX.Anim.IDLE)
		ad = deriveAnimData (ad, 	cinematX.Anim.RUN, 			cinematX.Anim.WALK)
		ad = deriveAnimData (ad, 	cinematX.Anim.JUMP, 		cinematX.Anim.IDLE)
		ad = deriveAnimData (ad, 	cinematX.Anim.FALL, 		cinematX.Anim.JUMP)
		
		ad = deriveAnimData (ad, 	cinematX.Anim.GRAB, 		cinematX.Anim.IDLE)
		ad = deriveAnimData (ad, 	cinematX.Anim.GRABWALK, 	cinematX.Anim.WALK)
		ad = deriveAnimData (ad, 	cinematX.Anim.GRABRUN, 		cinematX.Anim.RUN)
		ad = deriveAnimData (ad, 	cinematX.Anim.GRABJUMP,		cinematX.Anim.JUMP)
		ad = deriveAnimData (ad, 	cinematX.Anim.GRABFALL,		cinematX.Anim.FALL)
		ad = deriveAnimData (ad, 	cinematX.Anim.CLIMB, 		cinematX.Anim.JUMP)
	
		return ad;
	end
	
	
	function cinematX.Anim.readData (path)
		local p = Misc.resolveFile (path);
		if (p == nil) then return nil; end
		if (string.sub(p,-5) ~= ".anim") then
				p = p..".anim";
		end
   
		local ad = {};
		local f = io.open(p, "r");
   
		for t in f:lines() do
			local ts = split(t,"=");
	   
			if(#ts ~= 2) then
				error("Parse error. Invalid line structure: "..t,2)
			end
					   
			for k,v in ipairs(ts) do
				ts[k] = string.lower(trim(v));
			end
	   
			local cnt = false;
			local index = 1;
	   
			if(ts[1]== "frames") then
				ad[cinematX.Anim.state.NUMFRAMES] = tonumber(ts[2]);
				cnt=true;
				if(ad[cinematX.Anim.state.NUMFRAMES] == nil) then
					error("Parse error. Not a valid frame number: "..ts[2],2)
				end
			elseif(ts[1] == "idle") then
				index = cinematX.Anim.IDLE;
			elseif(ts[1] == "talk") then
				index = cinematX.Anim.TALK;
			elseif(ts[1] == "talk1") then
				index = cinematX.Anim.TALK1;
			elseif(ts[1] == "talk2") then
				index = cinematX.Anim.TALK2;
			elseif(ts[1] == "talk3") then
				index = cinematX.Anim.TALK3;
			elseif(ts[1] == "talk4") then
				index = cinematX.Anim.TALK4;
			elseif(ts[1] == "talk5") then
				index = cinematX.Anim.TALK5;
			elseif(ts[1] == "talk6") then
				index = cinematX.Anim.TALK6;
			elseif(ts[1] == "talk7") then
				index = cinematX.Anim.TALK7;
			elseif(ts[1] == "walk") then
				index = cinematX.Anim.WALK;
			elseif(ts[1] == "run") then
				index = cinematX.Anim.RUN;
			elseif(ts[1] == "jump") then
				index = cinematX.Anim.JUMP;
			elseif(ts[1] == "fall") then
				index = cinematX.Anim.FALL;
			elseif(ts[1] == "climb") then
				index = cinematX.Anim.CLIMB;
			elseif(ts[1] == "hurt") then
				index = cinematX.Anim.HURT;
			elseif(ts[1] == "stun") then
				index = cinematX.Anim.STUN;
			elseif(ts[1] == "defeat") then
				index = cinematX.Anim.DEFEAT;
			elseif(ts[1] == "attack") then
				index = cinematX.Anim.ATTACK;
			elseif(ts[1] == "attack1") then
				index = cinematX.Anim.ATTACK1;
			elseif(ts[1] == "attack2") then
				index = cinematX.Anim.ATTACK2;
			elseif(ts[1] == "attack3") then
				index = cinematX.Anim.ATTACK3;
			elseif(ts[1] == "attack4") then
				index = cinematX.Anim.ATTACK4;
			elseif(ts[1] == "attack5") then
				index = cinematX.Anim.ATTACK5;
			elseif(ts[1] == "attack6") then
				index = cinematX.Anim.ATTACK6;
			elseif(ts[1] == "attack7") then
				index = cinematX.Anim.ATTACK7;
			elseif(ts[1] == "grab") then
				index = cinematX.Anim.GRAB;
			elseif(ts[1] == "grabwalk") then
				index = cinematX.Anim.GRABWALK;
			elseif(ts[1] == "grabrun") then
				index = cinematX.Anim.GRABRUN;
			elseif(ts[1] == "grabjump") then
				index = cinematX.Anim.GRABJUMP;
			elseif(ts[1] == "grabfall") then
				index = cinematX.Anim.GRABFALL;
			elseif(tonumber(ts[1]) ~= nil) then
				index = tonumber(ts[1]);
			elseif(tonumber(ts[1]) == nil) then
				error("Parse error. Unknown frame label: "..ts[1],2)
			end
	   
			if(not cnt) then
				ad[index] = ts[2];
			end
		end
	   
		ad = cinematX.animDataAutofill (ad);
   
		return ad;
   
	end
end


 
  
--***************************************************************************************************
--                                                                                                  *
--            ACTOR WRAPPER CLASS                                                                   *
--                                                                                                  *
--***************************************************************************************************

do
	local Actor = {}
	Actor.__index = Actor
	

	function cinematX.Actor.create(smbxObjRef, smbxClass)
	   
		local thisActorObj = {}                                                 -- our new object
		setmetatable (thisActorObj, Actor)              -- make Actor handle lookup
		thisActorObj.smbxObjRef = smbxObjRef                            -- initialize our object
		thisActorObj.smbxClass = smbxClass                               

		thisActorObj.npcid = -1                          
		if (thisActorObj.smbxClass == "NPC") then
			thisActorObj.npcid = smbxObjRef.id
		end
	   
		thisActorObj.name = "UNNAMED"
		thisActorObj.uid = -1
		thisActorObj.wasMismatched = false
		thisActorObj.isDirty = true
	   
		thisActorObj.animState = cinematX.ANIMSTATE_IDLE
	   
		thisActorObj.shouldFacePlayer = false
		thisActorObj.hasCloseAnim = true
		thisActorObj.closeIdleAnim = cinematX.ANIMSTATE_TALK
		thisActorObj.farIdleAnim = cinematX.ANIMSTATE_IDLE
		thisActorObj.talkAnim = cinematX.ANIMSTATE_TALK
		thisActorObj.walkAnim = cinematX.ANIMSTATE_WALK
		thisActorObj.runAnim = cinematX.ANIMSTATE_RUN

		thisActorObj.shouldDespawn = true
		thisActorObj.isDespawned = false
		thisActorObj.isDead = false
		thisActorObj.savestateX = {}
		thisActorObj.savestateY = {}
		thisActorObj.savestateSpeedX = {}
		thisActorObj.savestateSpeedY = {}          
		thisActorObj.savestateDir = {}     

		thisActorObj.isUnderwater = false
		thisActorObj.isResurfacing = false
		thisActorObj.isClimbing = false
		thisActorObj.hasGravity = true
		
	   
		thisActorObj.extraSprites = {}
		thisActorObj.extraSpriteAnim = {}
		thisActorObj.extraSpriteProps = {}
		thisActorObj.extraSpriteProps["speed"] = 1
		thisActorObj.extraSpriteProps["xOffset"] = -2
		thisActorObj.extraSpriteProps["yOffset"] = 0
		thisActorObj.extraSpriteFrame = -1
		thisActorObj.extraSpriteCounter = 0

		thisActorObj.helloVoice = ""
		thisActorObj.goodbyeVoice = ""
		thisActorObj.saidHello = false
		thisActorObj.helloCooldown = 0

	   
		thisActorObj.carryStyle = 0  -- 0 = held in front, 1 = above head
		thisActorObj.carriedNPC = nil
		thisActorObj.carriedBlock = nil
		thisActorObj.carriedObject = nil
		thisActorObj.isCarrying = false
		thisActorObj.carryPriority = 0
	   
	   
		thisActorObj.hpMax = 3
		thisActorObj.hp = thisActorObj.hpMax
		thisActorObj.hpLastFrame = thisActorObj.hp
	   
		thisActorObj.isHidden = false
		thisActorObj.actorCollisionOn = true
		thisActorObj.hitbox = nil
		if  thisActorObj.smbxClass ~= "Player"  then
			thisActorObj.hitbox = colliders.getSpeedHitbox (thisActorObj.smbxObjRef)
		end            
		thisActorObj.killOnZeroHp = false
		thisActorObj.indefiniteKO = false
	   
		thisActorObj.stunCountdown = 0         
		thisActorObj.koCountdown = -1          
		thisActorObj.reviveHp = 1
	   
		thisActorObj.justThrownCounter = 0
	   
	   
		thisActorObj.blockToFollow = nil
		thisActorObj.npcToFollow = nil
		thisActorObj.actorToFollow = nil
		thisActorObj.shouldTeleportToTarget = false
		thisActorObj.distanceToFollow = 64
		thisActorObj.distanceToAccel = 128
		thisActorObj.destWalkSpeed = 0
		thisActorObj.walkSpeed = 0
		thisActorObj.walkDestX = 0
		thisActorObj.shouldWalkToDest = false

		thisActorObj.framesSinceJump = 0
		thisActorObj.jumpStrength = 0

		thisActorObj.isInteractive = false
		thisActorObj.sceneString = ""
		thisActorObj.routineString = ""
		thisActorObj.messagePointer = ""
		thisActorObj.messageString = ""
		thisActorObj.nameString = ""
		thisActorObj.talkTypeString = ""
		thisActorObj.altSubString = nil
		thisActorObj.wordBubbleIcon = nil
		thisActorObj.messageIsNew = true

		thisActorObj.invincible = false
		thisActorObj.onGround = true
	   
		--thisActorObj.x = 0
		--thisActorObj.y = 0
		--thisActorObj.speedX = 0
		--thisActorObj.speedY = 0
		--thisActorObj.direction = 0

	   
		--windowDebug ("Actor created: "..thisActorObj.smbxClass)

		return thisActorObj
	end
	
	
end


--***************************************************************************************************
--                                                                                                  *
--            CINEMATX CONFIG FUNCTIONS                                                             *
--                                                                                                  *
--***************************************************************************************************




--***************************************************************************************************
--                                                                                                  *
--           DEBUG                                                                                  *
--                                                                                                  *
--***************************************************************************************************

 
 
 
--***************************************************************************************************
--                                                                                                  *
--            CINEMATX INIT FUNCTIONS                                                               *
--                                                                                                  *
--***************************************************************************************************
 

 
 
--***************************************************************************************************
--                                                                                                  *
--            CINEMATX UPDATE FUNCTIONS                                                             *
--                                                                                                  *
--***************************************************************************************************
 

 
 
 
--***************************************************************************************************
--                                                                                                  *
--            CINEMATX INPUT MANAGEMENT                                                             *
--                                                                                                  *
--***************************************************************************************************
 

 
 
 
 
 
 --**************************************************************************************************
--                                                                                                  *
--            COROUTINE FUNCTIONS                                                                   *
--                                                                                                  *
--            THIS SECTION OF CODE BLATANTLY COPIED & EDITED FROM                                   *
--            http://www.mohiji.org/2012/12/14/lua-coroutines/                                      *
--                                                                                                  *
--***************************************************************************************************
 
    
 
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            TEST ROUTINES                                                                         *
--                                                                                                  *
--***************************************************************************************************
 

 
 
--***************************************************************************************************
--                                                                                                  *
--            DIALOGUE MANAGEMENT                                                                   *
--                                                                                                  *
--***************************************************************************************************
 

 
 
 
--***************************************************************************************************
--                                                                                                  *
--            BOSS/DYNAMIC SEQUENCE MANAGEMENT                                                      *
--                                                                                                  *
--***************************************************************************************************
 

 
 
 
--***************************************************************************************************
--                                                                                                  *
--            SIDEQUEST MANAGEMENT                                                                  *
--                                                                                                  *
--***************************************************************************************************
 

 
 
--***************************************************************************************************
--                                                                                                  *
--           CUTSCENE MANAGEMENT                                                                    *
--                                                                                                  *
--***************************************************************************************************
 

 
       
         
--***************************************************************************************************
--                                                                                                  *
--           NPC MANAGEMENT                                                                         *
--                                                                                                  *
--***************************************************************************************************
 



--***************************************************************************************************
--                                                                                                  *
--           MAKE ALIASES WORK                                                                      *
--                                                                                                  *
--***************************************************************************************************

do
	setmetatable (cinematX, {
		__newindex = function (tbl, key, value)

		local alias = aliases[key]
		if alias ~= nil  then
			local cursor = tbl
			for i=1,#alias-1 do
				cursor = cursor[alias[i]]
			end
				cursor[alias[#alias]] = value
			else
				error("You're trying to set cinematX."..tostring(key)..", that isn't defined in the library.", 2)
			end
		end,

		__index = function (tbl, key)
			-- Bypass aliases when directly defined
			local r = rawget(tbl, key)
			if (r != nil) then return r end

			local alias = aliases[key]
			if alias ~= nil  then
				local cursor = tbl
				for _,key in ipairs(alias) do
					cursor = cursor[key]
				end
				return cursor
			else
				error ("You're trying to read cinematX."..tostring(key)..", that isn't defined in the library.", 2)
			end
		end
	})
end


 
       
return cinematX
