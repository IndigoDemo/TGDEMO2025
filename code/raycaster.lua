-- raycaster.lua
local Raycaster = {}
-- Add fog configuration to the top of the file
local fogColor = {0.5, .6, .55}  -- Bluish-gray fog
local fogDensity = 0.1            -- Adjust for more/less fog
local Fovangle = 90
-- Configuration
local screenWidth, screenHeight = love.graphics.getDimensions()
local fov = Fovangle * math.pi/180
local maxDistance = 20.0
local maxRaySteps = 100  -- Add maximum steps for ray casting to prevent infinite loops

-- Camera/player state
local position = {x = 2.5, y = 2.5}
local direction = {x = 1, y = 0}
local plane = {x = 0, y = 0.66}

-- Textures
local textures = {}
local textureSize = 512

-- Map (can be any size)
local map = {
    {1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,1},
    {1,0,1,0,0,1,0,1},
    {1,0,1,0,0,1,0,1},
    {1,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1}
}

-- Debug variables
local debugMode = false
local lastFrameTime = 0

-- Initialize the raycaster
function Raycaster.init()
    -- Load textures
   -- textures[1] = love.graphics.newImage("wall.png")
   -- textures[2] = love.graphics.newImage("floor.png")
   -- textures[3] = love.graphics.newImage("ceiling.png")
    
-- Create shader for walls with proper texture scaling and fog effect

    
-- Create proper floor/ceiling shader with perspective-correct mapping and fog
Raycaster.floorShader = love.graphics.newShader[[
uniform Image mainTexture;
uniform Image bumpTexture;
uniform Image reflectionTexture;
uniform vec2 playerPos;
uniform vec2 playerDir;
uniform vec2 playerPlane;
uniform float screenHeight;
uniform float screenWidth;
uniform bool isCeiling;
uniform vec3 fogColor;
uniform float fogDensity;
uniform vec3 lightDir;
uniform float reflectionStrength;
uniform float time;  // New uniform to track time for potential animated effects

vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord) {
    // Calculate ray direction for the floor/ceiling
    float cameraX = 2.0 * screenCoord.x / screenWidth - 1.0;
    
    // Ray direction for leftmost ray
    float rayDirX0 = playerDir.x - playerPlane.x;
    float rayDirY0 = playerDir.y - playerPlane.y;
    
    // Ray direction for rightmost ray
    float rayDirX1 = playerDir.x + playerPlane.x;
    float rayDirY1 = playerDir.y + playerPlane.y;
    
    // Current y position compared to the center of the screen (horizon)
    float p;
    if (isCeiling) {
        // For ceiling, invert the vertical position
        p = screenHeight / 2.0 - screenCoord.y;
    } else {
        // For floor
        p = screenCoord.y - screenHeight / 2.0;
    }
    
    // Vertical position of the camera
    float posZ = 0.5 * screenHeight;
    
    // Horizontal distance from the camera to the floor/ceiling for the current row
    float rowDistance = posZ / p;
    
    // Calculate the real world step vector for one screen pixel
    float floorStepX = rowDistance * (rayDirX1 - rayDirX0) / screenWidth;
    float floorStepY = rowDistance * (rayDirY1 - rayDirY0) / screenWidth;
    
    // Real world coordinates of the leftmost column
    float floorX = playerPos.x + rowDistance * rayDirX0;
    float floorY = playerPos.y + rowDistance * rayDirY0;
    
    // Add to the current position the step multiplied by the x-coordinate
    floorX += floorStepX * screenCoord.x;
    floorY += floorStepY * screenCoord.x;
    
    // Get the texture coordinates from the world coordinates
    vec2 floorTexCoord = vec2(
        mod(floorX * 64.0, 64.0) / 64.0,
        mod(floorY * 64.0, 64.0) / 64.0
    );
    
    // Sample the main texture
    vec4 texColor = Texel(mainTexture, floorTexCoord);
    
    // Sample the bump map
    vec4 bumpColor = Texel(bumpTexture, floorTexCoord);
    
    // Create dynamic reflection coordinates based on player position and direction
    vec2 reflectionTexCoord = vec2(
        // Use player direction to skew the reflection
        floorTexCoord.x + playerDir.x * 0.5 + 
        // Add some world position influence
        floorX * 0.1 + 
        // Slight bump map distortion
        (bumpColor.r - 0.5) * 0.1,
        
        floorTexCoord.y + playerDir.y * 0.5 + 
        floorY * 0.1 + 
        (bumpColor.g - 0.5) * 0.1
    );
    
    // Sample the reflection texture with dynamic coordinates
    vec4 reflectionColor = Texel(reflectionTexture, reflectionTexCoord);
    
    // Calculate bump mapping effect
    vec3 surfaceNormal = normalize(bumpColor.rgb * 5.0 - 1.0);
    float lightIntensity = max(dot(surfaceNormal, normalize(lightDir)), 0.0);
    
    // Blend main texture with reflection
    vec3 baseColor = texColor.rgb * (0.5 + 0.5 * lightIntensity);
    vec3 reflectedColor = mix(baseColor, reflectionColor.rgb, reflectionStrength);
    
    // Calculate fog factor based on distance
    float fogFactor = 1.0 - exp(-fogDensity * rowDistance);
    fogFactor = clamp(fogFactor, 0.0, 1.0);
    
    // Mix the reflected color with the fog color
    vec3 finalColor = mix(reflectedColor, fogColor, fogFactor);
    
    return vec4(finalColor, texColor.a) * color;
}
]]



end

function angleToDirection(angleRadians)
    local direction = {}
    direction.x = math.cos(angleRadians)
    direction.y = math.sin(angleRadians)
    return direction
end

function angleToCameraPlane(angleRadians, fov)
    local plane = {}
    -- Perpendicular vector (rotated 90 degrees)
    plane.x = -math.sin(angleRadians) * fov
    plane.y = math.cos(angleRadians) * fov
    return plane
end

-- Update player position and camera
function Raycaster.update(dt, x, y, ang, fieldofview)
    local px = x
    local py = y
    local angle = ang 
    local fieldofview = fieldofview
    position.x = px 
    position.y = py 
    direction = angleToDirection(ang)
    plane = angleToCameraPlane(ang, fieldofview)
end

-- Render the scene
function Raycaster.draw()
    -- Draw floor and ceiling with simple color if performance is an issue
    if debugMode then
        -- Simple colored floor/ceiling for debugging
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", 0, screenHeight/2, screenWidth, screenHeight/2)
        love.graphics.setColor(0.4, 0.6, 0.8)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight/2)
        love.graphics.setColor(1, 1, 1)
    else
        -- Draw floor and ceiling with shader
       love.graphics.setShader(Raycaster.floorShader)
        Raycaster.floorShader:send("playerPos", {position.x, position.y})
        Raycaster.floorShader:send("playerDir", {direction.x, direction.y})
        Raycaster.floorShader:send("playerPlane", {plane.x, plane.y})
        Raycaster.floorShader:send("screenHeight", screenHeight)
        Raycaster.floorShader:send("screenWidth", screenWidth)
        Raycaster.floorShader:send("fogColor", fogColor)
        Raycaster.floorShader:send("fogDensity", fogDensity)

        -- Draw floor
        Raycaster.floorShader:send("isCeiling", false)
        Raycaster.floorShader:send("mainTexture", textures[2])
        --Raycaster.floorShader:send("reflectionTexture", textures[3])
        Raycaster.floorShader:send("reflectionStrength", .2)
        Raycaster.floorShader:send("bumpTexture", textures[4])
        Raycaster.floorShader:send("lightDir", {1.0, 1.0, 2.0}) 
        love.graphics.rectangle("fill", 0, screenHeight/2, screenWidth, screenHeight/2)

        -- Draw ceiling
        Raycaster.floorShader:send("isCeiling", true)
        Raycaster.floorShader:send("mainTexture", textures[1])
        Raycaster.floorShader:send("bumpTexture", textures[1])
        Raycaster.floorShader:send("lightDir", {1.0, 1.0, 1.0}) 
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight/2)
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setShader()
    
    -- Draw FPS counter
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    if debugMode then
        love.graphics.print("Position: " .. string.format("%.2f, %.2f", position.x, position.y), 10, 30)
        love.graphics.print("Direction: " .. string.format("%.2f, %.2f", direction.x, direction.y), 10, 50)
        love.graphics.print("Debug Mode: ON - Press F1 to toggle", 10, 70)
    end
end

-- Set the map
function Raycaster.setMap(newMap)
    map = newMap
end

-- Set player position
function Raycaster.setPosition(x, y)
    position.x = x
    position.y = y
end

-- Set player direction
function Raycaster.setDirection(x, y)
    direction.x = x
    direction.y = y
    -- Recalculate plane based on direction to maintain FOV
    plane.x = -direction.y * 0.66
    plane.y = direction.x * 0.66
end

-- Load textures
function Raycaster.loadTextures(wallTex, floorTex, ceilingTex)
    textures[1] = love.graphics.newImage(wallTex or "ceiling.png")
    textures[2] = love.graphics.newImage(floorTex or "floor.png")
    textures[3] = love.graphics.newImage(ceilingTex or "env.png")
    textures[4] = love.graphics.newImage(ceilingTex or "noise.png")
end

-- Toggle debug mode
function Raycaster.toggleDebug()
    debugMode = not debugMode
    return debugMode
end

return Raycaster