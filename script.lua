----- Cell and its attrs -----
local crystalColor = {
	'1','2','3','4','5','6',	-- 6 crystal colors
	[0] = '0',					-- crystal without a color
}

local crystalType = {
	[0] = '0',	-- regular crystal for generation
				-- specific crystals (explosion, lightning, recolor, block, etc.)
}

cell = {}
function cell:new()
    local obj = {}
	obj.color = 0
	obj.type  = 0
							-- we can add some additional here
							--   like: armor, needToCollect, etc.
	obj.changed  = false	-- cell was touched, so we must to check crystal in combination
	obj.destroed = false	-- cell will destoyed in cel by next tick

	obj.dump = function()
		return crystalColor[obj.color]		--..crystalType[self.type]
	end
	return obj
end

----- Field table -----
local field = {
	dim = 10,
}

function field:dump()
	local result = ""
	for y = 1, self.dim do
		for x = 1, self.dim do
			result = result..self[x][y]:dump()
		end
	end
	return result
end

----- Additional functions -----
function getCoordByDir(x, y, dir)
	if dir == "l" then
		return x-1, y
	elseif dir == "r" then
		return x+1, y
	elseif dir == "u" then
		return x, y-1
	elseif dir == "d" then
		return x, y+1
	end
end

function inBounds(...)
	inside = true
	coords = {...}
	for _, coord in ipairs(coords) do
		inside = inside and coord >= 1 and coord <= field.dim
	end
	return inside
end

function removeValue(tableName, element)
	for key, value in pairs(tableName) do
		if value == element then
			table.remove(tableName, key)
		end
	end
end

-- Field initialization
function init()
	math.randomseed( os.time() )
	for x = 1, field.dim do
		for y = 1, field.dim do
			if field[y] == nil then
				field[y] = {}
			end
			field[x][y] = cell:new()

			choice = {}
			for i = 1, table.maxn(crystalColor) do table.insert(choice, i) end

			-- check for two similar color to the left
			if x > 2 and field[x-1][y].color == field[x-2][y].color then
				removeValue(choice, field[x-1][y].color)
			end

			-- check for two similar color from the downside
			if y > 2 and field[x][y-1].color == field[x][y-2].color then
				removeValue(choice, field[x][y-1].color)
			end

			-- recolor our crystal to any remaining color
			field[x][y].color = choice[math.random(table.maxn(choice))]
		end
	end
	return field:dump()
end

-- Field update (if there are some combinations)
function tick()
	-- update crystals for destroing
	for x = 1, field.dim do
		for y = field.dim, 1, -1 do
			if field[x][y].destroed then
				-- move dow all crystals above us
				for iterY = y-1, 1, -1 do
					-- move crystals to one space below
					field[x][iterY+1] = field[x][iterY]
					field[x][iterY+1].changed = true
				end

				-- add random crystal to the top
				choice = {}
				for i = 1, table.maxn(crystalColor) do table.insert(choice, i) end
				field[x][1].color    = choice[math.random(table.maxn(choice))]
				field[x][1].type     = 0
				field[x][1].destroed = false
				field[x][1].changed  = true

				-- check cell again, in case of destroing previous crystal
				y = y + 1
			end
		end
	end

	-- check all touched cells to combinations again
	needToTick = 0
	for x = 1, field.dim do
		for y = 1, field.dim do
			if field[x][y].changed then
				needToTick = needToTick + checkExplosion(x, y)
			end
		end
	end

	needToUpdate = needToTick > 0
	if needToUpdate then
		return field:dump(), needToUpdate
	else
		if not checkMove() then
			return mix(), needToUpdate
		else
			return field:dump(), needToUpdate
		end
	end
end

-- Check for any combinations of that cell
function checkExplosion(x, y)
	color = field[x][y].color

	-- horisontal check to destroing
	horScore = 0
	lCount = sideCheckExplosion(x, y, 'l', color)
	rCount = sideCheckExplosion(x, y, 'r', color)
	if lCount + rCount >= 2 then
		sideSetRemoveFlag(x, y, 'l', color)
		sideSetRemoveFlag(x, y, 'r', color)
		field[x][y].destroed = true
		horScore = lCount + rCount + 1
	end

	-- vertical check to destroing
	vertScore = 0
	uCount = sideCheckExplosion(x, y, 'u', color)
	dCount = sideCheckExplosion(x, y, 'd', color)
	if uCount + dCount >= 2 then
		sideSetRemoveFlag(x, y, 'u', color)
		sideSetRemoveFlag(x, y, 'd', color)
		field[x][y].destroed = true
		vertScore = uCount + dCount + 1
	end

	return horScore + vertScore		-- эти значения можно передавать в систему очков
end

-- Subcheck for any combinations in exact direction
function sideCheckExplosion(x, y, dir, color)
	newX, newY = getCoordByDir(x, y, dir)
	if inBounds(newX, newY) and field[newX][newY].color == color then
		return sideCheckExplosion(newX, newY, dir, color) + 1
	end
	return 0
end

-- Mark all cells in combination by special flag
function sideSetRemoveFlag(x, y, dir, color)
	newX, newY = getCoordByDir(x, y, dir)
	if inBounds(newX, newY) and field[newX][newY].color == color then
		field[newX][newY].destroed = true
		sideSetRemoveFlag(newX, newY, dir, color)
	end
end

-- Check, how many moves are at a field
function checkMove()
	movesAvailable = 0


	return true
end

-- Shuffle all crystals at a field
function mix()
	-- memorize counts of each crystals
	countTable = {}
	for i = 1, table.maxn(crystalColor) do table.insert(countTable, 0) end
	for y = 1, field.dim do
		for x = 1, field.dim do
			countTable[field[x][y].color] = countTable[field[x][y].color] + 1
		end
	end

	-- arrange those crystals, that we have saved
	for y = 1, field.dim do
		for x = 1, field.dim do	
			-- collect info about crystals
			choice = {}
			for i = 1, table.maxn(crystalColor) do
				if countTable[i] > 0 then
					table.insert(choice, i)
				end
			end

			-- check for two similar color to the left
			if x > 2 and field[x-1][y].color == field[x-2][y].color then
				removeValue(choice, field[x-1][y].color)
			end

			-- check for two similar color from the downside
			if y > 2 and field[x][y-1].color == field[x][y-2].color then
				removeValue(choice, field[x][y-1].color)
			end

			if table.maxn(choice) == 0 then
				-- there are no available crystal, put a new stone
				color = field[x-1][y].color % 6 + 1
				if color == field[x][y-1].color then color = field[x][y-1].color % 6 + 1 end
				field[x][y].color = color
			else
				-- recolor our crystal to any remaining color
				field[x][y].color = choice[math.random(table.maxn(choice))]
				countTable[field[x][y].color] = countTable[field[x][y].color] - 1
			end
		end
	end

	if checkMove() then
		return field:dump()
	else
		return mix()
	end
end

-- Swap crystals by swipe from (x, y) to dir
function move(x1, y1, dir)
	needToUpdate = false
	if dir == 'l' and x1 <= 1
	or dir == 'r' and x1 >= field.dim
	or dir == 'u' and y1 <= 1        
	or dir == 'd' and y1 >= field.dim then
		return "", needToUpdate
	end
	x2, y2 = getCoordByDir(x1, y1, dir)
	-- we have checked extreme case, so now - swap them
	field[x1][y1], field[x2][y2] = field[x2][y2], field[x1][y1]
	field[x1][y1].changed = true
	field[x2][y2].changed = true
	
	if checkExplosion(x1, y1) > 0 or checkExplosion(x2, y2) > 0 then
		return tick()
	else
		field[x1][y1], field[x2][y2] = field[x2][y2], field[x1][y1]
		return "", needToUpdate
	end
end
