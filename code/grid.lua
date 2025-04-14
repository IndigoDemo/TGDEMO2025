
local BlinkingGrid = {}
BlinkingGrid.__index = BlinkingGrid

function BlinkingGrid.new(options)
    local self = setmetatable({}, BlinkingGrid)
    
    options = options or {}
    self.rows = options.rows or 6
    self.cols = options.cols or 6
    self.tileSize = options.tileSize or 60
    self.gap = options.gap or 10
    self.cornerRadius = options.cornerRadius or 10
    self.blinkInterval = options.blinkInterval or 1.0
    self.fadeTime = options.fadeTime or 1.2

    self.width = self.cols * (self.tileSize + self.gap) - self.gap
    self.height = self.rows * (self.tileSize + self.gap) - self.gap
    
    self.x = options.x or 0
    self.y = options.y or 0

    self.colors = {
        {0.8, 0.2, 0.2},  -- Red
        {1.0, 0.5, 0.0},  -- Orange
        {0.9, 0.9, 0.0},  -- Yellow
        {0.0, 0.8, 0.2},  -- Green
        {0.0, 0.7, 0.9},  -- Cyan
        {0.3, 0.3, 1.0},  -- Blue
        {0.7, 0.2, 0.9},  -- Purple
        {0.9, 0.3, 0.7},  -- Pink
    }

    self.baseColor = {0.01, 0.01, 0.01}
 
    self.flashColor = {1, 1, 1}

    self.tiles = {}
    for r = 1, self.rows do
        self.tiles[r] = {}
        for c = 1, self.cols do
            self.tiles[r][c] = {
                color = {unpack(self.baseColor)},
                active = false,
                fadeProgress = 0,
                flashProgress = 0
            }
        end
    end
 
    self.timer = 0
    self.patternIndex = 7
    
    self.canvas = love.graphics.newCanvas(self.width + self.gap, self.height + self.gap)
    
    self.patterns = {
        function (self, activerow)
            for i = 1, self.rows do 
                self:blinkTile(i, activerow)
            end
        end,

        -- Diagonal pattern
        function(self)
            for i = 1, self.rows do
                self:blinkTile(i, i)
            end
        end,
        
        -- X pattern
        function(self)
            for i = 1, self.rows do
                self:blinkTile(i, i)
                self:blinkTile(i, self.cols - i + 1)
            end
        end,
        
        -- Spiral pattern
        function(self)
            local center = math.ceil(self.rows / 2)
            for radius = 1, 3 do
                for i = -radius, radius do
                    self:blinkTile(center + i, center - radius)
                    self:blinkTile(center + i, center + radius)
                    self:blinkTile(center - radius, center + i)
                    self:blinkTile(center + radius, center + i)
                end
            end
        end,
        
        -- Random cluster
        function(self)
            local centerR = love.math.random(2, self.rows-1)
            local centerC = love.math.random(2, self.cols-1)
            
            self:blinkTile(centerR, centerC)
            self:blinkTile(centerR-1, centerC)
            self:blinkTile(centerR+1, centerC)
            self:blinkTile(centerR, centerC-1)
            self:blinkTile(centerR, centerC+1)
        end,
        
        -- Checkerboard
        function(self)
            for r = 1, self.rows do
                for c = 1, self.cols do
                    if (r + c) % 2 == 0 then
                        self:blinkTile(r, c)
                    end
                end
            end
        end,
        
        -- Row by row
        function(self)
            local row = love.math.random(1, self.rows)
            for c = 1, self.cols do
                self:blinkTile(row, c)
            end
        end,
        
        -- Column by column
        function(self)
            local col = love.math.random(1, self.cols)
            for r = 1, self.rows do
                self:blinkTile(r, col)
            end
        end
    }
    
    return self
end

function BlinkingGrid:update(dt, paddern, therow)
    local pattern = pattern
    for r = 1, self.rows do
        for c = 1, self.cols do
            local tile = self.tiles[r][c]
            
            if tile.active then
                if tile.flashProgress > 0 then
                    tile.flashProgress = tile.flashProgress - dt / (self.fadeTime * 0.3)
                    if tile.flashProgress <= 0 then
                        tile.flashProgress = 0
                    end
                    
                    for i = 1, 3 do
                        tile.color[i] = self.flashColor[i] * tile.flashProgress + 
                                        tile.activeColor[i] * (1 - tile.flashProgress)
                    end
                else
                    tile.fadeProgress = tile.fadeProgress - dt / self.fadeTime
                    if tile.fadeProgress <= 0 then
                        tile.fadeProgress = 0
                        tile.active = false
                    end
                    
                    for i = 1, 3 do
                        tile.color[i] = tile.activeColor[i] * tile.fadeProgress + 
                                        self.baseColor[i] * (1 - tile.fadeProgress)
                    end
                end
            end
        end
    end
    
    self.timer = self.timer + dt
    if self.timer >= self.blinkInterval then
        self.timer = 0
        
        if paddern then 
            if not therow then
             for i = 1, #paddern do
                self:blinkTile(paddern[i][1], paddern[i][2], nil, true)
               end
          else
          end      
        end
    end
    
    self:updateCanvas()
end

function BlinkingGrid:blinkPattern(i, row)
    self.patterns[i](self)
end

function BlinkingGrid:blinkRandom(count)
    count = count or 1
    
    for i = 1, count do
        local r = love.math.random(1, self.rows)
        local c = love.math.random(1, self.cols)
        self:blinkTile(r, c)
    end
end

function BlinkingGrid:blinkTile(row, col, color, noflash)
    if row < 1 or row > self.rows or col < 1 or col > self.cols then
        return
    end
    
    local tile = self.tiles[row][col]
    tile.active = true
    tile.fadeProgress = 1.0
    if noflash then 
        tile.flashProgress = 0.0
    else
        tile.flashProgress = 1.0
    end
  
    if color then 
     colorIdx = color
    else
     colorIdx = love.math.random(1, #self.colors)
    end
    tile.activeColor = {unpack(self.colors[colorIdx])}
    tile.color = {unpack(self.flashColor)} 
end

function BlinkingGrid:updateCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    for r = 1, self.rows do
        for c = 1, self.cols do
            local tile = self.tiles[r][c]
            
         
            local x = (c - 1) * (self.tileSize + self.gap)
            local y = (r - 1) * (self.tileSize + self.gap)
            
           
            love.graphics.setColor(tile.color,1)
            love.graphics.rectangle(
                "fill", 
                x, y, 
                self.tileSize, self.tileSize, 
                self.cornerRadius, self.cornerRadius
            )
        end
    end
    
    love.graphics.setCanvas()
end

function BlinkingGrid:draw(x, y)
    x = x or self.x
    y = y or self.y
    
    love.graphics.setColor(1, 1, 1,1)
    love.graphics.draw(self.canvas, x, y)
end

function BlinkingGrid:getCanvas()
    return self.canvas
end

return BlinkingGrid