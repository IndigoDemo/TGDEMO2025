
extern vec2 cameraPos; // Camera position (x, z)
extern float cameraHeight; // Camera height (y coordinate)
extern float cameraAngle; // Camera angle in radians
extern float fov; // Field of view in radians
extern float aspect; // Screen aspect ratio (width / height)
extern vec2 floorMovement; // Floor texture movement (x, z)
extern vec2 ceilingMovement; // Ceiling texture movement (x, z)
extern float floorTextureScale; // Scale of the floor texture
extern float ceilingTextureScale; // Scale of the ceiling texture
extern vec3 fogColor; // RGB fog color
extern float fogDensity; // Fog density (0.0 - 1.0)
extern float maxFogDistance; // Maximum distance before complete fog

vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords) {
    vec2 ndc = (screenCoords / love_ScreenSize.xy) * 2.0 - 1.0;
    ndc.x *= aspect;
    vec3 baseRayDir = normalize(vec3(ndc.x * tan(fov/2.0), -ndc.y * tan(fov/2.0), 1.0));
    float cosAngle = cos(cameraAngle);
    float sinAngle = sin(cameraAngle);
    vec3 rayDir = normalize(vec3(
        baseRayDir.x * cosAngle - baseRayDir.z * sinAngle,
        baseRayDir.y,
        baseRayDir.x * sinAngle + baseRayDir.z * cosAngle
    ));
    vec3 cameraPos3D = vec3(cameraPos.x, cameraHeight, cameraPos.y);
    float t_floor = -cameraPos3D.y / rayDir.y;
    float t_ceiling = (1.0 - cameraPos3D.y) / rayDir.y;
    vec4 finalColor = vec4(0.1, 0.3, 0.8, 1.0);
    if (rayDir.y < 0.0 && t_floor > 0.0) {
        vec3 floorPoint = cameraPos3D + rayDir * t_floor;
        vec2 floorUV = vec2(floorPoint.x + floorMovement.x, floorPoint.z + floorMovement.y);
        floorUV = floorUV * floorTextureScale;
        vec4 floorColor = Texel(texture, mod(floorUV, 1.0));
        float distance = t_floor;
        float fogFactor = clamp(distance / maxFogDistance, 0.0, 1.0);
        fogFactor = pow(fogFactor, fogDensity);
        finalColor = mix(floorColor, vec4(fogColor, 1.0), fogFactor);
    }
    else if (rayDir.y > 0.0 && t_ceiling > 0.0) {
        vec3 ceilingPoint = cameraPos3D + rayDir * t_ceiling;
        vec2 ceilingUV = vec2(ceilingPoint.x + ceilingMovement.x, ceilingPoint.z + ceilingMovement.y);
        ceilingUV = ceilingUV * ceilingTextureScale;
        vec4 ceilingColor = Texel(texture, mod(ceilingUV, 1.0));
        float distance = t_ceiling;
        float fogFactor = clamp(distance / maxFogDistance, 0.0, 1.0);
        fogFactor = pow(fogFactor, fogDensity);
        finalColor = mix(ceilingColor, vec4(fogColor, 1.0), fogFactor);
    }
    return finalColor * color;
}