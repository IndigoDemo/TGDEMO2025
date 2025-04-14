
local Arwing = {}
Arwing.__index = Arwing

local function project3D(x, y, z, camX, camY, camZ, fov, aspect, near, far)
    local dx = x - camX
    local dy = y - camY
    local dz = z - camZ
    if dz <= 0 then
        return nil, nil
    end
    local scale = 1 / math.tan(fov / 2)
    local screenX = (dx / dz) * scale * aspect * 300
    local screenY = (dy / dz) * scale * 300
    return screenX, screenY
end

local function rotatePoint(x, y, z, rotX, rotY, rotZ)
    local sinX, cosX = math.sin(rotX), math.cos(rotX)
    local sinY, cosY = math.sin(rotY), math.cos(rotY)
    local sinZ, cosZ = math.sin(rotZ), math.cos(rotZ)
    local y1 = y * cosX - z * sinX
    local z1 = y * sinX + z * cosX
    local x2 = x * cosY + z1 * sinY
    local z2 = -x * sinY + z1 * cosY
    local x3 = x2 * cosZ - y1 * sinZ
    local y3 = x2 * sinZ + y1 * cosZ
    return x3, y3, z2
end

function Arwing.new()
    local self = setmetatable({}, Arwing)
    self.x = 0
    self.y = 0
    self.z = 200
    self.rotX = 0  
    self.rotY = 0  
    self.rotZ = 0  
    self.vertices = {
        -- Nose
        {0, 0, -50}, 
        
        -- Main  
        {-15, 0, 0},   
        {15, 0, 0},    
        {-20, 0, 30},  
        {20, 0, 30},   
        {0, 10, 20},   
        {0, -5, 20},   
        
        -- Wing 
        {-60, 0, 0},   
        {60, 0, 0},    
        {-40, 0, 20},  
        {40, 0, 20},   
        
        -- Fin 
        {-10, 15, 40}, 
        {10, 15, 40},  
        {0, 0, 40}     
    }
    
    self.faces = {
        -- Nose to body
        {1, 2, 3},    
        {1, 2, 6},    
        {1, 3, 6},    
        {1, 2, 7},     
        {1, 3, 7},    
        
        -- Main body
        {2, 4, 6},     
        {3, 5, 6},     
        {2, 4, 7},    
        {3, 5, 7},    
        {4, 5, 6},     
        {4, 5, 7},     
        
        -- Left wing
        {2, 4, 8},    
        {2, 4, 10},    
        {8, 4, 10},   
        
        -- Right wing
        {3, 5, 9},     
        {3, 5, 11},    
        {9, 5, 11},    
        
        -- Fins
        {4, 6, 12},    
        {5, 6, 13},    
        {6, 12, 13},   
        {5, 13, 14},   
        {4, 12, 14},   
    }
    
    local factor = .6
    
    self.colors = {
        {0.7, 0.7*factor, 0.9}, 
        {0.5, 0.5*factor, 0.7}, 
        {0.3, 0.3*factor, 0.5}, 
        {0.2, 0.8*factor, 0.9}, 
        {0.1, 0.6*factor, 0.7}, 
        {0.6, 0.6*factor, 0.8}, 
    }
    
    return self
end

    
function Arwing:update(dt, controls)
    -- absolute rotation 
    self.rotX = controls.pitch  
    self.rotY = controls.yaw   
    self.rotZ = controls.roll   
    
    -- absolute movement 
    self.x =  controls.x  
    self.y =  controls.y  
    self.z =  controls.z  
end


function Arwing:draw()
    
    local camX, camY, camZ = 0, 0, -500
    local fov = math.pi / 3
    local aspect = love.graphics.getWidth() / love.graphics.getHeight()
    local projectedPoints = {}
    for i, v in ipairs(self.vertices) do
        local x, y, z = rotatePoint(v[1], v[2], v[3], self.rotX, self.rotY, self.rotZ)
        x = x + self.x
        y = y + self.y
        z = z + self.z
        local screenX, screenY = project3D(x, y, z, camX, camY, camZ, fov, aspect, 0.1, 10000)
        projectedPoints[i] = {screenX, screenY, z}
    end
    
   
    local sortedFaces = {}
    for i, face in ipairs(self.faces) do
        local v1 = projectedPoints[face[1]]
        local v2 = projectedPoints[face[2]]
        local v3 = projectedPoints[face[3]]
          if v1 and v2 and v3 then
            local avgZ = (v1[3] + v2[3] + v3[3]) / 3
            table.insert(sortedFaces, {
                indices = face,
                z = avgZ,
                colorIdx = (i % #self.colors) + 1
            })
        end
    end

    table.sort(sortedFaces, function(a, b) return a.z > b.z end)

    for _, face in ipairs(sortedFaces) do
        local v1 = projectedPoints[face.indices[1]]
        local v2 = projectedPoints[face.indices[2]]
        local v3 = projectedPoints[face.indices[3]]
        local color = self.colors[face.colorIdx]
        love.graphics.setColor(color[1], color[2], color[3])
        love.graphics.polygon("fill", 
            v1[1], v1[2],
            v2[1], v2[2],
            v3[1], v3[2]
        )
        love.graphics.setLineWidth( 1 )
        love.graphics.setColor(func.toRGB(45,226,230), 1)
        love.graphics.polygon("line", 
            v1[1], v1[2],
            v2[1], v2[2],
            v3[1], v3[2]
        )
        love.graphics.setLineWidth( 1 )
    end
end

return Arwing