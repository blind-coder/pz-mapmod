require "ISUI/ISCollapsableWindow"
require "bcUtils"

-- ISBuildMenu.cheat = true;
-- ModData used:
-- getModData()["BCMapMod"] = {
--   [options] = { -- some options for this map
--     [x] = 123,
--     [y] = 123,
--     [w] = 123,
--     [h] = 123, -- position / dimensions of this map
--     [zoom] = 8, -- zoomlevel
--     [autoMoveMap] = true|false -- option for autoMoveMap
--   },
--   [range] = { -- a range identifier to restrict drawing to available paper space
--     [freePaper] = int -- amount of unused paper in this map to use for additional cells
--     [cellX] = {
--       [cellY] = true -- if set and true, have paper for this cell
--     }
--   },
--   [empty] = true|false, -- if this map is empty
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

--[[ TEXTURE WRAPPER --]]
-- This is necessary to properly render textures that are not
-- exactly 64x64 pixels in size.
-- Written by TurboTuTone

TextureWrapper = {};
function TextureWrapper.new( _texture ) -- {{{
	local self = {};
	self.texture = _texture;
	
	function self.renderScaled( _uiObject, _x, _y, _zoom, _a, _r, _g, _b ) --uiObject can be lua or java uielement
		if self.texture and _uiObject then
			local x,y,w,h = _x+self.oX*_zoom, _y+self.oY*_zoom, self.W*_zoom, self.H*_zoom;
			_uiObject:drawTextureScaled(self.texture, x, y, w, h, _a, _r, _g, _b);
		end
	end

	function self.setOffsetX( _oX )
		self.oX = _oX;
	end

	function self.setOffsetY( _oY )
		self.oY = _oY;
	end
	
	local function init()
		if self.texture then
			self.sX = _texture:getXStart();
			self.sY = _texture:getYStart();
			--self.eX = _texture:getXEnd();
			--self.eY = _texture:getYEnd();
			self.W  = _texture:getWidth();
			self.H  = _texture:getHeight();
			self.rW = 64; -- _texture:getRealWidth();
			self.rH = 64; -- _texture:getRealHeight();

			self.oX = self.rW - self.W; -- X offset to apply
			self.oY = self.rH - self.H; -- Y offset to apply
		end

		return self;
	end
	
	return init();
end
-- }}}
TextureWrapper.init = function() -- {{{
	local textures = {};
	table.insert(textures, "Map_BaseTile");
	table.insert(textures, "Map_DirtRoad");
	table.insert(textures, "Map_DoorW");
	table.insert(textures, "Map_FogNE");
	table.insert(textures, "Map_FogNW");
	table.insert(textures, "Map_FogSE");
	table.insert(textures, "Map_FogSW");
	table.insert(textures, "Map_Street");
	table.insert(textures, "Map_WallNW");
	table.insert(textures, "Map_WallW");
	table.insert(textures, "Map_WindowW");
	table.insert(textures, "Map_FogN");
	table.insert(textures, "Map_FogS");
	table.insert(textures, "Map_TreePine");
	table.insert(textures, "Map_Container");
	table.insert(textures, "Map_FogE");
	table.insert(textures, "Map_FogW");
	table.insert(textures, "Map_TreeNormal");
	table.insert(textures, "Map_DoorN");
	table.insert(textures, "Map_WallN");
	table.insert(textures, "Map_WindowN");
	table.insert(textures, "Map_WallStump");

	for _,tex in pairs(textures) do
		TextureWrapper[tex] = TextureWrapper.new(getTexture(tex));
	end
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
			self.parent.xloc = self.parent.xloc - math.floor((self.panx)/math.floor(64 / self.parent.zoom));
			self.panx = self.panx % math.floor(64 / self.parent.zoom);
		end
		if math.abs(self.pany) > math.floor(64 / self.parent.zoom) then
			self.parent.yloc = self.parent.yloc - math.floor((self.pany)/math.floor(64 / self.parent.zoom));
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
		self.parent:changeZoom(1);
	else
		self.parent:changeZoom(-1);
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
	self.renderPanel.render = BCMapMod.renderMap;
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

	self.buttonPanel = ISPanel:new(0, 16, 100, self.height-32);
	self.buttonPanel:initialise();
	self.buttonPanel:setAnchorLeft(true);
	self.buttonPanel:setAnchorTop(true);
	self:addChild(self.buttonPanel);

	self.drawMapButton = ISButton:new(0, 0, 100, 32, "Draw map", self, self.drawMap);
	self.drawMapButton:initialise();
	self.drawMapButton:setAnchorLeft(true);
	self.drawMapButton:setAnchorTop(true);
	self.buttonPanel:addChild(self.drawMapButton);

	self.zoomOutButton = ISButton:new(0, 32, 100, 32, "Zoom -", self, self.zoomOut);
	self.zoomOutButton:initialise();
	self.zoomOutButton:setAnchorLeft(true);
	self.zoomOutButton:setAnchorTop(true);
	self.buttonPanel:addChild(self.zoomOutButton);

	self.zoomInButton = ISButton:new(0, 64, 100, 32, "Zoom +", self, self.zoomIn);
	self.zoomInButton:initialise();
	self.zoomInButton:setAnchorLeft(true);
	self.zoomInButton:setAnchorTop(true);
	self.buttonPanel:addChild(self.zoomInButton);

	self.findLocationButton = ISButton:new(0, 96, 100, 32, "Find Location", self, self.findLocation);
	self.findLocationButton:initialise();
	self.findLocationButton:setAnchorLeft(true);
	self.findLocationButton:setAnchorTop(true);
	self.buttonPanel:addChild(self.findLocationButton);

	self.autoMoveMap = ISTickBox:new(0, 128, 32, 32, "", self, self.toggleAutoMoveMap);
	self.autoMoveMap:initialise();
	self.autoMoveMap:addOption("Auto-move map", nil);
	self.autoMoveMap:setSelected(1, BCMapMod.autoMoveMap);
	self.autoMoveMap:setAnchorLeft(true);
	self.autoMoveMap:setAnchorTop(true);
	self.buttonPanel:addChild(self.autoMoveMap);

	--[[self.forceDrawButton = ISButton:new(0, self.height-64, 100, 32, "Force draw", self, self.forceDraw);
	self.forceDrawButton:initialise();
	self.forceDrawButton:setAnchorLeft(true);
	self.forceDrawButton:setAnchorTop(true);
	self.buttonPanel:addChild(self.forceDrawButton);
	--]]
end
-- }}}
function BCMapWindow:toggleAutoMoveMap(index, selected) -- {{{
	BCMapMod.autoMoveMap = selected;
	self:saveOptions();
end
-- }}}
function BCMapWindow:findLocation() -- {{{
	local player = getSpecificPlayer(0);
	local xPlayer = math.floor(player:getX());
	local yPlayer = math.floor(player:getY());

	if self.locationKnown then
		self.xloc = xPlayer;
		self.yloc = yPlayer;
		self.xPlayer = xPlayer;
		self.yPlayer = yPlayer;
		return;
	end

	local data = BCMapMod.getDataFromModData(self.item);
	if data.empty then return end;

	local x;
	local y;
	-- Check if we know some place close to us
	for x=xPlayer-5,xPlayer+5 do
		if data[x] then
			for y=yPlayer-5,yPlayer+5 do
				if data[x][y] then
					self.locationKnown = true; -- the player has already drawn this part of the map
					self.xloc = xPlayer;
					self.yloc = yPlayer;
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
	self.zoom = self.zoom or 1;

	if change > 0 then
		self.zoom = self.zoom * 2;
	else
		self.zoom = self.zoom / 2;
	end

	self.zoom = math.max(self.zoom, 1);
	self.zoom = math.min(self.zoom, 8);
	self:saveOptions();
end
-- }}}
function taPerform() -- {{{
	BCMapMod.MapWindow:drawSurroundings(10);
end
-- }}}
function taIsValid() -- {{{
	return true;
end
-- }}}
function BCMapWindow:drawMap() --{{{
	local ta = BCUGenericTA:new(getPlayer(), 30);
	ta:setOnPerform(taPerform);
	ISTimedActionQueue.add(ta);
end
-- }}}
function BCMapWindow:drawSurroundings(range) -- {{{
	local player   = getSpecificPlayer(0);
	local cell     = getCell();
	local chunkMap = cell:getChunkMap(0);
	local xPlayer  = math.floor(player:getX());
	local yPlayer  = math.floor(player:getY());
	local xCell    = math.floor(xPlayer / 300);
	local yCell    = math.floor(yPlayer / 300);
	range = range --[[ + (1+player:getTrait(Trait.Cartographer)) ]];

	local inv = player:getInventory();
	local pen;
	if bcUtils.isPenOrPencil(player:getPrimaryHandItem()) then
		pen = player:getPrimaryHandItem();
	elseif bcUtils.isPenOrPencil(player:getSecondaryHandItem()) then
		pen = player:getSecondaryHandItem();
	else
		pen = inv:FindAndReturn("Base.Pen");
		if pen == nil then
			pen = inv:FindAndReturn("Base.Pencil");
		end
	end
	if pen == nil then
		player:Say("I have no pen or pencil to draw with.");
		return;
	end
	BCMapMod.pen = pen;

	local data = BCMapMod.getDataFromModData(self.item);
	if not data.range[xCell] then
		data.range[xCell] = {};
	end
	if not data.range[xCell][yCell] then
		if data.range.freePaper > 0 then
			data.range[xCell][yCell] = true;
			data.range.freePaper = data.range.freePaper - 1;
		else
			player:Say("I am out of paper.");
			return;
		end
	end

	local firstTime = false;
	if data.empty then -- data is empty
		self.locationKnown = true; -- player doesn't know its location unless this is the first draw of the map
		firstTime = true;
	end

	if not self.locationKnown then
		player:Say("I don't know where I am...");
		return;
	end

	for x=xPlayer-range,xPlayer+range do
		for y=yPlayer-range,yPlayer+range do
			if bcUtils.realDist(xPlayer, yPlayer, x, y) <= range then
				self:drawSquare(x, y);
			end
		end
	end

	if firstTime then
		self:findLocation();
	end

	self.xPlayer = xPlayer;
	self.yPlayer = yPlayer;
end
-- }}}
function BCMapWindow:drawSquare(x, y) -- {{{
	local x2;
	local y2;
	local cell = getCell();
	local data = BCMapMod.getDataFromModData(self.item);
	data.empty = false;

	for x2=x-1,x+1 do
		if not data[x2] then data[x2] = {} end
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
				newDraw.draw = "door";
				newDraw.collideN = it:getNorth();
				newDraw.collideW = not it:getNorth();
				if it:getNorth() then
					doAdd = it:getNorth();
				else
					BCMapMod.insertDrawData(data[x-1][y].draw, newDraw);
				end
				--[[if sq:isDoorTo(nsq) or nsq:isDoorTo(sq) then
					print("door from "..x.."x"..y.." to "..x.."x"..(y-1));
					newDraw.collideN = true;
					doAdd = true;
				end
				nsq = cell:getGridSquare(x-1, y, 0);
				if sq:isDoorTo(nsq) or nsq:isDoorTo(sq) then
					print("door from "..x.."x"..y.." to "..(x-1).."x"..y);
					newDraw.collideW = true;
					doAdd = true;
				end
				]]
			elseif bcUtils.isTree(it) then
				newDraw.draw = "tree";
				doAdd = true;
			elseif bcUtils.isContainer(it) then
				newDraw.draw = "container";
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

	nsq = cell:getGridSquare(x+1, y, 0);
	if canSee or nsq:isCanSee(0) then
		if sq:isBlockedTo(nsq) then
			local newDraw = BCMapMod.newDrawElement();
			newDraw.collideW = true;
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
			BCMapMod.insertDrawData(data[x-1][y].draw, newDraw);
		end
	end
end
-- }}}
function BCMapWindow:setX(x) -- {{{
	ISCollapsableWindow.setX(self, x);
	self:saveOptions();
end
-- }}}
function BCMapWindow:setY(y) -- {{{
	ISCollapsableWindow.setY(self, y);
	self:saveOptions();
end
-- }}}
function BCMapWindow:onResize() -- {{{
	local dx = self:getWidth();
	local dy = self:getHeight();
	if dx < 300 then
		self.buttonPanel:setVisible(false);
		self.renderPanel:setX(0);
		self.renderPanel:setWidth(dx);
	else
		self.buttonPanel:setVisible(true);
		self.buttonPanel:setHeight(self.height-32);
		self.renderPanel:setX(100);
		self.renderPanel:setWidth(dx-100);
	end
	self:saveOptions();
end
-- }}}
function BCMapWindow:saveOptions() -- {{{
	local data = BCMapMod.getDataFromModData(self.item);
	data.options = {};
	data.options.x = self:getX();
	data.options.y = self:getY();
	data.options.w = self:getWidth();
	data.options.h = self:getHeight();
	data.options.zoom = self.zoom;
	data.options.autoMoveMap = BCMapMod.autoMoveMap;
end
-- }}}
function BCMapWindow:new (x, y, width, height, item) -- {{{
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=0.7};
	o.xloc = 0;
	o.yloc = 0;
	o.zoom = 1;
	o.locationKnown = false;
	o.item = item;

	local data = BCMapMod.getDataFromModData(item);
	if not data.options then
		o:saveOptions();
	else
		local _x, _y, _w, _h, _z, _a = data.options.x, data.options.y, data.options.w, data.options.h, data.options.zoom, data.options.autoMoveMap;
		BCMapMod.autoMoveMap = _a;
		o.zoom = _z or o.zoom;
		o:setWidth(_w or width);
		o:setHeight(_h or height);
		o:setX(_x or x);
		o:setY(_y or y);
	end

	return o
end
-- }}}

BCMapMod = {};

BCMapMod.Colors = {
	{r = 0.914, g = 0.914, b = 0.914, a = 1.0},
	{r = 0.702, g = 0.294, b = 0.282, a = 1.0},
	{r = 0.353, g = 0.416, b = 0.714, a = 1.0},
	{r = 0.420, g = 0.714, b = 0.345, a = 1.0},
	{r = 0.224, g = 0.224, b = 0.224, a = 1.0},
	{r = 0.886, g = 0.655, b = 0.220, a = 1.0},
	{r = 0.659, g = 0.110, b = 0.843, a = 1.0},
	{r = 0.804, g = 0.843, b = 0.102, a = 1.0},
	{r = 0.125, g = 0.8, b = 0.784, a = 1.0}
};

function BCMapMod.createWindow(item) -- {{{
	local m = BCMapWindow:new(50, 50, getCore():getScreenWidth() - 100, getCore():getScreenHeight() - 100, item);
	m:setVisible(true);
	m:addToUIManager();

	BCMapMod.MapWindow = m;
	BCMapMod.MapWindow:findLocation();
end
-- }}}
function BCMapMod.checkEquipMap() -- {{{
	local player = getPlayer();
	if BCMapMod.MapWindow then
		-- Only one map window at a time
		if player:getPrimaryHandItem()   == BCMapMod.MapWindow.item then return end
		if player:getSecondaryHandItem() == BCMapMod.MapWindow.item then return end
		BCMapMod.MapWindow:removeFromUIManager();
		BCMapMod.MapWindow = nil;
		return;
	end

	local item = player:getPrimaryHandItem();
	if item and item:getFullType() == "BCMapMod.Map" then
		BCMapMod.createWindow(item);
		return;
	end
	local item = player:getSecondaryHandItem();
	if item and item:getFullType() == "BCMapMod.Map" then
		BCMapMod.createWindow(item);
		return;
	end

	if BCMapMod.MapWindow then
		BCMapMod.MapWindow:removeFromUIManager();
		BCMapMod.MapWindow = nil;
	end
end
-- }}}
function BCMapMod.getDataFromModData(item) -- {{{
	local md = item:getModData();
	if not md["BCMapMod"] then
		md["BCMapMod"] = {};
		md["BCMapMod"].range = {};
		md["BCMapMod"].range.freePaper = 4; -- so we can draw 4 cells
		md["BCMapMod"].empty = true;
	end
	return md["BCMapMod"];
end
-- }}}
function BCMapMod.newDrawElement() -- {{{
	local color = { r = 0.6, g = 0.6, b = 0.6, a = 1.0 };
	if BCMapMod.pen:getFullType() == "Base.Pen" then
		md = BCMapMod.pen:getModData();
		if md.BCMapMod == nil then
			md.BCMapMod = {};
			md.BCMapMod.Color = BCMapMod.Colors[ZombRand(1, #BCMapMod.Colors)];
		end
		color = md.BCMapMod.Color;
	end
	return {
		collideN = false,
		collideW = false,
		draw = "",
		desc = "",
		color = color,
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
		-- if BCMapMod.MapWindow then
			-- BCMapMod.MapWindow:removeFromUIManager();
		-- end
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

	if BCMapMod.autoMoveMap then
		BCMapMod.MapWindow:findLocation();
	end
end
-- }}}
function BCMapMod:renderMap() -- {{{
	if not self.parent.item then return end;
	local data = BCMapMod.getDataFromModData(self.parent.item);
	if bcUtils.tableIsEmpty(data) then return end;

	local player   = getSpecificPlayer(0);
	local xPlayer  = math.floor(player:getX());
	local yPlayer  = math.floor(player:getY());
	local range = 10 --[[ * self.parent.zoom ]];
	local rW = 64 / self.parent.zoom;
	local rH = rW; -- math.min(self.width, self.height) / (range * 2);
	local xRange = math.ceil(self.width/rW);
	local yRange = math.ceil(self.height/rH);

	local gx = 0;
	self:setStencilRect(0, 0, self.width, self.height);
	for x=self.parent.xloc - math.floor(xRange / 2),self.parent.xloc + math.ceil(xRange / 2) do
		if data[x] then
			local gy = 0;
			for y=self.parent.yloc - math.floor(yRange / 2),self.parent.yloc + math.ceil(yRange / 2) do
				if self.parent.locationKnown and x == self.parent.xPlayer and y == self.parent.yPlayer then
					self:drawRect(rW * gx, rH * gy, rW, rH, 1.0, 0.3, 0, 0);
				end

				if data[x][y] then
					if data[x][y].seen then
						TextureWrapper["Map_BaseTile"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
					end

					if not bcUtils.tableIsEmpty(data[x][y].draw) then -- {{{
						for _,drawElement in pairs(data[x][y].draw) do
							local c = drawElement.color;
							c.a = c.a or 1.0;

							if drawElement.draw == "wall" then
								if drawElement.collideN and drawElement.collideW then
									TextureWrapper["Map_WallNW"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
								elseif drawElement.collideN then
									TextureWrapper["Map_WallW"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
								elseif drawElement.collideW then
									TextureWrapper["Map_WallN"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
								end
							end

							if drawElement.draw == "container" then
								TextureWrapper["Map_Container"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
							end
							if drawElement.draw == "street" then
								TextureWrapper["Map_Street"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
							end
							if drawElement.draw == "dirtroad" then
								TextureWrapper["Map_DirtRoad"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
							end
							if drawElement.draw == "door" then
								if drawElement.collideN then
									TextureWrapper["Map_DoorW"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
								end
								if drawElement.collideW then
									TextureWrapper["Map_DoorN"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
								end
							end
							if drawElement.draw == "tree" then
								if (x + y) % 2 == 0 then
									TextureWrapper["Map_TreePine"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
								else
									TextureWrapper["Map_TreeNormal"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, c.a, c.r, c.g, c.b);
								end
							end

						end
					end--}}}
					-- {{{ Fog of war
					--[[
					self.parent:ensureExists(x, y);
					self.parent:ensureExists(x, y-1);
					self.parent:ensureExists(x, y+1);
					self.parent:ensureExists(x+1, y);
					self.parent:ensureExists(x+1, y-1);
					self.parent:ensureExists(x+1, y+1);
					self.parent:ensureExists(x-1, y);
					self.parent:ensureExists(x-1, y-1);
					self.parent:ensureExists(x-1, y+1);
					if data[x][y].seen then
						if not data[x][y-1].seen then
							if data[x+1][y].seen and data[x-1][y].seen then
								TextureWrapper["Map_FogN"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
							end
							if not data[x+1][y].seen then
								TextureWrapper["Map_FogNE"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
							end
							if not data[x-1][y].seen then
								TextureWrapper["Map_FogNW"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
							end
						elseif not data[x][y+1].seen then
							if data[x+1][y+1].seen and data[x-1][y+1].seen then
								TextureWrapper["Map_FogS"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
							end
							if not data[x+1][y].seen then
								TextureWrapper["Map_FogSE"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
							end
							if not data[x-1][y].seen then
								TextureWrapper["Map_FogSW"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
							end
						elseif not data[x-1][y].seen then
							TextureWrapper["Map_FogW"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
						elseif not data[x+1][y].seen then
							TextureWrapper["Map_FogE"].renderScaled(self, rW * gx, rH * gy, 1/self.parent.zoom, 1, 1, 1, 1);
						end
					end
					--]]
					--}}}
				end
				gy = gy + 1;
			end
		end
		gx = gx + 1;
	end
	self:clearStencilRect();
end
-- }}}

Events.OnEquipPrimary.Add(BCMapMod.checkEquipMap);
Events.OnEquipSecondary.Add(BCMapMod.checkEquipMap);
Events.OnPlayerMove.Add(BCMapMod.onPlayerMove);

Events.OnLoad.Add(BCMapMod.checkEquipMap);
Events.OnGameStart.Add(TextureWrapper.init);

function BCMapMod.createInventoryMenu(player, context, items) -- {{{
	local item = items[1];
	if not instanceof(item, "InventoryItem") then
		item = item.items[1];
	end
	if item == nil then return end;

	if item:getFullType() == "BCMapMod.Map" then
		local o = context:addOption("Add page to map", player, BCMapMod.AddPageToMap, item);
		if getSpecificPlayer(player):getInventory():FindAndReturn("Base.SheetPaper") == nil then
			o.notAvailable = true;
		end
	end
end
-- }}}
function BCMapMod.AddPageToMap(player, map) -- {{{
	player = getSpecificPlayer(player);
	local inv = player:getInventory();
	inv:Remove(inv:FindAndReturn("Base.SheetPaper"));
	local data = BCMapMod.getDataFromModData(map);
	data.range.freePaper = data.range.freePaper + 1;
	player:Say("There are now "..data.range.freePaper.." free pages in this map.");
end
-- }}}
Events.OnFillInventoryObjectContextMenu.Add(BCMapMod.createInventoryMenu);

function BCMapMod.onKeyPressed(key) -- {{{
	if key == getCore():getKey("Equip_Map") then
		if BCMapMod.MapWindow then
			BCMapMod.MapWindow:removeFromUIManager();
			BCMapMod.MapWindow = nil;
			return;
		end
		local player = getPlayer();
		local map = player:getPrimaryHandItem();
		if map ~= nil and map:getFullType() == "BCMapMod.Map" then
			BCMapMod.createWindow(map);
			return;
		end
		map = player:getSecondaryHandItem();
		if map ~= nil and map:getFullType() == "BCMapMod.Map" then
			BCMapMod.createWindow(map);
			return;
		end
		local player = getSpecificPlayer(0);
		local inv = player:getInventory();
		map = inv:FindAndReturn("BCMapMod.Map");
		if map ~= nil then
			ISTimedActionQueue.add(ISEquipWeaponAction:new(player, map, 120, false, false));
		end
	end
end
-- }}}
Events.OnKeyPressed.Add(BCMapMod.onKeyPressed);

BCMapMod.ISToolTipInvRender = ISToolTipInv.render;
ISToolTipInv.render = function(self) -- {{{
	if self.item:getFullType() == "BCMapMod.Map" then
		local data = BCMapMod.getDataFromModData(self.item);
		self.item:setTooltip("Pages left: "..data.range.freePaper);
	end
	BCMapMod.ISToolTipInvRender(self);
end
-- }}}
