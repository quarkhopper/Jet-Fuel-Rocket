#include "script/Utils.lua"
#include "script/Defs.lua"
#include "script/Types.lua"
#include "script/Init.lua"

function init()
    updating_key = nil
end

function draw()
    UiButtonImageBox("ui/common/box-outline-6.png", 4, 4)
    UiPush()
        UiTranslate(UiCenter(), 200)
        UiAlign("center middle")
        UiFont("bold.ttf", 40)
        UiText("Jet Fuel Rocket Keybinds", true)
        UiText("Press a key to change the binding", true)
        UiText("Press esc to exit")

        UiTranslate(0, 200)

        for i = 1, #keybind_options do
            draw_keybind_line(keybind_options[i])
            UiTranslate(0, 40)
        end
    UiPop()

    if updating_key ~= nil then 
        draw_set_key_modal() 
    end
end

function draw_keybind_line(keybind)
    local sep = " : "
    UiAlign("right middle")
    UiText(keybind.name..sep)
    UiAlign("left middle")
    UiText(keybind.key)

    local key_pressed = InputLastPressedKey()
    if key_pressed == keybind.key and updating_key == nil then 
        updating_key = keybind
    end
end

function draw_set_key_modal()
    UiPush()
        UiModalBegin()
            UiAlign("left top")
            UiFont("bold.ttf", UI.OPTION_TEXT_SIZE)
            UiTextOutline(0,0,0,1,0.5)
            UiColor(1,1,1)
            UiPush()
                -- borders and background
                UiTranslate(UiCenter(), UiMiddle())
                UiAlign("center middle")
                UiColor(1, 1, 1)
                UiRect(505, 205)
                UiColor(0.2, 0.2, 0.2)
                UiRect(500, 200)
            UiPop()
            UiPush()
                UiTranslate(UiCenter(), UiMiddle())
                UiAlign("center middle")
                UiFont("bold.ttf", 20)
                UiText("Press any key to set binding for: "..updating_key.name)
            UiPop()
            local key_pressed = InputLastPressedKey()
            if key_pressed ~= "" and key_pressed ~= "esc" then 
                updating_key.key = key_pressed
                SetString(REG.PREFIX_TOOL_KEYBIND..REG.DELIM..updating_key.reg, key_pressed)
                updating_key = nil
            end
        UiModalEnd()
    UiPop()

end