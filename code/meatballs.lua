local e = {}
local balls
local x, y
local i 
function e.load()
   
    width, height = _w, _h
    e.canvas = love.graphics.newCanvas(width, height)
    balls = {}
    
    local palettes = {
        {1.0, 1.0, 1.0},  
    }
    
    for i = 1, 30 do
        local color = palettes[love.math.random(#palettes)]
        table.insert(balls, {
            x = love.math.random(100, width - 100),
            y = love.math.random(100, height - 100),
            radius = love.math.random(30, 50),
            vx = love.math.random(-30, 30),
            vy = love.math.random(-30, 30),
            mass = 0,
            strength = love.math.random(20),
            color = {color[1], color[2], color[3]}
        })
    end
    
    
    for _, ball in ipairs(balls) do
        ball.mass = ball.radius * ball.radius
    end
    
   
    resolution = 16
    
    
    threshold = 1.5
    
   
    gravityConstant = 200
    
    
    buoyancyStrength = 0
end

function e.update(dt)
    dt = dt *10
   
    applyGravity(dt)
    
   
    handleCollisions(dt)
    
    
    for i, ball in ipairs(balls) do
      
        ball.vx = ball.vx + (love.math.random() - 0.5) * 2
        ball.vy = ball.vy + (love.math.random() - 0.5) * 2
        
        
        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + ball.vy * dt
        
       
        if ball.x < ball.radius then
            ball.x = ball.radius
            ball.vx = -ball.vx * 0.8
        elseif ball.x > width - ball.radius then
            ball.x = width - ball.radius
            ball.vx = -ball.vx * 0.8
        end
        
        if ball.y < ball.radius then
            ball.y = ball.radius
            ball.vy = -ball.vy * 0.8
        elseif ball.y > height - ball.radius then
            ball.y = height - ball.radius
            ball.vy = -ball.vy * 0.8
        end
    end
end

function applyGravity(dt)
   
    for i = 1, #balls do
        for j = i + 1, #balls do
            local ball1 = balls[i]
            local ball2 = balls[j]
            
          
            local dx = ball2.x - ball1.x
            local dy = ball2.y - ball1.y
            local distSq = dx * dx + dy * dy
            local distance = math.sqrt(distSq)
            
           
            if distance < ball1.radius + ball2.radius then
                goto continue
            end
            
            local force = gravityConstant * (ball1.mass * ball2.mass) / distSq
            
           
            local fx = force * dx / distance
            local fy = force * dy / distance
            
            ball1.vx = ball1.vx + fx / ball1.mass * dt/2
            ball1.vy = ball1.vy + fy / ball1.mass * dt/2
            ball2.vx = ball2.vx - fx / ball2.mass * dt/2
            ball2.vy = ball2.vy - fy / ball2.mass * dt/2
            
            ::continue::
        end
    end
end

function handleCollisions(dt)
--nah, fuck this
end

function exponential(x, k)
    return 1 - math.exp(-k * x)
end

function e.draw()

    love.graphics.setCanvas(e.canvas)
    love.graphics.clear(0, 0, 0, 0)

    for y = 0, height, resolution do
        for x = 0, width, resolution do
            local sum = 0
            local r, g, b = 0, 0, 0
            local totalInfluence = 0
            
           
            for _, ball in ipairs(balls) do
                local dx = x - ball.x
                local dy = y - ball.y
                local distSq = dx * dx + dy * dy
                
               
                local influence = ball.strength * ball.radius * ball.radius / distSq
                sum = sum + influence
                
                if influence > 0.01 then
                    totalInfluence = totalInfluence + influence
                    r = r + ball.color[1] * influence
                    g = g + ball.color[2] * influence
                    b = b + ball.color[3] * influence
                end
            end
            
         
            if sum > threshold then
            
                if totalInfluence > 0 then
                    r = (r / totalInfluence) + math.random()*.1
                    g = (g / totalInfluence) + math.random()*.1
                    b = (b / totalInfluence) + math.random()*.1
                    alpha = 1 
                end
                
                -- Enhance color brightness based on field strength
                local intensity = math.min((sum - threshold) / 2, 1.0)
                love.graphics.setColor(r,g,b, alpha)
                
                local size = exponential(intensity, 4)

                love.graphics.rectangle("fill", x, y, size*resolution, size*resolution)
            end
        end
    end
 
    love.graphics.setCanvas()
    love.graphics.clear()
end

return e 