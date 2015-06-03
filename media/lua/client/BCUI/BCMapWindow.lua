require "ISUI/ISCollapsableWindow"

local bcUtils = {};
bcUtils.dump = function(o, lvl) -- {{{ Small function to dump an object.
  if lvl == nil then lvl = 5 end
  if lvl < 0 then return "SO ("..tostring(o)..")" end

  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if k == "prev" or k == "next" then
        s = s .. '['..k..'] = '..tostring(v);
      else
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. bcUtils.dump(v, lvl - 1) .. ',\n'
      end
    end
    return s .. '}\n'
  else
    return tostring(o)
  end
end
-- }}}
bcUtils.pline = function (text) -- {{{ Print text to logfile
  print(tostring(text));
end
-- }}}
bcUtils.isStove = function(o) -- {{{
	if not o then return false end;
	return instanceof(o, "IsoStove");
end
-- }}}
bcUtils.isWindow = function(o) -- {{{
	if not o then return false end;
	return instanceof(o, "IsoWindow");
end
-- }}}
bcUtils.isDoor = function(o) -- {{{
	if not o then return false end;
	return (instanceof(o, "IsoDoor") or (instanceof(o, "IsoThumpable") and o:isDoor()))
end
-- }}}
bcUtils.isTree = function(o) -- {{{
	if not o then return false end;
	return instanceof(o, "IsoTree");
end
-- }}}
bcUtils.isContainer = function(o) -- {{{
	if not o then return false end;
	return o:getContainer();
end
-- }}}

BCMapWindow = ISCollapsableWindow:derive("BCMapWindow");

function BCMapWindow:onMapMouseDown(x, y)--{{{
	self.panning = true;
	self.panx = 0;
	self.pany = 0;
	return true;
end
--}}}
function BCMapWindow:onMapMouseUp(x, y)--{{{
	self.panning = false;
	return true;
end
--}}}
function BCMapWindow:onMapMouseMove(dx, dy)--{{{
	if self.panning then
		self.panx = self.panx + dx;
		self.pany = self.pany + dy;
		bcUtils.pline("Current pan: "..self.panx.."x"..self.pany);
		if math.abs(self.panx) > math.floor(64 / self.parent.zoom) then
			bcUtils.pline("self.parent.x = "..self.parent.x.." + (("..self.panx..")/math.floor(64 / "..self.parent.zoom.."))");
			self.parent.x = self.parent.x - math.floor((self.panx)/math.floor(64 / self.parent.zoom));
			self.panx = self.panx % math.floor(64 / self.parent.zoom);
		end
		if math.abs(self.pany) > math.floor(64 / self.parent.zoom) then
			bcUtils.pline("self.parent.y = "..self.parent.y.." + (("..self.pany..")/math.floor(64 / "..self.parent.zoom.."))");
			self.parent.y = self.parent.y - math.floor((self.pany)/math.floor(64 / self.parent.zoom));
			self.pany = self.pany % math.floor(64 / self.parent.zoom);
		end
	end
	return true;
end
--}}}
function BCMapWindow:onMapRightMouseDown(x, y)--{{{
	self.panning = true;
	self.panx = 0;
	self.pany = 0;
	return true;
end
--}}}
function BCMapWindow:onMapRightMouseUp(x, y)--{{{
	self.panning = false;
	return true;
end
--}}}
function BCMapWindow:onMapMouseWheel(del)--{{{
	if (del > 0) then
		self.parent.zoom = math.min(8, self.parent.zoom + 1);
	else
		self.parent.zoom = math.max(1, self.parent.zoom - 1);
	end
	return true;
end
--}}}

function BCMapWindow:initialise() -- {{{
	ISCollapsableWindow.initialise(self);
	self.title = "Map booklet";
end
-- }}}
function BCMapWindow:createChildren() -- {{{
	ISCollapsableWindow.createChildren(self);

	self.renderPanel = ISPanel:new(100, 16, self.width-100, self.height-32);
	self.renderPanel.render = BCMapWindow.renderMap;
	self.renderPanel.parent = self;
	self.renderPanel:initialise();
	self.renderPanel:setAnchorRight(true);
	self.renderPanel:setAnchorBottom(true);
	self.renderPanel.onMouseWheel = BCMapWindow.onMapMouseWheel;
	self.renderPanel.onMouseUp = BCMapWindow.onMapMouseUp;
	self.renderPanel.onMouseUpOutside = BCMapWindow.onMapMouseUp;
	self.renderPanel.onMouseDown = BCMapWindow.onMapMouseDown;
	self.renderPanel.onRightMouseUp = BCMapWindow.onMapRightMouseUp;
	self.renderPanel.onRightMouseUpOutside = BCMapWindow.onMapRightMouseUp;
	self.renderPanel.onRightMouseDown = BCMapWindow.onMapRightMouseDown;
	self.renderPanel.onMouseMove = BCMapWindow.onMapMouseMove;
	self.renderPanel.onMouseMoveOutside = BCMapWindow.onMapMouseMove;
	self:addChild(self.renderPanel);

	self.drawMapButton = ISButton:new(1, 16, 98, 32, "Draw map", self, self.drawMap);
	self.drawMapButton:initialise();
	self.drawMapButton:setAnchorLeft(true);
	self.drawMapButton:setAnchorTop(true);
	self:addChild(self.drawMapButton);

	self.zoomOutButton = ISButton:new(1, 48, 98, 32, "Zoom -", self, self.zoomOut);
	self.zoomOutButton:initialise();
	self.zoomOutButton:setAnchorLeft(true);
	self.zoomOutButton:setAnchorTop(true);
	self:addChild(self.zoomOutButton);

	self.zoomInButton = ISButton:new(1, 80, 98, 32, "Zoom +", self, self.zoomIn);
	self.zoomInButton:initialise();
	self.zoomInButton:setAnchorLeft(true);
	self.zoomInButton:setAnchorTop(true);
	self:addChild(self.zoomInButton);

end
-- }}}
function BCMapWindow:drawMap() -- {{{
	local player   = getSpecificPlayer(0);
	local cell     = getCell();
	local chunkMap = cell:getChunkMap(0);
	local xPlayer  = math.floor(player:getX());
	local yPlayer  = math.floor(player:getY());
	local range    = 10 --[[ * (1+player:getTrait(Trait.Cartographer)) ]];
	local locKnown = false; -- player does NOT know where on the map s/he is

	if not self.data then
		self.data = {}
		locKnown = true; -- unless this is the first draw of the map
	end

	if self.data[xPlayer] then
		if self.data[xPlayer][yPlayer] then
			locKnown = true; -- or the player has already drawn this part of the map
		end
	end

	if not locKnown then
		player:Say("I don't know where I am...");
		return
	else
		self.x = xPlayer;
		self.y = yPlayer;
	end

	for x=xPlayer-range,xPlayer+range do
		if not self.data[x] then self.data[x] = {}; end
		for y=yPlayer-range,yPlayer+range do
			local sq = cell:getGridSquare(x, y, 0);
			local canSee = sq:isCanSee(0);

			if sq and canSee then
				if not self.data[x][y] then self.data[x][y] = {}; end
				-- self.data[xMin][yMin][x][y].collideN = sq:getProperties():Is(IsoFlagType.collideN);
				-- self.data[xMin][yMin][x][y].collideW = sq:getProperties():Is(IsoFlagType.collideW);
				local nsq;
				nsq = cell:getGridSquare(x, y-1, 0);
				self.data[x][y].collideN = sq:isBlockedTo(nsq) or sq:isDoorTo(nsq);
				nsq = cell:getGridSquare(x, y+1, 0);
				self.data[x][y].collideS = sq:isBlockedTo(nsq) or sq:isDoorTo(nsq);
				nsq = cell:getGridSquare(x-1, y, 0);
				self.data[x][y].collideW = sq:isBlockedTo(nsq) or sq:isDoorTo(nsq);
				nsq = cell:getGridSquare(x+1, y, 0);
				self.data[x][y].collideE = sq:isBlockedTo(nsq) or sq:isDoorTo(nsq);

				local objects = sq:getObjects();
				for k=0,objects:size()-1 do
					local it = objects:get(k);
					if bcUtils.isStove(it) then
						print(x.."x"..y..": Stove")
						self.data[x][y].draw = "stove";
					elseif bcUtils.isWindow(it) then
						print(x.."x"..y..": Window")
						self.data[x][y].draw = "window";
					elseif bcUtils.isDoor(it) then
						print(x.."x"..y..": Door")
						self.data[x][y].draw = "door";
						if it.north then
							self.data[x][y].collideN = true;
						else
							self.data[x][y].collideW = true;
						end
					elseif bcUtils.isTree(it) then
						print(x.."x"..y..": Tree")
						self.data[x][y].draw = "tree";
					elseif bcUtils.isContainer(it) then
						print(x.."x"..y..": Container: "..tostring(it:getContainer():getType()))
						self.data[x][y].draw = "container";
						self.data[x][y].desc = tostring(it:getContainer():getType());
					else
						--print(x.."x"..y..": Item #"..(k+1)..": "..tostring(it:getName()).."/"..tostring(it:getTextureName()));
						self.data[x][y].draw = "unknown";
					end
				end
			end
		end
	end
end
-- }}}
function BCMapWindow:zoomOut() -- {{{
	self:changeZoom(1);
end
-- }}}
function BCMapWindow:zoomIn() -- {{{
	self:changeZoom(-1);
end
-- }}}
function BCMapWindow:changeZoom(change) -- {{{
	if not self.zoom then
		self.zoom = 1 + change;
	else
		self.zoom = self.zoom + change;
	end
	self.zoom = math.max(self.zoom, 1);
	self.zoom = math.min(self.zoom, 8);
end
-- }}}

function BCMapWindow:grabInfo() -- {{{
	if not self.data then self.data = {} end

	local cell     = getCell(); --self.parent.cell;
	local chunkMap = cell:getChunkMap(0);
	local xMin     = chunkMap:getWorldXMinTiles();
	local yMin     = chunkMap:getWorldYMinTiles();

	if not self.data[xMin]       then self.data[xMin]       = {} end
	if not self.data[xMin][yMin] then self.data[xMin][yMin] = {} end
	if not self.data[xMin][yMin].known then
		self.data[xMin][yMin].known = true;
		for x=0,cell:getWidthInTiles()-1 do
			self.data[xMin][yMin][x] = {};
			for y=0,cell:getHeightInTiles()-1 do
				local sq = cell:getGridSquare(xMin + x, yMin + y, 0);
				self.data[xMin][yMin][x][y] = {};
				if sq then
					self.data[xMin][yMin][x][y].collideN = sq:getProperties():Is(IsoFlagType.collideN);
					self.data[xMin][yMin][x][y].collideW = sq:getProperties():Is(IsoFlagType.collideW);

					--[[
					local objects = sq:getObjects();
					for i=0,objects:size()-1 do
						local it = objects:get(i);
						print((x+xMin).."x"..(y+yMin)..": Item #"..(i+1)..": "..tostring(it:getName()).."/"..tostring(it:getTextureName()));
					end
					--]]
					local objects = sq:getObjects();
					for k=0,objects:size()-1 do
						local it = objects:get(k);
						if bcUtils.isStove(it) then
							print((x+xMin).."x"..(y+yMin)..": Stove")
						elseif bcUtils.isWindow(it) then
							print((x+xMin).."x"..(y+yMin)..": Window")
						elseif bcUtils.isDoor(it) then
							print((x+xMin).."x"..(y+yMin)..": Door")
						elseif bcUtils.isTree(it) then
							print((x+xMin).."x"..(y+yMin)..": Tree")
						-- elseif bcUtils.isContainer(it) then
							-- print((x+xMin).."x"..(y+yMin)..": Container: "..tostring(it:getContainer():getType()))
						-- else
							-- print((x+xMin).."x"..(y+yMin)..": Item #"..(k+1)..": "..tostring(it:getName()).."/"..tostring(it:getTextureName()));
						end
					end
				end
			end
		end
	end
end
-- }}}

function BCMapWindow:renderMap() -- {{{
	-- self:setStencilRect(0,0,self:getWidth(), self:getHeight());

	-- self.parent:grabInfo();
	local data = self.parent.data;
	if not data then return end;

	-- local player = getSpecificPlayer(0);
	-- local xPlayer = math.floor(player:getX());
	-- local yPlayer = math.floor(player:getY());
	local xPlayer = self.parent.x;
	local yPlayer = self.parent.y;
	local range = 10 --[[ * self.parent.zoom ]];
	-- local rW = math.floor(math.min(self.width, self.height) / (range * 2 + 1));
	local rW = 64 / self.parent.zoom;
	local rH = rW; -- math.min(self.width, self.height) / (range * 2);
	local xRange = math.floor(self.width/rW);
	local yRange = math.floor(self.height/rH);

	--[[
	for x=0,self.width,rW*2 do
		self:drawRectBorder(x, 0, rW, self.height-(self.height % rH), 1.0, 0.8, 0.8, 0.8);
	end
	for y=0,self.height,rH*2 do
		self:drawRectBorder(0, y, self.width-(self.width % rW), rH, 1.0, 0.8, 0.8, 0.8);
	end
	self:drawRectBorder(0, 0, self.width-(self.width % rW), self.height-(self.height % rH), 1.0, 0.8, 0.8, 0.8);
	--]]

	x = xPlayer - math.floor(xRange / 2);
	y = yPlayer - math.floor(yRange / 2);

	local gx = 0;
	for x=xPlayer - math.floor(xRange / 2),xPlayer + math.floor(xRange / 2) - 1 do
		if data[x] then
			local gy = 0;
			for y=yPlayer - math.floor(yRange / 2),yPlayer + math.floor(yRange / 2) - 1 do
				if data[x][y] then

					self:drawRectBorder(rW * gx, rH * gy, rW, rH, 1.0, 0.8, 0.8, 0.8);

					if data[x][y].collideN then
						self:drawRect(rW * gx, rH * gy, rW, 4, 1.0, 0.9, 0.163, 0.064);
					end
					if data[x][y].collideS then
						self:drawRect(rW * gx, rH * (gy+1), rW, 4, 1.0, 0.9, 0.163, 0.064);
					end
					if data[x][y].collideW then
						self:drawRect(rW * gx, rH * gy, 4, rH, 1.0, 0.9, 0.163, 0.064);
					end
					if data[x][y].collideE then
						self:drawRect(rW * (gx+1), rH * gy, 4, rH, 1.0, 0.9, 0.163, 0.064);
					end
					if data[x][y].desc then
						local offy = getTextManager():MeasureStringY(UIFont.Small, data[x][y].desc);
						self:drawText(data[x][y].desc, rW*gx, rH * (gy + 1) - (offy + 2), 0.9, 0.863, 0.964, 1.0, UIFont.Small);
					end

				end
				gy = gy + 1;
			end
		end
		gx = gx + 1;
	end

	-- self:clearStencilRect();
end
-- }}}

function BCMapWindow:new (x, y, width, height)
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0.7};
	o.x = 0;
	o.y = 0;
	o.zoom = 1;

	return o
end

function BCMapModCreateWindow()
	print("Creating BCMapWindow");
	local m = BCMapWindow:new(50, 50, getCore():getScreenWidth() - 100, getCore():getScreenHeight() - 100);
	m:setVisible(true);
	m:addToUIManager();
end

Events.OnGameStart.Add(BCMapModCreateWindow);
