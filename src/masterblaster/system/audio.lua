-- audio.lua

local Audio = {
    -- Separate volume for music and SFX
    musicVolume = 1.0,
    sfxVolume   = 1.0,
    musicPitch  = 1.5,
    sfxPitch    = 1.5,

    -- Tables to hold your music and SFX sources
    musicSources = {},
    sfxSources   = {}
}

function Audio.load()
    -- MUSIC (streamed)
    Audio.musicSources.arena = love.audio.newSource("assets/sounds/music.ogg", "stream")

    -- SFX (static)
    Audio.sfxSources.alarm   = love.audio.newSource("assets/sounds/alarm.ogg", "static")
    Audio.sfxSources.bingo   = love.audio.newSource("assets/sounds/bingo.ogg", "static")
    Audio.sfxSources.bingo22 = love.audio.newSource("assets/sounds/bingo22.ogg", "static")
    Audio.sfxSources.bubble  = love.audio.newSource("assets/sounds/bubble.ogg", "static")
    Audio.sfxSources.cash    = love.audio.newSource("assets/sounds/cash.ogg", "static")
    Audio.sfxSources.die     = love.audio.newSource("assets/sounds/die.ogg", "static")
    Audio.sfxSources.effect  = love.audio.newSource("assets/sounds/effect.ogg", "static")
    Audio.sfxSources.explode = love.audio.newSource("assets/sounds/explode.ogg", "static")
    Audio.sfxSources.go      = love.audio.newSource("assets/sounds/go.ogg", "static")
    Audio.sfxSources.warp    = love.audio.newSource("assets/sounds/warp.ogg", "static")
    Audio.sfxSources.click   = love.audio.newSource("assets/sounds/burp.ogg", "static")

    -- Set initial volumes and (optionally) looping for music
    for _, track in pairs(Audio.musicSources) do
        track:setVolume(Audio.musicVolume)
        track:setLooping(true)  -- typical for a background music track
    end

    for _, sfx in pairs(Audio.sfxSources) do
        sfx:setVolume(Audio.sfxVolume)
    end
end

------------------------------------------------------
-- PLAY / STOP: MUSIC
------------------------------------------------------
function Audio.playMusic(name)
    local track = Audio.musicSources[name]
    if track then
        track:setVolume(Audio.musicVolume)
        track:play()
    else
        print("Warning: Attempt to play unknown MUSIC track:", name)
    end
end

function Audio.stopMusic(name)
    local track = Audio.musicSources[name]
    if track then
        track:stop()
    end
end

------------------------------------------------------
-- PLAY / STOP: SFX
------------------------------------------------------
function Audio.playSFX(name)
    local sfx = Audio.sfxSources[name]
    if sfx then
        sfx:setVolume(Audio.sfxVolume)
        sfx:play()
    else
        print("Warning: Attempt to play unknown SFX:", name)
    end
end

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
