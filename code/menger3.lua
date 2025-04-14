local MengerSponge = {} --outer menger
local iter = 1 
local oldbeat = 0 
local hasbeaten = false

local timefactor = 5
local internaltime = 0 
function MengerSponge.new()
    local shader = love.graphics.newShader([[
        uniform float time;
        uniform vec2 resolution;
        uniform int iterations; 
        const int MAX_RAY_STEPS = 64;
        const float RAY_STOP_TRESHOLD = 0.0001;


        float maxcomp(vec2 v) { return max(v.x, v.y); }

        float sdCross(vec3 p) {
            p = abs(p);
            vec3 d = vec3(max(p.x, p.y),
                          max(p.y, p.z),
                          max(p.z, p.x));
            return min(d.x, min(d.y, d.z)) - (1.0 / 3.0);
        }

        float sdCrossRep(vec3 p) {
            vec3 q = mod(p + 1.0, 2.0) - 1.0;
            return sdCross(q);
        }

        float sdCrossRepScale(vec3 p, float s) {
            return sdCrossRep(p * s) / s;    
        }

        float scene(vec3 p) {
            float scale = 1.0;
            float dist = 0.0;
            for (int i = 0; i < iterations; i++) {
                dist = max(dist, -sdCrossRepScale(p, scale));
                scale *= 3.0;
            }
            return dist;
        }

        vec3 hsv2rgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        vec4 colorize(float c) {
            float hue = 0.69;
            float sat = 0.2;
            float lum = 1-c;
            vec3 hsv = vec3(hue, sat, lum);
            vec3 rgb = hsv2rgb(hsv);
            return vec4(rgb, 1.0);    
        }

        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            vec2 fragCoord = screen_coords;
            vec2 screenPos = fragCoord / resolution * 2.0 - 1.0;            
            vec3 cameraPos = vec3(0.0, 0.0, -time);
            vec3 cameraDir = vec3(0.0, 0.0, 1.0);
            vec3 cameraPlaneU = vec3(1.0, 0.0, 0.0);
            vec3 cameraPlaneV = vec3(0.0, 1.0, 0.0) * (resolution.y / resolution.x);
            vec3 rayPos = cameraPos;
            vec3 rayDir = cameraDir + screenPos.x * cameraPlaneU + screenPos.y * cameraPlaneV;
            
            rayDir = normalize(rayDir);
            
            float dist = scene(rayPos);
            int stepsTaken;
            for (int i = 0; i < MAX_RAY_STEPS; i++) {
                if (dist < RAY_STOP_TRESHOLD) {
                    break;
                }
                rayPos += rayDir * dist;
                dist = scene(rayPos);
                stepsTaken = i;
            }
            
            vec4 outputColor = colorize(pow(float(stepsTaken) / float(MAX_RAY_STEPS), 1));
            
            return outputColor;
        }
    ]])
    
     local instance = {
        shader = shader,
        beatfactor = {current = 1, default = 1, max = 4}
       
    }
    
    function instance:update(dt, time, beat, iteration)
        
        internaltime = internaltime + (dt * self.beatfactor.current)
        
        if self.beatfactor.current > self.beatfactor.default then 
            self.beatfactor.current = self.beatfactor.current - func.diff(self.beatfactor.current,self.beatfactor.default)*(dt*timefactor)
          
        end

        if beat == math.floor(beat) and hasbeaten == false then
            oldbeat = math.floor(beat)
            hasbeaten = true
          
            self.beatfactor.current = self.beatfactor.max
        end
        if oldbeat < math.floor(beat) then 
            hasbeaten = false
        end

       
        self.shader:send("time", internaltime)
        self.shader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        
        if iteration then 
            self.shader:send("iterations", iteration)
        else   
            self.shader:send("iterations", iter)
        end
    end
    
    function instance:draw()
       
        love.graphics.setShader(self.shader)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader()
       
    end
    
    return instance
end

return MengerSponge