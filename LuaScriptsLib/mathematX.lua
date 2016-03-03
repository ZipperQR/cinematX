--***************************************************************************************
--                                                                                      *
--  mathematX.lua                                                                       *
--  v0.2                                                                                *
--                                                                                      *
--***************************************************************************************
 
local mathematX = {}


	function mathematX.dirSign (direction)
		local dirMult = -1
		if direction == DIR_RIGHT then
				dirMult = 1
		end
	   
		return dirMult
	end


	function mathematX.lerp (minVal, maxVal, percentVal)
		return (1-percentVal) * minVal + percentVal*maxVal;
	end


	function mathematX.invLerp (minVal, maxVal, amountVal)                   
		return  math.min(1.00000, math.max(0.0000, math.abs(amountVal-minVal) / math.abs(maxVal - minVal)))
	end


	function mathematX.invLerpUnclamped (minVal, maxVal, amountVal)                   
		return  (amountVal-minVal) / (maxVal - minVal)
	end

	function mathematX.invLerpCycled (minVal, maxVal, amountVal)                   
		local raw = (amountVal-minVal) / (maxVal - minVal)		
		raw = raw%1
		
		return raw
	end
	
	

	function mathematX.magnitude (x,y)
		local vx = x
		local vy = y
	   
		local length = math.sqrt(vx * vx + vy * vy);
		return length
	end


	function mathematX.normalize (x, y)
		local vx = x
		local vy = y
	   
		local length = mathematX.magnitude(x,y);

		-- normalize vector
		vx = vx/length;
		vy = vy/length;

		return vx,vy
	end



	function mathematX.rotateVector (xMid, yMid, xOff, yOff, angleAdd)
		angleAdd = (angleAdd) * (math.pi/180); -- Convert to radians
	
		local newX = xMid + math.cos(angleAdd) * (xOff - xMid) - math.sin(angleAdd) * (yOff - yMid);
		local newY = yMid + math.sin(angleAdd) * (xOff - xMid) + math.cos(angleAdd) * (yOff - yMid);
 
		return newX,newY
		
	end
	



	function mathematX.intToHexString (hexVal)
		return string.format("%X", hexVal)
	end

	function mathematX.hexStringToInt (hexString)
		return tonumber(hexString, 16)
	end

	function mathematX.hexColorToTable (hexVal)
		local stringVal = mathematX.intToHexString (hexVal)
		local r, g, b, a = tonumber("0x"..stringVal:sub(1,2)), tonumber("0x"..stringVal:sub(3,4)), tonumber("0x"..stringVal:sub(5,6)), tonumber("0x"..stringVal:sub(7,8))
		
		return {r/255, g/255, b/255, a/255};
	end

	
return mathematX
