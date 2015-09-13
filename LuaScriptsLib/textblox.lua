--***************************************************************************************
--                                                                                      *
-- 	textblox.lua																		*
--  v0.1.0a                                                      						*
--  Documentation: ___											  						*
--                                                                                      *
--***************************************************************************************

local textblox = {} --Package table
local SpriteAPI = loadSharedAPI("sprite");
local graphX = loadSharedAPI("graphX");


function textblox.onInitAPI() --Is called when the api is loaded by loadAPI.
	--register event handler
	--registerEvent(string apiName, string internalEventName, string functionToCall, boolean callBeforeMain)
	
	registerEvent(textblox, "onLoop", "update", true) --Register the loop event
end


local textBlockRegister = {}



--***************************************************************************************************
--                                                                                                  *
--              FONT CLASS																    		*
--                                                                                                  *
--***************************************************************************************************

do
	Font = {}
	Font.__index = Font

	function Font.create (imagePath, charWidth, charHeight, kerning)
		local thisFont = {}
		setmetatable (thisFont, Font)
		
		thisFont.imageRef = Graphics.loadImage (Misc.resolveFile(imagePath))
		thisFont.charWidth = charWidth
		thisFont.charHeight = charHeight
		thisFont.kerning = kerning
		
		return thisFont
	end	

	
	function Font:drawCharImage (character, x,y)
		
		local index = string.byte(character,1)-33
		local w = self.charWidth
		local h = self.charHeight
		local sourceX = (index%16) * w
		local sourceY = math.floor(index/16) * h
				
		Graphics.drawImage (self.imageRef, x, y, sourceX, sourceY, w, h)
	end
	

	function textblox.print (text, x,y, font, wrapWidth)
		-- Setup
		local lineBreaks = 0
		local charsOnLine = 0
		local strLength = text:len()
		local wrapW = wrapWidth or 9999
		local currentLineWidth = 0
		local charEndWidth = 0
		local markupCount = 0
		local i = 1
		local totalShownChars = 0
		
		local lastSpaceX = nil
		local lastSpaceY = nil
		
		
		-- Effects
		local shakeMode = false
		local waveMode = false
		
		
		while (i <= strLength) do 
		
			-- Get character
			local lastNum = math.max(1, i-1)
			
			local lastChar = text:sub(lastNum, lastNum)
			local thisChar = text:sub(i,i)
			local nextChar = text:sub(i+1,i+1)
			local continue = false
			
			
			currentLineWidth = (charsOnLine) * (font.charWidth + font.kerning)
			charEndWidth = (charsOnLine+1) * (font.charWidth + font.kerning)
			
			local xPos = x + currentLineWidth
			local yPos = y + (lineBreaks*font.charHeight)
			
			
			-- Process inline commands
			if  thisChar == '<'   then
				
				-- Stop processing the following text
				markupCount = markupCount + 1
				
				-- Line break
				if  text:sub (i, i+2) == '<br'  then 
					lineBreaks = lineBreaks + 1
					charsOnLine = 0
					--i = i + 2

					
				-- Toggle shake mode
				elseif  text:sub (i, i+7) == '<tremble'  	then
					shakeMode = true
					--i = i + 7
				
				-- Turn off shake mode
				elseif  text:sub (i, i+8) == '</tremble'  	then
					shakeMode = false
					--i = i + 8
				
				-- Toggle wave mode
				elseif  text:sub (i, i+4) == '<wave'  		then
					waveMode = true
					--i = i + 4
				
				-- Turn off wave mode
				elseif  text:sub (i, i+5) == '</wave'  		then
					waveMode = false
					--i = i + 5
				end


			elseif  thisChar == ">"  then
				markupCount = markupCount - 1
				continue = true
			end
				
				
			-- Display the current character				
			if  continue == false  and  markupCount <= 0  then				
				
				-- Ensure all apostrophes are displayed correctly
				if  thisChar == "’"  or  thisChar == "‘"  then
					thisChar = "'"
				end

				-- Ignore spaces
				if  thisChar ~= ' '  then
					
					-- Process visual effects
					local xAffected = xPos
					local yAffected = yPos
										
					if  waveMode == true  then
						yAffected = yAffected + math.cos(totalShownChars*0.5 + textblox.waveModeCycle)
					end
					
					if  shakeMode == true  then
						local shakeX = 1--math.max(1, font.charWidth * 0.125)
						local shakeY = 1--math.max(1, font.charHeight * 0.125)
						
						xAffected = xAffected + math.random(-1*shakeX, shakeX)
						yAffected = yAffected + math.random(-1*shakeY, shakeY)
					end
					
					
					-- Finally, draw the image
					font:drawCharImage (thisChar, xAffected, yAffected)
				
				
				-- For debug purposes
				else
					lastSpaceX = xPos
					lastSpaceY = yPos
				end
			
				charsOnLine = charsOnLine + 1
				totalShownChars = totalShownChars + 1
			end
			
			
			-- Increment i
			i = i+1
		end
		
		
		if  lastSpaceX ~= nil  then
			graphX.boxScreen (lastSpaceX,lastSpaceY, font.charWidth,font.charHeight, 0x00990099)
		end
		--windowDebug (text)
	end

end



--***************************************************************************************************
--                                                                                                  *
--              TEXT BLOCK CLASS																    *
--                                                                                                  *
--***************************************************************************************************

do
	TextBlock = {}
	TextBlock.__index = TextBlock
	
	function TextBlock.create(x,y,w,h,textStr,bind,font,halign,valign,speed,xmargin,ymargin)
		
		local thisTextBlock = {}							-- our new object
		setmetatable (thisTextBlock, TextBlock)				-- make TextBlock handle lookup
		
		thisTextBlock.x = x
		thisTextBlock.y = y
		thisTextBlock.width = w
		thisTextBlock.height = h
		thisTextBlock.text = textStr
		thisTextBlock.filteredText = textStr
		thisTextBlock.length = string.len(textStr)
		
		thisTextBlock.bind = bind or "screen"				-- "screen" or "level"
		thisTextBlock.halign = halign or "left"  			-- "left", "mid", "right"
		thisTextBlock.valign = valign or "top"				-- "top", "mid", "bottom"
			
		thisTextBlock.font = font
		
		thisTextBlock.speed = speed or 0.5
		
		thisTextBlock.xMargin = xmargin or 0.0
		thisTextBlock.yMargin = ymargin or 0.0

		thisTextBlock.pauseFrames = 0
		thisTextBlock.shakeFrames = 0
		
		thisTextBlock.lastCharCounted = nil
		thisTextBlock.charsCounted = 0
		thisTextBlock.charsShown = 0
		if (thisTextBlock.speed <= 0) then
			thisTextBlock.charsShown = thisTextBlock.length
		end
		
		table.insert(textBlockRegister, thisTextBlock)
		
		return thisTextBlock
	end

	
	function TextBlock:getTextWrapped ()
		local numCharsPerLine = math.floor((self.width)/self.font.charWidth)
		local wrappedText = textblox.formatDialogForWrapping (self.text, numCharsPerLine)
		return wrappedText
	end
	
	
	function TextBlock:draw ()
		-- Get shake offset
		local shakeX = math.random (-12, 12) * (self.shakeFrames/8)
		local shakeY = math.random (-12, 12) * (self.shakeFrames/8)		
		
		
		-- Draw box
		textblox.drawMenuBox   (self.x - self.xMargin + shakeX,  
								self.y - self.yMargin + shakeY,
								self.width + 2*self.xMargin, 
								self.height + 2*self.yMargin)
	
	
		-- Display text
		local textToShow = string.sub(self:getTextWrapped (), 1, self.charsShown)
		--local wrappedText = textToShow
		
		textblox.print (textToShow, 
						self.x + shakeX, 
						self.y + shakeY,
						self.font,
						self.width)
	end


	function TextBlock:setText (textStr)
		text = textStr
	end
	
	function TextBlock:getLength ()
		return string.len (self:getTextWrapped ())
	end
	
	function TextBlock:getLengthFiltered ()
		return string.len (self.textFiltered)
	end

	
	
	function TextBlock:update ()
		self:updateTiming ()
	end
	
	
	function TextBlock:updateTiming ()
		self.pauseFrames = math.max(self.pauseFrames - 1, 0)
		self.shakeFrames = math.max(self.shakeFrames - 1, 0)
	
	
		-- Clamp typewriter effect to full text length
		if 	self.charsShown >= self:getLength ()  then
			self.charsShown = self:getLength ()
		end
	
		-- Increment typewriter effect
		if  (self.pauseFrames <= 0)  then

			self.charsShown = self.charsShown + 1
			
			local text = self:getTextWrapped ()
			
			
			-- Skip and process commands
			local continueSkipping = true
			
			while  (continueSkipping == true)  do
				
				-- Get current character
				local currentChar = text:sub (self.charsShown, self.charsShown)
				
				-- if it's the start of a command...
				if  currentChar == '<'  then
					
					-- ...First parse the command...
					local commandEnd = text:find ('>', self.charsShown)
					local fullCommand = text:sub (self.charsShown, commandEnd)
					local commandName = fullCommand:match ('%a+', 1)
					local commandArgsPlusEnd = nil
					local commandArgs = nil
					local abortNow = false
					
					if commandName ~= nil  then
						commandArgsPlusEnd = fullCommand:match ('%s.+>', 1)--commandName:len())						
						--windowDebug ("Name: " .. commandName .. "\nArgs plus end: " .. tostring(commandArgsPlusEnd))

					end
					
					if  commandArgsPlusEnd ~= nil  then						
						commandArgs = commandArgsPlusEnd:sub (2, commandArgsPlusEnd:len() - 1)
					end

					
					-- ...then perform behavior based on the command...
					-- Pause:  if no arguments, assume a full second
					if  commandName == 'pause' then
						--windowDebug (tostring(commandArgs))
						
						if  commandArgs == nil then
							commandArgs = 60
						end
						
						--windowDebug (tostring(commandArgs))
						
						self.pauseFrames = self.pauseFrames + commandArgs
						abortNow = true
					
					
					-- change speed
					elseif  commandName == 'speed' then
						if  commandArgs == nil then
							commandArgs = 0.5
						end
						
						self.speed = commandArgs
						abortNow = true
					
					
					-- Play sound effect
					elseif  commandName == 'sound' then
						if  commandArgs ~= nil then
							local sound = Misc.resolveFile (commandArgs)
							
							if sound ~= nil  then
								Audio.playSFX (sound)
							end
						end
						
						self.pauseFrames = self.pauseFrames + commandArgs
				
				
					-- Shake
					elseif  commandName == 'shake' then
						if  commandArgs == 'screen' or commandArgs == '0' or commandArgs == nil  then
							earthquake(8)
							
						elseif  commandArgs == 'box' or commandArgs == '1'  then
							self.shakeFrames = 8
						end
					
					end					
				
				
					-- ...then add the length of the command to the displayed characters to skip the command
					if  abortNow == true  then
						continueSkipping = false
						self.charsShown = self.charsShown
					end
					
					self.charsShown = self.charsShown + fullCommand:len()
				
				
				-- Otherwise, stop processing
				else
					continueSkipping = false			
				end
			end
			
			
			
			-- Pause for X frames
			local framesToPause = (1/self.speed)
			self.pauseFrames = self.pauseFrames + framesToPause
		end
	end
	
	
	function textblox.formatDialogForWrapping (text, wrapChars)
		
		-- Setup
		local newString = text
		local strLength = text:len()
		local currentLineWidth = 0
		local markupMode = 0
		
		local oldPos = 1
		local newOffset = 0
		
		local lineStart = 1
		local charsOnLine = 0
		local totalShownChars = 0
		
		local currentSpace = 1
		local prevSpace = 1
		
		local currentDash = 1
		local prevDash = 1
		
		
		while (oldPos <= strLength) do 
		
			-- Get character
			local lastNum = math.max(1, oldPos-1)
			
			local lastChar = text:sub(lastNum, lastNum)
			local thisChar = text:sub(oldPos,oldPos)
			local nextChar = text:sub(oldPos+1, oldPos+1)
			local continue = false
						
			
			-- Store space position
			if  thisChar == ' '  and  markupMode <= 0   then
				prevSpace = currentSpace
				currentSpace = oldPos
			
			-- Store dash position
			elseif  thisChar == '-'  and  markupMode <= 0   then
				prevDash = currentDash
				currentDash = oldPos
			
			-- Skip tags
			elseif  thisChar == '<'		then		
				markupMode = markupMode + 1
				continue = true
				
				-- But catch pre-existing breaks
				if  text:sub (oldPos, oldPos+3) == '<br>'  then
					charsOnLine = 0
					lineStart = oldPos
					
					currentSpace = oldPos
					prevSpace = oldPos
					currentDash = oldPos
					prevDash = oldPos
				end
				
			elseif  thisChar == ">"  	then
				markupMode = markupMode - 1
				continue = true
			end
				
			
			-- Wrap words when necessary
			if  charsOnLine >= wrapChars  then
			
				-- If a line break can be inserted between words, do so
				if  currentSpace ~= lineStart  then
					local firstHalf = newString:sub (1, currentSpace + newOffset)
					local secondHalf = newString:sub (currentSpace + 1 + newOffset, strLength + newOffset)
				
					newString = firstHalf .. "<br>" .. secondHalf
					newOffset = newOffset + 4
					charsOnLine = 0
					lineStart = oldPos
					
					currentSpace = oldPos
					prevSpace = oldPos
					currentDash = oldPos
					prevDash = oldPos
					
					continue = true
				
				
				-- Otherwise, if the word already has a dash, break the line there
				elseif  currentDash ~= lineStart  then
					local firstHalf = newString:sub (1, currentDash + newOffset)
					local secondHalf = newString:sub (currentDash + 1 + newOffset, strLength + newOffset)					
					
					newString = firstHalf .. "<br>" .. secondHalf
					newOffset = newOffset + 4
					charsOnLine = 0
					lineStart = oldPos
					
					currentSpace = oldPos
					prevSpace = oldPos
					currentDash = oldPos
					prevDash = oldPos
					
					continue = true
				
				
				-- Otherwise, insert a dash and a break
				else
					local firstHalf = newString:sub (1, oldPos - 1 + newOffset)
					local secondHalf = newString:sub (oldPos + newOffset, strLength + newOffset)
					
					newString = firstHalf .. "-<br>" .. secondHalf
					newOffset = newOffset + 5
					charsOnLine = 0
					lineStart = oldPos
					
					currentSpace = oldPos
					prevSpace = oldPos
					currentDash = oldPos
					prevDash = oldPos

					continue = true				
				end
			end

			
			-- Count the current character				
			if  continue == false  and  markupMode <= 0  then			
				charsOnLine = charsOnLine + 1
				totalShownChars = totalShownChars + 1
			end
			
			
			-- Increment i
			oldPos = oldPos+1
		end
		
		return newString
	end
end


--***************************************************************************************************
--                                                                                                  *
--              UPDATE																			    *
--                                                                                                  *
--***************************************************************************************************


textblox.waveModeCycle = 0

do
	function textblox.update ()
		textblox.waveModeCycle = (textblox.waveModeCycle + 0.25)%360
	
		for k,v in pairs (textBlockRegister)  do
			v:update ()
		end
	end
end

	

--***************************************************************************************************
--                                                                                                  *
--              DRAW BOXES																		    *
--                                                                                                  *
--***************************************************************************************************

do
	function textblox.drawMenuBorder (x,y,w,h)

		-- Black outline
		graphX.boxScreen (x-1,		y-1,	w+2,	3,		0x000000FF) -- Top
		graphX.boxScreen (x-1,		y+h-1,	w+2,	3,		0x000000FF) -- Bottom
		graphX.boxScreen (x-1,		y-1,	3,		h+2,	0x000000FF) -- Left
		graphX.boxScreen (x+w-1,		y-1,	3,		h+2,	0x000000FF) -- Right
		
		-- White outline
		graphX.boxScreen (x,			y,		w,		1,		0xFFFFFFFF) -- Top
		graphX.boxScreen (x,			y+h,	w,		1,		0xFFFFFFFF) -- Bottom
		graphX.boxScreen (x,			y,		1,		h,		0xFFFFFFFF) -- Left
		graphX.boxScreen (x+w,		y,		1,		h,		0xFFFFFFFF) -- Right
		
	end

	function textblox.drawMenuBox (x,y,w,h, col)
		-- Fill
		graphX.boxScreen (x,y,w,h, col)		
				
		-- Border
		textblox.drawMenuBorder (x,y,w,h)
	end
end	
	
	
	
return textblox