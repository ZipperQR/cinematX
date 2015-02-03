geographX = {}

geographX.levelIndexes = {}
geographX.indexedLevelPaths = {}
geographX.indexedLevelTitles = {}


geographX.numStars = mem(0x00B251E0, FIELD_DWORD)
geographX.levelCreatorStr = "Rockythechao"


cinemResourcePath = "..\\..\\..\\LuaScriptsLib\\cinematX\\"
geographX.resourcePath = "..\\..\\LuaScriptsLib\\geographX\\"


do
	function onLoad ()
		initHUD ()
		indexAllLevels ()
	end

	
	function initHUD ()

		-- Image slot and filename constants
		geographX.IMGSLOT_LEEK_0 				=	999991
		geographX.IMGSLOT_LEEK_1 				=	999990

		
		-- Color code constants
		geographX.COLOR_TRANSPARENT = 0xFFFFFF--0xFB009D
		
		
		-- Filename constants
		geographX.IMGNAME_BLANK	 				=	cinemResourcePath.."blankImage.bmp"
		geographX.IMGNAME_LEEK_0	 			=	geographX.resourcePath.."leek_0.bmp"
		geographX.IMGNAME_LEEK_1	 			=	geographX.resourcePath.."leek_1.bmp"
		
		
		-- Set up icon sprites
		loadImage (geographX.IMGNAME_LEEK_0,  geographX.IMGSLOT_LEEK_0,  geographX.COLOR_TRANSPARENT)
		loadImage (geographX.IMGNAME_LEEK_1,  geographX.IMGSLOT_LEEK_1,  geographX.COLOR_TRANSPARENT)
	end
end



function indexAllLevels ()
	
end


function indexLevel ()
	
end



function onLoop ()
	updateLevelInfo ()
	displayExtraInfo ()
end




function displayExtraInfo ()
end




function updateLevelInfo ()

	if (world.levelTitle ~= nil) then
		printText (geographX.levelCreatorStr, 2, 245, 88)
		
		-- Display level leeks
		local xPos = 0
		local yPos = 88
			
		for i=0,3 do
			xPos = 720 - 16*i
		
			local tempIcon = geographX.IMGSLOT_LEEK_0
			placeSprite (1, tempIcon, xPos, yPos, "", 2)
		end
	end
end