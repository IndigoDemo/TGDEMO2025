local e = {}


local refreshtimer = 0 
local floorCeilingShader = nil
local floorCeilingTexture = nil
local playerPos = {x = 0, z = 0}
local playerHeight = 0.5 
local playerAngle = 0
local moveSpeed = 2.0 
local turnSpeed = 2.0 
local FOV = math.pi / 3 
local BlinkingGrid = require("/code/grid")
local conway = require ("/code/conway")
local gridsize = {x=50,y=50}

function e.load()
    game = conway.new(gridsize.x, gridsize.y)
    game:randomize()
    updateTime = 0.01
    refreshTime = 10
    refreshtimer = 0 
    timer = 0.6

    grid = BlinkingGrid.new({
        rows = gridsize.x,
        cols = gridsize.y,
        tileSize = 15,
        gap = 1,
        cornerRadius = 2,
        blinkInterval = 0.01,
        fadeTime = 0.8
    })

        shaderCode = [[
        extern float time;
        extern float intensity;
        
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(tex, texture_coords);
            
            // Add a subtle wave distortion effect
            float distortionX = sin(texture_coords.y * 10.0 + time) * 0.06 * intensity;
            float distortionY = cos(texture_coords.x * 10.0 + time * 0.7) * 0.06 * intensity;
            vec2 newCoords = vec2(texture_coords.x + distortionX, texture_coords.y + distortionY);
            
            // Get the distorted pixel
            vec4 distortedPixel = Texel(tex, newCoords);
            
            // Blend between original and distorted based on brightness
            float brightness = (pixel.r + pixel.g + pixel.b) / 3.0;
            vec4 finalPixel = mix(pixel, distortedPixel, brightness * intensity);
            
            // Add a slight glow effect
            finalPixel.rgb += pixel.rgb * 0.7 * intensity;
            
            return finalPixel * color;
        }
    ]]
    
    e.shader = love.graphics.newShader(shaderCode)
    e.shaderIntensity = .01

   
    floorCeilingShader = love.graphics.newShader("/code/wall_ceiling_shader.glsl")
    updateShaderParams()
end

function updateShaderParams()
   
    floorCeilingShader:send("cameraPos", {playerPos.x, playerPos.z})
    floorCeilingShader:send("cameraHeight", playerHeight)
    floorCeilingShader:send("cameraAngle", playerAngle)  
    floorCeilingShader:send("fov", FOV)
    floorCeilingShader:send("aspect", love.graphics.getWidth() / love.graphics.getHeight())
    floorCeilingShader:send("floorMovement", {0, 0}) 
    floorCeilingShader:send("ceilingMovement", {0, 0})
    
   
    floorCeilingShader:send("floorTextureScale", 0.2) 
    floorCeilingShader:send("ceilingTextureScale", 0.2)
    
    -- Fog parameters
    floorCeilingShader:send("fogColor", {1.0, 1.0, 1.0}) 
    floorCeilingShader:send("fogDensity", 1.5)
    floorCeilingShader:send("maxFogDistance", 10.0)
end

function e.update(dt)

    playerPos.x = playerPos.x + math.cos(playerAngle + math.pi/2) * moveSpeed * dt
    playerPos.z = playerPos.z + math.sin(playerAngle + math.pi/2) * moveSpeed * dt
    playerAngle = playerAngle + (math.sin(global.time/3)*.3 - math.cos(global.time+1.8/4)*.3) * dt

    timer = timer + dt
    refreshtimer = refreshtimer + dt
    if refreshtimer >= refreshTime then 
        for i = 1, 10 do 
            local eks, jy = math.floor(math.random()*gridsize.x), math.floor(math.random()*gridsize.y)
            game:glider(eks, jy)
        end
        game:randomize(0.1)
        refreshtimer = 0 
    end
    if timer >= updateTime then
     
        pattern = game:update() or {}
       
        timer = 0
    end
    grid:update(dt, pattern)
    e.shader:send("time", love.timer.getTime())
    e.shader:send("intensity", e.shaderIntensity)
    e.canvas = love.graphics.newCanvas(grid.width+grid.gap, grid.height+grid.gap)
    e.outputcanvas = love.graphics.newCanvas()
    local x = (grid.width)
    local y = (grid.height)


   
    local floorMoveX = -playerPos.x * 0.1 
    local floorMoveZ = -playerPos.z * 0.1
    floorCeilingShader:send("floorMovement", {floorMoveX, floorMoveZ})
    
    
    floorCeilingShader:send("ceilingMovement", {floorMoveX * 0.5, floorMoveZ * 0.5})
    
   
    floorCeilingShader:send("cameraPos", {playerPos.x, playerPos.z})
    floorCeilingShader:send("cameraAngle", playerAngle)
end

function e.draw()
    love.graphics.setCanvas(e.canvas)
    love.graphics.clear()
    love.graphics.setShader(e.shader)
    grid:draw(x, y)
    love.graphics.setShader()
    love.graphics.setCanvas(e.outputcanvas)    

   
    love.graphics.setShader(floorCeilingShader)
    
    love.graphics.draw(e.canvas, 0, 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setShader()
    love.graphics.setCanvas()    

end




return e