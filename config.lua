--[[
-------------------------------------
------------USER SETTINGS------------
-------------------------------------

--------FUNCTIONS DESCRIPTION--------
01. click right mouse button     -> unselect all cards (same as origin)
02. hold right mouse button      -> multiply select cards (core function!)
03. click middle mouse button    -> esc
04. hold middle mouse button     -> quickly restart (same as key 'r')
05. middle mouse up              -> play cards
06. middle mouse down            -> discard cards
07. click X1 mouse button        -> sort hand by suit
08. click X2 mouse button        -> sort hand by value
09. hold gamepad b button        -> same as hold right mouse button
10. click gamepad left shoulder  -> same as click X1 mouse button
11. click gamepad right shoulder -> same as click X2 mouse button
12. hold gamepad right stick     -> same as hold middle mouse button
------FUNCTIONS DESCRIPTION END------

--set parameter to false below to turn function off
--note that if you turn certain function off, you ban the function, not the button,
--so if then you swap it's mapping, this button will still work to execute the other function

--]]
return {
    right_mouse_button_click = true,
    right_mouse_button_hold = true,
    middle_mouse_button_click = true,
    middle_mouse_button_hold = false,
    middle_mouse_button_up = true,
    middle_mouse_button_down = true,
    x1_click = true,
    x2_click = true,
    
    swap_mouse_wheel_up_with_down = false,
    swap_x1_with_x2 = false,
    swap_mouse_wheel_with_x1_x2 = false,

    b_click_or_hold = true,
    rightstick_click_or_hold = true,
    left_shoulder_click = true,
    left_shoulder_click = true,

    --in orighinal game, no matter you use what gamepad, the comfirm button is always the bottom face button same as xbox
    swap_a_with_b = false,
}
