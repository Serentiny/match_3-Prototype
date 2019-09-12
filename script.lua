-- Цвета камней
local crystalColor = {
	'1','2','3','4','5','6',	-- 6 цветов камней
	[0] = '0',					-- бесцветный камень
}

-- Типы камней
local crystalType = {
	[0] = '0',	-- обычный камень, для генерации
				-- специфичные камни(взрыв, молния, перекраска, блок, и т.д.)
}

-- Структура, описывающая ячейку, и то что в ней находится
cell = {}

function cell:new()
    local obj = {}
	obj.color = 0			-- цвет камня
	obj.type  = 0			-- тип камня
							-- сюда можно добавлять что-то дополнительное
							--   например: броню, необходимость к сбору, и т.д.
	obj.changed  = false	-- ячейка была изменена, и следующий камень следует проверить
	obj.destroed = false	-- камень в ячейке сейчас взорвется

	obj.dump = function()
		return crystalColor[obj.color]		--..crystalType[self.type]
	end
	return obj
end

-- Структура, описывающая всю таблицу целиком
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

-- Проверка элемента на наличие в таблице, и удаление его
function removeValue(tableName, element)
	for key, value in pairs(tableName) do
		if value == element then
			table.remove(tableName, key)
		end
	end
end

-- Инициализация всего игрового поля
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
			-- проверяем наличие двух одинаковых элементов слева от добавляемого
			if x > 2 and field[x-1][y].color == field[x-2][y].color then
				removeValue(choice, field[x-1][y].color)
			end
			-- проверяем наличие двух одинаковых элементов снизу от добавляемого
			if y > 2 and field[x][y-1].color == field[x][y-2].color then
				removeValue(choice, field[x][y-1].color)
			end
			-- разукрашиваем камень в один из оставшихся цветов
			field[x][y].color = choice[math.random(table.maxn(choice))]
		end
	end
	return field:dump()
end

-- Обновление игрового поля, если какие-то камни составляют сочетание
function tick()
	-- обработка всех камней на уничтожение, добавление новых (случайных), передвигаемся по 'y'
	for x = 1, field.dim do
		for y = field.dim, 1, -1 do
			if field[x][y].destroed then
				-- спускаем вниз те камни, что выше нас
				for iterY = y-1, 1, -1 do
					-- копируем все данные на позицию ниже
					field[x][iterY+1] = field[x][iterY]
					field[x][iterY+1].changed = true
				end

				-- добавляем сверху случайный камень
				choice = {}
				for i = 1, table.maxn(crystalColor) do table.insert(choice, i) end
				field[x][1].color    = choice[math.random(table.maxn(choice))]
				field[x][1].type     = 0
				field[x][1].destroed = false
				field[x][1].changed  = true

				-- из-за того, что камни спустились вниз, перепроверяем ячейку
				y = y + 1
			end
		end
	end

	-- проверяем все затронутые ячейки на уничтожение снова
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

-- Проверка, составляет ли камень в ячейке комбинации с соседями
function checkExplosion(x, y)
	color = field[x][y].color

	-- горизонтальная проверка на уничтожение
	horScore = 0
	lCount = sideCheckExplosion(x, y, 'l', color)
	rCount = sideCheckExplosion(x, y, 'r', color)
	if lCount + rCount >= 2 then
		sideSetRemoveFlag(x, y, 'l', color)
		sideSetRemoveFlag(x, y, 'r', color)
		field[x][y].destroed = true
		horScore = lCount + rCount + 1
	end

	-- вертикальная проверка на уничтожение
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

-- Подпроверка сочетаний в определенную сторону
function sideCheckExplosion(x, y, dir, color)
	newX, newY = getCoordByDir(x, y, dir)
	if inBounds(newX, newY) and field[newX][newY].color == color then
		return sideCheckExplosion(newX, newY, dir, color) + 1
	end
	return 0
end

-- Отмечаем сочетания специальным флагом
function sideSetRemoveFlag(x, y, dir, color)
	newX, newY = getCoordByDir(x, y, dir)
	if inBounds(newX, newY) and field[newX][newY].color == color then
		field[newX][newY].destroed = true
		sideSetRemoveFlag(newX, newY, dir, color)
	end
end

function checkMove()
	movesAvailable = 0
	-- делаем проверку, сколько ходов еще есть

	return true
end

-- Перемещиваем камни на поле
function mix()
	-- проходимся по таблице и запоминаем количество камней каждого цвета
	countTable = {}
	for i = 1, table.maxn(crystalColor) do table.insert(countTable, 0) end
	for y = 1, field.dim do
		for x = 1, field.dim do
			countTable[field[x][y].color] = countTable[field[x][y].color] + 1
		end
	end

	-- расставляем те камни, которые сохранили
	for y = 1, field.dim do
		for x = 1, field.dim do	
			-- собираем информацию по камням, которые можем выложить
			choice = {}
			for i = 1, table.maxn(crystalColor) do
				if countTable[i] > 0 then
					table.insert(choice, i)
				end
			end

			-- проверяем наличие двух одинаковых элементов слева от добавляемого
			if x > 2 and field[x-1][y].color == field[x-2][y].color then
				removeValue(choice, field[x-1][y].color)
			end

			-- проверяем наличие двух одинаковых элементов снизу от добавляемого
			if y > 2 and field[x][y-1].color == field[x][y-2].color then
				removeValue(choice, field[x][y-1].color)
			end

			if table.maxn(choice) == 0 then
				-- подходящих камней не осталось, подложим новый камень
				color = field[x-1][y].color % 6 + 1
				if color == field[x][y-1].color then color = field[x][y-1].color % 6 + 1 end
				field[x][y].color = color
			else
				-- разукрашиваем камень в один из оставшихся цветов
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

function move(x1, y1, dir)
	needToUpdate = false
	if dir == 'l' and x1 <= 1
	or dir == 'r' and x1 >= field.dim
	or dir == 'u' and y1 <= 1        
	or dir == 'd' and y1 >= field.dim then
		return "", needToUpdate
	end
	x2, y2 = getCoordByDir(x1, y1, dir)
	-- проверили крайние случаи, теперь перемещаем камни
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
