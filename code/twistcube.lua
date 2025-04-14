local e = {}
	
e.canvas = love.graphics.newCanvas()

local config = {
    segmentsPerAxis = 3,  -- Number of segments per axis
    cubeSize = 150,       -- Overall cube size
    rotationSpeed = 1.5,  -- Base rotation speed
    twistSpeed = 0.8,     -- Twist animation speed
    twistAmount = 6.28,    -- Maximum twist amount (in radians)
    cameraDistance = 300,  -- Distance from camera to cube (increased)
}

local function createRotationMatrix(angleX, angleY, angleZ)
    local cosX, sinX = math.cos(angleX), math.sin(angleX)
    local cosY, sinY = math.cos(angleY), math.sin(angleY)
    local cosZ, sinZ = math.cos(angleZ), math.sin(angleZ)
    
    return {
        { cosY * cosZ, cosY * sinZ, -sinY, 0 },
        { sinX * sinY * cosZ - cosX * sinZ, sinX * sinY * sinZ + cosX * cosZ, sinX * cosY, 0 },
        { cosX * sinY * cosZ + sinX * sinZ, cosX * sinY * sinZ - sinX * cosZ, cosX * cosY, 0 },
        { 0, 0, 0, 1 }
    }
end

local function multiplyMatrixVector(m, v)
    local x = m[1][1] * v[1] + m[1][2] * v[2] + m[1][3] * v[3] + m[1][4] * v[4]
    local y = m[2][1] * v[1] + m[2][2] * v[2] + m[2][3] * v[3] + m[2][4] * v[4]
    local z = m[3][1] * v[1] + m[3][2] * v[2] + m[3][3] * v[3] + m[3][4] * v[4]
    local w = m[4][1] * v[1] + m[4][2] * v[2] + m[4][3] * v[3] + m[4][4] * v[4]
    
    return {x, y, z, w}
end

local angleX, angleY, angleZ = 0, 0, 0
local segments = {}
local cubeVertices = {}
local cubeFaces = {}
local twistAngle = 0
local twistDirection = 1

function initializeCubeSegments()
    -- Create segments for the cube
    for x = 1, config.segmentsPerAxis do
        segments[x] = {}
        for y = 1, config.segmentsPerAxis do
            segments[x][y] = {}
            for z = 1, config.segmentsPerAxis do
                segments[x][y][z] = {
                    -- Normalized position (-1 to 1 range)
                    position = {
                        x = (x / config.segmentsPerAxis) * 2 - 1 - (1/config.segmentsPerAxis),
                        y = (y / config.segmentsPerAxis) * 2 - 1 - (1/config.segmentsPerAxis),
                        z = (z / config.segmentsPerAxis) * 2 - 1 - (1/config.segmentsPerAxis)
                    },
                    -- Colors will be assigned based on position
                    color = {
                        r = x / config.segmentsPerAxis,
                        g = y / config.segmentsPerAxis,
                        b = z / config.segmentsPerAxis,
                        a = 1
                    },
                    -- Twist angle for this segment
                    twist = 0
                }
            end
        end
    end
end

function generateCubeGeometry()
    local segSize = 2 / config.segmentsPerAxis
    
    -- For each segment, generate a cube
    for x = 1, config.segmentsPerAxis do
        for y = 1, config.segmentsPerAxis do
            for z = 1, config.segmentsPerAxis do
                local segment = segments[x][y][z]
                local pos = segment.position
                local halfSize = segSize / 2
                
                -- Define the eight corners of this segment
                local startIdx = #cubeVertices + 1
                
                -- Add 8 vertices for this segment's cube
                table.insert(cubeVertices, {pos.x - halfSize, pos.y - halfSize, pos.z - halfSize, 1, segment.color})
                table.insert(cubeVertices, {pos.x + halfSize, pos.y - halfSize, pos.z - halfSize, 1, segment.color})
                table.insert(cubeVertices, {pos.x + halfSize, pos.y + halfSize, pos.z - halfSize, 1, segment.color})
                table.insert(cubeVertices, {pos.x - halfSize, pos.y + halfSize, pos.z - halfSize, 1, segment.color})
                table.insert(cubeVertices, {pos.x - halfSize, pos.y - halfSize, pos.z + halfSize, 1, segment.color})
                table.insert(cubeVertices, {pos.x + halfSize, pos.y - halfSize, pos.z + halfSize, 1, segment.color})
                table.insert(cubeVertices, {pos.x + halfSize, pos.y + halfSize, pos.z + halfSize, 1, segment.color})
                table.insert(cubeVertices, {pos.x - halfSize, pos.y + halfSize, pos.z + halfSize, 1, segment.color})
                
                -- Define the 6 faces of this segment's cube (each with 4 vertices)
                -- Front face
                table.insert(cubeFaces, {startIdx, startIdx+1, startIdx+2, startIdx+3, segment})
                -- Back face
                table.insert(cubeFaces, {startIdx+4, startIdx+5, startIdx+6, startIdx+7, segment})
                -- Left face
                table.insert(cubeFaces, {startIdx, startIdx+3, startIdx+7, startIdx+4, segment})
                -- Right face
                table.insert(cubeFaces, {startIdx+1, startIdx+2, startIdx+6, startIdx+5, segment})
                -- Top face
                table.insert(cubeFaces, {startIdx+3, startIdx+2, startIdx+6, startIdx+7, segment})
                -- Bottom face
                table.insert(cubeFaces, {startIdx, startIdx+1, startIdx+5, startIdx+4, segment})
            end
        end
    end
end

function e.update(dt)
    -- Update global rotation
    angleX = angleX + dt * config.rotationSpeed * 0.5
    angleY = angleY + dt * config.rotationSpeed
    angleZ = angleZ + dt * config.rotationSpeed * 0.3
    
    -- Update twist animation
    twistAngle = twistAngle + dt * config.twistSpeed * twistDirection
    if math.abs(twistAngle) > config.twistAmount then
        twistDirection = -twistDirection
    end
    
    -- Apply twist to segments (around y-axis for this example)
    for x = 1, config.segmentsPerAxis do
        for y = 1, config.segmentsPerAxis do
            for z = 1, config.segmentsPerAxis do
                -- Different twisting patterns
                local segment = segments[x][y][z]
                
                -- Y axis twist - each Y layer gets twisted
                segment.twist = twistAngle * (y / config.segmentsPerAxis)
                
                -- You could create other twisting patterns here
            end
        end
    end
end

function e.draw()
    love.graphics.setCanvas(e.canvas)
    love.graphics.clear()
    local width, height = love.graphics.getDimensions()
    local centerX, centerY = width / 2, height / 2
    
    -- Background
    --love.graphics.setBackgroundColor(0.15, 0.15, 0.2)
    --love.graphics.clear()
    
    -- Create global rotation matrix
    local rotMatrix = createRotationMatrix(angleX, angleY, angleZ)
    
    -- Prepare transformed vertices for drawing
    local transformedVertices = {}
    for i, v in ipairs(cubeVertices) do
        -- Apply segment-specific twist (around Y axis)
        local segment = nil
        for _, face in ipairs(cubeFaces) do
            for j = 1, 4 do
                if face[j] == i then
                    segment = face[5]
                    break
                end
            end
            if segment then break end
        end
        
        local vertex = {v[1], v[2], v[3], v[4]}
        
        -- Apply twist if segment found
        if segment then
            local twistMatrix = createRotationMatrix(0, segment.twist, 0)
            vertex = multiplyMatrixVector(twistMatrix, vertex)
        end
        
        -- Apply global rotation
        local rotated = multiplyMatrixVector(rotMatrix, vertex)
        
        -- Simple perspective projection
        local z = rotated[3] + config.cameraDistance  -- Apply camera distance
        local scale = 600 / z     -- Adjusted perspective scaling factor
        
        transformedVertices[i] = {
            x = centerX + rotated[1] * scale * config.cubeSize/2,
            y = centerY + rotated[2] * scale * config.cubeSize/2,
            z = rotated[3],
            color = v[5]
        }
    end
    
    -- Sort faces by z-value (simple painter's algorithm)
    table.sort(cubeFaces, function(a, b)
        -- Calculate center z positions for comparison
        local aZ = (transformedVertices[a[1]].z + 
                   transformedVertices[a[2]].z + 
                   transformedVertices[a[3]].z + 
                   transformedVertices[a[4]].z) / 4
                   
        local bZ = (transformedVertices[b[1]].z + 
                   transformedVertices[b[2]].z + 
                   transformedVertices[b[3]].z + 
                   transformedVertices[b[4]].z) / 4
                   
        return aZ < bZ
    end)
    
    -- Draw all faces
    for _, face in ipairs(cubeFaces) do
        local v1 = transformedVertices[face[1]]
        local v2 = transformedVertices[face[2]]
        local v3 = transformedVertices[face[3]]
        local v4 = transformedVertices[face[4]]
        local segment = face[5]
        
        -- Calculate lighting factor based on face normal
        local ax = v2.x - v1.x
        local ay = v2.y - v1.y
        local bx = v3.x - v2.x
        local by = v3.y - v2.y
        
        -- Simple 2D normal approximation for lighting
        local nx = ay * by - ax * by
        local ny = ax * bx - ay * bx
        local len = math.sqrt(nx * nx + ny * ny)
        
        -- Avoid division by zero
        if len > 0.001 then
            nx, ny = nx / len, ny / len
        end
        
        -- Calculate light factor
        local lightFactor = (nx * 0.5 + 0.8) -- Adjusted for better visual
        
        -- Clamp light factor
        lightFactor = math.max(0.4, math.min(1.0, lightFactor))
        
        -- Apply lighting to segment color
        local r = segment.color.r * lightFactor
        local g = segment.color.g * lightFactor
        local b = segment.color.b * lightFactor
        
        -- Draw filled face with flat shading
        love.graphics.setColor(r, g, b)
        love.graphics.polygon("fill", v1.x, v1.y, v2.x, v2.y, v3.x, v3.y, v4.x, v4.y)
        
        -- Draw edge outlines
        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(1)
        love.graphics.polygon("line", v1.x, v1.y, v2.x, v2.y, v3.x, v3.y, v4.x, v4.y)
    	love.graphics.setColor(0, 0, 0)
    end
    love.graphics.setCanvas()
 end

function e.load()
	initializeCubeSegments()
	generateCubeGeometry()
end


return e

