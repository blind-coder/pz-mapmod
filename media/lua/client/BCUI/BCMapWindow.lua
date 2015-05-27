require "ISUI/ISCollapsableWindow"

local bcUtils = {};
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

function BCMapWindow:initialise()
	ISCollapsableWindow.initialise(self);
	self.title = "Map booklet";
end

--[[ {{{ TODO mouse handling
function BCMapWindow:onMapMouseDown(x, y)
	local cell = getCell();
	x = translatePointXInOverheadMapToWorld(x, self.javaObject,self.parent.zoom, self.parent.xpos);
	y = translatePointYInOverheadMapToWorld(y, self.javaObject,self.parent.zoom, self.parent.ypos);
	local sq = cell:getGridSquare(x, y, 0);
	self.parent.selectedSquare = sq;
	self.parent:fillInfo();
	return true;
end

function BCMapWindow:onMapMouseMove(dx, dy)
	if self.panning then
		self.parent.xpos = self.parent.xpos - ((dx)/self.parent.zoom);
		self.parent.ypos = self.parent.ypos - ((dy)/self.parent.zoom);
	end
	return true;
end

function BCMapWindow:onMapRightMouseDown(x, y)
	self.panning = true;
	return true;
end

function BCMapWindow:onMapRightMouseUp(x, y)
	self.panning = false;
	return true;
end

function BCMapWindow:onRenderMouseWheel(del)
	if(del > 0) then
		self.parent.zoom = self.parent.zoom* 0.8;
	else
		self.parent.zoom = self.parent.zoom* 1.2;
	end
	if self.parent.zoom > 30 then self.parent.zoom = 30 end
	return true;
end
-- }}} ]]

function BCMapWindow:createChildren() -- {{{
	ISCollapsableWindow.createChildren(self);

	self.renderPanel = ISPanel:new(100, 16, self.width-100, self.height-32);
	self.renderPanel.render = BCMapWindow.renderMap;
	self.renderPanel.parent = self;
	self.renderPanel:initialise();
	self.renderPanel:setAnchorRight(true);
	self.renderPanel:setAnchorBottom(true);
	self:addChild(self.renderPanel);

	self.drawMapButton = ISButton:new(1, 16, 98, 32, "Draw map", self, self.drawMap);
end
-- }}}
function BCMapWindow:drawMap() -- {{{
	if not self.data then self.data = {} end

	local cell     = getCell();
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
						elseif bcUtils.isContainer(it) then
							print((x+xMin).."x"..(y+yMin)..": Container: "..tostring(it:getContainer():getType()))
						else
							print((x+xMin).."x"..(y+yMin)..": Item #"..(k+1)..": "..tostring(it:getName()).."/"..tostring(it:getTextureName()));
						end
					end
				end
			end
		end
	end
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
						elseif bcUtils.isContainer(it) then
							print((x+xMin).."x"..(y+yMin)..": Container: "..tostring(it:getContainer():getType()))
						else
							print((x+xMin).."x"..(y+yMin)..": Item #"..(k+1)..": "..tostring(it:getName()).."/"..tostring(it:getTextureName()));
						end
					end
				end
			end
		end
	end
end
-- }}}
function BCMapWindow:renderMap() -- {{{
	self:setStencilRect(0,0,self:getWidth(), self:getHeight());

	self.parent:grabInfo();
	local data = self.parent.data;

	local cell = getCell(); --self.parent.cell;
	local chunkMap = cell:getChunkMap(0);
	local xMin = chunkMap:getWorldXMinTiles();
	local yMin = chunkMap:getWorldYMinTiles();
	local rW = math.min(self.width, self.height) / cell:getWidthInTiles();
	local rH = math.min(self.width, self.height) / cell:getHeightInTiles();

	for x=0,cell:getWidthInTiles()-1 do
		for y=0,cell:getHeightInTiles()-1 do

			if data[xMin][yMin][x][y].collideN then
				self:drawRect(rW * x, rH * y, rW, 4, 1.0, 0.9, 0.163, 0.064);
			end
			if data[xMin][yMin][x][y].collideW then
				self:drawRect(rW * x, rH * y, 4, rH, 1.0, 0.9, 0.163, 0.064);
			end
		end
	end

	self:clearStencilRect();
end
-- }}}

function BCMapWindow:new (x, y, width, height)
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.backgroundColor = {r=0, g=0, b=0, a=1.0};

	o.zoom = 1;

	return o
end

function BCMapModCreateWindow()
	local m = BCMapWindow:new(0, 0, 600, 600);
	m:setVisible(true);
	m:addToUIManager();
end

Events.OnGameStart.Add(BCMapModCreateWindow);
