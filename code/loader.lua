local e = {}
local elapsed = 0 
local bb = 0
local lb = 0
local rb = 0   
local phase = 1
local alpha = 0 
local allalpha = 1 
local thisfont = love.graphics.newFont(40)
function e.load()
end

function e.update(dt)
	elapsed = elapsed + dt

	if phase == 1 then 
		bb = bb + dt/25 + math.random()*.002
		if bb > .4 then 
			phase = 2 
			bb = .4 
		end 
	end

	if phase == 2 then 
		lb = lb + dt/25 + math.random()*.002
		if lb > .5 then 
			phase = 3 
			lb = .5 
		end 
	end

	if phase == 3 then 
		rb = rb + dt/25 + math.random()*.002
		if rb > .5 then 
			phase = 4 
			rb = .5 
		end 
	end

	if phase == 4 then 
		alpha = alpha + dt/3
		if alpha > 1 then 
			alpha = 1
			phase = 5
		end
	end

	if phase == 5 then 
		allalpha = allalpha - dt/3
		if allalpha < 0 then 
			allalpha = 0
			phase = 6
		end
	end
return phase 
end

function e.phase()
	return phase
end

function e.draw()
	if phase < 5 then 
							love.graphics.rectangle("line", _w*.3, _h*.7, _w*.4, _h*.1) --bottom bar
							love.graphics.rectangle("fill", _w*.3, _h*.7, _w*bb, _h*.1) --bottom bar w.4
		if phase > 1 then 	love.graphics.rectangle("line", _w*.3, _h*.2, _w*.06,_h*.5) 
							love.graphics.rectangle("fill", _w*.3, _h*.2, _w*.06,_h*lb) -- left bar  h.5
		end
	 
		if phase > 2 then 	love.graphics.rectangle("line", _w*.64, _h*.2, _w*.06,_h*.5) --right bar
							love.graphics.rectangle("fill", _w*.64, _h*.2, _w*.06,_h*rb) --right bar h.5
		end 

	--if phase > 4 then 	



		
		love.graphics.setColor(1,1,1,alpha)
	else 
		love.graphics.setColor(1,1,1,allalpha)
							love.graphics.rectangle("fill", _w*.3, _h*.7, _w*bb, _h*.1) --bottom bar w.4
		if phase > 1 then 	 
							love.graphics.rectangle("fill", _w*.3, _h*.2, _w*.06,_h*lb) -- left bar  h.5
		end
		 
		if phase > 2 then 	
							love.graphics.rectangle("fill", _w*.64, _h*.2, _w*.06,_h*rb) --right bar h.5
		end 

		
	end

	love.graphics.setFont(thisfont)
	local text = "I n d i g o  D e m o  D i v i s i o n"
	local textWidth = thisfont:getWidth(text)
	love.graphics.print(text, _w*.5, _h*.85,0,1,1,textWidth/2)

	love.graphics.rectangle("fill", _w*.47, _h*.2, _w*.06, _h*.1) -- dot
	love.graphics.rectangle("fill", _w*.47, _h*.35, _w*.06, _h*.3) -- i
	love.graphics.setColor(1,1,1,1)

end

return e