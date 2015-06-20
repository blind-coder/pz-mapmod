require "ISUI/ISCollapsableWindow"

-- ISBuildMenu.cheat = true;

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
bcUtils.isPenOrPencil = function(o) -- {{{
	return o:getFullType() == "Base.Pen" or o:getFullType() == "Base.Pencil";
end
-- }}}
bcUtils.isMap = function(o) -- {{{
	return o:getFullType() == "BCMapMod.Map";
end
-- }}}
bcUtils.tableIsEmpty = function(o) -- {{{
	for _,_ in pairs(o) do
		return false
	end
	return true
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
		if math.abs(self.panx) > math.floor(64 / self.parent.zoom) then
			self.parent.x = self.parent.x - math.floor((self.panx)/math.floor(64 / self.parent.zoom));
			self.panx = self.panx % math.floor(64 / self.parent.zoom);
		end
		if math.abs(self.pany) > math.floor(64 / self.parent.zoom) then
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

	self.drawMapButton = ISButton:new(0, 16, 100, 32, "Draw map", self, self.drawMap);
	self.drawMapButton:initialise();
	self.drawMapButton:setAnchorLeft(true);
	self.drawMapButton:setAnchorTop(true);
	self:addChild(self.drawMapButton);

	self.zoomOutButton = ISButton:new(0, 48, 100, 32, "Zoom -", self, self.zoomOut);
	self.zoomOutButton:initialise();
	self.zoomOutButton:setAnchorLeft(true);
	self.zoomOutButton:setAnchorTop(true);
	self:addChild(self.zoomOutButton);

	self.zoomInButton = ISButton:new(0, 80, 100, 32, "Zoom +", self, self.zoomIn);
	self.zoomInButton:initialise();
	self.zoomInButton:setAnchorLeft(true);
	self.zoomInButton:setAnchorTop(true);
	self:addChild(self.zoomInButton);

	self.findLocationButton = ISButton:new(0, 112, 100, 32, "Find Location", self, self.findLocation);
	self.findLocationButton:initialise();
	self.findLocationButton:setAnchorLeft(true);
	self.findLocationButton:setAnchorTop(true);
	self:addChild(self.findLocationButton);

	self.forceDrawButton = ISButton:new(0, self.height-64, 100, 32, "Force draw", self, self.forceDraw);
	self.forceDrawButton:initialise();
	self.forceDrawButton:setAnchorLeft(true);
	self.forceDrawButton:setAnchorTop(true);
	self:addChild(self.forceDrawButton);
end
-- }}}
function BCMapWindow:findLocation() -- {{{
	local player = getSpecificPlayer(0);
	local xPlayer = math.floor(player:getX());
	local yPlayer = math.floor(player:getY());

	if self.locationKnown then
		player:Say("I already know where I am.");
		return;
	end

	local data = BCMapMod.getDataFromModData(self.item);

	-- Check if we know some place close to us
	for x=xPlayer-5,xPlayer+5 do
		if data[x] then
			for y=yPlayer-5,yPlayer+5 do
				if data[x][y] then
					if data[x][y].fake then
						self.locationFake = true;
					else
						self.locationKnown = true; -- the player has already drawn this part of the map
					end
				end
			end
		end
	end
end
-- }}}
function BCMapWindow:forceDraw() -- {{{
	self.drawFakeMap = not self.drawFakeMap;
	if self.drawFakeMap then
		self.forceDrawButton.backgroundColor = {r=0.5, g=0.5, b=0.5, a=1.0};
	else
		self.forceDrawButton.backgroundColor = {r=0, g=0, b=0, a=1.0};
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

function BCMapWindow:drawMap() -- {{{
	local player   = getSpecificPlayer(0);
	local cell     = getCell();
	local chunkMap = cell:getChunkMap(0);
	local xPlayer  = math.floor(player:getX());
	local yPlayer  = math.floor(player:getY());
	local range    = 10 --[[ * (1+player:getTrait(Trait.Cartographer)) ]];

	local data = BCMapMod.getDataFromModData(self.item);

	if bcUtils.tableIsEmpty(data) then -- data is empty
		self.locationKnown = true; -- player doesn't know its location unless this is the first draw of the map
	end

	if not self.locationKnown and not self.locationFake then
		if self.locationFake then
			player:Say("This can't be right...");
		else
			player:Say("I don't know where I am...");
		end
		return
	end

	for x=xPlayer-range,xPlayer+range do
		for y=yPlayer-range,yPlayer+range do
			self:drawSquare(x, y);
		end
	end
end
-- }}}
function BCMapWindow:drawSquare(x, y) -- {{{
	local xOffset = 0;
	local yOffset = 0;
	local x2;
	local y2;
	local data = BCMapMod.getDataFromModData(self.item);
	local cell = getCell();

	if self.drawFakeMap then
		xOffset = self.x - x;
		yOffset = self.y - y;
	else
		self.x = x;
		self.y = y;
	end

	for x2=x-1,x+1 do
		if not data[x2+xOffset] then data[x2+xOffset] = {}; end
		for y2=y-1,y+1 do
			if not data[x2+xOffset][y2+yOffset] then data[x2+xOffset][y2+yOffset] = {}; end
		end
	end
	local sq = cell:getGridSquare(x, y, 0);
	local canSee = sq:isCanSee(0);

	local nsq;
	nsq = cell:getGridSquare(x, y-1, 0);
	if canSee or nsq:isCanSee(0) then
		data[x+xOffset][y+yOffset].collideN = nsq:isBlockedTo(sq) or nsq:isDoorTo(sq);
	end

	nsq = cell:getGridSquare(x, y+1, 0);
	if canSee or nsq:isCanSee(0) then
		data[x+xOffset][y+1+yOffset].collideN = sq:isBlockedTo(nsq) or sq:isDoorTo(nsq);
	end

	nsq = cell:getGridSquare(x-1, y, 0);
	if canSee or nsq:isCanSee(0) then
		data[x+xOffset][y+yOffset].collideW = nsq:isBlockedTo(sq) or nsq:isDoorTo(sq);
	end

	nsq = cell:getGridSquare(x+1, y, 0);
	if canSee or nsq:isCanSee(0) then
		data[x+1+xOffset][y+yOffset].collideW = sq:isBlockedTo(nsq) or sq:isDoorTo(nsq);
	end

	if canSee then
		data[x+xOffset][y+yOffset].seen = true;
		data[x+xOffset][y+yOffset].drawnBy = getSpecificPlayer(0):getForname().." "..getSpecificPlayer(0):getSurname();
		data[x+xOffset][y+yOffset].fake = self.drawFakeMap;

		local objects = sq:getObjects();
		for k=0,objects:size()-1 do
			local it = objects:get(k);
			if bcUtils.isStove(it) then
				print(x.."x"..y..": Stove")
				data[x+xOffset][y+yOffset].draw = "stove";
			elseif bcUtils.isWindow(it) then
				print(x.."x"..y..": Window")
				data[x+xOffset][y+yOffset].draw = "window";
			elseif bcUtils.isDoor(it) then
				print(x.."x"..y..": Door")
				data[x+xOffset][y+yOffset].draw = "door";
				if it.north then
					data[x+xOffset][y+yOffset].collideN = true;
					-- data[x+xOffset][y+yOffset].doorDirection = "north";
				else
					data[x+xOffset][y+yOffset].collideW = true;
					-- data[x+xOffset][y+yOffset].doorDirection = "west";
				end
			elseif bcUtils.isTree(it) then
				print(x.."x"..y..": Tree")
				data[x+xOffset][y+yOffset].draw = "tree";
			elseif bcUtils.isContainer(it) then
				print(x.."x"..y..": Container: "..tostring(it:getContainer():getType()))
				data[x+xOffset][y+yOffset].draw = "container";
				data[x+xOffset][y+yOffset].desc = tostring(it:getContainer():getType());
			else
				--print(x.."x"..y..": Item #"..(k+1)..": "..tostring(it:getName()).."/"..tostring(it:getTextureName()));
				data[x+xOffset][y+yOffset].draw = "unknown";
			end
		end
	end
end
-- }}}

function BCMapWindow:renderMap() -- {{{
	local data = BCMapMod.getDataFromModData(self.parent.item);
	if bcUtils.tableIsEmpty(data) then return end;

	local xPlayer = self.parent.x;
	local yPlayer = self.parent.y;
	local range = 10 --[[ * self.parent.zoom ]];
	local rW = 64 / self.parent.zoom;
	local rH = rW; -- math.min(self.width, self.height) / (range * 2);
	local xRange = math.floor(self.width/rW);
	local yRange = math.floor(self.height/rH);

	x = xPlayer - math.floor(xRange / 2);
	y = yPlayer - math.floor(yRange / 2);

	local gx = 0;
	for x=xPlayer - math.floor(xRange / 2),xPlayer + math.floor(xRange / 2) - 1 do
		if data[x] then
			local gy = 0;
			for y=yPlayer - math.floor(yRange / 2),yPlayer + math.floor(yRange / 2) - 1 do
				if (self.parent.locationKnown or self.parent.drawFakeMap) and x == self.parent.x and y == self.parent.y then
					self:drawRect(rW * gx, rH * gy, rW, rH, 1.0, 0.3, 0, 0);
				end

				if data[x][y] then
					local fake = data[x][y].fake and data[x][y].drawnBy == getSpecificPlayer(0):getForname().." "..getSpecificPlayer(0):getSurname();
					local alpha = 1.0;
					if fake then alpha = 0.5 end

					if data[x][y].seen then
						self:drawRectBorder(rW * gx, rH * gy, rW, rH, alpha, 0.8, 0.8, 0.8);
					end

					if data[x][y].collideN then
						self:drawRect(rW * gx, rH * gy, rW, 4, alpha, 0.9, 0.163, 0.064);
					end
					if data[x][y].collideW then
						self:drawRect(rW * gx, rH * gy, 4, rH, alpha, 0.9, 0.163, 0.064);
					end
					if data[x][y].desc and data[x][y].draw == "container" then
						local offy = getTextManager():MeasureStringY(UIFont.Small, data[x][y].desc);
						self:drawText(data[x][y].desc, rW*gx, rH * (gy + 1) - (offy + 2), 0.9, 0.863, 0.964, alpha, UIFont.Small);
					end

				end
				gy = gy + 1;
			end
		end
		gx = gx + 1;
	end
end
-- }}}

function BCMapWindow:new (x, y, width, height, item) -- {{{
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0.7};
	o.x = 0;
	o.y = 0;
	o.zoom = 1;
	o.locationKnown = false;
	o.locationFake = false;
	o.drawFakeMap = false;
	o.item = item;

	return o
end
-- }}}

BCMapMod = {};

function BCMapMod.createWindow(item) -- {{{
	local m = BCMapWindow:new(50, 50, getCore():getScreenWidth() - 100, getCore():getScreenHeight() - 100, item);
	m:setVisible(true);
	m:addToUIManager();

	BCMapMod.MapWindow = m;
end
-- }}}

function BCMapMod.cheatGetMap(player) -- {{{
	getSpecificPlayer(player):getInventory():AddItem("BCMapMod.Map");
end
-- }}}

function BCMapMod.createInventoryMenu(player, context, items) -- {{{
	item = items[1];
	if not instanceof(item, "InventoryItem") then
		item = item.items[1];
	end
	if item == nil then return end;

	if item:getFullType() == "BCMapMod.Map" then
		context:addOption("Open Map", item, BCMapMod.createWindow);
	else
		context:addOption("Cheat: Get Map", player, BCMapMod.cheatGetMap);
	end
end
-- }}}

function BCMapMod.getDataFromModData(item) -- {{{
	local md = item:getModData();
	if not md["BCMapMod"] then
		md["BCMapMod"] = {};
	end
	return md["BCMapMod"];
end
-- }}}

function BCMapModPlayerMove() -- {{{
	local player = getSpecificPlayer(0);

	if player:IsRunning() then 
		if BCMapMod.MapWindow then
			BCMapMod.MapWindow.locationKnown = false;
		end
		return;
	end -- No drawing maps when you're running around

	local primary = player:getPrimaryHandItem();
	local secondary = player:getSecondaryHandItem();

	if bcUtils:isMap(secondary) then
		swap = primary;
		primary = secondary;
		secondary = swap;
	end

	if bcUtils:isMap(primary) and bcUtils:isPenOrPencil(secondary) then
		primary:drawSurroundings(math.floor(player:getX()), math.floor(player:getY()), (2 --[[ + player:getTrait(Trait.Cartographer) ]]) * 2);
	else
		if BCMapMod.MapWindow then
			BCMapMod.MapWindow.locationKnown = false;
			-- Walking around without looking at the map, you'll get lost
		end
	end
end
-- }}}

-- Events.OnGameStart.Add(BCMapMod.createWindow);
Events.OnFillInventoryObjectContextMenu.Add(BCMapMod.createInventoryMenu);

-- Events.OnPlayerMove.Add(BCMapModPlayerMove);
