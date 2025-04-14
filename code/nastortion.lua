

local DistortionShaders = {
    shaders = {},
    active = nil,
    time = 0,
    intensity = 1.0,
    resolution = {love.graphics.getDimensions()},
}

local pixelSortShader = [[
    extern float time;
    extern float intensity;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        
        // Create distortion in rows
        float row = floor(uv.y * resolution.y / 8.0);
        float noise = fract(sin(row * 12.39456 + time) * 43758.5453);
        
        if (noise < 0.3 * intensity) {
            float amt = noise * 20.0 * intensity;
            uv.x = fract(uv.x + amt * 0.01);
        }
        
        return Texel(texture, uv) * color;
    }
]]

local rgbSplitShader = [[
    extern float time;
    extern float intensity;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        
        // Oscillating displacement amount
        float amount = (sin(time * 2.0) * 0.5 + 0.5) * 0.01 * intensity;
        
        // Sample each color channel with offset
        float r = Texel(texture, vec2(uv.x + amount, uv.y)).r;
        float g = Texel(texture, vec2(uv.x, uv.y)).g;
        float b = Texel(texture, vec2(uv.x - amount, uv.y)).b;
        
        return vec4(r, g, b, 1.0) * color;
    }
]]


local glitchShader = [[
    extern float time;
    extern float intensity;
    extern vec2 resolution;
    
    // Random function
    float random(vec2 st) {
        return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
    }
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        vec2 block = floor(uv * resolution / 16.0);
        vec2 uv_noise = block / 64.0;
        uv_noise += floor(vec2(time) * vec2(1234.0, 3543.0)) / 64.0;
        
        float block_thresh = pow(fract(time * 1236.0453), 2.0) * 0.6;
        float line_thresh = pow(fract(time * 2236.0453), 3.0) * 0.6;
        
        vec2 uv_r = uv, uv_g = uv, uv_b = uv;
        
        // Apply glitches with intensity control
        if (random(uv_noise) < block_thresh * intensity) {
            vec2 dist = (fract(uv_noise) - 0.5) * 0.3;
            uv_r += dist * 0.1 * intensity;
            uv_g += dist * 0.2 * intensity;
            uv_b += dist * 0.125 * intensity;
        }
        
        // Horizontal lines
        if (random(vec2(uv_noise.y, 0.0)) < line_thresh * intensity) {
            float line = fract(uv.y * resolution.y / 4.0);
            vec3 mask = vec3(3.0, 0.0, 0.0);
            if (line > 0.5) {
                uv_r.x = fract(uv_r.x + 0.1 * intensity);
                uv_g.x = fract(uv_g.x + 0.1 * intensity);
                uv_b.x = fract(uv_b.x + 0.1 * intensity);
            }
        }
        
        // Sample each color channel with glitch offsets
        float r = Texel(texture, uv_r).r;
        float g = Texel(texture, uv_g).g;
        float b = Texel(texture, uv_b).b;
        
        return vec4(r, g, b, 1.0) * color;
    }
]]

local vhsShader = [[
    extern float time;
    extern float intensity;
    extern vec2 resolution;
    
    // Noise function
    float noise(vec2 p) {
        vec2 ip = floor(p);
        vec2 u = fract(p);
        u = u*u*(3.0-2.0*u);
        
        float res = mix(
            mix(dot(vec2(fract(sin(dot(ip, vec2(12.9898, 78.233))) * 43758.5453)), u),
                dot(vec2(fract(sin(dot(ip+vec2(1.0,0.0), vec2(12.9898, 78.233))) * 43758.5453)), u-vec2(1.0,0.0)), u.x),
            mix(dot(vec2(fract(sin(dot(ip+vec2(0.0,1.0), vec2(12.9898, 78.233))) * 43758.5453)), u-vec2(0.0,1.0)),
                dot(vec2(fract(sin(dot(ip+vec2(1.0,1.0), vec2(12.9898, 78.233))) * 43758.5453)), u-vec2(1.0,1.0)), u.x), u.y);
        return res*res;
    }
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        
        // Tape waves
        float waves = sin(uv.y * 40.0 + time) * (0.001 + 0.001 * sin(time * 3.0)) * intensity;
        uv.x += waves;
        
        // Horizontal displacement (tracking error)
        float tracking = sin(time * 0.5) * sin(time * 1.37) * sin(time * 4.71);
        if (abs(tracking) < 0.3 * intensity) {
            float t = time * 15.0;
            float ypos = fract(t) * resolution.y;
            if (abs(screen_coords.y - ypos) < resolution.y * 0.01 * intensity) {
                uv.x = uv.x + (intensity * sin(uv.y * 100.0) * 0.1);
            }
        }
        
        // Vertical hold
        float vhold = sin(time * 0.1) * sin(time * 1.3) * sin(time * 3.7);
        if (abs(vhold) < 0.3 * intensity && abs(vhold) > 0.2 * intensity) {
            uv.y = uv.y + (sin(time) * 0.02 * intensity);
        }
        
        // Scanlines
        float scanline = sin(uv.y * resolution.y * 0.7) * 0.03 * intensity;
        
        // Add noise grain
        float noise_intensity = intensity * 0.15;
        float grain = noise(vec2(uv.x * 100.0, uv.y * 100.0 + time * 10.0)) * noise_intensity;
        
        // Fetch color with distorted UVs
        vec4 rgba = Texel(texture, uv);
        
        // Apply scanlines and noise
        rgba.rgb -= scanline;
        rgba.rgb += vec3(grain);
        
        // VHS color bleeding
        rgba.r += noise(vec2(uv.x * 100.0, uv.y * 100.0 + time * 10.0)) * 0.05 * intensity;
        rgba.b += noise(vec2(uv.x * 100.0, uv.y * 100.0 + time * 15.0)) * 0.05 * intensity;
        
        return rgba * color;
    }
]]

local pixelationShader = [[
    extern float time;
    extern float intensity;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        // Calculate pixel size based on intensity (higher intensity = larger pixels)
        float pixelSize = max(2.0, 20.0 * intensity);
        
        // Add some fluctuation to the pixel size based on time
        pixelSize += sin(time * 1.5) * 5.0 * intensity;
        
        // Calculate pixelated coordinates
        vec2 pixelCoords = floor(texture_coords * resolution / pixelSize) * pixelSize / resolution;
        
        // Digital noise/artifacts (based on time and position)
        float noise = fract(sin(dot(pixelCoords, vec2(12.9898, 78.233)) + time) * 43758.5453);
        if (noise > 0.97 - (0.1 * intensity)) {
            // Occasionally swap x/y coordinates for digital artifacts
            return Texel(texture, vec2(pixelCoords.y, pixelCoords.x));
        }
        
        // Sometimes shift the color channels
        if (noise > 0.94 - (0.1 * intensity)) {
            vec4 col = Texel(texture, pixelCoords);
            return vec4(col.g, col.b, col.r, col.a) * color;
        }
        
        return Texel(texture, pixelCoords) * color;
    }
]]

local scanLinesShader = [[
    extern float time;
    extern float intensity;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        vec4 texColor = Texel(texture, uv);
        
        // Create scan lines
        float scanLine = sin(uv.y * resolution.y * 1.0 - time * 10.0) * 0.5 + 0.5;
        scanLine = pow(scanLine, 10.0) * intensity * 0.3;
        
        // Digital rolling effect
        float roll = sin(time * 0.5) * 3.0 * intensity;
        uv.y = fract(uv.y + roll * 0.01);
        
        // Create interference patterns
        float noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time * 5.0) * 43758.5453);
        
        // Digital "snow" effect
        float snow = 0.0;
        if (noise > 0.95 - (intensity * 0.2)) {
            snow = 1.0;
        }
        
        // Horizontal offset distortion
        if (noise > 0.8 - (intensity * 0.3) && noise < 0.83) {
            uv.x = fract(uv.x + 0.01 * intensity);
        }
        
        // Apply combined effects
        vec4 finalColor = Texel(texture, uv);
        finalColor.rgb -= scanLine;
        finalColor.rgb += snow * intensity * 0.5;
        
        return finalColor * color;
    }
]]

local crtWarpShader = [[
    extern float time;
    extern float intensity;
    extern vec2 resolution;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        
        // CRT screen curvature/warp effect
        vec2 cc = uv - 0.5;
        float dist = dot(cc, cc) * intensity * 5.0;
        uv = uv + cc * (0.1 + 0.2 * dist) * intensity;
        
        // Add flickering
        float flicker = sin(time * 8.0) * sin(time * 0.3) * 0.03 * intensity;
        
        // CRT RGB pattern
        float x = uv.x * resolution.x;
        float maskR = 0.5 + 0.5 * sin(x * 3.14159);
        float maskG = 0.5 + 0.5 * sin((x + 0.33) * 3.14159);
        float maskB = 0.5 + 0.5 * sin((x + 0.66) * 3.14159);
        
        // Scan lines
        float scanline = sin(uv.y * resolution.y * 0.7 - time * 10.0) * 0.5 + 0.5;
        scanline = pow(scanline, 32.0) * 0.3 * intensity;
        
        // CRT after-image persistence effect
        float afterimage = sin(time * 0.5) * 0.01 * intensity;
        
        // Check if uv is out of bounds (CRT clipping)
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
            return vec4(0.0, 0.0, 0.0, 1.0);
        }
        
        // Get texture color
        vec4 texColor = Texel(texture, uv);
        
        // Apply all effects
        texColor.r = texColor.r * (1.0 - intensity * 0.2 + maskR * intensity * 0.2) - scanline;
        texColor.g = texColor.g * (1.0 - intensity * 0.2 + maskG * intensity * 0.2) - scanline;
        texColor.b = texColor.b * (1.0 - intensity * 0.2 + maskB * intensity * 0.2) - scanline;
        texColor.rgb += flicker;
        
        // Digital noise
        float noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time) * 43758.5453);
        if (noise > 0.97) {
            texColor.rgb += vec3(0.1, 0.1, 0.1) * intensity;
        }
        
        return texColor * color;
    }
]]

local waveDistortShader = [[
    extern float time;
    extern float intensity;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        
        // Apply wave distortion
        float xDist = sin(uv.y * 10.0 + time * 2.0) * 0.03 * intensity;
        float yDist = sin(uv.x * 10.0 + time * 2.0) * 0.03 * intensity;
        
        uv.x += xDist;
        uv.y += yDist;
        
        // Add some digital noise at the peaks of distortion
        if (abs(xDist) > 0.02 * intensity || abs(yDist) > 0.02 * intensity) {
            // Digital artifact effect
            float noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time) * 43758.5453);
            if (noise > 0.9) {
                // Add some color shift for certain pixels
                vec4 texColor = Texel(texture, uv);
                return vec4(texColor.b, texColor.r, texColor.g, texColor.a) * color;
            }
        }
        
        return Texel(texture, uv) * color;
    }
]]

local combinedShaderTemplate = [[
    extern float time;
    extern float intensity;
    extern vec2 resolution;
    
    // Multi-pass rendering through multiple effects
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = texture_coords;
        vec4 texColor = Texel(texture, uv);
        
        // EFFECT_BLOCKS
        
        return texColor * color;
    }
]]

local effectBlocks = {
    pixelSort = [[
        // Pixel Sort Effect
        {
            float row = floor(uv.y * resolution.y / 8.0);
            float noise = fract(sin(row * 12.39456 + time) * 43758.5453);
            
            if (noise < 0.3 * intensity) {
                float amt = noise * 20.0 * intensity;
                uv.x = fract(uv.x + amt * 0.01);
                texColor = Texel(texture, uv);
            }
        }
    ]],
    
    rgbSplit = [[
        // RGB Split Effect
        {
            float amount = (sin(time * 2.0) * 0.5 + 0.5) * 0.01 * intensity;
            
            float r = Texel(texture, vec2(uv.x + amount, uv.y)).r;
            float g = texColor.g;
            float b = Texel(texture, vec2(uv.x - amount, uv.y)).b;
            
            texColor = vec4(r, g, b, texColor.a);
        }
    ]],
    
    glitch = [[
        // Glitch Effect
        {
            vec2 block = floor(uv * resolution / 16.0);
            vec2 uv_noise = block / 64.0;
            uv_noise += floor(vec2(time) * vec2(1234.0, 3543.0)) / 64.0;
            
            float block_thresh = pow(fract(time * 1236.0453), 2.0) * 0.6;
            float line_thresh = pow(fract(time * 2236.0453), 3.0) * 0.6;
            
            float noise = fract(sin(dot(uv_noise, vec2(12.9898, 78.233))) * 43758.5453);
            
            if (noise < block_thresh * intensity) {
                vec2 dist = (fract(uv_noise) - 0.5) * 0.3;
                
                vec2 uv_r = uv + dist * 0.1 * intensity;
                vec2 uv_g = uv + dist * 0.2 * intensity;
                vec2 uv_b = uv + dist * 0.125 * intensity;
                
                float r = Texel(texture, uv_r).r;
                float g = Texel(texture, uv_g).g;
                float b = Texel(texture, uv_b).b;
                
                texColor = vec4(r, g, b, texColor.a);
            }
            
            // Horizontal lines
            float line_noise = fract(sin(dot(vec2(uv_noise.y, 0.0), vec2(12.9898, 78.233))) * 43758.5453);
            if (line_noise < line_thresh * intensity) {
                float line = fract(uv.y * resolution.y / 4.0);
                if (line > 0.5) {
                    uv.x = fract(uv.x + 0.1 * intensity);
                    texColor = Texel(texture, uv);
                }
            }
        }
    ]],
    
    vhs = [[
        // VHS Effect
        {
            // Tape waves
            float waves = sin(uv.y * 40.0 + time) * (0.001 + 0.001 * sin(time * 3.0)) * intensity;
            uv.x += waves;
            
            // Scanlines
            float scanline = sin(uv.y * resolution.y * 0.7) * 0.03 * intensity;
            texColor.rgb -= scanline;
            
            // Add noise grain
            float noise_intensity = intensity * 0.15;
            float grain = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time * 10.0) * 43758.5453) * noise_intensity;
            texColor.rgb += vec3(grain);
            
            // VHS color bleeding
            float r_noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time * 10.0) * 43758.5453);
            float b_noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time * 15.0) * 43758.5453);
            texColor.r += r_noise * 0.05 * intensity;
            texColor.b += b_noise * 0.05 * intensity;
        }
    ]],
    
    pixelation = [[
        // Pixelation Effect
        {
            float pixelSize = max(2.0, 20.0 * intensity);
            pixelSize += sin(time * 1.5) * 5.0 * intensity;
            
            vec2 pixelCoords = floor(uv * resolution / pixelSize) * pixelSize / resolution;
            texColor = Texel(texture, pixelCoords);
            
            float noise = fract(sin(dot(pixelCoords, vec2(12.9898, 78.233)) + time) * 43758.5453);
            if (noise > 0.97 - (0.1 * intensity)) {
                texColor = Texel(texture, vec2(pixelCoords.y, pixelCoords.x));
            }
        }
    ]],
    
    scanLines = [[
        // Scan Lines Effect
        {
            float scanLine = sin(uv.y * resolution.y * 1.0 - time * 10.0) * 0.5 + 0.5;
            scanLine = pow(scanLine, 10.0) * intensity * 0.3;
            texColor.rgb -= scanLine;
            
            float noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time * 5.0) * 43758.5453);
            if (noise > 0.95 - (intensity * 0.2)) {
                texColor.rgb += vec3(1.0) * intensity * 0.5;
            }
        }
    ]],
    
    crtWarp = [[
        // CRT Warp Effect
        {
            vec2 cc = uv - 0.5;
            float dist = dot(cc, cc) * intensity * 5.0;
            uv = uv + cc * (0.1 + 0.2 * dist) * intensity;
            
            if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                texColor = vec4(0.0, 0.0, 0.0, texColor.a);
            } else {
                texColor = Texel(texture, uv);
                
                // CRT RGB pattern
                float x = uv.x * resolution.x;
                float maskR = 0.5 + 0.5 * sin(x * 3.14159);
                float maskG = 0.5 + 0.5 * sin((x + 0.33) * 3.14159);
                float maskB = 0.5 + 0.5 * sin((x + 0.66) * 3.14159);
                
                texColor.r = texColor.r * (1.0 - intensity * 0.2 + maskR * intensity * 0.2);
                texColor.g = texColor.g * (1.0 - intensity * 0.2 + maskG * intensity * 0.2);
                texColor.b = texColor.b * (1.0 - intensity * 0.2 + maskB * intensity * 0.2);
            }
        }
    ]],
    
    waveDist = [[
        // Wave Distortion Effect
        {
            float xDist = sin(uv.y * 10.0 + time * 2.0) * 0.03 * intensity;
            float yDist = sin(uv.x * 10.0 + time * 2.0) * 0.03 * intensity;
            
            uv.x += xDist;
            uv.y += yDist;
            
            texColor = Texel(texture, uv);
            
            if (abs(xDist) > 0.02 * intensity || abs(yDist) > 0.02 * intensity) {
                float noise = fract(sin(dot(uv, vec2(12.9898, 78.233)) + time) * 43758.5453);
                if (noise > 0.9) {
                    texColor = vec4(texColor.b, texColor.r, texColor.g, texColor.a);
                }
            }
        }
    ]]
}

function DistortionShaders:init()
    self.shaders = {
        pixelSort = love.graphics.newShader(pixelSortShader),
        rgbSplit = love.graphics.newShader(rgbSplitShader),
        glitch = love.graphics.newShader(glitchShader),
        vhs = love.graphics.newShader(vhsShader),
        pixelation = love.graphics.newShader(pixelationShader),
        scanLines = love.graphics.newShader(scanLinesShader),
        crtWarp = love.graphics.newShader(crtWarpShader),
        waveDist = love.graphics.newShader(waveDistortShader)
    }
    

    self.combinedShaders = {}
    
 
    self:setShader("glitch")
    
 
    self:updateResolution()
    
    return self
end


function DistortionShaders:updateResolution(width, height)
    width = width or love.graphics.getWidth()
    height = height or love.graphics.getHeight()
    self.resolution = {width, height}
    
    
    for name, shader in pairs(self.shaders) do
        if shader:hasUniform("resolution") then
            shader:send("resolution", self.resolution)
        end
    end
    
   
    for name, shader in pairs(self.combinedShaders) do
        if shader:hasUniform("resolution") then
            shader:send("resolution", self.resolution)
        end
    end
end


function DistortionShaders:update(dt)
    self.time = self.time + dt
    
    for name, shader in pairs(self.shaders) do
        if shader:hasUniform("time") then
            shader:send("time", self.time)
        end
        if shader:hasUniform("intensity") then
            shader:send("intensity", self.intensity)
        end
    end
    
    for name, shader in pairs(self.combinedShaders) do
        if shader:hasUniform("time") then
            shader:send("time", self.time)
        end
        if shader:hasUniform("intensity") then
            shader:send("intensity", self.intensity)
        end
    end
end

function DistortionShaders:setShader(name)
    assert(self.shaders[name], "Shader '" .. name .. "' not found!")
    self.active = name
    self.isCombo = false
end

function DistortionShaders:combineShaders(shaderNames, name)
    
    for _, shaderName in ipairs(shaderNames) do
        assert(effectBlocks[shaderName], "Shader '" .. shaderName .. "' Aw FECK! No can worksies!")
    end
    
   
    if not name then
        name = table.concat(shaderNames, "_")
    end
    
    if self.combinedShaders[name] then
        self.active = name
        self.isCombo = true
        return
    end
    
   
    local shaderCode = combinedShaderTemplate
    local effectCode = ""
    
    for _, shaderName in ipairs(shaderNames) do
        effectCode = effectCode .. effectBlocks[shaderName]
    end
    
    shaderCode = shaderCode:gsub("    // EFFECT_BLOCKS", effectCode)
    
    
    local newShader = love.graphics.newShader(shaderCode)
    self.combinedShaders[name] = newShader
    
   
    self.active = name
    self.isCombo = true
    
    if newShader:hasUniform("time") then
        newShader:send("time", self.time)
    end
    if newShader:hasUniform("intensity") then
        newShader:send("intensity", self.intensity)
    end
    if newShader:hasUniform("resolution") then
        newShader:send("resolution", self.resolution)
    end
end

function DistortionShaders:setIntensity(intensity)
    self.intensity = math.max(0.0, math.min(1.0, intensity))
    
    for name, shader in pairs(self.shaders) do
        if shader:hasUniform("intensity") then
            shader:send("intensity", self.intensity)
        end
    end
    
    for name, shader in pairs(self.combinedShaders) do
        if shader:hasUniform("intensity") then
            shader:send("intensity", self.intensity)
        end
    end
end

function DistortionShaders:getActiveShader()
    if self.active then
        if self.isCombo then
            return self.combinedShaders[self.active]
        elseif self.shaders[self.active] then
            return self.shaders[self.active]
        end
    end
    return nil
end


function DistortionShaders:getShaderList()
    local list = {}
    

    for name, _ in pairs(self.shaders) do
        table.insert(list, name)
    end

    for name, _ in pairs(self.combinedShaders) do
        table.insert(list, name .. " (combined)")
    end
    
    return list
end


function DistortionShaders:getEffectsList()
    local list = {}
    for name, _ in pairs(effectBlocks) do
        table.insert(list, name)
    end
    return list
end

function DistortionShaders:destroy()
    for name, shader in pairs(self.shaders) do
        self.shaders[name] = nil
    end
    
    for name, shader in pairs(self.combinedShaders) do
        self.combinedShaders[name] = nil
    end
    
    self.active = nil
    self.isCombo = false
end

return DistortionShaders