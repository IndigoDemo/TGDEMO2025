--------- Indigo TG Demo 2025 : Mother Lovin' Indigo -----------------------------------------
-------|                                                               Party Version |--------
-------| Effects: -------------------------------------------------------------------|--------
-------| Beatindex | Index | Description                               | Status      |--------
----------------------------------------------------------------------------------------------
-------| n/a 	   | 1     | loader  								   | Finished    |--------
-------| 0		   | 2     | text + screenslime						   | Finished    |--------
-------| 28		   | 3     | Oldschool c64 cube and plasma			   | Finished    |--------
-------| 64		   | 4     | metaballs negative shader + menger wall   | Finished    |--------
-------| 160	   | 5     | menger sponge, dancing lady, creds		   | Finished    |--------
-------| 96		   | 6     | synthwave outrun greetings				   | Finished    |--------
-------| 273	   | 7     | static									   | Finished	 |--------
-------| 224   	   | 8     | Pure ketamine							   | Finished    |--------
-------| 192 	   | 9     | menger sponge the black album             | Finished    |--------
-------| 80        | 10    | Pretty fucking fractal                    | Finished    |--------
-------| 254       | 11    | Conway on an infinite plane               | Finished	 |--------
----------------------------------------------------------------------------------------------
-- for debugging: ----------------------------------------------------------------------------
deb = 	{	
			status 			= false, 	-- debug mode active 
			index 			= 8,	 	-- effectindex to start at
			offset 			= 0,	 	-- beat to start at
			keepsettings 	= true, 	-- stay on effect forever, or continue playing
			skiploader 		= false,  	-- skip the loader animation (independent of debug bool)
			panel 			= false		-- show debugpanel (independent of debug bool)
		} 
---------------------------------------------------------------------------------------------
local resolution = "FHD"  -- HD = 720p | FHD = 1080p | QHD = 1440p | POTATO = 540p --
local fullscreen = true

---------------------------------------------------------------------------------------------

-- list over beatindexes and the corresponding effect composer -------------------
-- bilist: 		beatindex trigger for scene transition --------------------------
-- eilist: 		which scene to trigger -----------------------------------------
-- blinklist: 	beatindex for flashing screen ---------------------------------
-- invertlist: 	beatindex for inverting the negative shader ------------------

local bilist = { 	28,  64,  80,  96, 160, 192, 224, 256, 264, 265, 266, 267, 268, 269, 
				   270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280}
local eilist = {  	 3,   4,  10,   6,   5,   9,   8,  11,   6,   9,   8,  10,  7,   6,   
					 8,   9,  10,   7,  11,  10,   9,   5,   8,   7,  11}
local blinklist = {	64,  68,  72,  76,  80,  88,  92,  93,  94,  95,  96,  128, 160, 192, 200, 
				   208, 212, 216, 220, 264, 265, 266, 267, 268, 269,  270, 271, 272, 
				   273, 274, 275, 276, 277, 278, 279, 280}
local invertlist = {50,  68,  72,  76, 164, 160, 192, 200, 208, 212, 216, 217, 218, 219}

local scenenames = {"Loader", "Screenslime", "Oldschool", "Metawalls", "Menger Creds", 
					"Synthwave Greets", "PSSSSSCHHHH", "KETAMINE", "Menger Creds Black", 
					"OmG sO pWeTTy!", "Conway Plane"}
--aliases
gfx = love.graphics
---------------------------------------------------------------------------------------------
gfx.setLineJoin("none") 
seed = os.time()
math.randomseed(os.time())
io.stdout:setvbuf('no')
love.mouse.setVisible(false)

local timing 	= require ("/code/audiotiming")
func 		 	= require ("/code/functions")
ilib			= require ("/code/indigolib")
loadingsong 	= love.audio.newSource("/media/loading.mp3", "stream")
res 			= {	fhd = 	{x = 1920, y = 1080, 	scale = 1}, 
					hd = 	{x = 1280, y = 720, 	scale = .7},
					qhd = 	{x = 2560, y = 1440, 	scale = 1.3}, 
					scale = 1
				}
global 			= {	time = 0, d = 0, videoplaying = false, scale = 1, b=0, delta = 0, x= 0, y = 0,z = 0,   
					oldbeat = 0, invertedflag = 0, resolution = resolution, color = 0}

demo = {effect 	= {index = 1, aindex = 1}, 
		shader 	= {canvas = {}, }, 
		tea = 0, coleur = 0, 
		beatfact = {current = 0, default = -20 }, 
		rscale 		= {0,0,0,0,0,0}, 
		rtrig 		= {2,2,2,2,2,2}, 
		rypos 		= {0,0,0,0,0,0}, 
		gendalpha 	= 1, 
		endalpha 	= 1, 
		lastalpha 	= 0, 
		currentangle= 0,
		incdt		= 0,
		spherefov 	= 180,
		plusminus = -1,
		angerintensity = 0,
		plox = 0    
}

-- Yes, i'm lazy and it's almost 1 in the morning.
-- bunch of variables for a variety of various ..vunctions

local mengIterations= 1
local volume 		= 1
local woffset 		= true
local onbeat 		= false
local phase 	
local plx 			= 0 
local plox 			= 0 
local cubeangle 	= {}
local blink 		= 0 
local sint 			= 0
local set11shader 	= false
local skip = {offs = false, 
		set = function(ldr)
		
			if ldr then 
				phase = 5.1
			end
		end, 
		}

---------------------------------------------------------------------------------------------

local function setResolution(argument) --guess what this does :p 
	local resindex = 0
	local restable = {	{name = "HD", 		x = 1280, 	y = 720, 	scale = 0.67},
						{name = "FHD", 		x = 1920, 	y = 1080, 	scale = 1 	},
						{name = "QHD", 		x = 2560, 	y = 1440, 	scale = 1.33}, 
						{name = "POTATO", 	x = 960, 	y = 540, 	scale = 0.5 }}
	
	for i = 1, #restable do 
		if restable[i].name == argument then
			resindex = i
		end 
	end
	love.window.setTitle("INDIGO")
	love.window.setMode(restable[resindex].x, restable[resindex].y)
	global.scale 	= restable[resindex].scale
	_w, _h 			= gfx.getDimensions()
	love.window.setFullscreen(fullscreen, "exclusive")
end

function isInt(int) -- int or nah? 
	if int == math.floor(int) then 
		return true
	else
		return false
	end
end

local function blink(dt, reset) --flashes the screen pure white
	if reset then 
		global.b = 1
	end 
	global.b = global.b - global.delta
	if global.b < 0 then global.b = 0 end 
	return global.b
end

local function checkforblink() -- checks the blinkindex for flashtriggers
	blink()
	local onbeat = math.floor(t.pbeat) 
	
	if t.pbeat == onbeat and onbeat > global.oldbeat then 
		global.oldbeat = onbeat
		
		for i = 1, #invertlist do 
			if onbeat == invertlist[i] then 
				if global.invertedflag == 0 then 
					global.invertedflag = 1
				else
					global.invertedflag = 0
				end
				demo.shader.negative:send("invertFlag", global.invertedflag)
			end
		end

		for i = 1, #blinklist do 
			if blinklist[i] == onbeat then 
				blink(0,true)
			end
		end
	end
end

local function getColorByValue(value) -- pretty color gradients for the fps counter
    value = math.max(1, math.min(100, value))
    local r, g, b = 0, 0, 0
    
    if value <= 30 then --red to orange
        local t = (value - 1) / 29  
        r = 1.0
        g = 0.5 * t
        b = 0
    elseif value <= 60 then -- orange to green
        local t = (value - 30) / 30  
        r = 1.0 - t
        g = 0.5 + (0.5 * t)
        b = 0
    else
        local t = (value - 60) / 40  -- green to blue
        r = 0
        g = 1.0 - (0.5 * t)
        b = t
    end
    
    return {r, g, b}
end

local function debugpanel(text) -- beatcounter in lower right corner. kinda neat.
	local thestring = ""
	local fps = love.timer.getFPS()
	local gpuStats = love.graphics.getStats()
	local cores = love.system.getProcessorCount()
	local drawCalls = gpuStats.drawcalls
	local canvases = gpuStats.canvasswitches
	local memory = collectgarbage("count") 
	local text = ("Beat: "..text)
	local text2 = ("FPS: "..fps)
	local text3 = ("Scene "..demo.effect.index..": "..scenenames[demo.effect.index])
   	local text4 = ("Drawcalls: "..drawCalls.." | Framebuffers: "..canvases.. " | Mem usage: "..math.floor(memory/1000).."MB") 
   	local textWidth 	= font.one:getWidth(text)
    local textHeight 	= font.one:getHeight(text)
	local textWidth2 	= font.one:getWidth(text2) 
    local textHeight2 	= font.one:getHeight(text2)
    local textWidth3 	= font.one:getWidth(text3) 
    local textWidth4	= font.one:getWidth(text4)
    -- make a semi transparent panel for debuginfo 
    gfx.setColor(.1,.3,.3,.4)
    gfx.rectangle ("fill",0,_h*.9, _w, _h*.20)
    gfx.rectangle ("fill",_w*.2,0, _w*.6, _h*.055)

	-- prints the current beatvalue to the screen. blinking green if on a beat    
    if isInt(t.pbeat) then 
   	    gfx.setColor(0,1,0,1)
	else
		gfx.setColor(1,1,1,1)
    end
    gfx.setFont(font.one)
    gfx.print(text,_w*.97, _h*.95, 0, 1, 1, textWidth, textHeight/2)

	-- prints FPS-info to the screen in pretty colors    
    local fpscolor = getColorByValue(fps)
   	gfx.setColor(fpscolor,1)
    gfx.print(text2,_w*.03, _h*.95, 0, 1, 1, 0, textHeight2/2)
    gfx.setColor(1,1,1)

    gfx.setColor(1,1,1)
    gfx.print(text3,_w*.5, _h*.95, 0, 1, 1, textWidth3/2, textHeight2/2)
    gfx.print(text4, _w*.5, _h*.03, 0, .5, .5, textWidth4/2, textHeight2/2)
end

local function parameterPusher(beat, dt) --keeps track of the render pipeline etc
	if demo.effect.loader then 
		phase = demo.effect.loader.phase()
		skip.set(deb.skiploader) -- function for skipping the loader-intro
	
		-- loaderstuff, will totally refactor later !
		if demo.effect.index == 1 then 
			if phase > 4 then 
				if volume > 0 then volume=volume-(dt/2)
					
					if volume < 0 then volume = 0 
						loadingsong:setVolume(volume)
					end
				end
			end
			if phase > 5 then 
				if global.d==0 then 
					love.audio.stop(loadingsong)
					loadingsong = nil
					timing:play(beatoffset)
					demo.effect.index = 2
					global.d=1 
				end
			end
		end
	end 

	-- set correct effect update- and renderorder
	if beat == oldbeat then 
	else
		for i = 1, #bilist do 
			if math.floor(beat) == bilist[i] then 
				demo.effect.index = eilist[i]
			end
		end

		if math.floor(beat) == 299 then 
			 love.event.quit()
		end
	end 

	local oldbeat = beat

	--for debugging ---------------------------------------------------
	if deb.status == true then 
		demo.effect.index 	= deb.index
		beatoffset   	= deb.offset
		if deb.keepsettings == false then deb.status = false end
	end
	-------------------------------------------------------------------
end

local debugInfo = {
	draw = function() --totally useless anonymous function, but had to test the method.
		debugpanel(t.tbeat) 
	end, 
}

local scenecomposer = require ("code/composer")

---------------------------------------------------------------------------------------------
----- MAIN LOOP FUNCTIONS -------------------------------------------------------------------
---------------------------------------------------------------------------------------------

function love.load(arg, arg2)
	local arguments = arg2
	for i = 1, #arguments do  
		-- res
		
		if arguments[i] == "--FHD" or arguments[i] =="--fhd" then 
			global.resolution = "FHD"
		elseif arguments[i] == "--HD" or arguments[i] =="--hd"then 
			global.resolution = "HD"
		elseif arguments[i] == "--QHD" or arguments[i] =="--qhd" then
			global.resolution = "QHD"
		elseif arguments[i] == "--POTATO" or arguments[i] =="--potato"then 
			global.resolution = "POTATO"
		end
		
		-- window mode
		if arguments[i] == "--FULLSCREEN" or arguments[i] =="--fullscreen" then 
			fullscreen = true
		elseif arguments[i] == "--WINDOW" or arguments[i] =="--window" then 
			fullscreen = false
		end
		
		-- debug info
		if arguments[i]== "--DEBUG" or arguments[i] =="--debug"then 
			deb.panel = true
		end
		-- skip the fake loader	
		if arguments[i]== "--SKIPLOADER" or arguments[i] =="--skiploader" then 
			deb.skiploader = true
		end

	end
	
	setResolution(global.resolution) 		-- sets resolution (hd, fhd and qhd supported. scaling is..partially implemented)
	timing.new("/media/ingido.mp3", 130, 4) 	-- loads the demochoon. 
	scenecomposer[1].load()					-- big fat loading routine
end

function love.update(dt)
	t = timing:getTimingInfo() 				-- checks if the demo still has a heart
	checkforblink()							-- strobe? yes? no? maybe? 
	parameterPusher(t.pbeat, dt) 			-- pushes current beat to the pP 
	global.time 	= global.time + dt  	-- it's hammer time!
	global.delta 	= dt 					-- it's hammer per frame time!
	scenecomposer[demo.effect.index].update(dt) 	-- updating the current scene
end

function love.draw()
	gfx.setColor(1,1,1) 							-- it DOES matter if you're black or white, atleast according to LÖVE
	gfx.clear() 									-- all your sins are forgiven
	scenecomposer[demo.effect.index].draw(global.delta) 	-- now paint me like one of your french bitches
	gfx.setColor(1,1,1,blink(dt)) 					--flash the screen
	
	gfx.rectangle("fill",0,0,_w,_h)
	
	if deb.panel == true then debugInfo.draw() end 	-- stats for nerds
end

function love.keypressed(key) 
    if key == "escape" then
        love.event.quit() -- cya!
    end
end