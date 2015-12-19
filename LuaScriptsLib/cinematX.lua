--***************************************************************************************
--                                                                                      *
--  cinematX.lua                                                                        *
--  v0.0.8m4                                                                            *
--  Documentation: http://engine.wohlnet.ru/pgewiki/CinematX.lua                        *
--  Discussion thread: http://talkhaus.raocow.com/viewtopic.php?f=36&t=15516            *
--                                                                                      *
--***************************************************************************************
 
local cinematX = {} --Package table
local graphX, textblox, eventu, npcconfig, colliders, inputs;
local libsLoaded = {}
local libsToLoad = {"graphX", "textblox", "eventu", "npcconfig", "colliders", "inputs"}
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
textblox = loadSharedAPI("textblox");
eventu = loadSharedAPI("eventu");
npcconfig = loadSharedAPI("npcconfig");
colliders = loadSharedAPI("colliders");
inputs = loadSharedAPI("inputs");
 
 
 
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
--            CONSTANTS AND ENUMS                                                                   *
--                                                                                                  *
--***************************************************************************************************
do     
	-- Resource path
	cinematX.resourcePath = "..\\..\\..\\LuaScriptsLib\\cinematX\\"
	cinematX.episodePath = "..\\"
   
	-- Checkpoint reached
	cinematX.midpointReached = false
   
	-- Animation states enum
	local i = 0;
   
	cinematX.ANIMSTATE_NUMFRAMES 	 =  i; i=i+1;
	cinematX.ANIMSTATE_BLANK         =  i; i=i+1;
	cinematX.ANIMSTATE_IDLE      	 =  i; i=i+1;
	cinematX.ANIMSTATE_TALK      	 =  i; i=i+1;
	cinematX.ANIMSTATE_TALK1         =  i; i=i+1;
	cinematX.ANIMSTATE_TALK2         =  i; i=i+1;
	cinematX.ANIMSTATE_TALK3         =  i; i=i+1;
	cinematX.ANIMSTATE_TALK4         =  i; i=i+1;
	cinematX.ANIMSTATE_TALK5         =  i; i=i+1;
	cinematX.ANIMSTATE_TALK6         =  i; i=i+1;
	cinematX.ANIMSTATE_TALK7         =  i; i=i+1;
	cinematX.ANIMSTATE_WALK          =  i; i=i+1;
	cinematX.ANIMSTATE_RUN           =  i; i=i+1;
	cinematX.ANIMSTATE_JUMP          =  i; i=i+1;
	cinematX.ANIMSTATE_FALL          =  i; i=i+1;
	cinematX.ANIMSTATE_DEFEAT        =  i; i=i+1;
	cinematX.ANIMSTATE_HURT          =  i; i=i+1;
	cinematX.ANIMSTATE_STUN          =  i; i=i+1;
	cinematX.ANIMSTATE_GRAB          =  i; i=i+1;
	cinematX.ANIMSTATE_GRABWALK      =  i; i=i+1;
	cinematX.ANIMSTATE_GRABRUN       =  i; i=i+1;
	cinematX.ANIMSTATE_GRABJUMP      =  i; i=i+1;
	cinematX.ANIMSTATE_GRABFALL      =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK        =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK1       =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK2       =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK3       =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK4       =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK5       =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK6       =  i; i=i+1;
	cinematX.ANIMSTATE_ATTACK7       =  i; i=i+1;
	cinematX.ANIMSTATE_CLIMB         =  i; i=i+1;  -- 31
	cinematX.ANIMSTATE_TOPPRESET =  i; i=i+1;
   
   
	-- Actor animation state table
	cinematX.npcAnimStates = {}
end
 
cinematX.actorsGrabbingNPCs = {}
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            ANIMDATA PARSER                                                                       *
--                                                                                                  *
--***************************************************************************************************
do
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
	 
   
	function cinematX.animDataAutofill (ad)

		if  ad[cinematX.ANIMSTATE_TALK] == nil  then
			ad[cinematX.ANIMSTATE_TALK] = ad[cinematX.ANIMSTATE_IDLE];
		end

		if  ad[cinematX.ANIMSTATE_HURT] == nil  then
			ad[cinematX.ANIMSTATE_HURT] = ad[cinematX.ANIMSTATE_IDLE];
		end

		if  ad[cinematX.ANIMSTATE_DEFEAT] == nil  then
			ad[cinematX.ANIMSTATE_DEFEAT] = ad[cinematX.ANIMSTATE_HURT];
		end

		if  ad[cinematX.ANIMSTATE_STUN] == nil  then
			ad[cinematX.ANIMSTATE_STUN] = ad[cinematX.ANIMSTATE_HURT];
		end

		if  ad[cinematX.ANIMSTATE_RUN] == nil  then
			ad[cinematX.ANIMSTATE_RUN] = ad[cinematX.ANIMSTATE_WALK];
		end

		if  ad[cinematX.ANIMSTATE_FALL] == nil  then
			ad[cinematX.ANIMSTATE_FALL] = ad[cinematX.ANIMSTATE_JUMP];
		end

		if  ad[cinematX.ANIMSTATE_GRAB] == nil  then
			ad[cinematX.ANIMSTATE_GRAB] = ad[cinematX.ANIMSTATE_IDLE];
		end

		if  ad[cinematX.ANIMSTATE_GRABWALK] == nil  then
			ad[cinematX.ANIMSTATE_GRABWALK] = ad[cinematX.ANIMSTATE_WALK];
		end            

		if  ad[cinematX.ANIMSTATE_GRABRUN] == nil  then
			ad[cinematX.ANIMSTATE_GRABRUN] = ad[cinematX.ANIMSTATE_RUN];
		end            

		if  ad[cinematX.ANIMSTATE_GRABJUMP] == nil  then
			ad[cinematX.ANIMSTATE_GRABJUMP] = ad[cinematX.ANIMSTATE_JUMP];
		end            

		if  ad[cinematX.ANIMSTATE_GRABFALL] == nil  then
			ad[cinematX.ANIMSTATE_GRABFALL] = ad[cinematX.ANIMSTATE_FALL];
		end            
	   
		if  ad[cinematX.ANIMSTATE_CLIMB] == nil  then
			ad[cinematX.ANIMSTATE_CLIMB] = ad[cinematX.ANIMSTATE_JUMP];
		end            
	   
		return ad;
	end
	 
	 
	function cinematX.readAnimData(path)
		local p = Misc.resolveFile(path);
		if(p == nil) then return nil; end
		if(string.sub(p,-5) ~= ".anim") then
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
				ad[cinematX.ANIMSTATE_NUMFRAMES] = tonumber(ts[2]);
				cnt=true;
				if(ad[cinematX.ANIMSTATE_NUMFRAMES] == nil) then
					error("Parse error. Not a valid frame number: "..ts[2],2)
				end
			elseif(ts[1] == "idle") then
				index = cinematX.ANIMSTATE_IDLE;
			elseif(ts[1] == "talk") then
				index = cinematX.ANIMSTATE_TALK;
			elseif(ts[1] == "talk1") then
				index = cinematX.ANIMSTATE_TALK1;
			elseif(ts[1] == "talk2") then
				index = cinematX.ANIMSTATE_TALK2;
			elseif(ts[1] == "talk3") then
				index = cinematX.ANIMSTATE_TALK3;
			elseif(ts[1] == "talk4") then
				index = cinematX.ANIMSTATE_TALK4;
			elseif(ts[1] == "talk5") then
				index = cinematX.ANIMSTATE_TALK5;
			elseif(ts[1] == "talk6") then
				index = cinematX.ANIMSTATE_TALK6;
			elseif(ts[1] == "talk7") then
				index = cinematX.ANIMSTATE_TALK7;
			elseif(ts[1] == "walk") then
				index = cinematX.ANIMSTATE_WALK;
			elseif(ts[1] == "run") then
				index = cinematX.ANIMSTATE_RUN;
			elseif(ts[1] == "jump") then
				index = cinematX.ANIMSTATE_JUMP;
			elseif(ts[1] == "fall") then
				index = cinematX.ANIMSTATE_FALL;
			elseif(ts[1] == "climb") then
				index = cinematX.ANIMSTATE_CLIMB;
			elseif(ts[1] == "hurt") then
				index = cinematX.ANIMSTATE_HURT;
			elseif(ts[1] == "stun") then
				index = cinematX.ANIMSTATE_STUN;
			elseif(ts[1] == "defeat") then
				index = cinematX.ANIMSTATE_DEFEAT;
			elseif(ts[1] == "attack") then
				index = cinematX.ANIMSTATE_ATTACK;
			elseif(ts[1] == "attack1") then
				index = cinematX.ANIMSTATE_ATTACK1;
			elseif(ts[1] == "attack2") then
				index = cinematX.ANIMSTATE_ATTACK2;
			elseif(ts[1] == "attack3") then
				index = cinematX.ANIMSTATE_ATTACK3;
			elseif(ts[1] == "attack4") then
				index = cinematX.ANIMSTATE_ATTACK4;
			elseif(ts[1] == "attack5") then
				index = cinematX.ANIMSTATE_ATTACK5;
			elseif(ts[1] == "attack6") then
				index = cinematX.ANIMSTATE_ATTACK6;
			elseif(ts[1] == "attack7") then
				index = cinematX.ANIMSTATE_ATTACK7;
			elseif(ts[1] == "grab") then
				index = cinematX.ANIMSTATE_GRAB;
			elseif(ts[1] == "grabwalk") then
				index = cinematX.ANIMSTATE_GRABWALK;
			elseif(ts[1] == "grabrun") then
				index = cinematX.ANIMSTATE_GRABRUN;
			elseif(ts[1] == "grabjump") then
				index = cinematX.ANIMSTATE_GRABJUMP;
			elseif(ts[1] == "grabfall") then
				index = cinematX.ANIMSTATE_GRABFALL;
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
--            GET TYPE                                                                              *
--                                                                                                  *
--***************************************************************************************************
local TYPE_PLAYER = 1;
local TYPE_NPC = 2;
local TYPE_BLOCK = 3;
local TYPE_ANIM = 4;
local TYPE_ACTOR = 5;
 
local function getType (obj)
	if (obj.TYPE ~= nil) then
		return obj.TYPE;
	elseif (obj.smbxObjRef ~= nil) then
		return TYPE_ACTOR;
	elseif (obj.powerup ~= nil) then
		return TYPE_PLAYER;
	elseif (obj.slippery ~= nil) then
		return TYPE_BLOCK;
	elseif (obj.timer ~= nil) then
		return TYPE_ANIM;
	elseif (obj.id ~= nil) then
		return TYPE_NPC;
	else
		error("Unknown object type.", 2);
	end
end
 
 
--***************************************************************************************************
--                                                                                                  *
--            ACTOR WRAPPER CLASS                                                                   *
--                                                                                                  *
--***************************************************************************************************
do
	Actor = {}
	Actor.__index = Actor

	function Actor.create(smbxObjRef, smbxClass)
	   
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

   
		   
	-- Memory functions
	do
			function Actor:getMem(offset,field)
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end
				   
					return self.smbxObjRef:mem (offset, field)
			end
		   
			function Actor:setMem(offset,field,value)
					if  (self.smbxObjRef == nil)  then  
							return;                
					end
				   
					self.smbxObjRef:mem (offset, field, value)
			end
		   
			function Actor:UIDCheck ()
					if  self.smbxClass == "Player"  then
							return true
					end
		   
					if   (self:getUIDMem ()  ~=  self.uid)  then
							if  (self.wasMismatched == false)  then
									self.wasMismatched = true
									cinematX.toConsoleLog ("UID MISMATCH: MEM " .. tostring(self:getUIDMem()) .. ", VAR " .. tostring(self.uid) .. "; NPCID MEM " .. self.smbxObjRef.id .. ", VAR " .. self.npcid)
							end
							return false;
					else
							return true;
							end
			end
		   
			function Actor:getUIDMem ()
					if  self.smbxClass == "Player"  then
							return 0
					end
		   
					return self:getMem (cinematX.ID_MEM, cinematX.ID_MEM_FIELD)
			end
	end
   
	-- Getters and setters for movement vars
	do
		function Actor:getDirection()
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end
				   
					if  self.smbxClass == "Player"  then
							return self.smbxObjRef:mem (0x106, FIELD_WORD)
				   
					else
							return self.smbxObjRef.direction
					end
		end
	   
		function Actor:setDirection(newDir)
					if  (self.smbxObjRef == nil)  then  
							return;                
					end
				   
					if self.smbxClass == "Player" then
							self.smbxObjRef:mem (0x106, FIELD_WORD, newDir)
					else
							self.smbxObjRef.direction = newDir
					end
		end
	   
			function Actor:setDirectionFromMovement()
					if  (self:getSpeedX () > 0)  then  
							self:setDirection (DIR_RIGHT)                  
					elseif  (self:getSpeedX () < 0)  then
							self:setDirection (DIR_LEFT)                   
					end
		end
	   
		function Actor:getX()
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end
		   
					local val = self.smbxObjRef.x
					return val
		end
	   
		function Actor:setX(newX)
					if  (self.smbxObjRef == nil)  then  
							return;                
					end
		   
					self.smbxObjRef.x = newX
		end
	   
		function Actor:getY()
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end
		   
					return self.smbxObjRef.y           
		end    
	   
		function Actor:setY(newY)
					if  (self.smbxObjRef == nil)  then  
							return;                
					end

					self.smbxObjRef.y = newY           
		end    
	   
			function Actor:getCenterX()
					return self:getX() + self.smbxObjRef.width*0.5
			end
		   
			function Actor:getCenterY()
					return self:getY() + self.smbxObjRef.height*0.5
			end
	   
			function Actor:getBottomY()
					return self:getY() + self.smbxObjRef.height
			end
	   
		function Actor:getSpeedX()
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end
		   
					return self.smbxObjRef.speedX      
		end
	   
		function Actor:setSpeedX(newSpd)
					if  (self.smbxObjRef == nil)  then  
							return;                
					end

					self.smbxObjRef.speedX = newSpd
		end
	   
		function Actor:getSpeedY()
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end

					return self.smbxObjRef.speedY      
		end
	   
		function Actor:setSpeedY(newSpd)
					if  (self.smbxObjRef == nil)  then  
							return;                
					end
		   
					self.smbxObjRef.speedY = newSpd
		end

	end
   
	-- Animation
	do                     
			function Actor:setExtraSprites (filename, rows, dirSplit)
					if  Misc.resolveFile(filename) ~= nil  and  rows ~= nil  and  dirSplit ~= nil  then    
							local file = Graphics.loadImage (filename)
							self.extraSprites["file"] = file
						   
							self.extraSprites["cols"] = 2
							if  dirSplit == false  then
									self.extraSprites["cols"] = 1
							end                            
							self.extraSprites["rows"] = rows
						   
							local pix = {}
							local w = 1
							local h = 1
							pix,w,h = Graphics.getPixelData (file)

							self.extraSprites["w"] = w
							self.extraSprites["h"] = h
							self.extraSprites["loaded"] = true
					else
							windowDebug ("Failed to set extra sprites for Actor:"..self.name)
					end
			end
		   
			function Actor:getAnimFrame ()
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end
				   
					--windowDebug (tostring(self.smbxObjRef:mem (0xE4, FIELD_WORD)))
				   
					return self.smbxObjRef:mem (0xE4, FIELD_WORD) --:getAnimFrame ()
			end
		   
			function Actor:setAnimFrame (newFrame)
					if  (self.smbxObjRef == nil)  then  
							return nil;                    
					end

					self.smbxObjRef:mem (0xE4, FIELD_WORD, newFrame)  --.setAnimFrame (newFrame)
			end
   
			function Actor:setAnimState (state)
			   self.animState = state
			end

			function Actor:setTalkAnimStates (closeIdle, farIdle, talk)
			   self.farIdleAnim = farIdle
			   self.closeIdleAnim = closeIdle
			   self.talkAnim = talk
			   self:setAnimState(farIdle)
			end
		   
			function Actor:getAnimState ()
			   return self.animState
			end
		   
			function Actor:overrideAnimation (animDataTable)
					cinematX.animDataAutofill(animDataTable)
					--windowDebug ("BEGINNING WORKS")
					local myState = self:getAnimState ()
				   
					local boundsString = animDataTable [myState]
					if (boundsString == nil) then
							--windowDebug ("BOUNDS STRING GATE")
							return;
					end
				   
					local dashCharPos = string.find (boundsString, "-")
					local minVal = tonumber(string.sub (boundsString, 0, dashCharPos-1))
					local maxVal = tonumber(string.sub (boundsString, dashCharPos+1))
			 
					-- Change to the appropriate animation based on the current movement
					self:setAnimStateByMovement ()
				   
					--windowDebug ("ANIM STATE BY MOVEMENT")
				   
					-- Clamp animation frames accordingly
					self:clampAnim (minVal, maxVal, npcconfig[self.npcid].frames)--animDataTable [cinematX.ANIMSTATE_NUMFRAMES])
			end
		   
									--gfxoffsetx, gfxoffsety, width, height, gfxwidth, gfxheight, frames, framespeed, framestyle,


			function Actor:clampAnim (minVal, maxVal, dirOffsetFrames)
			 
					-- Add an offset for flipped animations
					local dirOffset = dirOffsetFrames
					if (self:getDirection() == DIR_LEFT) then
							dirOffset = 0
					end

					-- Get the current animation frame
					animFrame = self:getAnimFrame ()
			 
					-- Clamp to the loop  
					if (animFrame < (minVal + dirOffset)  or  animFrame > (maxVal+dirOffset)) then
							self:setAnimFrame (minVal + dirOffset)
					end
			end
		   
			function Actor:setAnimStateByMovement ()

					-- Don't disrupt unique animations
					if self:getAnimState() < cinematX.ANIMSTATE_ATTACK1  
					or self:getAnimState() == self.talkAnim
					or self:getAnimState() == self.farIdleAnim
					or self:getAnimState() == self.closeIdleAnim  then

							-- If on ground
							if    (self.onGround == true)   then                           
									if    math.abs (self:getSpeedX()) < 1 then
											if    cinematX.dialogSpeaker == self   then
													self:setAnimState (self.talkAnim)
											else
												   
													if  self.isCarrying == true  then
															self:setAnimState (cinematX.ANIMSTATE_GRAB)                                                                                                            
													elseif (self:distanceActor (cinematX.playerActor) < 64) then
															self:setAnimState (self.closeIdleAnim)
													else
															self:setAnimState (self.farIdleAnim)
													end
														   
											end
									else
											if  math.abs (self:getSpeedX()) > 2  then
													if  self.isCarrying == true  then
															self:setAnimState (cinematX.ANIMSTATE_GRABRUN)
													else
															self:setAnimState (cinematX.ANIMSTATE_RUN)
													end
											elseif  self.isCarrying == true  then
													self:setAnimState (cinematX.ANIMSTATE_GRABWALK)
											else
													self:setAnimState (cinematX.ANIMSTATE_WALK)
											end
									end

							-- If jumping or falling
							elseif  self:getSpeedY() > 0 then
									if  self.isCarrying == true  then
											self:setAnimState (cinematX.ANIMSTATE_GRABFALL)
									else
											self:setAnimState (cinematX.ANIMSTATE_FALL)
									end
							else
									if  self.isCarrying == true  then
											self:setAnimState (cinematX.ANIMSTATE_GRABJUMP)
									else
											self:setAnimState (cinematX.ANIMSTATE_JUMP)
									end
							end
						   
							-- Stun overrides all other animations
							if  self.stunCountdown > 0  then
									if      self.onGround == true  then
											if      self.koCountdown > 0  then
													self:setAnimState (cinematX.ANIMSTATE_DEFEAT)
											else
													self:setAnimState (cinematX.ANIMSTATE_STUN)
											end
									else
											self:setAnimState (cinematX.ANIMSTATE_HURT)
									end
							end
					end
			end
				   
	end
   
	-- Relational
	do             
			function Actor:getScreenX ()
					local myX = self:getCenterX () - (player.x - player.screen.left)
					return myX
			end
		   
			function Actor:getScreenY ()
					local myY = self:getCenterY () - (player.y - player.screen.top)
					return myY
			end
		   
			function Actor:isOnScreen ()
					local withinRegion = false
				   
					if  (self:getScreenX () > -32   and
							 self:getScreenY () > -32   and
							 self:getScreenX () < 832   and
							 self:getScreenY () < 632)  then
							 
							 withinRegion = true
					end
				   
					return withinRegion
			end

			function Actor:relativeX (posX)
					return (posX - self:getCenterX())
			end
			 
			function Actor:relativeY (posY)
					return (posY - self:getCenterY())
			end
			 
			function Actor:distanceX (posX)
					return math.abs(self:relativeX (posX))
			end
			 
			function Actor:distanceY (posY)
					return math.abs(self:relativeY (posY))
			end
			 
			function Actor:distanceDestX ()
					return self:distanceX (self.walkDestX)
			end
							 
			function Actor:relativeActorX (targetActor)
					local dist = self:relativeX (targetActor:getX())
					return dist
			end
			 
			function Actor:relativeActorY (targetActor)
					local dist = self:relativeY (targetActor:getY())
					return dist
			end

			function Actor:distanceActorX (targetActor)
					local dist = self:distanceX (targetActor:getX())
					return dist
			end
			 
			function Actor:distanceActorY (targetActor)
					return self:distanceY (targetActor:getY())
			end      
			 
			function Actor:distancePos (xPos, yPos)
					local xDist = self:distanceX (xPos)
					local yDist = self:distanceY (yPos)
			 
					local diagDist = math.sqrt ((xDist^2) + (yDist^2))
					return diagDist
			end
		   
			function Actor:distanceActor (targetActor)
					return self:distancePos (targetActor:getCenterX(), targetActor:getCenterY())
			end
			 
			function Actor:dirToX (posX)
					if (self:relativeX (posX) > 0) then
							return DIR_RIGHT
					else
							return DIR_LEFT
					end
			end
					 
			function Actor:dirToActorX (targetActor)
					return self:dirToX (targetActor:getCenterX())
			end
   
   
			function Actor:forwardOffsetX (amount)
					local returnval = self:getCenterX() + dirSign(self:getDirection())*amount
					return returnval
			end
						   
			function Actor:topOffsetY (amount)
					return self:getY() - amount
			end
		   
			function Actor:bottomOffsetY (amount)
					return self:getBottomY() + amount
			end
   
   
			function Actor:closestNPC (id, maxDist)
					local localNpcTable = NPC.get (id,player.section)
					local closestRef = nil
					local closestDistance = maxDist or 9999
				   
					for k,v in pairs(localNpcTable)  do
							local distanceToThisNPC = self:distancePos (v.x, v.y)
						   
							if  distanceToThisNPC < closestDistance  and  v:mem(0x64, FIELD_WORD) == 0  and v:mem(0x122, FIELD_WORD) == 0  then
									closestRef = v
									closestDistance = distanceToThisNPC
							end
					end
				   
					return closestRef
			end
		   
			function Actor:closestBlock (id, maxDist)
					local blockTable = Block.get(id)
					local closestRef = nil
					local closestDistance = maxDist or 9999
				   
					for k,v in pairs(blockTable)  do
							local distanceToBlock = self:distancePos (v.x, v.y)
						   
							if  distanceToBlock  <  closestDistance   and   v.invisible == false  then
									closestRef = v
									closestDistance = distanceToBlock
							end
					end
				   
					return closestRef
			end
		   
	end
   
	-- Combat
	do
			tempMeleeActor = nil
			tempMeleeXOffset = 0
			tempMeleeYOffset = 0
			tempMeleeMotionType = 0
			tempMeleeDamageType = 0
			tempMeleeAnimState = 0
			tempMeleeCollider = nil
			tempMeleeSeconds = 0
			tempMeleeTargets = nil
		   
		   
			function Actor:meleeAttack (collider, xOffset, yOffset, damageType, motionType, targets, seconds, animState)
					tempMeleeActor = self
					tempMeleeXOffset = xoffset
					tempMeleeYOffset = yoffset
					tempMeleeMotionType = motionType
					tempMeleeDamageType = damageType
					tempMeleeAnimState = animState
					tempMeleeCollider = collider
					tempMeleeSeconds = seconds
					tempMeleeTargets = targets
				   
					cinematX.runCoroutine (cor_meleeAttack)
			end
				   
			function cor_meleeAttack ()
					--[[
							Motion types:
									00 = Maintain current momentum (or lack thereof)
									01 = Stop moving, then resume motion
									02 = Stop moving for the attack
									03 = Maintain horizontal, stop vertical
									04 = Maintain vertical, stop horizontal
					]]
					local actor = tempMeleeActor
					local moType = tempMeleeMotionType
					local damType = tempMeleeDamageType
					local xOff = tempMeleeXOffset
					local yOff = tempMeleeYOffset
					local animState = tempMeleeAnimState
					local seconds = tempMeleeSeconds
					local targets = tempMeleeTargets
				   
					local tempSpeedX = actor:getSpeedX()
					local tempSpeedY = actor:getSpeedY()
					local tempAnimState = actor.animState
				   
					local timePassed = 0
				   
					actor.setAnimState (animState)
				   
					while  (timePassed < seconds)  do
							------ Control movement based on motion type ------
						   
							-- Freeze completely
							if moType == 1  or  moType == 2  then
									actor:setSpeedX(0)
									actor:setSpeedY(0)
							end
						   
							collider.x = actor:getCenterX() + xOff
							collider.y = actor:getCenterY() + yOff
						   
						   
							------ Process collision ------
							for k,v in pairs(targets) do
									if  (collisionResult == colliders.collide(collider, v)) == true  then
											v:harm()
									end                                    
							end
						   
							------ Loop ------
							timePassed = timePassed + cinematX.deltaTime
							cinematX.yield()
					end
				   
					actor:setAnimState (tempAnimState)
				   
					if  moType == 1  then
							actor:setSpeedX(tempSpeedX)
							actor:setSpeedY(tempSpeedY)
					end
			end
		   
				   
			function Actor:projectile (npcid, xOffset, yOffset, speedX, speedY)
					local spawned = NPC.spawn (npcid, self:getCenterX() + xOffset, self:getCenterY() + yOffset,  player.section)
					spawned.speedX = speedX
					spawned.speedY = speedY
					return spawned
			end

		   
			function NPC:harm (damage)
					local hits = self:mem (0x148, FIELD_FLOAT)
					self:mem (0x148, FIELD_FLOAT, hits - damage)
			end
		   
			function Actor:harm (damage, stunFrames, knockbackX, knockBackY)
					self.hp = self.hp - damage
					self:knockback (knockbackX or 2, knockbackY or 5, stunFrames)
				   
					if self.hp  <=  0  then
							self:zeroHP ()
					end
			end

		   
			function Actor:stun (frames)
					if  frames == 0  then
							return
					end
					self.stunCountdown = frames
			end
		   
			function Actor:knockback (speedX, speedY, stunFrames)
					local dirFacing = self:getDirection ()
				   
					self:jump (speedY, false)
					self:setSpeedX (speedX)
				   
					self:setDirection (dirFacing)
					self:stun (stunFrames)
			end
		   
			function Actor:zeroHP ()
					if  self.killOnZeroHp == true  then
							self:kill ()
					else
							self:ko (self.indefiniteKO, 300)
					end
			end
		   
			function Actor:kill ()
					self.smbxObjRef:kill ()
			end
		   
			function Actor:ko (isIndefinite, koFrames)
					self.koCountdown = koFrames
					self.indefiniteKO = isIndefinite
			end

			function Actor:revive (amtRestored)
					self.koCountdown = -1
					self.stunCountdown = -1
				   
					self.hp = amtRestored or self.reviveHp
			end
	end
   
	-- Movement
	do
			function Actor:follow (targetObj, speed, howClose, shouldTeleport, easeDist)
					local targetType = getType (targetObj)
				   
					if  targetType == TYPE_ACTOR  then
							self:followActor (targetObj, speed, howClose, shouldTeleport, easeDist)
					elseif  targetType == TYPE_NPC  then
							self:followNPC (targetObj, speed, howClose, shouldTeleport, easeDist)                          
					elseif  targetType == TYPE_BLOCK  then
							self:followBlock (targetObj, speed, howClose, shouldTeleport, easeDist)                
					else
							return
					end
			end
		   
			function Actor:followActor (targetActor, speed, howClose, shouldTeleport, easeDist)
					self.shouldWalkToDest = true
					self.actorToFollow = targetActor
					self.distanceToFollow = howClose or 48
					self.destWalkSpeed = speed or 8
				   
					if shouldTeleport == nil  then
							shouldTeleport = false
					end
				   
					self.shouldTeleportToTarget = shouldTeleport
				   
					self.distanceToAccel = easeDist or 128
			end
		   
			function Actor:followNPC (targetNPC, speed, howClose, shouldTeleport, easeDist)
					self.npcToFollow = targetNPC
					self:walkToX (targetNPC.x, speed or 8, howClose or 48, easeDist or 128)
				   
					if shouldTeleport == nil  then
							shouldTeleport = false
					end
				   
					self.shouldTeleportToTarget = shouldTeleport
			end            
				   
			function Actor:followBlock (targetBlock, speed, howClose, shouldTeleport, easeDist)
					self.shouldWalkToDest = true
					self.blockToFollow = targetBlock
					self.distanceToFollow = howClose or 48
					self.destWalkSpeed = speed or 8
				   
					if shouldTeleport == nil  then
							shouldTeleport = false
					end
				   
					self.shouldTeleportToTarget = shouldTeleport
				   
					self.distanceToAccel = easeDist or 128
			end
   
			function Actor:stopFollowing ()
					self.shouldWalkToDest = false
					self.actorToFollow = nil
					self.blockToFollow = nil
					self.npcToFollow = nil
			end
   
   
   
			function Actor:grabNPC (npcRef, priority)
					local successful = true
					local playerHeldIndex = player:mem(0x154, FIELD_WORD)
					local npcUID = npcRef:mem(cinematX.ID_MEM, cinematX.ID_MEM_FIELD)
					local currentCarrierUID = cinematX.actorsGrabbingNPCs [npcUID]
					local currentCarrierActor = cinematX.indexedActors [currentCarrierUID]
				   
					self.carryPriority = priority  or  10
				   
				   
					-- Check for stealing against another player
					if  NPC(math.max(playerHeldIndex-1, 0)) == npcRef  then
							if  priority >= 10  then
									player:mem(0x154, FIELD_WORD, -1)
							else
									successful = false
							end
					end
				   
					-- Check for stealing against another actor
					if  currentCarrierUID ~= nil  then
							if  currentCarrierActor.carryPriority <= priority       then
									currentCarrierActor:dropCarried ()
									currentCarrierActor.isCarrying = false
									currentCarrierActor.carriedNPC = nil
									cinematX.actorsGrabbingNPCs[npcUID] = nil
							else
									successful = false
							end
					end
						   
						   
					-- If steal checks were passed, pick it up
					if  successful == true  then
							cinematX.actorsGrabbingNPCs[npcUID] = self.uid
							self.isCarrying = true
							self.carriedNPC = npcRef
							cinematX.playSFXSingle (23)
							self.carriedNPC:mem (0x136, FIELD_WORD, 3)
					end
			end
		   
			function Actor:dropCarried ()
					if  self.isCarrying == false  then
							return
					end
		   
					self.isCarrying = false
					local npcUID = self.carriedNPC:mem(cinematX.ID_MEM, cinematX.ID_MEM_FIELD)
				   
					self.carriedNPC:mem (0x136, FIELD_WORD, 0)
					cinematX.actorsGrabbingNPCs[npcUID] = nil
										   
					self.carriedNPC = nil
			end
		   
			function Actor:throwCarried (spdForward, spdUp)
					if  self.carriedNPC == nil  then
							self.isCarrying = false
							return
					end
				   
					self.isCarrying = false
					self.carriedNPC:mem (0x12C, FIELD_WORD, 0)
					--self.carriedNPC.x = self.carriedNPC.x + dirSign(self:getDirection()) * 24
					self.carriedNPC.speedX = dirSign(self:getDirection())  *  (spdForward  or 5)
					self.carriedNPC.speedY = -1 * (spdUp  or  5)
					cinematX.playSFXSingle (9)
				   
					local npcUID = self.carriedNPC:mem(cinematX.ID_MEM, cinematX.ID_MEM_FIELD)
					cinematX.actorsGrabbingNPCs[npcUID] = nil
				   
					self.carriedNPC = nil
					self.justThrownCounter = 30
			end
		   
						   
   
			function Actor:setSpawnX (newX)
					self.smbxObjRef:mem(0xAC, FIELD_WORD, newX)
			end
		   
			function Actor:setSpawnY (newY)
					self.smbxObjRef:mem(0xB4, FIELD_WORD, newY)
			end
   
   
			function Actor:setSpawnToCurrent ()
					local newSpawnX = cinematX.coordToSpawnX(self:getX())
					local newSpawnY = cinematX.coordToSpawnY(self:getY())
				   
					self:setSpawnX (newSpawnX)
					self:setSpawnY (newSpawnY)
			end
   
			function Actor:saveState (slot)
					--cinematX.toConsoleLog ("Saved state " .. tostring(slot))
				   
					self.savestateX [slot] = self:getX ()
					self.savestateY [slot] = self:getY ()
					self.savestateSpeedX [slot] = self:getSpeedX ()
					self.savestateSpeedY [slot] = self:getSpeedY ()
					self.savestateDir [slot] = self:getDirection ()
			end

			function Actor:loadState (slot)
					if  (self.savestateX [slot] == nil)  then
							return
					end
		   
					cinematX.toConsoleLog ("Loaded state" .. tostring(slot))
					self:setX (self.savestateX [slot])
					self:setY (self.savestateY [slot])
					self:setSpeedX (self.savestateSpeedX [slot])
					self:setSpeedY (self.savestateSpeedY [slot])
					self:setDirection (self.savestateDir [slot])
			end

		   
			function Actor:lookAtActor (target)
					self:setDirection (self:dirToActorX(target))
			end
		   
			function Actor:lookAtPlayer ()
					local newDir = self:dirToActorX (cinematX.playerActor)
					local oldDir = self:getDirection ()
				   
					if  newDir ~= oldDir  then
							self:setDirection (newDir)
					end
			end
		   
			function Actor:turnAround ()
					local newDir = self:getDirection ()
				   
					if  newDir == DIR_LEFT then
							newDir = DIR_RIGHT
					else
							newDir = DIR_LEFT                                      
					end
					self:setDirection (newDir)
			end
		   
			function Actor:lookAwayFromPlayer ()
					self:lookAtPlayer ()
					self:turnAround ()
			end
		   
			function Actor:walk (speed)
					if  self.stunCountdown > 0  or  self.koCountdown > 0  then
							return
					end
				   
					self.shouldWalkToDest = false
					self.walkSpeed = speed         
			end

			function Actor:walkForward (speed)
					if  self.stunCountdown > 0  or  self.koCountdown > 0  then
							return
					end
				   
					self.shouldWalkToDest = false
					self.walkSpeed = speed * self:getDirection ()
			end
		   
			function Actor:walkToX (dest, speed, precision, easeDist)              
					self.shouldWalkToDest = true
					self.walkDestX = dest
					self.destWalkSpeed = speed
					self.distanceToFollow = precision or 8
					self.distanceToAccel = easeDist or 128
			end

			function Actor:stopWalking ()
				self:walk (0)
			end
	
			
		   
			tempThisActor = nil
			tempOtherActor = nil
			tempDistance = 0
			tempForcedDelay = 0
		   
			function Actor:positionToTalk (otherActor, distance, shouldWait, forcedDelay)
					tempThisActor = self
					tempOtherActor = otherActor
					tempDistance = distance  or  64
					tempForcedDelay = forcedDelay  or  0
				   
					cinematX.runCoroutine(cor_positionToTalk)
				   
					if shouldWait == nil  then
							shouldWait = false
					end
						   
					if shouldWait == true then
							cinematX.waitSeconds(0.75)
					end
			end
		   
			function cor_positionToTalk ()
					--Text.showMessageBox ("talk positioning")
				   
					local thisActor = tempThisActor
					local otherActor = tempOtherActor
					local distance = tempDistance
					local forcedDelay = tempForcedDelay
				   
					local tempShouldFace = thisActor.shouldFacePlayer
					local positionedYet = false
					local targetPos = 0
					local offsetDir = otherActor:getDirection ()
					local timePassed = 0
				   
					thisActor:walk(0)
				   
					while  positionedYet == false  or  timePassed < forcedDelay  do
				   
							targetPos = otherActor:getCenterX() + distance*dirSign(offsetDir)
							--Text.print (tostring(targetPos), targetPos, thisActor:getCenterY()-64)
						   
							thisActor.shouldFacePlayer = false
							thisActor:walkToX (targetPos, 4, 1, 1)
						   
							positionedYet = false
							if  (math.abs(targetPos - thisActor:getCenterX()) <= 6)  then
									positionedYet = true
							end
							timePassed = timePassed + cinematX.deltaTime
							cinematX.yield()
					end
		   
					--Text.showMessageBox ("wrapping up talk positioning")
					cinematX.waitSeconds(0.05)
					thisActor:walk (0)
					thisActor:lookAtActor (otherActor)
					thisActor.shouldFacePlayer = tempShouldFace                    
					--Text.showMessageBox ("done with talk positioning")

			end
		   
		   
			function Actor:jump (strength, playSound)
					--if  self.smbxObjRef == player  then
				   
					if  playSound == nil  then
							playSound = true
					end
				   
					--else
							self:setSpeedY (-1 * strength)
						   
							if  playSound == true  then
									cinematX.playSFXSingle (1)     
							end
							self.framesSinceJump = 0
							self.jumpStrength = strength
					--end
			end
		   
			function Actor:teleportToPosition (newX, newY)
					-- Smoke puffs
					Animation.spawn (10, self:getX(), self:getY(), 0)
					Animation.spawn (10, self:getX()-8, self:getY()+16, 0)
					Animation.spawn (10, self:getX()+8, self:getY()+16, 0)
					Animation.spawn (10, self:getX(), self:getY()+24, 0)

					-- Teleport
					self:setX (newX)
					self:setY (newY)
						   
					-- Smoke puffs
					Animation.spawn (10, self:getX(), self:getY(), 0)
					Animation.spawn (10, self:getX()-8, self:getY()+16, 0)
					Animation.spawn (10, self:getX()+8, self:getY()+16, 0)
					Animation.spawn (10, self:getX(), self:getY()+24, 0)
			end
	end
		   
	-- Update
	function Actor:update ()
	   
		-- Skip update if the corresponding NPC/Player is destroyed
		local skipUpdate = false
	   
	   
		if  self.smbxClass == "Player"  then
			if  self.smbxObjRef.isValid == false  then
				skipUpdate = true
			end
		else
			if     (self.smbxObjRef == nil  or  self.smbxObjRef == 0  or  self.smbxObjRef == -1)  then  
				skipUpdate = true
			elseif (self.smbxObjRef:mem (0x122, FIELD_WORD) > 0   or   self:UIDCheck () == false  or self.smbxObjRef.id == 0)  then
				skipUpdate = true
			end
		end

		if  (skipUpdate == true)  then
			self.isDead = true
			return;
		end


		-- Update hidden state and collision toggle (with other actors)
		if  self.isHidden == true  then
			if  self.smbxClass == "Player"  then
				--self:setMem (0x13E, FIELD_WORD, 8)				
				self:setMem (0x122, FIELD_WORD, 8)
			else
		   		npcRef:mem(0xE4, FIELD_WORD, 255)
		   		npcRef:mem(0xE8, FIELD_DFLOAT, 0)
			end
		end
	   
		if  self.actorCollisionOn == false  then
			if  self.smbxClass == "Player"  then
			   self:setMem (0x122, FIELD_WORD, 8)
				--[[
				local startAdr = 0x130
			   
				for i=0,100,1 do
					local memVal = self:getMem (startAdr+2*i, FIELD_WORD)
		   
					if  math.abs(memVal) > 10  then
						memVal = memVal % 10
					end
		   
					--Text.print (intToHexString (startAdr+2*i)..": "..tostring(string.format("%.2f", memVal)), 3, 8 + 210*(math.floor(i/16)), 100 + 16*(i%16))
				end
			   
				self:setMem (0x13C, FIELD_WORD, 0)
				self:setMem (0x13E, FIELD_WORD, 0)
				--self:setMem (0x138, FIELD_FLOAT, 0)
				--self:setMem (0x132, FIELD_WORD, 100)
				--self:setMem (0xD8, FIELD_DFLOAT, 8)
				--self:setMem (0x142, FIELD_WORD, 2)                           
				]]
			else
		   
			end
		end
	   
	   
		-- Update hitbox
		self.hitbox = colliders.getSpeedHitbox (self.smbxObjRef)

	   
		-- Update HP
		if  self.hp <= 0  and  self.hpLastFrame > 0  then
			self:zeroHP ()
		end
		self.hpLastFrame = self.hp
	   
	   
		-- Decrement stun and KO countdowns
		self.stunCountdown = self.stunCountdown - 1
	   
		if  self.indefiniteKO == false  then
			self.koCountdown = self.koCountdown - 1
		end
	   
		if      self.koCountdown > 0            then
			self.stunCountdown = self.koCountdown
		end
	   
	   
		-- Revive from KO
		if  self.koCountdown == 0  then
			self.koCountdown = -1
		   
			self:revive ()
		end
	   
	   
		-- Display the actor's UID variables
		if  (cinematX.showDebugInfo == true)  then
			printText ("UID:" .. tostring(self:getUIDMem()) .. ", " .. self.uid, 4, self:getScreenX(), self:getScreenY()-32)
			printText (tostring(self:getAnimFrame()), 4, self:getScreenX(), self:getScreenY()-48)
		end
	   
		-- Update invincible
		if  (self.invincible == true)  then
			self:setMem (0x156, FIELD_WORD, 2)
		end

		-- Update on ground
		self.onGround = false
			   
		if  (self:getMem (0x00A, FIELD_WORD) == 2  or  self:getMem (0x120, FIELD_WORD) == 0xFFFF)  then
			self.onGround = true
		end
	   
	   
		-- Update jump signal
		self.framesSinceJump = self.framesSinceJump + 1
		--Text.print (tostring (self.framesSinceJump), self:getCenterX(), self:topOffsetY (16))
	   
	   
		-- Check if underwater
		self.isUnderwater = false
		if       self.smbxObjRef:mem (0x1C, FIELD_WORD) == 2   then
			self.isUnderwater = true
		end
	   
	   
		-- Decrement just thrown counter
		self.justThrownCounter = self.justThrownCounter - 1
	   
	   
		-- Following behavior
		do
			-- if following a block, NPC or another actor, set their position as the destination X
			local leaderToFollow = nil
			local leaderX = 0
			local leaderY = 0
			local leaderJumpStrength = 0
			local leaderJumpFrames = 0
			local leaderDirection = DIR_LEFT
		   
			if (self.actorToFollow ~= nil) then
				local leadActor = self.actorToFollow
			   
				leaderToFollow = leadActor
				leaderX = leadActor:getCenterX()
				leaderY = leadActor:getY()
				leaderJumpStrength = leadActor.jumpStrength
				leaderJumpFrames = leadActor.framesSinceJump
				leaderDirection = leadActor:getDirection ()
			end
		   
		   
			if (self.blockToFollow ~= nil) then
				leaderToFollow = self.blockToFollow
				leaderX = self.blockToFollow.x
				leaderY = self.blockToFollow.y
				leaderJumpStrength = 8
				leaderJumpFrames = 0
			   
				if  (leaderY < self:getY()-64  and  self.onGround == true)  then
					leaderJumpFrames = 13
					leaderJumpStrength = math.min(14, (self:getY() - leaderY) * 0.25)

				end
			   
				leaderDirection = self:getDirection ()
			end
				   
				   
			if (cinematX.validateNPCRef(self.npcToFollow)) then
				leaderToFollow = self.npcToFollow
				leaderX = leaderToFollow.x + (leaderToFollow.width*0.5)
				leaderY = leaderToFollow.y + (leaderToFollow.height*0.5)
				leaderJumpStrength = 8
				leaderJumpFrames = 0
			   
				if  (leaderY < self:getY()-64  and  self.onGround == true  and  self.justThrownCounter < 1)  then
					leaderJumpFrames = 13
					leaderJumpStrength = math.min(14, (self:getY() - leaderY) * 0.25)

				end
			   
				leaderDirection = self:getDirection ()
			else
				self.npcToFollow = nil
			end
				   
			if  leaderToFollow  ~=  nil  and  self.stunCountdown <= 0               then
				self.walkDestX = leaderX
			   
				-- Ground-based movement
				if  self.hasGravity == true  then
					-- If the actor being followed just jumped and they are above me, jump shortly after
					if  (leaderJumpFrames == 13     and  
						self:getSpeedY() == 0       and
						self:getY() > leaderY+64)      then
						 
						self:jump (leaderJumpStrength * 0.5)         
				   
					-- Swim
					elseif  (self:getY() > leaderY+32)      then
						local tempDistAdd = math.max(1, self:distanceActor (cinematX.playerActor) / 64)
					   
						if      (self.isUnderwater == true)  then
							self:jump (5 + tempDistAdd)
							self.isResurfacing = true
							
						elseif  (self.isResurfacing == true)  then
							self.isResurfacing = false
							self:jump (7 + tempDistAdd)
						end
					
					elseif  (self:getY() < leaderY-32)      then
						local tempDistAdd = -1*math.max(1, self:distanceActor (cinematX.playerActor) / 64)
					   
						if      (self.isUnderwater == true)  then
							if  self.hasGravity == false  then
								self:jump (-1.5*tempDistAdd)
							end
						elseif  (self.isResurfacing == true)  then
							self.isResurfacing = false
							self:jump (7 + tempDistAdd)
						end
					end
				
				else
					
				
				end
			   
			   
				-- Teleport to the actor's position if too far away
				if  (self:distancePos(leaderX,leaderY) > 350  and  self.shouldTeleportToTarget == true)   then
				   
					local telePosX = leaderX - self.distanceToFollow * leaderDirection
					local telePosY = leaderY - 32
				   
					if  true  then
						telePosX = leaderX
						telePosY = leaderY
					end
				   
					self:teleportToPosition (telePosX,
											 leaderY - 32)
				end
			end
		end

	   
		-- Control carrying
		if  cinematX.validateNPCRef(self.carriedNPC)  then
	   
			-- If the carried NPC is stolen by the player, either prevent it or stop carrying
			local playerHeldIndex = player:mem(0x154, FIELD_WORD)
			local carriedUID = self.carriedNPC:mem (cinematX.ID_MEM, cinematX.ID_MEM_FIELD)
		   
			if  NPC(math.max(playerHeldIndex-1, 0)) == self.carriedNPC              then
	   
				if  self.carryPriority  > 10  then
					player:mem(0x154, FIELD_WORD, -1)
				else
					cinematX.actorsGrabbingNPCs [carriedUID] = nil
					self.isCarrying = false
					self.carriedNPC = nil
				end
			end

				   
			-- Position the carried NPC above/in front of the actor
			local carryX = self:getX() + 24*dirSign (self:getDirection ())
			local carryY = self:getBottomY() - 36
		   
			if  self.carryStyle == 1  then
				carryX = self:getX()
				carryY = self:getY()-28
			end
		   
			if  self.carriedNPC ~= nil  then
				self.carriedNPC:mem (0x136, FIELD_WORD, -1)
				self.carriedNPC:mem (0x12C, FIELD_WORD, 2)
				self.carriedNPC:mem (0x12E, FIELD_WORD, 30)
				self.carriedNPC:mem (0x156, FIELD_WORD, 2)
				self.carriedNPC.x = carryX + self:getSpeedX()
				self.carriedNPC.y = carryY + self:getSpeedY()
				self.carriedNPC.speedX = 0
				self.carriedNPC.speedY = 0
			   
			end
		else
			self.carriedNPC = nil
		end
	   
	   
		-- Prevent despawning  --NPCMemSet,NPC ID,0x12A,55,0,0,w, thanks Willhart!
		if (self.shouldDespawn == false) then
			self.smbxObjRef:mem (0x12A, FIELD_WORD, 180)
		end
	   
	   
		-- Check whether or not the NPC is despawned
		self.isDespawned = true

		if (self.smbxObjRef:mem (0x12A, FIELD_WORD) == 55) then
			self.isDespawned = false
		end
	   
	   
		-- Old method of preventing despawning
		--[[
			-- Check to see if the actor is despawned
			self.isDespawned = false
		   
			if (self:isOnScreen () == false) then
				self.isDespawned = true
			end
		   
			-- If despawned, load from state
			if  (self.shouldDespawn == false  and  self.isDespawned == true)  then
				self:loadState(0)
			end
		--]]
	   
		-- Look at player if allowed to
		if  self.shouldFacePlayer == true  and  self.stunCountdown < 0   then
			self:lookAtPlayer ()
		end
	   
		-- Say hello if player approaches
		self.helloCooldown = self.helloCooldown - 1
	   
		if (cinematX.currentSceneState ~= cinematX.SCENESTATE_CUTSCENE)  and  self.stunCountdown <= 0  then
			if  self:distanceActorX (cinematX.playerActor) < 64  then
				if (self.saidHello == false  and  self.helloCooldown <= 0) then
					if  (self.helloVoice ~= "")  then
						cinematX.playSFXSDLSingle (self.helloVoice)
					end
					self.saidHello = true
				end
				   
			elseif  (self:distanceActorX (cinematX.playerActor) < 196)  then
				--
			elseif  (self:distanceActorX (cinematX.playerActor) < 400)  then
				if  (self.saidHello == true)  then
					if  (self.goodbyeVoice ~= "")  then
						cinematX.playSFXSDLSingle (self.goodbyeVoice)
					end
					self.saidHello = false
					self.helloCooldown = 300
				end
				   
			elseif  (self:distanceActorX (cinematX.playerActor) < 800)  then
				self.saidHello = false
				self.helloCooldown = 0
			end
		end
	   
	   
		-- Walk to destination
		if  (self.shouldWalkToDest == true)  then
		   
			-- Get distance
			local destDist = self:distanceDestX () - self.distanceToFollow
			if (destDist < 0) then destDist = 0 end
		   
			-- Get direction multiplier
			local dirMult = dirSign (self:dirToX (self.walkDestX))
		   
			-- Get acceleration multiplier
			local accelMult = invLerp (0,self.distanceToAccel, destDist)
		   
			-- Walk
			--self.walkSpeed = 0
		   
			self.walkSpeed = dirMult * accelMult * math.min(self.destWalkSpeed, destDist * 0.125)
		end
	   
		-- Perform walking
		if (self.walkSpeed ~= 0  and  (smbxObjRef == player  and  cinematX.currentSceneState ~= SCENESTATE_CUTSCENE) == false  and  self.stunCountdown <= 0  and  self.koCountdown <= 0) then
			self:setDirectionFromMovement ()
			self:setSpeedX (self.walkSpeed)
		end
	   
	   
		-- Stop movement if KO'd or stunned
		if  ((self.stunCountdown > 0  or  self.koCountdown > 0)  and  self.onGround == true)   then
			self:setSpeedX(0)
		end
	   
	   
		-- Update hitbox
		self.hitbox = colliders.getSpeedHitbox (self.smbxObjRef)
					   
	   
		-- Update extra sprites
		if  self.extraSprites["loaded"] == true  and  self.extraSpriteAnim ~= nil  and  next(self.extraSpriteAnim) ~= nil  then
		   
			local extraAnimLength = #self.extraSpriteAnim
								   
			self.extraSpriteFrame = (self.extraSpriteFrame + self.extraSpriteProps["speed"]*0.2) % extraAnimLength
			
			-- Looping
			if  self.extraSpriteAnim[math.floor(self.extraSpriteAnim) + 1] < 0  then
			
			local extraIndex = math.floor(self.extraSpriteFrame) + 1
			local extraCol = 1
		   
			local extraW = self.extraSprites["w"] / self.extraSprites["cols"]
			local extraH = self.extraSprites["h"] / self.extraSprites["rows"]
		   
			if  self.extraSprites["cols"] == 2  and  self:getDirection() == DIR_RIGHT  then
				extraCol = 2
			end
		   
			Graphics.drawImageToSceneWP (self.extraSprites["file"], self:getCenterX() - 0.5*extraW + self.extraSpriteProps["xOffset"], self:getCenterY() - 0.5*extraH + self.extraSpriteProps["yOffset"], (extraCol-1)*extraW, self.extraSpriteAnim[extraIndex]*extraH, extraW, extraH, 0.5)
		end
	   
	   
		-- Save state to prevent despawning
		if  (self.shouldDespawn == false  and  self.isDespawned == false)  then
			self:setSpawnToCurrent ()
			--self:saveState(0)
		end
	   
	   
		-- If this actor is a generator, disable interactions
		if  (self.smbxClass == "NPC")  then
			if  (self.smbxObjRef:mem (0x64, FIELD_WORD) == 1)  then
				isInteractive = false
			end
		end
	end
   
   
   
	function cinematX.spawnPlayerActors (amount, chars, powerups)
	   
		local originalTable = Player.get ()
		local originalCount = mem (0x00B2595E, FIELD_WORD)
	   
	   
		-- Spawn them
		Misc.cheatBuffer("superbdemo128")
			   
		mem (0x00B2595E, FIELD_WORD, amount)   
	   
	   
		-- Remove the bomb anim and sound
		local bombAnim = Animation.getIntersecting(player.x-32, player.y-32, player.x+32, player.y+32)[1]
		if  bombAnim ~= nil  then
			bombAnim.y = bombAnim.y + 10000
		end
	   
		Audio.clearSFXBuffer()
	   
	   
		-- Get the table of new actors
		local newTable = {}
	   
		for  k,v in pairs(Player.get())  do
			if  v ~= player  then
				local newActor = Actor.create (v, "Player")
				v.speedX = 0
				v.speedY = 0
				v.x = player.x - 56*(k-1)
				v.y = player.y
	   
				-- Assign character types
				if  chars ~= nil  then
					if chars[k-1] ~= nil  then
						v.character = chars[k-1]
					end
				end
	   
				-- Assign powerups
				if  powerups ~= nil  then
					if powerups[k-1] ~= nil  then
						v.powerup = powerups[k-1]
					end
				end
	   
				-- Add the actor to the new table
				newTable[k-1] = newActor
				--v.character = chars[ k ]
			end
		end
	   
		return newTable
	end
   
end
 
 
 end                      

--***************************************************************************************************
--                                                                                                  *
--            CINEMATX CONFIG FUNCTIONS                                                             *
--                                                                                                  *
--***************************************************************************************************

do
        cinematX.overrideNPCMessages = true
        cinematX.showDebugInfo = false
        cinematX.shouldGenerateActors = true
        cinematX.actorCriteria = nil
        cinematX.transitionBetweenSections = true
        cinematX.useNewUI = true
        cinematX.useHUDBox = false
        cinematX.textbloxSubtitle = true
        cinematX.freezeDuringCutscenes = true
       
        --cinematX.npcsToIgnore = {}
       
       
        function cinematX.config (toggleOverrideMsg, showDebug, useHUDBox, useTransitions, oglUI, sceneFreeze)
               
                -- Set default values
                if  toggleOverrideMsg                   == nil  then
                        toggleOverrideMsg = true
                end    
                if  showDebug                           == nil  then
                        showDebug = false
                end    
                if  useHUDBox                           == nil  then
                        useHUDBox = false
                end    
                if  useTransitions                      == nil  then
                        useTransitions = true
                end    
                if  oglUI                               == nil  then
                        oglUI = true
                end    
                if  sceneFreeze                         == nil  then
                        sceneFreeze = true
                end
               
       
                -- Assign values
                cinematX.overrideNPCMessages = toggleOverrideMsg
                cinematX.showDebugInfo = showDebug
                cinematX.useHUDBox = useHUDBox
                cinematX.transitionBetweenSections = useTransitions
                cinematX.useNewUI = oglUI
                cinematX.freezeDuringCutscenes = sceneFreeze
        end
       
       
        function cinematX.configExt (settings)
                if  settings ~= nil  then
                       
                        if  settings["overrideNpcText"] ~= nil  then
                                cinematX.overrideNPCMessages = settings["overrideNpcText"]
                        end
                       
                        if  settings["debug"] ~= nil  then
                                cinematX.showDebugInfo = settings["debug"]
                        end
                       
                        if  settings["hudBox"] ~= nil  then
                                cinematX.useHUDBox = settings["hudBox"]
                        end
                       
                        if  settings["sectionTransitions"] ~= nil  then
                                cinematX.transitionBetweenSections = settings["sectionTransitions"]
                        end
                       
                        if  settings["imageUi"] ~= nil  then
                                cinematX.useNewUI = not settings["imageUi"]
                        end
                       
                        if  settings["cutsceneFreeze"] ~= nil  then
                                cinematX.freezeDuringCutscenes = settings["cutsceneFreeze"]
                        end
                       
                        if  settings["noActors"] ~= nil  then
                                cinematX.shouldGenerateActors = not settings["noActors"]
                        end
                       
                        if      settings["textbloxSub"] ~= nil  then
                                cinematX.textbloxSubtitle = settings["textbloxSub"]
                        end
                end
        end
end
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            CINEMATX INIT FUNCTIONS                                                               *
--                                                                                                  *
--***************************************************************************************************
 
do
	cinematX.delayedInitCounter = 0
	cinematX.delayedInitCalledFromUpdate = false
	cinematX.delayedInitSectionNum = -1
   
	cinematX.initCalledYet = false
   
   
   
   
	function cinematX.initLevel ()
		-- Prevent this function from being called twice
		if  (cinematX.initCalledYet == true)  then  return  end

		cinematX.playerActor = Actor.create(player, "Player")


		-- Call all of the sub init functions  
		cinematX.initTiming ()
		cinematX.initHUD ()
		cinematX.initCamera ()
		cinematX.initDialog ()
		cinematX.initCutscene ()
		cinematX.initRace ()
		cinematX.initBoss ()
		cinematX.initQuestSystem ()
		cinematX.initDebug ()
	   
		cinematX.initCalledYet = true
	end
   
	function cinematX.initSection ()
		if   cinematX.transitionBetweenSections == true   then
				cinematX.fadeScreenIn (0.5)
		end
	   
		cinematX.initActors ()
	end
   
	function cinematX.delayedInitLevel ()
		--windowDebug ("TEST LEVEL")
		cinematX.updateMidpointCheck ()
	   
		cinematX.indexActors (false)
		cinematX.delayedInitCounter = cinematX.delayedInitCounter + 1
	   
		-- Play a cutscene if specified in an onLoad event
		if  (cinematX.levelStartScene ~= nil  and  cinematX.midpointReached == false)  then
				cinematX.runCutscene (cinematX.levelStartScene)
		end
	end
   
   
	function cinematX.delayedInitSection ()
		--windowDebug ("TEST SECTION")
		cinematX.updateMidpointCheck ()

		-- Play a cutscene if specified in an onLoad event
		if  (cinematX.sectionStartScene[cinematX.delayedInitSectionNum] ~= nil)  then
				cinematX.runCutscene (cinematX.sectionStartScene [cinematX.delayedInitSectionNum])
		end
	   
		--[[
		-- Play level start scene
		if  (cinematX.levelStartScene ~= nil  and  cinematX.levelStartScenePlayed == false  and  cinematX.midpointReached == false)  then
				cinematX.levelStartScenePlayed = true
				cinematX.runCutscene (cinematX.levelStartScene)
		end
		--]]
	end
   
	cinematX.currentFrameTime = 0
   
   
	function cinematX.initTiming ()
		cinematX.currentFrameTime = os.clock()
		cinematX.deltaTime = 0
	end
   
   
	cinematX.playerHidden = false
   
	cinematX.actorCount = 0
	cinematX.npcCount = 0
   
	cinematX.indexedActors = {}
	cinematX.indexedNPCRefs = {}
	cinematX.npcMessageKeyIndexes = {}

	cinematX.nilNPCPointer = nil
	cinematX.currentMessageNPCObj = nil
	cinematX.currentMessageNPCIndex = nil
	cinematX.currentMessageActor = nil
   
	cinematX.screenTintColor = 0xFFFFFF00
   
	cinematX.letterboxAlphaMax = 0.9
	cinematX.letterboxAlphaMult = 0
	cinematX.letterboxAlphaRate = 0.1
   
	cinematX.screenTransitionAmt = 0
	cinematX.screenTransitionTime = 0.5

	cinematX.currentImageRef_hud            =       nil    
	cinematX.currentImageRef_screen         =       nil    

   
   
	function cinematX.initDialog ()

		-- Speaker object
		cinematX.dialogSpeaker = nil

		-- _____
		--cinematX.dialogSpeakerFrame = 0

		-- Text display countdown
		cinematX.dialogTextTime = 0

		-- Speaker animation countdown
		cinematX.dialogSpeakerTime = 0

		-- Dialogue update rate (characters per frame)
		cinematX.dialogTextSpeed = 1

		-- Check whether a line of dialogue or subtitle is being processed
		cinematX.dialogOn = false

		-- Speaker name
		cinematX.dialogName = ""

		-- Full line of dialogue being spoken with timing commands
		cinematX.dialogTextFull = ""

		-- Currently-revealed dialogue string
		cinematX.dialogText = ""
	   
		-- Line of dialogue being spoken with timing commands
		cinematX.dialogTextCommands = ""

		-- Individual lines of the line of dialogue being spoken
		--cinematX.dialogTextLine1 = ""
		--cinematX.dialogTextLine2 = ""
		--cinematX.dialogTextLine3 = ""
		--cinematX.dialogTextLine4 = ""

		-- Total number of characters in the dialogue string
		cinematX.dialogNumCharsTotal = 0

		-- Number of characters revealed in the displayed dialogue
		-- Number of characters revealed in the displayed dialogue
		cinematX.dialogNumCharsCurrent = 0

		-- Number of characters revealed w/ bypassing commands
		cinematX.dialogNumCharsCommands = 0

		-- Can the player press the key to skip lines?
		cinematX.dialogSkippable = true

		-- Can the player press the key to skip the current line?
		cinematX.thisDialogSkippable = true
		
		-- Is the current line of dialogue a question?
		cinematX.dialogIsQuestion = false

		-- Player's choice for the question
		cinematX.questionPlayerResponse = nil
	   
		-- Does the player have to press a key to continue?
		cinematX.dialogEndWithInput = true
		
		-- Does the player have to press a key to continue this specific message?
		cinematX.thisDialogAutoEnd = true

		--
		cinematX.dialogLineEnded = false
		
	   

	   
		-- Textblox subtitle
		cinematX.IMGNAME_FONT1   =      cinematX.getImagePath ("font_subtitle.png")
		cinematX.IMGREF_FONT1    =      Graphics.loadImage (cinematX.IMGNAME_FONT1)
	   
		cinematX.subtitleFontProps = {}
		cinematX.subtitleFontProps ["charWidth"] = 16
		cinematX.subtitleFontProps ["charHeight"] = 16
		cinematX.subtitleFontProps ["image"] = cinematX.IMGREF_FONT1
		cinematX.subtitleFontProps ["kerning"] = -1
	   
		cinematX.subtitleFont = Font.create (textblox.FONTTYPE_SPRITE, cinematX.subtitleFontProps)
	   
	   
		cinematX.subtitleBoxProps = {}
		cinematX.subtitleBoxProps ["width"] = 800-24
		cinematX.subtitleBoxProps ["height"] = 132-32
		cinematX.subtitleBoxProps ["scaleMode"] = textblox.SCALE_FIXED
		cinematX.subtitleBoxProps ["bind"] = textblox.BIND_SCREEN
		cinematX.subtitleBoxProps ["textAlpha"] = 1
		cinematX.subtitleBoxProps ["textAnchorX"] = textblox.HALIGN_LEFT
		cinematX.subtitleBoxProps ["textAnchorY"] = textblox.VALIGN_TOP
		cinematX.subtitleBoxProps ["boxAnchorX"] = textblox.HALIGN_LEFT
		cinematX.subtitleBoxProps ["boxAnchorY"] = textblox.VALIGN_TOP
		cinematX.subtitleBoxProps ["boxColor"] = 0x999900AA
		cinematX.subtitleBoxProps ["boxType"] = textblox.BOXTYPE_NONE
		cinematX.subtitleBoxProps ["font"] = cinematX.subtitleFont
		cinematX.subtitleBoxProps ["speed"] = 0.5
		cinematX.subtitleBoxProps ["marginX"] = 4
		cinematX.subtitleBoxProps ["marginY"] = 4
		cinematX.subtitleBoxProps ["visible"] = true
		cinematX.subtitleBoxProps ["autoClose"] = false
	   
		cinematX.subtitleBoxBlock = TextBlock.create (8, 468+32, "", cinematX.subtitleBoxProps)
	   
	   
		-- Has this function been called?
		cinematX.dialogInitCalled = true
	end

	function cinematX.initCamera ()
		cinematX.cameraFocusX = 0
		cinematX.cameraFocusY = 0
	   
		cinematX.cameraTargetActor = -1
	   
		cinematX.cameraOffsetX = 0
		cinematX.cameraOffsetY = 0
	   
		cinematX.cameraXSpeed = 0
		cinematX.cameraYSpeed = 0
	   
		cinematX.cameraControlOn = false
	   
		cinematX.cameraSize = 1
	end


	-- Cutscene to play at the beginning of the level
	cinematX.levelStartScene = nil
	cinematX.levelStartScenePlayed = false
   
	-- Cutscenes to play at the beginning of each section
	cinematX.sectionStartScene = {}
   
	function cinematX.initCutscene ()
 
		-- Cutscene/Boss AI timing variables
		cinematX.cutsceneFrame = 0
 
		-- Can the entire cutscene be skipped?
		cinematX.cutsceneSkippable = true

		-- Player input currently active?
		cinematX.playerInputActive = true

		-- Current cutscene time in frames
		cinematX.cutsceneFrame = 0

		-- Current cutscene if there are multiple
		cinematX.cutsceneIndex = -1

		-- Scene state
		cinematX.SCENESTATE_PLAY = 0
		cinematX.SCENESTATE_CUTSCENE = 1
		cinematX.SCENESTATE_BATTLE = 2
		cinematX.SCENESTATE_RACE = 3

		cinematX.changeSceneMode (cinematX.SCENESTATE_PLAY)
	end

	function cinematX.initRace ()
		-- The opponent in a race
		cinematX.raceEnemyActor = nil
	   
		cinematX.raceActive = false
		cinematX.raceWinRoutine = nil
		cinematX.raceLoseRoutine = nil
	   
		cinematX.raceStartX = nil
		cinematX.raceEndX = nil
	   
		cinematX.racePlayerPos = 0.000000
		cinematX.raceEnemyPos = 0.000000               
	end
   
   
	function cinematX.initBoss ()
		-- Current attack pattern time in frames
		cinematX.battleFrame = 0  

		-- "Phase" of the boss' attack pattern
		cinematX.battlePhase = 0

		-- For sequential attack patterns, this is the current step of the pattern
		cinematX.bossAttackPattern = 0

		-- Name for boss' HP bar
		cinematX.bossName = "BOSS NAME"

		-- Boss HP
		cinematX.bossHPMax = 8
		cinematX.bossHP = 8
		cinematX.bossHPEase = 8

		-- Boss health display modes
		cinematX.BOSSHPDISPLAY_NONE = 0
		cinematX.BOSSHPDISPLAY_HITS = 1
		cinematX.BOSSHPDISPLAY_BAR1 = 2
		cinematX.BOSSHPDISPLAY_BAR2 = 3
	   
		-- The current display mode
		cinematX.bossHPDisplayType = cinematX.BOSSHPDISPLAY_BAR2               
	end

   
	function cinematX.getImagePath (filename)              
		--windowDebug ("TEST")
	   
		local localImagePath = Misc.resolveFile (filename)  
									   
		if  localImagePath  ~=  nil  then
			return localImagePath
			--return filename
		   
			--[[
			windowDebug ()
			return cinematX.episodePath..filename
			--]]
		end
	   
		return cinematX.resourcePath..filename
	end
   
   
	function cinematX.initHUD ()
		   
		-- Detect whether the computer can take advantage of the OpenGL renderer
		cinematX.canUseNewUI = Graphics.isOpenGLEnabled ()

		-- Color code constants
		cinematX.COLOR_TRANSPARENT = 0xFFFFFF--0xFB009D
	   
	   
		-- Filename constants
		cinematX.IMGNAME_BLANK	 				=	cinematX.getImagePath ("blankImage.png")
		cinematX.IMGNAME_LETTERBOX 				=	cinematX.getImagePath ("letterbox.png")
		cinematX.IMGNAME_FULLOVERLAY			=	cinematX.getImagePath ("fullScreenOverlay.png")
		cinematX.IMGNAME_NOGLFADE				=	cinematX.getImagePath ("noglFade.png")
		cinematX.IMGNAME_NOGLBOX_RED			=	cinematX.getImagePath ("noglBox_red.png")
		cinematX.IMGNAME_NOGLBOX_GREEN			=	cinematX.getImagePath ("noglBox_green.png")
		cinematX.IMGNAME_PLAYDIALOGBOX			=	cinematX.getImagePath ("playSubtitleBox.png")
		cinematX.IMGNAME_QUESTBOX				=	cinematX.getImagePath ("questBox.png")
		cinematX.IMGNAME_BOSSHP_RIGHT 			= 	cinematX.getImagePath ("bossHP_right.png")
		cinematX.IMGNAME_BOSSHP_LEFT 			=	cinematX.getImagePath ("bossHP_left.png")
		cinematX.IMGNAME_BOSSHP_EMPTY 			= 	cinematX.getImagePath ("bossHP_midE.png")
		cinematX.IMGNAME_BOSSHP_FULL 			=	cinematX.getImagePath ("bossHP_midF.png")
		cinematX.IMGNAME_BOSSHP_BG 				=	cinematX.getImagePath ("bossHP_bg.png")
		
		cinematX.IMGNAME_RACEBG 				=	cinematX.getImagePath ("raceBg.png")
		cinematX.IMGNAME_RACEPLAYER				=	cinematX.getImagePath ("racePlayer.png")
		cinematX.IMGNAME_RACEOPPONENT			=	cinematX.getImagePath ("raceOpponent.png")
		cinematX.IMGNAME_RACEFLAGSTART			=	cinematX.getImagePath ("raceFlag_Start.png")
		cinematX.IMGNAME_RACEFLAGEND			=	cinematX.getImagePath ("raceFlag_End.png")
		
		cinematX.IMGNAME_HUDBOX					=	cinematX.getImagePath ("hudBox.png")
		
		cinematX.IMGNAME_NPCICON_TALK_O	 		=	cinematX.getImagePath ("npcIcon_TalkOld.png")
		cinematX.IMGNAME_NPCICON_TALK_N 		=	cinematX.getImagePath ("npcIcon_TalkNew.png")
		cinematX.IMGNAME_NPCICON_INSPECT_O 		=	cinematX.getImagePath ("npcIcon_InspectOld.png")
		cinematX.IMGNAME_NPCICON_INSPECT_N 		=	cinematX.getImagePath ("npcIcon_InspectNew.png")
		cinematX.IMGNAME_NPCICON_QUEST_O 		=	cinematX.getImagePath ("npcIcon_QuestOld.png")
		cinematX.IMGNAME_NPCICON_QUEST_N 		=	cinematX.getImagePath ("npcIcon_QuestNew.png")
		cinematX.IMGNAME_NPCICON_PRESSUP 		=	cinematX.getImagePath ("npcIcon_PressUp.png")
		
	
	
		-- Image slot and filename constants
		cinematX.IMGREF_BLANK				=	Graphics.loadImage (cinematX.IMGNAME_BLANK)
		cinematX.IMGREF_LETTERBOX 			=	Graphics.loadImage (cinematX.IMGNAME_LETTERBOX)
		cinematX.IMGREF_FULLOVERLAY			=	Graphics.loadImage (cinematX.IMGNAME_FULLOVERLAY)
		cinematX.IMGREF_NOGLFADE			=	Graphics.loadImage (cinematX.IMGNAME_NOGLFADE)
		cinematX.IMGREF_NOGLBOX_RED			=	Graphics.loadImage (cinematX.IMGNAME_NOGLBOX_RED)
		cinematX.IMGREF_NOGLBOX_GREEN		=	Graphics.loadImage (cinematX.IMGNAME_NOGLBOX_GREEN)
		cinematX.IMGREF_QUESTBOX			=	Graphics.loadImage (cinematX.IMGNAME_QUESTBOX)
		cinematX.IMGREF_PLAYDIALOGBOX		=	Graphics.loadImage (cinematX.IMGNAME_PLAYDIALOGBOX)
		cinematX.IMGREF_BOSSHP_RIGHT 		= 	Graphics.loadImage (cinematX.IMGNAME_BOSSHP_RIGHT)
		cinematX.IMGREF_BOSSHP_LEFT 		=	Graphics.loadImage (cinematX.IMGNAME_BOSSHP_LEFT)
		cinematX.IMGREF_BOSSHP_EMPTY 		= 	Graphics.loadImage (cinematX.IMGNAME_BOSSHP_EMPTY)
		cinematX.IMGREF_BOSSHP_FULL 		=	Graphics.loadImage (cinematX.IMGNAME_BOSSHP_FULL)
		cinematX.IMGREF_BOSSHP_BG 			=	Graphics.loadImage (cinematX.IMGNAME_BOSSHP_BG)
		
		cinematX.IMGREF_RACEBG 				=	Graphics.loadImage (cinematX.IMGNAME_RACEBG)
		cinematX.IMGREF_RACEFLAGSTART		=	Graphics.loadImage (cinematX.IMGNAME_RACEFLAGSTART)
		cinematX.IMGREF_RACEFLAGEND			=	Graphics.loadImage (cinematX.IMGNAME_RACEFLAGEND)
		cinematX.IMGREF_RACEPLAYER			=	Graphics.loadImage (cinematX.IMGNAME_RACEPLAYER)
		cinematX.IMGREF_RACEOPPONENT		=	Graphics.loadImage (cinematX.IMGNAME_RACEOPPONENT)
		
		cinematX.IMGREF_HUDBOX				=	Graphics.loadImage (cinematX.IMGNAME_HUDBOX)
		cinematX.IMGREF_NPCICON_T_O			=	Graphics.loadImage (cinematX.IMGNAME_NPCICON_TALK_O)	
		cinematX.IMGREF_NPCICON_T_N			=	Graphics.loadImage (cinematX.IMGNAME_NPCICON_TALK_N)	
		cinematX.IMGREF_NPCICON_Q_O			=	Graphics.loadImage (cinematX.IMGNAME_NPCICON_QUEST_O)
		cinematX.IMGREF_NPCICON_Q_N			=	Graphics.loadImage (cinematX.IMGNAME_NPCICON_QUEST_N)	
		cinematX.IMGREF_NPCICON_I_O			=	Graphics.loadImage (cinematX.IMGNAME_NPCICON_INSPECT_O)
		cinematX.IMGREF_NPCICON_I_N			=	Graphics.loadImage (cinematX.IMGNAME_NPCICON_INSPECT_N)	
		cinematX.IMGREF_NPCICON_PRESSUP		=	Graphics.loadImage (cinematX.IMGNAME_NPCICON_PRESSUP)

		
		-- Stores the filename of the image loaded into IMGSLOT_HUD
		cinematX.currentHudOverlay = ""
	   
		cinematX.currentImageRef_hud            =       cinematX.IMGREF_BLANK
		cinematX.currentImageRef_screen         =       cinematX.IMGREF_BLANK
	   
		cinematX.refreshHUDOverlay ()
	end
   
   
   
	function cinematX.initActors ()
		--cinematX.playerDummyActor =
	   
		--[[
				Player control mode: How to handle the player during cutscenes
						_PLAY           = Player is active and visible, dummy actor is invisible and snapped to the
														center of the screen
						_SCENE          = Player and dummy actor swap positions and visibility; dummy actor serves
														as more flexibly-animated player, can change player position to pan camera
		--]]
		cinematX.PLAYERMODE_PLAY = 0
		cinematX.PLAYERMODE_SCENE = 1
	   
		cinematX.playerControlMode = cinematX.PLAYERMODE_PLAY
	end
   
   
	function cinematX.initQuestSystem ()
		--cinematX.defineQuest ("test", "Test Quest", "Test the quest the quest the test system")
		cinematX.questData = Data (Data.DATA_WORLD, "cinematX", true)
	end
   

	cinematX.debugLogTable = {}
	cinematX.debugCurrentLine = 00
				   
	function cinematX.initDebug ()
		cinematX.showConsole = false
	   
		cinematX.toConsoleLog ("Console test")
	end
end
 
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            CINEMATX UPDATE FUNCTIONS                                                             *
--                                                                                                  *
--***************************************************************************************************
 
do

	function cinematX.update ()

		-- Call level init
		if  (cinematX.initCalledYet == false)  then
			cinematX.initLevel ()
		end

		-- Keep track of how long the player holds the jump button
		--if (cinematX.playerHoldingJump == true) then
		--      cinematX.playerActor.jumpStrength = cinematX.playerActor.jumpStrength + 1
		--end

		cinematX.updateMidpointCheck ()
		cinematX.updateTiming ()
		cinematX.updateTextblox ()
		cinematX.updateActors ()
		cinematX.updateNPCMessages ()
		cinematX.updateDialog ()
		cinematX.updateRace ()
		cinematX.updateUI ()
		cinematX.updateCheats ()
		--cinematX.updateInput ()
	   
	   
		-- Call delayed init (level)
		if      cinematX.delayedInitCalledFromUpdate == false  then
			cinematX.delayedInitLevel ()
			cinematX.delayedInitCalledFromUpdate = true
		end

		-- Call delayed init (section)
		if  cinematX.delayedInitSectionNum ~= player.section  then
	   
			cinematX.delayedInitSection ()
			cinematX.delayedInitSectionNum = player.section
		end
	end

	function cinematX.updateMidpointCheck ()       
		local midpoint = findnpcs(192, -1) [0]
	   
		if midpoint == nil then
			return
		end
	   
		if (midpoint:mem (0x44, FIELD_WORD) ~= 0)  or  (midpoint:mem(0x122, FIELD_WORD) ~= 0)   then
			cinematX.midpointReached = true
			cinematX.toConsoleLog ("MIDPOINT")
		end
	end
   
   
	function cinematX.updateTiming ()
		local lastFrameTime = cinematX.currentFrameTime
		cinematX.currentFrameTime = os.clock ()
		cinematX.deltaTime = cinematX.currentFrameTime - lastFrameTime
		--cinematX.wakeUpWaitingThreads (cinematX.deltaTime)  
	end

   
	function cinematX.updateTextblox ()
		-- Trigger finish signals
		for  k,v in pairs (textblox.textBlockRegister)  do  
			if  v.deleteMe == true  then
				cinematX.signal ("blockClose_"..v.index)
			end
		   
			if  v.finished == true  then
				cinematX.signal ("blockFinish_"..v.index)
			end
		end            
	end
   
   
	function cinematX.updateCamera ()

		-- Camera
		--cinematX.cameraFocusX = cinematX.cameraFocusX + cinematX.cameraXSpeed
		--cinematX.cameraFocusY = cinematX.cameraFocusY + cinematX.cameraYSpeed        
	   
		if (cinematX.cameraControlOn == true) then
			--player.x = cinematX.cameraFocusX
			--player.y = cinematX.cameraFocusY
			--player.speedX = 0
			--player.speedY = 0
			--player:mem (0x112, FIELD_WORD, 500)
		end
	   
		--mem (cinematX.cameraXAddress, FIELD_DWORD, cinematX.cameraOffsetX)
		--mem (cinematX.cameraYAddress, FIELD_DWORD, cinematX.cameraOffsetY)
	end

   
	-- Process a cinematX tag from a valid NPC string
	function cinematX.parseTagFromNPCMessage (msgStr, tagName)
		local pTagStart = nil
		local pTagEnd = nil
		pTagStart, pTagEnd = string.find (msgStr, tagName.."=[%w_ ]+[,}]")
	   
		if  (pTagStart == nil  or  pTagEnd == nil)  then
				return nil
		end
	   
		pTagStart = pTagStart + string.len (tagName) + 1
		pTagEnd = pTagEnd - 1

		local pTagStr = string.sub (msgStr, pTagStart, pTagEnd)
	   
		return pTagStr
	end
   
   
	-- Swap this for the location to store and read the NPC unique ID. 0x08 appears unused, but this can be changed to any unused word.
	cinematX.ID_MEM =  0x76
	cinematX.ID_MEM_FIELD =  FIELD_WORD
   
	function cinematX.indexActors (onlyIndexNew)
		-- If configured not to generate actors, abort this function
		if  (cinematX.shouldGenerateActors == false)  then
			return
		end

		-- Loop through every NPC, create an indexed actor instance for each one and store the messages & other info
		--local i = 0

		for k,v in pairs (npcs()) do

			local uid = v:mem (cinematX.ID_MEM, cinematX.ID_MEM_FIELD);
			local isDying = false
			if  (v:mem (0x122, FIELD_WORD)  >  0)  then
				isDying = true
			end
		   
		   
			--Assign a new unique ID to the NPC (this applies to all NPCs, not just CinematX enabled ones.
			if (uid == 0  and  isDying == false)  then
				cinematX.npcCount = cinematX.npcCount + 1;
				uid = cinematX.npcCount;
				v:mem (cinematX.ID_MEM, FIELD_WORD, uid);
			   
			elseif  isDying == true  then
				--windowDebug("Killed: "..v.msg.str);
			end
		   
		   
			--Have we already defined this actor? If so, then we update the SMBX reference accordingly.
			if (cinematX.indexedActors[uid] ~= nil) then
				cinematX.indexedActors[uid].smbxObjRef = v;
				cinematX.indexedActors[uid].uid = uid;
				cinematX.indexedActors[uid].isDirty = true
				   
		   
			--Otherwise, create a new actor, if necessary.
			else

				--Validity check message string to ensure we don't follow null pointers.
				local msgStr = nil
				if(v:mem (0x4C, FIELD_DWORD) > 0) then
					msgStr = v.msg.str
				end

				if  (msgStr ~= nil  and   msgStr ~= "") then

					if (v:mem(0x122, FIELD_WORD) ~= 0)   then
						cinematX.toConsoleLog ("STILLBORN ACTOR")
					end

				   
					-- Run qualifier function if it exists
					local shouldBeActor = true
				   
					if  (cinematX.actorCriteria ~= nil)  then
						shouldBeActor = cinematX.actorCriteria (v)
					end
				   
					if  (shouldBeActor == true)  then
			   
						-- Create the actor and add it to the table
						local thisActor = Actor.create (v, "NPC")
						thisActor.uid = uid
						thisActor.messageNew = true  
						thisActor.messagePointer = v:mem (0x4C, FIELD_DWORD)
						cinematX.indexedActors[uid] = thisActor
				   
				   
						-- Get the message string
						thisActor.messageString = msgStr      
				   
				   
						-- Parse the message string                                            
			   
						-- Get the substring between the first and last characters
						local checkStringA = string.sub  (msgStr, 2, string.len(msgStr)-1)
						-- Get JUST the first and last characters
						local checkStringB = string.gsub (msgStr, checkStringA, "")

						-- If this is false, not a valid cinematX message
						local shouldClearMessage = false
					   
						if     (string.find (checkStringA, "[{}]") == nil
										and  checkStringB == "{}")  then

							shouldClearMessage = true
									 
							-- Parse tags
							local parsedKey       = cinematX.parseTagFromNPCMessage (msgStr, "key")
							local parsedName      = cinematX.parseTagFromNPCMessage (msgStr, "name")
							local parsedTalkType  = cinematX.parseTagFromNPCMessage (msgStr, "verb")
							local parsedPriority  = cinematX.parseTagFromNPCMessage (msgStr, "priority")
							local parsedAltSub    = cinematX.parseTagFromNPCMessage (msgStr, "sub")
							local parsedIcon      = cinematX.parseTagFromNPCMessage (msgStr, "icon")
							local parsedScene     = cinematX.parseTagFromNPCMessage (msgStr, "scene")
							local parsedRoutine   = cinematX.parseTagFromNPCMessage (msgStr, "routine")
							 
							 
							-- Store key for use in getNPCFromKey() if parsed
							if (parsedKey ~= nil) then
								cinematX.npcMessageKeyIndexes[parsedKey] = uid
								--windowDebug ("key = "..parsedKey..", "..tostring(cinematX.npcMessageKeyIndexes[parsedKey])..", "..tostring(cinematX.npcMessageKeyIndexes["calleoca"]))
							end
					 
							-- Store name if parsed
							if (parsedName == nil) then
								parsedName = ""
							end
							thisActor.nameString = parsedName
					 
							-- Store alt sub if parsed
							--if (parsedAltSub == nil) then
							--      parsedAltSub = nil
							--end
							thisActor.altSubString = parsedAltSub
					 
							-- Store talk type string if parsed
							if (parsedTalkType == nil) then
								parsedTalkType = "talk"
							end
							thisActor.talkTypeString = parsedTalkType

							-- Store icon if parsed
							thisActor.wordBubbleIcon = tonumber (parsedIcon)

							-- Store scene
							if (parsedScene == "nil") then
								parsedScene = nil
							end
							thisActor.sceneString = parsedScene
							--windowDebug (thisActor.sceneString)

							-- Store routine
							if (parsedRoutine == "nil") then
								parsedRoutine = nil
							end
							thisActor.routineString = parsedRoutine

							-- Store whether the actor is interactive
							if  (parsedRoutine ~= nil   or   parsedScene ~= nil)  then
								thisActor.isInteractive = true
							end
						end
				   
				   
				   -- If set to override the SMBX message system, clear the NPC's message after storing it
						if   (cinematX.overrideNPCMessages == true  and  shouldClearMessage == true)   then
								local message = msgStr
								v.msg:clear()
								cinematX.indexedActors[uid] = thisActor
						end
					   
						-- Increment the actor count
						cinematX.actorCount = cinematX.actorCount + 1;
						--i = i + 1;
					end                                    
				end
			end
		end
		   
		   
		-- Check dirty
		for k,v in pairs (cinematX.indexedActors) do
			if  (v.isDirty == true)  then
				cinematX.indexedActors[k].isDirty = false
				--windowDebug ("Actor cleaned")
			else
				cinematX.toConsoleLog ("Actor destroyed: "..(v.name)..", "..(v.npcid))
				cinematX.indexedActors[k].smbxObjRef = nil
				cinematX.indexedActors[k] = nil
			end
		end
	end
   
   
	function cinematX.updateActors ()
	   
		-- If no actors are generated, skip the update
		if (cinematX.shouldGenerateActors == false) then
			return
		end
	   
	   
		-- Index new actors
		cinematX.indexActors (true)
	   
	   
		-- Loop through every actor and call their update methods
		cinematX.playerActor:update ()
	   
		for k,v in pairs (cinematX.indexedActors) do
			if  (v ~= nil)  then
				if (v.smbxObjRef == nil) then
					windowDebug ("ERROR: NPC DESTROYED")
					cinematX.toConsoleLog ("ERROR: NPC DESTROYED")
					v = nil
				else
					v:update ()
				end
			end
		end
	   
	   
		-- Hide the player
		cinematX.playerActor.isHidden = cinematX.playerHidden          
	end

   
	function cinematX.updateNPCMessages ()
		cinematX.currentMessageActor = nil
			   
		if   (cinematX.overrideNPCMessages == true   and   cinematX.currentSceneState == cinematX.SCENESTATE_PLAY)   then

			cinematX.refreshHUDOverlay ()

			--cinematX.dialogOn = false
			cinematX.subtitleBox = false
		   
			for k,v in pairs (cinematX.indexedActors) do
				--if cinematX.playerActor ~= nil then
				--      windowDebug ("SHOULD BE NO PROBLEM")
				--end
			   
			   
				if  (v ~= nil)  then
					if  (v.smbxObjRef ~= nil)  then
						if  (v:distanceActor (cinematX.playerActor) < 800   and  
							(v.isInteractive == true  or  v.altSubString ~= nil))                          then
						   
							-- Check interaction type and whether the player has already spoken to the NPC
							local tempIconType = 0
							local tempIconNew = 0
							local tempIcon = cinematX.IMGREF_NPCICON_T_N
						   
							if  (v.wordBubbleIcon ~= nil)   then
								tempIconType = 10*v.wordBubbleIcon
							end

							if  v.messageIsNew == false  then
								tempIconNew = 1
							end                                    
						   
						   
							-- Determine the icon type based on the above
							local tempAdd = tempIconType + tempIconNew
						   
							if      (tempAdd == 00)  then  tempIcon = cinematX.IMGREF_NPCICON_T_N
							elseif  (tempAdd == 01)  then  tempIcon = cinematX.IMGREF_NPCICON_T_O
							elseif  (tempAdd == 10)  then  tempIcon = cinematX.IMGREF_NPCICON_Q_N
							elseif  (tempAdd == 11)  then  tempIcon = cinematX.IMGREF_NPCICON_Q_O
							elseif  (tempAdd == 20)  then  tempIcon = cinematX.IMGREF_NPCICON_I_N
							elseif  (tempAdd == 21)  then  tempIcon = cinematX.IMGREF_NPCICON_I_O
							end
								   
						   
							-- NPC Interaction indicators
							if      (cinematX.showConsole == false)  then                                  
					   
								-- If the player is close enough, store the NPC's index in      currentMessageNPCIndex
								if  v:distanceActor (cinematX.playerActor) < 48  then
									   
									if  v.isInteractive  then
										cinematX.currentMessageNPCObj = v.smbxObjRef
										cinematX.currentMessageNPCIndex = k
										cinematX.currentMessageActor = v
									end
								   
									--tempIcon = cinematX.IMGSLOT_NPCICON_PRESSUP

									if  cinematX.dialogOn == false  then
										cinematX.subtitleBox = true                                                            
										local subStr = v.altSubString
									   
										if  subStr == nil  then
											subStr = "[UP] to "..v.talkTypeString.."."
										end
							   
										cinematX.displayNPCSubtitle (v.nameString, subStr)
									end
								end
									   
							   
								-- Display the icon above the NPC
								if  (v.wordBubbleIcon ~= nil)  then
									local playerDistanceAlpha  =  math.max(1 - (v:distanceActor (cinematX.playerActor))/256,  0)
									Graphics.drawImageToScene (tempIcon, v:getX()-8, v:getY()-64, 0.3 + 0.7*playerDistanceAlpha)--math.sin(os.clock()))
								end
							end
						end
					end
					--[[
					if  (Actor_distanceActor (player, v) < 64   and   cinematX.npcMessageStrings[k] ~= "")  then
							--cinematX.dialogOn = true
							cinematX.displayNPCSubtitle ("Name", cinematX.npcMessageStrings[k])
					end
					--]]
				end
			end
		end
	end
   
   
   
	function cinematX.updateRace ()
		if  (cinematX.raceEnemyActor ~= nil
		and  cinematX.raceActive == true)
		then
   
			-- Calculate relative position of player and opponent
			cinematX.racePlayerPos = invLerp (cinematX.raceStartX, cinematX.raceEndX, cinematX.playerActor:getX ())
			cinematX.raceEnemyPos = invLerp (cinematX.raceStartX, cinematX.raceEndX, cinematX.raceEnemyActor:getX ())              
		   
			--[[
			printText (tostring(cinematX.racePlayerPos), 4, 5, 300)
			printText (tostring(cinematX.raceEnemyPos), 4, 5, 320)
		   
			printText (tostring(cinematX.raceStartX), 4, 5, 340)
			printText (tostring(cinematX.raceEndX), 4, 5, 360)
			printText (tostring(cinematX.playerActor:getX ()), 4, 5, 380)
			printText (tostring(cinematX.raceEnemyActor:getX ()), 4, 5, 400)
			--]]
		   
			-- Call win/lose coroutines
			if (cinematX.racePlayerPos >= 1) then
				cinematX.raceActive = false
				cinematX.runCoroutine (cinematX.raceWinRoutine)
			end
		   
			if (cinematX.raceEnemyPos >= 1) then
				cinematX.raceActive = false
				cinematX.runCoroutine (cinematX.raceLoseRoutine)
			end
		end
	end

   
   
   
	cinematX.memMonitorAddress = 0x00B25068
	cinematX.memMonitorField = 1
	cinematX.memMonitorScroll = 32
   
	cinematX.playerWarping = false
	cinematX.playerWarpingPrev = false
   
	function cinematX.updateUI ()
		   
		--testThisThing ()
	   
		-- MAIN HUD OVERLAY IS CHANGED WHEN cinematX.refreshHUDOverlay () IS CALLED
		-- BELOW ARE ADDITIONAL UI ELEMENTS BASED ON THE SCENE STATE
	   
	   
		-- TRANSITION OUT OF SECTIONS          
		local playerForcedAnimState = player:mem (0x122, FIELD_WORD)
		local playerWarpTimer = player:mem (0x15C, FIELD_WORD)
		local playerWarpType = player:mem (0x5A, FIELD_WORD)
	   
		cinematX.playerWarpingPrev = cinematX.playerWarping
		cinematX.playerWarping = false
	   
		if  (playerForcedAnimState == 3  or playerForcedAnimState == 7)  then
			cinematX.playerWarping = true
		end
	   
		if  (cinematX.playerWarping == true)  then
			if  (cinematX.playerWarpingPrev == false)  then
				if  cinematX.transitionBetweenSections == true then
				   
					-- Pipe
					if  playerForcedAnimState == 3  then
						cinematX.warpFade (0.8)
				   
					-- Door
					else
						cinematX.warpFade (0.25)
					end
				end
					   
			elseif   cinematX.screenTransitionAmt < 1  then
				--player:mem (0x122, FIELD_WORD, 3)
			end
		end
	   
	   
		-- SCREEN TINT
		graphX.boxScreen (0,0, 800,600,  cinematX.screenTintColor)
	   
		-- SCREEN FADE
		local screenFadeCol = 0x00000000 + math.floor(lerp(0, 255, cinematX.screenTransitionAmt))
		if  (cinematX.canUseNewUI == true)  then
			graphX.boxScreen (0,0, 800,600,  screenFadeCol)
		else
			Graphics.drawImage (cinematX.IMGREF_NOGLFADE, 0,0, cinematX.screenTransitionAmt)
		end
	   
	   
	   
		-- Fade letterboxing
		if      (cinematX.currentSceneState  ==  cinematX.SCENESTATE_CUTSCENE)  then
			cinematX.letterboxAlphaMult = math.min(1, cinematX.letterboxAlphaMult + cinematX.letterboxAlphaRate)
		else
			cinematX.letterboxAlphaMult = math.max(0, cinematX.letterboxAlphaMult - cinematX.letterboxAlphaRate)
		end
		cinematX.letterboxAlphaHex =    lerp(0x00000000, 0x000000FF, cinematX.letterboxAlphaMax * cinematX.letterboxAlphaMult)
	   
	   
			   
	   
		-- MENU BOXES
		if (cinematX.useNewUI == true  and   cinematX.canUseNewUI == true)  then
	   
			-- Enable the hud
			hud (true)

		   
			-- DEBUG CONSOLE
			if      (cinematX.showConsole == true)                                                                  then
				hud (false)
				graphX.boxScreen (0,0, 800,600,  0x00000099)
		   
			-- Race mode
			elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_RACE)      then
				cinematX.drawMenuBox (30,7, 740,72,  0x00000099)
				cinematX.drawMenuBox (30,494, 740,82,  0x00000099)     
			   
				graphX.boxScreen (60,529, 680,14,  0x000000FF)

		   
			-- Boss battle mode
			elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_BATTLE)    then
				cinematX.drawMenuBox (30,7, 740,72,  0x00000099)
				cinematX.drawMenuBox (30,494, 740,82,  0x00000099)     
		   
		   
			-- Cutscene mode
			elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_CUTSCENE)  then           
				   
				-- Disable the hud
				hud (false)

		   
			-- Play mode
			elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_PLAY)              then
				if  cinematX.useHUDBox == true  then
					cinematX.drawMenuBox (30,7, 740,72,  0x00000099)
				end
			   
				if      (cinematX.dialogOn == true)       then
					cinematX.drawMenuBox (2,468, 796,600-470,  0x00000099)
				elseif  (cinematX.subtitleBox == true)    then
					cinematX.drawMenuBox (30,500, 740,70,  0x00000099)
				end
			end
		   
			   
			-- Letterboxing is faded in and out now
			graphX.boxScreen (0,0, 800,100,  cinematX.letterboxAlphaHex)
			graphX.boxScreen (0,468, 800,600-468,  cinematX.letterboxAlphaHex)
		else

		   
			if  cinematX.IMGREF_LETTERBOX ~= nil  then
				Graphics.drawImageWP (cinematX.IMGREF_LETTERBOX, 0, 0, cinematX.letterboxAlphaMult*cinematX.letterboxAlphaMax, 3.494)
			end            
   
			if  cinematX.currentImageRef_hud  ~=  nil       then
				Graphics.drawImageWP (cinematX.currentImageRef_hud, 0, 0, 3.494)
			end
			if  cinematX.currentImageRef_screen  ~=  nil    then
				Graphics.drawImageWP (cinematX.currentImageRef_screen, 0, 0, 3.494)
			end
		end
	   
	   
	   
		-- RACE PROGRESS
		if   cinematX.currentSceneState == cinematX.SCENESTATE_RACE   then
			local raceMeterLeft = 48
			local raceMeterRight = 800-80
			local racePlayerIconX = lerp (raceMeterLeft, raceMeterRight, cinematX.racePlayerPos)
			local raceEnemyIconX = lerp (raceMeterLeft, raceMeterRight, cinematX.raceEnemyPos)
			local barY = 520

			Graphics.drawImageWP (cinematX.IMGREF_RACEFLAGSTART,    raceMeterLeft,          barY,  3.494)
			Graphics.drawImageWP (cinematX.IMGREF_RACEFLAGEND,              raceMeterRight,         barY,  3.494)

		   
			if (racePlayerIconX > raceEnemyIconX)  then
				Graphics.drawImageWP (cinematX.IMGREF_RACEOPPONENT,     raceEnemyIconX,         barY,  3.494)
				Graphics.drawImageWP (cinematX.IMGREF_RACEPLAYER,       racePlayerIconX,        barY,  3.494)
			else
				Graphics.drawImageWP (cinematX.IMGREF_RACEPLAYER,       racePlayerIconX,        barY,  3.494)
				Graphics.drawImageWP (cinematX.IMGREF_RACEOPPONENT,     raceEnemyIconX,         barY,  3.494)                  
			end
		end
			   
			   
		-- BOSS HP BAR
		if  cinematX.bossHPEase > cinematX.bossHP  then
			cinematX.bossHPEase = cinematX.bossHPEase - (cinematX.bossHPMax*0.0025)
		end
		
		if  cinematX.currentSceneState == cinematX.SCENESTATE_BATTLE   then

			-- Boss Name
			cinematX.printCenteredText (cinematX.bossName, 4, 400, 510)
			
			
			-- Different HP bar types
			local barBranch = cinematX.bossHPDisplayType
			local oglBarBranch = true
			
			if 	cinematX.useNewUI == false  or  cinematX.canUseNewUI == false  then
				oglBarBranch = false
			end
			
			
			-- BAR1 -- horizontal, unit-based, center-aligned (broken)
			if		(barBranch == cinematX.BOSSHPDISPLAY_BAR1)		then
			
				-- Bar sides
				local barLeft = player.screen.left + 400 - (cinematX.bossHPMax * 16)
				local barRight = barLeft + (cinematX.bossHPMax * 32)
				local barY = 520

				--placeSprite (1, IMG_BOSSHP_LEFT, barLeft, barY, "", 1)
				--placeSprite (1, IMG_BOSSHP_RIGHT, barRight, barY, "", 1)

				-- Bar units
				for i = 0, cinematX.bossHPMax-1 do
					local sprX = barLeft + (i+1)*32
					local sprImg = IMG_BOSSHP_EMPTY

					if (i <= cinematX.bossHP-1) then
						sprImg = IMG_BOSSHP_FULL
					end

					--placeSprite (1, sprImg, sprX, barY, "", 1)
				end

			
			-- BAR 2 -- horizontal, bar-based, center-aligned
			elseif	(barBranch == cinematX.BOSSHPDISPLAY_BAR2)		then
				
				cinematX.drawProgressBarLeft (50,540, 700,16,  0x00000099,  1)
				cinematX.drawProgressBarLeft (50,540, 700,16,  0xBB0000FF,  cinematX.bossHPEase/cinematX.bossHPMax)
				cinematX.drawProgressBarLeft (50,540, 700,16,  0x009900FF,  cinematX.bossHP/cinematX.bossHPMax)
			
				cinematX.bossHP = math.min (math.max (cinematX.bossHP, 0), cinematX.bossHPMax)
				
			
			
			-- HITS -- Just display the current and max hits
			elseif	(barBranch == cinematX.BOSSHPDISPLAY_HITS)		then
				cinematX.printCenteredText (cinematX.bossHP.."/"..cinematX.bossHPMax, 4, 400, 550)
			end
		end


		-- DISPLAY DIALOGUE/SUBTITLES
		if   cinematX.dialogOn == true  and  (cinematX.currentSceneState == cinematX.SCENESTATE_PLAY  or  cinematX.currentSceneState == cinematX.SCENESTATE_CUTSCENE)  then

			if  cinematX.textbloxSubtitle == true  then
				cinematX.subtitleBoxBlock.visible = true
			   
				if(cinematX.dialogName ~= "") then
					textblox.print (cinematX.dialogName..":", 5, 475, cinematX.subtitleFont, textblox.HALIGN_LEFT, textblox.HALIGN_TOP, 999, 1)
				end
			   
				if (cinematX.dialogIsQuestion == true) then
					local   tempBottomLine = "      YES                       NO          "
				   
					if cinematX.getResponse() == true then
									tempBottomLine = "    - YES -                     NO          "
					end
				   
					if cinematX.getResponse() == false then
									tempBottomLine = "      YES                     - NO -        "
					end
				   
					textblox.print (tempBottomLine, 400, 555, cinematX.subtitleFont, textblox.HALIGN_MID, textblox.HALIGN_TOP, 999, 1)

				elseif   (cinematX.thisDialogAutoEnd == false  and  cinematX.dialogTextTime <= 0  and  cinematX.subtitleBoxBlock:getFinished() == true  and  cinematX.dialogSetting_showThisPrompt == true)   then
					textblox.print ("(PRESS X TO CONTINUE)", 800-8, 580, cinematX.subtitleFont, textblox.HALIGN_RIGHT, textblox.HALIGN_TOP, 999, 1)
				end
			   
			else
				if(cinematX.dialogName ~= "") then
						Text.printWP (cinematX.dialogName..":", 4, 5, 475, 3.495)
				end
				Text.printWP (string.sub (cinematX.dialogText, 1, 42), 4, 15, 495, 3.495)
				Text.printWP (string.sub (cinematX.dialogText, 43, 85), 4, 15, 515, 3.495)
			   
				if (cinematX.dialogIsQuestion == true) then
					local   tempBottomLine = "      YES                       NO          "
				   
					if cinematX.getResponse() == true then
							tempBottomLine = "    > YES <                     NO          "
					end
				   
					if cinematX.getResponse() == false then
							tempBottomLine = "      YES                     > NO <        "
					end
				   
					Text.printWP (tempBottomLine, 4, 15, 555, 3.495)
			   
				else
					Text.printWP (string.sub (cinematX.dialogText, 86, 128), 4, 15, 535, 3.495)
					Text.printWP (string.sub (cinematX.dialogText, 129, 171), 4, 15, 555, 3.495)
				   
					if   (cinematX.thisDialogAutoEnd == false  and  cinematX.dialogTextTime <= 0  and  cinematX.dialogSetting_showThisPrompt)   then
						Text.printWP ("(PRESS X TO CONTINUE)", 4, 400, 580, 3.495)
					end

				end                    
			end
		end

	   
		-- QUEST STUFF
		if   cinematX.displayQuestInfo == true   then
			cinematX.displayQuestState (cinematX.currentQuestKey)
		end
	   
		-- DEBUG STUFF
		if   (cinematX.showDebugInfo == true)   then
   
			-- Display console
			if  (cinematX.showConsole == true)  then       
				local i = 0
				for k,v in pairs (cinematX.debugLogTable) do
					--if (cinematX.debugCurrentLine > 15)
				   
					printText (cinematX.debugLogTable[i], 4, 20, (550 - 20*cinematX.debugCurrentLine)+20*i)  
					i = i + 1
				end

				printText ("ACTORS: "..cinematX.actorCount, 4, 550, 100)  

			   
				-- Display cheat input string
				local cheatStr = Misc.cheatBuffer ()
				if  (cheatStr ~= nil)  then
					printText ("INPUT: " .. getInput().str, 4, 20, 580)
				end
				   
			else
				-- Disable cheating when the console is not open
				Misc.cheatBuffer ("")
			end
			--]]
		   
			--[[
			printText ("Delta Time: "..string.format("%.3f", cinematX.deltaTime), 4, 20, 100)  
			printText ("Current Time: "..string.format("%.3f", cinematX.CURRENT_TIME), 4, 20, 120)  
			printText ("Cutscene mode: "..tostring(cinematX.currentSceneState), 4, 20, 140)  
			printText ("Coroutine: "..tostring(cinematX.currentCoroutine), 4, 20, 160)  
			printText ("Hud img path: "..cinematX.currentHudOverlay, 4, 20, 180)
			--]]
		   
			-- NPC animation frames
		   
			--[[
			local i = 0
			for k,v in pairs (cinematX.indexedActors) do
			   
				printText (""..tostring(k).." animFrame "..tostring(v.animFrame).." animState "..tostring(v.animState), 4, 20, 100+20*i)

				i = i+1
			end
			--]]
		   
			--printText ("delayedInit calls: "..tostring(cinematX.delayedInitCounter), 4, 20, 100)
				   

			--cinematX.displayDebug_indexedKeys ()
		   
		   
		   
			-- Display memory values - GLOBAL
			--[[
			local myX = 300
			local myY = 300
		   
			local tempMemAdr = 0x00
			local tempMemType = FIELD_WORD
			local tempMemVal = mem(tempMemAdr, tempMemType)
		   
			local hexStr = string.format("%X", tempMemAdr)
			local valueStr = mem (tempMemAdr, tempMemType) --string.format("%X", v:mem(memAdrIterated, memField))
		   
			printText (hexStr.."="..valueStr, 4, myX-64, myY-96)
			--]]
		   
			--[[
			local memScroll = cinematX.memMonitorScroll
			local memAdr = cinematX.memMonitorAddress
			local memFieldTypes = {FIELD_BYTE,FIELD_WORD,FIELD_DWORD,FIELD_FLOAT,FIELD_DFLOAT,FIELD_STRING}
			local memFieldNames = {"BYTE","WORD","DWORD","FLOAT","DFLOAT","STRING"}
			local memField = memFieldTypes [cinematX.memMonitorField] --DWORD
			local memSize = 2--1
		   
			local myX = 300
			local myY = 500                
				   
			printText (memFieldNames [cinematX.memMonitorField], 4, myX-192, myY-96)
				   
			for i=0,16,1 do
				local memAdrIterated = memAdr+memSize*i
				local hexStr = string.format("%X", memAdrIterated)
				local valueStr = mem (memAdrIterated, memField)
			   
				if memField == FIELD_STRING then
					if valueStr ~= nil then
						valueStr = valueStr.str
					else
						valueStr = ""
					end
				end
			   
				--string.format("%X", v:mem(memAdrIterated, memField))
				printText (hexStr.."="..valueStr, 4, myX-64, myY-96-(16*i))
			end    
		   
				   
			for i=0,16,1 do
				local memAdrIterated = memScroll+memAdr+memSize*i
				local hexStr = string.format("%X", memAdrIterated)
				local valueStr = mem (memAdrIterated, memField)
			   
				if memField == FIELD_STRING then
					if valueStr ~= nil then
						valueStr = valueStr.str
					else
						valueStr = ""
					end
				end
			   
				--string.format("%X", v:mem(memAdrIterated, memField))
				printText (hexStr.."="..valueStr, 4, myX+256, myY-96-(16*i))
			end    
			--]]
		   
		   
			-- Display memory values - NPCs
		   
			--[[
			for k,v in pairs (npcs()) do
				--local myX = v.x - (player.x - player.screen.left)
				--local myY = v.y - (player.y - player.screen.top)
	   
				local spawnX = v:mem (0xAC, FIELD_WORD)
				local spawnY = v:mem (0xB4, FIELD_WORD)
				local currentX = v:mem (0x78, FIELD_DFLOAT)
				local currentY = v:mem (0x80, FIELD_DFLOAT)
			--]]
		   
				--[[
				printText ("Y pos    "..tostring(currentY), 4, myX-160, myY-16*10)
				printText ("CY to SY "..tostring(currentY*-(8) - 1572864.08), 4, myX-160, myY-16* 9)
				--printText ("Y pos    "..tostring(currentY), 4, myX-160, myY-16* 9)
			   
				printText ("Spawn Y  "..tostring(spawnY),   4, myX-160, myY-16* 7)
				--printText ("Spawn Y  "..tostring(spawnY),   4, myX-160, myY-16* )
											   
				--]]
				--printText ("_"..v.msg.str.."_", 4, myX, myY-96)
			   

				--if (v:mem (0x64, FIELD_WORD) == -1) then
					--v:mem(0x6A, FIELD_WORD, v:mem(0x6A, FIELD_WORD)-1)
				--end
			   
			   

				-- 1572863.88
				-- 1572863.98
				-- 1572864.08
	   
				--[[
				printText ("X            = "..tostring(v.x),                                                    4, myX-160, myY-16* 10)  
				printText ("X (mem)      = "..tostring(currentX),                                               4, myX-160, myY-16* 9)
				printText ("SpawnX       = "..tostring(spawnX),                                                 4, myX-160, myY-16* 8)  
				printText ("X To Spawn   = "..tostring(cinematX.coordToSpawnX (v.x)),           4, myX-160, myY-16* 7)  
				printText ("Spawn To X   = "..tostring(cinematX.spawnToCoordX (spawnX)),        4, myX-160, myY-16* 6)  
				--]]
			   
			   
				--[[
				local memAdr = cinematX.memMonitorAddress
				local memFieldTypes = {FIELD_BYTE,FIELD_WORD,FIELD_DWORD,FIELD_FLOAT,FIELD_DFLOAT}
				local memFieldNames = {"BYTE","WORD","DWORD","FLOAT","DFLOAT"}
				local memField = memFieldTypes[cinematX.memMonitorField] --DWORD
				local memSize = 2--1
			   
			   
				printText (memFieldNames[cinematX.memMonitorField], 4, myX-160, myY-96)
			   
				for i=0,8,1 do
					local memAdrIterated = memAdr+memSize*i
					local hexStr = string.format("%X", memAdrIterated)
					local valueStr = v:mem(memAdrIterated, memField)--string.format("%X", v:mem(memAdrIterated, memField))
					printText (hexStr.."="..valueStr, 4, myX-64, myY-96-(16*i))
				end    
				--]]                           
			--end
		   
		   
		   
			-- Coroutine threads
			--[[
			i = 0                  
			for k,v in pairs (cinematX.WAITING_ON_TIME) do

				printText (tostring(k).." wait until "..string.format("%.3f", v), 4, 20, 200+20*i)  
				i = i+1
			end

			if  (i <= 0)  then
				printText ("No active coroutines", 4, 20, 180)  
			else
				printText ("Num coroutines = "..tostring(i), 4, 20, 180)  
			end
		   
		   
		   
			--]]
		   
			--[[                   
			-- NPC Messages
			if   (cinematX.overrideNPCMessages == true)   then     

				for k,v in pairs (cinematX.npcMessageStrings) do

					printText (tostring(k),                                                                 4,  20, 220 + 20*i)
					printText (tostring(cinematX.npcMessagePointers[i]),    4,  60, 220 + 20*i)
					printText (" -> "..v,                                                                   4, 240, 220 + 20*i)
					i = i + 1
				end
			end
			--]]
			--windowDebug ("UPDATE UI")
		end

	end
   
	function cinematX.displayDebug_indexedKeys ()
		local i = 0
		for k,v in pairs (cinematX.npcMessageKeyIndexes) do
			printText ("K: "..tostring(k)..", V: "..tostring(v), 4, 20, 120+20*i)
			i = i+1
		end
	   
		i = 0
		for k,v in pairs (cinematX.indexedActors) do
			printText ("NO KEY "..tostring(k)..", "..v.smbxObjRef.msg.str, 4, 400, 120+20*i)
			i = i+1
		end
	   
		printText ("NUM ACTORS: "..tostring(i)..", "..tostring(cinematX.actorCount), 4, 20, 100)
	   
		if i == 0 then
			printText ("ERROR: INDEXED KEYS NOT FOUND", 4, 20, 120+20*i)
		end
	end
   
   
	function cinematX.updateDialog ()
	   
		-- REMOVE THE TEXTBLOX SUBTITLE BLOCK
		if  cinematX.textbloxSubtitle == false  then
			cinematX.subtitleBoxBlock:closeSelf ()
		end
	   
		-- Display the text only revealed by the typewriter effect
		local currentCharNum = math.floor (cinematX.dialogNumCharsCurrent)

		cinematX.dialogText = string.sub (cinematX.dialogTextFull, 0, currentCharNum)
		local currentChar = string.sub (cinematX.dialogTextFull, currentCharNum-1, currentCharNum)

		-- Decrement the dialogue timer and increment the typewriter effect.
		if   (cinematX.dialogTextTime > 0)   then
			cinematX.dialogTextTime = cinematX.dialogTextTime - 1
		end

		if (cinematX.dialogNumCharsCurrent < string.len (cinematX.dialogTextFull)) then
			cinematX.dialogNumCharsCurrent = cinematX.dialogNumCharsCurrent + cinematX.dialogTextSpeed
			--if (currentChar ~= " "  and  dialogNumCharsCurrent % 2 == 0) then
					--playSFX (35) -- 10 = skid, 14 = coin, 23 = shckwup, 24 = boing, 26 = skittish ticking, 29 = menu option, 33 = whoosh, 35 = blip
			--end
		end

		
		-- Text end signal
		if  cinematX.getDialogFinished () == true  and  cinematX.dialogLineEnded == false  then
			cinematX.signal ("endDialogText")
			cinematX.dialogLineEnded = true
		end
		
		-- Auto-end subtitle
		if  cinematX.thisDialogAutoEnd == true  and  cinematX.getDialogFinished () == true  then
			cinematX.endDialogLine ()
		end
		

		-- When the speaker timer reaches zero, reset the speaker.
		cinematX.dialogSpeakerTime = cinematX.dialogSpeakerTime - 1

		if(cinematX.dialogSpeakerTime == 0) then
			cinematX.dialogSpeaker = nil
		end    


		-- DIALOG INPUT ------------------------------
		if (cinematX.dialogOn == true) then
		   
			-- Choose a response to a yes/no question
			if  (cinematX.dialogIsQuestion == true)  then
	   
				if (inputs.state["left"] == inputs.PRESS) then
					cinematX.questionPlayerResponse = true
					cinematX.playSFXSingle (3)
				end
	   
				if (inputs.state["right"] == inputs.PRESS) then
					cinematX.questionPlayerResponse = false
					cinematX.playSFXSingle (3)
				end
			end
		   
			-- Skip dialog if allowed                      
			if  (inputs.state["run"] == inputs.PRESS)  then
				if (cinematX.thisDialogSkippable == true  and  cinematX.getDialogFinished () == false)  then
					   
					if  cinematX.textbloxSubtitle == true  then
						cinematX.subtitleBoxBlock:finish ()
					end
				   
					cinematX.dialogNumCharsCurrent = string.len (cinematX.dialogTextFull)
					cinematX.dialogTextTime = 0
					cinematX.dialogSpeakerTime = 0
		   
				elseif  (cinematX.thisDialogAutoEnd == false)   then
					if  (cinematX.dialogIsQuestion == true  and  cinematX.questionPlayerResponse == nil)  then
						cinematX.playSFXSingle (10) -- 10 = skid, 14 = coin, 23 = shckwup
					else
						cinematX.playSFXSingle (26) -- 10 = skid, 14 = coin, 23 = shckwup
						cinematX.endDialogLine ()
					end
				end
			end
		end
	   
	end

	-- cinematX-specific cheats
	function cinematX.updateCheats ()
	   
		-- Check for non-despawned NPCs
		--if (cinematX.processCheat ("cinecheattest")) then
			--windowDebug ("CHEAT TEST")
		--end
	end
   
	function cinematX.processCheat (cheatString)
		local tempStr = getInput().str
		local isTrue = false
	   
		if  (string.find (tempStr, cheatString..""))  then
			cinematX.showConsole = false
			cinematX.playSFXSingle (0)
			isTrue = true
			getInput():clear ()
		end
	   
		return isTrue
	end
end
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            CINEMATX INPUT MANAGEMENT                                                             *
--                                                                                                  *
--***************************************************************************************************
 
do
	-- REGISTER JUMP FOR PLAYER ACTOR ---------------
   
	function cinematX.onJump ()            
		cinematX.playerHoldingJump = true
		cinematX.playerActor.jumpStrength = 17
		cinematX.playerActor.framesSinceJump = 0
	end
   
   

	-- OVERRIDE PLAYER MOVEMENT DURING CUTSCENES ---------------
	function cinematX.onInputUpdate ()
		   
		-- Disable extra players' inputs
		for  k,v in pairs(Player.get())  do
			if  v ~= player  then
				v.upKeyPressing = false
				v.downKeyPressing = false
				v.leftKeyPressing = false
				v.rightKeyPressing = false
				v.jumpKeyPressing = false
				v.altJumpKeyPressing = false
				v.runKeyPressing = false
				v.altRunKeyPressing = false
				v.dropItemKeyPressing = false
				v.pauseKeyPressing = false     

				--v:mem(0x62, FIELD_WORD, k)
			end
		   
			--Text.print ("0x62   "..tostring(v:mem(0x62, FIELD_WORD)), 8, 100+20*k)
		end


		-- Re-enable input
		for k,v in pairs(inputs.state) do
			inputs.locked[k] = false
		   
			if  v == inputs.PRESS  then  
				cinematX.signal ("keyPress"..k)
			end
			if  v == inputs.RELEASE  then  
				cinematX.signal ("keyRelease"..k)
			end
		end


	   
		-- Disable the player's inputs when in a cutscene
		if  (cinematX.currentSceneState == cinematX.SCENESTATE_CUTSCENE   and   cinematX.freezeDuringCutscenes == true)  or  (cinematX.freezePlayer == true)  then
			   
			for k,v in pairs(inputs.locked) do
				inputs.locked[k] = true
			end
		   
			--[[
			player.upKeyPressing = false
			player.downKeyPressing = false
		   
			-- Dialogue input workaround
			playerPressedLeft = false
			playerPressedRight = false
			playerPressedRun = false
			playerPressedJump = false

		   
			if  (player.leftKeyPressing == true)    then
				   
				if  (playerLeftKeyStop == false)                then
					playerPressedLeft = true
					playerLeftKeyStop = true
				end
			else
				playerLeftKeyStop = false                      
			end
		   
		   
			if  (player.rightKeyPressing == true)   then
				   
				if  (playerRightKeyStop == false)               then
					playerPressedRight = true
					playerRightKeyStop = true
				end
			else
				playerRightKeyStop = false                     
			end
		   
		   
			if  (player.runKeyPressing == true)             then
				   
				if  (playerRunKeyStop == false)         then
					playerPressedRun = true
					playerRunKeyStop = true
				end
			else
				playerRunKeyStop = false                       
			end            

		   
			if  (player.jumpKeyPressing == true)    then
			   
				if  (playerJumpKeyStop == false)                then
					playerPressedJump = true
					playerJumpKeyStop = true
				end
			else
				playerJumpKeyStop = false                      
			end
		   

			player.leftKeyPressing = false
			player.rightKeyPressing = false
		   
			player.jumpKeyPressing = false
			player.altJumpKeyPressing = false
			player.runKeyPressing = false
			player.altRunKeyPressing = false
			player.dropItemKeyPressing = false
			]]
		end
	end

   
   
	function cinematX.onKeyUp (keycode)
		-- Stop gauging the strength of the player's jump
		if   (keycode == KEY_JUMP  and  cinematX.playerHoldingJump == true)   then
			cinematX.playerHoldingJump = false
			--cinematX.playerActor.jumpStrength = 8
		end
	end
   
	function cinematX.onKeyDown (keycode)
		--cinematX.toConsoleLog ("Key pressed: "..tostring(keycode))
	   
	   
		-- Speak to NPCs (if SMBX messages are being overridden)
		if (keycode == KEY_UP                                  	                            and    
			cinematX.overrideNPCMessages ==  true                                           and
			cinematX.currentMessageActor ~=  nil                                            and
			cinematX.currentSceneState   ==  cinematX.SCENESTATE_PLAY)  then
		   
				cinematX.processNPCMessage (cinematX.currentMessageNPCIndex)
				cinematX.refreshHUDOverlay ()
		end
	   
		-- DEBUG: CONSOLE
		if  (keycode == KEY_SEL  and  cinematX.showDebugInfo == true)  then
			if  (cinematX.showConsole == false)  then
				cinematX.showConsole = true
			else
				cinematX.showConsole = false
			end
		end
	   
		-- DEBUG: MEMORY MONITOR
		if (keycode == KEY_UP) then
			cinematX.memMonitorAddress = cinematX.memMonitorAddress + cinematX.memMonitorScroll
		end
	   
		if (keycode == KEY_DOWN  and  cinematX.memMonitorAddress > 0) then
			cinematX.memMonitorAddress = cinematX.memMonitorAddress - cinematX.memMonitorScroll
		end
	   
		if (keycode == KEY_LEFT   and  cinematX.memMonitorField > 1) then
			cinematX.memMonitorField = cinematX.memMonitorField - 1
		end
	   
		if (keycode == KEY_RIGHT  and  cinematX.memMonitorField < 6) then
			cinematX.memMonitorField = cinematX.memMonitorField + 1
		end
	end

end
 
 
 
 
 
 --**************************************************************************************************
--                                                                                                  *
--            COROUTINE FUNCTIONS                                                                   *
--                                                                                                  *
--            THIS SECTION OF CODE BLATANTLY COPIED & EDITED FROM                                   *
--            http://www.mohiji.org/2012/12/14/lua-coroutines/                                      *
--                                                                                                  *
--***************************************************************************************************
 
do
	-- This table is indexed by coroutine and simply contains the time at which the coroutine
	-- should be woken up.
	cinematX.WAITING_ON_TIME = {}
	 
	-- Keep track of how long the game has been running.
	cinematX.CURRENT_TIME = 0
   
   
	function cinematX.yield ()
		return eventu.waitFrames (0)
	end

	function cinematX.waitFrames (frames)
		return eventu.waitFrames (frames)
	end
   
	function cinematX.waitSeconds (seconds)
		return eventu.waitSeconds (seconds)            
	end
   
   
	function cinematX.wakeUpWaitingThreads (deltaTimeParam)
		-- This function should be called once per game logic update with the amount of time
		-- that has passed since it was last called
		cinematX.CURRENT_TIME = cinematX.CURRENT_TIME + deltaTimeParam
 
		-- First, grab a list of the threads that need to be woken up. They'll need to be removed
		-- from the WAITING_ON_TIME table which we don't want to try and do while we're iterating
		-- through that table, hence the list.
		local threadsToWake = {}
		for co, wakeupTime in pairs(cinematX.WAITING_ON_TIME) do
		   
			--windowDebug (wakeupTime.."/"..cinematX.CURRENT_TIME)
		   
			if wakeupTime < cinematX.CURRENT_TIME then     
				table.insert (threadsToWake, co)
			end
		end
 
		-- Now wake them all up.
		for _, co in ipairs(threadsToWake) do
			cinematX.WAITING_ON_TIME[co] = nil -- Setting a field to nil removes it from the table
			cinematX.toConsoleLog ("Waking up")
			coroutine.resume (co)
		end
	end

	
	function cinematX.runCoroutine (func)
		if (func ~= nil)  then
			return eventu.run (func)
		end
	end
	
	function cinematX.stopCoroutine (func)
		return coroutine.yield (func)
	end
	 
	 
	--[[    DEMONSTRATION
	 
	runCoroutine (function ()
			print ("Hello world. I will now astound you by waiting for 2 seconds.")
			waitSeconds(2)
			print ("Haha! I did it!")
	end)
	 
	 
	From the original author of this script:
	"And that’s it. Call wakeUpWaitingThreads from your game logic loop and you’ll be able to have a bunch of functions waking up after sleeping for some period of time.
	 
	Note: this might not scale to thousands of coroutines. You might need to store them in a priority queue or something at that point."
	--]]
	 
	 
	cinematX.WAITING_ON_SIGNAL = {}

	function cinematX.waitSignal (signalName)
		-- Same check as in waitSeconds; the main thread cannot wait
		local co = coroutine.running ()
		assert (co ~= nil, "The main thread cannot wait!")

		if cinematX.WAITING_ON_SIGNAL[signalStr] == nil then
			-- If there wasn't already a list for this signal, start a new one.
			cinematX.WAITING_ON_SIGNAL[signalName] = { co }
		else
			table.insert (cinematX.WAITING_ON_SIGNAL[signalName], co)
		end
	   
		return coroutine.yield ()
	end
   

	function cinematX.signal (signalName)

		local threads = cinematX.WAITING_ON_SIGNAL[signalName]
		if threads == nil then return end

		cinematX.WAITING_ON_SIGNAL[signalName] = nil
		for _, co in ipairs (threads) do
			coroutine.resume (co)
		end
	end
   
   
	function cinematX.waitForDialog ()
		cinematX.toConsoleLog ("Begin waiting for dialog closed")
	   
		cinematX.waitSignal ("endDialog")
		--cinematX.waitFrames (1)
	end
	
	function cinematX.waitForDialogClosed ()
		cinematX.toConsoleLog ("Begin waiting for dialog closed")
	   
		cinematX.waitSignal ("endDialog")
		--cinematX.waitFrames (1)
	end
   
	function cinematX.waitForDialogFinished ()
		cinematX.toConsoleLog ("Begin waiting for dialog finish")
	   
		cinematX.waitSignal ("endDialogText")
		--cinematX.waitFrames (1)
	end
   
   
	function cinematX.waitForKeyPress (keyString)
		cinematX.toConsoleLog ("Begin waiting for "..keyString.." key pressed")
	   
		cinematX.waitSignal ("keyPress"..keyString)
	end
   
	function cinematX.waitForKeyRelease (keyString)
		cinematX.toConsoleLog ("Begin waiting for "..keyString.." key released")
	   
		cinematX.waitSignal ("keyRelease"..keyString)
	end
   
   
	function cinematX.waitForTextblockFinished (object)
		if  object ~= nil  then
	   
			while (object.index == -1)  do
				cinematX.yield ()
			end
		   
			cinematX.toConsoleLog ("Begin waiting for text block "..tostring(object.index).." to finish")
			cinematX.waitSignal ("blockFinish_"..tostring(object.index))
		else
			windowDebug ("ERROR: INVALID TEXT BLOCK")
		end
	end
   
   
	function cinematX.waitForTextblockClosed (object)
		if  object ~= nil  then
	   
			while (object.index == -1)  do
				cinematX.yield ()
			end
		   
			cinematX.toConsoleLog ("Begin waiting for text block "..tostring(object.index).." to close")
			cinematX.waitSignal ("blockClose_"..tostring(object.index))
		else
			windowDebug ("ERROR: INVALID TEXT BLOCK")
		end
	end
end
         
 
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            TEST ROUTINES                                                                         *
--                                                                                                  *
--***************************************************************************************************
 
do
	function cutscene_TestBreak ()
		cinematX.waitSeconds (2.0)
		npcToCoins ()
	end
   
	function cutscene_TestSceneStates ()           
	   
		cinematX.toConsoleLog ("Begin testing screen modes")
	   
		--windowDebug ("BEGIN TESTING SCENE MODES")
		cinematX.cycleSceneMode ()
		cinematX.waitSeconds (1.0)
	   
		cinematX.cycleSceneMode ()     
		cinematX.waitSeconds (1.0)
					   
		cinematX.cycleSceneMode ()     
		cinematX.waitSeconds (1.0)
	   
		cinematX.toConsoleLog ("Finished testing screen modes")

		cinematX.endCutscene ()
	end
   
	function cutscene_LevelStartTest ()
   
		cinematX.setDialogSkippable (true)
		cinematX.setDialogInputWait (true)

		--cinematX.waitSeconds (1)
		cinematX.startDialog  (-1, "TEST", "THIS WORKS", 140, 120, "voice_talk1.wav")
		cinematX.waitForDialog ()              
		cinematX.endCutscene ()
	end
   
	function cutscene_TestDialog ()

		cinematX.setDialogSkippable (true)
		cinematX.setDialogInputWait (true)

		--cinematX.waitSeconds (1)
		cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa1"), "TEST DIALOG TEST DIALOG TEST DIALOG TEST DIALOG TEST DIALOG TEST DIALOG TEST DIALOG TEST DIALOG TEST DIALOG", 140, 120, "voice_talk1.wav")
		cinematX.waitForDialog ()
	   
		cinematX.waitSeconds (1)
		cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa1"), "Hello, this is a test of the cutscene system.", 120, 100, "voice_talk2.wav")
		cinematX.waitForDialog ()

		cinematX.startDialog  (NPCID_BROADSWORD, cinematX.getActorName_Key("goopa1"), "Please remain calm and keep your arms and legs inside the cutscene at all times.", 120, 100, "voice_talk3.wav") 
		cinematX.waitForDialog ()
	   
		cinematX.waitSeconds (1)
		cinematX.endCutscene ()
	end
 
end
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            DIALOGUE MANAGEMENT                                                                   *
--                                                                                                  *
--***************************************************************************************************
 
do
	cinematX.BOXTYPE_SUBTITLE = 0
	cinematX.BOXTYPE_SMBX = 1
	cinematX.BOXTYPE_TEXTBLOX = 2

	cinematX.dialogSetting_promptDelay = 30
	cinematX.dialogSetting_showPrompt = true
	cinematX.dialogSetting_showThisPrompt = true
	cinematX.dialogSetting_autoTime = true
	cinematX.dialogSetting_closeTime = -1
	cinematX.dialogSetting_speakTime = 30
	cinematX.dialogSetting_startSound = ""
	cinematX.dialogSetting_blipSounds = {}
	cinematX.dialogSetting_boxType = cinematX.BOXTYPE_SUBTITLE
	cinematX.dialogSetting_bloxProps = {}
	cinematX.dialogSetting_answers = {}


	--function cinematX.setDialogRules (pause, skippable, needInput, textSpeed)
	function cinematX.configDialog (skippable, needInput, textSpeed)
		--cinematX.dialogPause = pause
		cinematX.setDialogSkippable (skippable)
	   
		if  needInput ~= nil  then
			cinematX.setDialogInputWait (needInput)
		end
	   
		if  textSpeed ~= nil  then
			cinematX.setDialogSpeed (textSpeed)
		end
	end
   
	function cinematX.configDialogExt (properties)
		if  properties ~= nil  then
			if  properties["canSkip"] ~= nil  then
				cinematX.setDialogSkippable (properties["canSkip"])
			end

			if  properties["autoEnd"] ~= nil  then
				cinematX.setDialogInputWait (not properties["autoEnd"])
			end

			if  properties["autoTime"] ~= nil  then
				cinematX.dialogSetting_autoTime = properties["autoTime"]
			end

			if  properties["textSpeed"] ~= nil  then
				cinematX.setDialogSpeed (properties["textSpeed"])
			end
		   
			if  properties["promptDelay"] ~= nil  then
				cinematX.dialogSetting_promptDelay = properties["promptDelay"]
			end
			
			if  properties["showPrompt"] ~= nil  then
				cinematX.dialogSetting_showPrompt = properties["showPrompt"]
			end
		   
			if  properties["closeTime"] ~= nil  then
				cinematX.dialogSetting_closeTime = properties["closeTime"]
			end
		   
			if  properties["speakTime"] ~= nil  then
				cinematX.dialogSetting_speakTime = properties["speakTime"]
			end
		   
			if  properties["startSound"] ~= nil  then
				cinematX.dialogSetting_startSound = properties["startSound"]
			end
		   
			if  properties["blipSounds"] ~= nil  then
				cinematX.dialogSetting_blipSounds = properties["blipSounds"]
			end
		   
			if  properties["boxType"] ~= nil  then
				cinematX.dialogSetting_boxType = properties["boxType"]
			end
		   
			if  properties["bloxProps"] ~= nil  then
				cinematX.dialogSetting_bloxProps = properties["bloxProps"]
			end
		   
			if  properties["question"] ~= nil  then
				cinematX.dialogIsQuestion = properties["question"]
			end                                    
		end
	end
   
   
	function cinematX.setDialogSpeed (textSpeed)
		cinematX.dialogTextSpeed = textSpeed
	end

	function cinematX.setDialogSkippable (skippable)
		cinematX.dialogSkippable = skippable
	end    
   
	function cinematX.setDialogInputWait (needInput)
		cinematX.dialogEndWithInput = needInput
	end
   
	function cinematX.startQuestion (speakerActor, name, text, textTime, speakTime, sound)
		cinematX.startDialog (speakerActor, name, text, textTime, speakTime, sound)
		cinematX.dialogIsQuestion = true
		cinematX.questionPlayerResponse = nil
	end
   
	function cinematX.getResponse ()
		return cinematX.questionPlayerResponse
	end

   
	function cinematX.formatDialogForWrapping (str)
		local tl = str;
		local hd = "";
		local i = 1;
		while (string.len(tl)>42) do
			local split = cinematX.wrapString(tl,42);
			split.hd = split.hd:gsub("^%s*", "")
			split.tl = split.tl:gsub("^%s*", "")
			local c = 42;
			if(i > 1) then c = 43; end
			while (string.len(split.hd) < c) do
				split.hd = split.hd.." ";
			end
			hd = hd..split.hd;
			tl = split.tl;
			i = i + 1;
		end
		return hd..tl;
	end

	function cinematX.wrapString (str, l)
		local head = "";
		local tail = "";
		local wrds = {}
		local i = 0;
		for j in string.gmatch(str, "%S+") do
			wrds[i] = j;
			i = i + 1
		end
		i = 0;
		while(wrds[i] ~= nil) do
			local newHd = head.." "..wrds[i];
			if(string.len(newHd) <= l) then
				head = newHd;
				i = i + 1
			else
				break;
			end
		end

		while(wrds[i] ~= nil) do
			tail = tail.." "..wrds[i];
			i = i + 1
		end

		return { hd = head, tl = tail };
	end



	function cinematX.startDialog (speakerActor, name, text, textTime, speakTime, sound, autoEnd, skippable)
		local txtTime = textTime or 30
		local spkTime = speakTime or 30
		local snd = sound or ""
		
		-- Auto-end for specific lines
		if  autoEnd == nil  then
			autoEnd = not cinematX.dialogEndWithInput
		end
		cinematX.thisDialogAutoEnd = autoEnd
		
		-- Skippable for specific lines
		if  skippable == nil  then
			skippable = cinematX.dialogSkippable
		end
		cinematX.thisDialogSkippable = skippable
		
		
		-- Voice clip
		if  cinematX.dialogOn == false  and  snd ~= ""  then
			cinematX.playSFXSDLSingle (snd)
		end
	   
		--NPC speaking animation
		if   (speakerActor ~= nil  and  speakerActor ~= -1)   then
			cinematX.triggerDialogSpeaker (speakerActor, spkTime)
		end
	   
		cinematX.triggerDialogText (name, text, txtTime)
		cinematX.dialogOn = true
	end
   
   
	function cinematX.startDialogExt (text, properties)
		local returnObj = nil
	   
		local txtName = ""
		local x = 0
		local y = 0
		local speakerActor = nil
		local promptTime = cinematX.dialogSetting_promptDelay
		local showPrompt = cinematX.dialogSetting_showPrompt
		local closeTime = cinematX.dialogSetting_closeTime
		local speakTime = cinematX.dialogSetting_speakTime
		local startSound = cinematX.dialogSetting_startSound
		local blipSounds = cinematX.dialogSetting_blipSounds
		local skippable = cinematX.dialogSkippable
		local autoEnd = cinematX.dialogEndWithInput
		local autoTime = cinematX.dialogSetting_autoTime
		local boxType = cinematX.dialogSetting_boxType
		local bloxProps = cinematX.dialogSetting_bloxProps
		local answers = cinematX.dialogSetting_Answers

		local textSpeed = cinematX.dialogTextSpeed
		
		if  properties ~= nil  then
			if  properties["x"] ~= nil  then
				x = properties["x"]
			end
		   
			if  properties["y"] ~= nil  then
				y = properties["y"]
			end
   
			if  properties["name"] ~= nil  then
				txtName = properties["name"]                                            -- string
			end
		   
			if  properties["actor"] ~= nil  then
				speakerActor = properties["actor"]                                      -- Actor ref
			end

			if  properties["promptDelay"] ~= nil  then
				promptTime = properties["promptDelay"]                     			    -- int
			end
			
			if  properties["showPrompt"] ~= nil  then
				showPrompt = properties["showPrompt"]                     			    -- boolean
			end
		   
			if  properties["closeTime"] ~= nil  then
				closeTime = properties["closeTime"]                   			        -- int
			end
			
			if  properties["textSpeed"] ~= nil  then				
				textSpeed = properties["textSpeed"]										-- float
			end		   
			
			if  properties["speakTime"] ~= nil  then		
				speakTime = properties["speakTime"]                  			        -- int
			end
		   
			if  properties["startSound"] ~= nil  then
				startSound = properties["startSound"]                  			        -- filename string
			end
		   
			if  properties["blipSounds"] ~= nil  then
				blipSounds = properties["blipSounds"]                 					-- table of filename strings
			end
		   
			if  properties["canSkip"] ~= nil  then
				skippable = properties["canSkip"]                                       -- boolean
			end
		   
			if  properties["autoEnd"] ~= nil  then
				autoEnd = properties["autoEnd"]                                         -- boolean
			end
			
			if  properties["autoTime"] ~= nil  then
				autoTime = properties["autoTime"]                                       -- boolean
			end
		   
			if  properties["boxType"] ~= nil  then
				boxType = properties["boxType"]                                         -- box type enum
			end
		   
			if  properties["bloxProps"] ~= nil  then
				bloxProps = properties["bloxProps"]                                     -- textblox property table
				
				if  bloxProps["font"] == nil  then
					bloxProps["font"] = cinematX.subtitleFont
				end
			end
		   
			if  properties["answers"] ~= nil  then
				answers = properties["answers"]                                         -- textblox property table
			end
		end
	   
	   
		if      boxType == cinematX.BOXTYPE_SUBTITLE    then
			--cinematX.subtitleBoxBlock.autoClose = autoEnd
			cinematX.subtitleBoxBlock.defaultSpeed = textSpeed
			cinematX.subtitleBoxBlock.autoTime = autoTime
			cinematX.subtitleBoxBlock.finishDelay = closeTime
			cinematX.dialogSetting_showThisPrompt = showPrompt
	   
			cinematX.startDialog (speakerActor, txtName, text, promptTime, speakTime, startSound, autoEnd, skippable)
	   
		elseif  boxType == cinematX.BOXTYPE_SMBX        then
			Text.showMessageBox (text)
	   
		elseif  boxType == cinematX.BOXTYPE_TEXTBLOX    then  
			if  startSound ~= nil  then
				cinematX.playSFXSDLSingle (startSound)
			end
			--[[
			if   (speakerActor ~= nil  and  speakerActor ~= -1)   then
				cinematX.triggerDialogSpeaker (speakerActor, speakTime)
			end
			]]
			returnObj = TextBlock.create (x,y, text, bloxProps)
	   
		end
	   
		return returnObj
	end
   
   
	function cinematX.triggerDialogSpeaker (speakerActor, timeVal)
		cinematX.dialogSpeaker = speakerActor
		cinematX.dialogSpeakerTime = timeVal
	end

	function cinematX.triggerDialogText (name,text,textTime)
		cinematX.dialogName = name
		cinematX.dialogTextFull = cinematX.formatDialogForWrapping (text)
		cinematX.dialogTextTime = textTime
	   
		if  cinematX.textbloxSubtitle == true  then
			
			cinematX.subtitleBoxBlock:resetText (text)
			--[[
			cinematX.subtitleBoxBlock.text = text
			cinematX.subtitleBoxBlock.charsShown = 0
			cinematX.subtitleBoxBlock.finished = false
			cinematX.subtitleBoxBlock.updatingChars = true
			cinematX.subtitleBoxBlock.pauseFrames = -1
			]]
		end
	end
		   
	function cinematX.getDialogFinished ()
		local result = false
	   
		if  cinematX.textbloxSubtitle == true  then
			result = cinematX.subtitleBoxBlock:isFinished ()
		else
			result = cinematX.dialogNumCharsCurrent >= string.len (cinematX.dialogTextFull)
		end
	   
		return result
	end
		   
	function cinematX.endDialogLine ()
		cinematX.dialogOn = false
		cinematX.dialogTextTime = 0
		cinematX.dialogSpeakerTime = 0
		cinematX.dialogSpeaker = 0
		cinematX.dialogNumCharsCurrent = 0
		cinematX.dialogNumCharsTotal = 0
		cinematX.dialogTextFull = ""
	   cinematX.dialogLineEnded = false
	   
		cinematX.dialogIsQuestion = false
	   
		if  (cinematX.textbloxSubtitle == true)  then
			cinematX.subtitleBoxBlock.visible = false
			cinematX.subtitleBoxBlock:resetText("")

		end
	   
		cinematX.signal ("endDialog")
	end

	function cinematX.displayNPCSubtitle (name, text)
		if  cinematX.textbloxSubtitle == true  then
			textblox.print (name, 400, 510, cinematX.subtitleFont, textblox.HALIGN_MID, textblox.HALIGN_TOP, 999, 1)
			textblox.print (text, 400, 530, cinematX.subtitleFont, textblox.HALIGN_MID, textblox.HALIGN_TOP, 999, 1)
		else
			--cinematX.dialogOn = true
			cinematX.printCenteredText (name, 4, 400, 510)
			cinematX.printCenteredText (text, 4, 400, 530)
		end
	end
   
	function cinematX.processNPCMessage (npcIndex)
	   
		-- Parse the NPC's message
		--local tempMsgStr = cinematX.npcMessageStrings [npcIndex]
		local thisActor = cinematX.indexedActors[npcIndex]
		thisActor.messageIsNew = false
	   
		local tempFunctStr = ""
		local tempFunctA = nil
		local tempFunctB = nil
	   
		--windowDebug ("R: " .. cinematX.npcMessageRoutines [npcIndex] .. ", C: " .. cinematX.npcMessageScenes [npcIndex])
		--windowDebug ("R: " .. cinematX.npcMessageRoutines [npcIndex] .. ", C: " .. cinematX.npcMessageScenes [npcIndex])
	   
	   
		-- Call the coroutine or cutscene
		if      (thisActor.sceneString ~= nil)   then
			tempFunctStr = thisActor.sceneString
			tempFunctA = loadstring ("return __lunalocal."..tempFunctStr)
			tempFunctB = tempFunctA ()
			--windowDebug (tempFunctStr .. " " .. type(tempFunctB))
			cinematX.runCutscene (tempFunctB)
			   
			--loadstring ("cinematXMain.runCutscene (__lunalocal."..tempFunctString..")") ()
		   
		elseif  (thisActor.routineString ~= nil) then
			tempFunctStr = thisActor.routineString
			tempFunctA = loadstring ("return __lunalocal."..tempFunctStr)
			tempFunctB = tempFunctA ()
			--windowDebug (tempFunctStr .. " " .. type(tempFunctB))
			cinematX.runCoroutine (tempFunctB)
		end
	   
	   
		-- LOG TO CONSOLE
		if  (tempFunctB == nil)  then
			cinematX.toConsoleLog ("ERROR: Function '" .. tempFunctStr .. "' does not exist")
		else
			cinematX.toConsoleLog ("Actor " .. tostring(npcIndex) .. " calling scene " .. tempFunctStr)
		end
	end
   
   
	cinematX.playerNameASXT = function ()
		return cinematX.playerNames ("Demo", "Iris", "Kood", "raocow", "Sheath")
	end
   
	cinematX.playerNameASXT2 = function ()
		return cinematX.playerNames ("Nevada", "Pily", "Alt P3", "Alt P4", "Broadsword")
	end
   
	cinematX.playerNameSMBX = function ()
		return cinematX.playerNames ("Mario", "Luigi", "Peach", "Toad", "Link")
	end
   
	function cinematX.playerNames (marioName, luigiName, peachName, toadName, linkName)
		local indexVal = player:mem(0xF0, FIELD_WORD) --player.Identity

		if      indexVal == 0  then
			return "NONE"
		elseif  indexVal == 1  then
			return marioName
		elseif  indexVal == 2  then
			return luigiName
		elseif  indexVal == 3  then
			return peachName
		elseif  indexVal == 5  then
			return linkName
		else
			return toadName
		end
	end
   
   
	function cinematX.printCenteredText (text, font, xPos, yPos)
		if text ~= nil then
			if  cinematX.textbloxSubtitle == true  then
				textblox.print (text, xPos, yPos, cinematX.subtitleFont, textblox.HALIGN_MID, textblox.HALIGN_TOP, 999, 1)
			else
				Text.printWP (text, font, xPos-9 * string.len(text), yPos, 3.495)
			end
		end
	end
end
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            BOSS/DYNAMIC SEQUENCE MANAGEMENT                                                      *
--                                                                                                  *
--***************************************************************************************************
 
do
	function cinematX.beginRace (otherActor, startX, endX, raceFunc, loseFunc, winFunc)
	   
		cinematX.raceEnemyActor = otherActor
		cinematX.raceStartX = startX
		cinematX.raceEndX = endX
	   
		cinematX.raceLoseRoutine = loseFunc
		cinematX.raceWinRoutine = winFunc
	   
		cinematX.changeSceneMode (cinematX.SCENESTATE_RACE)    
		cinematX.refreshHUDOverlay ()
		cinematX.raceActive = true
	   
		cinematX.runCoroutine (raceFunc)
	end
   
   
	function cinematX.beginBattle (name, hits, barType, func)
		cinematX.bossName = name
	   
		cinematX.bossHPMax = hits
		cinematX.bossHP = cinematX.bossHPMax
		cinematX.bossHPEase = cinematX.bossHP
	   
		cinematX.bossHPDisplayType = barType
		cinematX.changeSceneMode (cinematX.SCENESTATE_BATTLE)
		cinematX.refreshHUDOverlay ()
	   
		cinematX.runCoroutine (func)
	end
   
	function cinematX.getBattleProgress ()
		return cinematX.bossHP
	end
   
	function cinematX.getBattleProgressPercent ()
		return (cinematX.bossHPMax - cinematX.bossHP) / cinematX.bossHPMax
	end    
   
	function cinematX.setBattleProgress (amount)
		cinematX.bossHP = cinematX.bossHP - amount
	   
		if cinematX.bossHP <= 0 then
			cinematX.winBattle ()
		end
	end
   
	--[[
	function cinematX.winBattle ()
	end
   
	function cinematX.loseBattle ()
	end
	--]]
end
 
 
 
 
--***************************************************************************************************
--                                                                                                  *
--            SIDEQUEST MANAGEMENT                                                                  *
--                                                                                                  *
--***************************************************************************************************
 
do
	cinematX.questName = {}
	cinematX.questDescr = {}
	cinematX.currentQuestKey = ""
	cinematX.displayQuestInfo = false
   
	cinematX.QUESTSTATE_NOTSTARTED = 0
	cinematX.QUESTSTATE_STARTED = 1
	cinematX.QUESTSTATE_FINISHED = 2
   
   
	function cinematX.defineQuest (questKey, missionName, missionText)
		cinematX.setQuestName (questKey, missionName)
		cinematX.setQuestDescription (questKey, missionText)
	end

	function cinematX.setQuestName (questKey, missionName)
		cinematX.questName[questKey] = missionName
	end

	function cinematX.setQuestDescription (questKey, missionText)
		cinematX.questDescr[questKey] = missionText
	end

	function cinematX.displayQuestState (questKey)
		local tempState = cinematX.getQuestState (questKey)
	   
		if  cinematX.useNewUI == true  and  cinematX.canUseNewUI == true  then
			cinematX.drawMenuBox (30,140,740,200, 0x00000099)
		else
			Graphics.drawImageWP (cinematX.IMGREF_QUESTBOX, 0, 0, 3.494)   
		end
	   
	   
		if  tempState == cinematX.QUESTSTATE_STARTED  then
			cinematX.printCenteredText ("QUEST ACCEPTED:", 4, 400, 200)
		elseif  tempState == cinematX.QUESTSTATE_FINISHED  then
			cinematX.printCenteredText ("QUEST COMPLETED:", 4, 400, 200)
		end
	   
		cinematX.printCenteredText (cinematX.questName[questKey], 4, 400, 240)
		cinematX.printCenteredText (cinematX.questDescr[questKey], 4, 400, 260)
		--cinematX.printCenteredText (tostring(cinematX.getQuestState(questKey)), 4, 400, 380, 60)
	end
   
	function cinematX.setQuestState (questKey, questState)
		cinematX.questData:set ("questState_" .. questKey, tostring(questState))
		cinematX.questData:save ()
	   
		if   questState ~= cinematX.QUESTSTATE_NOTSTARTED   then
			cinematX.currentQuestKey = questKey
			cinematX.displayQuestInfo = true
		end
	end
   
	function cinematX.setQuestProgress (questKey, questProgress, newMessage)
		cinematX.questData:set ("questProg_" .. questKey, tostring(questProgress))
		cinematX.questData:save ()
					   
		if (newMessage ~= "") then
			cinematX.setQuestDescription (questKey, newMessage)
		end
	end
   
	function cinematX.initQuest (questKey)
		cinematX.setQuestState (questKey, cinematX.QUESTSTATE_NOTSTARTED)
		cinematX.setQuestProgress (questKey, 0)
	end

	function cinematX.beginQuest (questKey)
		cinematX.setQuestState (questKey, cinematX.QUESTSTATE_STARTED)
	end

	function cinematX.finishQuest (questKey)
		cinematX.setQuestState (questKey, cinematX.QUESTSTATE_FINISHED)
	end
   
	function cinematX.getQuestProgress (questKey)
		local loadedData = cinematX.questData:get("questProg_"..questKey)
		local returnval = -1
	   
		if  loadedData ~= ""  then
			returnval = tonumber (loadedData)
		end
	   
		return returnval
	end
   
	function cinematX.getQuestState (questKey)
		local loadedData = cinematX.questData:get("questState_"..questKey)
		local returnVal = -1
	   
		if loadedData ~= "" then
			returnval = tonumber (loadedData)
		end
	   
		return returnval
	end
   
	function cinematX.isQuestStarted (questKey)
		if  cinematX.getQuestState (questKey) ~= cinematX.QUESTSTATE_NOTSTARTED  then
			return true
		else
			return false
		end
	end
   
	function cinematX.isQuestFinished (questKey)
		if  cinematX.getQuestState (questKey) == cinematX.QUESTSTATE_FINISHED  then
			return true
		else
			return false
		end
	end
end
 
 
 
 
--***************************************************************************************************
--                                                                                                  *
--           CUTSCENE MANAGEMENT                                                                    *
--                                                                                                  *
--***************************************************************************************************
 
do
	cinematX.tempPlayerX = 0
	cinematX.tempPlayerY = 0
	cinematX.tempPlayerXSpeed = 0
	cinematX.tempPlayerYSpeed = 0
	cinematX.tempPlayerPowerup = 0
	cinematX.tempPlayerState = 0
   
	function cinematX.savePlayerPosition ()
		cinematX.tempPlayerX = player.x
		cinematX.tempPlayerY = player.y
		cinematX.tempPlayerXSpeed = player.speedX
		cinematX.tempPlayerYSpeed = player.speedY
		cinematX.tempPlayerPowerup = player.powerup
		cinematX.tempPlayerState = player:mem (0x112, FIELD_WORD)
	end    
   
	function cinematX.restorePlayerPosition ()
		player.x = cinematX.tempPlayerX
		player.y = cinematX.tempPlayerY
		player.speedX = cinematX.tempPlayerXSpeed
		player.speedY = cinematX.tempPlayerYSpeed
		player.powerup = cinematX.tempPlayerPowerup
		player:mem (0x112, FIELD_WORD, cinematX.tempPlayerState)
	end
   
   
   
   
	tintColS = 0x00000000
	tintColE = 0x00000000
	tintLerpTime = 0
   
	function cinematX.setScreenTint (newCol)
		cinematX.screenTintColor = col
	end
   
	function cinematX.lerpScreenTint (newCol, timeAmt)
		tintColS = cinematX.screenTintColor
		tintColE = newCol
		tintLerpTime = timeAmt
		cinematX.runCoroutine (cor_lerpScreenTint)
	end
   
   
	function cor_lerpScreenTint ()
		local colTime = tintLerpTime
		local colS = tintColS
		local colE = tintColE
	   
		local currentTime = 0
	   
		while  currentTime < colTime  do
			local lerpAmt = invLerp (0, colTime, currentTime)
			local col = lerp (colS, colE, lerpAmt)
			cinematX.screenTintColor = col
			currentTime = currentTime + cinematX.deltaTime
			cinematX.waitSeconds(0.0)
		end
	end
   
   
	function cinematX.enterCameraMode ()
		cinematX.savePlayerPosition ()
		cinematX.cameraFocusX = player.x --0.5*(Player.screen.left + Player.screen.right)
		cinematX.cameraFocusY = player.y --0.5*(Player.screen.top + Player.screen.bottom)
		cinematX.cameraControlOn = true
	end
   
	function cinematX.exitCameraMode ()
		cinematX.cameraControlOn = false
		player:mem (0x112, FIELD_WORD, 0)
		cinematX.restorePlayerPosition ()
	end
   
   
	function cinematX.runCutscene (func)
		cinematX.changeSceneMode (cinematX.SCENESTATE_CUTSCENE)
		--cinematX.enterCameraMode ()
		cinematX.refreshHUDOverlay ()
	   
		return cinematX.runCoroutine (func)
	end
		   
	function cinematX.endCutscene ()
		cinematX.changeSceneMode (cinematX.SCENESTATE_PLAY)
		if  (cinematX.playerActor.shouldWalkToDest == true)  then
				cinematX.playerActor:walk(0)
		end
			   
		--cinematX.exitCameraMode ()
	end
   
	function cinematX.cycleSceneMode ()
		cinematX.changeSceneMode ((cinematX.currentSceneState + 1) % 4)
	end
		   
	function cinematX.changeSceneMode (sceneModeType)      
		cinematX.currentSceneState = sceneModeType
		cinematX.toConsoleLog ("SWITCH TO STATE "..cinematX.currentSceneState)

	end

   
   

	function cinematX.refreshHUDOverlay ()
		if (cinematX.useNewUI == true  and  cinematX.canUseNewUI == true)  		then
			cinematX.changeHudOverlay (cinematX.IMGREF_BLANK)
			return;
		end

		-- Enable the hud
		hud (true)

	   
		-- DEBUG CONSOLE
		if      (cinematX.showConsole == true)                                  then
			hud (false)
			cinematX.changeHudOverlay (cinematX.IMGREF_FULLOVERLAY)        
	   
		-- Race mode
		elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_RACE)      then
			cinematX.changeHudOverlay (cinematX.IMGREF_RACEBG)
	   
		-- Boss battle mode
		elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_BATTLE)    then
			cinematX.changeHudOverlay (cinematX.IMGREF_BOSSHP_BG)          
	   
		-- Cutscene mode
		elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_CUTSCENE)  then
							   
			-- Disable the hud
			hud (false)
			cinematX.changeHudOverlay (cinematX.IMGREF_BLANK)
			   
	   
		-- Play mode
		elseif  (cinematX.currentSceneState  ==  cinematX.SCENESTATE_PLAY)      then

			if      (cinematX.dialogOn == true)       then
				cinematX.changeHudOverlay (cinematX.IMGREF_PLAYDIALOGBOX)
			elseif  (cinematX.subtitleBox == true)    then
				cinematX.changeHudOverlay (cinematX.IMGREF_BOSSHP_BG)
			else
				cinematX.changeHudOverlay (cinematX.IMGREF_BLANK)
			end
		end
	end
   
   
	function cinematX.changeHudOverlay (imageRef)

		if   cinematX.currentImageRef_screen ~= imageRef   then
		   
			-- Screen overlay      
			cinematX.currentImageRef_screen = imageRef
		   
		   
			-- Hud box
			if   imageRef == cinematX.IMGREF_LETTERBOX  or  cinematX.useHUDBox == false  then
				cinematX.currentImageRef_hud = cinematX.IMGREF_BLANK
			else
				cinematX.currentImageRef_hud = cinematX.IMGREF_HUDBOX
			end
		end            
	end    
   
   
   
	cinematX.changeSection_outTime = 0
	cinematX.changeSection_inTime = 0
	cinematX.changeSection_newSect = 0
   
	function cinematX.changeSection (newSection, outSeconds, inSeconds)
		cinematX.changeSection_outTime = outSeconds or 1
		cinematX.changeSection_inTime = inSeconds or 1
		cinematX.changeSection_newSect = newSection or 1

		cinematX.runCoroutine (cinematX.cor_changeSection)
	end

   
	function cinematX.cor_changeSection ()
		local inTime = cinematX.changeSection_inTime
		local outTime = cinematX.changeSection_outTime
		local newSect = cinematX.changeSection_newSect
	   
		cinematX.fadeScreenOut (outTime)
		cinematX.waitSeconds (outTime)
	   
		player:mem (0x15A, FIELD_WORD, newSect)
	   
		cinematX.fadeScreenIn (inTime)
	end
   
		   
   
	cinematX.warpFadeSeconds = 0
   
	function cinematX.warpFade (seconds)
		cinematX.warpFadeSeconds = seconds
		cinematX.runCoroutine (cor_warpFade)
	end
		   
	function cor_warpFade ()
		local seconds = cinematX.warpFadeSeconds
	   
		cinematX.fadeScreenOut (seconds)
		cinematX.waitSeconds (seconds+0.2)
		cinematX.fadeScreenIn (seconds)
	   
	end
   
		   
	function cinematX.fadeScreenOut (seconds)
		--cinematX.stopCoroutine (cinematX.cor_fadeOut)
		--cinematX.stopCoroutine (cinematX.cor_fadeIn)
		cinematX.screenTransitionTime = seconds or 1
		cinematX.runCoroutine (cinematX.cor_fadeOut)
	end

	function cinematX.fadeScreenIn (seconds)
		--cinematX.stopCoroutine (cinematX.cor_fadeOut)
		--cinematX.stopCoroutine (cinematX.cor_fadeIn)
		cinematX.screenTransitionTime = seconds or 1
		cinematX.runCoroutine (cinematX.cor_fadeIn)
	end
   
   
	function cinematX.cor_fadeOut ()
		currentTime = 0
		cinematX.screenTransitionAmt = 0
	   
		while (currentTime < cinematX.screenTransitionTime) do
			currentTime = currentTime + cinematX.deltaTime
			cinematX.screenTransitionAmt = math.min(1, currentTime/cinematX.screenTransitionTime)
			cinematX.waitSeconds (0)
		end
	   
		cinematX.screenTransitionAmt = 1
	end
   
	function cinematX.cor_fadeIn ()
		currentTime = 0
		cinematX.screenTransitionAmt = 1
	   
		while (currentTime < cinematX.screenTransitionTime) do
			currentTime = currentTime + cinematX.deltaTime
			cinematX.screenTransitionAmt = math.max (1-(currentTime/cinematX.screenTransitionTime), 0)
			cinematX.waitSeconds (0)
		end
	   
		cinematX.screenTransitionAmt = 0
	end
 
       
       
  	function cinematX.drawMenuBorder (x,y,w,h)
		if  cinematX.useNewUI == true  and  cinematX.canUseNewUI == true  then
			graphX.menuBorderScreen (x,y,w,h)
		end
	end

	function cinematX.drawMenuBox (x,y,w,h, col)
		-- Fill
		graphX.boxScreen (x,y,w,h, col, graphX.MENU_FILL)		
				
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)
	end
	
	
	function cinematX.drawProgressBarLeft (x,y,w,h, col, amt)		
		
		-- Fill
		if 	cinematX.useNewUI == false  or  cinematX.canUseNewUI == false  then
			if  cinematX.delayedInitCounter > 0  and  amt > 0  then
				if  col == 0xBB0000FF  then
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_RED, 		x,	y, 0,0, w*amt,	h,   3.495)
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_RED, 		x,	y, 0,0, w*amt,	h,   3.495)
				elseif  col < 0x000000FF  then
					Graphics.drawImageWP (cinematX.IMGREF_NOGLFADE, 		x,	y, 0,0, w*amt,	h,   3.495)
				else
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_GREEN, 	x,	y, 0,0,	w*amt,	h,   3.495)
				end
			end
		else
			graphX.boxScreen (x,	y,	w*amt,	h,	col)		
		end
		
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)		
	end
		
		
	function cinematX.drawProgressBarRight (x,y,w,h, col, amt)		
		
		-- Fill
		if 	cinematX.useNewUI == false  or  cinematX.canUseNewUI == false  then
			if  cinematX.delayedInitCounter > 0  and  amt > 0  then
				if  col == 0xBB0000FF  then
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_RED, 		x + w*(1-amt),	y, 0,0,	w*amt,	h,   3.495)
				else
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_GREEN, 	x + w*(1-amt),	y, 0,0, w*amt,	h,   3.495)
				end
			end
		else
			graphX.boxScreen (x + w*(1-amt),	y,	w*amt,	h,	col)		
		end
		
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)	
	end

	
	function cinematX.drawProgressBarTop (x,y,w,h, col, amt)		
		
		-- Fill
		if 	cinematX.useNewUI == false  or  cinematX.canUseNewUI == false  then
			if  cinematX.delayedInitCounter > 0  and  amt > 0  then
				if  col == 0xBB0000FF  then
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_RED, 		x,	y, 0,0,	w,	h*amt,   3.495)
				else
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_GREEN, 	x,	y, 0,0,	w,	h*amt,   3.495)
				end
			end
		else
			graphX.boxScreen (x,	y,	w,	h*amt,	col)		
		end
		
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)			
	end

	
	function cinematX.drawProgressBarBottom (x,y,w,h, col, amt)	
		
		-- Fill
		if 	cinematX.useNewUI == false  or  cinematX.canUseNewUI == false  then
			if  cinematX.delayedInitCounter > 0  and  amt > 0  then
				if  col == 0xBB0000FF  then
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_RED, 		x,	y + h*(1-amt), 0,0,	w,	h*amt,   3.495)
				else
					Graphics.drawImageWP (cinematX.IMGREF_NOGLBOX_GREEN, 	x,	y + h*(1-amt), 0,0,	w,	h*amt,   3.495)
				end
			end
		else
			graphX.boxScreen (x,	y + h*(1-amt),	w,	h*amt,	col)		
		end
		
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)	
	end

 
       
   
   
	cinematX.lastSFXPlayed = -1
	cinematX.delaySFX = 0
	cinematX.lastSFXSDLPlayed = ""
	cinematX.delaySFXSDL = 0
   

	function cinematX.cor_SFXSingle ()
		local delay = cinematX.delaySFX
		playSFX (cinematX.lastSFXPlayed)
		cinematX.waitSeconds (delay)
		cinematX.lastSFXPlayed = -1
	end
   
	function cinematX.cor_SFXSDLSingle ()
		local delay = cinematX.delaySFXSDL
		playSFXSDL (cinematX.lastSFXSDLPlayed)
		cinematX.waitSeconds (delay)
		cinematX.lastSFXSDLPlayed = ""
	end
   
	function cinematX.playSFXSingle (sound, seconds)
		if  cinematX.lastSFXPlayed ~= sound  then
			cinematX.lastSFXPlayed = sound
			cinematX.delaySFX = seconds or 0.1
			cinematX.runCoroutine (cinematX.cor_SFXSingle)
		end
	end

	function cinematX.playSFXSDLSingle (sound, seconds)
		if  cinematX.lastSFXSDLPlayed ~= sound  then
			cinematX.lastSFXSDLPlayed = sound
			cinematX.delaySFXSDL = seconds or 0.1
			cinematX.runCoroutine (cinematX.cor_SFXSDLSingle)
		end
	end

end
 
       
 
       
 
--***************************************************************************************************
--                                                                                                  *
--           DEBUG STUFF                                                                            *
--                                                                                                  *
--***************************************************************************************************
 
do
	function cinematX.toConsoleLog (text)
		cinematX.debugLogTable [cinematX.debugCurrentLine] = text
		cinematX.debugCurrentLine = cinematX.debugCurrentLine + 1
	end
   
	function cinematX.displayDebugText (text)
		if  (cinematX.showDebugInfo == true)  then
			cinematX.printCenteredText (text, 4, 400, 300+math.random(-1,1))
		end
		   
		cinematX.toConsoleLog (text)
	end
 
end
 
 
 
 
--***************************************************************************************************
--                                                                                                  *
--           MATH                                                                                   *
--                                                                                                  *
--***************************************************************************************************
 
do
 
	function dirSign (direction)
		local dirMult = -1
		if direction == DIR_RIGHT then
				dirMult = 1
		end
	   
		return dirMult
	end


	function lerp (minVal, maxVal, percentVal)
		return (1-percentVal) * minVal + percentVal*maxVal;
	end
   
	function invLerp (minVal, maxVal, amountVal)                   
		return  math.min(1.00000, math.max(0.0000, math.abs(amountVal-minVal) / math.abs(maxVal - minVal)))
	end
   
   
    function magnitude (x,y)
		local vx = x
		local vy = y
	   
		local length = math.sqrt(vx * vx + vy * vy);
		return length
	end
   
   
	function normalize (x, y)
		local vx = x
		local vy = y
	   
		local length = magnitude(x,y);

		-- normalize vector
		vx = vx/length;
		vy = vy/length;

		return vx,vy
	end
   
   
   
	function intToHexString (hexVal)
		return string.format("%X", hexVal)
	end
   
	function hexToDec (hexVal)
	end
   
	function decToHex (decVal)
	end
   
	function cinematX.coordToSpawnX (xPos)
		local newX = xPos*-(8) - 1572863.88
		return newX
	end
   
	function cinematX.coordToSpawnY (yPos)
		local newY = yPos*-(8) - 1572864.08
		return newY
	end

	function cinematX.spawnToCoordX (xPos)
		local newX = -(xPos + 1572863.88)/8
		return newX
	end
   
	function cinematX.spawnToCoordY (yPos)
		local newY = -(yPos + 1572864.08)/8
		return newY
	end
end
 
 
       
--***************************************************************************************************
--                                                                                                  *
--           NPC MANAGEMENT                                                                         *
--                                                                                                  *
--***************************************************************************************************
 
do     
	function cinematX.validateNPCRef (ref)
		if  ref == nil  then
			return false
		end
	   
		if  ref.isValid == false  then
			return false
		end            
	   
		if  ref.id == nil  then
			return false
		end            
	   
		if  ref.id == -1  then
			return false
		end            
			   
		if  ref:mem (0x122, FIELD_WORD) ~= 0  then
			return false
		end
			   
		return true
	end


	function cinematX.getNPCFromKey (keyStr)
		return cinematX.getActorFromKey (keyStr).smbxObjRef
	end

	function cinematX.getActorFromKey (keyStr)
		local thisIndex = cinematX.getNPCIndexFromKey (keyStr)
		return cinematX.indexedActors[cinematX.npcMessageKeyIndexes[keyStr]]  --thisIndex]
	end

	function cinematX.getActorFromNPC (npcRef)
		local uid = npcRef:mem (cinematX.ID_MEM, cinematX.ID_MEM_FIELD)
		return cinematX.indexedActors[uid]
	end
   
	function cinematX.getNPCIndexFromKey (keyStr)
		local thisIndex = cinematX.npcMessageKeyIndexes[keyStr]
		--cinematX.toConsoleLog ("GOT INDEX "..tostring(thisIndex).." FROM KEY "..keyStr)
		--windowDebug ("key = '"..keyStr.."', "..tostring(cinematX.npcMessageKeyIndexes[keyStr])..", "..tostring(cinematX.npcMessageKeyIndexes["calleoca"]))
		return thisIndex
	end

   
	function cinematX.resetNPCMessageNew_Key (keyStr)
		--cinematX.resetNPCMessageNew_Index (cinematX.getNPCIndexFromKey (keyStr))
	end
   
	function cinematX.resetNPCMessageNew_Index (index)
		--cinematX.npcMessageNew [index] = true
	end

   
	function cinematX.setNPCName_Key (keyStr, nameStr)
		--cinematX.setNPCName_Index (cinematX.getNPCIndexFromKey (keyStr), nameStr)
	end
   
	function cinematX.setNPCName_Index (index, nameStr)
		--cinematX.npcMessageNames [index] = nameStr
	end

   
	function cinematX.getNPCName_Key (keyStr)
		return cinematX.getNPCName_Index (cinematX.getNPCIndexFromKey (keyStr))
	end
   
	function cinematX.getActorName_Key (keyStr)
		return cinematX.getActorName_Index (cinematX.getNPCIndexFromKey (keyStr))
	end
   
	function cinematX.getNPCName_Index (index)
		local returnval = cinematX.npcMessageNames [index]
		   
		if returnval == nil  then
			returnval = "NAME NOT FOUND ERROR"
		end
		   
		return returnval
	end
   
	function cinematX.getActorName_Index (index)
		return cinematX.indexedActors [index].nameString
	end
		   
end
 
       
return cinematX
