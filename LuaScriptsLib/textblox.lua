--***************************************************************************************
--                                                                                      *
-- 	textblox.lua																		*
--  v0.2.0a                                                      						*
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

	
	function Font:drawCharImage (character, x,y, opacity)
		
		local alpha = opacity or 1.00
		local index = string.byte(character,1)-33
		local w = self.charWidth
		local h = self.charHeight
		local sourceX = (index%16) * w
		local sourceY = math.floor(index/16) * h
				
		Graphics.drawImage (self.imageRef, x, y, sourceX, sourceY, w, h, alpha)
	end
	

	function textblox.print (text, x,y, font, halign, valign, width, opacity)
		-- Setup
		local lineBreaks = 0
		local charsOnLine = 0
		local strLength = text:len()
		
		local lineStr = ""
		
		local totalWidth = 1
		local totalHeight = 1
		
		local alpha = opacity or 1.00
		
		local startOfLine = 1
		local currentLineWidth = 0
		local fullLineWidth = 0
		local charEndWidth = 0
		local markupCount = 0
		local i = 1
		local totalShownChars = 0
		
		local t_halign = halign or textblox.HALIGN_LEFT
		local t_valign = valign or textblox.VALIGN_TOP
		
		local lastSpaceX = nil
		local lastSpaceY = nil
		
		
		-- Effects
		local shakeMode = false
		local waveMode = false
		
		
		while (i <= strLength) do 
		
			-- Get character info
			local lastNum = math.max(1, i-1)
			
			local lastChar = text:sub(lastNum, lastNum)
			local thisChar = text:sub(i,i)
			local nextChar = text:sub(i+1,i+1)
			
			local endOfLineA = text:len() - startOfLine
			local endOfLineB = text:len() - i
			local endOfLineC = text:find ("<br", startOfLine)
			local endOfLine = nil
			
			endOfLine = endOfLineC
			
			
			
			local throwawayVar = nil
			local allLineBreaks = nil
			throwawayVar, allLineBreaks  = text:gsub('<br>','<br>')
			
			if  allLineBreaks == nil  then
				allLineBreaks = 1
			end
			
			
			
			local lineStrA = text:sub (startOfLine, endOfLine)
			local lineStrB = lineStrA:gsub ('<.->', '')
			lineStrB = lineStrB:gsub ('<.*','')
			lineStrB = lineStrB:gsub ('.->','')
			
			if  i == strLength  then
				--windowDebug ("CURRENT LINE BREAKS: " .. lineBreaks .. ", ALL LINE BREAKS: " .. allLineBreaks)
				--windowDebug ("START: " .. tostring(startOfLine) .. "\nEND A: " .. tostring(endOfLineA) .. "\nEND B: " .. tostring(endOfLineB)  .. "\nDECIDED END: " .. tostring(endOfLine) .. "\n\n" .. lineStrA .. "\n\n" .. lineStrB)
			end
			
			local continue = false
			
			
			
			-- Get line width info
			fullLineWidth = (lineStrB:len()) * (font.charWidth + font.kerning)
			currentLineWidth = (charsOnLine) * (font.charWidth + font.kerning)
			charEndWidth = (charsOnLine+1) * (font.charWidth + font.kerning)
	
			if 	fullLineWidth > totalWidth  then
				totalWidth = fullLineWidth
			end
			
			totalHeight = (lineBreaks+1)*font.charHeight
			
			
			-- Determine the position based on alignment
			local xPos = nil
			local yPos = nil
			local fullLine = text:match('.*<br>', i)

			
			if		t_halign == textblox.HALIGN_LEFT  then
				xPos = x + currentLineWidth
			
			elseif	t_halign == textblox.HALIGN_RIGHT  then
				xPos = x - fullLineWidth + currentLineWidth -- - font.charWidth
			
			else
				xPos = x - 0.5*(fullLineWidth) + currentLineWidth
			end
			
			
			if		t_valign == textblox.VALIGN_TOP  then
				yPos = y + (lineBreaks*font.charHeight)
			
			elseif	t_valign == textblox.VALIGN_BOTTOM  then
				yPos = y + (lineBreaks - allLineBreaks - 1)*font.charHeight
			
			else
				yPos = y + (lineBreaks*font.charHeight)	- ((allLineBreaks+1)*font.charHeight*0.5)
			end
			
			
			
			-- Process inline commands
			if  thisChar == '<'   then
				
				-- Stop processing the following text
				markupCount = markupCount + 1
				
				-- Line break
				if  text:sub (i, i+2) == '<br'  then 
					startOfLine = endOfLine + 3
					
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
				if  thisChar ~= ' '  and  alpha > 0.0  then
					
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
					font:drawCharImage (thisChar, xAffected, yAffected, alpha)
				
				
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
		
		--windowDebug ("W: " .. tostring(totalWidth) .. ",  H: " .. tostring(totalHeight))
		return totalWidth, totalHeight
	end

end



--***************************************************************************************************
--                                                                                                  *
--              TEXT BLOCK CLASS																    *
--                                                                                                  *
--***************************************************************************************************

do
	textblox.BOXTYPE_NONE = 1
	textblox.BOXTYPE_MENU = 2
	textblox.BOXTYPE_WORDBUBBLE = 3
	textblox.BOXTYPE_CUSTOM = 4
	
	textblox.BIND_SCREEN = 1
	textblox.BIND_LEVEL = 2

	textblox.SCALE_FIXED = 1
	textblox.SCALE_AUTO = 2
	
	textblox.HALIGN_LEFT = 1
	textblox.HALIGN_MID = 2
	textblox.HALIGN_RIGHT = 3
	
	textblox.VALIGN_TOP = 1
	textblox.VALIGN_MID = 2
	textblox.VALIGN_BOTTOM = 3
	
	
	TextBlock = {}
	TextBlock.__index = TextBlock
	
	function TextBlock.create(x,y, textStr, properties)
		
		local thisTextBlock = {}							-- our new object
		setmetatable (thisTextBlock, TextBlock)				-- make TextBlock handle lookup
		
		
		-- Properties
		thisTextBlock.x = x
		thisTextBlock.y = y
		thisTextBlock.text = textStr
		
		thisTextBlock.boxType = properties["boxType"] or textblox.BOXTYPE_MENU
		thisTextBlock.boxTex = properties["boxTex"]
		thisTextBlock.boxColor = properties["boxColor"] or 0x00AA0099 			-- transparent green
		
		thisTextBlock.scaleMode = properties["scaleMode"] or textblox.SCALE_FIXED
		thisTextBlock.width = properties["width"] or 200
		thisTextBlock.height = properties["height"] or 200
		
		thisTextBlock.bind = properties["bind"] or textblox.BIND_SCREEN
		
		thisTextBlock.halign = properties["textAnchorX"] or textblox.HALIGN_LEFT
		thisTextBlock.valign = properties["textAnchorY"] or textblox.VALIGN_TOP
		
		thisTextBlock.textAlpha = properties["textAlpha"] or 1
		
		thisTextBlock.boxhalign = properties["boxAnchorX"] or textblox.HALIGN_LEFT
		thisTextBlock.boxvalign = properties["boxAnchorY"] or textblox.VALIGN_TOP
				
		thisTextBlock.font = properties["font"] or textblox.FONT_DEFAULT
		
		thisTextBlock.speed = properties["speed"] or 0.5
		
		thisTextBlock.xMargin = properties["marginX"] or 4
		thisTextBlock.yMargin = properties["marginY"] or 4

		thisTextBlock.visible = properties["visible"]
		if  thisTextBlock.visible == nil  then
			thisTextBlock.visible = true
		end
		
		
		-- Control vars
		thisTextBlock.pauseFrames = 0
		thisTextBlock.shakeFrames = 0

		thisTextBlock.autoWidth = 1
		thisTextBlock.autoHeight = 1
		
		
		thisTextBlock.filteredText = textStr
		thisTextBlock.length = string.len(textStr)
		
		thisTextBlock.lastCharCounted = nil
		thisTextBlock.charsCounted = 0
		thisTextBlock.charsShown = 0
		if (thisTextBlock.speed <= 0) then
			thisTextBlock.charsShown = thisTextBlock.length
		end
		
		table.insert(textBlockRegister, thisTextBlock)
		
		return thisTextBlock
	end

	
	function TextBlock:getCharsPerLine ()
		local numCharsPerLine = math.floor((self.width)/(self.font.charWidth + self.font.kerning))
		return numCharsPerLine
	end
	
	
	function TextBlock:getTextWrapped (addSlashN)
		if  addSlashN == nil  then
			addSlashN = false
		end
		
		local wrappedText = textblox.formatDialogForWrapping (self.text, self:getCharsPerLine (), addSlashN)
		return wrappedText
	end
	
	
	function TextBlock:draw ()
		-- Get width and height
		local textToShow = string.sub(self:getTextWrapped (), 1, self.charsShown)
		
		
		--self.autoWidth = 4
		--self.autoHeight = 4
		---[[
		self.autoWidth, self.autoHeight = textblox.print   (textToShow, 
															9999, 
															9999,
															self.font,
															self.halign,
															self.valign,
															self.width,
															0.0)
		--]]
		
	
		-- Get shake offset
		local shakeX = math.random (-12, 12) * (self.shakeFrames/8)
		local shakeY = math.random (-12, 12) * (self.shakeFrames/8)		
		
		
		-- Get alignment and width based on scale mode
		local boxAlignX = self.boxhalign
		local boxAlignY = self.boxvalign
		local boxWidth = self.width
		local boxHeight = self.height 
		
		if  self.scaleMode == textblox.SCALE_AUTO  then
			boxAlignX = self.halign
			boxAlignY = self.valign
			boxWidth = self.autoWidth
			boxHeight = self.autoHeight 
			--windowDebug ("TEST\n\n" .. tostring(self.autoWidth) .. "," .. tostring(self.autoHeight))
		end

		--[[
		if  self.autoWidth == nil  then
			boxWidth = 4
		end
		if  self.autoHeight == nil  then
			boxHeight = 4
		end
		--]]
		
		-- Get box positioning based on anchors
		local boxX = nil
		local boxY = nil
		
		if		boxAlignX == textblox.HALIGN_LEFT  then
			boxX = self.x + shakeX
		
		elseif	boxAlignX == textblox.HALIGN_RIGHT  then
			boxX = self.x - boxWidth + shakeX
		
		else
			boxX = self.x - (0.5*boxWidth) + shakeX
		end

		
		if		boxAlignY == textblox.VALIGN_TOP  then
			boxY = self.y + shakeY
		
		elseif	boxAlignY == textblox.VALIGN_BOTTOM  then
			boxY = self.y - boxHeight + shakeY
		
		else
			boxY = self.y - (0.5*boxHeight) + shakeY
		end

		
		
		-- Draw box
		if  self.boxType == textblox.BOXTYPE_MENU  then
			textblox.drawMenuBox   (boxX-self.xMargin,  
									boxY-self.yMargin,
									boxWidth + 2*self.xMargin, 
									boxHeight + 2*self.yMargin,
									self.boxColor)
		end
		

		-- Get text positioning based on anchors
		local textX = nil
		local textY = nil
		
		---[[
		if		self.halign == textblox.HALIGN_LEFT  then
			textX = boxX
		
		elseif	self.halign == textblox.HALIGN_RIGHT  then
			textX = boxX + boxWidth
		
		else
			textX = boxX + 0.5*boxWidth
		end

		
		if		self.valign == textblox.VALIGN_TOP  then
			textY = boxY
		
		elseif	self.valign == textblox.VALIGN_BOTTOM  then
			textY = boxY + boxHeight
		
		else
			textY = boxY + 0.5*boxHeight
		end
		--]]
		

		-- Display text
		self.autoWidth, self.autoHeight = textblox.print   (textToShow, 
															textX, 
															textY,
															self.font,
															self.halign,
															self.valign,
															self.width,
															self.textAlpha)
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
		
		if  self.visible == true  then
			self.autoWidth,self.autoHeight = self:draw ()
		end
	end
	
	
	function TextBlock:updateTiming ()
		self.pauseFrames = math.max(self.pauseFrames - 1, 0)
		self.shakeFrames = math.max(self.shakeFrames - 1, 0)
	
	
		-- Clamp typewriter effect to full text length
		if 	self.charsShown >= self:getLength ()  then
			self.charsShown = self:getLength ()
			
			--windowDebug ("Chars per line: " .. self:getCharsPerLine () .. "\n\n" .. self:getTextWrapped (true))
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
						self.charsShown = self.charsShown - 1
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
	
	
	function textblox.formatDialogForWrapping (text, wrapChars, addSlashN)
		
		-- Setup
		local newString = text
		local strLength = text:len()
		local currentLineWidth = 0
		local markupMode = 0
		
		local oldPos = 1
		local newOffset = 0
		local newOffsetDebug = 0
		
		local lineStart = 1
		local charsOnLine = 0
		local totalShownChars = 0
		
		local currentSpace = 1
		local prevSpace = 1
		local currentSpaceVisChars  = 0
		local prevSpaceVisChars  = 0
		
		local currentDash = 1
		local prevDash = 1
		local currentDashVisChars  = 0
		local prevDashVisChars  = 0
		
		
		while (oldPos <= strLength) do 
		
			-- Get character
			local lastNum = math.max(1, oldPos-1)
			
			local lastChar = text:sub(lastNum, lastNum)
			local thisChar = text:sub(oldPos,oldPos)
			local nextChar = text:sub(oldPos+1, oldPos+1)
			local continue = false
								
			
			-- Wrap words when necessary
			if  charsOnLine > wrapChars  then
			
				
				local firstHalf = nil
				local secondHalf = nil
				local breakPoint = nil
			
			
				-- Add a break command + \n for debugging purposes
				local breakStr = "<br>"
				if  addSlashN == true  then
					breakStr = 	"_\n" 
								.. tostring(prevSpace-lineStart) .. "," .. tostring(currentSpace-lineStart) .. ", " .. tostring(oldPos-lineStart) 
								.. "   " .. tostring(newOffsetDebug) .. ", " .. tostring(oldPos+newOffsetDebug) .. ", " .. tostring(oldPos+newOffsetDebug-lineStart)
								.. "   " .. tostring(prevSpaceVisChars) .. "/" .. tostring(currentSpaceVisChars) .. ", " .. tostring(charsOnLine).. "\n\n"
				end
				
			
				-- If a line break can be inserted between words, do so
				if  currentSpace ~= lineStart  then
					breakPoint = currentSpace
					
					firstHalf = newString:sub (1, breakPoint + newOffset)
					secondHalf = newString:sub (breakPoint + 1 + newOffset, strLength + newOffset)
				
					newString = firstHalf .. breakStr .. secondHalf
					newOffset = newOffset + breakStr:len()
					newOffsetDebug = newOffsetDebug + 4 - 1
				
				
				-- Otherwise, if the word already has a dash, break the line there
				elseif  currentDash ~= lineStart  then
					breakPoint = currentDash

					firstHalf = newString:sub (1, breakPoint + newOffset)
					secondHalf = newString:sub (breakPoint + 1 + newOffset, strLength + newOffset)					
					
					newString = firstHalf .. breakStr .. secondHalf
					newOffset = newOffset + breakStr:len()
					newOffsetDebug = newOffsetDebug + 4
				
				
				-- Otherwise, insert a dash and a break
				else
					breakPoint = oldPos - 3
					
					firstHalf = newString:sub (1, breakPoint + newOffset)
					secondHalf = newString:sub (breakPoint + 1 + newOffset, strLength + newOffset)
					
					newString = firstHalf .. "-" .. breakStr .. secondHalf
					newOffset = newOffset + 1 + breakStr:len()
					newOffsetDebug = newOffsetDebug + 4 + 1			
				end
				
				
				-- Set up new line
				local newLineString = text:sub(breakPoint, oldPos)
				newLineString = newLineString:gsub ('<.*>', '')
				
				newLineChars = newLineString:len()
				
				charsOnLine = newLineChars
				lineStart = oldPos
				
				currentSpace = oldPos
				prevSpace = oldPos
				currentDash = oldPos
				prevDash = oldPos

				currentSpaceVisChars = 0
				prevSpaceVisChars = 0
				currentDashVisChars = 0
				prevDashVisChars = 0
			end

			
			-- Store space position
			if  thisChar == ' '  and  markupMode <= 0   then
				prevSpace = currentSpace
				currentSpace = oldPos
				prevSpaceVisChars = currentSpaceVisChars
				currentSpaceVisChars = charsOnLine
				
			
			-- Store dash position
			elseif  thisChar == '-'  and  markupMode <= 0   then
				prevDash = currentDash
				currentDash = oldPos
				prevSpaceVisChars = currentDashVisChars
				currentDashVisChars = charsOnLine
			
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