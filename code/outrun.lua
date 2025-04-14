e = {}
local b = 0
local beats = false  
local time              = 0     -- these 2 are the same
local t                 = 0     -- but i'm an inconsistent bastard
local fontChars         = {}    -- Bitmap font characters
local fontPixelData     = {}    -- Bitmap data for row-by-row manipulation
local message           = "                        ELIX   EXCESS   OUTRACKS   KVASIGEN   ASD   SPACEBALLS   ZOMGTRONICS   DEVJEEPER   SCENESAT   ENITG   SUPERTED   MIU   SKURK   DUBMOOD   KB   PROTEQUE   SESSE   ZEILA   FREYA   ANDY   SANDSMARK   BIGZ   PETTEROEA   THE GATHERING CREW   LoVE GAME FRAMEWORK "
local scrollPos         = 0
local FontSpeed         = 305   -- pixels per second
local waveIntensity     = 20  
local waveSpeed         = 2
local vanishPointY      = 0.5   
local suncolor                = func.toRGB(255,108,17) -- returns table with rgb-values between 0-1
local bgcolor                 = func.toRGB(36,23,52)
local sunsize                 = 200
horizonY                = height / 2    -- Middle of the screen
local gridSize          = 150           -- Number of grid cells
local gridSpacing       = 20            -- Distance between grid points
local heightScale       = 100           -- Base height scale
local scrollSpeed       = 60            -- How fast the landscape updates
local valleyWidth       = gridSize * gridSpacing    -- Width of the landscape
local valleyCenter      = valleyWidth / 2           -- Center point of the valley
local valleyDepth       = 6             -- How much taller the edges are compared to center 
local worldZ            = 0
local sunheight         = .93
zmax                    = 0             -- helper vars for the wireframe effect
zmin                    = 0             -- same
ztarget                 = 0             -- same
----- Perlin Noise for heightmap
local noiseScale        = 0.1
noise.init(seed)

----- Landscape Lighting
local ambientLight      = 0.3 -- Light level (0-1)
local diffuseStrength   = 0.7 
local lightDir          = {x = 0.5, y = -1, z = 0.3} -- Direction of light
lightDir = func.normalize(lightDir) -- Normalize the vector
local wirecanvas = love.graphics.newCanvas()
----- Camera Inits
cameraHeight            = 0
cameraX                 = gridSize * gridSpacing / 2
cameraY                 = 80  -- Camera y position
local x
local y 
local i 
----- Arwing Inits
controls = {
        pitch = 0,  -- X rotation
        yaw = 0,    -- Y rotation
        roll = 0,   -- Z rotation
        x = 0,      -- X movement
        y = 0,      -- Y movement
        z = 0       -- Z movement
    }
camX, camY, camZ = 0, 0, -500
fov = math.pi / 3
aspect = love.graphics.getWidth() / love.graphics.getHeight()
near = 0.1
far = 10000
moveSpeed = 5
rotateSpeed = 0.05  

function loadLandscape()
    heightMap = {}
    for z = 1, gridSize do
        heightMap[z] = {}
        for x = 1, gridSize do
            heightMap[z][x] = generateHeight(x, z + worldZ)
        end
    end
    
     colors = { func.toRGB(13,25,15),--bottom
                func.toRGB(2,55,135),
                func.toRGB(101,13,137),
                func.toRGB(146,0,117),
                func.toRGB(246,0,157),
                func.toRGB(212,0,120), --top
                }
end

function setColorByHeight(height) -- these two are technically the same, but still very different 
    if height < -20 then
        love.graphics.setColor(colors[1])
    elseif height < 0 then
        love.graphics.setColor(colors[2])
    elseif height < 10 then
        love.graphics.setColor(colors[3])
    elseif height < 30 then
        love.graphics.setColor(colors[4])
    elseif height < 60 then
        love.graphics.setColor(colors[5])
    else
        love.graphics.setColor(colors[6])
    end
end

function getColorByHeight(height) -- this one returns stuff instead of setting them directly. fun stuff.
    if height < -20 then
        return colors[1][1], colors[1][2], colors[1][3]
    elseif height < 0 then
        return colors[2][1], colors[2][2], colors[2][3]
    elseif height < 10 then
        return colors[3][1], colors[3][2], colors[3][3]
    elseif height < 30 then
        return colors[4][1], colors[4][2], colors[4][3]
    elseif height < 60 then
        return colors[5][1], colors[5][2], colors[5][3]
    else
        return colors[6][1], colors[6][2], colors[6][3]
    end
end


function createBitmapFont() -- because ttf is for pussies
    fontPixelData = charData
    -- Convert each pixeldata into image
    for char, data in pairs(charData) do
        local imageData = love.image.newImageData(8, 8)
        for y = 1, 8 do
            for x = 1, 8 do
                local pixel = data[y]:sub(x, x)
                if pixel == "#" then
                    imageData:setPixel(x-1, y-1, 1, 1, 1, 1)  -- White pixel
                else
                    imageData:setPixel(x-1, y-1, 0, 0, 0, 0)  -- Transparent pixel
                end
            end
        end
        fontChars[char] = love.graphics.newImage(imageData)
    end
end

function e.drawBackground() -- pretty self-explanatory
    -- backdrop
    love.graphics.setColor(bgcolor) 
    love.graphics.rectangle("fill", 0,0,_w*3,_h)
    -- sun
    
    love.graphics.setColor(suncolor) 
    love.graphics.circle("fill", screenWidth*.5, screenHeight*sunheight, sunsize)
    
    -- sunstripes
    love.graphics.setColor(bgcolor)
    love.graphics.rectangle("fill", 0,screenHeight*.43, screenWidth*2,5)
    love.graphics.rectangle("fill", 0,screenHeight*.45, screenWidth*2,9)
    love.graphics.rectangle("fill", 0,screenHeight*.47, screenWidth*2,13)
    love.graphics.rectangle("fill", 0,screenHeight*.495, screenWidth*2,20)
   
    -- mask under horizon for wireframe purposes
    love.graphics.rectangle("fill", 0,screenHeight*.55, screenWidth,screenHeight)
end

function e.drawScroller() -- hacks the NSA mainframe
    local charWidth         = 32  
    local charHeight        = 32  
    local baseY             = screenHeight*(math.sin(time)*.5) + screenHeight*.5 - charHeight / 2
    local visibleChars      = math.ceil(screenWidth / charWidth) + 2
    local startCharIndex    = math.floor(scrollPos / charWidth) + 1
    local xOffset           = -(scrollPos % charWidth) 

    -- scan trough the message and draw accordingly         
    for i = 0, visibleChars - 1 do
        local charIndex = ((startCharIndex + i - 1) % #message) + 1
        local char = message:sub(charIndex, charIndex)
        baseY = screenHeight*(math.sin(time+charIndex)*math.sin(time)*.02) + screenHeight*.3 - charHeight / 2
        if not fontPixelData[char] then goto continue end        
        local x = xOffset + i * charWidth 

        -- Rainbow road effect
        local colorPhase = (time * 0.5 + (x / 120)) % 1
        local r, g, b
        
        if colorPhase < 0.2 then
            -- Red to Yellow
            r = 1
            g = colorPhase * 5
            b = 0
        elseif colorPhase < 0.4 then
            -- Yellow to Green
            r = 1 - (colorPhase - 0.2) * 5
            g = 1
            b = 0
        elseif colorPhase < 0.6 then
            -- Green to Cyan
            r = 0
            g = 1
            b = (colorPhase - 0.4) * 5
        elseif colorPhase < 0.8 then
            -- Cyan to Blue
            r = 0
            g = 1 - (colorPhase - 0.6) * 5
            b = 1
        else
            -- Blue to Magenta
            r = (colorPhase - 0.8) * 5
            g = 0
            b = 1
        end
   
        love.graphics.setColor(r, g, b, 1)
    
        --draw chars
        for row = 1, 8 do
            local waveOffset = math.sin((time * waveSpeed) + (x / 40.0) + (row * 0.2)) * waveIntensity
            local rowData = fontPixelData[char][row]
            for col = 1, 8 do
                if rowData:sub(col, col) == "#" then
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.rectangle("fill",math.floor(x + (col - 1) * 4) * 2 , math.floor(baseY + (row - 1) * 4 + waveOffset), 9, 6 * (charWidth/32),5,5)
                    love.graphics.setColor(r, g, b, 1)
                    love.graphics.rectangle("fill",math.floor(x + (col - 1) * 4) * 2 +1, math.floor(baseY + (row - 1) * 4 + waveOffset)+1, 8, 5 * (charWidth/32),5,5)
                end
            end
        end        
    -- i really love the way lua handles labels. looks totally out of place compared to the rest of the syntax
    ::continue::
    end
end

function e.drawLandscape()
    for z = gridSize - 1, 1, -1 do -- depth-loop going from back to front because z-buffers are hard
        for x = 1, gridSize - 1 do -- looping the x-axis 
            local wx1       = x * gridSpacing
            local wz1       = z * gridSpacing
            local wx2       = (x + 1) * gridSpacing
            local wz2       = (z + 1) * gridSpacing
            local hy1       = heightMap[z][x]
            local hy2       = heightMap[z][x+1]
            local hy3       = heightMap[z+1][x+1]
            local hy4       = heightMap[z+1][x]
            local v1        = {x = wx1 - cameraX, y = hy1, z = wz1}
            local v2        = {x = wx2 - cameraX, y = hy2, z = wz1}
            local v3        = {x = wx2 - cameraX, y = hy3, z = wz2}
            local v4        = {x = wx1 - cameraX, y = hy4, z = wz2}
            local x1, y1    = func.project3Dto2D(v1.x, v1.y, v1.z)
            local x2, y2    = func.project3Dto2D(v2.x, v2.y, v2.z)
            local x3, y3    = func.project3Dto2D(v3.x, v3.y, v3.z)
            local x4, y4    = func.project3Dto2D(v4.x, v4.y, v4.z)
            local avgHeight = (hy1 + hy2 + hy3 + hy4) *.25 
            local normal1   = func.calculateNormal(v1, v2, v3)
            local normal2   = func.calculateNormal(v1, v3, v4)
            local light1    = ambientLight + diffuseStrength * math.max(0, 
                normal1.x * lightDir.x + normal1.y * lightDir.y + normal1.z * lightDir.z)
            local light2    = ambientLight + diffuseStrength * math.max(0, 
                normal2.x * lightDir.x + normal2.y * lightDir.y + normal2.z * lightDir.z)
            light1          = math.min(1, math.max(ambientLight, light1))
            light2          = math.min(1, math.max(ambientLight, light2))
            -- wireframe effect
            local r,g,b --local color vars for green to white wireframe fade  
            if z > zmax and z < zmin and t > 3.5 then -- within the wireframe clamp
                r = 0
                g = 1
                b = 0
                love.graphics.setLineWidth( 1 )
                love.graphics.setColor(r , g, b )
                love.graphics.polygon("line", x1, y1, x2, y2, x3, y3)
                love.graphics.setColor(r , g , b)
                love.graphics.polygon("line", x1, y1, x3, y3, x4, y4)
                
            else -- outside the wireframe clamp. let's draw some boring flat shaded polys instead
                r, g, b = getColorByHeight(avgHeight)
                love.graphics.setColor(r * light1, g * light1, b * light1)
                love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3)
                love.graphics.setColor(r * light2, g * light2, b * light2)
                love.graphics.polygon("fill", x1, y1, x3, y3, x4, y4)
                love.graphics.setColor(0,0,0)
            end
        end

        -- clamp the area for the wireframe between 2 z-points
        zmax = gridSize * ztarget 
        zmin = gridSize * ztarget + 8
    end
    if beat then 
        ztarget = 1
    end 
    -- wrap wireframe target value
    ztarget = ztarget - 5 * global.delta
    if ztarget < -.2 then ztarget = -.2 end
    
    -- make shit happen on beat
    if beat then 
        sunsize = 300
        glimit = 255
        blimit = 255
    else
        -- ease values back to default (temporary easing function)
        if glimit then 
            if sunsize > 200 then 
                sunsize = sunsize - func.diff(300,200)*.1
            end
            if glimit > 108 then 
                glimit = glimit - func.diff(255,108)*.1
            end
            if blimit > 17 then 
                blimit = blimit - func.diff(255,108)*.1 
            end
            suncolor = func.toRGB(255,glimit,blimit)
        end
    end
end

function e.drawShips()
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
    ship:draw()
    love.graphics.pop()
end

function updateShips(dt)
    local dtf = dt * 60
    controls.pitch  = 3.1415 + .4 + math.cos(t)*.2 
    controls.yaw    = math.cos(t)*.2
    controls.roll   = math.cos(t)*.3 
    controls.x      = math.sin(t)*60 
    controls.y      = 80 + math.cos(t)*20 
    controls.z      = 0
    ship:update(dt, controls)
end

function getHeightMultiplier(x)
    local distFromCenter = math.abs(x * gridSpacing - valleyCenter) / (valleyWidth / 2)
    local multiplier = distFromCenter * valleyDepth
    local minHeight = 0.3
    return minHeight + multiplier
end

function generateHeight(x, z)
    local baseHeight = noise.perlin2((x * noiseScale), (z * noiseScale)) * heightScale
    local multiplier = getHeightMultiplier(x)
    return baseHeight * multiplier
end

function e.load()
    
    ship            = Arwing.new()
    love.graphics.setLineWidth( 3 ) -- thicc(er) lines
    screenWidth = _w
    screenHeight = _h
    loadLandscape()
    createBitmapFont()

    -- create framebuffers for selective shader manipulation
    background      = love.graphics.newCanvas()
    landscape       = love.graphics.newCanvas()
    scroller        = love.graphics.newCanvas()
    shiplayer       = love.graphics.newCanvas()
    -- wrap screen resolution into table and send to shader
    res      = {_w,_h} 
end

function e.update(dt, beats, pbeat)
    t=t+dt -- accumulated time
    delta=dt --deltatime

    if pbeat > 159 then 
        suntop = .95
        d=func.diff(suntop, sunheight)
        if sunheight < suntop then 
            sunheight = sunheight + d/20
         end   
    end
    
    if pbeat > 128 and pbeat < 159 then 
        if beats then 
        	beat = true 
        else beat = false 
        end 
    end

    if pbeat > 125 and pbeat < 159 then 
        suntop = .45
        d = func.diff(suntop,sunheight) 
        if sunheight > suntop then 
            sunheight = sunheight - d/100
        end
    end

    updateShips(dt)

    scrollPos = scrollPos + FontSpeed * dt
    time = time + dt
    if scrollPos > #message * 32 then
        scrollPos = 0
    end
    
    cameraX = gridSize * gridSpacing / 2 + (math.sin(t)*100)
    worldZ = worldZ + scrollSpeed * dt
    table.remove(heightMap, 1) 
    local newRow = {}
    for x = 1, gridSize do
        newRow[x] = generateHeight(x, gridSize + worldZ)
    end
    table.insert(heightMap, newRow) 
end

function e.draw()
    local sine = math.sin(time/10)
    love.graphics.setCanvas(background)
    love.graphics.clear()
    drawBackground()
    love.graphics.setCanvas(landscape)
    love.graphics.clear()
    bloomEffect3:apply(background)
    drawLandscape()
    love.graphics.setCanvas(shiplayer)
    love.graphics.clear()
    bloomEffect4:apply(landscape)
    drawShips()
    love.graphics.setCanvas(scroller)
    love.graphics.clear()
    drawScroller()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setCanvas()
    love.graphics.clear()
    love.graphics.setShader(shader.vhs)
    love.graphics.draw(landscape, screenWidth/2, screenHeight/2, sine*.19, 1.35, 1.35, screenWidth/2, screenHeight/2)
    love.graphics.draw(shiplayer, screenWidth/2, screenHeight/2, sine*.19, 1.35, 1.35, screenWidth/2, screenHeight/2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader()
    love.graphics.draw(scroller, 0, screenHeight*-.7, 0, 2, 4)
end

return e 