local settings = ac.storage({
    leftPanel = 'navigator',
    rightPanel = 'music',
    splitRatio = 0.65
}, 'dashboard')

local loadedWidgets = {}

local function loadWidget(app)
    if not app or not app.widget then
        return nil
    end

    if loadedWidgets[app.id] then
        return loadedWidgets[app.id]
    end

    local widget = app.widget

    if type(widget) == 'string' then
        local ok, result = pcall(require, widget)

        if not ok then
            ac.warn('Failed to load widget for ' .. app.id .. ': ' .. tostring(result))

            return nil
        end

        widget = result
    end

    loadedWidgets[app.id] = widget
    return widget
end


local function maskRoundedCorners(position, size, radius, color)
    radius = math.floor(math.min(radius, size.x / 2, size.y / 2))

    local step = 2

    for y = 0, radius - 1, step do
        local circleY = radius - y

        local cut = radius - math.sqrt(math.max(0, radius * radius - circleY * circleY))

        cut = math.ceil(cut)

        if cut > 0 then
            local rowHeight = math.min(step, radius - y)

            -- Top-left
            ui.drawRectFilled(vec2(position.x, position.y + y), vec2(position.x + cut, position.y + y + rowHeight),
                color)

            -- Top-right
            ui.drawRectFilled(vec2(position.x + size.x - cut, position.y + y),
                vec2(position.x + size.x, position.y + y + rowHeight), color)

            -- Bottom-left
            ui.drawRectFilled(vec2(position.x, position.y + size.y - y - rowHeight),
                vec2(position.x + cut, position.y + size.y - y), color)

            -- Bottom-right
            ui.drawRectFilled(vec2(position.x + size.x - cut, position.y + size.y - y - rowHeight),
                vec2(position.x + size.x, position.y + size.y - y), color)
        end
    end
end

local function drawWidgetPanel(app, panelID, position, size, dt, cornerRadius)
    ui.setCursor(position)

    ui.childWindow(
        panelID,
        size,
        false,
        bit.bor(
            ui.WindowFlags.NoScrollbar,
            ui.WindowFlags.NoScrollWithMouse
        ),
        function()
            ui.drawRectFilled(
                vec2(0, 0),
                ui.windowSize(),
                system.bgColor
            )

            local widget = loadWidget(app)

            if widget then
                widget(dt, ui.windowSize())
            else
                ui.setCursor(vec2(20, 20))

                ui.text(
                    app
                        and 'No widget available for ' .. app.name
                        or 'App unavailable'
                )
            end

            -- This must be inside the child window.
            if cornerRadius and cornerRadius > 0 then
                maskRoundedCorners(
                    vec2(0, 0),
                    ui.windowSize(),
                    cornerRadius,
                    rgbm.colors.black
                )
            end
        end
    )
end



return function(dt)

    local panelRadius = 18
    local maskColor = rgbm.colors.black


    local size = ui.windowSize()

    local dividerWidth = 6

    local leftWidth = math.floor((size.x - dividerWidth) * settings.splitRatio)

    local rightWidth = size.x - leftWidth - dividerWidth

    local leftSize = vec2(leftWidth, size.y)

    local rightPosition = vec2(leftWidth + dividerWidth, 0)

    local rightSize = vec2(rightWidth, size.y)

    local leftApp = system.getApp(settings.leftPanel)

    local rightApp = system.getApp(settings.rightPanel)

    -- Maps is a CSP scriptable display.
    -- It renders full-screen underneath the dashboard.
    if leftApp and leftApp.displays then
        -- Navigator is already rendered underneath by Dashboard's manifest.
        touchscreen.forceAwake()
        -- ui.text("Maps detected!")
    else
    drawWidgetPanel(
        leftApp,
        '__dashboard_left',
        vec2(0, 0),
        leftSize,
        dt,
        panelRadius
        )
    end


    -- Divider
    ui.drawRectFilled(vec2(leftWidth, 0), vec2(leftWidth + dividerWidth, size.y), rgbm.colors.black)

    -- The opaque right panel covers the right side
    -- of the full-screen map.
    drawWidgetPanel(rightApp, '__dashboard_right', rightPosition, rightSize, dt, panelRadius)

    -- Apply rounded visual clipping after both panels are rendered.
    maskRoundedCorners(
      vec2(0, 0),
      leftSize,
      panelRadius,
      maskColor
    )

end


