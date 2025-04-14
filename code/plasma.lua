local plasma = {}

plasma.width = 800
plasma.height = 600
plasma.scale = 1
plasma.speed = 1
plasma.colorCycle = true
local canvas
local shader
local time = 0
local x = 0

function plasma.init(width, height, scale)
    plasma.width = width or love.graphics.getWidth()
    plasma.height = height or love.graphics.getHeight()
    plasma.scale = scale or 1
    plasma.canvas = love.graphics.newCanvas(plasma.width / plasma.scale, plasma.height / plasma.scale)
    
    local shaderCode = [[
        extern number time;
        
        vec3 hsv2rgb(vec3 c) {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            // Calculate plasma value
            float x = screen_coords.x / love_ScreenSize.x;
            float y = screen_coords.y / love_ScreenSize.y;
            
            float v1 = sin((x * 10.0) + time);
            float v2 = sin((y * 10.0) + time);
            float v3 = sin((x * 10.0 + y * 10.0) + time);
            float v4 = sin(sqrt((x - 0.5) * (x - 0.5) + (y - 0.5) * (y - 0.5)) * 20.0 + time);
            
            float plasma = (v1 + v2 + v3 + v4) / 4.0;
            
            // Map plasma value to color
            vec3 hsv = vec3(plasma * 0.5 + 0.5 + time * 0.1, 1.0, 1.0);
            vec3 rgb = hsv2rgb(hsv);
            
            return vec4(rgb, 1.0) * color;
        }
    ]]
    
    shader = love.graphics.newShader(shaderCode)
    
    return plasma
end

function plasma.update(dt)
    time = time + dt * plasma.speed
    
    if shader then
        shader:send("time", time)
    end
end
function plasma.draw(x,y)
    y = y or 0 
    if not plasma.canvas or not shader then
        plasma.init()
    end
    love.graphics.setCanvas(plasma.canvas)
    love.graphics.clear()
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, plasma.canvas:getWidth(), plasma.canvas:getHeight())
    love.graphics.setShader()
    love.graphics.setCanvas()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.draw(plasma.canvas, 0, y, 0, plasma.scale, plasma.scale)
    love.graphics.setBlendMode("alpha")
end

function plasma.dispose()
    if canvas then
        canvas:release()
        canvas = nil
    end
    shader = nil
end

return plasma