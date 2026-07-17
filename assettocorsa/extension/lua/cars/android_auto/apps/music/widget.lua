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

-- This extracts an accent color from the album cover.
local background = touchscreen.blurredBackgroundImage(
    rgbm(0.18, 0.18, 0.18, 1)
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

    ----------------------------------------------------------------
    -- Responsive scale
    ----------------------------------------------------------------

    local referenceWidth = 350
    local referenceHeight = 500

    local scale = math.min(
        size.x / referenceWidth,
        size.y / referenceHeight
    )

    scale = math.clamp(scale, 0.60, 1.20)

    local function px(value)
        return math.floor(value * scale + 0.5)
    end

    ----------------------------------------------------------------
    -- Full-panel album-cover background
    ----------------------------------------------------------------

    ui.setCursor(vec2(0, 0))

    if playing.hasCover then
        -- Reduce opacity so text and controls remain readable.
        ui.pushStyleVarAlpha(0.35)

        ui.image(
            playing,
            size,
            ui.ImageFit.Cover
        )

        ui.popStyleVar()
    else
        background.draw(dt)
    end

    ----------------------------------------------------------------
    -- Cover-derived color filter
    ----------------------------------------------------------------

    local accent = background.accent()

    local average =
        (accent.r + accent.g + accent.b) / 3

    -- Slightly desaturate the sampled cover color.
    local tintStrength = 0.58

    local tintR = math.lerp(average, accent.r, tintStrength)
    local tintG = math.lerp(average, accent.g, tintStrength)
    local tintB = math.lerp(average, accent.b, tintStrength)

    -- Cover-colored filter.
    ui.drawRectFilled(
        vec2(0, 0),
        size,
        rgbm(
            tintR,
            tintG,
            tintB,
            0.18
        )
    )

    -- Contrast layer: darkens shadows without strongly
    -- changing the cover’s overall color.
    ui.drawRectFilledMultiColor(
        vec2(0, 0),
        size,
        rgbm(0, 0, 0, 0.04),
        rgbm(0, 0, 0, 0.04),
        rgbm(0, 0, 0, 0.30),
        rgbm(0, 0, 0, 0.30)
    )

    ----------------------------------------------------------------
    -- Readability overlays
    ----------------------------------------------------------------

    -- Light overlay at the top, darker near the bottom.
    ui.drawRectFilledMultiColor(
        vec2(0, 0),
        size,
        rgbm(1, 1, 1, 0.05),
        rgbm(1, 1, 1, 0.05),
        rgbm(0, 0, 0, 0.55),
        rgbm(0, 0, 0, 0.55)
    )

    -- Additional subtle overall tint.
    ui.drawRectFilled(
        vec2(0, 0),
        size,
        rgbm(0, 0, 0, 0.08)
    )

    ----------------------------------------------------------------
    -- Top-left music icon
    ----------------------------------------------------------------

    local topPadding = px(14)
    local iconSize = px(24)

    ui.setCursor(vec2(
        topPadding,
        topPadding
    ))

    ui.drawCircleFilled(
        vec2(
            topPadding + iconSize / 2,
            topPadding + iconSize / 2
        ),
        iconSize / 2,
        rgbm(
            accent.r,
            accent.g,
            accent.b,
            0.95
        ),
        24
    )

    ui.setCursor(vec2(
        topPadding,
        topPadding
    ))

    ui.icon(
        ui.Icons.Music,
        vec2(iconSize, iconSize),
        rgbm.colors.white
    )

    ----------------------------------------------------------------
    -- Top-right menu dots
    ----------------------------------------------------------------

    -- local dotRadius = math.max(2, px(3))
    -- local dotSpacing = px(12)

    -- local dotY = topPadding + iconSize / 2
    -- local dotStartX = size.x - topPadding - dotSpacing * 2

    -- for i = 0, 2 do
    --     ui.drawCircleFilled(
    --         vec2(
    --             dotStartX + dotSpacing * i,
    --             dotY
    --         ),
    --         dotRadius,
    --         rgbm(1, 1, 1, 0.85),
    --         16
    --     )
    -- end

    ----------------------------------------------------------------
    -- Text layout
    ----------------------------------------------------------------

    local horizontalPadding = px(18)
    local textWidth = size.x - horizontalPadding * 2

    local buttonSize = px(48)
    local controlsBottomPadding = px(30)

    local controlsY =
        size.y
        - buttonSize
        - controlsBottomPadding
    ----------------------------------------------------------------
    -- Responsive text stack
    ----------------------------------------------------------------

    local title = playing.title ~= ''
        and playing.title
        or 'Nothing playing'

    -- Estimate whether the title needs two lines.
    local estimatedCharacterWidth = px(11)

    local estimatedTitleWidth =
        #title * estimatedCharacterWidth

    local wrapsTitle =
        estimatedTitleWidth > textWidth

    -- Dynamic title height.
    local titleHeight =
        wrapsTitle
            and px(62)
            or px(32)

    local titleArtistGap = px(6)

    local artistHeight =
        playing.artist ~= ''
            and px(24)
            or 0

    local artistProgressGap = px(12)

    local progressBarHeight =
        math.max(3, px(4))

    local progressTimeGap = px(8)
    local timeHeight = px(20)

    -- Total height of the title/artist/progress/time group.
    local textStackHeight =
        titleHeight
        + titleArtistGap
        + artistHeight
        + artistProgressGap
        + progressBarHeight
        + progressTimeGap
        + timeHeight

    -- Anchor the stack just above the playback controls.
    local stackBottomGap = px(10)

    local textStackBottom =
        controlsY - stackBottomGap

    local titleY =
        textStackBottom - textStackHeight

    ----------------------------------------------------------------
    -- Title
    ----------------------------------------------------------------

    ui.setCursor(vec2(
        horizontalPadding,
        titleY
    ))

    ui.dwriteTextAligned(
        title,
        px(23),
        ui.Alignment.Start,
        ui.Alignment.Start,
        vec2(
            textWidth,
            titleHeight
        ),
        true,
        rgbm.colors.white
    )

    ----------------------------------------------------------------
    -- Artist
    ----------------------------------------------------------------

    local artistY =
        titleY
        + titleHeight
        + titleArtistGap

    if playing.artist ~= '' then
        ui.setCursor(vec2(
            horizontalPadding,
            artistY
        ))
      
        ui.dwriteTextAligned(
            playing.artist,
            px(17),
            ui.Alignment.Start,
            ui.Alignment.Start,
            vec2(
                textWidth,
                artistHeight
            ),
            true,
            rgbm(1, 1, 1, 0.82)
        )
    end

    ----------------------------------------------------------------
    -- Progress bar
    ----------------------------------------------------------------

    local progressBarWidth =
        textWidth * 0.82

    local progressBarX =
        (size.x - progressBarWidth) / 2

    local progressBarY =
        artistY
        + artistHeight
        + artistProgressGap

    local progress = 0

    if playing.trackPosition ~= -1
        and playing.trackDuration ~= -1
        and playing.trackDuration > 0 then
        
        progress = math.saturateN(
            playing.trackPosition
                / playing.trackDuration
        )
    end

    -- Unfilled bar.
    ui.drawRectFilled(
        vec2(
            progressBarX,
            progressBarY
        ),
        vec2(
            progressBarX + progressBarWidth,
            progressBarY + progressBarHeight
        ),
        rgbm(1, 1, 1, 0.32),
        progressBarHeight / 2
    )

    -- Filled bar.
    ui.drawRectFilled(
        vec2(
            progressBarX,
            progressBarY
        ),
        vec2(
            progressBarX
                + progressBarWidth * progress,
            progressBarY
                + progressBarHeight
        ),
        rgbm.colors.white,
        progressBarHeight / 2
    )

    ----------------------------------------------------------------
    -- Time display
    ----------------------------------------------------------------

    if playing.trackPosition ~= -1
        and playing.trackDuration ~= -1 then
        
        local timeY =
            progressBarY
            + progressBarHeight
            + progressTimeGap
        
        ui.setCursor(vec2(
            progressBarX,
            timeY
        ))
      
        ui.dwriteTextAligned(
            formatTime(playing.trackPosition),
            px(12),
            ui.Alignment.Start,
            ui.Alignment.Start,
            vec2(
                progressBarWidth / 2,
                timeHeight
            ),
            false,
            rgbm(1, 1, 1, 0.72)
        )
      
        ui.setCursor(vec2(
            progressBarX
                + progressBarWidth / 2,
            timeY
        ))
      
        ui.dwriteTextAligned(
            formatTime(playing.trackDuration),
            px(12),
            ui.Alignment.End,
            ui.Alignment.Start,
            vec2(
                progressBarWidth / 2,
                timeHeight
            ),
            false,
            rgbm(1, 1, 1, 0.72)
        )
    end


    ----------------------------------------------------------------
    -- Playback controls
    ----------------------------------------------------------------

    local preferredSpacing = px(42)
    local controlsWidth =
        buttonSize * 3
        + preferredSpacing * 2

    -- Reduce spacing automatically on narrow panels.
    local maximumControlsWidth =
        size.x - horizontalPadding * 2

    local spacing = preferredSpacing

    if controlsWidth > maximumControlsWidth then
        spacing = math.max(
            px(8),
            (
                maximumControlsWidth
                - buttonSize * 3
            ) / 2
        )

        controlsWidth =
            buttonSize * 3
            + spacing * 2
    end

    local controlsX =
        (size.x - controlsWidth) / 2

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

    -- Rounded play/pause background.
    local playButtonPosition =
        ui.getCursor()

    ui.drawRectFilled(
        playButtonPosition,
        playButtonPosition
            + vec2(buttonSize, buttonSize),
        rgbm(1, 1, 1, 0.90),
        px(14)
    )

    if touchscreen.iconButton(
        playing.isPlaying
            and ui.Icons.Pause
            or ui.Icons.Play,
        buttonSize,
        rgbm(0.08, 0.08, 0.08, 1)
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