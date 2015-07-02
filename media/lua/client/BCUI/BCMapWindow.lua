require "ISUI/ISCollapsableWindow"

-- ISBuildMenu.cheat = true;
-- ModData used:
-- getModData()["BCMapMod"] = {
--   [x] = { -- xCoordinates of map, absolute
--     [y] = { -- yCoordinates of map, absolute
--       seen = true|false -- tile has been seen
--       drawnBy = <string> -- "forename surname" of drawer, used internally
--       draw = [ -- array of stuff to draw
--         collideN = true|false -- has a wall on the north side
--         collideW = true|false -- has a wall on the west side
--         draw = <string> -- what object to draw at this tile
--         desc = <string> -- description of tile, WIP
--         color = { r = 0..1, g = 0..1, b = 0..1, a = 0..1} -- color to pass to drawTextureScaled
--         street = {
--           left = true|false
--           right = true|false
--           up = true|false
--           down = true|fals   -- whether there's another street tile in
--                                 given direction. WIP
--         }
--       ]
--     }
--   }

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

	--[[self.forceDrawButton = ISButton:new(0, self.height-64, 100, 32, "Force draw", self, self.forceDraw);
	self.forceDrawButton:initialise();
	self.forceDrawButton:setAnchorLeft(true);
	self.forceDrawButton:setAnchorTop(true);
	self:addChild(self.forceDrawButton);
	--]]
end
-- }}}
function BCMapWindow:findLocation() -- {{{
	local player = getSpecificPlayer(0);
	local xPlayer = math.floor(player:getX());
	local yPlayer = math.floor(player:getY());

	if self.locationKnown then
		self.x = xPlayer;
		self.y = yPlayer;
		self.xPlayer = xPlayer;
		self.yPlayer = yPlayer;
		return;
	end

	local data = BCMapMod.getDataFromModData(self.item);

	-- Check if we know some place close to us
	for x=xPlayer-5,xPlayer+5 do
		if data[x] then
			for y=yPlayer-5,yPlayer+5 do
				if data[x][y] then
					self.locationKnown = true; -- the player has already drawn this part of the map
					self.x = xPlayer;
					self.y = yPlayer;
					self.xPlayer = xPlayer;
					self.yPlayer = yPlayer;
					return;
				end
			end
		end
	end

	player:Say("I don't know where I am.");
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

function BCMapWindow:drawMap() --{{{
	BCMapMod.MapWindow:drawSurroundings(10);
end
-- }}}
function BCMapWindow:drawSurroundings(range) -- {{{
	local player   = getSpecificPlayer(0);
	local cell     = getCell();
	local chunkMap = cell:getChunkMap(0);
	local xPlayer  = math.floor(player:getX());
	local yPlayer  = math.floor(player:getY());
	range = range --[[ + (1+player:getTrait(Trait.Cartographer)) ]];

	local data = BCMapMod.getDataFromModData(self.item);

	if bcUtils.tableIsEmpty(data) then -- data is empty
		self.locationKnown = true; -- player doesn't know its location unless this is the first draw of the map
	end

	if not self.locationKnown then
		player:Say("I don't know where I am...");
		return
	end

	for x=xPlayer-range,xPlayer+range do
		for y=yPlayer-range,yPlayer+range do
			if bcUtils.realDist(xPlayer, yPlayer, x, y) <= range then
				self:drawSquare(x, y);
			end
		end
	end

	self.xPlayer = xPlayer;
	self.yPlayer = yPlayer;
end
-- }}}
function BCMapWindow:drawSquare(x, y) -- {{{
	local x2;
	local y2;
	local data = BCMapMod.getDataFromModData(self.item);
	local cell = getCell();

	for x2=x-1,x+1 do
		if not data[x2] then data[x2] = {seen = false, drawnBy = "", draw = {}}; end
		for y2=y-1,y+1 do
			if not data[x2][y2] then data[x2][y2] = {seen = false, drawnBy = "", draw = {}}; end
		end
	end
	local sq = cell:getGridSquare(x, y, 0);
	local canSee = sq:isCanSee(0);

	if canSee then
		data[x][y].seen = true;
		data[x][y].drawnBy = getSpecificPlayer(0):getForname().." "..getSpecificPlayer(0):getSurname();

		local objects = sq:getObjects();
		for k=0,objects:size()-1 do
			local doAdd = false;
			local newDraw = BCMapMod.newDrawElement();
			local it = objects:get(k);
			if bcUtils.isStreet(it) then
				newDraw.draw = "street";
				newDraw.street = {};
				newDraw.street.left = bcUtils.hasStreet(cell:getGridSquare(x-1, y, 0));
				newDraw.street.right = bcUtils.hasStreet(cell:getGridSquare(x+1, y, 0));
				newDraw.street.up = bcUtils.hasStreet(cell:getGridSquare(x-1, y, 0));
				newDraw.street.down = bcUtils.hasStreet(cell:getGridSquare(x+1, y, 0));
				doAdd = true;
			elseif bcUtils.isDirtRoad(it) then
				newDraw.draw = "dirtroad";
				newDraw.street = {};
				newDraw.street.left = bcUtils.hasDirtRoad(cell:getGridSquare(x-1, y, 0));
				newDraw.street.right = bcUtils.hasDirtRoad(cell:getGridSquare(x+1, y, 0));
				newDraw.street.up = bcUtils.hasDirtRoad(cell:getGridSquare(x-1, y, 0));
				newDraw.street.down = bcUtils.hasDirtRoad(cell:getGridSquare(x+1, y, 0));
				doAdd = true;
			elseif bcUtils.isStove(it) then
				newDraw.draw = "stove";
				doAdd = true;
			elseif bcUtils.isWindow(it) then
				newDraw.draw = "window";
				doAdd = true;
			elseif bcUtils.isDoor(it) then
				local nsq = cell:getGridSquare(x, y-1, 0);
				newDraw.draw = "door";
				if sq:isDoorTo(nsq) then
					newDraw.collideN = true;
				else
					newDraw.collideW = true;
				end
				doAdd = true;
			elseif bcUtils.isTree(it) then
				newDraw.draw = "tree";
				doAdd = true;
			elseif bcUtils.isContainer(it) then
				newDraw.draw = "container";
				newDraw.desc = tostring(it:getContainer():getType());
				doAdd = true;
			else
				--print(x.."x"..y..": Item #"..(k+1)..": "..tostring(it:getName()).."/"..tostring(it:getTextureName()));
				newDraw.draw = "unknown";
			end
			if doAdd then
				BCMapMod.insertDrawData(data[x][y].draw, newDraw);
			end
		end
	end

	local nsq;
	nsq = cell:getGridSquare(x, y-1, 0);
	if canSee or nsq:isCanSee(0) then
		if nsq:isBlockedTo(sq) then
			local newDraw = BCMapMod.newDrawElement();
			newDraw.collideN = true;
			newDraw.draw = "wall";
			BCMapMod.insertDrawData(data[x][y].draw, newDraw);
		end
	end

	nsq = cell:getGridSquare(x, y+1, 0);
	if canSee or nsq:isCanSee(0) then
		if sq:isBlockedTo(nsq) then
			local newDraw = BCMapMod.newDrawElement();
			newDraw.collideN = true;
			newDraw.draw = "wall";
			BCMapMod.insertDrawData(data[x][y+1].draw, newDraw);
		end
	end

	nsq = cell:getGridSquare(x-1, y, 0);
	if canSee or nsq:isCanSee(0) then
		if nsq:isBlockedTo(sq) then
			local newDraw = BCMapMod.newDrawElement();
			newDraw.collideW = true;
			newDraw.draw = "wall";
			BCMapMod.insertDrawData(data[x][y].draw, newDraw);
		end
	end

	nsq = cell:getGridSquare(x+1, y, 0);
	if canSee or nsq:isCanSee(0) then
		if sq:isBlockedTo(nsq) then
			local newDraw = BCMapMod.newDrawElement();
			newDraw.collideW = true;
			newDraw.draw = "wall";
			BCMapMod.insertDrawData(data[x+1][y].draw, newDraw);
		end
	end
end
-- }}}
function BCMapWindow:renderMap() -- {{{
	local data = BCMapMod.getDataFromModData(self.parent.item);
	if bcUtils.tableIsEmpty(data) then return end;

	local player   = getSpecificPlayer(0);
	local xPlayer  = math.floor(player:getX());
	local yPlayer  = math.floor(player:getY());
	local range = 10 --[[ * self.parent.zoom ]];
	local rW = 64 / self.parent.zoom;
	local rH = rW; -- math.min(self.width, self.height) / (range * 2);
	local xRange = math.floor(self.width/rW);
	local yRange = math.floor(self.height/rH);

	local gx = 0;
	for x=self.parent.x - math.floor(xRange / 2),self.parent.x + math.floor(xRange / 2) - 1 do
		if data[x] then
			local gy = 0;
			for y=self.parent.y - math.floor(yRange / 2),self.parent.y + math.floor(yRange / 2) - 1 do
				if self.parent.locationKnown and x == self.parent.xPlayer and y == self.parent.yPlayer then
					self:drawRect(rW * gx, rH * gy, rW, rH, 1.0, 0.3, 0, 0);
				end

				if data[x][y] then
					if data[x][y].seen then
						self:drawTextureScaled(getTexture("Map_BaseTile"), rW * gx, rH * gy, rW, rH, 1, 1, 1, 1);
					end

					if not bcUtils.tableIsEmpty(data[x][y].draw) then
						for _,drawElement in pairs(data[x][y].draw) do
							local c = drawElement.color;

							if drawElement.draw == "wall" then
								if drawElement.collideN and drawElement.collideW then
									self:drawTextureScaled(getTexture("Map_WallNW"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
								elseif drawElement.collideN then
									self:drawTextureScaled(getTexture("Map_WallN"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
								elseif drawElement.collideW then
									self:drawTextureScaled(getTexture("Map_WallW"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
								end
							end

							if drawElement.desc and drawElement.draw == "container" then
								self:drawTextureScaled(getTexture("Map_Container"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
							end
							if drawElement.draw == "street" then
								self:drawTextureScaled(getTexture("Map_Street"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
							end
							if drawElement.draw == "dirtroad" then
								self:drawTextureScaled(getTexture("Map_DirtRoad"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
							end
							if drawElement.draw == "door" then
								if drawElement.collideN then
									self:drawTextureScaled(getTexture("Map_DoorN"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
								end
								if drawElement.collideW then
									self:drawTextureScaled(getTexture("Map_DoorW"), rW * gx, rH * gy, rW, rH, c.a, c.r, c.g, c.b);
								end
							end

						end
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
function BCMapMod.newDrawElement() -- {{{
	return {
		collideN = false,
		collideW = false,
		draw = "",
		desc = "",
		color = { r = 0.6, g = 0.6, b = 0.6, a = 1.0 },
		street = {
			left = false,
			right = false,
			up = false,
			down = false
		}
	};
end
-- }}}
function BCMapMod.insertDrawData(tbl, el) -- {{{
	-- make sure every element exists only once
	local c1 = bcUtils.cloneTable(el);
	c1.color = nil;
	for k,v in pairs(tbl) do
		local c2 = bcUtils.cloneTable(v);
		c2.color = nil;
		if bcUtils.tableIsEqual(c1, c2) then return end
	end
	table.insert(tbl, el);
end
-- }}}
function BCMapMod.onPlayerMove() -- {{{
	if not BCMapMod.MapWindow then return end

	local player = getSpecificPlayer(0);

	if player:IsRunning() then 
		if BCMapMod.MapWindow then
			BCMapMod.MapWindow:removeFromUIManager();
		end
		return;
	end -- No drawing or checking maps when you're running around

	local primary = player:getPrimaryHandItem();
	local secondary = player:getSecondaryHandItem();

	if bcUtils.isMap(secondary) then
		swap = primary;
		primary = secondary;
		secondary = swap;
	end

	if bcUtils.isMap(primary) and bcUtils.isPenOrPencil(secondary) then
		BCMapMod.MapWindow:drawSurroundings(3);
	end
end
-- }}}

Events.OnFillInventoryObjectContextMenu.Add(BCMapMod.createInventoryMenu);

Events.OnPlayerMove.Add(BCMapMod.onPlayerMove);
