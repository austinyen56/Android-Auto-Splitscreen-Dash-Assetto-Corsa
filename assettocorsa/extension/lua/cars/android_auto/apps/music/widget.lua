local function formatTime(value)
    if value == -1 then
        return '--:--'
    end

    return string.format(
        '%02d:%02d',
        math.floor(value / 60),
        math.floor(value % 60)
    )
end

-- Uses the same blurred, cover-derived background system
-- as the original full-screen Music app.
local background = touchscreen.blurredBackgroundImage(
    rgbm(33 / 255, 212 / 255, 94 / 255, 1)
)

local function updateCover()
    local playing = ac.currentlyPlaying()

    background.update(
        playing.hasCover and playing or nil
    )
end

updateCover()
ac.onAlbumCoverUpdate(updateCover)

return function(dt, size)
    local playing = ac.currentlyPlaying()

    -- Draw blurred background derived from album art.
    background.draw(dt)

    -- Dark overlay for text readability.
    ui.drawRectFilled(
        vec2(0, 0),
        size,
        rgbm(0, 0, 0, 0.45)
    )

    local padding = 16
    local contentOffsetY = 50

    -- Album cover dimensions.
    local coverSize = math.min(
        size.x - padding * 2,
        size.y * 0.42
    )

    coverSize = math.max(coverSize, 80)

    -- Center album cover horizontally.
    local coverX = (size.x - coverSize) / 2
    local coverY = padding + contentOffsetY

    ui.setCursor(vec2(coverX, coverY))

    if playing.hasCover then
        ui.image(
            playing,
            vec2(coverSize, coverSize),
            ui.ImageFit.Fit
        )
    else
        ui.drawRectFilled(
            vec2(coverX, coverY),
            vec2(
                coverX + coverSize,
                coverY + coverSize
            ),
            rgbm(0.1, 0.1, 0.1, 0.8),
            12
        )

        ui.setCursor(vec2(coverX, coverY))

        ui.textAligned(
            'No cover',
            0.5,
            vec2(coverSize, coverSize)
        )
    end

    -- Text area below cover.
    local textY = coverY + coverSize + 28
    local textWidth = size.x - padding * 2

    local title = playing.title ~= ''
        and playing.title
        or 'Nothing playing'

    ui.setCursor(vec2(padding, textY))

    ui.dwriteTextAligned(
        title,
        22,
        ui.Alignment.Center,
        ui.Alignment.Start,
        vec2(textWidth, 54),
        true,
        rgbm.colors.white
    )

    textY = textY + 60

    if playing.artist ~= '' then
        ui.setCursor(vec2(padding, textY))

        ui.dwriteTextAligned(
            playing.artist,
            16,
            ui.Alignment.Center,
            ui.Alignment.Start,
            vec2(textWidth, 28),
            true,
            rgbm(1, 1, 1, 0.72)
        )

        textY = textY + 26
    end

    -- Progress bar
    local progressBarWidth = textWidth * 0.82
    local progressBarHeight = 4
    local progressBarX = (size.x - progressBarWidth) / 2
    local progressBarY = textY + 8

    local progress = 0

    if playing.trackPosition ~= -1
        and playing.trackDuration ~= -1
        and playing.trackDuration > 0 then
        progress = math.saturateN(
            playing.trackPosition / playing.trackDuration
        )
    end

    -- Background track
    ui.drawRectFilled(
        vec2(progressBarX, progressBarY),
        vec2(
            progressBarX + progressBarWidth,
            progressBarY + progressBarHeight
        ),
        rgbm(1, 1, 1, 0.18),
        progressBarHeight / 2
    )

    -- Filled progress
    ui.drawRectFilled(
        vec2(progressBarX, progressBarY),
        vec2(
            progressBarX + progressBarWidth * progress,
            progressBarY + progressBarHeight
        ),
        rgbm.colors.white,
        progressBarHeight / 2
    )

    textY = progressBarY + 12

    if playing.trackPosition ~= -1
        and playing.trackDuration ~= -1 then

        ui.setCursor(vec2(padding, textY))

        ui.dwriteTextAligned(
            string.format(
                '%s / %s',
                formatTime(playing.trackPosition),
                formatTime(playing.trackDuration)
            ),
            14,
            ui.Alignment.Center,
            ui.Alignment.Start,
            vec2(textWidth, 24),
            false,
            rgbm(1, 1, 1, 0.65)
        )
    end

    -- Playback controls.
    local buttonSize = 48
    local spacing = 50
    local controlsWidth =
        buttonSize * 3 + spacing * 2

    local controlsX =
        (size.x - controlsWidth) / 2

    local controlsY =
        size.y - buttonSize - 18

    ui.setCursor(vec2(
        controlsX,
        controlsY
    ))

    if touchscreen.iconButton(
        ui.Icons.Back,
        buttonSize
    ) then
        ac.mediaPreviousTrack()
    end

    ui.sameLine(0, spacing)

    if touchscreen.iconButton(
        playing.isPlaying
            and ui.Icons.Pause
            or ui.Icons.Play,
        buttonSize
    ) then
        ac.mediaPlayPause()
    end

    ui.sameLine(0, spacing)

    if touchscreen.iconButton(
        ui.Icons.Next,
        buttonSize
    ) then
        ac.mediaNextTrack()
    end
end