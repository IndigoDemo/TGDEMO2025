e = {}

io.stdout:setvbuf('no')
local objLoader = {}
local camera = {}
local model = {
    vertices = {},
    normals = {},
    texcoords = {},
    faces = {}
}

camera.x = 0
camera.y = 0
camera.z = -5
camera.zoom = 1.5
camera.fov = 45
local rotspeed = 1
local modelRotX = 3.1415
local modelRotY = 1.571

local renderMode = "shaded" 
local currentShader = nil
local shaders = {}


function initShaders()
 
    local hologramShaderCode = [[
        uniform float time;
        uniform float modelRotX;  // Rotation around X axis
        uniform float modelRotY;  // Rotation around Y axis
        
        varying vec3 varyingNormal;
        varying vec3 varyingPosition;
        varying vec3 varyingWorldPosition;
        varying vec3 varyingLocalPosition;
        
        #ifdef VERTEX
        attribute vec3 VertexNormal;
        
        // Rotation matrix function
        mat4 rotationMatrix(vec3 axis, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            float oc = 1.0 - c;
            
            return mat4(
                oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                 0.0,                                 0.0,                                 1.0
            );
        }
        
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            // Store local position for wireframe calculation
            varyingLocalPosition = vertex_position.xyz;
            
            // Create rotation matrices
            mat4 rotX = rotationMatrix(vec3(1.0, 0.0, 0.0), modelRotX);
            mat4 rotY = rotationMatrix(vec3(0.0, 1.0, 0.0), modelRotY);
            
            // Apply rotations to the vertex position
            vec4 rotatedPosition = rotY * rotX * vertex_position;
            
            // Transform the normal
            vec4 rotatedNormal = rotY * rotX * vec4(VertexNormal, 0.0);
            varyingNormal = normalize(rotatedNormal.xyz);
            
            // Pass position
            varyingPosition = rotatedPosition.xyz;
            varyingWorldPosition = rotatedPosition.xyz;
            
            // Return final position
            return transform_projection * rotatedPosition;
        }
        #endif
        
        #ifdef PIXEL
        // Wireframe helper functions
        float gridFactor(vec3 position, float lineWidth, float cellSize) {
            vec3 coord = position / cellSize;
            vec3 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
            float line = min(min(grid.x, grid.y), grid.z);
            return 1.0 - min(line, 1.0);
        }
        
        float computeWireframe(vec3 position, float thickness) {
            // Primary grid
            float gridMain = gridFactor(position, thickness, 1.5);
            
            // Secondary grid (smaller)
            float gridSecondary = gridFactor(position, thickness * 0.5, 0.1) * 0.5;
            
            return max(gridMain, gridSecondary);
        }
        
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
            // Calculate view-space normal
            vec3 normal = normalize(varyingNormal);
            
            // Edge highlighting
            float edgeFactor = abs(dot(normal, normalize(vec3(0.0, 0.0, 1.0))));
            
            // Scan line effect
            float scanLine = sin(screen_coords.y * 0.1 + time * 2.0) * 0.8 + 0.5;
            
            // Add wireframe effect
            float wireframeThickness = 3.8;
            float wireframe = computeWireframe(varyingLocalPosition, wireframeThickness);
            
            // Make wireframe pulsate
            wireframe *= 0.7 + 0.3 * sin(time * 3.0);
            
            // Add distance fadeout for wireframe (stronger near edges)
            float distanceFromCenter = length(varyingLocalPosition);
            float fadeOut = smoothstep(0.8, 1.0, distanceFromCenter);
            wireframe = mix(wireframe, wireframe * 2.0, fadeOut);
            
            // Combine wireframe with hologram effect
            vec3 baseColor = vec3(1.0, 1.0, 1.0); // Cyan-blue hologram color
            vec3 wireframeColor = vec3(0.0, 0.0, 0.0); // White wireframe
            
            // Apply wireframe to color
            vec3 finalColor = mix(baseColor, wireframeColor, wireframe * 0.8);
            
            // Add vertical scan effect
            float verticalScan = smoothstep(0.0, 1.0, sin(time * 0.5 + varyingWorldPosition.y * 3.0) * 0.5 + 0.5);
            finalColor += vec3(0.2, 0.2, 0.2) * verticalScan;
            
            // Calculate alpha
            float alpha = (1.0 - edgeFactor * 0.8) * scanLine * 0.7 + 0.3;
            
            // Intensify edges with wireframe
            alpha = mix(alpha, 1.0, wireframe * 0.5);
            
            // Add some noise
            float noise = fract(sin(dot(screen_coords.xy, vec2(12.9898, 78.233)) * time * 0.1) * 43758.5453);
            alpha *= (0.9 + noise * 0.5);
            
            return vec4(finalColor, alpha);
        }
        #endif
    ]]
  
    local success = true
    local errorMsg = ""
    
    
    -- Create Hologram shader
    shaders.hologram = love.graphics.newShader(hologramShaderCode)
 
    currentShader = shaders.hologram
    
    return success
end


function objLoader.load(filename)
    local vertices = {}
    local normals = {}
    local texcoords = {}
    local faces = {}
    
    print (filename)
    local thefile = love.filesystem.newFile(filename,"r" )
    file = thefile
   
    if not file then
        return nil
    end
    
    for line in file:lines() do
        local words = {}
        for word in line:gmatch("%S+") do
            table.insert(words, word)
        end
        
        if #words > 0 then
            if words[1] == "v" then
                -- Vertex
                table.insert(vertices, {
                    tonumber(words[2]),
                    tonumber(words[3]),
                    tonumber(words[4])
                })
            elseif words[1] == "vn" then
                -- Normal
                table.insert(normals, {
                    tonumber(words[2]),
                    tonumber(words[3]),
                    tonumber(words[4])
                })
            elseif words[1] == "vt" then
                -- Texture coordinate
                table.insert(texcoords, {
                    tonumber(words[2]),
                    tonumber(words[3])
                })
            elseif words[1] == "f" then
                -- Face
                local face = {}
                for i = 2, #words do
                    local v, t, n = words[i]:match("(%d+)/?(%d*)/?(%d*)")
                    table.insert(face, {
                        v = tonumber(v),
                        t = t ~= "" and tonumber(t) or nil,
                        n = n ~= "" and tonumber(n) or nil
                    })
                end
                table.insert(faces, face)
            end
        end
    end
    
    file:close()
    model.vertices = vertices
    model.normals = normals
    model.texcoords = texcoords
    model.faces = faces
    objLoader.centerAndScale()
    model.mesh = objLoader.generateMesh()
    
    return model
end

function objLoader.centerAndScale()
    -- Find min and max values
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, v in ipairs(model.vertices) do
        minX = math.min(minX, v[1])
        minY = math.min(minY, v[2])
        minZ = math.min(minZ, v[3])
        
        maxX = math.max(maxX, v[1])
        maxY = math.max(maxY, v[2])
        maxZ = math.max(maxZ, v[3])
    end
    
    -- Calculate center
    local centerX = (minX + maxX) / 2
    local centerY = (minY + maxY) / 2
    local centerZ = (minZ + maxZ) / 2
    
    -- Find the maximum dimension
    local width = maxX - minX
    local height = maxY - minY
    local depth = maxZ - minZ
    local maxDim = math.max(width, height, depth)
    
    -- Scale factor to normalize to size 2
    local scale = 2 / maxDim
    
    -- Apply centering and scaling
    for i, v in ipairs(model.vertices) do
        v[1] = (v[1] - centerX) * scale
        v[2] = (v[2] - centerY) * scale
        v[3] = (v[3] - centerZ) * scale
    end
end

function objLoader.project(x, y, z)
    
    local rotY = y * math.cos(modelRotX) - z * math.sin(modelRotX)
    local rotZ = y * math.sin(modelRotX) + z * math.cos(modelRotX)
    y = rotY
    z = rotZ
    
   
    local rotX = x * math.cos(modelRotY) + z * math.sin(modelRotY)
    rotZ = -x * math.sin(modelRotY) + z * math.cos(modelRotY)
    x = rotX
    z = rotZ
    
    -- Apply camera transformations
    local tempX = x - camera.x
    local tempY = y - camera.y
    local tempZ = z - camera.z
    
    -- Simple perspective projection
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local aspect = screenWidth / screenHeight
    local fov = math.rad(camera.fov)
    local scale = camera.zoom * (screenHeight / (2 * math.tan(fov / 2)))
    
    if tempZ <= 0.1 then 
        tempZ = 0.1 
    end
    
    local projX = (tempX * scale / tempZ) * aspect + screenWidth / 2
    local projY = (tempY * scale / tempZ) + screenHeight / 2
    
    return projX, projY, tempZ
end

-- Parse .obj file and generate vertex data for shader rendering
function objLoader.generateMesh()
    if #model.vertices == 0 or #model.faces == 0 then
        return nil
    end
    
    -- Check if model has normals, if not generate them
    local hasNormals = #model.normals > 0
    if not hasNormals then
        objLoader.generateNormals()
    end
    
    -- Create vertex data for mesh
    local vertices = {}
    local indices = {}
    local indexCount = 0
    
    for _, face in ipairs(model.faces) do
        for i = 2, #face - 1 do
            -- First vertex of the triangle (the center of the fan)
            local v1 = model.vertices[face[1].v]
            local n1 = face[1].n and model.normals[face[1].n] or {0, 1, 0}
            
            -- Second vertex
            local v2 = model.vertices[face[i].v]
            local n2 = face[i].n and model.normals[face[i].n] or {0, 1, 0}
            
            -- Third vertex
            local v3 = model.vertices[face[i+1].v]
            local n3 = face[i+1].n and model.normals[face[i+1].n] or {0, 1, 0}
            
            
            table.insert(vertices, {
                v1[1], v1[2], v1[3],  -- position
                n1[1], n1[2], n1[3]   -- normal
            })
            table.insert(vertices, {
                v2[1], v2[2], v2[3],
                n2[1], n2[2], n2[3]
            })
            table.insert(vertices, {
                v3[1], v3[2], v3[3],
                n3[1], n3[2], n3[3]
            })
            
            -- Add indices
            table.insert(indices, indexCount + 1)
            table.insert(indices, indexCount + 2)
            table.insert(indices, indexCount + 3)
            indexCount = indexCount + 3
        end
    end
    
    -- Create the mesh
    local mesh = love.graphics.newMesh({
        {"VertexPosition", "float", 3},
        {"VertexNormal", "float", 3}
    }, vertices, "triangles")
    
    mesh:setVertexMap(indices)
    return mesh
end


function objLoader.generateNormals()
   
    model.normals = {}
    
    
    local faceNormals = {}
    for i, face in ipairs(model.faces) do
        if #face >= 3 then
            local v1 = model.vertices[face[1].v]
            local v2 = model.vertices[face[2].v]
            local v3 = model.vertices[face[3].v]
            
            local edge1 = {v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]}
            local edge2 = {v3[1] - v1[1], v3[2] - v1[2], v3[3] - v1[3]}
            local normal = {
                edge1[2] * edge2[3] - edge1[3] * edge2[2],
                edge1[3] * edge2[1] - edge1[1] * edge2[3],
                edge1[1] * edge2[2] - edge1[2] * edge2[1]
            }
            
            -- Normalize
            local length = math.sqrt(normal[1]^2 + normal[2]^2 + normal[3]^2)
            if length > 0 then
                normal[1] = normal[1] / length
                normal[2] = normal[2] / length
                normal[3] = normal[3] / length
            end
            
            faceNormals[i] = normal
        end
    end
    
    
    for i, normal in ipairs(faceNormals) do
       
        table.insert(model.normals, normal)
        
       
        local face = model.faces[i]
        for j, vertex in ipairs(face) do
            vertex.n = #model.normals
        end
    end
end

local function drawShaded()
    if model.mesh and currentShader then
        love.graphics.setShader(currentShader)
        
        -- Get screen center for translating model
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        
        -- Set up transformation
        love.graphics.push()
        love.graphics.translate(screenWidth / 2, screenHeight / 2)
        love.graphics.scale(200 * camera.zoom)
        
        currentShader:send("modelRotX", modelRotX)
        currentShader:send("modelRotY", modelRotY)
        
        love.graphics.setDepthMode("lequal", true)
        love.graphics.setMeshCullMode("back")
        love.graphics.draw(model.mesh)
        love.graphics.setDepthMode()
        
        love.graphics.pop()
        love.graphics.setShader()
    else
        drawWireframe()
    end
end

function e.load(thisfile)
    initShaders()
    model = objLoader.load(thisfile)
   
    model.mesh = objLoader.generateMesh()
end

function e.setvars(speed, zoom)

        camera.zoom = zoom or 1.5   

        rotspeed = speed or 1
end 
function e.resetvars()

        camera.zoom = 1.5   

        rotspeed = 1
end 


function e.update(dt)
   
    local rotationSpeed = 1.5 * dt * rotspeed
    modelRotY = modelRotY + rotationSpeed

    local prevRotX = modelRotX
    local prevRotY = modelRotY
    
    if love.keyboard.isDown("left") then
        modelRotY = modelRotY - rotationSpeed
    elseif love.keyboard.isDown("right") then
        modelRotY = modelRotY + rotationSpeed
    end
    
    if love.keyboard.isDown("up") then
        modelRotX = modelRotX - rotationSpeed
    elseif love.keyboard.isDown("down") then
        modelRotX = modelRotX + rotationSpeed
    end
    
    if prevRotX ~= modelRotX or prevRotY ~= modelRotY then
        print("Rotation: X=" .. modelRotX .. ", Y=" .. modelRotY)
    end
    
    -- Wrap rotation angles to prevent overflow
    modelRotX = modelRotX % (2 * math.pi)
    modelRotY = modelRotY % (2 * math.pi)
    
    -- Update shader time for effects
    if currentShader and currentShader:hasUniform("time") then
        currentShader:send("time", love.timer.getTime())
    end
    
    -- Update model rotation uniforms for all shaders
    if currentShader then
        if currentShader:hasUniform("modelRotX") then
            currentShader:send("modelRotX", modelRotX)
        end
        
        if currentShader:hasUniform("modelRotY") then
            currentShader:send("modelRotY", modelRotY)
        end
    end
    
    -- Update light direction for shaders
    if currentShader and currentShader:hasUniform("lightDirection") then
        currentShader:send("lightDirection", {math.cos(love.timer.getTime() * 0.5), 1.0, math.sin(love.timer.getTime() * 0.5)})
    end
    
    -- Update view position for shaders
    if currentShader and currentShader:hasUniform("viewPos") then
        currentShader:send("viewPos", {camera.x, camera.y, camera.z})
    end
    
 
end

function e.draw(thiscanvas)
    love.graphics.setColor(1, 1, 1)
    drawShaded()
end

--camera.zoom
--modelRotX
--modelRotY

return e