CURRENT_VERSION = "1.0"
TOOL_NAME = "Jet Fuel Rocket"

-- delimeters
DELIM = {}
DELIM.VEC = ":"
DELIM.STRINGS = "~"
DELIM.ENUM_PAIR = "&"
DELIM.OPTION_SET = "|"
DELIM.OPTION = ";"

-- registry related delimeters and strings
REG = {}
REG.DELIM = "."
REG.TOOL_KEY = "jetfuelrocket"
REG.TOOL_NAME = "savegame.mod.tool." .. REG.TOOL_KEY .. ".quarkhopper"
REG.TOOL_OPTION = "option"
REG.PREFIX_TOOL_OPTIONS = REG.TOOL_NAME .. REG.DELIM .. REG.TOOL_OPTION
REG.TOOL_KEYBIND = "keybind"
REG.PREFIX_TOOL_KEYBIND = REG.TOOL_NAME .. REG.DELIM .. REG.TOOL_KEYBIND

-- Keybinds
function setup_keybind(name, reg, default_key)
    local keybind = {["name"] = name, ["reg"] = reg}
    keybind.key = GetString(REG.PREFIX_TOOL_KEYBIND..REG.DELIM..keybind.reg)
    if keybind.key == "" then 
        keybind.key = default_key
        SetString(REG.PREFIX_TOOL_KEYBIND..REG.DELIM..keybind.reg, keybind.key)
    end
    return keybind
end

KEY = {}
KEY.FIRE = setup_keybind("Fire rocket", "fire", "LMB")
KEY.CYCLE_FUSE = setup_keybind("cycle fuse distance", "cycle_fuse", "V")

keybind_options = {KEY.FIRE, KEY.CYCLE_FUSE }

-- set on init
TOOL = {}
VALUES = {}

VALUES.SPARK_HURT_SCALE = 0.005
VALUES.IMPULSE_SCALE = 0.005
VALUES.PRESSURE_EFFECT_SCALE = 10^-3
VALUES.PUFF_CONTRAST = 0.65

-- UI 
UI = {}
UI.LEGEND_TEXT_SIZE = 20
UI.OPTION_TEXT_SIZE = 14
UI.OPTION_CONTROL_WIDTH = 300
