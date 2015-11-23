--graphX.lua 
--v0.3a
--Pretty blatantly based on colliders.lua by Hoeloe

local graphX = {}
local vectr = loadSharedAPI ("vectr")

	graphX.resourcePath = "..\\..\\..\\LuaScriptsLib\\graphX\\"

	graphX.imageWidths = {}
	graphX.imageHeights = {}
	
	
	local function getScreenBounds()
		local h = (player:mem(0xD0, FIELD_DFLOAT));
		local b = { left = player.x-400+player.speedX, right = player.x+400+player.speedX, top = player.y-260+player.speedY, bottom = player.y+340+player.speedY };
		
		local sect = Section(player.section);
		local bounds = sect.boundary;

		if(b.left < bounds.left - 10) then
			b.left = bounds.left - 10;
			b.right = b.left + 800;
		end
		
		if(b.right > bounds.right - 10) then
			b.right = bounds.right - 10;
			b.left = b.right - 800;
		end
		
		if(b.top < bounds.top+40-h) then
			b.top = bounds.top+40-h;
			b.bottom = b.top + 600;
		end
		
		if(b.bottom > bounds.bottom+40-h) then
			b.bottom = bounds.bottom+40-h;
			b.top = b.bottom - 600;
		end
		
		return b;
		
	end

	function graphX.worldToScreen(x,y)
		local b = getScreenBounds();
		local x1 = x-b.left;
		local y1 = y-b.top-(player:mem(0xD0, FIELD_DFLOAT))+30;
		return x1,y1;
	end
	
	
	function graphX.boxLevel (x,y,w,h, col, tex)
		local x1,y1 = graphX.worldToScreen (x, y);
		graphX.boxScreen (x1,y1,w,h, col, tex)
	end
	
	function graphX.boxScreen (x,y,w,h, col, tex)
		col = col or 0xFFFFFFFF; --0xFF000099;
		Graphics.glSetTextureRGBA (tex, col);
		
		local pts = {};
		local x1,y1 = x,y;
		pts[0] = x1; 	pts[1] = y1;
		pts[2] = x1+w;	pts[3] = y1;
		pts[4] = x1;	pts[5] = y1+h;
		pts[6] = x1;	pts[7] = y1+h;
		pts[8] = x1+w;	pts[9] = y1+h;
		pts[10] = x1+w; pts[11] = y1;

		local texpts = {};
		texpts[0] = 0.0; 	texpts[1] = 0.0;
		texpts[2] = 1.0;	texpts[3] = 0.0;
		texpts[4] = 0.0;	texpts[5] = 1.0;
		texpts[6] = 0.0;	texpts[7] = 1.0;
		texpts[8] = 1.0;	texpts[9] = 1.0;
		texpts[10] = 1.0; 	texpts[11] = 0.0;

		
		Graphics.glDrawTriangles (pts, texpts, 6);
		Graphics.glSetTextureRGBA (nil, 0xFFFFFFFF);
	end

	
	
	function graphX.boxLevelExt (x,y,w,h, properties)
		local x1,y1 = graphX.worldToScreen (x, y);
		graphX.boxScreenExt (x1,y1,w,h, properties)
	end
	
	function graphX.boxScreenExt (x,y,w,h, properties)			
		local x1,y1 = x,y;
		local pts = {};
		pts[1] = x1; 	pts[2] = y1;
		pts[3] = x1+w;	pts[4] = y1;
		pts[5] = x1;	pts[6] = y1+h;
		pts[7] = x1;	pts[8] = y1+h;
		pts[9] = x1+w;	pts[10] = y1+h;
		pts[11] = x1+w; pts[12] = y1;
		
		graphX.polyExt (pts, properties)
	end
	
	
	
	function graphX.quadLevelExt (points, properties)
		for i=1, #points, 2 do 
			local x1,y1 = graphX.worldToScreen (points[i], points[i+1]);
			points[i],points[i+1] = x1,y1
		end

		graphX.quadScreenExt (points, properties)
	end
	
	function graphX.quadScreenExt (points, properties)
		local x1,x2,x3,x4 = points[1],points[3],points[5],points[7];
		local y1,y2,y3,y4 = points[2],points[4],points[6],points[8];
		
		local pts = {};
		pts[1] = x1; 	pts[2] = y1;
		pts[3] = x2;	pts[4] = y2;
		pts[5] = x3;	pts[6] = y3;
		pts[7] = x3;	pts[8] = y3;
		pts[9] = x4;	pts[10] = y4;
		pts[11] = x1;	pts[12] = y1;
		
		graphX.polyExt (pts, properties)
	end
	
	
	
	function graphX.polyExt (points, properties)
		
		-- Get properties
		local uAdd, vAdd = 0,0
		local tile = false
		local col = 0xFFFFFFFF
		local tex = nil
		local texAngle = 0
		local texScaleX = 1
		local texScaleY = 1
		
		if  properties ~= nil  then
			uAdd = properties["u"] or 0
			vAdd = properties["v"] or 0
			tex = properties["tex"]
			texAngle = properties["texAngle"] or 0
			texScaleX = properties["texScaleX"] or properties["texScale"] or 1
			texScaleY = properties["texScaleY"] or properties["texScale"] or 1
			
			col = properties["color"] or 0xFFFFFFFF
			tile = properties["tile"]
			
			if  tile == nil  then
				tile = false
			end			
		end
		
		
		-- Get UV bounds
		Graphics.glSetTextureRGBA (tex, col);
		local x1,x2,y1,y2 = points[1],points[1],points[2],points[2];
		
		for i=1, #points, 2 do 
			-- Left- and rightmost
			if  points[i] < x1  then 
				x1 = points[i]
			end
			if  points[i] > x2  then 
				x2 = points[i]
			end
			
			-- Top- and bottommost
			if  points[i+1] < y1  then 
				y1 = points[i+1]
			end
			if  points[i+1] > y2  then 
				y2 = points[i+1]
			end
		end
		
		
		-- Calculate texture positioning
		local shapeW,shapeH = x2-x1, y2-y1;
		local xMid,yMid = (x1+x2)*0.5, (y1+y2)*0.5;
		
		local pixels = {};
		local texW,texH = 2,2;
		if   tex ~= nil  then
			if  graphX.imageWidths[tex] == nil  then
				pixels,texW,texH = Graphics.getPixelData(tex);
				graphX.imageWidths[tex] = texW
				graphX.imageHeights[tex] = texH
			else
				texW,texH = graphX.imageWidths[tex],graphX.imageHeights[tex]
			end
		end

		local texL,texR,texT,texB = x1,x2,y1,y2;
		
		
		if  tile == false  then
			texW,texH = shapeW, shapeH;		
		end
		
		texW,texH = texW*texScaleX, texH*texScaleY;
		
		
		texL = xMid - texW*(0.5)--+uAdd);
		texR = texL+texW;
		texT = yMid - texH*(0.5)--+vAdd);
		texB = texT+texH;
		
		if  texW == 0  or  texH == 0  then
			return
		end
		
		
		-- Calculate rotation
		local angleAdd = (texAngle) * (math.pi/180);
		local cosMult, sinMult = math.cos(angleAdd), math.sin(angleAdd)
		
		-- Determine UVs
		local uvs = {}
		for i=1, (#points), 2  do
			local rotX = xMid + cosMult * (points[i] - xMid) - sinMult * (points[i+1] - yMid);
			local rotY = yMid + sinMult * (points[i] - xMid) + cosMult * (points[i+1] - yMid);
			
			local newU, newV = invLerp (texL,texR, rotX), invLerp (texT,texB, rotY);
			
			uvs[i] = newU;
			uvs[i+1] = newV;
			
			--Text.print (string.format("%.2f", uvs[i])..", "..string.format("%.2f", uvs[i+1]), 4, 8, 120+10*i)
		end
		

		-- Draw the poly
		Graphics.glDrawTriangles (points, uvs, (#points + 1)/2);
		Graphics.glSetTextureRGBA (nil, 0xFFFFFFFF);
	end

	
	
	function graphX.circleLevel (x,y,r, col)
		local x1,y1 = graphX.worldToScreen (x, y);
		graphX.circleScreen (x1,y1,r, col)
	end
	
	function graphX.circleScreen (x,y,r, col)
		col = col or 0xFF000099;
		Graphics.glSetTextureRGBA (nil, col);
		
		local pts = circleToTris(x,y,r);
		
		Graphics.glDrawTriangles (pts, {}, (#pts + 1)/2);
		Graphics.glSetTextureRGBA (nil, 0xFFFFFFFF);
	end
		

	function circleToTris(x,y,r)
		local x1 = x
		local y1 = y;
		local pts = {};
		local m = math.ceil(math.sqrt(r));
		if(m < 1) then m = 1; end
		local s = (math.pi/2)/m;
		local ind = 0;
		local xmult = 1;
		local ymult = -1;
		for n=1,4 do
			local lx = 0;
			local ly = 1;
			for i=1,m do
				local xs = math.cos((math.pi/2)-s*i);
				local ys = math.sin((math.pi/2)-s*i);
				pts[ind] = x1;
				pts[ind+1] = y1;
				pts[ind+2] = x1+xmult*r*lx;
				pts[ind+3] = y1+ymult*r*ly;
				pts[ind+4] = x1+xmult*r*xs;
				pts[ind+5] = y1+ymult*r*ys;
				ind = ind+6;
				lx = xs;
				ly = ys;
			end
			if xmult == 1 then
				if ymult == -1 then
					ymult = 1;
				elseif ymult == 1 then
					xmult = -1;
				end
			elseif xmult == -1 then
				if ymult == -1 then
					xmult = 1;
				elseif ymult == 1 then
					ymult = -1;
				end
			end
		end
		return pts;
	end

	
	
	graphX.MENU_FILL = Graphics.loadImage(graphX.resourcePath.."menuFillA.png")
	graphX.BORDER_UL = Graphics.loadImage(graphX.resourcePath.."menuBorderUL.png")
	graphX.BORDER_UR = Graphics.loadImage(graphX.resourcePath.."menuBorderUR.png")
	graphX.BORDER_DL = Graphics.loadImage(graphX.resourcePath.."menuBorderDL.png")
	graphX.BORDER_DR = Graphics.loadImage(graphX.resourcePath.."menuBorderDR.png")
	graphX.BORDER_U = Graphics.loadImage(graphX.resourcePath.."menuBorderU.png")
	graphX.BORDER_D = Graphics.loadImage(graphX.resourcePath.."menuBorderD.png")
	graphX.BORDER_L = Graphics.loadImage(graphX.resourcePath.."menuBorderL.png")
	graphX.BORDER_R = Graphics.loadImage(graphX.resourcePath.."menuBorderR.png")

	
	function graphX.menuBoxLevel (x,y,w,h, col, fillTex, borderTable)
		local x1,y1 = graphX.worldToScreen (x, y);
		graphX.menuBoxScreen (x1,y1,w,h, col, fillTex, borderTable)
	end
	
	function graphX.menuBoxScreen (x,y,w,h, col, fillTex, borderTable)
		local texImg = tex or graphX.MENU_FILL
		
		local x1 = math.min(x,x+w)
		local y1 = math.min(y,y+h)
		
		-- Fill
		graphX.boxScreen (x1,y1,math.abs(w),math.abs(h), col, texImg)
					
		-- Border
		graphX.menuBorderScreen (x,y,w,h, borderTable)
	end


	function graphX.menuBorderLevel (x,y,w,h, borderTable)
		local x1,y1 = graphX.worldToScreen (x, y);
		graphX.menuBorderScreen (x1,y1,w,h, borderTable)
	end
	
	function graphX.menuBorderScreen (x,y,w,h, borderTable)
					
		-- Border
		drawMenuBorder (x,y,w,h, borderTable)
	end

	

	function drawMenuBorder (x,y,w,h, borderTable)

		if borderTable == nil  then
			borderTable = {}
		end
	
		local ulImg = borderTable["ulImg"] or graphX.BORDER_UL
		local uImg = borderTable["uImg"] or graphX.BORDER_U
		local urImg = borderTable["urImg"] or graphX.BORDER_UR
		local rImg = borderTable["rImg"] or graphX.BORDER_R
		local drImg = borderTable["drImg"] or graphX.BORDER_DR
		local dImg = borderTable["dImg"] or graphX.BORDER_D
		local dlImg = borderTable["dlImg"] or graphX.BORDER_DL
		local lImg = borderTable["lImg"] or graphX.BORDER_L

		local th = borderTable["thick"] or 4
		
		local x1 = math.min(x,x+w)-th
		local x2 = x
		local x3 = math.max(x,x+w)
		local x4 = x3+th

		local y1 = math.min(y,y+h)-th
		local y2 = y
		local y3 = math.max(y,y+h)
		local y4 = y3+th
		
		-- Corners
		graphX.boxScreen (x1,y1,th,th, 0xFFFFFFFF, ulImg) -- Upper-left
		graphX.boxScreen (x3,y1,th,th, 0xFFFFFFFF, urImg) -- Upper-right
		graphX.boxScreen (x1,y3,th,th, 0xFFFFFFFF, dlImg) -- Lower-left
		graphX.boxScreen (x3,y3,th,th, 0xFFFFFFFF, drImg) -- Lower-right
		
		-- Edges
		graphX.boxScreen (x1,y2,th,h, 0xFFFFFFFF, lImg) -- Left
		graphX.boxScreen (x2,y1,w,th, 0xFFFFFFFF, uImg) -- Top
		graphX.boxScreen (x3,y2,th,h, 0xFFFFFFFF, rImg) -- Right
		graphX.boxScreen (x2,y3,w,th, 0xFFFFFFFF, dImg) -- Bottom
		
		--[[
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
		]]
	end

	
	--[[
	function graphX.polyScreen(x,y,...)
		local arg = {...};
		
		local p = {x=x, y=y};
		local ts = {};
		
		for _,v in ipairs(arg) do
			if(v[1] == nil or v[2] == nil) then
				error("Invalid polygon definition.", 2);
			end
			if(p.minX == nil or v[1] < p.minX) then
				p.minX = v[1];
			end
			if(p.maxX == nil or v[1] > p.maxX) then
				p.maxX = v[1];
			end
			if(p.minY == nil or v[2] < p.minY) then
				p.minY = v[2];
			end
			if(p.maxY == nil or v[2] > p.maxY) then
				p.maxY = v[2];
			end
		end
		
		local vlist;
		local winding = 0;
		
		--Calculate winding order.
		for k,v in ipairs(arg) do
			local n = k+1;
			local pr = k-1;
			if(n > table.getn(arg)) then n = 1; end
			if(pr <= 0) then pr = table.getn(arg); end
			winding = winding + (v[1]+arg[n][1])*(v[2]-arg[n][2]);
		end
		
		--If winding order is anticlockwise, triangulation will fail, so reverse vertex list in that case.
		if(winding > 0) then
			vlist = {};
			local argn = #arg;
			for k,v in ipairs(arg) do
				vlist[argn - k + 1] = v;
			end
		else 
			vlist = arg;
		end
		
		local trilist = {};
		
		--Repeatedly search for and remove convex triangles (ears) from the polygon (as long as they have no other vertices inside them). When the polygon has only 3 vertices left, stop.
		while(table.getn(vlist) > 3) do
			local count = table.getn(vlist);
			for k,v  in ipairs(vlist) do
				local n = k+1;
				local pr = k-1;
				if(n > table.getn(vlist)) then n = 1; end
				if(pr <= 0) then pr = table.getn(vlist); end
				local lr = v[1] > vlist[pr][1] or v[2] > vlist[pr][2];
				if lr then
					lr = 1;
				else
					lr = -1;
				end
				local left = isLeft(vlist[n], vlist[pr], v);
				if(left > 0) then
					local t = colliders.Tri(0,0,vlist[pr],v,vlist[n]);
					local pointin = false;
					for k2,v2 in ipairs(vlist) do
						if(k2 ~= k and k2 ~= n and k2 ~= pr and testTriPoint(t,v2)) then
							pointin = true;
							break;
						end
					end
					if(not pointin) then
						table.insert(trilist, t);
						table.remove(vlist,k);
						break;
					end
				elseif(left == 0) then
					table.remove(vlist,k);
					break;
				end
			end
			if(table.getn(vlist) == count) then
				error("Polygon is not simple. Please remove any edges that cross over.",2);
			end
		end
		
		--Insert the final triangle to the triangle list.
		table.insert(trilist, colliders.Tri(0,0,vlist[1],vlist[2],vlist[3]));
		
		for k,v in ipairs(trilist) do
			v.x = p.x;
			v.y = p.y;
		end
		
		p.tris = trilist;
		
		p.Rotate = function(obj, angle)
			for k,v in ipairs(obj.tris) do
				v:Rotate(angle);
				if(v.minX < obj.minX) then obj.minX = v.minX; end
				if(v.maxX > obj.maxX) then obj.maxX = v.maxX; end
				if(v.minY < obj.minY) then obj.minY = v.minY; end
				if(v.maxY > obj.maxY) then obj.maxY = v.maxY; end
			end
		end
		
		p.Translate = function(obj, x, y)
			for k,v in ipairs(obj.tris) do
				v:Translate(x,y);
			end
			obj.minX = obj.minX + x;
			obj.maxX = obj.maxX + x;
			obj.minY = obj.minY + y;
			obj.maxY = obj.maxY + y;
		end
		
		p.Scale = function(obj, x, y)
			y = y or x;
			for k,v in ipairs(obj.tris) do
				v:Scale(x,y);
			end
			obj.minX = obj.minX*x;
			obj.maxX = obj.maxX*x;
			obj.minY = obj.minY*y;
			obj.maxY = obj.maxY*y;
		end
		
		p.Draw = function(obj, c)
			c = c or 0x0000FF99;
			for _,v in ipairs(obj.tris) do
				v.x = obj.x;
				v.y = obj.y;
				Graphics.glSetTextureRGBA(nil, c);
				v:Draw(c);
			end
		end
		
		setmetatable(p,createMeta(TYPE_POLY))
		
		return p;
	end
	]]
	
	function graphX.progressBarLevel (x,y,w,h, col, align, amt)
		local x1,y1 = graphX.worldToScreen (x, y);
		graphX.progressBarScreen (x1,y1,w,h, col, align, amt)
	end
	
	function graphX.progressBarScreen (x,y,w,h, col, align, amt)
		if  align == "left"  then
			drawProgressBarLeft (x,y,w,h, col, amt)
		end
		
		if  align == "top"  then
			drawProgressBarTop (x,y,w,h, col, amt)
		end
		
		if  align == "right"  then
			drawProgressBarRight (x,y,w,h, col, amt)
		end
		
		if  align == "bottom"  then
			drawProgressBarBottom (x,y,w,h, col, amt)
		end
	
	end

	
	
	local function drawProgressBarLeft (x,y,w,h, col, amt)		
		-- Fill
		graphX.boxScreen (x,	y,	w*amt,	h,	col)		
				
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)		
	end
	
	local function drawProgressBarRight (x,y,w,h, col, amt)		
		-- Fill
		graphX.boxScreen (x + w*(1-amt),	y,	w*amt,	h,	col)		
				
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)		
	end

	local function drawProgressBarTop (x,y,w,h, col, amt)		
		-- Fill
		graphX.boxScreen (x,	y,	w,	h*amt,	col)		
				
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)		
	end

	local function drawProgressBarBottom (x,y,w,h, col, amt)		
		-- Fill
		graphX.boxScreen (x,	y + h*(1-amt),	w,	h*amt,	col)		
				
		-- Border
		cinematX.drawMenuBorder (x,y,w,h)		
	end
		
	
	
--***************************************************************************************************
--                                                                       		                    *
-- 				MATH																				*
--                                                                                                  *
--***************************************************************************************************
	

	
	function lerp (minVal, maxVal, percentVal)
		return (1-percentVal) * minVal + percentVal*maxVal;
	end
	
	function invLerp (minVal, maxVal, amountVal)			
		return (amountVal-minVal) / (maxVal - minVal)
	end
	
	
	--[[
	-- math.cos and math.sin expect a radian value, and this little function converts degrees to radians
	toRadians = function(degrees)
		return degrees / 180 * math.pi 
	end 
	 
	function rotateVector(point, xMid, yMid, degrees)
		local x = origin.x + ( math.cos(toRadians(degrees)) * (point.x - origin.x) - math.sin(toRadians(degrees)) * (point.y - origin.y) )
		local y = origin.y + ( math.sin(toRadians(degrees)) * (point.x - origin.x) + math.cos(toRadians(degrees)) * (point.y - origin.y) )
		point.x = x
		point.y = y
	end
	--]]
	
	
	function graphX.rotateVector (xMid, yMid, xOff, yOff, angleAdd)
		angleAdd = (angleAdd) * (math.pi/180); -- Convert to radians
	
		local newX = xMid + math.cos(angleAdd) * (xOff - xMid) - math.sin(angleAdd) * (yOff - yMid);
		local newY = yMid + math.sin(angleAdd) * (xOff - xMid) + math.cos(angleAdd) * (yOff - yMid);
 
		return newX,newY
		
	end
	
	
		
return graphX;