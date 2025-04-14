
local shaderCode = [[
// Bloom shader with RGB range selection
extern vec3 minColor = vec3(0.7, 0.7, 0.7); // Minimum RGB to bloom
extern vec3 maxColor = vec3(1.0, 1.0, 1.0); // Maximum RGB to bloom
extern number threshold = 0.5;     // Brightness threshold
extern number intensity = 1.5;     // Bloom intensity
extern number radius = 2.0;        // Bloom radius

// Check if a color is within the specified range
bool inRange(vec3 color) {
    return color.r >= minColor.r && color.r <= maxColor.r && 
           color.g >= minColor.g && color.g <= maxColor.g && 
           color.b >= minColor.b && color.b <= maxColor.b;
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    // Sample the original color
    vec4 original = Texel(tex, tc);
    
    // Extract just the colors in range for blooming
    vec4 bloomExtract = original;
    if (!inRange(original.rgb)) {
        bloomExtract = vec4(0.0, 0.0, 0.0, original.a);
    }
    
    // Apply threshold
    float brightness = dot(bloomExtract.rgb, vec3(0.2126, 0.7152, 0.0722));
    if (brightness < threshold) {
        bloomExtract = vec4(0.0, 0.0, 0.0, bloomExtract.a);
    }
    
    return bloomExtract;
}
]]

local blurH = [[
extern number radius = 5.0;
extern number blurScale = 1.0; // Controls blur intensity

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 sum = vec4(0.0);
    vec2 texSize = vec2(love_ScreenSize.xy);
    vec2 texelSize = vec2(1.0) / texSize;
    float weightSum = 0.0;
    
    // Gaussian distribution for weights
    for (float i = -radius; i <= radius; i++) {
        float weight = exp(-(i*i) / (2.0 * blurScale * blurScale));
        weightSum += weight;
        vec2 offset = vec2(i * texelSize.x, 0.0);
        sum += Texel(tex, tc + offset) * weight;
    }
    
    return sum / weightSum;
}
]]

local blurV = [[
extern number radius = 5.0;
extern number blurScale = 1.0; // Controls blur intensity

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 sum = vec4(0.0);
    vec2 texSize = vec2(love_ScreenSize.xy);
    vec2 texelSize = vec2(1.0) / texSize;
    float weightSum = 0.0;
    
    // Gaussian distribution for weights
    for (float i = -radius; i <= radius; i++) {
        float weight = exp(-(i*i) / (2.0 * blurScale * blurScale));
        weightSum += weight;
        vec2 offset = vec2(0.0, i * texelSize.y);
        sum += Texel(tex, tc + offset) * weight;
    }
    
    return sum / weightSum;
}
]]

local combine = [[
extern number intensity = 1.5;
extern Image bloomTexture;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec4 original = Texel(tex, tc);
    vec4 bloom = Texel(bloomTexture, tc);
    
    // Add bloom to original with intensity
    return original + (bloom * intensity);
}
]]

local Bloom = {}

function Bloom:new(width, height)
    local bloom = {
        width = width or love.graphics.getWidth(),
        height = height or love.graphics.getHeight(),
        minColor = {0.7, 0.7, 0.7},
        maxColor = {1.0, 1.0, 1.0},
        threshold = 0.5,
        intensity = 1.5,
        radius = 5.0,
        blurScale = 2.0,      
        downscaleFactor = 2,  -- Downscale for better blur performance
    }
    
    bloom.extractShader = love.graphics.newShader(shaderCode)
    bloom.blurHShader = love.graphics.newShader(blurH)
    bloom.blurVShader = love.graphics.newShader(blurV)
    bloom.combineShader = love.graphics.newShader(combine)
    
    local downWidth = math.floor(bloom.width / bloom.downscaleFactor)
    local downHeight = math.floor(bloom.height / bloom.downscaleFactor)
    
    bloom.extractCanvas = love.graphics.newCanvas(bloom.width, bloom.height)
    bloom.downscaledCanvas = love.graphics.newCanvas(downWidth, downHeight)
    bloom.blurH1Canvas = love.graphics.newCanvas(downWidth, downHeight)
    bloom.blurV1Canvas = love.graphics.newCanvas(downWidth, downHeight)
    
    bloom.blurH2Canvas = love.graphics.newCanvas(downWidth, downHeight)
    bloom.blurV2Canvas = love.graphics.newCanvas(downWidth, downHeight)
    
    setmetatable(bloom, {__index = Bloom})
    return bloom
end

function Bloom:setColorRange(minR, minG, minB, maxR, maxG, maxB)
    self.minColor = {minR, minG, minB}
    self.maxColor = {maxR, maxG, maxB}
    return self
end

function Bloom:setBloomParams(threshold, intensity, radius, blurScale)
    self.threshold = threshold or self.threshold
    self.intensity = intensity or self.intensity
    self.radius = radius or self.radius
    self.blurScale = blurScale or self.blurScale
    return self
end

function Bloom:downscale(sourceCanvas, targetCanvas)
    love.graphics.setCanvas(targetCanvas)
    love.graphics.clear()
    love.graphics.setShader()
    love.graphics.draw(sourceCanvas, 0, 0, 0, 
                      1/self.downscaleFactor, 1/self.downscaleFactor)
end

function Bloom:applyBlur(sourceCanvas, passes)
    passes = passes or 2 
    
    -- First pass
    self.blurHShader:send("radius", self.radius)
    self.blurHShader:send("blurScale", self.blurScale)
    love.graphics.setCanvas(self.blurH1Canvas)
    love.graphics.clear()
    love.graphics.setShader(self.blurHShader)
    love.graphics.draw(sourceCanvas)
    
    self.blurVShader:send("radius", self.radius)
    self.blurVShader:send("blurScale", self.blurScale)
    love.graphics.setCanvas(self.blurV1Canvas)
    love.graphics.clear()
    love.graphics.setShader(self.blurVShader)
    love.graphics.draw(self.blurH1Canvas)
    
    local result = self.blurV1Canvas
    
    -- Additional passes
    for i = 2, passes do
        love.graphics.setCanvas(self.blurH2Canvas)
        love.graphics.clear()
        love.graphics.setShader(self.blurHShader)
        love.graphics.draw(result)
        
        love.graphics.setCanvas(self.blurV2Canvas)
        love.graphics.clear()
        love.graphics.setShader(self.blurVShader)
        love.graphics.draw(self.blurH2Canvas)
        
        result = self.blurV2Canvas
    end
    
    return result
end


function Bloom:apply(canvas, lfa, blurPasses)
    local oldCanvas = love.graphics.getCanvas()
    local oldShader = love.graphics.getShader()
     
    self.extractShader:send("minColor", self.minColor)
    self.extractShader:send("maxColor", self.maxColor)
    self.extractShader:send("threshold", self.threshold)
    love.graphics.setCanvas(self.extractCanvas)
    love.graphics.clear()
    love.graphics.setShader(self.extractShader)
    love.graphics.draw(canvas)
    
   
    self:downscale(self.extractCanvas, self.downscaledCanvas)
    
    local blurredCanvas = self:applyBlur(self.downscaledCanvas, blurPasses or 2)
    
    love.graphics.setCanvas(oldCanvas)
    self.combineShader:send("bloomTexture", blurredCanvas)
    self.combineShader:send("intensity", self.intensity)
    love.graphics.setShader(self.combineShader)
    
    
    love.graphics.draw(canvas)
    love.graphics.setShader(oldShader)
    return self
end

return Bloom