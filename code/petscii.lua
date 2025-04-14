return love.graphics.newShader[[
    extern number pixelSize = 4.0;
    extern number ditherStrength = 1; 
    
    // C64 color palette (16 colors)
    const vec3 c64_palette[16] = vec3[16](
        vec3(0.0, 0.0, 0.0),       // Black
        vec3(1.0, 1.0, 1.0),       // White
        vec3(0.4, 0.21, 0.16),     // Red
        vec3(0.67, 1.0, 0.93),     // Cyan
        vec3(0.75, 0.27, 0.76),    // Purple
        vec3(0.0, 0.53, 0.19),     // Green
        vec3(0.0, 0.0, 0.67),      // Blue
        vec3(1.0, 1.0, 0.33),      // Yellow
        vec3(0.75, 0.47, 0.0),     // Orange
        vec3(0.47, 0.33, 0.0),     // Brown
        vec3(1.0, 0.53, 0.53),     // Light Red
        vec3(0.33, 0.33, 0.33),    // Dark Grey
        vec3(0.67, 0.67, 0.67),    // Medium Grey
        vec3(0.0, 1.0, 0.33),      // Light Green
        vec3(0.0, 0.23, 1.0),       // Light Blue
        vec3(0.67, 0.67, 0.67)     // Light Grey
    );
    
  
    const float bayerMatrix[64] = float[64](
        0, 32, 8, 40, 2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26,
        12, 44, 4, 36, 14, 46, 6, 38,
        60, 28, 52, 20, 62, 30, 54, 22,
        3, 35, 11, 43, 1, 33, 9, 41,
        51, 19, 59, 27, 49, 17, 57, 25,
        15, 47, 7, 39, 13, 45, 5, 37,
        63, 31, 55, 23, 61, 29, 53, 21
    );
    
   
    float getBayerValue(vec2 blockCoord) {
        int x = int(mod(blockCoord.x / pixelSize, 8.0));
        int y = int(mod(blockCoord.y / pixelSize, 8.0));
        return bayerMatrix[y * 8 + x];
    }
    
   
    vec3 findClosestColor(vec3 color) {
        float minDist = 100000.0;
        vec3 closestColor = vec3(0.0);
        
        for (int i = 0; i < 16; i++) {
            float dist = distance(color, c64_palette[i]);
            if (dist < minDist) {
                minDist = dist;
                closestColor = c64_palette[i];
            }
        }
        
        return closestColor;
    }
    
    
    void findTwoClosestColors(vec3 color, out vec3 color1, out vec3 color2, out float mix_ratio) {
        float minDist1 = 100000.0;
        float minDist2 = 100000.0;
        
        
        for (int i = 0; i < 16; i++) {
            float dist = distance(color, c64_palette[i]);
            if (dist < minDist1) {
                minDist2 = minDist1;
                color2 = color1;
                minDist1 = dist;
                color1 = c64_palette[i];
            } else if (dist < minDist2) {
                minDist2 = dist;
                color2 = c64_palette[i];
            }
        }
        
       
        float totalDist = minDist1 + minDist2;
        if (totalDist < 0.001) {
            mix_ratio = 0.5;
        } else {
            mix_ratio = minDist2 / totalDist;  // Inverted to make more intuitive
        }
    }
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      
        vec2 textureSize = vec2(love_ScreenSize.x, love_ScreenSize.y);
        vec2 pixelCoords = floor(texture_coords * textureSize / pixelSize) * pixelSize;
        vec2 downsampledCoords = pixelCoords / textureSize;
        
       
        vec4 texColor = Texel(texture, downsampledCoords);
        
       
        vec3 color1, color2;
        float mix_ratio;
        findTwoClosestColors(texColor.rgb, color1, color2, mix_ratio);
        
       
        float bayerValue = getBayerValue(pixelCoords) / 64.0;
        
        
        vec3 finalColor;
        
        if (bayerValue > mix_ratio) {
            finalColor = color1;
        } else {
            finalColor = color2;
        }
        
       
        vec3 quantizedColor = findClosestColor(texColor.rgb);
        finalColor = mix(quantizedColor, finalColor, ditherStrength);
        return vec4(finalColor, texColor.a) * color;
    }
]]