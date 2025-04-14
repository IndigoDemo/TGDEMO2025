local MengerSponge = {}
iter = 0 


function MengerSponge.new()
    local shader = love.graphics.newShader([[
        uniform float time;
        uniform vec2 resolution;
        uniform int iterations; 
        uniform float colorval; 

        const int MAX_RAY_STEPS = 64;
        const float RAY_STOP_TRESHOLD = 0.0001;


        float maxcomp(vec2 v) { return max(v.x, v.y); }

        float sdCross(vec3 p) {
            p = abs(p);
            vec3 d = vec3(max(p.y, p.x),
                          max(p.y, p.x),
                          max(p.z, p.z));
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
            float hue = 0.55-(c/2)+colorval;  //mix(0.1, 1.15, min(c * 1.2 - 0.05, 1.0));
            float sat = 1.0 - pow(c, 4.0);
            float lum = (c/3)+1;
            vec3 hsv = vec3(hue, sat, lum);
            vec3 rgb = hsv2rgb(hsv);
            return vec4(rgb, 1.0);    
        }

        vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
        {
            vec2 fragCoord = screen_coords;
            vec2 screenPos = fragCoord / resolution * 2.0 - 1.0;            
            vec3 cameraPos = vec3(time, -time/2, 0.0);
            //vec3 cameraDir = vec3(1*sin(time), .2*-cos(time), .2*-cos(time/2)+.3);
            vec3 cameraDir = vec3(1, -1 ,0);
            vec3 cameraPlaneU = vec3(1.0, 1.0, 1.0);
            vec3 cameraPlaneV = vec3(1.0, 1.0, 0.0);
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
    }
    
    function instance:update(dt, color, iterations)
        local time = love.timer.getTime()
        local colors = color
        local iter = iterations
        
        self.shader:send("colorval", colors)
        self.shader:send("time", time)
        self.shader:send("resolution", {love.graphics.getWidth(), love.graphics.getHeight()})
        self.shader:send("iterations", iter)
    end
    
    function instance:draw()
      
        love.graphics.setShader(self.shader)
        love.graphics.rectangle("fill", 0, 0, _w, _h)
        love.graphics.setShader()

    end
    
    return instance
end

return MengerSponge