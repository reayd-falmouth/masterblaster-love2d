-- masterblaster/system/audio.lua
local Audio = {
    -- Separate volume for music and SFX
    musicVolume = 1.0,
    sfxVolume   = 1.0,
    musicPitch  = 1.5,
    sfxPitch    = 1.5,

    -- Tables to hold music and SFX sources
    musicSources = {},
    sfxSources   = {}
}

------------------------------------------------------
-- LOAD AUDIO FILES
------------------------------------------------------

--- Loads all sound files into the system.
function Audio.load()
    local function loadSound(path, mode)
        if not love.filesystem.getInfo(path) then
            error("Sound file not found: " .. path)
        end
        return love.audio.newSource(path, mode)
    end

    -- Load music
    Audio.musicSources.arena = loadSound("assets/sounds/music.ogg", "stream")

    -- Load SFX
    local sfxFiles = {
        "alarm", "bingo", "bingo22", "bubble", "cash",
        "die", "effect", "explode", "go", "warp", "burp"
    }

    for _, name in ipairs(sfxFiles) do
        Audio.sfxSources[name] = loadSound("assets/sounds/" .. name .. ".ogg", "static")
    end

    -- Set initial volume and looping settings
    for _, track in pairs(Audio.musicSources) do
        track:setVolume(Audio.musicVolume)
        track:setLooping(true)
    end

    for _, sfx in pairs(Audio.sfxSources) do
        sfx:setVolume(Audio.sfxVolume)
    end
end

------------------------------------------------------
-- PLAY / STOP FUNCTIONS
------------------------------------------------------

--- Plays a music track.
-- @param name (string) The name of the track
function Audio.playMusic(name)
    local track = Audio.musicSources[name]
    if track then
        track:setVolume(Audio.musicVolume)
        track:play()
    else
        print("Warning: Attempt to play unknown music track:", name)
    end
end

--- Stops a music track.
-- @param name (string) The name of the track
function Audio.stopMusic(name)
    local track = Audio.musicSources[name]
    if track then
        track:stop()
    end
end

--- Plays a sound effect.
-- @param name (string) The name of the sound effect
function Audio.playSFX(name)
    local sfx = Audio.sfxSources[name]
    if sfx then
        sfx:setVolume(Audio.sfxVolume)
        sfx:play()
    else
        print("Warning: Attempt to play unknown SFX:", name)
    end
end

--- Stops a sound effect.
-- @param name (string) The name of the sound effect
function Audio.stopSFX(name)
    local sfx = Audio.sfxSources[name]
    if sfx then
        sfx:stop()
    end
end

------------------------------------------------------
-- VOLUME CONTROLS
------------------------------------------------------

function Audio.setMusicVolume(vol)
    Audio.musicVolume = vol
    for _, track in pairs(Audio.musicSources) do
        track:setVolume(vol)
    end
end

function Audio.setSFXVolume(vol)
    Audio.sfxVolume = vol
    for _, sfx in pairs(Audio.sfxSources) do
        sfx:setVolume(vol)
    end
end

function Audio.getMusicVolume()
    return Audio.musicVolume
end

function Audio.getSFXVolume()
    return Audio.sfxVolume
end

return Audio
