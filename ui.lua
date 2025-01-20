#include "script/Utils.lua"
#include "script/Defs.lua"
#include "script/Types.lua"
#include "script/Simulation.lua"

function draw()
	if not canInteract(false, true) then return end
	drawLegend()
end

function drawLegend()
	UiPush()
		UiFont("bold.ttf", UI.LEGEND_TEXT_SIZE)
		UiTextOutline(0,0,0,1,0.5)
		UiColor(1,1,1)

		UiPush()
			UiTranslate(0, UI.LEGEND_TEXT_SIZE + 2)

			UiPush()
				UiAlign("left")
				for i=1, #keybind_options do
					option = keybind_options[i]
					local keybindString = "["..option.key.." "..option.name.."]"
					local textWidth = UiGetTextSize(keybindString)
					UiText(keybindString, true)
				end
			UiPop()

			UiPush()
				UiAlign("right")
				UiTranslate(UiWidth() - 5, 0)
				UiText("[FUSE DIST: "..fuseDistances[fuseIndex].."]")
			UiPop()
		UiPop()

		UiPush()
			UiTranslate(0, UiHeight() - 2)
			UiAlign("left")
			UiText("Total sparks: "..#allSparks, true)
		UiPop()
	UiPop()
end



