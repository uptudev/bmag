--- holdb.lua
--
-- Hold the gamepad B button for about 0.7 seconds to close every open menu at once.
-- A quick tap of B keeps its normal "Back" behaviour (one menu at a time).
--
-- The hold is timed from the gamepad itself (not from the game's button events), so it keeps working even when a
-- bound button is swallowed by this mod's input hooks or by another mod.

--- Seconds B must be held before every menu closes.
HOLD_B_SECONDS = 0.7;

local state = { t0 = nil, fired = false };

--- Raw LOVE name of the button the game treats as "B" (respects the swapped A/B option).
local function raw_b_button()
    local raw = 'b';
    if G and G.button_mapping then
        for k, v in pairs(G.button_mapping) do
            if v == 'b' then raw = k; end
        end
    end
    return raw;
end

--- Is B currently held down?
local function b_is_down(ctl)
    if ctl and ctl.held_buttons and ctl.held_buttons['b'] then return true; end
    if love and love.joystick and love.joystick.getJoysticks then
        local raw = raw_b_button();
        local ok, down = pcall(function()
            for _, j in ipairs(love.joystick.getJoysticks()) do
                if j.isGamepad and j:isGamepad() and j:isGamepadDown(raw) then return true; end
            end
            return false;
        end);
        if ok and down then return true; end
    end
    return false;
end

--- Closes the mods menu (saving mod settings) and any other open overlay menu.
local function close_all_menus()
    if G.ACTIVE_MOD_UI or (SMODS and SMODS.IN_MODS_TAB) then
        if G.FUNCS.exit_mods then pcall(G.FUNCS.exit_mods); end
    end
    if G.OVERLAY_MENU and G.FUNCS.exit_overlay_menu then
        pcall(G.FUNCS.exit_overlay_menu);
    end
end

--- Per-frame check; called from the controller update hook in timers.lua.
--
-- @param ctl the controller instance
function hold_b_tick(ctl)
    if b_is_down(ctl) then
        if
            G.OVERLAY_MENU
            and not (ctl and ctl.text_input_hook)
            and not (STATE and STATE.listening)
        then
            local now = love.timer.getTime();
            if not state.t0 then state.t0 = now; end
            if not state.fired and (now - state.t0) >= HOLD_B_SECONDS then
                state.fired = true;
                close_all_menus();
            end
        end
    else
        state.t0, state.fired = nil, false;
    end
end
