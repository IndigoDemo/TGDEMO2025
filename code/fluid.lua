local fluid = {}
local width, height = _w, _h
local centerX, centerY = width/2, height/2
local particleCount = 50000
local planetRadius = 50
local moonRadius = 20
local moonOrbitRadius = 200
local moonOrbitSpeed = 0.5
local cameraRotationSpeed = 0.05
local cameraAngle = 0
local particleSize = 2
local gravityStrength = 2000
local moonGravityStrength = 3000
local fluidViscosity = 0.9998
local timeStep = 3
local cameraDistance = 1500
local particles = {}
function fluid.load()
    
    for i = 1, particleCount do
        local u = math.random() * 2 - 1  
        local theta = math.random() * math.pi * 2
        local radius = planetRadius + math.random(10, 50)
        
        local phi = math.acos(u)
        local x = radius * math.sin(phi) * math.cos(theta)
        local y = radius * math.sin(phi) * math.sin(theta)
        local z = radius * math.cos(phi)
        
        table.insert(particles, {
            pos = {x = x, y = y, z = z},
            vel = {x = math.random(-2, 2), y = math.random(-2, 2), z = math.random(-2, 2)},
            color = {
                r = 0.2 + 0.6 * math.random(),
                g = 0.5 + 0.5 * math.random(),
                b = 0.7 + 0.3 * math.random(),
                a = 0.7 + 0.3 * math.random()
            },
            size = particleSize * (0.7 + 0.6 * math.random())
        })
    end

    metaballShader = love.graphics.newShader[[
        extern float threshold;
        extern vec3 fluidColor;
        
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(tex, texture_coords);
            
            // Metaball effect: create smooth fluid from particle density
            float value = pixel.r;
            float alpha = smoothstep(threshold - 1, threshold, value);
            
            // Add fluid shading (fake lighting)
            vec3 normal = vec3(
                Texel(tex, texture_coords + vec2(0.001, 0.0)).r - Texel(tex, texture_coords - vec2(0.001, 0.0)).r,
                Texel(tex, texture_coords + vec2(0.0, 0.001)).r - Texel(tex, texture_coords - vec2(0.0, 0.001)).r,
                0.01
            );
            normal = normalize(normal);
            
            // Lighting direction
            vec3 lightDir = normalize(vec3(0.5, 0.7, 0.5));
            float diffuse = max(0.0, dot(normal, lightDir)) * 1.6 + 0.4;
            
            // Specular highlight
            vec3 viewDir = vec3(0.0, 0.0, -0.5);
            vec3 halfDir = normalize(lightDir + viewDir);
            float specular = pow(max(0.0, dot(normal, halfDir)), 32.0) * 0.6;
            
            // Final color
            vec3 finalColor = fluidColor * diffuse + vec3(specular);
            
            return vec4(finalColor, alpha * 1.0);
        }
    ]]
    
    metaballShader:send("threshold", 0.75)
    metaballShader:send("fluidColor", {0.6, 0.2, 0.9})
    
    particleCanvas = love.graphics.newCanvas()
    fluid.fluidcanvas = love.graphics.newCanvas()
end

function fluid.update(dt)
    
    local colorPhase = (t.beat * 0.1 ) % 1
        local r, g, b
        
        if colorPhase < 0.2 then
            
            r = 1
            g = colorPhase * 5
            b = 0
        elseif colorPhase < 0.4 then
           
            r = 1 - (colorPhase - 0.2) * 5
            g = 1
            b = 0
        elseif colorPhase < 0.6 then
           
            r = 0
            g = 1
            b = (colorPhase - 0.4) * 5
        elseif colorPhase < 0.8 then
           
            r = 0
            g = 1 - (colorPhase - 0.6) * 5
            b = 1
        else

            r = (colorPhase - 0.8) * 5
            g = 0
            b = 1
        end
   
         metaballShader:send("fluidColor", {r*.5,g*.5,b*.5})

    dt = dt * 8
 
    local moonAngle = love.timer.getTime() * moonOrbitSpeed
    local moonX = moonOrbitRadius * math.cos(moonAngle)
    local moonY = 0
    local moonZ = moonOrbitRadius * math.sin(moonAngle)

    for i, p in ipairs(particles) do
     
        local distX, distY, distZ = -p.pos.x, -p.pos.y, -p.pos.z
        local distSq = distX*distX + distY*distY + distZ*distZ
        local dist = math.sqrt(distSq)
        local force = gravityStrength / distSq
        p.vel.x = p.vel.x + (distX / dist) * force * dt
        p.vel.y = p.vel.y + (distY / dist) * force * dt
        p.vel.z = p.vel.z + (distZ / dist) * force * dt
        local moonDistX = p.pos.x - moonX
        local moonDistY = p.pos.y - moonY
        local moonDistZ = p.pos.z - moonZ
        local moonDistSq = moonDistX*moonDistX + moonDistY*moonDistY + moonDistZ*moonDistZ
        local moonDist = math.sqrt(moonDistSq)
        if moonDist > moonRadius then 
            local moonForce = moonGravityStrength / moonDistSq  -- Increased from 100 to 2000
            p.vel.x = p.vel.x + (moonDistX / moonDist) * moonForce * dt * -5  -- Note the -1 to pull toward moon
            p.vel.y = p.vel.y + (moonDistY / moonDist) * moonForce * dt * -5
            p.vel.z = p.vel.z + (moonDistZ / moonDist) * moonForce * dt * -5
        end
        p.vel.x = p.vel.x * fluidViscosity
        p.vel.y = p.vel.y * fluidViscosity
        p.vel.z = p.vel.z * fluidViscosity
        p.pos.x = p.pos.x + p.vel.x * dt
        p.pos.y = p.pos.y + p.vel.y * dt
        p.pos.z = p.pos.z + p.vel.z * dt
    end
end

function project(x, y, z, camX, camY, camZ)
    local dx = x - camX
    local dy = y - camY
    local dz = z - camZ
    local scale = 800 / (dz + 800)
    local offsetX = 0.18 * dz 
    local offsetY = 0.04 * dz  
    return centerX + (dx + offsetX) * scale, centerY + (dy + offsetY) * scale, scale
end

function fluid.draw()
    love.graphics.clear()
    local camX = math.sin(cameraAngle) * cameraDistance * 0.9 - 300 
    local camY = math.sin(cameraAngle * 0.5) * 150 -50  
    local camZ = math.cos(cameraAngle) * cameraDistance * 1.1  
    love.graphics.setCanvas(particleCanvas)
    love.graphics.clear(0, 0, 0, 0)
    for i, p in ipairs(particles) do
        local screenX, screenY, particleScale = project(p.pos.x, p.pos.y, p.pos.z, camX, camY, camZ)
        local depth = (p.pos.x-camX)^2 + (p.pos.y-camY)^2 + (p.pos.z-camZ)^2
        local size = p.size * particleScale * 3  -- Larger for better blending
        local intensity = math.min(1.0, 1.0 / (depth / 5000000 + 0.1))
        if screenX > -size and screenX < width + size and 
           screenY > -size and screenY < height + size then
            love.graphics.setColor(intensity, intensity, intensity, 1)
            love.graphics.circle("fill", screenX, screenY, size)
        end
    end
    love.graphics.setCanvas(fluid.fluidcanvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setShader(metaballShader)
    love.graphics.draw(particleCanvas)
    love.graphics.setShader()
    love.graphics.setCanvas()
    local moonAngle = love.timer.getTime() * moonOrbitSpeed
    local moonX = moonOrbitRadius * math.cos(moonAngle)
    local moonY = 0
    local moonZ = moonOrbitRadius * math.sin(moonAngle)
    local moonProjX, moonProjY, moonScale = project(moonX, moonY, moonZ, camX, camY, camZ)
    local moonProjSize = moonRadius * moonScale
    local planetProjX, planetProjY, planetScale = project(0, 0, 0, camX, camY, camZ)
    local planetProjRadius = planetRadius * planetScale
    love.graphics.setColor(1, 1, 1, 1)

end

return fluid