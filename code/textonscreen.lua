local e = {}
local thatfont = love.graphics.newFont("/media/NeoBulletin Italic.ttf", math.floor(100* global.scale) )

local wordlist = {}
local text = {}
local timing 
local inctext = 0 
local internaltime = 0
local ypos = _h/2
local ypos2 = _h*.7
local xpos = _w/2
local alpha = 0
local rolling
local oldbeat = 0 
local yfactor = 190
local afactor = .6
local bindex = 7 
local maxbindex = 7
local newscale = 1
local rindex = 1 
local jomsfix = love.graphics.newCanvas()
function colorfucker(time)
 	local colorPhase = (time * 0.1 ) % 1
 	local r, g, b
    
	if colorPhase < 0.2 then
	    -- Red to Yellow
	    r = 1
	    g = colorPhase * 5
	    b = 0
	elseif colorPhase < 0.4 then
	    -- Yellow to Green
	    r = 1 - (colorPhase - 0.2) * 5
	    g = 1
	    b = 0
	elseif colorPhase < 0.6 then
	    -- Green to Cyan
	    r = 0
	    g = 1
	    b = (colorPhase - 0.4) * 5
	elseif colorPhase < 0.8 then
	    -- Cyan to Blue
	    r = 0
	    g = 1 - (colorPhase - 0.6) * 5
	    b = 1
	else
	    -- Blue to Magenta
	    r = (colorPhase - 0.8) * 5
	    g = 0
	    b = 1
	end
	local rgb = {r,g,b}
	return rgb
end

function e.load()

	wordlist = 	{word = {		"I", "IS", "FOR", "INTELLIGENT", "AS", "SMART", "AS", "THEY", "COME", 		--9
								"N", "IS", "FOR", "NICE", "BECAUSE", "IT'S", "NICE", "TO", "BE", "NICE", 	--19
								"D", "IS", "FOR", "DETERMINED", "CAUSE", "WE", "NEVER", "GIVE", "UP"," ",  	--29
								"I", "IS", "FOR", "INTELLIGENT", "GOTTA", "SAY", "IT", "AGAIN",				--37
								"G", "IS", "FOR", "GORGEOUS", "JUST", "LOOK", "AT", "THESE", "FACES",		--46
								"O", "IS", "FOR", "OBNOXIOUS", "FUCKING", "OBNOXIOUS", 						--52
					            "F&CK", "C%NT", "B@TCH", "HESTK&K", "F!TT3", "RUMPEH%LL", "TI55EFANT", "TARMSLYNG", "TG:GAME",  --61
					            "[INDIGO]", --62
					            -- music   dance    resources  code
					            " ", "KEPLER", "ANYA", "KEPLER", "JOMS", "KIMMEY", "SUNO v4", "KEPLER", "[INDIGO]", " " 
					},
					 timing = { .3, .2, .4, 1.1, .2, .3, .3, .3, 1.8, .3, .2, .2, .4, .6, .3, .2, .3, .5, 1.3, .3, .3, .3, .7, .4, .3, .4, .2, 2, 4.3, .3, .3, .3, 1, .3, .3, .3, 1.9, .2, .2, .3, 1, .3, .3, .3, .6,   1.2, .3, .3, .3, 1.8, 0.9, 3.3, .3, .3, .2, .2,.2,.3,.3,.3,.3, 10,
					 			10, 10, 10, 10},
					 		--   i  is  for int as sm  as  th  come   n  is  for ni  bec  it ni  to  be  ni    d   is  fo  de  ca  we ne  gi   up       i  is  fo  in  go  sa  it  ag    g  is  fo  gor jus loo at the fac    o  is  for obn  fu ob 
					 index = 1
				}

	rolelist = {" ", "Music:", "Performance Art: ", "GFX:" , "Resources: ", "Models: ", "Vocals: ", "Code: ", "We're Back, baby!", " "}

end

function e.setIndex(index)
	wordlist.index = index
end

function e.update(dt, beat, flag)
	flag = flag
	timing = beat
	if flag then
	else 
		newscale = global.scale  
		if timing > 25 then ypos = _h*.8 end 
		if timing > 59.4 then ypos = _h*.5 end 
		alpha = 1
		
		if beat > 240 then 
			xpos = _w*.5
			newscale = global.scale
		end

		internaltime = internaltime + dt
		if internaltime > wordlist.timing[wordlist.index]*.8 then 
			internaltime = internaltime - wordlist.timing[wordlist.index]*.8
			wordlist.index = wordlist.index + 1
			if wordlist.index > #wordlist.timing then wordlist.index = #wordlist.timing end
		end
	end 
	
	if flag == 1 then 
		newscale = global.scale * .6 
		
		if timing == math.floor(timing) and math.floor(timing) > oldbeat then
			oldbeat = math.floor(timing)
			bindex = bindex + 1
			
			if bindex > maxbindex then 
				wordlist.index = wordlist.index + 1
				
				rindex = rindex + 1
				if rindex > #rolelist then rindex = #rolelist end

				bindex = 0 
				ypos = _h*.9
				ypos2 = _h*1.1 
				alpha = 0 
			end
		end	
		
		xpos = _w * .7
		ypos = ypos - dt * yfactor
		ypos2 = ypos2 - dt*(yfactor*1.5)

		local tempfactor 
		
		if ypos < _h *.5 then 
			tempfactor = -afactor
		else
			tempfactor = afactor
		end

		alpha = alpha + dt * tempfactor
		if alpha > 1 then alpha = 1 end
		if alpha < 0 then alpha = 0 end
			
		role = rolelist[rindex]
	end
	
	if wordlist.index > #wordlist.word then wordlist.index = #wordlist.word end
	text = wordlist.word[wordlist.index]

end

function e.getalpha()
	return alpha
end

function e.draw2()
	 	love.graphics.setCanvas(jomsfix)
			love.graphics.clear()
			love.graphics.setColor(0,0,0,1)
			love.graphics.setFont(thatfont)
			local textWidth = thatfont:getWidth(role) * global.scale
			local textHeight = thatfont:getHeight(role) * global.scale
			love.graphics.print(role, xpos*.8, ypos2, -.2, global.scale*1.1, global.scale*1.1, (textWidth / 2) * 1.05, (textHeight / 2)  * 1.05)
			love.graphics.setColor(1,1,1,1)
			love.graphics.print(role, xpos*.8, ypos2, -.2, global.scale*1, global.scale*1, (textWidth / 2) , (textHeight / 2) )
		love.graphics.setCanvas()
		love.graphics.setColor(1,1,1,alpha)
		love.graphics.draw(jomsfix)
end

function e.draw()

	local textWidth = thisfont:getWidth(text)
	local textHeight = thisfont:getHeight(text) 
	love.graphics.setColor(colorfucker(timing*.5),1)
	love.graphics.setFont(thisfont)
	love.graphics.print(text, xpos, ypos, 0, newscale*math.random()*.3+1, newscale*math.random()*.5+1, (textWidth / 2), (textHeight / 2))
	love.graphics.setColor(colorfucker(timing*2),1)
	love.graphics.print(text, xpos, ypos, 0, newscale*math.random()*.3+1, newscale*math.random()*.5+1, (textWidth / 2), (textHeight / 2))


end

return e 