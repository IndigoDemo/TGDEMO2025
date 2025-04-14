return love.graphics.newShader[[
    extern Image maskTexture;
    extern number invertFlag;

    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {

    vec4 pixel = Texel(texture, texture_coords) * color;
    
    float maskValue = Texel(maskTexture, texture_coords).r;
      
    if (invertFlag > 0.5) {
        maskValue = 1.0 - maskValue;
    }
    
    vec3 originalColor = pixel.rgb;
    vec3 invertedColor = 1.0 - pixel.rgb;
    
    vec3 finalColor = mix(originalColor, invertedColor, maskValue);
    
    return vec4(finalColor, pixel.a);
}
    ]]