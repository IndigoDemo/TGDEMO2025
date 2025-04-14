return love.graphics.newShader[[
    extern number time;
    extern number glowStrength = 1.35;
    extern number glowRadius = 1.5;
    extern number aberrationStrength = 0.005;
    extern number vhsNoiseStrength = 0.11;
    extern number scanlineStrength = 0.22;
    extern vec2 resolution;

    // Hash function for noise
    float hash(float n) {
        return fract(sin(n) * 43758.5453);
    }

    // VHS noise function
    float vhsNoise(vec2 uv) {
        float noise = hash(uv.x * 100.0 + uv.y * 10000.0 + time * 10.0);
        return noise;
    }

    // Scanline effect
    float scanline(vec2 uv) {
        return sin(uv.y * resolution.y * 1.0 + time * 10.0) * 0.5 + 0.5;
    }

    vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
        // VHS tracking distortion
        float distortionY = sin(time * 0.5 + uv.y * 20.0) * 0.003;
        uv.y += distortionY * vhsNoiseStrength * 5.0;
        
        // Horizontal jitter
        float jitter = hash(floor(time * 15.0) + floor(uv.y * 90.0)) * 2.0 - 1.0;
        jitter *= 0.003 * vhsNoiseStrength * 5.0;
        uv.x += jitter;
        
        // Chromatic aberration
        vec4 r = Texel(tex, uv + vec2(aberrationStrength, 0.001));
        vec4 g = Texel(tex, uv);
        vec4 b = Texel(tex, uv - vec2(aberrationStrength, 0.001));
        
        vec4 baseColor = vec4(r.r, g.g, b.b, g.a);
        
        // Glow effect
        vec4 glow = vec4(0.0);
        float totalWeight = 0.0;
        
        for (float x = -glowRadius; x <= glowRadius; x += 1.0) {
            for (float y = -glowRadius; y <= glowRadius; y += 1.0) {
                float weight = 1.0 - length(vec2(x, y)) / glowRadius;
                if (weight < 0.0) weight = 0.0;
                weight *= weight;
                
                glow += Texel(tex, uv + vec2(x, y) / resolution) * weight;
                totalWeight += weight;
            }
        }
        
        glow /= totalWeight;
        
        // VHS noise and scanlines
        float noise = vhsNoise(uv);
        float scanlineEffect = mix(1.0, scanline(uv), scanlineStrength);
        
        vec4 finalColor = mix(baseColor, glow, glowStrength);
        finalColor.rgb *= scanlineEffect;
        finalColor.rgb += vec3(noise) * vhsNoiseStrength * 0.1;
        
        return finalColor * color;
    }
]]
