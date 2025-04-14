local e = {}

local SphereInterior = require("/code/sphere")
local BlinkingGrid = require("/code/grid")
local conway = require ("/code/conway")
local Tube = require("/code/tube")
local sintimer = 0 
local canvas
local pattern 
local gridsize = {x=80,y=45}
local torusEffect
local insideTexture
local game
local updateTime
local refreshtimer
local timer 
local canvas 
local grid 
local state = {
   
    tubeRadius = 21.9,
    curvatureRadius = 237.0,
    curvatureFactor = 0.32,
    fov = 100.0,
    
   
    cameraPos = {x = 36.4, y = 16.5, z = -78.9},
    cameraTarget = {x = 63.9, y = 9.8, z = -79.8},
    rotation = {x = 0, y = 0, z = 0},
    
   
    moveSpeed = 50, -- units per second
    lookSpeed = 0.003, -- radians per pixel
    isInsideView = true, -- toggle between inside and outside view
  
    mouseLocked = false,
    mouseDelta = {x = 0, y = 0},
    lastMousePos = {x = 0, y = 0},
  
    textureScrollSpeed = {x = 3.6, y = -0.05},
    showHUD = true,
}

function e.load()
    game = conway.new(gridsize.x, gridsize.y)
    game:randomize()
    updateTime = 0.1
    refreshTime = 10
    refreshtimer = 0 
    timer = 0.6

    torusEffect = Tube.new()
    torusEffect:setTubeRadius(state.tubeRadius)
    torusEffect:setCurvatureRadius(state.curvatureRadius)
    torusEffect:setCurvatureFactor(state.curvatureFactor)
    torusEffect:setFOV(state.fov)
    torusEffect:setCameraPosition(state.cameraPos.x, state.cameraPos.y, state.cameraPos.z)
    torusEffect:setCameraTarget(state.cameraTarget.x, state.cameraTarget.y, state.cameraTarget.z)
    torusEffect:setLookAtTarget(true)
    torusEffect:setScrollSpeed(state.textureScrollSpeed.x, state.textureScrollSpeed.y)
    
        grid = BlinkingGrid.new({
        rows = gridsize.x,
        cols = gridsize.y,
        tileSize = 30,
        gap = 2,
        cornerRadius = 2,
        blinkInterval = 0.1,
        fadeTime = 0.2
    })

        local shaderCode = [[
        extern float time;
        extern float intensity;
        
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(tex, texture_coords);
            
          
            float distortionX = sin(texture_coords.y * 10.0 + time) * 0.06 * intensity;
            float distortionY = cos(texture_coords.x * 10.0 + time * 0.7) * 0.06 * intensity;
            vec2 newCoords = vec2(texture_coords.x + distortionX, texture_coords.y + distortionY);
            
          
            vec4 distortedPixel = Texel(tex, newCoords);
            
          
            float brightness = (pixel.r + pixel.g + pixel.b) / 3.0;
            vec4 finalPixel = mix(pixel, distortedPixel, brightness * intensity);
            
          
            finalPixel.rgb += pixel.rgb * 0.7 * intensity;
            
            return finalPixel * color;
        }
    ]]
    
    e.shader = love.graphics.newShader(shaderCode)
    e.shaderIntensity = .01
    e.canvas = love.graphics.newCanvas(grid.width+grid.gap, grid.height+grid.gap)
    e.bloomcanvas = love.graphics.newCanvas()
    e.spherecanvas = love.graphics.newCanvas()
    e.tubecanvas = love.graphics.newCanvas()
    sphereEffect = SphereInterior.new()
    sphereEffect:setRadius(500.0)
    sphereEffect:setCameraPosition(100, 0, 300)
    
end

function e.setSphereCam(x,y,z)
    sphereEffect:setCameraPosition(x, y, z)
end

function e.update(dt, sphfov, sxr, syr, szr)
    local fov = sphfov or 90
    
    sintimer = sintimer + dt
    timer = timer + dt
    refreshtimer = refreshtimer + dt
  	
  	sphereEffect:setFOV(fov)
  	
    torusEffect:setCameraPosition(state.cameraPos.x+math.sin(sintimer)*2, state.cameraPos.y+math.cos(sintimer)*2, state.cameraPos.z)
  
    if refreshtimer >= refreshTime then 
        game:randomize(0.2)
        refreshtimer = 0 
    end
    if timer >= updateTime then
        pattern = game:update() or {}
       
        timer = 0
    end
   
    torusEffect:update(dt)
    local tile = math.floor(math.random()*90)
    
    grid:update(dt)
    e.shader:send("time", love.timer.getTime())
    e.shader:send("intensity", e.shaderIntensity)
    
    local x = (grid.width)
    local y = (grid.height)
    local time = love.timer.getTime()
    torusEffect:setScrollSpeed(math.sin(time)*0.1,-0.2)
    sphereEffect:setRotation(sxr, syr, szr)
end

function e.blink(x,y, color)
        grid:blinkTile(x,y, color)
end

function e.draw(arg)
    love.graphics.clear()
    love.graphics.setCanvas(e.canvas)
    love.graphics.clear()
    love.graphics.setShader(e.shader)
    grid:draw(x, y)
    love.graphics.setShader()
    
    love.graphics.setCanvas(e.spherecanvas)
    love.graphics.clear()
    if arg == "sphere" then 
        sphereEffect:draw(e.canvas)
    else
        torusEffect:draw(e.canvas) 
    end
    love.graphics.setCanvas()
end

return e