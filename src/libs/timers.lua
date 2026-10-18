--- timers.lua
--
--  This file contains the @{TimerTable} object.

--- A table of monotonic integer clocks.
-- Checked every frame to determine whether to send a click or hold event.
TimerTable = {};

--- Creates a new TimerTable.
-- Creates a new empty TimerTable.
--
-- Example:
-- local timers = TimerTable:new()
--
-- @return the new TimerTable instance
function TimerTable:new()
    local t = {};
    setmetatable(t, self);
    self.__index = self;
    return t;
end

--- Starts a timer for the specified button.
-- Sets the timer to `0` for the given button.
--
-- @param button the keycode to begin a timer for
-- @param meta optional table with input source info for fallback forwarding
-- @return the @{TimerTable} instance for chain-calling
function TimerTable:start(button, meta)
    if
        STATE.bind_map.binding_to_button['multiselect'] and
        STATE.bind_map.binding_to_button['multiselect'].button == button
    then
        STATE.multiselecting = true;
        STATE.multiselect_down_pos = {
            x = G.CONTROLLER.cursor_position.x,
            y = G.CONTROLLER.cursor_position.y,
        };
    end
    self[button] = 0;
    if not self._meta then self._meta = {}; end
    self._meta[button] = meta;
    return self;
end

--- Stops a timer for the specified button.
-- Sets the timer to `nil` for the given button.
--
-- @param button the keycode to stop the timer for
-- @return the @{TimerTable} instance for chain-calling
function TimerTable:stop(button)
    if
        STATE.bind_map.binding_to_button['multiselect'] and
        STATE.bind_map.binding_to_button['multiselect'].button == button
    then
        STATE.multiselecting = nil;
        STATE.multiselect_down_pos = nil;
    end
    -- binds to config if listening here
    if STATE.listening then
        if self[button] ~= nil then
            STATE.bind_map:bind_click(button, STATE.listening);
            self[button] = nil;
            if self._meta then self._meta[button] = nil; end
        end
        stop_listening();
        return self;
    end

    if self[button] ~= nil then
        -- Short press: if the button only has a hold binding, forward to the game
        -- so the button retains its normal function on quick taps.
        if STATE.bind_map:is_bound(button) == 'hold' then
            local meta = self._meta and self._meta[button];
            self[button] = nil;
            if self._meta then self._meta[button] = nil; end
            if meta and INPUT_FALLBACKS then
                if meta.type == 'gamepad' then
                    INPUT_FALLBACKS.gamepadpressed(meta.joystick, button);
                    INPUT_FALLBACKS.gamepadreleased(meta.joystick, button);
                elseif meta.type == 'keyboard' then
                    INPUT_FALLBACKS.keypressed(button);
                    INPUT_FALLBACKS.keyreleased(button);
                elseif meta.type == 'mouse' then
                    INPUT_FALLBACKS.mousepressed(meta.x, meta.y, meta.button, meta.istouch);
                    INPUT_FALLBACKS.mousereleased(meta.x, meta.y, meta.button, meta.istouch);
                end
            end
            return self;
        end
        STATE.bind_map:on_click(button);
    end
    self[button] = nil;
    return self;
end

--- Gets the elapsed time for the specified button.
-- Gets the amount of updates since the button was pressed last.
--
-- @param button the keycode to return the elapsed time for
-- @return the amount of time elapsed
function TimerTable:get(button)
    return self[button];
end

--- Increments all active timers.
-- Runs on every controller update cycle; iterates over all entries in the TimerTable instance
-- and adds `1` to the value of all of the timers.
--
-- @param dt delta time since last frame processed
-- @return the @{TimerTable} instance for chain-calling
function TimerTable:increment(dt)
    for button, time in pairs(self) do
        if type(time) == 'number' then
            self[button] = time + dt;
            self:check_overflow(button);
        end
    end
    return self;
end

--- Checks all active timers for overflow.
-- If a timer has overflowed, it is a hold event that must be started.
--
-- @param button the keycode to check
-- @return the @{TimerTable} instance for chain-calling
function TimerTable:check_overflow(button)
    if self[button] >= 0.2 then
        self[button] = nil;
        if self._meta then self._meta[button] = nil; end
        if STATE.listening then
            STATE.bind_map:bind_hold(button, STATE.listening);
            stop_listening();
            return self;
        end
        STATE.bind_map:hold_start(button);
    end
    return self;
end

--- Old Controller update loop
local old_update = G.CONTROLLER.update;

--- Controller update loop hook
-- Runs all game code first, then does all per-frame mod functions
--
-- @param dt delta time since last frame
function G.CONTROLLER:update(dt)
    old_update(self, dt);
    STATE.timers:increment(dt);
    if hold_b_tick then hold_b_tick(self); end
    if STATE.multiselecting ~= nil then
        multiselect_hold();
    end
end
