--- input.lua
--
-- This file contains the Love2D input event hooks. All hooks should do is call
-- methods on the @{TimerTable} instance, which starts the mod's input pipeline.

-- old event hooks used for fallback; stored globally so timers.lua can forward inputs
INPUT_FALLBACKS = {
    mousepressed = love.mousepressed,
    mousereleased = love.mousereleased,
    gamepadpressed = love.gamepadpressed,
    gamepadreleased = love.gamepadreleased,
    gamepadaxis = love.gamepadaxis,
    keypressed = love.keypressed,
    keyreleased = love.keyreleased,
};

--- Mouse press event hook.
-- Love2D mouse button press event override.
--
-- @param x cursor x position
-- @param y cursor y position
-- @param button cursor button pressed
-- @param istouch boolean true if from a touchscreen
function love.mousepressed(x, y, button, istouch)
    if
        button ~= 1
        and (STATE.bind_map:is_bound('mouse' .. button)
        or STATE.listening)
        and not G.CONTROLLER.locks.frame
        and not G.SETTINGS.PAUSED
    then
        STATE.timers:start('mouse'..button, { type = 'mouse', x = x, y = y, button = button, istouch = istouch });
    else
        INPUT_FALLBACKS.mousepressed(x, y, button, istouch);
    end
end

--- Mouse release event hook.
-- Love2D mouse button release event override.
--
-- @param x cursor x position
-- @param y cursor y position
-- @param button cursor button released
-- @param istouch boolean true if from a touchscreen
function love.mousereleased(x, y, button, istouch)
    if
        button ~= 1
        and (STATE.bind_map:is_bound('mouse' .. button)
        or STATE.listening)
        and not G.CONTROLLER.locks.frame
        and not G.SETTINGS.PAUSED
    then
        STATE.timers:stop('mouse'..button);
    else
        INPUT_FALLBACKS.mousereleased(x, y, button, istouch);
    end
end

--- Mouse wheel movement event hook.
-- Love2D mouse wheel movement event override.
--
-- @param x mouse wheel x position delta
-- @param y mouse wheel y position delta
function love.wheelmoved(x, y)
    -- L2D does not store mouse wheel movement as a KeyCode; spoofing with pseudovalues
    local button = 'wheel_error';

    -- check wheel movement direction
    -- TODO: find out what x direction wheel movement represents and handle if needed;
    if y > 0 then
        button = 'wheel_up';
    elseif y < 0 then
        button = 'wheel_down';
    end

    if
        (STATE.bind_map:is_bound(button)
        or STATE.listening)
        and not G.CONTROLLER.locks.frame
        and not G.SETTINGS.PAUSED
    then
        STATE.timers:start(button);
        STATE.timers:stop(button);
    end
end

--- Gamepad button press event hook.
-- Love2D gamepad button press event override.
--
-- @param joystick the @{love.Joystick} object
-- @param button the button being pressed
function love.gamepadpressed(joystick, button)
    if
        (STATE.bind_map:is_bound(button)
        or (STATE.listening and button ~= 'start'))
        and not G.CONTROLLER.locks.frame
        and not G.SETTINGS.PAUSED
    then
        STATE.timers:start(button, { type = 'gamepad', joystick = joystick });
    else
        if
            button == 'start' and
            STATE.listening
        then
            return;
        end
        INPUT_FALLBACKS.gamepadpressed(joystick, button);
    end
end

--- Gamepad button release event hook.
-- Love2D gamepad button release event override.
--
-- @param joystick the @{love.Joystick} object
-- @param button the button being released
function love.gamepadreleased(joystick, button)
    if
        (STATE.bind_map:is_bound(button)
        or (STATE.listening and button ~= 'start'))
        and not G.CONTROLLER.locks.frame
        and not G.SETTINGS.PAUSED
    then
        STATE.timers:stop(button);
    else
        if
            button == 'start' and
            STATE.listening
        then
            stop_listening()
            return;
        end
        INPUT_FALLBACKS.gamepadreleased(joystick, button);
    end
end

--- Keyboard button press event hook.
-- Love2D keyboard button press event override.
--
-- @param joystick the @{love.Joystick} object
-- @param button the button being pressed
function love.keypressed(key)
    if
        (STATE.bind_map:is_bound(key)
        or (STATE.listening and key ~= 'escape'))
        and not G.CONTROLLER.locks.frame
        and not G.SETTINGS.PAUSED
    then
        STATE.timers:start(key, { type = 'keyboard' });
    else
        if
            key == 'escape' and
            STATE.listening
        then
            return;
        end
        INPUT_FALLBACKS.keypressed(key);
    end
end

--- Gamepad button release event hook.
-- Love2D gamepad button release event override.
--
-- @param joystick the @{love.Joystick} object
-- @param button the button being released
function love.keyreleased(key)
    if
        (STATE.bind_map:is_bound(key)
        or (STATE.listening and key ~= 'escape'))
        and not G.CONTROLLER.locks.frame
        and not G.SETTINGS.PAUSED
    then
        STATE.timers:stop(key);
    else
        if
            key == 'escape' and
            STATE.listening
        then
            STATE.bind_map:remove_binding(STATE.listening);
            stop_listening()
            return;
        end
        INPUT_FALLBACKS.keyreleased(key);
    end
end

--- Trigger state tracking for menu page navigation
local trigger_states = {
    triggerleft = false,
    triggerright = false,
};

--- Threshold for trigger activation
local TRIGGER_THRESHOLD = 0.5;

--- Gamepad axis event hook.
-- Love2D gamepad axis event override.
-- Handles trigger inputs for page navigation in menus.
--
-- @param joystick the @{love.Joystick} object
-- @param axis the axis being moved
-- @param value the axis value (-1 to 1 for sticks, 0 to 1 for triggers)
function love.gamepadaxis(joystick, axis, value)
    if axis == 'triggerleft' or axis == 'triggerright' then
        local pressed = value > TRIGGER_THRESHOLD;
        local was_pressed = trigger_states[axis];
        trigger_states[axis] = pressed;

        if pressed and not was_pressed and G.OVERLAY_MENU then
            local direction = axis == 'triggerleft' and 'l' or 'r';
            navigate_page(direction);
        end
    end

    if INPUT_FALLBACKS.gamepadaxis then
        INPUT_FALLBACKS.gamepadaxis(joystick, axis, value);
    end
end