--***************************************************************************************
--                                                                                      *
-- 	textblox.lua																		*
--  v1.0.0a                                                      						*
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
		local markupMode = false
		local i = 1
		local totalShownChars = 0
		
		
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
				markupMode = true
				
				-- Line break
				if  text:sub (i, i+2) == '<br'  then 
					lineBreaks = lineBreaks + 1
					charsOnLine = 0
					i = i + 2

					
				-- Toggle shake mode
				elseif  text:sub (i, i+7) == '<tremble'  	then
					shakeMode = true
				
				-- Turn off shake mode
				elseif  text:sub (i, i+8) == '</tremble'  	then
					shakeMode = false
				
				-- Toggle wave mode
				elseif  text:sub (i, i+4) == '<wave'  		then
					waveMode = true
				
				-- Turn off wave mode
				elseif  text:sub (i, i+5) == '</wave'  		then
					waveMode = false
				end


			elseif  thisChar == ">"  then
				markupMode = false
				continue = true
			end
				
				
			-- Display the current character				
			if  continue == false  and  markupMode == false  then				
				
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
				end
			
				charsOnLine = charsOnLine + 1
				totalShownChars = totalShownChars + 1
			end
			
			
			-- Increment i
			i = i+1
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
		
		thisTextBlock.charsShown = 1
		if (thisTextBlock.speed <= 0) then
			thisTextBlock.charsShown = thisTextBlock.length
		end
		
		table.insert(textBlockRegister, thisTextBlock)
		
		return thisTextBlock
	end

	
	function TextBlock:getTextWrapped ()
		local numCharsPerLine = math.floor((self.width)/self.font.charWidth) + 3
		local wrappedText = textblox.formatDialogForWrapping (self.text, numCharsPerLine)
		return wrappedText
	end
	
	
	function TextBlock:draw ()
		-- Draw box
		textblox.drawMenuBox (self.x - self.xMargin, self.y - self.yMargin, self.width + 2*self.xMargin, self.height + 2*self.yMargin)
	
		-- Display text
		local textToShow = string.sub(self:getTextWrapped (), 1, self.charsShown)
		--local wrappedText = textToShow
		
		textblox.print (textToShow, self.x, self.y, self.font, self.width)
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
		self.pauseFrames = self.pauseFrames - 1
	
		if 	self.charsShown >= self:getLength ()  then
			self.charsShown = self:getLength ()
		end
		
		if 	self.charsShown < self:getLength ()  and  self.pauseFrames <= 0  then
			self.charsShown = self.charsShown + self.speed
		end
	end

	
	
	function textblox.formatDialogForWrapping (str,chars)
		local tl = str;
		local hd = "";
		local i = 1;
		while (string.len(tl)>chars) do
			local split = textblox.wrapString(tl,chars);
			split.hd = split.hd:gsub("^%s*", "")
			split.tl = split.tl:gsub("^%s*", "")
			local c = chars;
			if(i > 1) then c = (chars+1); end
			if (string.len(split.hd) < c) then
				split.hd = split.hd.."<br>";
			end
			hd = hd..split.hd;
			tl = split.tl;
			i = i + 1;
		end
		return hd..tl;
	end
	
	function textblox.wrapString (str, l)
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