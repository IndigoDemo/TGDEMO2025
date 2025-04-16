local e = {}
local w = _w
local h = _h
local shaderCode = [[
extern vec2 screenSize;
extern float time;
extern float noiseAmount;
extern float scanlineIntensity;
extern float resolution;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 pixelCoords = floor(screenCoords / resolution) * resolution;
    
    float noise = rand(pixelCoords + vec2(time * 100.0));
    
    vec4 texColor = Texel(texture, textureCoords);
    
    float scanline = sin(screenCoords.y * 0.7 + time) * 0.5 + 0.5;
    scanline = pow(scanline, 1.0) * scanlineIntensity;
    
    float verticalGlitch = 0.0;
    if (mod(time, 4.0) > 3.8) {
        verticalGlitch = step(0.5, rand(vec2(time))) * step(0.98, rand(vec2(screenCoords.y, time)));
    }
    
    vec4 staticColor = vec4(noise, noise, noise, 1.0);
    vec4 result = mix(texColor, staticColor, noiseAmount);
    
    float vignette = 1.0 - length((screenCoords / screenSize) - 0.5) * 0.2;
    
    result.r += 0.05 * sin(screenCoords.y * 0.1 + time);
    result.g += 0.03 * cos(screenCoords.y * 0.1 + time * 0.7);
    
    if (verticalGlitch > 0.0) {
        vec2 glitchOffset = vec2(sin(screenCoords.y * 0.01 + time * 10.0) * 10.0, 0.0);
        result = Texel(texture, textureCoords + glitchOffset * 0.01);
        result += vec4(0.1, 0.0, 0.0, 0.0);
    }
    
    return result * color * (scanline * 0.3 + 0.7) * vignette;
}
]]

e.config = {
    noiseAmount = 0.3,
    scanlineIntensity = 0.35,
    resolution = 4.0
}

function e.load()

    e.shader = love.graphics.newShader(shaderCode)
    
    e.canvas = love.graphics.newCanvas()
    e.finalcanvas = love.graphics.newCanvas()
    e.shader:send("screenSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    e.shader:send("noiseAmount", e.config.noiseAmount)
    e.shader:send("scanlineIntensity", e.config.scanlineIntensity)
    e.shader:send("resolution", e.config.resolution)
end

function e.update(dt)
    e.shader:send("time", love.timer.getTime())
    
    e.shader:send("noiseAmount", e.config.noiseAmount)
    e.shader:send("scanlineIntensity", e.config.scanlineIntensity)
    e.shader:send("resolution", e.config.resolution)
end

function e.draw()
    love.graphics.setCanvas(e.finalcanvas)
    love.graphics.clear()
    love.graphics.setShader(e.shader)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill",0,0,_w,_h)
    love.graphics.setShader()
    love.graphics.setCanvas()
end

function e.resize(w, h)
    e.canvas = love.graphics.newCanvas(w, h)
    e.shader:send("screenSize", {w, h})
end

function e.setNoiseAmount(amount)
    e.config.noiseAmount = math.max(0.0, math.min(1.0, amount))
end

function e.setScanlineIntensity(amount)
    e.config.scanlineIntensity = math.max(0.0, math.min(1.0, amount))
end

function e.setResolution(res)
    e.config.resolution = math.max(1.0, res)
end

return e