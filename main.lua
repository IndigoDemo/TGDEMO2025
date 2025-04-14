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
-------| 273	   | 7     | todo-screen							   | well, duh.  |--------
-------| 224   	   | 8     | Pure ketamine							   | Finished    |--------
-------| 192 	   | 9     | menger sponge the black album             | Finished    |--------
-------| 80        | 10    | Pretty fucking fractal                    | Finished    |--------
-------| 254       | 11    | Conway on an infinite plane               | Finished	 |--------
----------------------------------------------------------------------------------------------
-- for debugging: ----------------------------------------------------------------------------
deb = 	{	
			status 			= false, 	-- debug mode active 
			index 			= 11,	 	-- effectindex to start at
			offset 			= 254,	 	-- beat to start at
			keepsettings 	= false, 	-- stay on effect forever, or continue playing
			skiploader 		= false,  	-- skip the loader animation 
			panel 			= false  	-- show debugpanel
		} 
---------------------------------------------------------------------------------------------
local resolution = "FHD"  -- HD = 720p | FHD = 1080p | QHD = 1440p | POTATO = 540p --
local fullscreen = false
---------------------------------------------------------------------------------------------

-- list over beatindexes and the corresponding effect composer -------------------
-- bilist: 		beatindex trigger for scene transition --------------------------
-- eilist: 		which scene to trigger -----------------------------------------
-- blinklist: 	beatindex for flashing screen ---------------------------------
-- invertlist: 	beatindex for inverting the negative shader ------------------

local bilist = { 	28,  64,  80,  96, 160, 192, 224, 256, 264, 265, 266, 267, 268, 269, 
				   270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280}
local eilist = {  	 3,   4,  10,   6,   5,   9,   8,  11,   6,   9,   8,  10,  11,   6,   
					 8,   9,  10,   7,  11,  10,   9,   5,   8,   6,  11}
local blinklist = {	64,  68,  72,  76,  80,  88,  92,  93,  94,  95,  96,  128, 160, 192, 200, 
				   208, 212, 216, 220, 264, 265, 266, 267, 268, 269,  270, 271, 272, 
				   273, 274, 275, 276, 277, 278, 279, 280}
local invertlist = {50,  68,  72,  76, 164, 160, 192, 200, 208, 212, 216, 217, 218, 219}

local scenenames = {"Loader", "Screenslime", "Oldschool", "Metawalls", "Menger Creds", 
					"Synthwave Greets", "TODO:", "KETAMINE", "Menger Creds Black", 
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
local effect 	= {index = 1, aindex = 1}
local shader 	= {canvas = {}, }
-- Yes, i'm lazy and it's almost 1 in the morning.
-- bunch of variables for a variety of various ..vunctions

local beatfact 		= {current = 0, default = -20 }
local plusminus 	= -1
local rscale 		= {0,0,0,0,0,0}
local rtrig 		= {2,2,2,2,2,2}
local rypos 		= {0,0,0,0,0,0}
local mengIterations= 1
local coleur 		= 0
local volume 		= 1
local woffset 		= true
local onbeat 		= false
local phase 	
local plx 			= 0 
local plox 			= 0 
local spherefov 	= 180
local incdt			= 0 
local cubeangle 	= {}
local currentangle 	= 0
local blink 		= 0 
local sint 			= 0
local set11shader 	= false
local endalpha 		= 1
local gendalpha 	= 1 
local lastalpha 	= 0
local angerintensity = 0 
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

	love.window.setMode(restable[resindex].x, restable[resindex].y)
	global.scale 	= restable[resindex].scale
	_w, _h 			= gfx.getDimensions()
	love.window.setFullscreen(fullscreen, "exclusive")
end

local function isInt(int) -- int or nah? 
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
				shader.negative:send("invertFlag", global.invertedflag)
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
	
	local text = ("Beat: "..text)
	local text2 = ("FPS: "..fps)
	local text3 = ("Scene "..effect.index..": "..scenenames[effect.index])
   	
   	local textWidth 	= font.one:getWidth(text)
    local textHeight 	= font.one:getHeight(text)
	local textWidth2 	= font.one:getWidth(text2) 
    local textHeight2 	= font.one:getHeight(text2)
    local textWidth3 	= font.one:getWidth(text3) 
    
    -- make a semi transparent panel for debuginfo 
    gfx.setColor(.1,.3,.3,.4)
    gfx.rectangle ("fill",0,_h*.9, _w, _h*.20)

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
end

local function parameterPusher(beat, dt) --keeps track of the render pipeline etc
	phase = effect.loader.phase()
	skip.set(deb.skiploader) -- function for skipping the loader-intro
	
	-- loaderstuff, will totally refactor later !
	if effect.index == 1 then 
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
				effect.index = 2
				global.d=1 
			end
		end
	end
	
	-- set correct effect update- and renderorder
	if beat == oldbeat then 
	else
		for i = 1, #bilist do 
			if math.floor(beat) == bilist[i] then 
				effect.index = eilist[i]
			end
		end

		if math.floor(beat) == 299 then 
			 love.event.quit()
		end
	end 

	local oldbeat = beat

	--for debugging ---------------------------------------------------
	if deb.status == true then 
		effect.index 	= deb.index
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

local scenecomposer = { --this is the demo, guys. it's all here. that's the demo. 

----##------####----##----#####---######--#####--------------------
----##-----#---##-##--##--##--##--##------##--##-------------------
----##-----#---##-##--##--##---#--#####---#####--------------------
----##-----#---##-######--##--##--##------##--##-------------------
----######--####--##--##--####----######--##--##-------------------
	{	
		-- load function for the whole demo because i'm lazy and didn't want to 
		-- write a real loader. also, it loads fast as fuck anyway.
		-- yea, i said it. the loadingscreen is a phony. a big fat phony.

		load = function()
		effect.loader = require ("code/loader")
		font = {one = gfx.newFont(math.floor(60*global.scale))}
		tallfont = gfx.newFont("media/ferrum.otf", math.floor(500*global.scale))
		thisfont = gfx.newFont("media/MTF Toast.ttf", math.floor(350*global.scale) )
		-- set global max, min, current-value for shader params
		global.noisestrength = {max = 1, min = .1, current = .1}

		-- load shaders and configure if necessary 
		-- deadline is nearing, code suffers.
		shader.whirlpool = gfx.newShader[[ 
		    extern vec2 center = vec2(0.5, 0.5); 
		    extern number radius = 1.0;          
		    extern number strength = 10.0;       
		    extern number tightness = 3.0;       
		    
		    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
		    {
		        vec2 distance = texture_coords - center;
		        float dist = length(distance);
		        float angle = atan(distance.y, distance.x);
		        float swirl = strength * (1.0 - (dist / radius));
		        if (dist < radius) {
		            angle += swirl / tightness;
		            float newX = dist * cos(angle);
		            float newY = dist * sin(angle);
		            vec2 new_coords = center + vec2(newX, newY);
		            return Texel(tex, new_coords) * color;
		        } else {
		            return Texel(tex, texture_coords) * color;
		        }
		    }
		]]

		shader.angry = require ("code/nastortion")
		shader.angry:init()
		shader.angry:setIntensity(0)
		shader.c64 = require ("code/petscii")
		shader.bloom = require ("code/bloomshader")
		shader.vhs = require ("code/retroshader")
		shader.negative = require ("code/negative")
		shader.portal = require("code/mixmask")
		shader.menger2 = require("code/menger2")
		shader.menger3 = require("code/menger3")
		video = gfx.newVideo("media/dance.ogv")
		cuboid = shader.menger2.new()
		cuboid2 = shader.menger3.new()

		local resolution = {_w,_h}
		fluidX = {default = -_w, current = 0 } 
    	plx = -_h
    	shader.vhs:send("resolution", resolution)
    	
		charData = require ("/code/chardata")
		noise = require ("/code/noise") 
		Arwing = require ("/code/arwing") 

    	-- create framebuffers 
		canvas1 		= gfx.newCanvas() --we're doing a shitload of shader combinations
		canvas2 		= gfx.newCanvas() --so we'll probably need them all
		canvas3 		= gfx.newCanvas() -- hope yall's got some vram
		canvas4 		= gfx.newCanvas() -- cuz we're using all of it
		canvas5 		= gfx.newCanvas() -- like the bastards we are
		vcanvas 		= gfx.newCanvas(1920,1080)
		squarecanvas 	= gfx.newCanvas(_w,_w)

		-- configure bloom-shader values for the different effects
		-- i'm not very good at coming up with names. 		
		
		---bakgrunn
		bloomEffect = shader.bloom:new()
    	bloomEffect:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
    	bloomEffect:setBloomParams(0.3, 10, 200.0, 3)
		---tekst
		bloomEffect2 = shader.bloom:new()
    	bloomEffect2:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
    	bloomEffect2:setBloomParams(0.1, 6, 500.0, 3)
		---outrun 
		bloomEffect3 = shader.bloom:new()
   	 	bloomEffect3:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
    	bloomEffect3:setBloomParams(0.2, 10, 200.0, 3)
    	---spheretube
    	bloomEffect4 = shader.bloom:new()
        bloomEffect4:setColorRange(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
        bloomEffect4:setBloomParams(0.2, 10, 200.0, 3)
        
       	-- load effects
		effect.fluid 		= require ("code/fluid")
		effect.fluid.load()
		
		effect.tos 			= require("code/textonscreen")
		effect.tos.load()
		
		effect.c64 			= require ("code/c64")
		effect.c64.load()

		effect.meatballs 	= require("code/meatballs")
		effect.meatballs.load()

		effect.cube 		= require("code/twistcube")
		effect.cube:load()

		effect.outrun 		= require("code/outrun")
		effect.outrun.load()

		effect.spheretube 	= require("code/spheretube")
		effect.spheretube.load()
		
		effect.fractal = require("code/fractal")
		effect.fractal.load()

		effect.raycast 		= require("code/wallceiling")
		effect.raycast.load()

		effect.objv			= require("code/objviewer")
		effect.objv.load("media/indigo.obj")
		
		effect.plasma 		= require("code/plasma")
		effect.menger 		= require("code/mengereffect")
		
		-- play that funky music, audio-boi
		love.audio.play(loadingsong)
		gfx.clear()
		end,
		
		update = function(dt)
			effect.loader.update(dt)
		end,
		draw = function()
			effect.loader.draw()
		
		end


	}
	
--------------------######----------------------------------------
--------------------------#---------------------------------------
----------------------####--------: fluid splash and text --------
---------------------#--------------------------------------------
--------------------#########-------------------------------------

	,
	{ 
	
	draw = function()
		--draw the background to effectcanvas
		effect.fluid.draw() 
		-- switch canvas and render effectcanvas into canvas 1
		gfx.setCanvas(canvas1)
		gfx.draw(effect.fluid.fluidcanvas)
		-- switch to canvas 2 and make the retroshader active
		gfx.setCanvas(canvas2)
		gfx.setShader(shader.vhs)
		-- add bloom to canvas1 and render into canvas 2 with
		-- retroshader active
		bloomEffect:apply(canvas1)
		gfx.setCanvas()
		-- draw canvas 2 to screen and reset shader
		gfx.draw(canvas2, fluidX.current, 0)
		--gfx.draw(canvas2)
		gfx.setShader()
		-- set canvas 3, clear it, and render texteffect to it
		gfx.setCanvas(canvas3)
		gfx.clear()
		effect.tos.draw()
		-- set canvas to screen, apply bloom-effect to canvas 3
		-- and render it to screen
		gfx.setCanvas()
		--gfx.clear()
		bloomEffect2:apply(canvas3)
	end, 
	update = function(dt)
		local num 
		-- update effects with vars
		effect.tos.update(dt, t.pbeat)
		
		effect.fluid.update(dt, t.pbeat, 0)
		shader.vhs:send("time", love.timer.getTime())
		
		if t.pbeat > 26 then
			if fluidX.current > fluidX.default then 
				local deff = ((math.abs(fluidX.default) / func.diff(fluidX.current, fluidX.default))*dt*200)
				fluidX.current = fluidX.current - math.pow(deff,2) 
			
			end 
		end	
		-- check if we're directly on a beat, and modify the
		-- shaders parameters for a pulsing effect if we are
		local onbeat = false
		if math.floor(t.pbeat) == t.pbeat then
			onbeat = true
			global.noisestrength.current = global.noisestrength.max
		end 
		-- easing the parameters back to normal over time
		num = func.diff(global.noisestrength.min, global.noisestrength.current)
		global.noisestrength.current = global.noisestrength.current - num*(dt*10)
		--else
		--	num = .01	
		--end
		-- send parameters to shaders
		bloomEffect:setBloomParams(0.09, 10*num, 200.0, 3)
		shader.vhs:send("vhsNoiseStrength", global.noisestrength.current)
		shader.vhs:send("aberrationStrength", 1*num)
	end,
	},
----------------------#########-----------------------------------
------------------------------#-----------------------------------
--------------------------####-----: C64 Stuff and text ----------
------------------------------#-----------------------------------
----------------------########------------------------------------
 	{ 
	draw = function()
			--draw the background to effectcanvas
		if t.pbeat > 47 and t.pbeat < 65 then 
			effect.plasma.draw(0, 0)
		end 
		if t.pbeat > 31 then 
			effect.cube.draw()
		end
		-- switch canvas and render effectcanvas into canvas 1
		gfx.setCanvas(canvas1)
		gfx.setColor(1,1,1,1)
		gfx.clear()
		gfx.setColor(0,0.23,1)
		gfx.rectangle("fill",0,0,_w,_h)
		gfx.setColor(1,1,1)

		if t.pbeat > 47 and t.pbeat < 64 then 
			gfx.draw(effect.plasma.canvas, 0, plx)
		end
			
		if t.pbeat > 31 then 
			if woffset then 
				tea = global.time
				woffset = false
			end
			woffs = ilib.transition(_w*5, 0, global.time, tea + 10, "easeOut")
			gfx.draw(effect.cube.canvas, woffs, 0)
		end
		gfx.setCanvas()
		-- draw canvas 2 to screen and reset shader
		if t.pbeat > 30 then gfx.setShader(shader.c64) end 
		gfx.draw(canvas1)
		effect.cube.draw()
		effect.c64.draw()
		gfx.setShader()
		-- set canvas 3, clear it, and render texteffect to it
		gfx.setCanvas(canvas3)
		gfx.clear()
		effect.tos.draw()
		-- set canvas to screen, apply bloom-effect to canvas 3
		-- and render it to screen
		gfx.setCanvas()
		bloomEffect2:apply(canvas3)
	end, 
	
	update = function(dt)
		local num 
		if t.pbeat > 47 and t.pbeat < 62 then 
			boing = func.diff(plx, 0)
			plx = plx + ( boing * dt * 1.5)
			if plx > 0 then plx = 0 end 
		end
		-- update effects with vars
		effect.cube.update(dt)
		effect.plasma.update(dt)
		effect.tos.update(dt, t.pbeat)
		--effect.fluid.update(dt, t.pbeat)
		shader.vhs:send("time", love.timer.getTime())
		-- check if we're directly on a beat, and modify the
		-- shaders parameters for a pulsing effect if we are
		if t.pbeat>31 then 
			local onbeat = false
			if math.floor(t.pbeat) == t.pbeat then
				onbeat = true
				effect.plasma.speed = 5
				global.noisestrength.current = global.noisestrength.max
			end 
			-- easing the parameters back to normal over time
			
			if effect.plasma.speed > 1.5 then 
				effect.plasma.speed = effect.plasma.speed - dt*10
			end
			--print (effect.plasma.speed)
			num = func.diff(global.noisestrength.min, global.noisestrength.current)
			global.noisestrength.current = global.noisestrength.current - num*(dt*10)
		else
			num = .01	
		end
		-- send parameters to shaders
		bloomEffect:setBloomParams(0.09, 10*num, 200.0, 3)
		shader.vhs:send("vhsNoiseStrength", global.noisestrength.current)
		shader.vhs:send("aberrationStrength", 10*num)
		effect.c64.update(dt, t.pbeat)
	end,
	
	}, 

----------------------#----#--------------------------------------
----------------------#----#--------------------------------------
----------------------######------: Menger Wall and Invert--------
---------------------------#--------------------------------------
---------------------------#--------------------------------------

	{
	update = function(dt)
		coleur = coleur + .001 
		effect.tos.update(dt, t.pbeat)
		effect.menger.update(dt, coleur, 4)
		effect.meatballs.update(dt)	
		local onbeat = math.floor(t.pbeat) 
		if t.pbeat == onbeat and onbeat > global.oldbeat then 
			global.oldbeat = onbeat
		end
	end
	, 
	
	draw = function()
		gfx.setCanvas(canvas1)
		effect.menger:draw()
		gfx.setCanvas()
		effect.meatballs.draw()
		shader.negative:send("maskTexture", effect.meatballs.canvas)
		gfx.setCanvas(canvas5)
		gfx.setShader(shader.negative)
		gfx.draw(canvas1)
		gfx.setShader()
		gfx.setCanvas()
		gfx.draw(canvas5)
		gfx.setCanvas(canvas3)
		gfx.clear()
		effect.tos.draw()
		-- set canvas to screen, apply bloom-effect to canvas 3
		-- and render it to screen
		gfx.setCanvas()
		bloomEffect2:apply(canvas3)
	end 
	}, 

---------------------#######--------------------------------------
---------------------##-------------------------------------------
---------------------######---------: Menger Cube and dancer 1----
---------------------------#--------------160 - 192---------------
---------------------#######--------------------------------------

	{ 
	update = function (dt)
		if math.floor(t.pbeat) == 188 then
			mengIterations = 2
		end 
		if math.floor(t.pbeat) == 189 then
			mengIterations = 3
		end 
		if math.floor(t.pbeat) == 190 then
			mengIterations = 4
		end 
		if math.floor(t.pbeat) == 191 then
			mengIterations = 5
		end 

		cuboid:update(dt, global.time, t.pbeat)
		cuboid2:update(dt, global.time, t.pbeat, mengIterations)
		
		if global.videoplaying == false then 
			video:seek(29)
			video:play()
			effect.tos.setIndex(63)
			global.videoplaying = true
		end
		


		effect.tos.update(dt, t.pbeat, 1)
	end, 

	draw = function()
		gfx.setCanvas(vcanvas) 
		gfx.draw(video, _w*.3, _h/2, 0, 1, 1, _w/2, _h/2)
		shader.portal:send("maskTexture", vcanvas)
		gfx.setCanvas()
		gfx.setCanvas(canvas2)
		gfx.clear()
		cuboid:draw()
		shader.portal:send("alternateTexture", canvas2)
		gfx.setCanvas()
		gfx.setCanvas(canvas3)
		gfx.clear()
		cuboid2:draw()
		gfx.setCanvas()
		gfx.setShader(shader.portal)
		gfx.clear()
		gfx.draw(canvas3)
		gfx.setShader()
		gfx.setCanvas(canvas4)
		gfx.clear()
		effect.tos.draw()
		gfx.setCanvas(canvas5)
		gfx.clear()
		bloomEffect2:apply(canvas4)
		gfx.setCanvas()
		gfx.setColor(1,1,1,effect.tos.getalpha())
		gfx.draw(canvas5)
		gfx.setColor(1,1,1,1)
		if t.pbeat < 192 then 
			effect.tos.draw2()
		end
	end, 
	},

-------------------------######-----------------------------------
-------------------------##---------------------------------------
-------------------------#####------: Outrun Synthwave -----------
-------------------------##---#-----------------------------------
--------------------------#####-----------------------------------
{
	update = function(dt)
		if math.floor(t.pbeat) == t.pbeat then
			onbeat = true
		else 
			onbeat = false
		end

		effect.outrun.update(dt, onbeat, t.pbeat)
		shader.vhs:send("time", love.timer.getTime())
    	shader.vhs:send("vhsNoiseStrength", .1)
    	shader.vhs:send("aberrationStrength", .001)
	end, 

	draw = function()
		local sine = math.sin(global.time/10)
		gfx.setCanvas(background)
    	gfx.clear()
    	effect.outrun.drawBackground()
    	gfx.setCanvas(landscape)
    	gfx.clear()
   	 	bloomEffect3:apply(background)
    	effect.outrun.drawLandscape()
    	gfx.setCanvas(shiplayer)
    	gfx.clear()
    	effect.outrun.drawShips()
       	gfx.setCanvas(scroller)
    	gfx.clear()
    	effect.outrun.drawScroller()
       	gfx.setColor(1, 1, 1, 1)
    	gfx.setCanvas()
    	gfx.clear()
    	gfx.setShader(shader.vhs)
    	gfx.draw(landscape, screenWidth/2, screenHeight/2, sine*.19, 1.3, 1.3, screenWidth/2 , screenHeight/2)
    	gfx.draw(shiplayer, screenWidth/2, screenHeight/2, sine*.19, 1.3, 1.3, screenWidth/2, screenHeight/2)
    	gfx.setColor(1, 1, 1, 1)
    	gfx.setShader()
    	-- draw the scroller framebuffer
    	gfx.draw(scroller, 0, screenHeight*-.7, 0, 2, 4)		
	end
	}, 
	
-------------------------######-----------------------------------
-----------------------------##-----------------------------------
---------------------------##-----: TODO PLACEHOLDER -------------
--------------------------##--------------------------------------
--------------------------##--------------------------------------

	{ 

	update = function (dt)
		if not tsize then 
			tsize = 1
		else
			if tsize > 1 then tsize = tsize - dt end
		end 
		if t.pbeat == math.floor(t.pbeat) then 
			tsize = 2
		end
	end, 

	draw = function()
		local text = "//TODO:"
		local textHeight = font.one:getHeight(text) 
		local textWidth = font.one:getWidth(text) 
		gfx.setFont(font.one)
		gfx.setColor(.2,1,.2)
		gfx.print(text, _w, _h, 0, tsize, tsize, textWidth/2, textHeight/2)
		gfx.setColor(1,1,1)
	end, 
	}, 

-------------------------######-----------------------------------
------------------------#------#----------------------------------
-------------------------######------: tube glitch  --
------------------------#------#----------------------------------
-------------------------######-----------------------------------
	{
	update = function (dt)
		local boost = 1 
		if not shaderset then 
			
			shader.angry:combineShaders({"pixelSort", "rgbSplit"})
			shaderset = true
		end

		global.color = global.color + 1
		if global.color > 8 then global.color = 1 end
		global.z = math.sin(global.time)*45
		global.y = global.y - 2 
		global.x = global.x - 3
		if global.x < 1 then global.x = 90 end
		if global.y < 1 then global.y = 90 end
		if global.z > 90 then global.z = 1 end

		for i = 1, 45 do 
			effect.spheretube.blink(global.x,i, 1)
			effect.spheretube.blink(global.y,i, 6)
		end
		
		for i = 1, 90 do 
			effect.spheretube.blink(i, math.floor(global.z), 4)
		end
	
		shader.angry:update(dt)
		local incdt = incdt + (dt*50*boost)  

		spherefov = spherefov - incdt
		if spherefov < -180 then spherefov = 180 end
		--print (spherefov)
		sx, sy, sz = 0,global.time *.3,global.time
		
		if isInt(t.pbeat) then 
			boost = 6
			effect.spheretube.setSphereCam(math.sin(global.time)*200, math.cos(global.time)*200, 100)
			effect.spheretube.update(dt, spherefov, sx+boost, sy, sz)
			plusminus = -plusminus	
			plox = 0 
		else
			effect.spheretube.update(dt)
			plox = plox + dt*3
			if plox > 1 then plox = 1 end
		end
		shader.angry:setIntensity(plox)

		if t.pbeat > 240 then 
			effect.tos.setIndex(62)
			effect.tos.update(dt, t.pbeat, nil) 
		end
	end, 

	draw = function(arg)
		local effectlist = {"pixelSort", "rgbSplit", "waveDist", "glitch", "vhs", "pixelation", "scanLines", "crtWarp"}
		local indexer = math.floor(math.random()*#effectlist)+1
		local indexer2 = math.floor(math.random()*#effectlist)+1
		gfx.clear()
		if plusminus == 1 then
			shader.angry:combineShaders( {effectlist[indexer],effectlist[indexer2]})
			effect.spheretube.draw("sphere")
		else
			shader.angry:combineShaders({"waveDist", "glitch"})
			effect.spheretube.draw()
		end
		gfx.setCanvas(canvas1)
		gfx.clear()
		gfx.draw(effect.spheretube.spherecanvas)	
		if t.pbeat > 240 and t.pbeat < 255 then 
			effect.tos.draw()
		end
		gfx.setCanvas(canvas2)
		gfx.clear()
		bloomEffect4:apply(canvas1)
		gfx.setCanvas()
		gfx.setShader(shader.angry:getActiveShader())
		gfx.clear()
		gfx.draw(canvas2)
		gfx.setShader()
		
	end
	}, 

-------------------------#######----------------------------------
------------------------#------#----------------------------------
-------------------------#######----: Menger Cube and dancer 2 ---
-------------------------------#----------------------------------
------------------------########----------------------------------
	{ 
	update = function (dt)
		local colors = {h = 1, s = .1}
		local beatfactor = {default = -1, max = 10}		
		local iter = 3
		local oldbeat = 0 
		local dummyangle = 0 
		cubeangle = {0.785, 1.57, 2.356, 3.14, 3.93, 4.71, 5.5, 6.28}

		if t.pbeat > 220 then 
			beatfactor.default = .2
			beatfactor.max = .2
		end

		cuboid:update(dt, global.time, t.pbeat, colors, iter, true)
		cuboid2:update(dt, global.time, t.pbeat, 1)
		cuboid:setBeatFactor(beatfactor)
		
		if t.pbeat == math.floor(t.pbeat) and math.floor(t.pbeat) > oldbeat + 4 then 
			oldbeat = math.floor (t.pbeat)
			effect.aindex = effect.aindex + 1
			dummyangle  = 0 
			if effect.aindex > #cubeangle then effect.aindex = 1 end
		end

		if dummyangle < 1 then 
			dummyangle = dummyangle + func.diff(dummyangle, 5) * dt*2 
		end		

		if t.pbeat < 220 then 
			currentangle = currentangle + dummyangle/10
		end

		if currentangle > 6.28 then 
			currentangle = currentangle - 6.28
		end 

		if global.videoplaying == false then 
			video:seek(29)
			video:play()
			effect.tos.setIndex(63)
			global.videoplaying = true
			
		end
		effect.tos.update(dt, t.pbeat, 1)
	end, 

	draw = function(dt)
		gfx.reset()
		-- set up the mask (video stream) and send it to the shader
		gfx.setCanvas(vcanvas) 
		gfx.draw(video, _w*.4, _h/2, 0, 1.5, 1.5, _w/2, _h/2)
		shader.negative:send("maskTexture", vcanvas)
		-- draw the menger cube into a square canvas for easier rotation
		gfx.setCanvas(squarecanvas) 
		gfx.clear()
		cuboid:draw2()
		-- send the square canvas trough the twisty shader and draw it into canvas 3
		gfx.setCanvas(canvas2) 
		gfx.setShader(shader.whirlpool)
		gfx.clear()
		gfx.draw(squarecanvas, _w/2, _h/2, currentangle, 1.2, 1.2, _w/2, _w/2) --fraktal med maske nå i canvas 3
		gfx.setShader()
		-- draw canvas 3 (twisty menger) into canvas 4 with the negative shader enabled
		gfx.setCanvas(canvas4)
		gfx.setShader(shader.negative)
		gfx.draw(canvas2)
		gfx.setShader()
		-- draw the main textlayer into canvas 5
		gfx.setCanvas(canvas5)
		gfx.clear()
		effect.tos.draw()
		-- apply bloom to canvas 5 (main text layer) and put it into canvas 1
		gfx.setCanvas(canvas1)
		gfx.clear()
		bloomEffect2:apply(canvas5)
		gfx.setColor(1,1,1,1)
		gfx.setCanvas()	
		-- draw canvas 4 (twisty, negative-masked menger) to screen
		gfx.draw(canvas4)
		-- set alpha values and draw canvas1 (bloomy main text layer) to screen 
		gfx.setColor(1,1,1,effect.tos.getalpha())
		gfx.draw(canvas1)
		gfx.setColor(1,1,1,1)
		-- draw textlayer 2 to screen 
		if t.pbeat < 224 then 
			effect.tos.draw2()
		end
	end, 
	},
------------------##----#######-----------------------------------
----------------####---##-----##----------------------------------
------------------##---##-----##----: pretty fucking fractal
------------------##---##-----##----------------------------------
------------------##----#######-----------------------------------
	{
	update = function(dt)
		
		if global.videoplaying == true then 
			video:seek(0)
			video:play()
			effect.tos.setIndex(63)
			global.videoplaying = false
		end

		if isInt(t.pbeat) then 
			beatfact.current = 70
			if t.pbeat > 79 then 
				rtrig[1] = 1
			end
			if t.pbeat > 80 then 
				rtrig[2] = 1
			end
			if t.pbeat > 81 then 
				rtrig[3] = 1
				rtrig[1] = 0
			end
			if t.pbeat > 82 then 
				rtrig[4] = 1
				rtrig[2] = 0
			end
			if t.pbeat > 83 then 
				rtrig[5] = 1
				rtrig[3] = 0
			end
			if t.pbeat > 84 then 
				rtrig[4] = 0
			end
			if t.pbeat > 85 then 
				rtrig[5] = 0
				rtrig[6] = 1
			end
			if t.pbeat > 87 then 
				rtrig[6] = 0
			end
		end
		
		for i = 1, 6 do 
			if rtrig[i] == 1 and rscale[i] < 1 then 
				rscale[i] = rscale[i] + func.diff(rscale[i], 1) * dt * 6
			end
			if rtrig[i] == 0 and rypos[i] < 1 then 
				rypos[i] = rypos[i] + func.diff(rypos[i], 1) * dt * 6
			end
		end

			if beatfact.current > beatfact.default then 
				beatfact.current = beatfact.current - (func.diff(beatfact.current, beatfact.default) * dt * 4)
			end
		effect.fractal.update(dt, beatfact.current)
		
		if t.pbeat > 92 then 
			if isInt(t.pbeat) then 
				effect.objv.setvars(8, 2)
				effect.objv.update(dt)
			end
		end
		if t.pbeat < 92 then effect.objv.update(dt) end
		if t.pbeat > 92 and t.pbeat < 150 then gendalpha = gendalpha - dt * 8 end
	end, 

	draw = function()
		effect.fractal.draw()
		gfx.setCanvas(canvas1)
		gfx.clear()
		gfx.setColor(1,1,1,1)
		local textlist = {"I","N","D","I","G","O"}
		gfx.setFont(tallfont)
		for i = 1, 6 do 
			local textWidth = tallfont:getWidth(textlist[2])
			local textHeight = tallfont:getHeight(textlist[i])
			gfx.setColor (1,1,1,1)
			gfx.rectangle("fill", (i*(_w/6))-_w/6, _h*rypos[i], _w/6, _h*rscale[i])
			gfx.setColor (0,0,0,1)
	
			gfx.print(textlist[i], (i*(_w/6)-textWidth*1.5), _h/2-(textHeight*.65), 0, 1, 2, -textWidth/2 )
		end
		gfx.setColor(1,1,1,1)
		gfx.setCanvas()
		shader.negative:send("maskTexture", canvas1)
		gfx.setCanvas(canvas2)
		gfx.setShader(effect.fractal.shader)
		gfx.rectangle("fill",0,0,_w,_h)
		gfx.setShader()
		gfx.setCanvas(canvas4)
		gfx.setShader(shader.negative)
		gfx.draw(canvas2)
		gfx.setShader()
		gfx.setCanvas()
		
		gfx.setColor(1,1,1,gendalpha)
		gfx.draw(canvas4)
		
		if t.pbeat > 88 and t.pbeat < 150 then  
			effect.objv.draw()
		end		
	end
	}, 
------------------##---##----------------------------------------
----------------####-####-----------------------------------------
------------------##---##-----------: Conway on an infinite plane
------------------##---##-----------------------------------------
------------------##---##-----------------------------------------
	{ 
		load = function()
			effect.raycast.load()
		end, 

		update = function(dt)
			gendalpha = 1
			if set11shader == false then 
				shader.angry:combineShaders({"pixelSort", "glitch"})
				set11shader=true
			end 
			effect.objv.resetvars()
			effect.raycast.update(dt)
			effect.objv.update(dt)
			if t.pbeat > 288 then 
				endalpha = endalpha - dt *.5 
				shader.angry:update(dt)
				shader.angry:setIntensity(angerintensity)
			else
				endalpha = 1
			end
			
		end, 

		draw = function()
			effect.raycast.draw()
			gfx.setCanvas(canvas1)
			gfx.draw(effect.raycast.outputcanvas)
			gfx.setCanvas()
			
			gfx.setCanvas(canvas2)
			gfx.setColor(1,1,1,1)
				gfx.clear()
				effect.objv.draw()
			gfx.setCanvas()
			gfx.setCanvas(canvas3)
			gfx.setColor(1,1,1,1)
			gfx.clear()
			gfx.setShader(shader.angry:getActiveShader())
				gfx.draw(canvas2)
			gfx.setShader()
			gfx.setCanvas()
		
			gfx.setColor(1,1,1,endalpha)
			gfx.draw(canvas1)
			gfx.setColor(1,1,1,1)
			if t.pbeat > 292 then 
				gfx.draw(canvas3)
				
			else
				gfx.draw(canvas2)
			end
			if t.pbeat > 290 then 
				lastalpha = lastalpha + global.delta *.3
				angerintensity = angerintensity + global.delta *.3
				local text = "Vote With Your Heart: Vote Indigo"
				local textWidth = font.one:getWidth(text)
				love.graphics.setFont(font.one)
				gfx.setColor(1,1,1,lastalpha)
				gfx.print(text, _w*.5, _h*.8, 0, global.scale, global.scale, textWidth/2 )
				gfx.setColor(1,1,1,1)
			end
		end
	}
}

---------------------------------------------------------------------------------------------
----- MAIN LOOP FUNCTIONS -------------------------------------------------------------------
---------------------------------------------------------------------------------------------

function love.load()
	print("Program name", arg[0])
	print("Arguments:")
	for l = 1, #arg do
	print(l," ",arg[l])
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
	scenecomposer[effect.index].update(dt) 	-- updating the current scene
end

function love.draw()
	gfx.setColor(1,1,1) 							-- it DOES matter if you're black or white, atleast according to LÖVE
	gfx.clear() 									-- all your sins are forgiven
	scenecomposer[effect.index].draw(global.delta) 	-- now paint me like one of your french bitches
	gfx.setColor(1,1,1,blink(dt)) 					--flash the screen
	
	gfx.rectangle("fill",0,0,_w,_h)
	
	if deb.panel == true then debugInfo.draw() end 	-- stats for nerds
end

function love.keypressed(key) 
    if key == "escape" then
        love.event.quit() -- cya!
    end
end