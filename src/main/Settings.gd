extends Node

const IGNORE_SETTINGS_FILE = false
const SETTINGS_PATH = "user://settings.ini"

var volume_master = 1.0
var volume_music = 0.5
var volume_sfx = 1.0
var volume_player = 1.0
var volume_others = 1.0
var volume_enemies = 1.0
var volume_map = 1.0

func _ready():
	$Panel.hide()
	if IGNORE_SETTINGS_FILE: return
	var file = File.new()
	if file.file_exists(SETTINGS_PATH):
		load_settings()
	save_settings()
	
func load_settings():
	var config = ConfigFile.new()
	config.load(SETTINGS_PATH)
	
	for sec in config.get_sections():
		if sec != "KEYBINDS":
			for key in config.get_section_keys(sec):
				var prop_name = sec.to_lower() + "_" + key
				set(prop_name, config.get_value(sec, key))
	
	if config.has_section("KEYBINDS"):
		for action_name in config.get_section_keys("KEYBINDS"):
			InputMap.action_erase_events(action_name)
			var list = config.get_value("KEYBINDS", action_name)
			if !(list is Array):
				list = [list]
			for action in list:
				var event = null
				if action is String and action.begins_with("KEY_"):
					event = InputEventKey.new()
					event.scancode = input_keys[action]
				elif action is String and action.begins_with("BUTTON_"):
					event = InputEventMouseButton.new()
					event.button_index = input_keys[action]
				elif action is String and action.begins_with("JOY_"):
					event = InputEventJoypadButton.new()
					event.button_index = input_keys[action]
				elif action is Dictionary and action.has("key"):
					event = InputEventKey.new()
					event.scancode = input_keys[action.key]
					for m in input_modifiers:
						if m in action and action[m]:
							event.set(m, true)
				elif action is Dictionary and action.has("button"):
					event = InputEventMouseButton.new()
					event.button_index = input_keys[action.key]
					for m in input_modifiers:
						if m in action and action[m]:
							event.set(m, true)
				elif action is Dictionary and action.has("joy"):
					event = InputEventJoypadButton.new()
					event.button_index = action.joy
					if action.has("device"):
						event.device = action.device
				elif action is Dictionary and action.has("axis"):
					event = InputEventJoypadMotion.new()
					event.axis = input_keys[action.axis]
					event.axis_value = action.value
					if action.has("device"):
						event.device = action.device
					if action.has("deadzone"):
						InputMap.action_set_deadzone(action_name, action.deadzone)
				if event != null:
					InputMap.action_add_event(action_name, event)
				else:
					print("INVALID ACTION!")
	
func save_settings():
	var config = ConfigFile.new()
	
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
			var i = prop.name.find("_")
			var sec = prop.name.substr(0, i).to_upper()
			var key = prop.name.substr(i + 1, prop.name.length() - i - 1)
			config.set_value(sec, key, get(prop.name))
	
	var all_actions = InputMap.get_actions()
	all_actions.sort_custom(self, "sort_action_names")
	for action_name in all_actions:
		if action_name.begins_with("ui_"): continue
		var list = []
		var actions = InputMap.get_action_list(action_name)
		for action in actions:
			var binding = get_input_binding(action)
			if binding:
				list.append(binding)
		if list.size() == 1:
			config.set_value("KEYBINDS", action_name, list[0])
		elif list.size() > 1:
			config.set_value("KEYBINDS", action_name, list)
	
	config.save(SETTINGS_PATH)
	
	
func get_input_binding(event):
	if event is InputEventKey:
		for k in input_keys:
			if k.begins_with("KEY_") and input_keys[k] == event.scancode:
				var mod = false
				var dict = {}
				dict["key"] = k
				for m in input_modifiers:
					if event.get(m):
						mod = true
						dict[m] = true
				if mod:
					return dict
				else:
					return k
	elif event is InputEventMouseButton:
		for k in input_keys:
			if k.begins_with("BUTTON_") and input_keys[k] == event.button_index:
				var mod = false
				var dict = {}
				dict["button"] = k
				for m in input_modifiers:
					if event.get(m):
						mod = true
						dict[m] = true
				if mod:
					return dict
				else:
					return k
	elif event is InputEventJoypadButton:
		for k in input_keys:
			if k.begins_with("JOY_") and input_keys[k] == event.button_index:
				return k
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.5:
		for k in input_keys:
			if k.begins_with("JOY_AXIS_") and input_keys[k] == event.axis:
				var dict = {}
				dict["axis"] = k
				dict["value"] = -1 if event.axis_value < 0 else 1
				return dict
	return false

func sort_action_names(a1, a2):
	if a1.begins_with("ui_") and not a2.begins_with("ui_"):
		return false
	elif a2.begins_with("ui_") and not a1.begins_with("ui_"):
		return true
	elif a1 < a2:
		return true
	else:
		return false

const input_modifiers = [ "alt", "command", "control", "meta", "shift" ]
const input_keys = {
	"KEY_ESCAPE": KEY_ESCAPE,
	"KEY_TAB": KEY_TAB,
	"KEY_BACKTAB": KEY_BACKTAB,
	"KEY_BACKSPACE": KEY_BACKSPACE,
	"KEY_ENTER": KEY_ENTER,
	"KEY_KP_ENTER": KEY_KP_ENTER,
	"KEY_INSERT": KEY_INSERT,
	"KEY_DELETE": KEY_DELETE,
	"KEY_PAUSE": KEY_PAUSE,
	"KEY_PRINT": KEY_PRINT,
	"KEY_SYSREQ": KEY_SYSREQ,
	"KEY_CLEAR": KEY_CLEAR,
	"KEY_HOME": KEY_HOME,
	"KEY_END": KEY_END,
	"KEY_LEFT": KEY_LEFT,
	"KEY_UP": KEY_UP,
	"KEY_RIGHT": KEY_RIGHT,
	"KEY_DOWN": KEY_DOWN,
	"KEY_PAGEUP": KEY_PAGEUP,
	"KEY_PAGEDOWN": KEY_PAGEDOWN,
	"KEY_SHIFT": KEY_SHIFT,
	"KEY_CONTROL": KEY_CONTROL,
	"KEY_META": KEY_META,
	"KEY_ALT": KEY_ALT,
	"KEY_CAPSLOCK": KEY_CAPSLOCK,
	"KEY_NUMLOCK": KEY_NUMLOCK,
	"KEY_SCROLLLOCK": KEY_SCROLLLOCK,
	"KEY_F1": KEY_F1,
	"KEY_F2": KEY_F2,
	"KEY_F3": KEY_F3,
	"KEY_F4": KEY_F4,
	"KEY_F5": KEY_F5,
	"KEY_F6": KEY_F6,
	"KEY_F7": KEY_F7,
	"KEY_F8": KEY_F8,
	"KEY_F9": KEY_F9,
	"KEY_F10": KEY_F10,
	"KEY_F11": KEY_F11,
	"KEY_F12": KEY_F12,
	"KEY_F13": KEY_F13,
	"KEY_F14": KEY_F14,
	"KEY_F15": KEY_F15,
	"KEY_F16": KEY_F16,
	"KEY_KP_MULTIPLY": KEY_KP_MULTIPLY,
	"KEY_KP_DIVIDE": KEY_KP_DIVIDE,
	"KEY_KP_SUBTRACT": KEY_KP_SUBTRACT,
	"KEY_KP_PERIOD": KEY_KP_PERIOD,
	"KEY_KP_ADD": KEY_KP_ADD,
	"KEY_KP_0": KEY_KP_0,
	"KEY_KP_1": KEY_KP_1,
	"KEY_KP_2": KEY_KP_2,
	"KEY_KP_3": KEY_KP_3,
	"KEY_KP_4": KEY_KP_4,
	"KEY_KP_5": KEY_KP_5,
	"KEY_KP_6": KEY_KP_6,
	"KEY_KP_7": KEY_KP_7,
	"KEY_KP_8": KEY_KP_8,
	"KEY_KP_9": KEY_KP_9,
	"KEY_SUPER_L": KEY_SUPER_L,
	"KEY_SUPER_R": KEY_SUPER_R,
	"KEY_MENU": KEY_MENU,
	"KEY_HYPER_L": KEY_HYPER_L,
	"KEY_HYPER_R": KEY_HYPER_R,
	"KEY_HELP": KEY_HELP,
	"KEY_DIRECTION_L": KEY_DIRECTION_L,
	"KEY_DIRECTION_R": KEY_DIRECTION_R,
	"KEY_BACK": KEY_BACK,
	"KEY_FORWARD": KEY_FORWARD,
	"KEY_STOP": KEY_STOP,
	"KEY_REFRESH": KEY_REFRESH,
	"KEY_VOLUMEDOWN": KEY_VOLUMEDOWN,
	"KEY_VOLUMEMUTE": KEY_VOLUMEMUTE,
	"KEY_VOLUMEUP": KEY_VOLUMEUP,
	"KEY_BASSBOOST": KEY_BASSBOOST,
	"KEY_BASSUP": KEY_BASSUP,
	"KEY_BASSDOWN": KEY_BASSDOWN,
	"KEY_TREBLEUP": KEY_TREBLEUP,
	"KEY_TREBLEDOWN": KEY_TREBLEDOWN,
	"KEY_MEDIAPLAY": KEY_MEDIAPLAY,
	"KEY_MEDIASTOP": KEY_MEDIASTOP,
	"KEY_MEDIAPREVIOUS": KEY_MEDIAPREVIOUS,
	"KEY_MEDIANEXT": KEY_MEDIANEXT,
	"KEY_MEDIARECORD": KEY_MEDIARECORD,
	"KEY_HOMEPAGE": KEY_HOMEPAGE,
	"KEY_FAVORITES": KEY_FAVORITES,
	"KEY_SEARCH": KEY_SEARCH,
	"KEY_STANDBY": KEY_STANDBY,
	"KEY_OPENURL": KEY_OPENURL,
	"KEY_LAUNCHMAIL": KEY_LAUNCHMAIL,
	"KEY_LAUNCHMEDIA": KEY_LAUNCHMEDIA,
	"KEY_LAUNCH0": KEY_LAUNCH0,
	"KEY_LAUNCH1": KEY_LAUNCH1,
	"KEY_LAUNCH2": KEY_LAUNCH2,
	"KEY_LAUNCH3": KEY_LAUNCH3,
	"KEY_LAUNCH4": KEY_LAUNCH4,
	"KEY_LAUNCH5": KEY_LAUNCH5,
	"KEY_LAUNCH6": KEY_LAUNCH6,
	"KEY_LAUNCH7": KEY_LAUNCH7,
	"KEY_LAUNCH8": KEY_LAUNCH8,
	"KEY_LAUNCH9": KEY_LAUNCH9,
	"KEY_LAUNCHA": KEY_LAUNCHA,
	"KEY_LAUNCHB": KEY_LAUNCHB,
	"KEY_LAUNCHC": KEY_LAUNCHC,
	"KEY_LAUNCHD": KEY_LAUNCHD,
	"KEY_LAUNCHE": KEY_LAUNCHE,
	"KEY_LAUNCHF": KEY_LAUNCHF,
	"KEY_UNKNOWN": KEY_UNKNOWN,
	"KEY_SPACE": KEY_SPACE,
	"KEY_EXCLAM": KEY_EXCLAM,
	"KEY_QUOTEDBL": KEY_QUOTEDBL,
	"KEY_NUMBERSIGN": KEY_NUMBERSIGN,
	"KEY_DOLLAR": KEY_DOLLAR,
	"KEY_PERCENT": KEY_PERCENT,
	"KEY_AMPERSAND": KEY_AMPERSAND,
	"KEY_APOSTROPHE": KEY_APOSTROPHE,
	"KEY_PARENLEFT": KEY_PARENLEFT,
	"KEY_PARENRIGHT": KEY_PARENRIGHT,
	"KEY_ASTERISK": KEY_ASTERISK,
	"KEY_PLUS": KEY_PLUS,
	"KEY_COMMA": KEY_COMMA,
	"KEY_MINUS": KEY_MINUS,
	"KEY_PERIOD": KEY_PERIOD,
	"KEY_SLASH": KEY_SLASH,
	"KEY_0": KEY_0,
	"KEY_1": KEY_1,
	"KEY_2": KEY_2,
	"KEY_3": KEY_3,
	"KEY_4": KEY_4,
	"KEY_5": KEY_5,
	"KEY_6": KEY_6,
	"KEY_7": KEY_7,
	"KEY_8": KEY_8,
	"KEY_9": KEY_9,
	"KEY_COLON": KEY_COLON,
	"KEY_SEMICOLON": KEY_SEMICOLON,
	"KEY_LESS": KEY_LESS,
	"KEY_EQUAL": KEY_EQUAL,
	"KEY_GREATER": KEY_GREATER,
	"KEY_QUESTION": KEY_QUESTION,
	"KEY_AT": KEY_AT,
	"KEY_A": KEY_A,
	"KEY_B": KEY_B,
	"KEY_C": KEY_C,
	"KEY_D": KEY_D,
	"KEY_E": KEY_E,
	"KEY_F": KEY_F,
	"KEY_G": KEY_G,
	"KEY_H": KEY_H,
	"KEY_I": KEY_I,
	"KEY_J": KEY_J,
	"KEY_K": KEY_K,
	"KEY_L": KEY_L,
	"KEY_M": KEY_M,
	"KEY_N": KEY_N,
	"KEY_O": KEY_O,
	"KEY_P": KEY_P,
	"KEY_Q": KEY_Q,
	"KEY_R": KEY_R,
	"KEY_S": KEY_S,
	"KEY_T": KEY_T,
	"KEY_U": KEY_U,
	"KEY_V": KEY_V,
	"KEY_W": KEY_W,
	"KEY_X": KEY_X,
	"KEY_Y": KEY_Y,
	"KEY_Z": KEY_Z,
	"KEY_BRACKETLEFT": KEY_BRACKETLEFT,
	"KEY_BACKSLASH": KEY_BACKSLASH,
	"KEY_BRACKETRIGHT": KEY_BRACKETRIGHT,
	"KEY_ASCIICIRCUM": KEY_ASCIICIRCUM,
	"KEY_UNDERSCORE": KEY_UNDERSCORE,
	"KEY_QUOTELEFT": KEY_QUOTELEFT,
	"KEY_BRACELEFT": KEY_BRACELEFT,
	"KEY_BAR": KEY_BAR,
	"KEY_BRACERIGHT": KEY_BRACERIGHT,
	"KEY_ASCIITILDE": KEY_ASCIITILDE,
	"KEY_NOBREAKSPACE": KEY_NOBREAKSPACE,
	"KEY_EXCLAMDOWN": KEY_EXCLAMDOWN,
	"KEY_CENT": KEY_CENT,
	"KEY_STERLING": KEY_STERLING,
	"KEY_CURRENCY": KEY_CURRENCY,
	"KEY_YEN": KEY_YEN,
	"KEY_BROKENBAR": KEY_BROKENBAR,
	"KEY_SECTION": KEY_SECTION,
	"KEY_DIAERESIS": KEY_DIAERESIS,
	"KEY_COPYRIGHT": KEY_COPYRIGHT,
	"KEY_ORDFEMININE": KEY_ORDFEMININE,
	"KEY_GUILLEMOTLEFT": KEY_GUILLEMOTLEFT,
	"KEY_NOTSIGN": KEY_NOTSIGN,
	"KEY_HYPHEN": KEY_HYPHEN,
	"KEY_REGISTERED": KEY_REGISTERED,
	"KEY_MACRON": KEY_MACRON,
	"KEY_DEGREE": KEY_DEGREE,
	"KEY_PLUSMINUS": KEY_PLUSMINUS,
	"KEY_TWOSUPERIOR": KEY_TWOSUPERIOR,
	"KEY_THREESUPERIOR": KEY_THREESUPERIOR,
	"KEY_ACUTE": KEY_ACUTE,
	"KEY_MU": KEY_MU,
	"KEY_PARAGRAPH": KEY_PARAGRAPH,
	"KEY_PERIODCENTERED": KEY_PERIODCENTERED,
	"KEY_CEDILLA": KEY_CEDILLA,
	"KEY_ONESUPERIOR": KEY_ONESUPERIOR,
	"KEY_MASCULINE": KEY_MASCULINE,
	"KEY_GUILLEMOTRIGHT": KEY_GUILLEMOTRIGHT,
	"KEY_ONEQUARTER": KEY_ONEQUARTER,
	"KEY_ONEHALF": KEY_ONEHALF,
	"KEY_THREEQUARTERS": KEY_THREEQUARTERS,
	"KEY_QUESTIONDOWN": KEY_QUESTIONDOWN,
	"KEY_AGRAVE": KEY_AGRAVE,
	"KEY_AACUTE": KEY_AACUTE,
	"KEY_ACIRCUMFLEX": KEY_ACIRCUMFLEX,
	"KEY_ATILDE": KEY_ATILDE,
	"KEY_ADIAERESIS": KEY_ADIAERESIS,
	"KEY_ARING": KEY_ARING,
	"KEY_AE": KEY_AE,
	"KEY_CCEDILLA": KEY_CCEDILLA,
	"KEY_EGRAVE": KEY_EGRAVE,
	"KEY_EACUTE": KEY_EACUTE,
	"KEY_ECIRCUMFLEX": KEY_ECIRCUMFLEX,
	"KEY_EDIAERESIS": KEY_EDIAERESIS,
	"KEY_IGRAVE": KEY_IGRAVE,
	"KEY_IACUTE": KEY_IACUTE,
	"KEY_ICIRCUMFLEX": KEY_ICIRCUMFLEX,
	"KEY_IDIAERESIS": KEY_IDIAERESIS,
	"KEY_ETH": KEY_ETH,
	"KEY_NTILDE": KEY_NTILDE,
	"KEY_OGRAVE": KEY_OGRAVE,
	"KEY_OACUTE": KEY_OACUTE,
	"KEY_OCIRCUMFLEX": KEY_OCIRCUMFLEX,
	"KEY_OTILDE": KEY_OTILDE,
	"KEY_ODIAERESIS": KEY_ODIAERESIS,
	"KEY_MULTIPLY": KEY_MULTIPLY,
	"KEY_OOBLIQUE": KEY_OOBLIQUE,
	"KEY_UGRAVE": KEY_UGRAVE,
	"KEY_UACUTE": KEY_UACUTE,
	"KEY_UCIRCUMFLEX": KEY_UCIRCUMFLEX,
	"KEY_UDIAERESIS": KEY_UDIAERESIS,
	"KEY_YACUTE": KEY_YACUTE,
	"KEY_THORN": KEY_THORN,
	"KEY_SSHARP": KEY_SSHARP,
	"KEY_DIVISION": KEY_DIVISION,
	"KEY_YDIAERESIS": KEY_YDIAERESIS,
	"BUTTON_LEFT": BUTTON_LEFT,
	"BUTTON_RIGHT": BUTTON_RIGHT,
	"BUTTON_MIDDLE": BUTTON_MIDDLE,
	"BUTTON_XBUTTON1": BUTTON_XBUTTON1,
	"BUTTON_XBUTTON2": BUTTON_XBUTTON2,
	"BUTTON_WHEEL_UP": BUTTON_WHEEL_UP,
	"BUTTON_WHEEL_DOWN": BUTTON_WHEEL_DOWN,
	"BUTTON_WHEEL_LEFT": BUTTON_WHEEL_LEFT,
	"BUTTON_WHEEL_RIGHT": BUTTON_WHEEL_RIGHT,
	"BUTTON_MASK_LEFT": BUTTON_MASK_LEFT,
	"BUTTON_MASK_RIGHT": BUTTON_MASK_RIGHT,
	"BUTTON_MASK_MIDDLE": BUTTON_MASK_MIDDLE,
	"BUTTON_MASK_XBUTTON1": BUTTON_MASK_XBUTTON1,
	"BUTTON_MASK_XBUTTON2": BUTTON_MASK_XBUTTON2,
	"JOY_BUTTON_0": JOY_BUTTON_0,
	"JOY_BUTTON_1": JOY_BUTTON_1,
	"JOY_BUTTON_2": JOY_BUTTON_2,
	"JOY_BUTTON_3": JOY_BUTTON_3,
	"JOY_BUTTON_4": JOY_BUTTON_4,
	"JOY_BUTTON_5": JOY_BUTTON_5,
	"JOY_BUTTON_6": JOY_BUTTON_6,
	"JOY_BUTTON_7": JOY_BUTTON_7,
	"JOY_BUTTON_8": JOY_BUTTON_8,
	"JOY_BUTTON_9": JOY_BUTTON_9,
	"JOY_BUTTON_10": JOY_BUTTON_10,
	"JOY_BUTTON_11": JOY_BUTTON_11,
	"JOY_BUTTON_12": JOY_BUTTON_12,
	"JOY_BUTTON_13": JOY_BUTTON_13,
	"JOY_BUTTON_14": JOY_BUTTON_14,
	"JOY_BUTTON_15": JOY_BUTTON_15,
	"JOY_BUTTON_MAX": JOY_BUTTON_MAX,
	"JOY_SONY_CIRCLE": JOY_SONY_CIRCLE,
	"JOY_SONY_X": JOY_SONY_X,
	"JOY_SONY_SQUARE": JOY_SONY_SQUARE,
	"JOY_SONY_TRIANGLE": JOY_SONY_TRIANGLE,
	"JOY_XBOX_B": JOY_XBOX_B,
	"JOY_XBOX_A": JOY_XBOX_A,
	"JOY_XBOX_X": JOY_XBOX_X,
	"JOY_XBOX_Y": JOY_XBOX_Y,
	"JOY_DS_A": JOY_DS_A,
	"JOY_DS_B": JOY_DS_B,
	"JOY_DS_X": JOY_DS_X,
	"JOY_DS_Y": JOY_DS_Y,
	"JOY_SELECT": JOY_SELECT,
	"JOY_START": JOY_START,
	"JOY_DPAD_UP": JOY_DPAD_UP,
	"JOY_DPAD_DOWN": JOY_DPAD_DOWN,
	"JOY_DPAD_LEFT": JOY_DPAD_LEFT,
	"JOY_DPAD_RIGHT": JOY_DPAD_RIGHT,
	"JOY_L": JOY_L,
	"JOY_L2": JOY_L2,
	"JOY_L3": JOY_L3,
	"JOY_R": JOY_R,
	"JOY_R2": JOY_R2,
	"JOY_R3": JOY_R3,
	"JOY_AXIS_0": JOY_AXIS_0,
	"JOY_AXIS_1": JOY_AXIS_1,
	"JOY_AXIS_2": JOY_AXIS_2,
	"JOY_AXIS_3": JOY_AXIS_3,
	"JOY_AXIS_4": JOY_AXIS_4,
	"JOY_AXIS_5": JOY_AXIS_5,
	"JOY_AXIS_6": JOY_AXIS_6,
	"JOY_AXIS_7": JOY_AXIS_7,
	"JOY_AXIS_8": JOY_AXIS_8,
	"JOY_AXIS_9": JOY_AXIS_9,
	"JOY_AXIS_MAX": JOY_AXIS_MAX,
	"JOY_ANALOG_LX": JOY_ANALOG_LX,
	"JOY_ANALOG_LY": JOY_ANALOG_LY,
	"JOY_ANALOG_RX": JOY_ANALOG_RX,
	"JOY_ANALOG_RY": JOY_ANALOG_RY,
	"JOY_ANALOG_L2": JOY_ANALOG_L2,
	"JOY_ANALOG_R2": JOY_ANALOG_R2
}
