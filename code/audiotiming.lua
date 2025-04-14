-- Indigo Audiotimer

local MusicTimer = {}
local this = {}

function MusicTimer.new(audioPath, bpm, beatsPerBar, adjustment, verbose)
   
    this.verbose = verbose or false
    this.adjustTime = adjustment or 0 
    
    this.bpm = tonumber(bpm) or 120
    if this.bpm <= 0 then
        print("Warning: Invalid BPM value, defaulting to 120")
        this.bpm = 120
    end
    
    this.beatsPerBar = tonumber(beatsPerBar) or 4
    if this.beatsPerBar <= 0 then
        print("Warning: Invalid beats per bar value, defaulting to 4")
        this.beatsPerBar = 4
    end
    
    this.beatInterval = 60 / this.bpm
    this.barInterval = this.beatInterval * this.beatsPerBar
    this.currentBeat = 0
    this.currentBar = 0
    this.isPlaying = false
    this.startTime = 0

    print("Initialized music timer:")
    print("  BPM: " .. this.bpm)
    print("  Beats per bar: " .. this.beatsPerBar)
    print("  Beat interval: " .. this.beatInterval .. " seconds")
    print("  Bar interval: " .. this.barInterval .. " seconds")
    
    if audioPath then
        local info = love.filesystem.getInfo(audioPath)
        if info then
            print(" ")
            print("Loading audio file: " .. audioPath)
            this.audio = love.audio.newSource(audioPath, "stream")
        else
            print("Warning: Audio file not found: " .. audioPath)
        end
    else
        error("Audio path is required")
    end
end

function MusicTimer:play(beatoffset)
    if not this.isPlaying then

        if not this.beatInterval or this.beatInterval <= 0 then
            this.beatInterval = 60 / (this.bpm or 120)
            print("Fixed beatInterval: " .. this.beatInterval)
        end
        
        if not this.barInterval or this.barInterval <= 0 then
            this.barInterval = this.beatInterval * (this.beatsPerBar or 4)
            print("Fixed barInterval: " .. this.barInterval)
        end
        
        this.audio:play()
       
        if this.adjustTime then 
            this.startTime = love.timer.getTime() + this.adjustTime
        else
            this.startTime = love.timer.getTime() 
        end
        this.isPlaying = true
        this.currentBeat = beatoffset or 0 
        this.currentBar = 0
        print(" ")
        print ("Load time : "..this.startTime)
        print("Music timer started at " .. this.startTime)
    end
end

function MusicTimer:stop()
    if this.isPlaying then
        if this.audio then
            this.audio:stop()
        end
        this.isPlaying = false
        print("Music timer stopped")
    end
end

function MusicTimer:pause()
    if this.isPlaying then
        if this.audio then
            this.audio:pause()
        end
        this.pauseTime = love.timer.getTime()
        this.isPlaying = false
        print("Music timer paused at " .. this.pauseTime)
    end
end

function MusicTimer:resume()
    if not this.isPlaying and this.pauseTime then
        if this.audio then
            this.audio:play()
        end
        local pauseDuration = love.timer.getTime() - this.pauseTime
        this.startTime = this.startTime + pauseDuration
        this.isPlaying = true
        print("Music timer resumed, adjusted start time to " .. this.startTime)
    end
end

function MusicTimer:update()
    if not this.isPlaying then return end
    
    -- Ensure timing values are valid
    if not this.beatInterval or this.beatInterval <= 0 then
        this.beatInterval = 60 / (this.bpm or 120)
        print("Fixed beatInterval in update: " .. this.beatInterval)
    end
    
    if not this.beatsPerBar or this.beatsPerBar <= 0 then
        this.beatsPerBar = 4
        print("Fixed beatsPerBar in update: " .. this.beatsPerBar)
    end
    
    local currentTime = love.timer.getTime()
    local elapsedTime = currentTime - this.startTime
    
    local newBeat = math.floor(elapsedTime / this.beatInterval)
    
    if newBeat > this.currentBeat then
        for beat = this.currentBeat + 1, newBeat do
            local beatInBar = beat % this.beatsPerBar
            local bar = math.floor(beat / this.beatsPerBar)
            
            if this.verbose then 
                print(string.format("Beat: %d (Bar: %d, Beat in bar: %d)", 
                beat, bar + 1, beatInBar + 1))
            end 
            if beatInBar == 0 and bar > this.currentBar then
            if this.verbose then 
                print(string.format("Bar: %d", bar + 1))
            end 
        
                this.currentBar = bar
            end
        end
        
        this.currentBeat = newBeat
    end
end

function MusicTimer:getTimingInfo()
    if not beatoffset then beatoffset = 0 end

    if not this.isPlaying then
        return {
            beat = 0 + beatoffset,
            tbeat = 0 + beatoffset, 
            pbeat = 0 + beatoffset,
            bar = 0,
            beatInBar = 0,
            isPlaying = false,
            interval = this.beatInterval
        }
    end
    
    if not this.beatInterval or this.beatInterval <= 0 then
        this.beatInterval = 60 / (this.bpm or 120)
    end
    
    if not this.beatsPerBar or this.beatsPerBar <= 0 then
        this.beatsPerBar = 4
    end
    
    local currentTime = love.timer.getTime()
    local elapsedTime = currentTime - this.startTime
    
    local beat = math.floor((elapsedTime / this.beatInterval)*10) / 10
    if beat == math.floor(beat) then 
        tbeat = (beat+beatoffset..".0") 
    else 
        tbeat = beat+beatoffset end
    
    precisionbeat = beat 
    beat = math.floor(beat)
    local beatInBar = beat % this.beatsPerBar
    local bar = math.floor(beat / this.beatsPerBar)
    
    return {
        beat = beat + beatoffset,
        tbeat = tbeat,  
        pbeat = precisionbeat + beatoffset,
        bar = bar + 1,
        beatInBar = beatInBar + 1,
        elapsedTime = elapsedTime,
        isPlaying = this.isPlaying,
        adjusted = this.adjustTime,
        interval = this.beatInterval
    }
end

function MusicTimer:setBPM(newBPM)
    newBPM = tonumber(newBPM)
    if newBPM and newBPM > 0 then
        if this.isPlaying then
            local currentTime = love.timer.getTime()
            local elapsedBeats = (currentTime - this.startTime) / (60 / (this.bpm or 120))
            
            this.bpm = newBPM
            this.beatInterval = 60 / this.bpm
            this.barInterval = this.beatInterval * (this.beatsPerBar or 4)
            this.startTime = currentTime - (elapsedBeats * (60 / this.bpm))
            
            print("BPM changed to " .. this.bpm .. " while playing")
            print("New beat interval: " .. this.beatInterval)
            print("New bar interval: " .. this.barInterval)
        else
            this.bpm = newBPM
            this.beatInterval = 60 / this.bpm
            this.barInterval = this.beatInterval * (this.beatsPerBar or 4)
            
            print("BPM changed to " .. this.bpm)
            print("New beat interval: " .. this.beatInterval)
            print("New bar interval: " .. this.barInterval)
        end
    else
        print("Warning: Invalid BPM value")
    end
end

return MusicTimer