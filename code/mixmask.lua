return love.graphics.newShader[[
 
extern Image maskTexture;
extern Image alternateTexture;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
   
    vec4 pixel = Texel(texture, texture_coords) * color;
    float maskValue = Texel(maskTexture, texture_coords).r;
    vec4 alternatePixel = Texel(alternateTexture, texture_coords) * color;
    vec3 finalColor = mix(pixel.rgb, alternatePixel.rgb, maskValue);
    
    return vec4(finalColor, pixel.a);
}
    ]]