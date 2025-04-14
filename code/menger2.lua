local MengerSponge = {} --inner menger
local iter = 0 
local oldbeat = 0 
local hasbeaten = false
local internaltime = 0 
local timefactor = 5
local hue = 1

function MengerSponge.new()
    local shader = love.graphics.newShader([[
        uniform float time;
        uniform float hue;
        uniform float sat = 0.4; 
        uniform vec2 resolution;
        uniform int iterations; 
        const int MAX_RAY_STEPS = 64;
        const float RAY_STOP_TRESHOLD = 0.0001;


        float maxcomp(vec2 v) { return max(v.x, v.y); }

        float sdCross(vec3 p) {
            p = abs(p);
            vec3 d = vec3(max(p.x-0.1, p.y-0.1),
                          max(p.y+0.1, p.z),
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
            //float hue = 1;
            //float sat = 0.4;
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
    
    function instance:setBeatFactor(factor)
        self.beatfactor.default = factor.default
        self.beatfactor.max = factor.max

    end


    function instance:update(dt, time, beat, colors, iteration, flag)
        if colors then 
            hue = colors.h 
            saturation = colors.s
        end
        
        internaltime = internaltime + (dt * self.beatfactor.current)
        
        if self.beatfactor.current > self.beatfactor.default then 
            self.beatfactor.current = self.beatfactor.current - func.diff(self.beatfactor.current,self.beatfactor.default)*(dt*timefactor)
            --print (self.beatfactor.current)
        end

        if beat == math.floor(beat) and hasbeaten == false then
            oldbeat = math.floor(beat)
            hasbeaten = true
            if colors then 
                hue = colors.h 
                saturation = colors.s
            else
                hue = math.abs(math.sin(internaltime))*1
            end

            iter = iter + 1
            self.beatfactor.current = self.beatfactor.max
        end
        if oldbeat < math.floor(beat) then 
            hasbeaten = false
        end

        if iter > 4 then iter = 1 end
        local i = math.floor(iter)
        self.shader:send("hue", hue)
        
        if colors then 
            self.shader:send("sat", saturation)
        end
        self.shader:send("time", internaltime)
        
        if flag then 
            self.shader:send("resolution", {love.graphics.getWidth(), love.graphics.getWidth()})
        else
            self.shader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        end            

        if iteration then 
            self.shader:send("iterations", iteration)
        else
            self.shader:send("iterations", iter)
        end
        --print (i)
    end
    
    function instance:draw()
       
        love.graphics.setShader(self.shader)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setShader()
       
    end
    
    function instance:draw2()
       
        love.graphics.setShader(self.shader)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getWidth())
        love.graphics.setShader()
       
    end


    return instance
end

return MengerSponge