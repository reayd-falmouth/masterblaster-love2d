-- audio.lua

local audio = {
    -- Separate volume for music and SFX
    musicVolume = 1.0,
    sfxVolume   = 1.0,

    -- Tables to hold your music and SFX sources
    musicSources = {},
    sfxSources   = {}
}

function audio.load()
    -- MUSIC (streamed)
    audio.musicSources.music = love.audio.newSource("src/masterblaster/assets/sounds/music.ogg", "stream")

    -- SFX (static)
    audio.sfxSources.alarm   = love.audio.newSource("src/masterblaster/assets/sounds/alarm.ogg", "static")
    audio.sfxSources.bingo   = love.audio.newSource("src/masterblaster/assets/sounds/bingo.ogg", "static")
    audio.sfxSources.bingo22 = love.audio.newSource("src/masterblaster/assets/sounds/bingo22.ogg", "static")
    audio.sfxSources.bubble  = love.audio.newSource("src/masterblaster/assets/sounds/bubble.ogg", "static")
    audio.sfxSources.cash    = love.audio.newSource("src/masterblaster/assets/sounds/cash.ogg", "static")
    audio.sfxSources.die     = love.audio.newSource("src/masterblaster/assets/sounds/die.ogg", "static")
    audio.sfxSources.effect  = love.audio.newSource("src/masterblaster/assets/sounds/effect.ogg", "static")
    audio.sfxSources.explode = love.audio.newSource("src/masterblaster/assets/sounds/explode.ogg", "static")
    audio.sfxSources.go      = love.audio.newSource("src/masterblaster/assets/sounds/go.ogg", "static")
    audio.sfxSources.warp    = love.audio.newSource("src/masterblaster/assets/sounds/warp.ogg", "static")

    -- Set initial volumes and (optionally) looping for music
    for _, track in pairs(audio.musicSources) do
        track:setVolume(audio.musicVolume)
        track:setLooping(true)  -- typical for a background music track
    end

    for _, sfx in pairs(audio.sfxSources) do
        sfx:setVolume(audio.sfxVolume)
    end
end

------------------------------------------------------
-- PLAY / STOP: MUSIC
------------------------------------------------------
function audio.playMusic(name)
    local track = audio.musicSources[name]
    if track then
        track:setVolume(audio.musicVolume)
        track:play()
    else
        print("Warning: Attempt to play unknown MUSIC track:", name)
    end
end

function audio.stopMusic(name)
    local track = audio.musicSources[name]
    if track then
        track:stop()
    end
end

------------------------------------------------------
-- PLAY / STOP: SFX
------------------------------------------------------
function audio.playSFX(name)
    local sfx = audio.sfxSources[name]
    if sfx then
        sfx:setVolume(audio.sfxVolume)
        sfx:play()
    else
        print("Warning: Attempt to play unknown SFX:", name)
    end
end

function audio.stopSFX(name)
    local sfx = audio.sfxSources[name]
    if sfx then
        sfx:stop()
    end
end

------------------------------------------------------
-- VOLUME CONTROLS
------------------------------------------------------
function audio.setMusicVolume(vol)
    audio.musicVolume = vol
    for _, track in pairs(audio.musicSources) do
        track:setVolume(vol)
    end
end

function audio.setSFXVolume(vol)
    audio.sfxVolume = vol
    for _, sfx in pairs(audio.sfxSources) do
        sfx:setVolume(vol)
    end
end

return audio
