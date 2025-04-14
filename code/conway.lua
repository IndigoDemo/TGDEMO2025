local conway = {}

function conway.new(width, height)
    local self = {}
    self.width = width
    self.height = height
    self.cells = {}
    self.buffer = {}
    for y = 1, height do
        self.cells[y] = {}
        self.buffer[y] = {}
        for x = 1, width do
            self.cells[y][x] = 0
            self.buffer[y][x] = 0
        end
    end
    function self:setCell(x, y, state)
        if x >= 1 and x <= self.width and y >= 1 and y <= self.height then
            self.cells[y][x] = state
        end
    end
    function self:getCell(x, y)
        if x < 1 or x > self.width or y < 1 or y > self.height then
            return 0
        end
        return self.cells[y][x]
    end
    function self:countNeighbors(x, y)
        local count = 0
        for dy = -1, 1 do
            for dx = -1, 1 do
                if not (dx == 0 and dy == 0) then
                    local nx, ny = x + dx, y + dy
                    count = count + self:getCell(nx, ny)
                end
            end
        end
        return count
    end
    function self:update()
        for y = 1, self.height do
            for x = 1, self.width do
                local neighbors = self:countNeighbors(x, y)
                local state = self:getCell(x, y)
                if state == 1 and (neighbors < 2 or neighbors > 3) then
                    
                    self.buffer[y][x] = 0
                elseif state == 0 and neighbors == 3 then
                    
                    self.buffer[y][x] = 1
                else
                   
                    self.buffer[y][x] = state
                end
            end
        end
        self.cells, self.buffer = self.buffer, self.cells
        return self:getActiveCells()
    end
    
    function self:clear()
        for y = 1, self.height do
            for x = 1, self.width do
                self.cells[y][x] = 0
            end
        end
    end
    
    function self:randomize(density)
        density = density or 0.3
        for y = 1, self.height do
            for x = 1, self.width do
                if self.cells[y][x] == 0 then 
                    if math.random() < density then
                        self.cells[y][x] = 1
                    else
                        self.cells[y][x] = 0
                    end
                end
            end
        end
    end
    
    function self:glider(x, y)
        x = x or 2
        y = y or 2
        self:setCell(x+1, y, 1)
        self:setCell(x+2, y+1, 1)
        self:setCell(x, y+2, 1)
        self:setCell(x+1, y+2, 1)
        self:setCell(x+2, y+2, 1)
    end
    
    function self:blinker(x, y)
        x = x or math.floor(self.width / 2)
        y = y or math.floor(self.height / 2)
        self:setCell(x-1, y, 1)
        self:setCell(x, y, 1)
        self:setCell(x+1, y, 1)
    end
    
    function self:getActiveCells()
        local activeCells = {}
        for y = 1, self.height do
            for x = 1, self.width do
                if self.cells[y][x] == 1 then
                    table.insert(activeCells, {x, y})
                end
            end
        end
        return activeCells
    end
    
    function self:draw(cellSize, offsetX, offsetY)
        cellSize = cellSize or 10
        offsetX = offsetX or 0
        offsetY = offsetY or 0
        for y = 1, self.height do
            for x = 1, self.width do
                if self.cells[y][x] == 1 then
                    love.graphics.rectangle("fill", 
                        offsetX + (x-1) * cellSize, 
                        offsetY + (y-1) * cellSize, 
                        cellSize, cellSize)
                end
            end
        end
    end
    
    return self
end

return conway