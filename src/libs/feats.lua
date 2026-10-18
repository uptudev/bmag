--- Recursively searches a UIE tree for cycle arrow elements.
-- Looks for elements whose config.ref_value matches the specified direction.
--
-- @param node the UIE node to search from
-- @param direction 'l' for left or 'r' for right
-- @param results accumulator table for found elements
-- @return table of matching UIE elements
local function find_cycle_arrows(node, direction, results)
    if not node then return results; end
    results = results or {};

    if node.config and node.config.ref_value == direction then
        table.insert(results, node);
    end

    if node.children then
        for _, child in ipairs(node.children) do
            find_cycle_arrows(child, direction, results);
        end
    end

    return results;
end

--- Navigates to the next or previous page in the current menu overlay.
-- Searches the overlay menu for page navigation cycle arrows and clicks the
-- last one found (page navigation is typically at the bottom of the menu).
--
-- @param direction 'l' for left/previous or 'r' for right/next
function navigate_page(direction)
    if not G.OVERLAY_MENU or not G.OVERLAY_MENU.UIRoot then return; end

    local arrows = find_cycle_arrows(G.OVERLAY_MENU.UIRoot, direction);

    if #arrows == 0 then return; end

    local arrow = arrows[#arrows];
    if arrow.click then
        arrow:click();
    end
end

--- Update function for multiselect
-- Only runs when `STATE.multiselecting` is not nil.
function multiselect_hold()
    if
        G.CONTROLLER.hovering.target ~= nil and
        G.CONTROLLER.hovering.target:is(Card) and
        G.CONTROLLER.hovering.target.area == G.hand
    then
        if
            STATE.multiselecting == true and
            Vector_Dist(STATE.multiselect_down_pos, G.CONTROLLER.cursor_position) > 0.1 * G.MIN_CLICK_DIST
        then
            STATE.multiselecting = false;
            G.CONTROLLER.hovering.target:click();
            STATE.prev_target = G.CONTROLLER.hovering.target;
        elseif
            STATE.multiselecting == false and
            STATE.prev_target ~= G.CONTROLLER.hovering.target
        then
            if
                STATE.prev_prev_target ~= nil and
                STATE.prev_prev_target == G.CONTROLLER.hovering.target
            then
                STATE.prev_target:click();
            end
            G.CONTROLLER.hovering.target:click();
            STATE.prev_prev_target = STATE.prev_target;
            STATE.prev_target = G.CONTROLLER.hovering.target;
        end
    end
end

--- Deselects all cards currently selected
-- Deselects all cards in the current hand
function deselect_all()
    if
        G.CONTROLLER.locked or
        G.SETTINGS.paused or
        (G.play and #G.play.cards > 0) or
        (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) or
        not (G.hand and G.hand.highlighted[1])
    then
        return;
    end
    G.hand:unhighlight_all();
end

--- Sorts hand by suit
-- Sorts all cards in the hand by suit
function sort_by_suit()
    if
        G.CONTROLLER.locked or
        G.SETTINGS.paused or                    -- ...if the game is paused, or...
        G.STATE ~= G.STATES.SELECTING_HAND      -- ...if not currently selecting a hand, return early.
    then
        return;
    end
    G.FUNCS.sort_hand_suit();
end

--- Sorts hand by value
-- Sorts all cards in the hand by value
function sort_by_value()
    if
        G.CONTROLLER.locked or
        G.SETTINGS.paused or                    -- ...if the game is paused, or...
        G.STATE ~= G.STATES.SELECTING_HAND      -- ...if not currently selecting a hand, return early.
    then
        return;
    end
    G.FUNCS.sort_hand_value();
end

--- Plays a selected hand
-- Plays the highlighted cards
function play_hand()
    local remaining = G.GAME.current_round.hands_left;
    if
        G.CONTROLLER.locks.frame or
        (
            G.CONTROLLER.target and                 -- ...if currently dragging a card...
            G.CONTROLLER.target.states.drag.is
        ) or
        G.SETTINGS.paused or                        -- ...if the game is paused, or...
        G.STATE ~= G.STATES.SELECTING_HAND or       -- ...if not currently selecting a hand, return early.
        G.hand.highlighted[1] == nil or
        remaining == nil or
        remaining == 0
    then
        return;
    end
    G.FUNCS.play_cards_from_highlighted();      -- else play the selected hand
end

--- Discards a selected hand
-- Discards the highlighted cards
function discard_hand()
    local remaining = G.GAME.current_round.discards_left;
    if
        G.CONTROLLER.locks.frame or
        (
            G.CONTROLLER.target and                 -- ...if currently dragging a card...
            G.CONTROLLER.target.states.drag.is
        ) or
        G.SETTINGS.paused or                        -- ...if the game is paused, or...
        G.STATE ~= G.STATES.SELECTING_HAND or       -- ...if not currently selecting a hand, return early.
        G.hand.highlighted[1] == nil or
        remaining == nil or
        remaining == 0
    then
        return;
    end
    G.FUNCS.discard_cards_from_highlighted();   -- else discard the selected hand
end

--- Restarts the current game, recalculating seed if applicable
-- Ported pretty much verbatim from the base game's `Controller:key_hold_update` method
function restart_game()
    if
        G.CONTROLLER.locked or
        G.CONTROLLER.frame_buttonpress
    then
        return;
    end
    if
        not G.GAME.won and
        not G.GAME.seeded and
        not G.GAME.challenge
    then
        G.PROFILES[G.SETTINGS.profile].high_scores.current_streak.amt = 0;
    end
    G:save_settings();
    G.SETTINGS.current_setup = 'New Run';
    G.GAME.viewed_back = nil;
    G.run_setup_seed = G.GAME.seeded;
    G.challenge_tab = G.GAME and G.GAME.challenge and G.GAME.challenge_tab or nil;
    G.forced_seed, G.setup_seed = nil, nil;
    if G.GAME.seeded then
        G.forced_seed = G.GAME.pseudorandom.seed;
    end
    G.forced_stake = G.GAME.stake
    if G.STAGE == G.STAGES.RUN then
        G.FUNCS.start_setup_run();
    end
    G.forced_stake = nil;
    G.challenge_tab = nil;
    G.forced_seed = nil;
end
