return
love.graphics.newShader
[[
    
    extern float vanishPointY;
    extern float distortionFactor;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
       
        vec2 normalizedCoords = vec2(screen_coords.x / love_ScreenSize.x, 
                                      screen_coords.y / love_ScreenSize.y);
        
       
        float distFromCenter = abs(normalizedCoords.x - 0.5);
        
       
        float verticalDistortion = distFromCenter * distortionFactor;
        
     
        float yDistFromVanish = abs(normalizedCoords.y - vanishPointY);
        float stretchFactor = 10.0 + (yDistFromVanish * verticalDistortion);
        
       
        vec2 newCoords = vec2(
            texture_coords.x,
            (texture_coords.y - vanishPointY) * stretchFactor + vanishPointY
        );
        
       
        return Texel(texture, newCoords) * color;
    }
]]
