local TorusInterior = {}
TorusInterior.__index = TorusInterior

function TorusInterior.new()
    local self = setmetatable({}, TorusInterior)
    
    -- Default settings
    self.tubeRadius = 20.0         
    self.curvatureRadius = 100.0    
    self.rotation = {x = 0, y = 0, z = 0}
    
    self.cameraPosition = {x = 80.0, y = 0, z = 0}  
    self.cameraTarget = {x = 100.0, y = 0, z = 20.0} 
    
    self.fov = 100.0 
    self.scrollSpeed = {x = 0, y = 0} 
    self.scrollOffset = {x = 0, y = 0}  
    self.brightness = 1.8 
    self.ambientLight = 0.2  
    self.curvatureFactor = 0.1  
    self.textureScale = 1.0  
    
   
    self.fogDensity = 0.0         
    self.fogMaxDistance = 0.0     
    self.fogColor = {0.0, 0.0, 0.0} 
    self.fogSampleSteps = 1       
    self.fogTextureInfluence = 0.0 
    
   
    self.lightAttenuationFactor = 0.055  
    self.lightMinDistance = 30.0       
    self.lightMaxDistance = 50.0     
    
    
    self.distanceBlurEnabled = true  
    self.distanceBlurStart = 30.0    
    self.distanceBlurFactor = 1.15   
    self.distanceBlurSamples = 8     
    
    -- Create the shader
self.shader = love.graphics.newShader[[
        uniform float tubeRadius;
        uniform float curvatureRadius;
        uniform float curvatureFactor;
        uniform vec3 rotation;
        uniform vec3 cameraPosition;
        uniform vec3 viewDirection; 
        uniform bool lookAtTarget;  
        uniform float fov;  
        uniform vec2 scrollOffset;           
        uniform float displacementTime = 0.0;  
        uniform float brightness;              
        uniform float ambientLight;  
        uniform float textureScale = 1.0;  
        uniform float bumpStrength = 0.25;       
        uniform vec2 xWaveAmplitude = vec2(1.5, 0.5);  
        uniform vec2 yWaveAmplitude = vec2(2.5, 0.8); 
        uniform vec2 xWaveLength = vec2(0.2, 0.1);     
        uniform vec2 yWaveLength = vec2(0.2, 0.05);   
        uniform vec2 xWaveOffset = vec2(0.0, 0.0);     
        uniform vec2 yWaveOffset = vec2(0.0, 0.0);    
        uniform float waveTimeScale = 4.0;           
        uniform float waveBlendFactor = 0.6;          
        uniform float fogDensity;
        uniform float fogMaxDistance;
        uniform vec3 fogColor;
        uniform int fogSampleSteps;
        uniform float fogTextureInfluence;
        uniform float lightAttenuationFactor;
        uniform float lightMinDistance;
        uniform float lightMaxDistance;
        uniform bool distanceBlurEnabled;
        uniform float distanceBlurStart;
        uniform float distanceBlurFactor;
        uniform int distanceBlurSamples;
        uniform Image texture;
        const float PI = 3.14159265359;
        const float TWO_PI = 6.28318530718;
        float getLuminance(vec3 color) {
            return dot(color, vec3(0.299, 0.587, 0.114));
        }
        vec4 getTextureSample(vec2 uv, vec2 offset) {
            return Texel(texture, fract(uv + offset));
        }
        float noise(vec3 p) {
            vec3 ip = floor(p);
            vec3 fp = fract(p);
            fp = fp * fp * (3.0 - 2.0 * fp);
            
            float n = ip.x + ip.y * 157.0 + 113.0 * ip.z;
            return mix(
                mix(
                    mix(sin(n+0.0), sin(n+1.0), fp.x),
                    mix(sin(n+157.0), sin(n+158.0), fp.x),
                    fp.y),
                mix(
                    mix(sin(n+113.0), sin(n+114.0), fp.x),
                    mix(sin(n+270.0), sin(n+271.0), fp.x),
                    fp.y),
                fp.z);
        }
        vec3 rotateX(vec3 p, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            return vec3(p.x, c*p.y-s*p.z, s*p.y+c*p.z);
        }
        
        vec3 rotateY(vec3 p, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            return vec3(c*p.x+s*p.z, p.y, -s*p.x+c*p.z);
        }
        
        vec3 rotateZ(vec3 p, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            return vec3(c*p.x-s*p.y, s*p.x+c*p.y, p.z);
        }
        
        vec2 calculateTextureCoords(vec3 p, float effectiveR) {
            vec2 uv;
            
            if (curvatureFactor < 0.01) {
              
                float angle = atan(p.y, p.x);
                uv.x = (angle + PI) / TWO_PI;
                uv.y = p.z / (2.0 * tubeRadius);
            } else {
                vec2 toCenter = vec2(p.x, p.z);
                float distToCenter = length(toCenter);
                if (distToCenter < 0.001) return vec2(0.0); // Avoid division by zero
                vec2 dirToCenter = toCenter / distToCenter;
                float phi = atan(dirToCenter.y, dirToCenter.x);
                vec3 ringCenter = vec3(dirToCenter.x, 0, dirToCenter.y) * effectiveR;
                vec3 fromRingCenter = p - ringCenter;
                float projX = dot(fromRingCenter, vec3(dirToCenter.x, 0.0, dirToCenter.y));
                float projY = fromRingCenter.y;
                float theta = atan(projY, projX);
                uv.x = (theta + PI) / TWO_PI;
                uv.y = (phi + PI) / TWO_PI;
            }
            uv.x = uv.x * (2.0 * PI * tubeRadius / 200.0) * textureScale;
            uv.y = uv.y * textureScale;
            return uv;
        }
        float sineWaveDisplacement(vec2 uv) {
            float timeX = displacementTime * waveTimeScale;
            float timeY = displacementTime * waveTimeScale * 0.7; // Slightly different speeds
            float xWave1 = sin((uv.x * TWO_PI / xWaveLength.x) + xWaveOffset.x + timeX) * xWaveAmplitude.x;
            float xWave2 = sin((uv.x * TWO_PI / xWaveLength.y) + xWaveOffset.y + timeX * 1.3) * xWaveAmplitude.y;
            float yWave1 = sin((uv.y * TWO_PI / yWaveLength.x) + yWaveOffset.x + timeY) * yWaveAmplitude.x;
            float yWave2 = sin((uv.y * TWO_PI / yWaveLength.y) + yWaveOffset.y + timeY * 1.5) * yWaveAmplitude.y;
            float xCombined = xWave1 + xWave2;
            float yCombined = yWave1 + yWave2;
            float combinedWave = mix(xCombined, yCombined, waveBlendFactor);
            return (combinedWave + 1.0) * 0.5;
        }
        float sampleDisplacement(vec3 p, float effectiveR) {
            vec2 uv = calculateTextureCoords(p, effectiveR);
            float waveDisplacement = sineWaveDisplacement(uv);
            vec2 textureUV = fract(uv + scrollOffset);
            vec4 texSample = Texel(texture, textureUV);
            float texDisplacement = getLuminance(texSample.rgb) * 0.2;
            return waveDisplacement + texDisplacement;
        }
        float sdf_torus(vec3 p, float R, float r) {
            vec2 q = vec2(length(p.xz) - R, p.y);
            return length(q) - r;
        }
        float sdf_displaced(vec3 p, float effectiveR) {
            float base_dist;
            vec3 local_normal;
            if (curvatureFactor < 0.01) {
                base_dist = length(p.xy) - tubeRadius;
                local_normal = normalize(vec3(-p.x, -p.y, 0.0));
            } else {
                vec2 toCenter = vec2(p.x, p.z);
                float distToCenter = length(toCenter);
                if (distToCenter < 0.001) {
                    local_normal = vec3(1.0, 0.0, 0.0); // Arbitrary direction for singularity
                } else {
                    vec2 dirToCenter = toCenter / distToCenter;
                    vec3 ringCenter = vec3(dirToCenter.x, 0, dirToCenter.y) * effectiveR;
                    vec3 fromRingCenter = p - ringCenter;
                    local_normal = normalize(fromRingCenter);
                }
                vec2 q = vec2(length(p.xz) - effectiveR, p.y);
                base_dist = length(q) - tubeRadius;
            }
            if (abs(base_dist) < tubeRadius * 0.5) {
                float displacement = sampleDisplacement(p, effectiveR);
                float displaceAmount = bumpStrength * tubeRadius * displacement;
                return base_dist - displaceAmount;
            }
            return base_dist;
        }
        
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
           
            vec2 uv = (screen_coords / love_ScreenSize.xy) * 2.0 - 1.0;
            uv.x *= love_ScreenSize.x / love_ScreenSize.y; // Aspect ratio correction
            float fovRadians = radians(fov);
            float z = 1.0 / tan(fovRadians / 2.0);
            vec3 rd = normalize(vec3(uv.x, uv.y, -z));
            vec3 forward;
            if (lookAtTarget) {
            
                forward = normalize(viewDirection);
            } else {
              
                forward = vec3(0.0, 0.0, 1.0);
            }
            vec3 worldUp = vec3(0.0, 1.0, 0.0);
            vec3 right = normalize(cross(forward, worldUp));
            vec3 up = cross(right, forward);
            rd = rd.x * right + rd.y * up + rd.z * forward;
            rd = rotateX(rd, rotation.x);
            rd = rotateY(rd, rotation.y);
            rd = rotateZ(rd, rotation.z);
            vec3 ro = cameraPosition;
            ro = rotateX(ro, rotation.x);
            ro = rotateY(ro, rotation.y);
            ro = rotateZ(ro, rotation.z);
            const int MAX_STEPS = 100;
            const float MAX_DIST = 200.0;  // Increased for outside views
            const float SURF_DIST = 0.01;
            float effectiveR = curvatureRadius * curvatureFactor;
            float t = 0.0;
            float d = 0.0;
            {
                for (int i = 0; i < MAX_STEPS; i++) {
                    vec3 p = ro + rd * t;
                    float dist = sdf_displaced(p, effectiveR);
                    d = -dist;
                    if (d < SURF_DIST || t > MAX_DIST) break;
                    t += d;
                }
                if (t > MAX_DIST || d > SURF_DIST) {
                    return vec4(0.0, 0.0, 0.0, 1.0);
                }
            }
            vec3 p = ro + rd * t;
            vec2 tubeUV = calculateTextureCoords(p, effectiveR);
            vec2 baseUV = fract(tubeUV + scrollOffset);
            float viewDistance = length(p - ro);
            float normalizedDistance = min(viewDistance / fogMaxDistance, 1.0);
            vec4 texColor;
            if (distanceBlurEnabled) {
                float blurAmount = 0.0;
                if (viewDistance > distanceBlurStart) {
                    float distanceFactor = clamp((viewDistance - distanceBlurStart) / 
                                               (fogMaxDistance - distanceBlurStart), 0.0, 1.0);
                    blurAmount = distanceBlurFactor * distanceFactor * distanceFactor;
                }
                if (blurAmount > 0.001) {
                    texColor = vec4(0.0);
                    float totalWeight = 0.0;
                    for (int i = 0; i < distanceBlurSamples; i++) {
                        float angle = float(i) * 2.4;
                        float baseRadius = blurAmount * sqrt(float(i) / float(distanceBlurSamples));
                        float xScale = (2.0 * PI * tubeRadius / 200.0) * textureScale;
                        float yScale = textureScale;
                        vec2 offset = vec2(
                            cos(angle) * baseRadius / xScale,
                            sin(angle) * baseRadius / yScale
                        );
                      
                        vec2 sampleUV = fract(tubeUV + scrollOffset + offset);
                        float scaledLength = length(vec2(offset.x * xScale, offset.y * yScale));
                        float weight = 1.0 - scaledLength / blurAmount;
                        weight = weight * weight; // Squared for gaussian-like falloff
                        texColor += Texel(tex, sampleUV) * weight;
                        totalWeight += weight;
                    }
                    texColor /= totalWeight;
                } else {
                    texColor = Texel(tex, baseUV);
                }
            } else {
                texColor = Texel(tex, baseUV);
            }
            const float eps = 0.01;
            float dx = sdf_displaced(p + vec3(eps, 0, 0), effectiveR) - sdf_displaced(p - vec3(eps, 0, 0), effectiveR);
            float dy = sdf_displaced(p + vec3(0, eps, 0), effectiveR) - sdf_displaced(p - vec3(0, eps, 0), effectiveR);
            float dz = sdf_displaced(p + vec3(0, 0, eps), effectiveR) - sdf_displaced(p - vec3(0, 0, eps), effectiveR);
            vec3 normal = normalize(vec3(dx, dy, dz));
            normal = -normal;
            vec3 lightDir1 = normalize(vec3(1.0, 1.0, 0.0));
            vec3 lightDir2 = normalize(vec3(-1.0, -1.0, 0.0));
            vec3 lightDir3 = normalize(vec3(0.0, 0.0, 1.0));
            float diffuse1 = max(0.0, dot(normal, lightDir1));
            float diffuse2 = max(0.0, dot(normal, lightDir2));
            float diffuse3 = max(0.0, dot(normal, lightDir3));
            float diffuse = ambientLight + (1.0 - ambientLight) * (diffuse1 + diffuse2 + diffuse3) / 3.0;
            float distanceAttenuation = 1.0;
            if (viewDistance > lightMinDistance) {
                float distanceFactor = clamp((viewDistance - lightMinDistance) / (lightMaxDistance - lightMinDistance), 0.0, 1.0);
                distanceAttenuation = exp(-distanceFactor * lightAttenuationFactor * viewDistance);
                distanceAttenuation = ambientLight + (1.0 - ambientLight) * distanceAttenuation;
            }
            diffuse *= brightness * distanceAttenuation;
            float emission = 0.3; // Minimum brightness to ensure visibility inside the tube
            vec4 surfaceColor = texColor * color * vec4(vec3(diffuse + emission), 1.0);
            float fogFactor = 1.0 - exp(-normalizedDistance * fogDensity * viewDistance);
            fogFactor = fogFactor * (1.0 - distanceAttenuation * 0.5);
            vec4 fogContribution = vec4(0.0);
            if (fogSampleSteps > 0) {
                float stepSize = viewDistance / float(fogSampleSteps);
                float sampleDist = stepSize * 0.5;
                for (int i = 0; i < fogSampleSteps; i++) {
                    vec3 samplePos = ro + rd * sampleDist;
                    float sampleRatio = sampleDist / viewDistance;
                    float sampleFogDensity = fogDensity * sampleRatio * stepSize;
                    vec2 fogUV = calculateTextureCoords(samplePos, effectiveR);
                    fogUV = fract(fogUV + scrollOffset);
                    vec4 fogTexColor = Texel(tex, fogUV);
                    vec3 sampleFogColor = mix(fogColor, fogTexColor.rgb, fogTextureInfluence);
                    fogContribution += vec4(sampleFogColor * sampleFogDensity, sampleFogDensity);
                    sampleDist += stepSize;
                }
                if (fogContribution.a > 0.0) {
                    fogContribution.rgb /= fogContribution.a;
                }
            }
            return mix(surfaceColor, vec4(fogContribution.rgb, 1.0), fogFactor);
        }
    ]]
    self:updateShaderVariables()
    return self
end

function TorusInterior:updateShaderVariables()
    self.shader:send("tubeRadius", self.tubeRadius)
    self.shader:send("curvatureRadius", self.curvatureRadius)
    self.shader:send("curvatureFactor", self.curvatureFactor)
    self.shader:send("textureScale", self.textureScale or 1.0)
    
    self.lookAtTarget = true
    if self.lookAtTarget then
       
        local viewDir = {
            x = self.cameraTarget.x - self.cameraPosition.x,
            y = self.cameraTarget.y - self.cameraPosition.y,
            z = self.cameraTarget.z - self.cameraPosition.z
        }
        
     
        local length = math.sqrt(viewDir.x^2 + viewDir.y^2 + viewDir.z^2)
        viewDir.x = viewDir.x / length
        viewDir.y = viewDir.y / length
        viewDir.z = viewDir.z / length
        
        
        self.shader:send("viewDirection", {viewDir.x, viewDir.y, viewDir.z})
    end
    
    self.shader:send("rotation", {self.rotation.x, self.rotation.y, self.rotation.z})
    self.shader:send("cameraPosition", {self.cameraPosition.x, self.cameraPosition.y, self.cameraPosition.z})
    self.shader:send("lookAtTarget", self.lookAtTarget)
    self.shader:send("fov", self.fov)
    self.shader:send("scrollOffset", {self.scrollOffset.x, self.scrollOffset.y})
    self.shader:send("brightness", self.brightness)
    self.shader:send("ambientLight", self.ambientLight)
    self.shader:send("fogDensity", self.fogDensity)
    self.shader:send("fogMaxDistance", self.fogMaxDistance)
    self.shader:send("fogColor", self.fogColor)
    self.shader:send("fogSampleSteps", self.fogSampleSteps)
    self.shader:send("fogTextureInfluence", self.fogTextureInfluence)
    self.shader:send("lightAttenuationFactor", self.lightAttenuationFactor)
    self.shader:send("lightMinDistance", self.lightMinDistance)
    self.shader:send("lightMaxDistance", self.lightMaxDistance)
    self.shader:send("distanceBlurEnabled", self.distanceBlurEnabled)
    self.shader:send("distanceBlurStart", self.distanceBlurStart)
    self.shader:send("distanceBlurFactor", self.distanceBlurFactor)
    self.shader:send("distanceBlurSamples", self.distanceBlurSamples)
end

function TorusInterior:setTubeRadius(radius)
    self.tubeRadius = radius
    self:updateShaderVariables()
end

function TorusInterior:setCurvatureRadius(radius)
    self.curvatureRadius = radius
    self:updateShaderVariables()
end

function TorusInterior:setCurvatureFactor(factor)
    self.curvatureFactor = factor
    self:updateShaderVariables()
end

function TorusInterior:setRotation(x, y, z)
    self.rotation.x = x or self.rotation.x
    self.rotation.y = y or self.rotation.y
    self.rotation.z = z or self.rotation.z
    self:updateShaderVariables()
end

function TorusInterior:setCameraPosition(x, y, z)
    self.cameraPosition.x = x or self.cameraPosition.x
    self.cameraPosition.y = y or self.cameraPosition.y
    self.cameraPosition.z = z or self.cameraPosition.z
    self:updateShaderVariables()
end

function TorusInterior:setCameraTarget(x, y, z)
    self.cameraTarget.x = x or self.cameraTarget.x
    self.cameraTarget.y = y or self.cameraTarget.y
    self.cameraTarget.z = z or self.cameraTarget.z
    self:updateShaderVariables()
end

function TorusInterior:setLookAtTarget(enabled)
    self.lookAtTarget = enabled
    self:updateShaderVariables()
end

function TorusInterior:setTextureScale(scale)
    self.textureScale = scale
    self:updateShaderVariables()
end

function TorusInterior:debugTextureCoords()
    return {
        tubeRadius = self.tubeRadius,
        curvatureRadius = self.curvatureRadius,
        textureScale = self.textureScale
    }
end

function TorusInterior:setFOV(fov)
    self.fov = fov
    self:updateShaderVariables()
end

function TorusInterior:setScrollSpeed(x, y)
    self.scrollSpeed.x = x or self.scrollSpeed.x
    self.scrollSpeed.y = y or self.scrollSpeed.y
end

function TorusInterior:setBrightness(brightness)
    self.brightness = brightness
    self:updateShaderVariables()
end

function TorusInterior:setAmbientLight(ambient)
    self.ambientLight = ambient
    self:updateShaderVariables() 
end

function TorusInterior:setFogDensity(density)
    self.fogDensity = density
    self:updateShaderVariables()
end

function TorusInterior:setFogMaxDistance(distance)
    self.fogMaxDistance = distance
    self:updateShaderVariables()
end

function TorusInterior:setFogColor(r, g, b)
    self.fogColor = {r or 1.0, g or 1.0, b or 1.0}
    self:updateShaderVariables()
end

function TorusInterior:setFogSampleSteps(steps)
    self.fogSampleSteps = steps
    self:updateShaderVariables()
end

function TorusInterior:setFogTextureInfluence(influence)
    self.fogTextureInfluence = math.max(0.0, math.min(1.0, influence))
    self:updateShaderVariables()
end

function TorusInterior:setLightAttenuationFactor(factor)
    self.lightAttenuationFactor = factor
    self:updateShaderVariables()
end

function TorusInterior:setLightMinDistance(distance)
    self.lightMinDistance = distance
    self:updateShaderVariables()
end

function TorusInterior:setLightMaxDistance(distance)
    self.lightMaxDistance = distance
    self:updateShaderVariables()
end

function TorusInterior:setDistanceBlurEnabled(enabled)
    self.distanceBlurEnabled = enabled
    self:updateShaderVariables()
end

function TorusInterior:setDistanceBlurStart(distance)
    self.distanceBlurStart = distance
    self:updateShaderVariables()
end

function TorusInterior:setDistanceBlurFactor(amount)
    self.distanceBlurFactor = amount
    self:updateShaderVariables()
end

function TorusInterior:setDistanceBlurSamples(samples)
    self.distanceBlurSamples = samples
    self:updateShaderVariables()
end

function TorusInterior:update(dt)
    self.scrollOffset.x = self.scrollOffset.x + self.scrollSpeed.x * dt
    self.scrollOffset.y = self.scrollOffset.y + self.scrollSpeed.y * dt
    self.scrollOffset.x = self.scrollOffset.x % 1.0
    self.scrollOffset.y = self.scrollOffset.y % 1.0
    self:updateShaderVariables()
end

function TorusInterior:draw(texture)
    love.graphics.setShader(self.shader)
    love.graphics.draw(texture or love.graphics.getBackgroundImage(), 0, 0, 0, 
                       love.graphics.getWidth() / (texture and texture:getWidth() or 1), 
                       love.graphics.getHeight() / (texture and texture:getHeight() or 1))
    love.graphics.setShader()
end

return TorusInterior