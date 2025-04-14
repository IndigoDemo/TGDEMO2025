local e = {}
local shader
local beatCanvas  
local canvasSize = 1024 
local useBloom = false
local internaltime = 0 
local brightness = 3    
local baseColorR = 1.0     
local baseColorG = 1.0    
local baseColorB = 1.0     
local beatDecay = 1.5     
local beatSpeed = 8.0    
local beatActive = 0.1  
local lastBeatTime = 0
local beatCooldown = 0.01  
local manualBeatTrigger = false 

local function updateBeatCanvas(intensity)
   
    love.graphics.setCanvas(beatCanvas)
    love.graphics.clear(0, 0, 0, 1)
    
    love.graphics.setColor(math.random()*intensity, math.random()*intensity, math.random()*intensity, 1)
    love.graphics.rectangle("fill", 0, 0, canvasSize, 1)
    
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)
end
local function initBeatCanvas()
    beatCanvas = love.graphics.newCanvas(canvasSize, 1)
    updateBeatCanvas(0)
end
function e.load()
    e.shader = love.graphics.newShader("/code/main.glsl")
    initBeatCanvas()
end
function e.update(dt, bfc)
    internaltime = internaltime + dt * bfc
    local currentTime = love.timer.getTime()
    beatActive = math.max(0, beatActive - beatDecay)
    updateBeatCanvas(beatActive)
    beatCooldown = math.max(0.01, 0.2 - beatActive * 0.1)
end

function e.draw()
    e.shader:send("iTime", internaltime)
    e.shader:send("iResolution", {width, height})
    e.shader:send("iChannel0", beatCanvas)
    e.shader:send("brightness", brightness)
    e.shader:send("baseColor", {baseColorR, baseColorG, baseColorB})
    e.shader:send("beatSpeed", beatSpeed)
end

return e