

local SphereInterior = {}
SphereInterior.__index = SphereInterior

function SphereInterior.new()
    local self = setmetatable({}, SphereInterior)
    
    self.radius = 10.0
    self.rotation = {x = 0, y = 0, z = 0}
    self.cameraPosition = {x = 0, y = 0, z = 5}
    self.fov = 90.0  
    
    self.shader = love.graphics.newShader[[
       
        uniform float radius;
        uniform vec3 rotation;
        uniform vec3 cameraPosition;
        uniform float fov;  // Field of view in degrees
        
      
        uniform Image texture;
        
        vec3 rotateX(vec3 p, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            return vec3(p.x, c*p.y-s*p.z, s*p.y+c*p.z);
        }
        
        vec3 rotateY(vec3 p, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            return vec3(c*p.x+s*p.z, p.y, -s*p.x+c*p.z);
        }
        
        vec3 rotateZ(vec3 p, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            return vec3(c*p.x-s*p.y, s*p.x+c*p.y, p.z);
        }
        
        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
           
            vec2 uv = (screen_coords / love_ScreenSize.xy) * 2.0 - 1.0;
            uv.x *= love_ScreenSize.x / love_ScreenSize.y; // Aspect ratio correction
            
          
            float fovRadians = radians(fov);
            float z = 1.0 / tan(fovRadians / 2.0);
            
            
            vec3 rd = normalize(vec3(uv.x, uv.y, -z));
            
           
            vec3 forward = normalize(-cameraPosition); // Look toward origin
            vec3 worldUp = vec3(0.0, 1.0, 0.0);
            vec3 right = normalize(cross(forward, worldUp));
            vec3 up = cross(right, forward);
            
           
            rd = rd.x * right + rd.y * up + rd.z * forward;
            
         
            rd = rotateX(rd, rotation.x);
            rd = rotateY(rd, rotation.y);
            rd = rotateZ(rd, rotation.z);
            
           
            vec3 ro = cameraPosition;
            
           
            float b = dot(ro, rd);
            float c = dot(ro, ro) - radius * radius;
            float discriminant = b * b - c;
            
            if (discriminant < 0.0) {
                // No intersection
                return vec4(0.0, 0.0, 0.0, 1.0);
            }
            
            float t = b + sqrt(discriminant);
            if (t < 0.0) {
                // Intersection behind camera
                return vec4(0.0, 0.0, 0.0, 1.0);
            }
            
          
            vec3 p = ro + rd * t;
            
           
            vec2 sphereUV;
            sphereUV.x = 0.5 + atan(p.z, p.x) / (2.0 * 3.14159);
            sphereUV.y = 0.5 - asin(p.y / radius) / 3.14159;
            
          
            vec4 texColor = Texel(tex, sphereUV);
            
          
            vec3 normal = normalize(p);
            float diffuse = 1.0 + 1.0 * dot(normal, normalize(vec3(1.0, 1.0, 1.0)))*0;
            
            return texColor * color * vec4(vec3(diffuse), 1.0);
        }
    ]]
    
    self:updateShaderVariables()
    
    return self
end

function SphereInterior:updateShaderVariables()
    self.shader:send("radius", self.radius)
    self.shader:send("rotation", {self.rotation.x, self.rotation.y, self.rotation.z})
    self.shader:send("cameraPosition", {self.cameraPosition.x, self.cameraPosition.y, self.cameraPosition.z})
    self.shader:send("fov", self.fov)
end

function SphereInterior:setRadius(radius)
    self.radius = radius
    self:updateShaderVariables()
end

function SphereInterior:setRotation(x, y, z)
    self.rotation.x = x or self.rotation.x
    self.rotation.y = y or self.rotation.y
    self.rotation.z = z or self.rotation.z
    self:updateShaderVariables()
end

function SphereInterior:setCameraPosition(x, y, z)
    self.cameraPosition.x = x or self.cameraPosition.x
    self.cameraPosition.y = y or self.cameraPosition.y
    self.cameraPosition.z = z or self.cameraPosition.z
    self:updateShaderVariables()
end

function SphereInterior:setFOV(fov)
    self.fov = fov
    self:updateShaderVariables()
end

function SphereInterior:draw(texture)
    love.graphics.setShader(self.shader)
    love.graphics.draw(texture or love.graphics.getBackgroundImage(), 0, 0, 0, 
                       love.graphics.getWidth() / (texture and texture:getWidth() or 1), 
                       love.graphics.getHeight() / (texture and texture:getHeight() or 1))
    love.graphics.setShader()
end

return SphereInterior