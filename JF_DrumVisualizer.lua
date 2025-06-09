reaper.gmem_attach("JF_DrumVisualizer")

function tableInsert(t, data)
  if not t then
	debug_printStack()
	end
  t[#t+1] = data
  end

function deepCopy(orig)
  local copy = {}
  for k, v in pairs(orig) do
	if type(v) == "table" then
	  copy[k] = deepCopy(v)
	else
	  copy[k] = v
	end
  end
  return copy
end

function deepEquals(t1, t2)
  if type(t1) ~= "table" or type(t2) ~= "table" then
	return t1 == t2
  end

  -- Check that all keys and values in t1 match those in t2
  for k, v in pairs(t1) do
	if not deepEquals(v, t2[k]) then
	  return false
	end
  end

  -- Check that t2 doesn't have extra keys
  for k in pairs(t2) do
	if t1[k] == nil then
	  return false
	end
  end

  return true
end

function getScriptDirectory()
  local dir = reaper.GetResourcePath() .. "/JF_DrumVisualizer/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getAssetsDirectory()
  local dir = getGodotDirectory() .. "assets/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end
  
function getConfigurationsDirectory()
  local dir = getScriptDirectory() .. "configurations/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getDrumKitsDirectory()
  local dir = getScriptDirectory() .. "drum_kits/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end
  
function getOtherDirectory()
  local dir = getAssetsDirectory() .. "other/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getNoteTypesFilePath()
  return getGodotDirectory() .. "note_types.json"
  end
  
function getSettingsFilePath()
  return getScriptDirectory() .. "settings.txt"
  end

function getSettingListFromFile()
  local list = {}
  
  local file = io.open(getSettingsFilePath(), "r")
  if file then
	local fileText = file:read("*all")
	file:close()
	
	for line in fileText:gmatch("[^\r\n]+") do
	  line = trimTrailingSpaces(line)
	  local key, value
	  local spaceIndex = string.find(line, " ")
	  if not spaceIndex then
		key = line
	  else
		key = string.sub(line, 1, spaceIndex-1)
		value = string.sub(line, spaceIndex+1, #line)
		end
	  tableInsert(list, {key, value})
	  end
	end
  
  return list
  end

function getSettingFromFile(key, default)
  local list = getSettingListFromFile()
  for x=1, #list do
	local data = list[x]
	if data[1] == key then
	  local value = data[2]
	  if not value then
		value = writeSettingToFile(key, default)
		end
	  if tonumber(value) then value = tonumber(value) end
	  return value
	  end
	end
  
  return writeSettingToFile(key, default)
  end

function writeSettingToFile(key, value)
  if not value then return end
  
  local returnVal = value

  local str = ""
  
  local list = getSettingListFromFile()
  local foundSetting = false
  for x=1, #list do
	local data = list[x]
	if data[1] == key then
	  data[2] = value
	  foundSetting = true
	  end
	str = str .. data[1]
	if data[2] then
	  str = str .. " " .. tostring(data[2])
	  end
	str = str .. "\n"
	end
  
  if not foundSetting then
	str = str .. key .. " " .. value .. "\n"
	end
	
  local file = io.open(getSettingsFilePath(), "w+")
  file:write(str)
  file:close()
  
  return returnVal
  end

function defineRequiredNoteTypeTable()
  noteTypeTable = {}
  
  local json = dofile(getScriptDirectory() .. "dkjson.lua")
  
  local file = io.open(getNoteTypesFilePath(), "r")
  local fileText = file:read("*all")
  file:close()
  
  local obj, pos, err = json.decode(fileText, 1, nil)
  if err then
	reaper.ShowConsoleMsg("Error:", err)
  else
	for noteType, value in pairs(obj) do
	  local stateList = value.States
	  local propertiesList = value.Properties
	  tableInsert(noteTypeTable, {noteType, stateList, propertiesList})
	  end
	end
  end
  
function runProfiler()
  local profiler = dofile(reaper.GetResourcePath() ..
	'/Scripts/ReaTeam Scripts/Development/cfillion_Lua profiler.lua')
  reaper.defer = profiler.defer
  profiler.attachToWorld() -- after all functions have been defined
  profiler.run()
  end
  
function floor(x)
  return math.floor(x)
  end

function trimTrailingSpaces(s)
  return s:gsub("%s+$", "")
  end

function colorToRGB(color)
  local r = (color >> 16) & 0xFF
  local g = (color >> 8) & 0xFF
  local b = color & 0xFF
  return r, g, b
  end
	  
function hexColor(r, g, b, a) --optional a
  if a == nil then
	a = 255
	end
  
  r = math.min(math.max(r, 0), 255)
  g = math.min(math.max(g, 0), 255)
  b = math.min(math.max(b, 0), 255)
  a = math.min(math.max(a, 0), 255)
  
  local function formatToHex(num)
	num = math.floor(num)
	num = string.format("%x", num)
	if string.len(num) == 1 then
	  num = "0" .. num
	  end
	return num
	end
  
  local strTable = {"0x", formatToHex(r), formatToHex(g), formatToHex(b), formatToHex(a)}
  local str = table.concat(strTable)
  
  return tonumber(str)
  end

function padToFourDigits(n)
  return string.format("%04d", n)
  end

function getNumCharsInString(str, char)
  return select(2, str:gsub(char, ""))
  end
  
local masterImageList, gemImageList, notationImageList

local VALID_RHYTHM_DENOM_LIST = {1, 2, 4, 8, 16, 32, 64, 128}

local notationLayer_clef
local notationLayer_notehead
local notationLayer_gracenotehead
local notationLayer_rest
local notationLayer_dot
local notationLayer_ghost
local notationLayer_flag
local notationLayer_graceflag
local notationLayer_graceline
local notationLayer_beam
local notationLayer_stem
local notationLayer_legerLine
local notationLayer_tuplet
local notationLayer_articulation
local notationLayer_timeSig
local notationLayer_measureLine
local notationLayer_beatNumber
local notationLayer_measureNumber
local notationLayer_tempo
local notationLayer_dynamic

function defineErrorCodes()
  ERROR_INVALIDTAKE = 0
  ERROR_INVALIDREAPERSETUP = 1
  ERROR_CONFIGINTOMEMORY = 2
  ERROR_MIDIINTOMEMORY = 3
  ERROR_RHYTHMLIST = 4
  end

function defineIndeces()
  INDEX_LABEL = 1
  INDEX_DISPLAYNAME = 2
  INDEX_MIDINOTENUM = 3
  
  INDEX_SPRITE = 2
  INDEX_COLOR = 3
  INDEX_POSITION = 4
  INDEX_NOTATIONLABEL = 5
  INDEX_NOTATIONPOS = 6
  
  STATEINDEX_GEM = 1
  STATEINDEX_COLOR = 2
  STATEINDEX_NOTEHEAD = 3
  STATEINDEX_STAFFLINE = 4
  STATEINDEX_ARTICULATION = 5
  STATEINDEX_HHPEDAL = 6
  STATEINDEX_NAME = 7 --always make sure this is the last index!
  
  TEMPOMAPINDEX_QN = 1
  TEMPOMAPINDEX_PPQPOS = 2
  TEMPOMAPINDEX_TIME = 3
  TEMPOMAPINDEX_BPM = 4
  
  CHORDGLOBALDATAINDEX_QN = 1
  CHORDGLOBALDATAINDEX_PPQPOS = 2
  CHORDGLOBALDATAINDEX_VOICEINDEX = 3
  CHORDGLOBALDATAINDEX_ISREST = 4
  CHORDGLOBALDATAINDEX_ARTICULATIONLIST = 5
  CHORDGLOBALDATAINDEX_BEAMSTATE = 6
  CHORDGLOBALDATAINDEX_DRAWBEAMSTATE = 7
  CHORDGLOBALDATAINDEX_ROLL = 8
  CHORDGLOBALDATAINDEX_EXTRATIE = 9
  CHORDGLOBALDATAINDEX_FAKECHORD = 10
  CHORDGLOBALDATAINDEX_SUSTAINSTART = 11
  
  MEASURELISTINDEX_PPQPOS = 1 --keep as 1
  MEASURELISTINDEX_QN = 2
  MEASURELISTINDEX_TIME = 3
  MEASURELISTINDEX_BEAMGROUPINGS = 4
  MEASURELISTINDEX_SECONDARYBEAMGROUPINGS = 5
  MEASURELISTINDEX_TIMESIGNUM = 6
  MEASURELISTINDEX_TIMESIGDENOM = 7
  MEASURELISTINDEX_MEASUREBOUNDARYXMIN = 8
  MEASURELISTINDEX_MEASUREBOUNDARYXMAX = 9
  MEASURELISTINDEX_TUPLETLIST = 10
  MEASURELISTINDEX_BEATTABLE = 11
  MEASURELISTINDEX_QUANTIZESTR = 12
  MEASURELISTINDEX_QUANTIZEDENOM = 13
  MEASURELISTINDEX_QUANTIZETUPLETFACTORNUM = 14
  MEASURELISTINDEX_QUANTIZETUPLETFACTORDENOM = 15
  MEASURELISTINDEX_QUANTIZEMODIFIER = 16
  MEASURELISTINDEX_RESTOFFSET1 = 17
  MEASURELISTINDEX_RESTOFFSET2 = 18
  MEASURELISTINDEX_VALIDCURRENTMEASURE = 19
  MEASURELISTINDEX_MULTIREST = 20
  
  NOTELISTINDEX_STARTPPQPOS = 1
  NOTELISTINDEX_ENDPPQPOS = 2
  NOTELISTINDEX_STARTQN = 3
  NOTELISTINDEX_ENDQN = 4
  NOTELISTINDEX_STARTTIME = 5
  NOTELISTINDEX_ENDTIME = 6
  NOTELISTINDEX_QNQUANTIZED = 7 --ensure this is the same as RESTLISTINDEX_QNQUANTIZED
  NOTELISTINDEX_CHANNEL = 8
  NOTELISTINDEX_MIDINOTENUM = 9
  NOTELISTINDEX_STATENAME = 10
  NOTELISTINDEX_GEM = 11
  NOTELISTINDEX_COLOR = 12
  NOTELISTINDEX_POSITION = 13
  NOTELISTINDEX_VOICEINDEX = 14
  NOTELISTINDEX_ROLL = 15
  NOTELISTINDEX_GHOST = 16
  NOTELISTINDEX_GRACESTATE = 17
  NOTELISTINDEX_NOTEHEAD = 18
  NOTELISTINDEX_STAFFLINE = 19
  NOTELISTINDEX_ARTICULATION = 20
  NOTELISTINDEX_VELOCITY = 21
  NOTELISTINDEX_NOTEID = 22
  NOTELISTINDEX_SUSTAINID = 23
  NOTELISTINDEX_SUSTAINVOICEINDEX = 24
  
  CHARTNOTELISTINDEX_TIME = 1
  CHARTNOTELISTINDEX_GEM = 2
  CHARTNOTELISTINDEX_POSITION = 3
  CHARTNOTELISTINDEX_VELOCITY = 4
  CHARTNOTELISTINDEX_SHIFTX = 5
  CHARTNOTELISTINDEX_SHIFTY = 6
  CHARTNOTELISTINDEX_SCALE = 7
  CHARTNOTELISTINDEX_COLOR_R = 8
  CHARTNOTELISTINDEX_COLOR_G = 9
  CHARTNOTELISTINDEX_COLOR_B = 10
  CHARTNOTELISTINDEX_COLOR_A = 11
  CHARTNOTELISTINDEX_ZINDEX = 12
  
  ARTICULATIONLISTINDEX_PPQPOS = 1
  ARTICULATIONLISTINDEX_QN = 2
  ARTICULATIONLISTINDEX_TEXTEVTID = 3
  ARTICULATIONLISTINDEX_TABLE = 4
  
  BEAMOVERRIDELISTINDEX_PPQPOS = 1
  BEAMOVERRIDELISTINDEX_QN = 2
  BEAMOVERRIDELISTINDEX_TEXTEVTID = 3
  BEAMOVERRIDELISTINDEX_VAL = 4
  
  TUPLETLISTINDEX_STARTPPQPOS = 1
  TUPLETLISTINDEX_ENDPPQPOS = 2
  TUPLETLISTINDEX_STARTQN = 3
  TUPLETLISTINDEX_ENDQN = 4
  TUPLETLISTINDEX_STARTTIME = 5
  TUPLETLISTINDEX_ENDTIME = 6
  TUPLETLISTINDEX_CHANNEL = 7
  TUPLETLISTINDEX_BASERHYTHM = 8
  TUPLETLISTINDEX_NUM = 9
  TUPLETLISTINDEX_DENOM = 10
  TUPLETLISTINDEX_SHOWCOLON = 11
  
  RHYTHMOVERRIDELISTINDEX_STARTPPQPOS = 1
  RHYTHMOVERRIDELISTINDEX_ENDPPQPOS = 2
  RHYTHMOVERRIDELISTINDEX_STARTQN = 3
  RHYTHMOVERRIDELISTINDEX_ENDQN = 4
  RHYTHMOVERRIDELISTINDEX_STARTTIME = 5
  RHYTHMOVERRIDELISTINDEX_ENDTIME = 6
  RHYTHMOVERRIDELISTINDEX_NUM = 7
  RHYTHMOVERRIDELISTINDEX_DENOM = 8
  
  SUSTAINLISTINDEX_STARTPPQPOS = 1
  SUSTAINLISTINDEX_ENDPPQPOS = 2
  SUSTAINLISTINDEX_STARTQN = 3
  SUSTAINLISTINDEX_ENDQN = 4
  SUSTAINLISTINDEX_STARTTIME = 5
  SUSTAINLISTINDEX_ENDTIME = 6
  SUSTAINLISTINDEX_ROLLTYPE = 7
  SUSTAINLISTINDEX_TIE = 8
  
  RESTLISTINDEX_STARTPPQPOS = 1
  RESTLISTINDEX_ENDPPQPOS = 2
  RESTLISTINDEX_STARTQN = 3
  RESTLISTINDEX_ENDQN = 4
  RESTLISTINDEX_STARTTIME = 5
  RESTLISTINDEX_ENDTIME = 6
  RESTLISTINDEX_QNQUANTIZED = 7 --ensure this is the same as NOTELISTINDEX_QNQUANTIZED
  RESTLISTINDEX_NOTATIONTEXT = 8
  
  DYNAMICLISTINDEX_STARTPPQPOS = 1
  DYNAMICLISTINDEX_ENDPPQPOS = 2
  DYNAMICLISTINDEX_STARTQN = 3
  DYNAMICLISTINDEX_ENDQN = 4
  DYNAMICLISTINDEX_STARTTIME = 5
  DYNAMICLISTINDEX_ENDTIME = 6
  DYNAMICLISTINDEX_TYPE = 7
  DYNAMICLISTINDEX_OFFSET = 8
  
  STAFFTEXTLISTINDEX_PPQPOS = 1
  STAFFTEXTLISTINDEX_QN = 2
  STAFFTEXTLISTINDEX_TEXT = 3
  STAFFTEXTLISTINDEX_OFFSET = 4
  STAFFTEXTLISTINDEX_TEXTEVTID = 5
  
  RESTOFFSETLISTINDEX_PPQPOS = 1
  RESTOFFSETLISTINDEX_QN = 2
  RESTOFFSETLISTINDEX_OFFSET = 3
  RESTOFFSETLISTINDEX_TEXTEVTID = 4
  
  RHYTHMLISTINDEX_NUM = 1
  RHYTHMLISTINDEX_DENOM = 2
  RHYTHMLISTINDEX_TUPLETFACTORNUM = 3
  RHYTHMLISTINDEX_TUPLETFACTORDENOM = 4
  RHYTHMLISTINDEX_HASDOT = 5
  RHYTHMLISTINDEX_QN = 6
  RHYTHMLISTINDEX_CHORD = 7
  RHYTHMLISTINDEX_GRACECHORDLIST = 8
  RHYTHMLISTINDEX_NEWBEAM = 9
  RHYTHMLISTINDEX_LABEL = 10
  RHYTHMLISTINDEX_NOTATEDRHYTHMDENOM = 11
  RHYTHMLISTINDEX_TUPLETMODIFIER = 12
  RHYTHMLISTINDEX_BEAMXMLDATA = 13
  RHYTHMLISTINDEX_TUPLETXMLDATA = 14
  RHYTHMLISTINDEX_TIMEMODIFICATIONXMLDATA = 15
  RHYTHMLISTINDEX_ISRHYTHMOVERRIDE = 16
  RHYTHMLISTINDEX_BEGINSTUPLET = 17
  RHYTHMLISTINDEX_ENDSTUPLET = 18
  RHYTHMLISTINDEX_CURRENTRHYTHMWITHOUTTUPLETS = 19
  RHYTHMLISTINDEX_MAXRHYTHMWITHOUTTUPLETS = 20
  RHYTHMLISTINDEX_MINBEAT = 21
  RHYTHMLISTINDEX_MAXBEAT = 22
  RHYTHMLISTINDEX_STARTTIE = 23
  RHYTHMLISTINDEX_FAKECHORD = 24
  RHYTHMLISTINDEX_CHOKE = 25
  
  BEATLISTINDEX_PPQPOS = 1
  BEATLISTINDEX_TIME = 2
  BEATLISTINDEX_QN = 3
  BEATLISTINDEX_BEATTYPE = 4
  
  TEMPOLISTINDEX_PPQPOS = 1
  TEMPOLISTINDEX_QN = 2
  TEMPOLISTINDEX_BPMBASIS = 3
  TEMPOLISTINDEX_BPM = 4
  TEMPOLISTINDEX_PERFORMANCEDIRECTION = 5
  end

REFRESHSTATE_NOTREFRESHING = 0
REFRESHSTATE_COMPLETE = 1
REFRESHSTATE_KEEPSELECTIONS = 2
REFRESHSTATE_ERROR = 3
currentRefreshState = REFRESHSTATE_COMPLETE

PPQ_RESOLUTION = 960

local windowVisibility_CONFIG = getSettingFromFile("window_config", 1)
local windowVisibility_CHART = getSettingFromFile("window_chart", 0)
local windowVisibility_NOTATION = getSettingFromFile("window_notation", 0)

local initialConfigWindowX = 0
local initialConfigWindowY = 45
local initialConfigWindowSizeX = 1050
local initialConfigWindowSizeY = 200

local chartWindowX = 500
local chartWindowSizeX = 810
local chartWindowY = initialConfigWindowY
local chartWindowSizeY = 455

local notationWindowX = 0
local notationWindowSizeX = 1460
local notationWindowY = chartWindowY+chartWindowSizeY-130
local notationWindowSizeY = 355

local errorWindowX = 200
local errorWindowY = 45
local errorWindowSizeX = 1200
local errorWindowSizeY = 300

local MEASURE_PHRASE = 24
local BEAT_MEASURE_CHART = 14
local BEAT_STRONG_CHART = 13
local BEAT_WEAK_CHART = 12
local BEAT_MEASURE_NOTATION = 2
local BEAT_STRONG_NOTATION = 1
local BEAT_WEAK_NOTATION = 0

local firstFrame = true
local VALID_NOTESTRACKNAME = "PART NOTES"
local VALID_EVENTSTRACKNAME = "PART EVENTS"
local TEXT_EVENT = 1
local NOTATION_EVENT = 15
local MAX_RHYTHM = 128
local notationEditor_followPage = true
local globalFrameID = 0
local globalLightingFrameID = 0
local MAX_LIGHTINGFRAMEID = 15

local STAFFLINETHICKNESS = 2
local MEASUREENDSPACING = 5
local MEASURESTARTSPACING = 12
local STEM_XSHIFT = 1
local GRACEQNDIFF = 0.00001

local QUARTERBEATXLEN = 110

local DRAWBEAM_START = 0
local DRAWBEAM_FULLCURRENT = 1
local DRAWBEAM_FULLPREV = 2
local DRAWBEAM_STUBLEFT = 3
local DRAWBEAM_STUBRIGHT = 4
local DRAWBEAM_SECONDARY = 5
local DRAWBEAM_STUBLEFTSECONDARY = 6
local DRAWBEAM_STUBRIGHTSECONDARY = 7
local DRAWBEAM_STUBRIGHTLEFTSECONDARY = 8
local DRAWBEAM_END = 10

local COLOR_BLACK = hexColor(0, 0, 0)
local COLOR_WHITE = hexColor(255, 255, 255)
local COLOR_RED = hexColor(255, 0, 0)
local COLOR_ORANGE = hexColor(255, 128, 0)
local COLOR_YELLOW = hexColor(255, 255, 0)
local COLOR_GREEN = hexColor(0, 255, 0)
local COLOR_BLUE = hexColor(0, 0, 255)
local COLOR_PURPLE = hexColor(255, 0, 255)
local COLOR_PINK = hexColor(255, 105, 180)
local COLOR_BROWN = hexColor(149, 69, 53)

local COLOR_SELECTED = hexColor(0, 70, 255)
local COLOR_HOVERING = hexColor(0, 0, 255)

local TOOLBARCOLOR_RHYTHM = hexColor(235, 255, 255)
local TOOLBARCOLOR_ARTICULATION = hexColor(255, 235, 255)
local TOOLBARCOLOR_GHOST = hexColor(255, 255, 235)
local TOOLBARCOLOR_SUSTAIN = hexColor(195, 215, 255)
local TOOLBARCOLOR_BEAM = hexColor(235, 235, 255)
local TOOLBARCOLOR_GREEN = hexColor(235, 95, 55)
local COLOR_ACTIVE = hexColor(0, 255, 0)
local COLOR_ON = hexColor(200, 255, 135)
local COLOR_HOVERED = hexColor(0, 255, 255)
local COLOR_CLICKED = hexColor(0, 155, 255)
local COLOR_DISABLED = hexColor(100, 100, 100)
	  
local function defineButtonColors(r, g, b)
  return hexColor(r, g, b), hexColor(r+20, g+20, b+20), hexColor(r+40, g+40, b+40)
  end
  
local COLOR_ADD, COLOR_ADD_HOVERED, COLOR_ADD_ACTIVE = defineButtonColors(1, 100, 32)
local COLOR_DELETE, COLOR_DELETE_HOVERED, COLOR_DELETE_ACTIVE = defineButtonColors(255, 40, 0)
local COLOR_SAVE, COLOR_SAVE_HOVERED, COLOR_SAVE_ACTIVE = defineButtonColors(50, 140, 70)
local COLOR_LOAD, COLOR_LOAD_HOVERED, COLOR_LOAD_ACTIVE = defineButtonColors(30, 60, 90)
local COLOR_ARROWBUTTON, COLOR_ARROWBUTTON_HOVERED, COLOR_ARROWBUTTON_ACTIVE = defineButtonColors(50, 50, 50)
local COLOR_ERROR, COLOR_ERROR_HOVERED, COLOR_ERROR_ACTIVE = defineButtonColors(155, 40, 60)

local COLOR_COLLAPSINGHEADER, COLOR_COLLAPSINGHEADER_HOVERED, COLOR_COLLAPSINGHEADER_ACTIVE = defineButtonColors(34, 100, 140)

local MIDICHANNELCOLORLIST = {
  hexColor(209, 75, 75),
  hexColor(186, 198, 124),
  hexColor(97, 200, 109),
  hexColor(59, 114, 177),
  hexColor(106, 150, 129),
  hexColor(161, 58, 100),
  hexColor(198, 146, 81),
  hexColor(55, 177, 63),
  hexColor(55, 164, 177),
  hexColor(65, 25, 165),
  hexColor(187, 128, 203),
  hexColor(192, 155, 110),
  hexColor(178, 192, 110),
  hexColor(110, 192, 177),
  hexColor(103, 120, 155),
  hexColor(170, 120, 197)
}

local BEATLINE_COLOR_LIST = {80, 120, 160}

local TOOLBARRHYTHMLIST = {32, 16, 8, 4, "dot"}

local COLOR_BACKGROUND = COLOR_BLACK
local COLOR_HIDDEN = hexColor(0, 0, 0, 0)
local COLOR_INACTIVEBEAT = hexColor(100, 100, 100)
	  
local MAX_RACKTOMS = 3
local MAX_FLOORTOMS = 2

local ARROW_BUTTON_WIDTH = 20

function debug_printStack()
  local str = ""
  for x=2, math.huge do
	if debug.getinfo(x) == nil then
	  break
	  end
	local name = debug.getinfo(x).name
	if name ~= nil then
	  str = str .. name .. ": "
	  end
	str = str .. debug.getinfo(x).currentline .. "\n"
	end
  reaper.ShowConsoleMsg(str .. "-----\n")
  end

function throwError(text, measureIndex, time)
  if not text then
	text = ""
	end
	
  if measureIndex then
	text = "m." .. measureIndex .. ": " .. text
	local measurePPQPOS = measureList[measureIndex][MEASURELISTINDEX_PPQPOS]
	time = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, measurePPQPOS)
	end
  
  if time then
	reaper.SetEditCurPos(time, true, false)
	end
		
  debug_printStack()
  --reaper.ShowConsoleMsg(text .. "\n")
  error(text)
  end

function getChartType()
  local projectPath = reaper.GetProjectPath()
  if string.find(projectPath, "\\DrumPerformer\\songs\\") then return 0 end
  if string.find(projectPath, "\\DrumPerformer\\jam_tracks\\") then return 1 end
  if string.find(projectPath, "\\DrumPerformer\\lessons\\") then return 2 end
  throwError("Invalid chart type!")
  end
  
function doesNotContainSpecialChars(str)
  return not str:match("[\"'{}]")
  end
  
function addImage(drawList, img, xMin, yMin, xMax, yMax, uvXMin, uvYMin, uvXmax, uvYMax, tintColor)
  if not img then
	debug_printStack()
	end
	
  if xMax > -100 and xMin < 2000 then
	if not tintColor then
	  tintColor = 255
	  end
	reaper.ImGui_DrawList_AddImage(drawList, img, xMin, yMin, xMax, yMax, uvXMin, uvYMin, uvXmax, uvYMax, tintColor)
	end
  end

function addRectFilled(drawList, xMin, yMin, xMax, yMax, color)
  if xMax > -100 and xMin < 2000 then
	reaper.ImGui_DrawList_AddRectFilled(drawList, xMin, yMin, xMax, yMax, color)
	end
  end

function addLine(drawList, x1, y1, x2, y2, color, thickness, force)
  if force or (x1 > -100 and x1 < 2000 and x2 > -100 and x2 < 2000) then
	if not color then
	  color = COLOR_BLACK
	  end
	if not thickness then
	  thickness = STAFFLINETHICKNESS
	  end
	reaper.ImGui_DrawList_AddLine(drawList, x1, y1, x2, y2, color, thickness)
	end
  end
  
function removeExcessZeroes(num)
  return tostring(num):gsub("%.?0+$", "")
  end

function removeQuotes(str)
  if tonumber(str) then return str end
  return string.gsub(str, '"', "")
  end

function findCharFromEnd(str, char, startIndex)
  if not startIndex then
	startIndex = #str
	end
	
  for i = startIndex, 1, -1 do
	if str:sub(i, i) == char then
	  return i  -- Return the first match found
	  end
	end
  end

function closestPowerOfTwo(n)
  if n < 2 then return nil end
  
  local power = 1
  while true do
	if 2^power > n then
	  return 2^(power-1)
	  end
	power = power + 1
	end
  end

function isInRect(xPos, yPos, xMin, yMin, xMax, yMax)
  return xPos >= xMin and xPos <= xMax and yPos >= yMin and yPos <= yMax
  end
  
function round(num, decimals)
  if not decimals or decimals == 0 then
	return math.floor(num+0.5)
	end
	
  local change = 10^decimals
  local val = math.floor((num*change+0.5))/change
  if decimals == 0 then
	val = math.floor(val)
	end
  return val
  end

function roundFloatingPoint(qn)
  return round(qn, 9)
  end

function gcd(a, b)
  while b ~= 0 do
	  a, b = b, a % b
	end
  return math.abs(a)
  end

-- Function to compute the least common multiple (LCM) of two numbers
function lcm(a, b)
  if not a or not b then
	debug_printStack()
	end
	
  return math.abs(a * b) // gcd(a, b) -- Use integer division
  end

function getExtremeValueInTableList(tables, minOrMax, subTableIndex)
  local result
  if minOrMax == "min" then
	result = math.huge  -- Start with a very large number
  elseif minOrMax == "max" then
	result = -math.huge
  else
	throwError("Bad minOrMax parameter")
	end
	
  for _, tbl in ipairs(tables) do
	if tbl[subTableIndex] then
	  if (minOrMax == "min" and tbl[subTableIndex] < result) or (minOrMax == "max" and tbl[subTableIndex] > result) then
		result = tbl[subTableIndex]
		end
	  end
	end
  
  return result
  end

-- Function to compute the LCM of a table of numbers
function lcmOfTable(denominators)
  if #denominators == 0 then
	return nil -- No LCM for an empty table
	end
  local result = denominators[1]
  for i = 2, #denominators do
	result = lcm(result, denominators[i])
	end
  return result
  end

function simplifyFraction(num, denom)
  if denom == 0 then
	throwError("Denominator cannot be zero")
	end
  -- Function to calculate GCD using the Euclidean algorithm
  local function gcd(a, b)
	if not a or not b then
	  debug_printStack()
	  end
	  
	while b ~= 0 do
	  a, b = b, a % b
	  end
	return math.abs(a) -- Ensure GCD is positive
	end

  -- Calculate GCD and simplify
  local divisor = gcd(num, denom)
  num = num // divisor -- Integer division
  denom = denom // divisor

  -- Ensure the denominator is positive
  if denom < 0 then
	num = -num
	denom = -denom
	end

  return round(num), round(denom)
  end

function convertRange(val, oldMin, oldMax, newMin, newMax)
  if not val then debug_printStack() end
  
  return ( (val - oldMin) / (oldMax - oldMin) ) * (newMax - newMin) + newMin
  end

function incrementValue(val, ticks, min, max)
  local direction = ticks/math.abs(ticks)
  for x=1, math.abs(ticks) do
	val = val + direction
	if val > max then
	  val = min
	elseif val < min then
	  val = max
	  end
	end
  return math.floor(val+0.5)
  end
  
function isInTable(t, data)
  if not data then return false end
  
  if not t then
	debug_printStack()
	end
	
  for x=1, #t do
	local testData = t[x]
	if type(testData) == "table" then
	  testData = t[x][1]
	  end
	if testData == data then
	  return x
	  end
	end
  return false
  end

function getTrackID(track)
  return reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER") - 1
  end
  
function separateString(str)
  local list = {}
  while true do
	local quotes = (string.sub(str, 1, 1) == "\"")
	local backticks = (string.sub(str, 1, 1) == "`")
	
	local i
	if quotes or backticks then
	  if quotes then
		i = string.find(str, "\" ", 2)
		end
	  if backticks then
		i = string.find(str, "` ", 2)
		end
	  if i then
		i = i + 1
		end
	else
	  i = string.find(str, " ")
	  end
	  
	local value
	if not i then
	  value = str
	else
	  value = string.sub(str, 1, i-1)
	  end
	  
	if quotes or backticks then
	  value = string.sub(value, 2, string.len(value)-1)
	elseif tonumber(value) then
	  value = tonumber(value)
	  end
	tableInsert(list, value)
	
	if not i then
	  return list
	  end
	
	str = string.sub(str, i+1, string.len(str))
	end
  end

function getLabel(line)
  local i = string.find(line, " ")
  if i == nil then
	return line
	end

  return string.sub(line, 1, i-1)
  end

function getValue(line, quotes)
  local i
  if string.sub(line, 1, 1) == "\"" then
	i = string.find(line, "\"", 2) + 1 --???
  else
	i = string.find(line, " ")
	end
  if i == nil then
	return nil
	end
  
  if quotes then
	local j = string.find(line, " \"")
	if j ~= nil then
	  return string.sub(line, j+1, string.len(line))
	  end
	end
  
  local val = string.sub(line, i+1, string.len(line))
	
  return val
  end

function getListsWithTextEvtIDs()
  local list = {}
  
  if articulationListBothVoices then --not defined yet if populating missing config override lanes (really dumb)
	tableInsert(list, {articulationListBothVoices[1], ARTICULATIONLISTINDEX_TEXTEVTID})
	tableInsert(list, {articulationListBothVoices[2], ARTICULATIONLISTINDEX_TEXTEVTID})
	tableInsert(list, {beamOverrideListBothVoices[1], BEAMOVERRIDELISTINDEX_TEXTEVTID})
	tableInsert(list, {beamOverrideListBothVoices[2], BEAMOVERRIDELISTINDEX_TEXTEVTID})
	tableInsert(list, {staffTextList, STAFFTEXTLISTINDEX_TEXTEVTID})
	tableInsert(list, {restOffsetListBothVoices[1], RESTOFFSETLISTINDEX_TEXTEVTID})
	tableInsert(list, {restOffsetListBothVoices[2], RESTOFFSETLISTINDEX_TEXTEVTID})
	end
	
  return list
  end

function getMatchingTextEvtID(take, targetPPQPOS, targetEvtType, targetMsg)
  local _, _, _, chartTextCount = reaper.MIDI_CountEvts(take)
  
  local originalTextEvtID = findAnyTextEventIDAtPPQPOS(take, targetPPQPOS)
  if not originalTextEvtID then
	return
	end
  
  reaper.ShowConsoleMsg("OG: " .. originalTextEvtID .. " " .. targetMsg .. "\n")
  local indexOffset = 0
  local doneWithLeftSide, doneWithRightSide
  local testCount = 0
  
  while true do
	local textEvtID = originalTextEvtID + indexOffset
	local retval, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(take, textEvtID)
	
	if indexOffset < 0 and (not retval or ppqpos < targetPPQPOS) then
	  doneWithLeftSide = true
	elseif (not retval or ppqpos > targetPPQPOS) then
	  doneWithRightSide = true
	else
	  if evtType == targetEvtType and msg == targetMsg then
		return textEvtID
		end
	  end
	
	if doneWithLeftSide and doneWithRightSide then
	  return
	  end
	
	if indexOffset >= 0 then
	  indexOffset = indexOffset * (-1) - 1
	else
	  indexOffset = indexOffset * (-1)
	  end
	
	testCount = testCount + 1
	if testCount == 100 then
	  throwError("getNotationTextEventID")
	  end
	end
  end
  
function insertTextSysexEvt(take, selected, muted, ppqpos, evtType, msg, relevantList, relevantListPPQPOSIndex, relevantListTextEvtIDIndex)
  debug_printStack()
  reaper.MIDI_InsertTextSysexEvt(take, selected, muted, ppqpos, evtType, msg)
  local textEvtID = getMatchingTextEvtID(take, ppqpos, evtType, msg)
  
  reaper.ShowConsoleMsg("INSERT TEXT EVT ID: " .. textEvtID .. " " .. msg .. "\n")
  
  local listsWithTextEvtIDs = getListsWithTextEvtIDs()
  for x=1, #listsWithTextEvtIDs do
	local data = listsWithTextEvtIDs[x]
	
	local list = data[1]
	local listIndex = data[2]
	
	for index=#list, 1, -1 do
	  if list[index][listIndex] >= textEvtID then
		list[index][listIndex] = list[index][listIndex] + 1
	  else
		break
		end
	  end
	end
  
  if relevantList then
	local relevantListIndex = findClosestIndexAtOrBelow(relevantList, ppqpos, relevantListPPQPOSIndex)
	if not relevantListIndex then
	  relevantListIndex = 0
	  end
	relevantListIndex = relevantListIndex + 1
	table.insert(relevantList, relevantListIndex, {})
	relevantList[relevantListIndex][relevantListPPQPOSIndex] = ppqpos
	relevantList[relevantListIndex][relevantListTextEvtIDIndex] = textEvtID
	
	for x=1, #relevantList do
	  local subList = relevantList[x]
	  reaper.ShowConsoleMsg("TEST: " .. subList[relevantListPPQPOSIndex] .. " " .. subList[relevantListTextEvtIDIndex] .. "\n")
	  end
	end
  
  setRefreshState(REFRESHSTATE_KEEPSELECTIONS)
  end

function setTextSysexEvt(take, textEvtID, selectedIn, mutedIn, ppqposIn, evtTypeIn, msg)
  reaper.ShowConsoleMsg("SET TEXT EVT ID: " .. textEvtID .. " " .. msg .. "\n")
  
  local _, _, _, prevTextEvtCount = reaper.MIDI_CountEvts(take)
  reaper.MIDI_SetTextSysexEvt(take, textEvtID, selectedIn, mutedIn, ppqposIn, evtTypeIn, msg)
  local _, _, _, laterTextEvtCount = reaper.MIDI_CountEvts(take)
  
  if laterTextEvtCount == round(prevTextEvtCount-1) then --if notation text event went away
	local listsWithTextEvtIDs = getListsWithTextEvtIDs()
	for x=1, #listsWithTextEvtIDs do
	  local data = listsWithTextEvtIDs[x]
	  
	  local list = data[1]
	  local listIndex = data[2]
	  
	  for index=#list, 1, -1 do
		if list[index][listIndex] > textEvtID then
		  list[index][listIndex] = list[index][listIndex] - 1
		else
		  break
		  end
		end
	  end
	end
	
  setRefreshState(REFRESHSTATE_KEEPSELECTIONS)
  end
  
function deleteTextSysexEvt(take, textEvtID, relevantList, relevantListTextEvtIDIndex)
  reaper.MIDI_DeleteTextSysexEvt(take, textEvtID)
  
  reaper.ShowConsoleMsg("DELETE TEXT EVT ID: " .. textEvtID .. "\n")
  
  if relevantList then
	local relevantListIndex = findClosestIndexAtOrBelow(relevantList, textEvtID, relevantListTextEvtIDIndex)
	table.remove(relevantList, relevantListIndex)
	end
	
  local listsWithTextEvtIDs = getListsWithTextEvtIDs()
  for x=1, #listsWithTextEvtIDs do
	local data = listsWithTextEvtIDs[x]
	
	local list = data[1]
	local listIndex = data[2]
	
	for index=#list, 1, -1 do
	  if list[index][listIndex] > textEvtID then
		list[index][listIndex] = list[index][listIndex] - 1
	  else
		break
		end
	  end
	end
  
  setRefreshState(REFRESHSTATE_KEEPSELECTIONS)
  end
  
function getFileExtension(filePath)
  local dotIndex = string.find(filePath, "%.")
  if not dotIndex then return end
  return string.sub(filePath, dotIndex+1, string.len(filePath))
  end

function getSongsDirectory()
  local dir = getScriptDirectory() .. "songs/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getGodotDirectory()
  local dir = "C:/Users/jarod/Documents/GitHub/DrumPerformer/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getGodotUserDirectory()
  local dir = "C:/Users/jarod/AppData/Roaming/Godot/app_userdata/Drum Performer/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end
  
function getGemsDirectory()
  local dir = getAssetsDirectory() .. "gems/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getNotationsDirectory()
  local dir = getAssetsDirectory() .. "notations/selected/"
  reaper.RecursiveCreateDirectory(dir, 0)
  return dir
  end

function getTemposTextFilePath()
  return getGodotUserDirectory() .. "tempos.txt"
  end

function getConfigTextFilePath()
  return getGodotUserDirectory() .. "config.txt"
  end
  
function getEventsTextFilePath()
  return getGodotUserDirectory() .. "events.txt"
  end
  
function getMIDIDataTextFilePath()
  return getGodotUserDirectory() .. "midi.txt"
  end

function getNoteMapTextFilePath()
  return getGodotDirectory() .. "note_map.txt"
  end

function getChunksTextFilePath()
  return getGodotDirectory() .. "chunks/chunks.txt"
  end
  
function fileExists(filePath)
  local file = io.open(filePath, "r")
  if file then
	file:close()
	return true
	end
  return false
  end

function defineImage(dir, fileName, label)
  local filePath = dir .. fileName  .. ".png"
  if fileExists(filePath) then
	local img = reaper.ImGui_CreateImage(filePath)
	tableInsert(masterImageList, {label, img})
	reaper.ImGui_Attach(ctx, img)
	return true
	end
  return false
  end

function getImageSize(imgFileName)
  for i, v in ipairs(imgSizeList) do
	if v[1] == imgFileName then
	  return v[2], v[3]
	  end
	end
  end
  
function updateImageDimensions()
  local list = {}
  
  for _, v in ipairs(masterImageList) do
	local imgFileName = v[1]
	local img = getImageFromList(imgFileName)
	local imgSizeX, imgSizeY = reaper.ImGui_Image_GetSize(img)
	tableInsert(list, imgFileName .. " " .. imgSizeX .. " " .. imgSizeY)
	end
  
  local file = io.open(getAssetsDirectory() .. "sizes.txt", "w+")
  file:write(table.concat(list, "\n"))
  file:close()
  end
  
function getImageFromList(fileName)
  for _, v in ipairs(masterImageList) do
	if v[1] == fileName then
	  return table.unpack(v, 2)
	  end
	end
  end

function getAlbumArtImage()
  local dir = reaper.GetProjectPath() .. "\\"
  local fileName = "album"
  local img = getImageFromList(fileName)
  if not img then
	defineImage(dir, fileName, fileName)
	img = getImageFromList(fileName)
	end
  return img
  end

function getHiHatFootImage()
  local dir = getOtherDirectory()
  local fileName = "hihatfoot"
  local img = getImageFromList(fileName)
  if not img then
	defineImage(dir, fileName, fileName)
	img = getImageFromList(fileName)
	end
  return img
  end

function getTremoloImage()
  local dir = getOtherDirectory()
  local fileName = "tremolo"
  local img = getImageFromList(fileName)
  if not img then
	defineImage(dir, fileName, fileName)
	img = getImageFromList(fileName)
	end
  return img
  end

function getBuzzImage()
  local dir = getOtherDirectory()
  local fileName = "buzz"
  local img = getImageFromList(fileName)
  if not img then
	defineImage(dir, fileName, fileName)
	img = getImageFromList(fileName)
	end
  return img
  end

function getMusescoreImage()
  local dir = getOtherDirectory()
  local fileName = "musescore"
  local img = getImageFromList(fileName)
  if not img then
	defineImage(dir, fileName, fileName)
	img = getImageFromList(fileName)
	end
  return img
  end
  
function initializeImages()
  storeImageListsIntoMemory()
  
  masterImageList = {}
  for x=1, #gemImageList do
	local gemLabel = gemImageList[x]
	local dir = getGemsDirectory() .. gemLabel .. "/"
	defineImage(dir, "base", gemLabel .. "_base")
	defineImage(dir, "tint", gemLabel .. "_tint")
	defineImage(dir, "ring", gemLabel .. "_ring")
	local lightingFrameID = 0
	while defineImage(dir, "lighting" .. padToFourDigits(lightingFrameID), gemLabel .. "_lighting" .. padToFourDigits(lightingFrameID)) do
	  lightingFrameID = lightingFrameID + 1
	  end
	end
  for x=1, #notationImageList do
	local notationLabel = notationImageList[x]
	defineImage(getNotationsDirectory(), notationLabel, notationLabel)
	end
  
  getMusescoreImage() --puts it into list
  
  updateImageDimensions()
  end

function defineFonts()
  ctx = reaper.ImGui_CreateContext("Drum Visualizer")
  drawList = reaper.ImGui_GetWindowDrawList(ctx)
  local fontName = "Verdana"
  defaultFont = reaper.ImGui_CreateFont(fontName, 15)
  sectionFont = reaper.ImGui_CreateFont(fontName, 25, reaper.ImGui_FontFlags_Bold())
  weakBeatFont = reaper.ImGui_CreateFont(fontName, 20, reaper.ImGui_FontFlags_Bold())
  strongBeatFont = reaper.ImGui_CreateFont(fontName, 40, reaper.ImGui_FontFlags_Bold())
  measureNumberFont = reaper.ImGui_CreateFont(fontName, 14)
  velocityFont = reaper.ImGui_CreateFont(fontName, 25, reaper.ImGui_FontFlags_Bold())
  staffTextFont = reaper.ImGui_CreateFont(fontName, 20, reaper.ImGui_FontFlags_Italic())
  errorFont = reaper.ImGui_CreateFont(fontName, 30, reaper.ImGui_FontFlags_Bold())
  errorDirFont = reaper.ImGui_CreateFont(fontName, 20, reaper.ImGui_FontFlags_Bold())
  reaper.ImGui_Attach(ctx, defaultFont)
  reaper.ImGui_Attach(ctx, sectionFont)
  reaper.ImGui_Attach(ctx, weakBeatFont)
  reaper.ImGui_Attach(ctx, strongBeatFont)
  reaper.ImGui_Attach(ctx, measureNumberFont)
  reaper.ImGui_Attach(ctx, velocityFont)
  reaper.ImGui_Attach(ctx, staffTextFont)
  reaper.ImGui_Attach(ctx, errorFont)
  reaper.ImGui_Attach(ctx, errorDirFont)
  end
defineFonts()

function getGodotProjectDirectory()
  return "C:/Users/jarod/Documents/GitHub/DrumPerformer/test_song/"
  end
  
function getGameDataDirectory()
  return getScriptDirectory()
  end

function getValueFromKey(line, key)
  line = trimTrailingSpaces(line)
  local values = separateString(line)
  for x=1, #values do
	local testKey, value = getKeyAndValue(values[x])
	if testKey == key then
	  if tonumber(value) then
		value = tonumber(value)
		end
	  return value
	  end
	end
  end

function isSong()
  return CHART_TYPE == 0
  end

function isJamTrack()
  return CHART_TYPE == 1
  end

function isLesson()
  return CHART_TYPE == 2
  end
  
function getKeyAndValue(str)
  local equalsIndex = string.find(str, "=")
  local spaceIndex = string.find(str, " ")
  if spaceIndex or not equalsIndex then
	throwError("Bad line in getKey()! " .. str)
	end
  local key = string.sub(str, 1, equalsIndex-1)
  local value = string.sub(str, equalsIndex+1, #str)
  return key, value
  end
  
function runChartCompiler(reaperProcessingCurrentMeasureIndex)
  local drumKitName = getSettingFromFile("drumkit")
  local file = io.open(getDrumKitsDirectory() .. drumKitName .. ".txt", "r")
  local drumkitFileText = file:read("*all")
  file:close()
  
  local gemNameTable = {}
  local gemConfigTextTable = {}
  for x=1, #gemImageList do
	local gemFolderName = gemImageList[x]
	local configFilePath = getGemsDirectory() .. gemFolderName .. "/config.txt"
	local file = io.open(configFilePath, "r")
	local fileText = file:read("*all")
	file:close()
	
	tableInsert(gemNameTable, gemFolderName)
	tableInsert(gemConfigTextTable, fileText)
	end
  
  dofile(getGodotDirectory() .. "godot_reaper_environment.lua")
  local outputTextFilePath = getGodotUserDirectory() .. "output.txt"
  
  local file = io.open(getAssetsDirectory() .. "sizes.txt", "r")
  local imgSizesFileText = file:read("*all")
  file:close()
  
  local file = io.open(getTemposTextFilePath(), "r")
  local temposFileText = file:read("*all")
  file:close()
  
  local file = io.open(getConfigTextFilePath(), "r")
  local configFileText = file:read("*all")
  file:close()
  
  local file = io.open(getEventsTextFilePath(), "r")
  local eventsFileText = file:read("*all")
  file:close()
  
  local file = io.open(getNoteMapTextFilePath(), "r")
  local noteMapFileText = file:read("*all")
  file:close()
  
  local file = io.open(getChunksTextFilePath(), "r")
  local chunksFileText = file:read("*all")
  file:close()
  
  local songDataFilePath = getGodotUserDirectory() .. "songdata.txt"
  local midiTextFilePath = getMIDIDataTextFilePath()
  
  local fileText = runGodotReaperEnvironment(
	true, 
	reaperProcessingCurrentMeasureIndex, 
	masterImageList,
	CHART_TYPE,
	noteMapFileText,
	chunksFileText,
	drumkitFileText, 
	gemNameTable, 
	gemConfigTextTable, 
	songDataFilePath,
	outputTextFilePath, 
	imgSizesFileText, 
	temposFileText,
	configFileText,
	eventsFileText, 
	midiTextFilePath,
	notesTake,
	notesTrack,
	notesTrackID,
	eventsTake,
	eventsTrack,
	eventsTrackID
	)
  
  if reaperProcessingCurrentMeasureIndex then
	return
	end
	
  local NUM_CONSTANTS = 1
  local NUM_ARRAYS = 19
  local num_lanes
  
  local time_list = {}
  local velocity_list = {}
  local position_list = {}
  local gem_list = {}
  local color_r_list = {}
  local color_g_list = {}
  local color_b_list = {}
  local color_a_list = {}
  local notation_color_r_list = {}
  local notation_color_g_list = {}
  local notation_color_b_list = {}
  local shift_x_list = {}
  local shift_y_list = {}
  local scale_list = {}
  local z_index_list = {}
  local pad_index_list = {}
  local sustain_line_list = {}
  local pedal_list = {}
  local midi_id_list = {}
  
  local line_id = 0
  for line in fileText:gmatch("[^\r\n]+") do
	if tonumber(line) then
	  line = tonumber(line)
	  end
	  
	if line_id == 0 then
	  num_lanes = line
	--ATTENTION: if adding new constant, update NUM_CONSTANTS!
	
	else
	  local array_id = (line_id - NUM_CONSTANTS) % NUM_ARRAYS
	  local arr
	  
	  if array_id == 0 then arr = time_list end
	  if array_id == 1 then arr = velocity_list end
	  if array_id == 2 then arr = position_list end
	  if array_id == 3 then arr = gem_list end
	  if array_id == 4 then arr = color_r_list end
	  if array_id == 5 then arr = color_g_list end
	  if array_id == 6 then arr = color_b_list end
	  if array_id == 7 then arr = color_a_list end
	  if array_id == 8 then arr = notation_color_r_list end
	  if array_id == 9 then arr = notation_color_g_list end
	  if array_id == 10 then arr = notation_color_b_list end
	  if array_id == 11 then arr = shift_x_list end
	  if array_id == 12 then arr = shift_y_list end
	  if array_id == 13 then arr = scale_list end
	  if array_id == 14 then arr = z_index_list end
	  if array_id == 15 then arr = pad_index_list end
	  if array_id == 16 then arr = sustain_line_list end
	  if array_id == 17 then arr = pedal_list end
	  if array_id == 18 then arr = midi_id_list end
	  --ATTENTION: if adding new array, update NUM_ARRAYS!
		
	  tableInsert(arr, line)
	  end
	  
	line_id = line_id + 1
	end
	
  NUM_CHART_LANES = num_lanes
  
  chartNoteList = {}
  chartSustainList = {}
  chartHiHatPedalList = {}
  for x=1, #time_list do
	local data = {}
	
	data[CHARTNOTELISTINDEX_TIME] = time_list[x]
	data[CHARTNOTELISTINDEX_VELOCITY] = velocity_list[x]
	data[CHARTNOTELISTINDEX_POSITION] = position_list[x]
	data[CHARTNOTELISTINDEX_GEM] = gem_list[x]
	data[CHARTNOTELISTINDEX_COLOR_R] = color_r_list[x]
	data[CHARTNOTELISTINDEX_COLOR_G] = color_g_list[x]
	data[CHARTNOTELISTINDEX_COLOR_B] = color_b_list[x]
	data[CHARTNOTELISTINDEX_COLOR_A] = color_a_list[x]
	data[CHARTNOTELISTINDEX_SHIFTX] = shift_x_list[x]
	data[CHARTNOTELISTINDEX_SHIFTY] = shift_y_list[x]
	data[CHARTNOTELISTINDEX_SCALE] = scale_list[x]
	data[CHARTNOTELISTINDEX_ZINDEX] = z_index_list[x]
	
	local sustainLine = sustain_line_list[x]
	if sustainLine ~= -1 then
	  local sustainRollType = getValueFromKey(sustainLine, "type")
	  local sustainPosition = data[CHARTNOTELISTINDEX_POSITION]
	  local sustainColor = hexColor(data[CHARTNOTELISTINDEX_COLOR_R], data[CHARTNOTELISTINDEX_COLOR_G], data[CHARTNOTELISTINDEX_COLOR_B])
	  local sustainShiftX = data[CHARTNOTELISTINDEX_SHIFTX]
	  local sustainShiftY = data[CHARTNOTELISTINDEX_SHIFTY]
	  local sustainScale = data[CHARTNOTELISTINDEX_SCALE]
	  local sustainValues = {}
	  local lineValues = separateString(sustainLine)
	  for x=4, #lineValues, 3 do
		local sustainTime = lineValues[x]
		local sustainVal = lineValues[x+1]
		local sustainGradient = (lineValues[x+2] == 1)
		tableInsert(sustainValues, {sustainTime, sustainVal, sustainGradient})
		end
	  local sustainStartTime = sustainValues[1][1]
	  local sustainEndTime = sustainValues[#sustainValues][1]
	  
	  tableInsert(chartSustainList, {sustainStartTime, sustainEndTime, sustainRollType, sustainPosition, sustainColor, sustainShiftX, sustainShiftY, sustainScale, sustainValues})
	  end
	
	local pedalCC = pedal_list[x]
	if pedalCC ~= -1 then
	 
	  end
	
	--data[CHARTNOTELISTINDEX_MIDIID] = midi_id_list[x]
	
	tableInsert(chartNoteList, data)
	end
  end
  
function pushCollapsingHeaderColor(ctx)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Header(), COLOR_COLLAPSINGHEADER)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderHovered(), COLOR_COLLAPSINGHEADER_HOVERED)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_HeaderActive(), COLOR_COLLAPSINGHEADER_ACTIVE)
  end

function popCollapsingHeaderColor(ctx)
  reaper.ImGui_PopStyleColor(ctx, 3)
  end

function collapsingHeader(label)
  pushCollapsingHeaderColor(ctx)
  local retval = reaper.ImGui_CollapsingHeader(ctx, label)
  popCollapsingHeaderColor(ctx)
  
  if retval then
	
	end
  
  return retval
  end

function getNotationItemData(identifier, header)
  local values = separateString(identifier)
  header = header .. "_"
  local lenHeader = #header
  for x=1, #values do
	local value = values[x]
	if string.sub(value, 1, lenHeader) == header then
	  local result = string.sub(value, lenHeader+1, #value)
	  if tonumber(result) then
		result = tonumber(result)
		end
	  return result
	  end
	end
  end
  
function notationPosToStaffLine(notationPos)
  local staffLine = math.floor(notationPos)
  return staffLine, staffLine ~= notationPos
  end

function findIndexInListEqualOrGreaterThan(list, target, subTableIndex)
  local low = 1
  local high = #list
  local result = nil -- To store the index of the first value >= target

  while low <= high do
	local mid = math.floor((low + high) / 2)
	local midValue -- First value in the subtable
	if subTableIndex then
	  midValue = list[mid][subTableIndex]
	else
	  midValue = list[mid]
	  end
	  
	if midValue >= target then
	  result = mid -- Potential candidate
	  high = mid - 1 -- Continue searching the left half
	else
	  low = mid + 1 -- Search the right half
	  end
	end

  return result -- Returns nil if no such value exists
  end
  
function findIndexInListEqualOrLessThan(list, target, subTableIndex)
  if not list then
	debug_printStack()
	end
	
  local low = 1
  local high = #list
  local result = nil -- To store the index of the first value >= target

  while low <= high do
	local mid = math.floor((low + high) / 2)
	local midValue
	if subTableIndex then
	  midValue = list[mid][subTableIndex] -- First value in the subtable
	else
	  midValue = list[mid] -- First value in the subtable
	  end
	
	if midValue == nil or target == nil then
	  debug_printStack()
	  end
	if midValue <= target then
	  result = mid -- Potential candidate
	  low = mid + 1
	else
	  high = mid - 1
	  end
	end

  return result -- Returns nil if no such value exists
  end

function isGradualDynamic(dynamic)
  return (string.sub(dynamic, 1, 5) == "cresc" or string.sub(dynamic, 1, 3) == "dim" or string.sub(dynamic, 1, 7) == "decresc")
  end

function getTupletFactorNumDenom(tupletModifier)
  if not tupletModifier then return 1, 1 end
  
  if tupletModifier == "t" then return 2, 3 end
  if tupletModifier == "q" then return 4, 5 end
  if tupletModifier == "s" then return 4, 7 end
  
  throwError("Not a valid tuplet modifier!")
  end

function findAnyTextEventIDAtPPQPOS(take, targetPPQPOS)
  local _, _, _, chartTextCount = reaper.MIDI_CountEvts(take)
  
  local low, high = 0, chartTextCount - 1

  while low <= high do
	local mid = math.floor((low + high) / 2)
	local _, _, _, ppqpos = reaper.MIDI_GetTextSysexEvt(take, mid)

	if ppqpos == targetPPQPOS then
	  return mid  -- Found an event at the target PPQ position
	elseif ppqpos < targetPPQPOS then
	  low = mid + 1  -- Search right
	else
	  high = mid - 1  -- Search left
	  end
	end
  end
  
function getNotationTextEventID(noteStartPPQPOS, noteChannel, noteMIDINoteNum)
  local _, _, _, chartTextCount = reaper.MIDI_CountEvts(notesTake)
  
  local originalTextEvtID = findAnyTextEventIDAtPPQPOS(notesTake, noteStartPPQPOS)
  if not originalTextEvtID then
	return
	end
  
  local indexOffset = 0
  local doneWithLeftSide, doneWithRightSide
  local testCount = 0

  while true do
	local textEvtID = originalTextEvtID + indexOffset
	local retval, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(notesTake, textEvtID)
	
	if indexOffset < 0 and (not retval or ppqpos < noteStartPPQPOS) then
	  doneWithLeftSide = true
	elseif (not retval or ppqpos > noteStartPPQPOS) then
	  doneWithRightSide = true
	else
	  local data = separateString(msg)
	  local header = data[1]
	  local channel = data[2]
	  local midiNoteNum = data[3]
	  
	  if evtType == NOTATION_EVENT and header == "NOTE" and channel == noteChannel and midiNoteNum == noteMIDINoteNum then
		return textEvtID
		end
	  end
	
	if doneWithLeftSide and doneWithRightSide then
	  return
	  end
	
	if indexOffset >= 0 then
	  indexOffset = indexOffset * (-1) - 1
	else
	  indexOffset = indexOffset * (-1)
	  end
	
	testCount = testCount + 1
	if testCount == 100 then
	  throwError("getNotationTextEventID")
	  end
	end
  end

function getNumBeams(beamValue)
  return round(math.log(beamValue)/math.log(2) - 2)
  end

function cleanSpacesFromStr(str)
  while string.sub(str, 1, 1) == " " do
	str = string.sub(str, 2, #str)
	end
  while string.sub(str, #str, #str) == " " do
	str = string.sub(str, 1, #str-1)
	end
  return str
  end
  
function cleanPunctuationFromStr(str)
  local firstChar = string.sub(str, 1, 1)
  if not tonumber(firstChar) then
	str = string.sub(str, 2, #str)
	end
  local lastChar = string.sub(str, #str, #str)
  if not tonumber(lastChar) then
	str = string.sub(str, 1, #str-1)
	end
  return str
  end

function getNoteProperty(midiNoteNum, property)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return end
  
  local notePropertyTable = noteTable[19]
  local index = isInTable(notePropertyTable, property)
  if index then
	return notePropertyTable[index][2]
	end
  end

function setTextEventParameter(take, textEvtID, header, val)
  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(take, textEvtID)
  
  if evtType == TEXT_EVENT then
	local newMsg
	
	local headerIndex, underscoreIndex = string.find(msg, header .. "_")
	if headerIndex then
	  if val then
		newMsg = string.sub(msg, 1, underscoreIndex) .. val
	  else
		newMsg = string.sub(msg, 1, headerIndex-2)
		end
	  local spaceIndex = string.find(msg, " ", underscoreIndex)
	  if spaceIndex then
		newMsg = newMsg .. string.sub(msg, spaceIndex, #msg)
		end
	else
	  if val then
		newMsg = msg .. " " .. header .. "_" .. val
	  else
		newMsg = msg
		end
	  end
	  
	setTextSysexEvt(take, textEvtID, nil, nil, nil, evtType, newMsg)
	end
  end
  
function setNotationTextEventParameter(noteStartPPQPOS, noteChannel, noteMIDINoteNum, headerWithUnderscore, val, prevVal)
  local valToInsert
  if headerWithUnderscore then
	valToInsert = headerWithUnderscore .. "_" .. val
  else
	valToInsert = val
	end
  
  local textEvtID = getNotationTextEventID(noteStartPPQPOS, noteChannel, noteMIDINoteNum)
  if textEvtID then
	local newMsg
	
	local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(notesTake, textEvtID)
	
	local textHeaderIndexStart = string.find(msg, "text ")
	if textHeaderIndexStart then
	  local textStrStart = textHeaderIndexStart + 5
	  local textStrEnd
	  if string.sub(msg, textStrStart, textStrStart) == "\"" then
		textStrStart = textStrStart + 1
		textStrEnd = string.find(msg, "\"", textStrStart)
	  else
		textStrEnd = string.find(msg, " ", textStrStart)
		end
	  if not textStrEnd then
		textStrEnd = #msg
		end
	  textStrEndWithQuotes = textStrEnd
	  if string.sub(msg, textStrEnd, textStrEnd) == "\"" then
		textStrEnd = textStrEnd - 1
		end
	  
	  local currentTextStr = cleanSpacesFromStr(string.sub(msg, textStrStart, textStrEnd))
	  local textValues = separateString(currentTextStr)
	  
	  local index
	  if headerWithUnderscore then
		for x=1, #textValues do
		  if string.sub(textValues[x], 1, #headerWithUnderscore+1) == headerWithUnderscore .. "_" then
			index = x
			break
			end
		  end
	  else
		index = isInTable(textValues, prevVal)
		end
	  if index then
		if valToInsert then
		  textValues[index] = valToInsert
		else
		  table.remove(textValues, index)
		  end
	  elseif valToInsert and not isInTable(textValues, valToInsert) then
		tableInsert(textValues, valToInsert)
		end
		
	  local textValueStr = table.concat(textValues, " ")
	  if #textValueStr > 0 then
		textValueStr = "text \"" .. textValueStr .. "\""
		end
		
	  newMsg = string.sub(msg, 1, textHeaderIndexStart-1) .. textValueStr .. string.sub(msg, textStrEndWithQuotes+1, #msg)
	else
	  if valToInsert then
		newMsg = msg .. " text " .. valToInsert
		end
	  end
	
	if newMsg then
	  setTextSysexEvt(notesTake, textEvtID, nil, nil, nil, evtType, newMsg)
	  end
  else
	if valToInsert then
	  local msg = "NOTE " .. noteChannel .. " " .. noteMIDINoteNum .. " text " .. valToInsert
	  insertTextSysexEvt(notesTake, false, false, noteStartPPQPOS, NOTATION_EVENT, msg)
	  end
	end
  end

function isNoteDefaultGhost(noteData)
  local noteStartQN = noteData[NOTELISTINDEX_STARTQN]
  local velocity = noteData[NOTELISTINDEX_VELOCITY]
  
  local index = findIndexInListEqualOrLessThan(ghostThresholdTextEvtList, noteStartQN, 1)
  local ghostThresh = ghostThresholdTextEvtList[index][2]
  return (velocity <= ghostThresh)
  end
  
function isNoteGhost(noteData)
  local isGhost = noteData[NOTELISTINDEX_GHOST]
  if isGhost == nil then
	isGhost = isNoteDefaultGhost(noteData)
	end
  
  return isGhost
  end

function isChordDefaultAccent(chord)
  local chordGlobalData = chord[1]
  local chordNotes = chord[2]

  local chordQN = chordGlobalData[CHORDGLOBALDATAINDEX_QN]
  local chordArticulationList = chordGlobalData[CHORDGLOBALDATAINDEX_ARTICULATIONLIST]
	
  for chordNoteIndex=1, #chordNotes do
	local noteData = chordNotes[chordNoteIndex]
	
	local velocity = noteData[NOTELISTINDEX_VELOCITY]
	
	local index = findIndexInListEqualOrLessThan(accentThresholdTextEvtList, chordQN, 1)
	local accentThresh = accentThresholdTextEvtList[index][2]
	if accentThresh >= 0 and velocity >= accentThresh then
	  return true
	  end
	end
  
  return false
  end

function anyMainWindowVisible()
  return windowVisibility_CONFIG == 1 or windowVisibility_CHART == 1 or windowVisibility_NOTATION == 1
  end
  
function setNoteGhost(noteData, enable)
  local valStr, prevValStr
  if enable then
	prevValStr = "noghost"
	if isNoteDefaultGhost(noteData) == false then
	  valStr = "ghost"
	  end
  else
	prevValStr = "ghost"
	if isNoteDefaultGhost(noteData) then
	  valStr = "noghost"
	  end
	end
  
  local startPPQPOS = noteData[NOTELISTINDEX_STARTPPQPOS]
  local channel = noteData[NOTELISTINDEX_CHANNEL]
  local midiNoteNum = noteData[NOTELISTINDEX_MIDINOTENUM]
  setNotationTextEventParameter(startPPQPOS, channel, midiNoteNum, nil, valStr, prevValStr)
  end

function getChordVoiceIndex(chord)
  local chordGlobalData = chord[1]
  return chordGlobalData[CHORDGLOBALDATAINDEX_VOICEINDEX]
  end

function getSustainMIDINoteNum(voiceIndex)
  for midiNoteNum=0, 127 do
	if getNoteName(midiNoteNum) == "sustain" .. voiceIndex then
	  return midiNoteNum
	  end
	end
  end

function doesChordHaveArticulation(chord, articulationName)
  local chordGlobalData = chord[1]
  local chordArticulationList = chordGlobalData[CHORDGLOBALDATAINDEX_ARTICULATIONLIST]
  
  if isInTable(chordArticulationList, articulationName) then
	return true
	end
  
  if string.sub(articulationName, 1, 8) == "sticking" then
	return isInTable(chordArticulationList, "stickingLR")
	end
  end

function setArticulation(chord, articulationName, enable)
  local valStr, prevValStr
  if enable then
	prevValStr = "no" .. articulationName
	if articulationName == "accent" then
	  if isChordDefaultAccent(chord) == false then
		valStr = "accent"
		end
	else
	  valStr = articulationName
	  end
  else
	prevValStr = articulationName
	if articulationName == "accent" and isChordDefaultAccent(chord) then
	  valStr = "no" .. articulationName
	  end
	end
  
  local chordGlobalData = chord[1]
  local chordPPQPOS = chordGlobalData[CHORDGLOBALDATAINDEX_PPQPOS]
  local voiceIndex = chordGlobalData[CHORDGLOBALDATAINDEX_VOICEINDEX]
  
  local articulationList = articulationListBothVoices[voiceIndex]
  local articulationListIndex = findClosestIndexAtOrBelow(articulationList, chordPPQPOS, ARTICULATIONLISTINDEX_PPQPOS)
  
  local articulationTextEvtID
  if articulationListIndex then
	local articulationPPQPOS = articulationList[articulationListIndex][ARTICULATIONLISTINDEX_PPQPOS]
	if articulationPPQPOS == chordPPQPOS then
	  articulationTextEvtID = articulationList[articulationListIndex][ARTICULATIONLISTINDEX_TEXTEVTID]
	  end
	end
  if articulationTextEvtID then
	local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(notesTake, articulationTextEvtID)
	local values = separateString(msg)
	local alreadyExists
	for x=#values, 1, -1 do
	  if values[x] == prevValStr then
		table.remove(values, x)
	  elseif values[x] == valStr then
		alreadyExists = true
		end
	  end
	if valStr and not alreadyExists then
	  tableInsert(values, valStr)
	  end
	if #values == 1 then
	  deleteTextSysexEvt(notesTake, articulationTextEvtID, articulationList, ARTICULATIONLISTINDEX_TEXTEVTID)
	else
	  setTextSysexEvt(notesTake, articulationTextEvtID, nil, nil, nil, evtType, table.concat(values, " "))
	  end
  else
	if valStr then
	  insertTextSysexEvt(notesTake, false, false, chordPPQPOS, TEXT_EVENT, "articulation_" .. voiceIndex .. " " .. valStr, articulationList, ARTICULATIONLISTINDEX_PPQPOS, ARTICULATIONLISTINDEX_TEXTEVTID)
	  end
	end
  end

function setBeam(chord, beamState)
  local chordGlobalData = chord[1]
  local chordPPQPOS = chordGlobalData[CHORDGLOBALDATAINDEX_PPQPOS]
  local voiceIndex = chordGlobalData[CHORDGLOBALDATAINDEX_VOICEINDEX]
  
  local beamOverrideList = beamOverrideListBothVoices[voiceIndex]
  local beamOverrideListIndex = findClosestIndexAtOrBelow(beamOverrideList, chordPPQPOS, BEAMOVERRIDELISTINDEX_PPQPOS)
  
  local beamOverrideTextEvtID
  if beamOverrideListIndex then
	local beamOverridePPQPOS = beamOverrideList[beamOverrideListIndex][BEAMOVERRIDELISTINDEX_PPQPOS]
	if beamOverridePPQPOS == chordPPQPOS then
	  beamOverrideTextEvtID = beamOverrideList[beamOverrideListIndex][BEAMOVERRIDELISTINDEX_TEXTEVTID]
	  end
	end
  
  if beamState then
	local valStr = "beam_" .. voiceIndex .. " " .. beamState
	if beamOverrideTextEvtID then
	  setTextSysexEvt(notesTake, beamOverrideTextEvtID, nil, nil, nil, TEXT_EVENT, valStr)
	else
	  insertTextSysexEvt(notesTake, false, false, chordPPQPOS, TEXT_EVENT, valStr, beamOverrideList, BEAMOVERRIDELISTINDEX_PPQPOS, BEAMOVERRIDELISTINDEX_TEXTEVTID)
	  end
  elseif beamOverrideTextEvtID then
	deleteTextSysexEvt(notesTake, beamOverrideTextEvtID, beamOverrideList, BEAMOVERRIDELISTINDEX_TEXTEVTID)
	end
  end

function getVelocitySizePercentage(velocity)
  return convertRange(velocity, 0, 127, 0.5, 1) 
  end
  
function setRefreshState(refreshState)
  if CURRENT_ERRORCODE_CHECKPOINT then return end
  
  currentRefreshState = refreshState
  end

function checkError(errorCode)
  if ERRORCODE and errorCode >= ERRORCODE then
	if CURRENT_ERRORCODE_CHECKPOINT and ERRORCODE < CURRENT_ERRORCODE_CHECKPOINT then
	  throwError("Bad error code checking! " .. ERRORCODE .. " < " .. CURRENT_ERRORCODE_CHECKPOINT)
	  end
	CURRENT_ERRORCODE_CHECKPOINT = ERRORCODE
	return true
	end
  end
	
function setError(errorCode, errorMsg)
  ERRORCODE = errorCode
  ERRORMSG = errorMsg
  currentRefreshState = REFRESHSTATE_NOTREFRESHING
  end
  
function displayError()
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), COLOR_ERROR)
  reaper.ImGui_PushFont(ctx, errorFont)
  
  local err = ERRORMSG
  local lineNumberStr
  local endOfDirIndex = string.find(err, ": ")
  if endOfDirIndex then
	local _, luaExtIndex = string.find(err, ".lua:")
	if luaExtIndex then
	  lineNumberStr = "(Line #" .. string.sub(err, luaExtIndex+1, endOfDirIndex-1) .. ")"
	  end
	err = string.sub(err, endOfDirIndex+2, #ERRORMSG)
	end
  err = "ERROR: " .. err
  
  reaper.ImGui_TextWrapped(ctx, err)
  
  reaper.ImGui_Dummy(ctx, 0, 20)
  if button(COLOR_ERROR, COLOR_ERROR_HOVERED, COLOR_ERROR_ACTIVE, "Refresh##ERRORREFRESH", nil) then
	currentRefreshState = REFRESHSTATE_COMPLETE
	end
  reaper.ImGui_Dummy(ctx, 0, 20)
  
  reaper.ImGui_PopFont(ctx)
  
  if lineNumberStr then
	reaper.ImGui_PushFont(ctx, errorDirFont)
	reaper.ImGui_TextWrapped(ctx, lineNumberStr)
	reaper.ImGui_PopFont(ctx)
	end
	
  reaper.ImGui_PopStyleColor(ctx, 1)
  end
  
function drawChart(chartSizeX, chartSizeY, hitboxPercentage, chartBGColor_R, chartBGColor_G, chartBGColor_B, laneColor, alpha, hasBeatLines, drawKick, drawNormal, drawCymbals)
  if checkError(ERROR_MIDIINTOMEMORY) then return end
  if not tonumber(NUM_CHART_LANES) then return end
  
  local TRACKSPEED = getSettingFromFile("trackspeed", 1.5)
  local MAXANGLEDEGREES = getSettingFromFile("trackangle", 15)
  local VISIBLE_TIMERANGE = TRACKSPEED * 3
  local SHOWLANES = getSettingFromFile("showlanes", 0)
  
  local visibleTimeMin = getCursorPosition()
  local visibleTimeMax = visibleTimeMin + VISIBLE_TIMERANGE
  
  local sectionXMax = chartWindowX + chartWindowSizeX - 20
  local sectionXMin = sectionXMax - 300
  
  local chartXMin = chartWindowX + 10
  local chartYMin = chartWindowY + 50
  local chartXMax = chartXMin + chartSizeX
  local CHART_CENTERX = (chartXMin + chartXMin + chartXMax) / 2
  local chartYMax = chartYMin + chartSizeY
  local chartXMin2, chartXMax2
  
  local x1_first, y1_first, x2_first, y2_first, x1_last, y1_last, x2_last, y2_last
  local horizonX, horizonY
  
  local sectionYMin = chartYMin
  local sectionYMax = chartYMin + 300
  local sectionSizeX = sectionXMax - sectionXMin
  local sectionSizeY = sectionYMax - sectionYMin
  
  local CHART_BOUNDARYTHICKNESS = 2
  local CHART_TESTFRAMECOLOR = COLOR_WHITE
	
  local CHART_BACKGROUNDCOLOR = hexColor(chartBGColor_R, chartBGColor_G, chartBGColor_B, alpha) 
  local CHART_BACKGROUNDCOLOR_T = hexColor(chartBGColor_R, chartBGColor_G, chartBGColor_B, 0)
  local alphaBackgroundColor = hexColor(0, 0, 0, 255)
  local alphaAlbumArtPercentage = 0.85 --0.85
  
  local lanePositionList = {}
  
  local mouseX, mouseY = reaper.ImGui_GetMousePos(ctx)
  local isLeftMouseClicked = reaper.ImGui_IsMouseClicked(ctx, 0)
  local isLeftMouseDoubleClicked = reaper.ImGui_IsMouseDoubleClicked(ctx, 0)
  local isRightMouseClicked = reaper.ImGui_IsMouseClicked(ctx, 1)
  local isLeftMouseDown = reaper.ImGui_IsMouseDown(ctx, 0)
  local isRightMouseDown = reaper.ImGui_IsMouseDown(ctx, 1)
  local isLeftMouseReleased = reaper.ImGui_IsMouseReleased(ctx, 0)
  local isRightMouseReleased = reaper.ImGui_IsMouseReleased(ctx, 1)
  
  local function getVerticalLineSlope(angle)
	-- Convert angle to radians
	local radians = math.rad(angle)
  
	-- Calculate the slope using cotangent
	local slope = 1 / math.tan(radians)
  
	return slope
	end
  
  local function getXAtY(x1, y1, x2, y2, y)
	-- Handle vertical line
	if x1 == x2 then
	  return x1
	  end
  
	-- Calculate slope
	local m = (y2 - y1) / (x2 - x1)
  
	-- Calculate x at the given y
	local x = (y - y1) / m + x1
  
	return x
	end
	
  local function getLanePosition(lane)
	local data = lanePositionList[lane+1]
	return data[1], data[2], data[3], data[4]
	end
	
  local function drawChartBackground()
	addRectFilled(drawList, chartXMin, chartYMin, chartXMax, chartYMax, CHART_BACKGROUNDCOLOR - round(255*(1-alphaAlbumArtPercentage)))
	end
	
  local function drawFrame()
	addLine(drawList, chartXMin, chartYMin, chartXMax, chartYMin, CHART_TESTFRAMECOLOR, CHART_BOUNDARYTHICKNESS)
	addLine(drawList, chartXMax, chartYMin, chartXMax, chartYMax, CHART_TESTFRAMECOLOR, CHART_BOUNDARYTHICKNESS)
	addLine(drawList, chartXMax, chartYMax, chartXMin, chartYMax, CHART_TESTFRAMECOLOR, CHART_BOUNDARYTHICKNESS)
	addLine(drawList, chartXMin, chartYMax, chartXMin, chartYMin, CHART_TESTFRAMECOLOR, CHART_BOUNDARYTHICKNESS)
	end
  
  local function getYPosFromTime(time, isHighwaySkin)
	local y_strikeline = chartYMax
	local y_horizon = horizonY
	local time_at_half_horizon = TRACKSPEED
	if isHighwaySkin then
	  time_at_half_horizon = time_at_half_horizon * 0.44 --TODO: figure out proper math
	  end
	local time_at_strikeline = visibleTimeMin
	
	local future = time - time_at_strikeline
	local halves = future / time_at_half_horizon
	return y_horizon + (y_strikeline - y_horizon) * (0.5 ^ halves)
	end
	
  local function getIntersection(x1_first, y1_first, x2_first, y2_first, x1_last, y1_last, x2_last, y2_last)
	local m1 = (y2_first - y1_first) / (x2_first - x1_first)
	local mN = (y2_last - y1_last) / (x2_last - x1_last)

	if m1 == mN then
	  return nil, nil  -- Parallel lines, no intersection
	  end

	-- Corrected x-intersection formula
	local x = ((m1 * x1_first - y1_first) - (mN * x1_last - y1_last)) / (m1 - mN)

	-- Use one of the line equations to get y
	local y = m1 * (x - x1_first) + y1_first

	return x, y
	end
  
  local function calculateHorizon()
	x1_first, y2_first, x2_first, y1_first = getLanePosition(0)
	x1_last, y2_last, x2_last, y1_last = getLanePosition(NUM_CHART_LANES)
	horizonX, horizonY = getIntersection(x1_first, y1_first, x2_first, y2_first, x1_last, y1_last, x2_last, y2_last)
	end
	
  local function drawChartBoundaries()
	--draw filled black side triangles
	local _, _, chartXMin2 = getLanePosition(0)
	local _, _, chartXMax2 = getLanePosition(NUM_CHART_LANES)
	reaper.ImGui_DrawList_AddTriangleFilled(drawList, chartXMin, chartYMin, chartXMin2, chartYMin, chartXMin, chartYMax, COLOR_BACKGROUND)
	reaper.ImGui_DrawList_AddTriangleFilled(drawList, chartXMax2, chartYMin, chartXMax, chartYMin, chartXMax, chartYMax, COLOR_BACKGROUND)
	addRectFilled(drawList, chartXMin-200, chartYMax, chartXMax+200, chartWindowY+chartWindowSizeY, COLOR_BACKGROUND)
	
	addLine(drawList, x1_first, y1_first, x2_first, y2_first, laneColor, CHART_BOUNDARYTHICKNESS)
	addLine(drawList, x1_last, y1_last, x2_last, y2_last, laneColor, CHART_BOUNDARYTHICKNESS)
	addLine(drawList, chartXMin, chartYMax, chartXMax, chartYMax, laneColor, CHART_BOUNDARYTHICKNESS)
	
	horizonX, horizonY = getIntersection(x1_first, y1_first, x2_first, y2_first, x1_last, y1_last, x2_last, y2_last)
	end
  
  local function drawLanes()
	for lane=1, NUM_CHART_LANES-1 do
	  local xMin, yMin, xMax, yMax = getLanePosition(lane)
	  addLine(drawList, xMin, yMax, xMax, yMin, COLOR_GREEN, CHART_BOUNDARYTHICKNESS)
	  end
	end
	
  local function drawBlurredRectangles()
	local percentageDownTrack = 0.2
	--draw alpha background
	reaper.ImGui_DrawList_AddRectFilledMultiColor(drawList, chartXMin, chartYMin, chartXMax, chartYMin+chartSizeY*percentageDownTrack, alphaBackgroundColor, alphaBackgroundColor, CHART_BACKGROUNDCOLOR_T, CHART_BACKGROUNDCOLOR_T)
	
	--draw top cover
	addRectFilled(drawList, chartXMin, chartYMin, chartXMax, chartYMin-50, COLOR_BACKGROUND)
	end
  
  local function rotateLine(x1, y1, x2, y2, angle)
	-- Convert angle to radians
	angle = angle * (-1)
	local radians = math.rad(angle)
  
	-- Calculate the horizontal displacement (Delta x)
	local delta_x = (y2 - y1) * math.tan(radians)
  
	-- Calculate the new x2
	local new_x2 = x1 + delta_x
	
	return new_x2
	end
  
  local function getLaneBound(percentage)
	local angle = convertRange(percentage, 0, 0.5, MAXANGLEDEGREES, 0)
  
	local x1 = chartXMin + chartSizeX*percentage
	local y_max = chartYMax
	local y_min = chartYMin
	local x2 = rotateLine(x1, y_max, x1, y_min, angle)
  
	return x1, x2
	end
	
  local function getSpriteVertices(imgSizeX, imgSizeY, percentageShiftX, percentageShiftY, percentageScale, position, startTime, velocity, isHighwaySkin)
	local radius
	if not position or position == -1 then
	  position = 0.5
	  radius = 0.5
	else
	  radius = (1/NUM_CHART_LANES) * 0.5
	  end
	
	local lane_start_x1, lane_start_x2 = getLaneBound(position - radius)
	local lane_end_x1, lane_end_x2 = getLaneBound(position + radius)
	
	local spriteYMax = getYPosFromTime(startTime, isHighwaySkin)
	
	local spriteXMin = getXAtY(lane_start_x2, chartYMin, lane_start_x1, chartYMax, spriteYMax)
	local spriteXMax = getXAtY(lane_end_x2, chartYMin, lane_end_x1, chartYMax, spriteYMax)
	
	----
	
	local imgAspectRatio = imgSizeX/imgSizeY
	local spriteSizeX = spriteXMax - spriteXMin
	
	--velocity scaling
	local percentageScalar
	if not velocity then
	  percentageScalar = 1
	else
	  percentageScalar = getVelocitySizePercentage(velocity)
	  end
	local scaledSpriteSizeX = spriteSizeX * percentageScalar
	local sizeXDifference = (scaledSpriteSizeX - spriteSizeX)/2
	spriteXMin = spriteXMin - sizeXDifference
	spriteXMax = spriteXMax + sizeXDifference
	
	local spriteSizeY = scaledSpriteSizeX/imgAspectRatio
	local spriteYMin = spriteYMax - spriteSizeY
	
	if percentageShiftX then
	  local xLen = spriteXMax - spriteXMin
	  spriteXMin = spriteXMin + xLen*percentageShiftX
	  spriteXMax = spriteXMax + xLen*percentageShiftX
	  end
	if percentageShiftY then
	  local yLen = spriteYMax - spriteYMin
	  spriteYMin = spriteYMin + yLen*percentageShiftY
	  spriteYMax = spriteYMax + yLen*percentageShiftY
	  end
	if percentageScale then
	  local xIncrease = (spriteXMax-spriteXMin)*(percentageScale-1)
	  local yIncrease = (spriteYMax-spriteYMin)*(percentageScale-1)
	  spriteXMin = spriteXMin - xIncrease/2
	  spriteXMax = spriteXMax + xIncrease/2
	  spriteYMin = spriteYMin - yIncrease/2
	  spriteYMax = spriteYMax + yIncrease/2
	  end
	  
	return spriteXMin, spriteYMin, spriteXMax, spriteYMax
	end
  
  local function drawSkinOnHighway(img, laneStart, laneEnd, alphaValues)
	local imgSizeX, imgSizeY = reaper.ImGui_Image_GetSize(img)
	local imgAspectRatio = imgSizeX/imgSizeY
	
	local xMin, _, xMin2 = getLanePosition(laneStart)
	local xMax, _, xMax2 = getLanePosition(laneEnd)
	local yMin = chartYMin
	local sizeX = xMax - xMin
	local scalingFactor = sizeX/imgSizeX
	local sizeY = imgSizeY*scalingFactor
	local yMax = yMin + sizeY
	
	local time = getCursorPosition()
	local timeRange = VISIBLE_TIMERANGE
	local percentageImageStart = time/timeRange - math.floor(time/timeRange)
	local yOffset = math.floor(convertRange(percentageImageStart, 1, 0, yMin, yMax))
	
	local blur_strength = 5
	local alpha = 0.3 
	
	for yStep=0, sizeY-1 do
	  -- Simulate blur by drawing the image multiple times with small offsets
	  for dy = -blur_strength, blur_strength do
		local minPixel = yOffset+yStep+dy
		while minPixel < 0 do
		  minPixel = minPixel + sizeY
		  end
		while minPixel >= sizeY do
		  minPixel = minPixel - sizeY
		  end
		  
		local maxPixel = minPixel+blur_strength
		local minPercentage = minPixel/sizeY
		local maxPercentage = maxPixel/sizeY
		local yMinPartial = yMin+yStep+dy
		local yMaxPartial = yMinPartial+blur_strength
		
		local angledXMin = getXAtY(xMin2, chartYMin, xMin, chartYMax, yMinPartial)
		local angledXMax = getXAtY(xMax2, chartYMin, xMax, chartYMax, yMinPartial)
		
		local offset_alpha = alpha * convertRange(math.abs(dy), 0, blur_strength, alpha, alpha/2) -- Adjust alpha for subtle blending
		--addImage(drawList, img, angledXMin, yMinPartial, angledXMax, yMaxPartial, 0, minPercentage, 1, maxPercentage, color)
		
		local spriteXMin, spriteYMin, spriteXMax, spriteYMax = getSpriteVertices(imgSizeX, yMaxPartial-yMinPartial, nil, nil, nil, _, time+((sizeY-yStep)/sizeY), nil, true)
		spriteYMin = round(spriteYMin)
		spriteYMax = round(spriteYMax)
		if spriteYMax == spriteYMin then spriteYMax = spriteYMax + 1 end
		
		local forcedXMin, _, forcedXMin2 = getLanePosition(0)
		local forcedXMax, _, forcedXMax2 = getLanePosition(1)
		local xAtYMin = getXAtY(forcedXMin2, chartYMin, forcedXMin, chartYMax, spriteYMin)
		local xAtYMax = getXAtY(forcedXMax2, chartYMin, forcedXMax, chartYMax, spriteYMin)
		
		local color
		if alphaValues then
		  local function getAlphaValue()
			for x=1, #alphaValues do
			  local data = alphaValues[x]
			  local yPosStart = data[1]
			  local alphaStart = data[2]
			  local yPosEnd = data[3]
			  local alphaEnd = data[4]
			  local isGradient = data[5]
			  
			  if spriteYMin >= yPosStart then
				if not isGradient then return alphaStart end
				return convertRange(spriteYMin, yPosStart, yPosEnd, alphaStart, alphaEnd)
				end
			  end
			end
		  color = hexColor(255, 255, 255, getAlphaValue())
		else
		  color = floor(offset_alpha * 255) + 0xFFFF00 -- White with transparency
		  end
		  
		addImage(drawList, img, xAtYMin, spriteYMin, xAtYMax, spriteYMax, 0, minPercentage, 1, maxPercentage, color)
	
		--addImage(drawList, img, spriteXMin, spriteYMin, spriteXMax, spriteYMax, 0, minPercentage, 1, maxPercentage, color)

		--TODO: slow
		end
	  end
	end
	
  local function drawAlbumArt()
	--drawSkinOnHighway(getAlbumArtImage(), 0, NUM_CHART_LANES)
	end
  
  local function calculateLanePositions()
	for lane=0, NUM_CHART_LANES do
	  local angle = convertRange(lane, 0, NUM_CHART_LANES/2, MAXANGLEDEGREES, 0)
	  
	  local xMin = chartXMin + chartSizeX*(lane/(NUM_CHART_LANES))
	  local yMax = chartYMax
	  local yMin = chartYMin
	  local xMax = rotateLine(xMin, yMax, xMin, yMin, angle)
	  
	  tableInsert(lanePositionList, {xMin, yMin, xMax, yMax})
	  end
	
	_, _, chartXMin2 = getLanePosition(0)
	_, _, chartXMax2 = getLanePosition(NUM_CHART_LANES)
	end
	
  local function drawGemsInSubList(gemSubList)
	for x=#gemSubList, 1, -1 do
	  local gemData = gemSubList[x]
	  local imgBase = gemData[1]
	  local imgTint = gemData[2]
	  local imgRing = gemData[3]
	  local imgLighting = gemData[4]
	  local gemXMin = gemData[5]
	  local gemYMin = gemData[6]
	  local gemXMax = gemData[7]
	  local gemYMax = gemData[8]
	  local color_r = gemData[9]
	  local color_g = gemData[10]
	  local color_b = gemData[11]
	  local color_a = gemData[12]
	  
	  local lightingR = floor(color_r + (255 - color_r)/2)
	  local lightingG = floor(color_g + (255 - color_g)/2)
	  local lightingB = floor(color_b + (255 - color_b)/2)
	  
	  if imgTint then
		addImage(drawList, imgTint, gemXMin, gemYMin, gemXMax, gemYMax, 0, 0, 1, 1, hexColor(color_r, color_g, color_b, color_a))
		end
	  addImage(drawList, imgBase, gemXMin, gemYMin, gemXMax, gemYMax, 0, 0, 1, 1, COLOR_WHITE)
	  if imgRing then
		local factor = 50
		--addImage(drawList, imgRing, gemXMin-factor, gemYMin-factor, gemXMax+factor, gemYMax+factor, 0, 0, 1, 1, hexColor(color_r, color_g, color_b))
		end
	  if imgLighting then
		addImage(drawList, imgLighting, gemXMin, gemYMin, gemXMax, gemYMax, 0, 0, 1, 1, hexColor(lightingR, lightingG, lightingB))
		end
	  end
	end
  
  local function drawBeatLines()
	local indexStart = findIndexInListEqualOrGreaterThan(chartBeatList, visibleTimeMin, BEATLISTINDEX_TIME)
	if not indexStart then
	  return
	  end
	
	for beatID=indexStart, #chartBeatList do
	  local data = chartBeatList[beatID]
	  local time = data[BEATLISTINDEX_TIME]
	  local beatType = data[BEATLISTINDEX_BEATTYPE]
	  
	  local yPos = getYPosFromTime(time)
	  local colorVal = BEATLINE_COLOR_LIST[beatType+1]
	  local color = hexColor(colorVal, colorVal, colorVal)
	  local thickness = (beatType + 1) * 2
	  
	  if time > visibleTimeMax then
		break
		end
		
	  addLine(drawList, chartXMin+1, yPos, chartXMax-1, yPos, color, thickness)
	  end
	end
  
  local function drawHHBars()
	local function getAlpha(ccVal)
	  local MAX_ALPHA = 125
	  return convertRange(ccVal, 0, 127, 0, MAX_ALPHA)
	  end
	
	for x=1, #hhLaneValueList do
	  local subTable = hhLaneValueList[x]
	  local laneStart = subTable[1][1]
	  local laneEnd = subTable[1][2]
	  local laneColor = subTable[1][3]
	  local laneColor_r, laneColor_g, laneColor_b = colorToRGB(laneColor)
	  
	  local alphaValues = {}
	  
	  for y=2, #subTable do
		local data = subTable[y]
		
		local time = data[1]
		local ccVal = data[2]
		local alpha = getAlpha(ccVal)
		local nextTime = visibleTimeMax
		local nextCCVal = ccVal
		local nextAlpha = alpha
		local isGradient
		if y < #subTable then
		  local nextSubTable = subTable[y+1]
		  nextTime = nextSubTable[1]
		  nextCCVal = nextSubTable[2]
		  isGradient = data[3]
		  if isGradient then
			nextAlpha = getAlpha(nextCCVal)
			end
		  end
		
		local toDraw = false
		if not nextTime or nextTime >= visibleTimeMin then
		  toDraw = true
		  end
		if time > visibleTimeMax then
		  toDraw = false
		  end
		
		local color = hexColor(laneColor_r, laneColor_g, laneColor_b, alpha)
		local nextColor = hexColor(laneColor_r, laneColor_g, laneColor_b, nextAlpha)
		
		if toDraw then
		  local xMin = getLanePosition(laneStart)
		  local yMin = getYPosFromTime(nextTime)
		  local xMax = getLanePosition(laneEnd+1)
		  local yMax = getYPosFromTime(time)
		  xMin = getLanePosition(laneStart)
		  xMax = getLanePosition(NUM_CHART_LANES)
		  --reaper.ImGui_DrawList_AddRectFilledMultiColor(drawList, xMin, yMin, xMax, yMax, nextColor, nextColor, color, color)
		  
		  tableInsert(alphaValues, {getYPosFromTime(nextTime), nextAlpha, getYPosFromTime(time), alpha, isGradient})
		  end
		end
	  
	  local img = getHiHatFootImage()
	  local imgSizeX, imgSizeY = reaper.ImGui_Image_GetSize(img)
	  local imgAspectRatio = imgSizeX/imgSizeY
	  
	  local xMin, _, xMin2 = getLanePosition(laneStart)
	  local xMax, _, xMax2 = getLanePosition(laneEnd+1)
	  local sizeY = imgSizeY
	  local yMin = chartYMin
	  local yMax = yMin + sizeY
	  local sizeX = xMax - xMin
	  
	  local time = getCursorPosition()
	  local timeRange = VISIBLE_TIMERANGE
	  local percentageImageStart = time/timeRange - floor(time/timeRange)
	  local yOffset = floor(convertRange(percentageImageStart, 1, 0, yMin, yMax))
	  
	  local currentYPixel = chartYMin
	  
	  local yStart = getYPosFromTime(visibleTimeMax)
	  local yEnd = getYPosFromTime(visibleTimeMin)

	  for yStep=0, yEnd-yStart do
		local minPixel = yOffset+yStep
		while minPixel < 0 do
		  minPixel = minPixel + sizeY
		  end
		while minPixel >= sizeY do
		  minPixel = minPixel - sizeY
		  end
		 
		local maxPixel = minPixel+1
		local minPercentage = minPixel/sizeY
		local maxPercentage = maxPixel/sizeY
		local yMinPartial = currentYPixel
		
		local xAtYMin = getXAtY(xMin2, chartYMin, xMin, chartYMax, currentYPixel)
		local xAtYMax = getXAtY(xMax2, chartYMin, xMax, chartYMax, currentYPixel)
		
		local function getAlphaValue()
		  for x=1, #alphaValues do
			local data = alphaValues[x]
			local yPosStart = data[1]
			local alphaStart = data[2]
			local yPosEnd = data[3]
			local alphaEnd = data[4]
			local isGradient = data[5]
			
			if currentYPixel >= yPosStart then
			  if not isGradient then return alphaStart end
			  return convertRange(currentYPixel, yPosStart, yPosEnd, alphaStart, alphaEnd)
			  end
			end
		  end
		  
		local color = hexColor(255, 255, 255, getAlphaValue())
		  
		addImage(drawList, img, xAtYMin, currentYPixel, xAtYMax, currentYPixel+1, 0, minPercentage, 1, maxPercentage, color)
		currentYPixel = currentYPixel + 1
		end
	  end
	end
  
  local function drawSustainLanes()
	for x=1, #chartSustainList do
	  local data = chartSustainList[x]
	  
	  local startTime = data[1]
	  local endTime = data[2]
	  local rollType = data[3]
	  local position = data[4]
	  local color = data[5]
	  local shiftX = data[6]
	  local shiftY = data[7]
	  local scale = data[8]
	  local values = data[9]
	  
	  local yBoundaryMin = getYPosFromTime(endTime)
	  local yBoundaryMax = getYPosFromTime(startTime)
	  
	  local ccValues = {}
	  
	  for y=1, #values do
		local value = values[y]
		
		local time = value[1]
		local ccVal = value[2]
		local nextTime = visibleTimeMax
		local nextCCVal = ccVal
		local isGradient
		if y < #values then
		  local nextValue = values[y+1]
		  nextTime = nextValue[1]
		  isGradient = value[3]
		  if isGradient then
			nextCCVal = nextValue[2]
			end
		  end
		
		local toDraw = false
		if not nextTime or nextTime >= visibleTimeMin then
		  toDraw = true
		  end
		if time > visibleTimeMax then
		  toDraw = false
		  end
		
		--TODO: toDraw optimization
		tableInsert(ccValues, {getYPosFromTime(nextTime), nextCCVal, getYPosFromTime(time), ccVal, isGradient})
		end
	  
	  local img
	  if rollType == "tremolo" then img = getTremoloImage() end
	  if rollType == "buzz" then img = getBuzzImage() end  

	  local imgSizeX, imgSizeY = reaper.ImGui_Image_GetSize(img)
	  local imgAspectRatio = imgSizeX/imgSizeY

	  local yStart = getYPosFromTime(visibleTimeMax)
	  local yEnd = getYPosFromTime(visibleTimeMin)
  
	  for currentYPixel=chartYMin, chartYMax do
		if currentYPixel <= yBoundaryMax and currentYPixel > yBoundaryMin then
		  local minPercentage = currentYPixel/imgSizeY
		  local maxPercentage = (currentYPixel+1)/imgSizeY

		  local function getCCVal()
			for x=1, #ccValues do
			  local data = ccValues[x]
			  local yPosStart = data[1]
			  local ccStart = data[2]
			  local yPosEnd = data[3]
			  local ccEnd = data[4]
			  local isGradient = data[5]
			  
			  if currentYPixel >= yPosStart then
				if not isGradient then
				  return ccStart
				  end
				return convertRange(currentYPixel, yPosStart, yPosEnd, ccStart, ccEnd)
				end
			  end
			end
		  
		  local ccVal = getCCVal()
		  
		  local time = convertRange(currentYPixel, yEnd, yStart, visibleTimeMin, visibleTimeMax)
		  local sliceXMin, sliceYMin, sliceXMax, sliceYMax = getSpriteVertices(imgSizeX, imgSizeY, percentageShiftX, percentageShiftY, percentageScale, position, time, ccVal, isHighwaySkin)
		  
		  addImage(drawList, img, sliceXMin, sliceYMin, sliceXMax, sliceYMin+1, 0, minPercentage, 1, maxPercentage, color)
		  end
		  
		currentYPixel = currentYPixel + 1
		end
	  end
	end
	
  local function drawGems()
	local indexStart = findIndexInListEqualOrGreaterThan(chartNoteList, visibleTimeMin, CHARTNOTELISTINDEX_TIME)
	if not indexStart then
	  return
	  end
	
	local gemsByZOrder = {}
	for zIndex=1, 16 do
	  tableInsert(gemsByZOrder, {})
	  end
	  
	for noteID=indexStart, #chartNoteList do
	  local data = chartNoteList[noteID]
	  
	  local time = data[CHARTNOTELISTINDEX_TIME]
	  local gem = data[CHARTNOTELISTINDEX_GEM]
	  local position = data[CHARTNOTELISTINDEX_POSITION]
	  local velocity = data[CHARTNOTELISTINDEX_VELOCITY]
	  local color_r = data[CHARTNOTELISTINDEX_COLOR_R]
	  local color_g = data[CHARTNOTELISTINDEX_COLOR_G]
	  local color_b = data[CHARTNOTELISTINDEX_COLOR_B]
	  local color_a = data[CHARTNOTELISTINDEX_COLOR_A]
	  local percentageShiftX = data[CHARTNOTELISTINDEX_SHIFTX]
	  local percentageShiftY = data[CHARTNOTELISTINDEX_SHIFTY]
	  local percentageScale = data[CHARTNOTELISTINDEX_SCALE]
	  local zIndex = data[CHARTNOTELISTINDEX_ZINDEX]
	  
	  if gem ~= "none" then
		if time >= visibleTimeMax then
		  break
		  end
		
		local imgBase = getImageFromList(gem .. "_base")
		local imgTint = getImageFromList(gem .. "_tint")
		local imgRing = getImageFromList(gem .. "_ring")
		local imgLighting = getImageFromList(gem .. "_lighting" .. padToFourDigits(globalLightingFrameID))
		
		if imgBase then
		  local imgSizeX, imgSizeY = reaper.ImGui_Image_GetSize(imgBase)
		  local gemXMin, gemYMin, gemXMax, gemYMax = getSpriteVertices(imgSizeX, imgSizeY, percentageShiftX, percentageShiftY, percentageScale, position, time, velocity)
		  tableInsert(gemsByZOrder[zIndex+1], {imgBase, imgTint, imgRing, imgLighting, gemXMin, gemYMin, gemXMax, gemYMax, color_r, color_g, color_b, color_a})
		else
		  throwError("No imgBase! " .. gem)
		  end
		end
	  end
	
	--draw in correct z_order
	for zIndex=1, #gemsByZOrder do
	  drawGemsInSubList(gemsByZOrder[zIndex])
	  end
	end
  
  local function drawSectionNames()
	local sectionAlphaYPercentage = 0.2
	local sectionAlphaYMin = sectionYMin + sectionSizeY*sectionAlphaYPercentage
	local sectionAlphaYMax = sectionYMax - sectionSizeY*sectionAlphaYPercentage
	local sectionCenterY = sectionYMin+sectionSizeY/2
	
	local function getCenterY(pos, scrollOffsetY)
	  if not scrollOffsetY then
		scrollOffsetY = 0
		end
	  return sectionYMin + sectionSizeY*(0.2*pos+0.5) - scrollOffsetY
	  end
	  
	local function isValidIndex(index)
	  return (index > 0 and index <= #sectionTextEvtList)
	  end
	
	local function drawSectionFrame()
	  reaper.ImGui_DrawList_AddRect(drawList, sectionXMin, sectionYMin, sectionXMax, sectionYMax, COLOR_WHITE)
	  addRectFilled(drawList, sectionXMin, chartWindowY, sectionXMax, sectionYMin, COLOR_BLACK)
	  end
	
	local function drawTrackSpeedSlider()
	  local cursorPosX, cursorPosY = reaper.ImGui_GetCursorPos(ctx)
	  
	  local settingsX = sectionXMin+10-chartWindowX
	  local yOffset = 20
	  
	  reaper.ImGui_SetCursorPos(ctx, settingsX, sectionYMin+10-chartWindowY)
	  reaper.ImGui_SetNextItemWidth(ctx, 100)
	  local maxVal = 10
	  local factor = 4
	  local retval, val = reaper.ImGui_SliderInt(ctx, "Track Speed", maxVal+1-round(TRACKSPEED*factor), 1, maxVal)
	  if retval then
		writeSettingToFile("trackspeed", (maxVal+1-val)/factor)
		end
	  
	  reaper.ImGui_SetCursorPosX(ctx, settingsX)
	  reaper.ImGui_SetNextItemWidth(ctx, 100)
	  local maxVal = 10
	  local factor = 4
	  local retval, val = reaper.ImGui_SliderInt(ctx, "Angle", MAXANGLEDEGREES, 1, 50)
	  if retval then
		writeSettingToFile("trackangle", val)
		end
		
	  reaper.ImGui_SetCursorPosX(ctx, settingsX)
	  if reaper.ImGui_Checkbox(ctx, "Show Lanes?", (SHOWLANES == 1)) then
		writeSettingToFile("showlanes", math.abs(SHOWLANES-1))
		end
	  
	  reaper.ImGui_SetCursorPos(ctx, cursorPosX, cursorPosY)
	  end
	  
	local function drawSectionName(index, pos, scrollOffsetY)
	  if not isValidIndex(index) then return end
	  
	  reaper.ImGui_PushFont(ctx, sectionFont)
	  
	  local sectionName = sectionTextEvtList[index][2]
	  local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, sectionName)
	  local centerX = sectionXMin + sectionSizeX/2
	  local centerY = getCenterY(pos, scrollOffsetY)
	  reaper.ImGui_SetCursorPosX(ctx, centerX - textSizeX/2 - chartWindowX)
	  reaper.ImGui_SetCursorPosY(ctx, centerY - textSizeY/2 - chartWindowY)
	  
	  local invalidPos
	  if centerY < getCenterY(0, scrollOffsetY) then
		invalidPos = -1
	  else
		invalidPos = 1
		end
	  local percentageValid = convertRange(centerY, getCenterY(invalidPos, scrollOffsetY), getCenterY(0, scrollOffsetY), 0, 1)
	  local color = hexColor(255, 255, 255*(1-percentageValid))
	  reaper.ImGui_TextColored(ctx, color, sectionName)
	  
	  reaper.ImGui_PopFont(ctx)
	  end
	
	local function drawBlurredSectionBackgrounds()
	  reaper.ImGui_DrawList_AddRectFilledMultiColor(drawList, sectionXMin, sectionAlphaYMin, sectionXMax, sectionCenterY, alphaBackgroundColor, alphaBackgroundColor, CHART_BACKGROUNDCOLOR_T, CHART_BACKGROUNDCOLOR_T)
	  reaper.ImGui_DrawList_AddRectFilledMultiColor(drawList, sectionXMin, sectionAlphaYMax, sectionXMax, sectionCenterY, alphaBackgroundColor, alphaBackgroundColor, CHART_BACKGROUNDCOLOR_T, CHART_BACKGROUNDCOLOR_T)
	  
	  addRectFilled(drawList, sectionXMin, sectionYMin, sectionXMax, sectionAlphaYMin, COLOR_BACKGROUND)
	  addRectFilled(drawList, sectionXMin, sectionAlphaYMax, sectionXMax, sectionYMax, COLOR_BACKGROUND)
	  end
	  
	local index = findClosestIndexAtOrBelow(sectionTextEvtList, reaper.MIDI_GetPPQPosFromProjTime(eventsTake, getCursorPosition()), 1)
	if index then
	  local scrollOffsetY
	  if index == #sectionTextEvtList then
		scrollOffsetY = 0
	  else
		local ppqpos = sectionTextEvtList[index][1]
		local nextPPQPOS = sectionTextEvtList[index+1][1]
		local currentTime = getCursorPosition()
		local nextTime = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, nextPPQPOS)
		if nextTime - currentTime < SECTIONNAMESCROLLTIME then
		  local scrollDistance = getCenterY(1) - getCenterY(0)
		  scrollOffsetY = convertRange(currentTime, nextTime-SECTIONNAMESCROLLTIME, nextTime, 0, scrollDistance)
		  end
		end
	  for x=-2, 2 do
		drawSectionName(index+x, x, scrollOffsetY)
		end
	  end
	  
	drawBlurredSectionBackgrounds()
	
	drawSectionFrame()
	
	drawTrackSpeedSlider()
	end
  
  local function addDrumKitSelector()
	local setting = "drumkit"
	
	local width = 150
	reaper.ImGui_SetCursorPos(ctx, sectionXMin-width-10-chartWindowX, sectionYMin-chartWindowY)
	reaper.ImGui_SetNextItemWidth(ctx, width)
	local drumKitName = getSettingFromFile(setting)
	
	local drumKitList = {}
	local dir = getDrumKitsDirectory()
	
	reaper.EnumerateFiles(dir, -1)
	
	local fileIndex = 0
	while true do
	  local fileName = reaper.EnumerateFiles(dir, fileIndex)
	  if not fileName then
		break
		end
	  
	  tableInsert(drumKitList, string.sub(fileName, 1, #fileName-4))
	  fileIndex = fileIndex + 1
	  end
	  
	if not drumKitName or not isInTable(drumKitList, drumKitName) then
	  drumKitName = "Select drum kit..."
	  end
	  
	if reaper.ImGui_BeginCombo(ctx, "##DRUMSELECTORCOMBO", drumKitName) then
	  for x=1, #drumKitList do
		local testDrumKitName = drumKitList[x]
		if reaper.ImGui_Selectable(ctx, testDrumKitName .. "##SELECTDRUMKIT", false, reaper.ImGui_SelectableFlags_None()) then
		  writeSettingToFile(setting, testDrumKitName)
		  setRefreshState(REFRESHSTATE_COMPLETE)
		  end
		end
	  reaper.ImGui_EndCombo(ctx)
	  end
	end
	
  local function drawDefaultVelocity()
	local midiEditor = reaper.MIDIEditor_GetActive()
	if reaper.MIDIEditor_GetTake(midiEditor) ~= notesTake then return end
	
	local commandID = reaper.NamedCommandLookup("_RS7d3c_7dbef3757c50fc913a33a0134e978f5174c9b288")
	if reaper.GetToggleCommandStateEx(32060, commandID) ~= 1 then return end
	
	reaper.ImGui_PushFont(ctx, velocityFont)
	
	local defaultVelocity = reaper.MIDIEditor_GetSetting_int(midiEditor, "default_note_vel")
	local xMin = chartWindowX+chartWindowSizeX - 100
	local yMin = chartWindowY+chartWindowSizeY - 50
	local xMax = chartWindowX+chartWindowSizeX
	local yMax = chartWindowY+chartWindowSizeY
	
	--addRectFilled(drawList, xMin, yMin, xMax, yMax, COLOR_WHITE) --test boundary
	
	local str = tostring(defaultVelocity)
	local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, str)
	local textXMin = xMin + (xMax-xMin)/2 - textSizeX/2
	local textYMin = yMin + (yMax-yMin)/2 - textSizeY/2
	local textXMax = textXMin + textSizeX
	local textYMax = textYMin + textSizeY
	reaper.ImGui_SetCursorPos(ctx, textXMin-chartWindowX, textYMin-chartWindowY)
	
	local color
	if defaultVelocity == 1 or defaultVelocity == 50 or defaultVelocity == 100 or defaultVelocity == 127 then
	  color = COLOR_GREEN
	else
	  color = COLOR_RED
	  end
	reaper.ImGui_TextColored(ctx, color, str)
	
	reaper.ImGui_PopFont(ctx)
	end
	
  calculateLanePositions()
  calculateHorizon()
  
  drawAlbumArt()
  
  drawChartBackground()
  
  if hasBeatLines then
	drawBeatLines()
	end
  
  --drawHHBars()
  drawSustainLanes()
  
  drawGems()
  
  drawBlurredRectangles()
  
  drawChartBoundaries()
  
  if SHOWLANES == 1 then
	drawLanes()
	end
	
  --drawFrame()
  
  drawSectionNames()
  
  addDrumKitSelector()
  
  drawDefaultVelocity()
  end

function getMeasureTextEvents()
  measureList = {}
  
  local recentBeamGroupings = {}
  
  local function getDefaultTimeSigNumDenom(currentMeasureListIndex)
	local measureID = reaper.TimeMap_QNToMeasures(0, measureList[currentMeasureListIndex][MEASURELISTINDEX_QN])
	local _, _, _, timeSigNum, timeSigDenom = reaper.TimeMap_GetMeasureInfo(0, measureID)
	return timeSigNum, timeSigDenom
	end
	
  local function getDefaultBeamGroupingsStr(currentMeasureListIndex, timeSigNum, timeSigDenom)
	for x=1, #recentBeamGroupings do
	  local data = recentBeamGroupings[x]
	  if data[1] == timeSigNum and data[2] == timeSigDenom then
		return data[3]
		end
	  end
	  
	local str = ""
  
	local beamValue = math.max(timeSigDenom, 8)
	
	local beatTable = measureList[currentMeasureListIndex][MEASURELISTINDEX_BEATTABLE]
	local strongBeatsTable = {}
	for beatID=1, #beatTable do
	  if beatTable[beatID][2] then
		tableInsert(strongBeatsTable, beatID-1)
		end
	  end
	  
	for x=1, #strongBeatsTable do
	  local prevStrongBeat = strongBeatsTable[x]
	  local strongBeat
	  if x == #strongBeatsTable then
		strongBeat = timeSigNum
	  else
		strongBeat = strongBeatsTable[x+1]
		end
  
	  local numBeamedNotes = round((strongBeat-prevStrongBeat) * (beamValue/timeSigDenom))
	  str = str .. numBeamedNotes .. ","
	  
	  prevStrongBeat = strongBeat
	  end
	  
	str = cleanPunctuationFromStr(str)
	
	return str
	end
  
  local function getDefaultSecondaryBeamGroupingsStr(timeSigNum, timeSigDenom)
	for x=1, #recentBeamGroupings do
	  local data = recentBeamGroupings[x]
	  if data[1] == timeSigNum and data[2] == timeSigDenom then
		return data[4]
		end
	  end
	  
	return ""
	end
  
  local function getDefaultQuantizeStr()
	return "1/64T"
	end
  
  local function updateRecentBeamGrouping(timeSigNum, timeSigDenom, beamGroupings, secondaryBeamGroupings)
	for x=1, #recentBeamGroupings do
	  local data = recentBeamGroupings[x]
	  if data[1] == timeSigNum and data[2] == timeSigDenom then
		data[3] = beamGroupings
		data[4] = secondaryBeamGroupings
		return
		end
	  end
	
	tableInsert(recentBeamGroupings, {timeSigNum, timeSigDenom, beamGroupings, secondaryBeamGroupings})
	end
	
  local isMeasureOverride = false
  
  local currentMeasureListIndex = 1
  local currentPPQPOS
  local isAtMeasure = false
  local isMeasureOverride = false
  
  local timeSigNum, timeSigDenom, beamGroupings, secondaryBeamGroupings, quantizeStr
  
  ---
  
  local function insertInBeatTable(qnBeat, isStrongBeat)
	local beatTable = measureList[#measureList][MEASURELISTINDEX_BEATTABLE]
	tableInsert(beatTable, {qnBeat, isStrongBeat})
	end
  
  for x=1, #notationBeatList-1 do
	local data = notationBeatList[x]
	local ppqpos = data[BEATLISTINDEX_PPQPOS]
	local qn = getQNFromPPQPOS(eventsTake, ppqpos)
	local time = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, ppqpos)
	
	local beatType = data[BEATLISTINDEX_BEATTYPE]
	
	if beatType == BEAT_MEASURE_NOTATION then
	  if #measureList > 0 then --add qnEnd beat
		insertInBeatTable(qn, false)
		end
		
	  tableInsert(measureList, {})
	  measureList[#measureList][MEASURELISTINDEX_PPQPOS] = ppqpos
	  measureList[#measureList][MEASURELISTINDEX_QN] = qn
	  measureList[#measureList][MEASURELISTINDEX_TIME] = time
	  measureList[#measureList][MEASURELISTINDEX_BEATTABLE] = {}
	  insertInBeatTable(qn, true)
	  end
	if beatType == BEAT_STRONG_NOTATION then
	  insertInBeatTable(qn, true)
	  end
	if beatType == BEAT_WEAK_NOTATION then
	  insertInBeatTable(qn, false)
	  end
	end
  insertInBeatTable(endEvtQN, false) --put endEvtPPQPOS in last subTable
	
  ---
  
  local function processPreviousMeasureValues(measureIndex, fixingFirstMeasure)
	if timeSigNum == "default" or fixingFirstMeasure then
	  isMeasureOverride = false
	  timeSigNum, timeSigDenom = getDefaultTimeSigNumDenom(measureIndex)
	elseif timeSigDenom then
	  isMeasureOverride = true
	else
	  timeSigNum, timeSigDenom = getDefaultTimeSigNumDenom(measureIndex)
	  end
	
	if not beamGroupings or fixingFirstMeasure then
	  beamGroupings = getDefaultBeamGroupingsStr(measureIndex, timeSigNum, timeSigDenom)
	  end
	if not secondaryBeamGroupings or fixingFirstMeasure then
	  secondaryBeamGroupings = getDefaultSecondaryBeamGroupingsStr(timeSigNum, timeSigDenom)
	  end
	if not quantizeStr or quantizeStr == "default" or fixingFirstMeasure then
	  quantizeStr = getDefaultQuantizeStr()
	  end
	  
	local currentTable = measureList[measureIndex]
	
	currentTable[MEASURELISTINDEX_TIMESIGNUM] = timeSigNum
	currentTable[MEASURELISTINDEX_TIMESIGDENOM] = timeSigDenom
	if not fixingFirstMeasure or not currentTable[MEASURELISTINDEX_BEAMGROUPINGS] then
	  currentTable[MEASURELISTINDEX_BEAMGROUPINGS] = beamGroupings
	  end
	if not fixingFirstMeasure or not currentTable[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS] then
	  currentTable[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS] = secondaryBeamGroupings
	  end
	if not fixingFirstMeasure or not currentTable[MEASURELISTINDEX_QUANTIZESTR] then
	  currentTable[MEASURELISTINDEX_QUANTIZESTR] = quantizeStr
	  end
	  
	updateRecentBeamGrouping(timeSigNum, timeSigDenom, beamGroupings, secondaryBeamGroupings)
	end
  
  local lastCurrentMeasureListIndex = 1
  local _, _, _, textCount = reaper.MIDI_CountEvts(eventsTake)
  for textEvtID=0, textCount-1 do
	local _, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(eventsTake, textEvtID)
	local qn = getQNFromPPQPOS(eventsTake, ppqpos)
	local time = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, ppqpos)
	
	if time >= END_TEXT_EVT_TIME then
	  break
	  end

	if evtType == TEXT_EVENT then
	  if ppqpos >= startEvtPPQPOS and ppqpos < endEvtPPQPOS then
		if ppqpos ~= currentPPQPOS then
		  if isAtMeasure then --process previous measure values
			processPreviousMeasureValues(currentMeasureListIndex)
			end
		  
		  --update to new measure
		  currentPPQPOS = ppqpos
		  timeSigNum, timeSigDenom, beamGroupings, secondaryBeamGroupings, quantizeStr = nil, nil, nil, nil, nil, nil
		  isAtMeasure = false
		  while currentMeasureListIndex <= #measureList do
			local measurePPQPOS = measureList[currentMeasureListIndex][MEASURELISTINDEX_PPQPOS]
			if currentPPQPOS == measurePPQPOS then
			  lastCurrentMeasureListIndex = currentMeasureListIndex
			  isAtMeasure = true
			  break
			  end
			if currentPPQPOS < measurePPQPOS then
			  throwError("Measure text event not aligned with measure! " .. currentMeasureListIndex)
			  end
			if currentPPQPOS > measurePPQPOS then
			  currentMeasureListIndex = currentMeasureListIndex + 1
			  end
			end
		  end
		  
		local spaceIndex = string.find(msg, " ")
		if evtType == TEXT_EVENT and spaceIndex and isAtMeasure then
		  local header = string.sub(msg, 1, spaceIndex-1)
		  local val = string.sub(msg, spaceIndex+1, #msg)
		  if tonumber(val) then
			val = tonumber(val)
			end
		  
		  if header == "timesig" then
			if isJamTrack() then
			  throwError("No custom time signature events allowed in jam tracks!", nil, time)
			  end
			if val == "default" then
			  timeSigNum = val
			else
			  local slashIndex = string.find(val, "/")
			  if slashIndex then
				local testNum = tonumber(string.sub(val, 1, slashIndex-1))
				local testDenom = tonumber(string.sub(val, slashIndex+1, #val))
				if testNum and testDenom and floor(testNum) == testNum and floor(testDenom) == testDenom and isInTable(VALID_RHYTHM_DENOM_LIST, testDenom) then
				  timeSigNum = floor(testNum)
				  timeSigDenom = floor(testDenom)
				  end
				end
			  if not timeSigNum or not timeSigDenom then
				throwError("Invalid time signature (no slash)!", nil, time)
				end
			  end
			end
		  
		  if header == "beamgroupings" then
			if isJamTrack() then
			  throwError("No custom beam grouping events allowed in jam tracks!", nil, time)
			  end
			beamGroupings = val
			end
		  if header == "secondarybeamgroupings" then
			if isJamTrack() then
			  throwError("No custom secondary beam grouping events allowed in jam tracks!", nil, time)
			  end
			secondaryBeamGroupings = val
			end
		  if header == "quantize" then
			if isJamTrack() then
			  throwError("No custom quantize events allowed in jam tracks!", nil, time)
			  end
			quantizeStr = val
			end
		  end
		end
	  end
	end
  
  processPreviousMeasureValues(lastCurrentMeasureListIndex)
	
  local currentTimeSigNum, currentTimeSigDenom, currentBeamGroupings, currentSecondaryBeamGroupings, currentQuantizeStr
  for measureIndex=1, #measureList do
	local data = measureList[measureIndex]
	
	local timeSigNum = data[MEASURELISTINDEX_TIMESIGNUM]
	if timeSigNum then
	  currentTimeSigNum = timeSigNum
	else
	  if measureIndex == 1 then
		processPreviousMeasureValues(measureIndex, true)
		currentTimeSigNum = data[MEASURELISTINDEX_TIMESIGNUM]
	  else
		data[MEASURELISTINDEX_TIMESIGNUM] = currentTimeSigNum
		end
	  end
	
	local timeSigDenom = data[MEASURELISTINDEX_TIMESIGDENOM]
	if timeSigDenom then
	  currentTimeSigDenom = timeSigDenom
	else
	  data[MEASURELISTINDEX_TIMESIGDENOM] = currentTimeSigDenom
	  end
	  
	local beamGroupings = data[MEASURELISTINDEX_BEAMGROUPINGS]
	if beamGroupings then
	  currentBeamGroupings = beamGroupings
	else
	  data[MEASURELISTINDEX_BEAMGROUPINGS] = currentBeamGroupings
	  end
	  
	local secondaryBeamGroupings = data[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS]
	if secondaryBeamGroupings then
	  currentSecondaryBeamGroupings = secondaryBeamGroupings
	else
	  data[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS] = currentSecondaryBeamGroupings
	  end
	
	local quantizeStr = data[MEASURELISTINDEX_QUANTIZESTR]
	if quantizeStr then
	  currentQuantizeStr = tostring(quantizeStr)
	else
	  data[MEASURELISTINDEX_QUANTIZESTR] = currentQuantizeStr
	  end
	
	local quantizeStr = currentQuantizeStr
	local quantizeModifier
	if not tonumber(string.sub(quantizeStr, #quantizeStr, #quantizeStr)) then
	  quantizeModifier = string.lower(string.sub(quantizeStr, #quantizeStr, #quantizeStr))
	  quantizeStr = string.sub(quantizeStr, 1, #quantizeStr-1)
	  end
	local quantizeTupletFactorNum, quantizeTupletFactorDenom = getTupletFactorNumDenom(quantizeModifier)
	
	local quantizeNum, quantizeDenom
	local slashIndex = string.find(quantizeStr, "/")
	if slashIndex then
	  quantizeNum = tonumber(string.sub(quantizeStr, 1, slashIndex-1))
	  quantizeDenom = tonumber(string.sub(quantizeStr, slashIndex+1, #quantizeStr))
	else
	  quantizeNum = 1
	  quantizeDenom = tonumber(quantizeStr)
	  end
	
	if not (quantizeNum == 1 and isInTable(VALID_RHYTHM_DENOM_LIST, quantizeDenom)) then
	  throwError("Invalid quantize value! " .. quantizeStr, nil, time)
	  end
	  
	quantizeNum = round(quantizeNum*quantizeTupletFactorNum)
	quantizeDenom = round(quantizeDenom*quantizeTupletFactorDenom)
	quantizeNum, quantizeDenom = simplifyFraction(quantizeNum, quantizeDenom)
	
	data[MEASURELISTINDEX_QUANTIZEDENOM] = quantizeDenom
	data[MEASURELISTINDEX_QUANTIZETUPLETFACTORNUM] = quantizeTupletFactorNum
	data[MEASURELISTINDEX_QUANTIZETUPLETFACTORDENOM] = quantizeTupletFactorDenom
	data[MEASURELISTINDEX_QUANTIZEMODIFIER] = quantizeModifier
	
	---
	
	local beatTable = data[MEASURELISTINDEX_BEATTABLE]
	if #beatTable ~= currentTimeSigNum + 1 then
	  throwError("Beats don't add up to time signature! (" .. currentTimeSigNum .. "/" .. currentTimeSigDenom .. ")", measureIndex)
	  end
	  
	for x=1, #beatTable do
	  local subTable = beatTable[x]
	  if #subTable ~= 2 then
		error("BAD BEAT SUB TABLE")
		end
	  local num = x-1
	  local denom = currentTimeSigDenom --TODO: fix
	  num, denom = simplifyFraction(num, denom)
	
	  tableInsert(subTable, roundFloatingPoint(num/denom))
	  tableInsert(subTable, num)
	  tableInsert(subTable, denom)
	  end
	end
  end

function getNotationTempos()
  local list = {}
  
  local function addToList(ppqpos, qn, bpmBasis, bpm, performanceDirection)
	tableInsert(list, {ppqpos, qn, bpmBasis, removeExcessZeroes(round(bpm, 2)), performanceDirection})
	end
  
  local function getPerformanceDirection(markerID)
	local _, _, _, _, bpm, _, _, isLinear = reaper.GetTempoTimeSigMarker(0, markerID)
	if not isLinear then
	  return
	  end
	  
	local retval, _, _, _, nextBPM = reaper.GetTempoTimeSigMarker(0, markerID+1)
	if retval then
	  if nextBPM > bpm then
		return "accel."
		end
	  if nextBPM < bpm then
		return "rit."
		end
	  end
	end
	
  for x=1, #tempoTextEvtList do
	local overrideSegment = tempoTextEvtList[x]
	local overrideEndPPQPOS = overrideSegment[#overrideSegment]

	local lastIndex = #overrideSegment
	if tonumber(overrideEndPPQPOS) then --if overriding to [end]
	  lastIndex = lastIndex - 1
	  end
	for x=1, #overrideSegment do
	  local data = overrideSegment[x]
	  if tonumber(data) then --if overrideEndPPQPOS then
		local overrideEndPPQPOS = data
		
		local bpm, performanceDirection
		local numTempoTimeSigMarkers = reaper.CountTempoTimeSigMarkers(0)
		for tempoTimeSigMarkerID=numTempoTimeSigMarkers-1, 0, -1 do
		  local _, tempoTime, _, _, bpm = reaper.GetTempoTimeSigMarker(0, tempoTimeSigMarkerID)
		  local tempoPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(eventsTake, tempoTime)
		  if tempoPPQPOS <= overrideEndPPQPOS then
			addToList(overrideEndPPQPOS, getQNFromPPQPOS(eventsTake, overrideEndPPQPOS), "q", bpm, getPerformanceDirection(tempoTimeSigMarkerID))
			break
			end
		  end
		break
		end
		
	  local ppqpos = data[TEMPOLISTINDEX_PPQPOS]
	  local qn = data[TEMPOLISTINDEX_QN]
	  local bpmBasis = data[TEMPOLISTINDEX_BPMBASIS]
	  local bpm = data[TEMPOLISTINDEX_BPM]
	  local performanceDirection = data[TEMPOLISTINDEX_PERFORMANCEDIRECTION]
	  addToList(ppqpos, qn, bpmBasis, bpm, performanceDirection)
	  end
	end
	  
  local numTempoTimeSigMarkers = reaper.CountTempoTimeSigMarkers(0)
  for tempoTimeSigMarkerID=0, numTempoTimeSigMarkers-1 do
	local _, tempoTime, measure, beat, bpm = reaper.GetTempoTimeSigMarker(0, tempoTimeSigMarkerID)
	local tempoPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(eventsTake, tempoTime)
	
	local isInOverrideSegment = false
	for x=1, #tempoTextEvtList do
	  local overrideSegment = tempoTextEvtList[x]
	  local overrideStartPPQPOS = overrideSegment[1][1]
	  local overrideEndPPQPOS = overrideSegment[#overrideSegment]
	  if tempoPPQPOS >= overrideStartPPQPOS then
		if not tonumber(overrideEndPPQPOS) or tempoPPQPOS <= overrideEndPPQPOS then
		  isInOverrideSegment = true
		  break
		  end
		end
	  end
	  
	if not isInOverrideSegment then
	  addToList(tempoPPQPOS, getQNFromPPQPOS(eventsTake, tempoPPQPOS), "q", bpm, getPerformanceDirection(tempoTimeSigMarkerID))
	  end
	end
  
  table.sort(list, function(a, b)
	return a[TEMPOLISTINDEX_PPQPOS] < b[TEMPOLISTINDEX_PPQPOS]
	end)
  
  local hasMarkerAtStartPPQPOS = false
  for x=#list, 1, -1 do
	local data = list[x]
	local ppqpos = data[TEMPOLISTINDEX_PPQPOS]
	
	if ppqpos == startEvtPPQPOS then
	  hasMarkerAtStartPPQPOS = true
	  end
	if ppqpos >= endEvtPPQPOS then
	  table.remove(list, x)
	  end
	if ppqpos < startEvtPPQPOS then
	  if hasMarkerAtStartPPQPOS then
		table.remove(list, x)
	  else
		data[TEMPOLISTINDEX_PPQPOS] = startEvtPPQPOS
		data[TEMPOLISTINDEX_QN] = getQNFromPPQPOS(eventsTake, startEvtPPQPOS)
		hasMarkerAtStartPPQPOS = true
		end
	  end
	end
	
  --TODO: after done with everything, check if any ppqpos's are the same, and delete (loop backward) (shouldn't happen)
  
  return list
  end

function isValidMIDINote(midiNoteNum)
  return midiNoteNum >= 0 and midiNoteNum <= 127 and floor(midiNoteNum) == midiNoteNum
  end

function setLaneOverrideName(midiNoteNum, name)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
	throwError("No config text event ID! " .. midiNoteNum)
	end
  
  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(notesTake, textEvtID)
  local quoteIndex = string.find(msg, "\"")
  local newMsg
  if quoteIndex then
	newMsg = string.sub(msg, 1, quoteIndex) .. name .. "\""
  else
	newMsg = msg .. " \"" .. name .. "\""
	end
  
  setTextSysexEvt(notesTake, textEvtID, nil, nil, nil, evtType, newMsg)
  end
	
function getQNFromPPQPOS(take, ppqpos)
  return roundFloatingPoint(reaper.MIDI_GetProjQNFromPPQPos(take, ppqpos))
  end

function findClosestIndexAtOrBelow(list, target, subTableIndex)
  local low = 1
  local high = #list
  local result = nil -- To store the index of the closest value <= target

  while low <= high do
	local mid = floor((low + high) / 2)
	local midValue
	if subTableIndex then
	  midValue = list[mid][subTableIndex]
	else
	  midValue = list[mid]
	  end

	if midValue <= target then
	  result = mid -- Update result to the current index
	  low = mid + 1 -- Continue searching the right half
	else
	  high = mid - 1 -- Search the left half
	  end
	end

  return result -- Returns nil if no value <= target exists
  end

function getQNFromBeat(beatTable, beat)
  local flooredBeat = floor(beat)
  local flooredBeatStart = flooredBeat
  
  flooredBeatStart = math.max(flooredBeatStart, 0)
  flooredBeatStart = math.min(flooredBeatStart, #beatTable-2)
  
  local flooredBeatEnd = flooredBeatStart+1
  
  local boundStart = beatTable[flooredBeatStart+1][1]
  local boundEnd = beatTable[flooredBeatEnd+1][1]
  
  return convertRange(beat, flooredBeatStart, flooredBeatEnd, boundStart, boundEnd)
  end
  
function binarySearchClosestOrLess(sortedTable, target, isSubTable)
  local low = 1
  local high = #sortedTable
  local result = nil

  while low <= high do
	local mid = floor((low + high) / 2)
	local midValue
	if isSubTable then
	  midValue = sortedTable[mid][1]
	else
	  midValue = sortedTable[mid]
	  end

	if midValue == target then
	  return mid -- Exact match found
	elseif midValue < target then
	  result = mid -- Potential candidate
	  low = mid + 1 -- Search the right half
	else
	  high = mid - 1 -- Search the left half
	  end
	end

  return result
  end

local function exactBinarySearch(list, target, subTableIndex)
  local left, right = 1, #list
  
  while left <= right do
  local mid = math.floor((left + right) / 2)
  local midValue -- First value in the subtable
  if subTableIndex then
	midValue = list[mid][subTableIndex]
  else
	midValue = list[mid]
	end
  
  if midValue == target then
	return mid -- Found the target, return its index
  elseif midValue < target then
	left = mid + 1 -- Search in the right half
  else
	right = mid - 1 -- Search in the left half
	end
  end
  
  return nil -- Target not found
  end

function getStaffLinePosition(staffLine, isSpaceAbove)
  local centerStaffLineIndex = NUMLOWERLEGERLINES + 3
  local index = centerStaffLineIndex + staffLine
  local pos = staffLinePositionList[index]
  if isSpaceAbove then
	pos = pos - STAFFSPACEHEIGHT/2
	end
  return pos
  end

function getTupletImagesAndBoundaries(tupletNum, tupletDenom, showColon)
  local tupletStr = tostring(tupletNum)
  if showColon then
	tupletStr = tupletStr .. ":" .. tupletDenom
	end
	
  local imgTable = {}
  for x=1, #tupletStr do
	local char = string.sub(tupletStr, x, x)
	if char == ":" then
	  char = "colon"
	  end
	local imgFileName = "tuplet_" .. char
	local img = getImageFromList(imgFileName)
	tableInsert(imgTable, {img, imgFileName, (char=="colon")})
	end
  
  local imgData = {}
  
  local yMin = 0
  local yMaxNumbers = STAFFSPACEHEIGHT*1.3
  local yMaxColon = STAFFSPACEHEIGHT
  
  local xMin = 0
  for x=1, #imgTable do
	local img = imgTable[x][1]
	local imgFileName = imgTable[x][2]
	local isColon = imgTable[x][3]
	
	local imgSizeX, imgSizeY = getImageSize(imgFileName)
	local imgAspectRatio = imgSizeX/imgSizeY

	local yMax
	if isColon then
	  yMax = yMaxColon
	else
	  yMax = yMaxNumbers
	  end
	local sizeY = yMax - yMin
	
	local scalingFactor = sizeY/imgSizeY
	local sizeX = imgSizeX*scalingFactor
	
	local xMax = xMin + sizeX
	
	tableInsert(imgData, {img, xMin, yMin, xMax, yMax, imgFileName})
	
	xMin = xMax + STAFFSPACEHEIGHT/10
	end
  
  return imgData, yMax
  end

function getBeamOverride(chord)
  local chordGlobalData = chord[1]
  local chordPPQPOS = chordGlobalData[CHORDGLOBALDATAINDEX_PPQPOS]
  local voiceIndex = chordGlobalData[CHORDGLOBALDATAINDEX_VOICEINDEX]
  
  local beamOverrideList = beamOverrideListBothVoices[voiceIndex]
  local beamOverrideListIndex = findClosestIndexAtOrBelow(beamOverrideList, chordPPQPOS, BEAMOVERRIDELISTINDEX_PPQPOS)
  
  if beamOverrideListIndex then
	local beamPPQPOS = beamOverrideList[beamOverrideListIndex][BEAMOVERRIDELISTINDEX_PPQPOS]
	if beamPPQPOS == chordPPQPOS then
	  return beamOverrideList[beamOverrideListIndex][BEAMOVERRIDELISTINDEX_VAL]
	  end
	end
  end

function getStaffLinePositions()
  local list = {}
  
  local centerStaffLine = floor((NUM_STAFFLINES+1)/2)-1
  for staffLine=MINSTAFFLINE, MAXSTAFFLINE do
	local staffLineYPos = getStaffLinePosition(staffLine)
	local color
	if staffLine >= -2 and staffLine <= 2 then
	  color = COLOR_BLACK
	else
	  color = COLOR_GREEN
	  end
	if color == COLOR_BLACK then
	  local staffLineXMin = NOTATION_XMIN
	  local staffLineXMax = ENDMEASUREXMAX-1-reaper.ImGui_GetScrollX(ctx)
	  tableInsert(list, {staffLineXMin, staffLineXMax, staffLineYPos, color})
	  end
	end
  
  return list
  end
  
function drawStaffLines()
  local positions = getStaffLinePositions()
  for x=1, #positions do
	local data = positions[x]
	
	local xMin = data[1]
	local xMax = data[2]
	local yPos = data[3]
	local color = data[4]
	addLine(drawList, xMin, yPos, xMax, yPos, color, STAFFLINETHICKNESS, true)
	end
  end
  
function drawNotation()
  if checkError(ERROR_RHYTHMLIST) then return end
  
  addRectFilled(drawList, NOTATION_XMIN, NOTATION_YMIN, NOTATION_XMAX, NOTATION_YMAX, NOTATION_BGCOLOR)

  local clickedItem, clickedItemXMin, clickedItemYMin, clickedItemXMax, clickedItemYMax
  
  local cursorPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(eventsTake, getCursorPosition())
  
  local currentMeasureIndex = findClosestIndexAtOrBelow(measureList, cursorPPQPOS, MEASURELISTINDEX_PPQPOS)
  local pageListIndex
  if not currentMeasureIndex then
	pageListIndex = 1
  else
	pageListIndex = findIndexInListEqualOrLessThan(measurePageList, currentMeasureIndex, 1)
	end
  
  local pageData = measurePageList[pageListIndex]
  local firstVisibleMeasureIndex = pageData[1]
  local boundXMin = pageData[2][1]
  local xOffset = boundXMin - NOTATIONDRAWAREA_XMIN
  local flooredCurrentBeat
  local pastEndOfSong = reaper.MIDI_GetPPQPosFromProjTime(eventsTake, getCursorPosition()) >= endEvtPPQPOS
  
  if PLAYSTATE == 1 and notationEditor_recentScrollX and reaper.ImGui_GetScrollX(ctx) ~= notationEditor_recentScrollX then
	notationEditor_followPage = false
	end
  
  notationEditor_recentScrollX = reaper.ImGui_GetScrollX(ctx)
  
  if currentMeasureIndex and currentMeasureIndex <= NUMSUCCESSFULMEASURES and not pastEndOfSong then
	local pageDataSubTableIndex = 2
	for measureIndex=firstVisibleMeasureIndex, currentMeasureIndex-1 do
	  pageDataSubTableIndex = pageDataSubTableIndex + 1
	  end
	local activeMeasureBoundXMin = pageData[pageDataSubTableIndex][1]
	local activeMeasureBoundXMax = pageData[pageDataSubTableIndex][2]

	measureBoundXMin = activeMeasureBoundXMin
	
	gettingCurrentValues = true
	runChartCompiler(currentMeasureIndex)
	gettingCurrentValues = false
	
	local timeEnd = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, reaper.MIDI_GetPPQPosFromProjQN(eventsTake, currentMeasureData_qnEnd))
	local currentTime = getCursorPosition()
	if notationEditor_followPage and PLAYSTATE == 1 then
	  if pageListIndex < #measurePageList and measurePageList[pageListIndex+1][1] == currentMeasureIndex+1 and timeEnd - currentTime < NOTATIONSCROLLTIME then
		local percentageScrolled = convertRange(currentTime, timeEnd-NOTATIONSCROLLTIME, timeEnd, 0, 1)
		notationEditor_recentScrollX = round(xOffset + (measureList[currentMeasureIndex][MEASURELISTINDEX_MEASUREBOUNDARYXMAX]-(NOTATIONDRAWAREA_XMIN+xOffset))*percentageScrolled)
	  else
		notationEditor_recentScrollX = round(xOffset)
		end
	  end
	
	local currentValidMeasureIndex = currentMeasureIndex
	while currentValidMeasureIndex >= 1 do
	  if measureList[currentValidMeasureIndex][MEASURELISTINDEX_VALIDCURRENTMEASURE] then
		break
		end
	  currentValidMeasureIndex = currentValidMeasureIndex - 1
	  end
	
	if PLAYSTATE == 1 then
	  reaper.ImGui_SetScrollX(ctx, notationEditor_recentScrollX)
	  
	  local boundaryXMin = measureList[currentValidMeasureIndex][MEASURELISTINDEX_MEASUREBOUNDARYXMIN] - notationEditor_recentScrollX + NOTATION_BOUNDARYXMINOFFSET
	  local boundaryXMax = measureList[currentValidMeasureIndex][MEASURELISTINDEX_MEASUREBOUNDARYXMAX] - notationEditor_recentScrollX
	  addRectFilled(drawList, boundaryXMin, NOTATION_YMIN, boundaryXMax, NOTATION_YMAX, CURRENTMEASURECOLOR)
	  end
	  
	local cursorXPos
	if measureList[currentMeasureIndex][MEASURELISTINDEX_MULTIREST] then
	  local lastInvalidMeasureIndex = currentMeasureIndex
	  while lastInvalidMeasureIndex < #measureList do
		if not measureList[lastInvalidMeasureIndex][MEASURELISTINDEX_MULTIREST] then
		  lastInvalidMeasureIndex = lastInvalidMeasureIndex - 1
		  break
		  end
		lastInvalidMeasureIndex = lastInvalidMeasureIndex + 1
		end
	  local cursorBoundaryXMin = measureList[currentValidMeasureIndex][MEASURELISTINDEX_MEASUREBOUNDARYXMIN] - notationEditor_recentScrollX
	  local cursorBoundaryXMax = measureList[lastInvalidMeasureIndex][MEASURELISTINDEX_MEASUREBOUNDARYXMAX] - notationEditor_recentScrollX
	  local cursorBoundaryStartPPQPOS = measureList[currentValidMeasureIndex][MEASURELISTINDEX_PPQPOS]
	  local cursorBoundaryEndPPQPOS
	  if lastInvalidMeasureIndex == #measureList then
		cursorBoundaryEndPPQPOS = endEvtPPQPOS
	  else
		cursorBoundaryEndPPQPOS = measureList[lastInvalidMeasureIndex+1][MEASURELISTINDEX_PPQPOS]
		end
	  cursorXPos = convertRange(cursorPPQPOS, cursorBoundaryStartPPQPOS, cursorBoundaryEndPPQPOS, cursorBoundaryXMin, cursorBoundaryXMax)
	else
	  cursorXPos = currentMeasureData_cursorXPos - notationEditor_recentScrollX
	  end
	addLine(drawList, cursorXPos, NOTATION_YMIN, cursorXPos, NOTATION_YMAX, COLOR_GREEN, 2)
	end
  
  local scrollX = notationEditor_recentScrollX
  
  local mouseX, mouseY = reaper.ImGui_GetMousePos(ctx)
  local isCtrlDown = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Ctrl())
  local isAltDown = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Alt())
  local isShiftDown = reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Mod_Shift())
  
  local isLeftMouseClicked = reaper.ImGui_IsMouseClicked(ctx, 0) and isInRect(mouseX, mouseY, NOTATION_XMIN, notationWindowY, NOTATION_XMAX, NOTATION_YMAX)
  local isLeftMouseDoubleClicked = reaper.ImGui_IsMouseDoubleClicked(ctx, 0) and isInRect(mouseX, mouseY, NOTATION_XMIN, notationWindowY, NOTATION_XMAX, NOTATION_YMAX)
  local isRightMouseClicked = reaper.ImGui_IsMouseClicked(ctx, 1) and isInRect(mouseX, mouseY, NOTATION_XMIN, notationWindowY, NOTATION_XMAX, NOTATION_YMAX)
  local isLeftMouseDown = reaper.ImGui_IsMouseDown(ctx, 0)
  local isRightMouseDown = reaper.ImGui_IsMouseDown(ctx, 1)
  local isLeftMouseReleased = reaper.ImGui_IsMouseReleased(ctx, 0)
  local isRightMouseReleased = reaper.ImGui_IsMouseReleased(ctx, 1)
  
  local isSpacePressed = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Space())
  local isEscPressed = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape())
  local isUpArrowPressed = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_UpArrow())
  local isDownArrowPressed = reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_DownArrow())
  
  local function setClickedItem(identifier, xMin, xMax, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, chord)
	clickedItem = identifier
	clickedItemXMin = xMin
	clickedItemYMin = yMin
	clickedItemXMax = xMax
	clickedItemYMax = yMax
	clickedItemVoiceIndex = voiceIndex
	clickedItemIsRhythmOverride = isRhythmOverride
	clickedItemCurrentRhythmWithoutTuplets = currentRhythmWithoutTuplets
	clickedItemMaxRhythmWithoutTuplets = maxRhythmWithoutTuplets
	clickedItemMinBeat = minBeat
	clickedItemMaxBeat = maxBeat
	clickedItemTupletFactorNum = tupletFactorNum
	clickedItemTupletFactorDenom = tupletFactorDenom
	clickedItemBeatTable = beatTable
	clickedItemTimeSigNum = timeSigNum
	clickedItemTimeSigDenom = timeSigDenom
	clickedItemChord = chord
	
	if voiceIndex == 1 then
	  voice1Filter = true
	  end
	if voiceIndex == 2 then
	  voice2Filter = true
	  end
	end
  
  local function addToSelectedItemList(identifier, xMin, xMax, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, action)
	local clickedData = {identifier, xMin, xMax, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom}
	if action == "add" then
	  tableInsert(masterSelectedItemList, clickedData)
	  end
	if action == "reset" then
	  masterSelectedItemList = {clickedData}
	  end
	end
	
  local function handleItemClicking(hovering, isLeftMouseClicked, identifier, xMin, xMax, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, ppqpos, chord)
	if hovering then
	  if isLeftMouseClicked then
		setClickedItem(identifier, xMin+scrollX, xMax+scrollX, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, chord)
		end
	  end
	  
	if notationGroupSelect and not isInTable(masterSelectedItemList, identifier) then
	  if xMax+scrollX >= notationGroupSelectXMin and xMin+scrollX <= notationGroupSelectXMax and yMax >= notationGroupSelectYMin and yMin <= notationGroupSelectYMax then
		addToSelectedItemList(identifier, xMin+scrollX, xMax+scrollX, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, "add")
		end
	  end
	
	local function updateEditCursorIdentifier(xPos)
	  local distance = math.abs(xPos - editCursorClickedXPos)
	  if distance < editCursorMinXDistance then
		editCursorMinXDistance = distance
		editCursorPPQPOS = ppqpos
		end
	  end
	
	if editCursorClickedXPos and ppqpos then
	  updateEditCursorIdentifier(xMin)
	  updateEditCursorIdentifier(xMax)
	  end
	end
	
  local function drawNotationLayers()
  
	--draw everything
	notationLayer_clef = {}
	notationLayer_notehead = {}
	notationLayer_gracenotehead = {}
	notationLayer_rest = {}
	notationLayer_wholeRest = {}
	notationLayer_multirest_rect = {}
	notationLayer_multirest_line = {}
	notationLayer_multirest_number = {}
	notationLayer_dot = {}
	notationLayer_ghost = {}
	notationLayer_flag = {}
	notationLayer_graceflag = {}
	notationLayer_graceline = {}
	notationLayer_beam = {}
	notationLayer_stem = {}
	notationLayer_legerLine = {}
	notationLayer_tremolo = {}
	notationLayer_buzz = {}
	notationLayer_choke = {}
	notationLayer_tuplet_line = {}
	notationLayer_tuplet_number = {}
	notationLayer_articulation = {}
	notationLayer_tie = {}
	notationLayer_timeSig = {}
	notationLayer_measureLine = {}
	notationLayer_beatNumber = {}
	notationLayer_measureNumber = {}
	notationLayer_tempo = {}
	notationLayer_dynamic = {}
	notationLayer_staffText = {}
	
	restOffsetMeasuresAffectedList = {}
	
	for x=1, #notationDrawList do
	  local data = notationDrawList[x]
	  local category = data[1]
	  
	  local tableToInsert
	  
	  if category == "clef" then
		tableToInsert = notationLayer_clef
		end
	  if category == "notehead" then
		tableToInsert = notationLayer_notehead
		end
	  if category == "gracenotehead" then
		tableToInsert = notationLayer_gracenotehead
		end
	  if category == "rest" then
		tableToInsert = notationLayer_rest
		end
	  if category == "wholeRest" then
		tableToInsert = notationLayer_wholeRest
		end
	  if category == "multirest_rect" then
		tableToInsert = notationLayer_multirest_rect
		end
	  if category == "multirest_line" then
		tableToInsert = notationLayer_multirest_line
		end
	  if category == "multirest_number" then
		tableToInsert = notationLayer_multirest_number
		end
	  if category == "dot" then
		tableToInsert = notationLayer_dot
		end
	  if category == "ghost" then
		tableToInsert = notationLayer_ghost
		end
	  if category == "flag" then
		tableToInsert = notationLayer_flag
		end
	  if category == "graceflag" then
		tableToInsert = notationLayer_graceflag
		end
	  if category == "graceline" then
		tableToInsert = notationLayer_graceline
		end
	  if category == "beam" then
		tableToInsert = notationLayer_beam
		end
	  if category == "stem" then
		tableToInsert = notationLayer_stem
		end
	  if category == "legerLine" then
		tableToInsert = notationLayer_legerLine
		end
	  if category == "tremolo" then
		tableToInsert = notationLayer_tremolo
		end
	  if category == "buzz" then
		tableToInsert = notationLayer_buzz
		end
	  if category == "choke" then
		tableToInsert = notationLayer_choke
		end
	  if category == "tuplet_line" then
		tableToInsert = notationLayer_tuplet_line
		end
	  if category == "tuplet_number" then
		tableToInsert = notationLayer_tuplet_number
		end
	  if category == "articulation" then
		tableToInsert = notationLayer_articulation
		end
	  if category == "tie" then
		tableToInsert = notationLayer_tie
		end
	  if category == "timeSig" then
		tableToInsert = notationLayer_timeSig
		end
	  if category == "measureLine" then
		tableToInsert = notationLayer_measureLine
		end
	  if category == "beatNumber" then
		tableToInsert = notationLayer_beatNumber
		end
	  if category == "measureNumber" then
		tableToInsert = notationLayer_measureNumber
		end
	  if category == "tempo" then
		tableToInsert = notationLayer_tempo
		end
	  if category == "dynamic" then
		tableToInsert = notationLayer_dynamic
		end
	  if category == "staffText" then
		tableToInsert = notationLayer_staffText
		end
		
	  if not tableToInsert then
		error("No valid notation layer table!")
		end
	  
	  tableInsert(tableToInsert, data)
	  end
	
	for x=1, #notationLayer_notehead do
	  local data = notationLayer_notehead[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  local chord = data[7]
	  local chordNoteIndex = data[8]
	  local isRhythmOverride = data[9]
	  local currentRhythmWithoutTuplets = data[10]
	  local maxRhythmWithoutTuplets = data[11]
	  local minBeat = data[12]
	  local maxBeat = data[13]
	  local tupletFactorNum = data[14]
	  local tupletFactorDenom = data[15]
	  local beatTable = data[16]
	  local timeSigNum = data[17]
	  local timeSigDenom = data[18]
	  
	  local chordGlobalData = chord[1]
	  local chordNotes = chord[2]
	  local noteData = chordNotes[chordNoteIndex]
	  local ppqpos = noteData[NOTELISTINDEX_STARTPPQPOS]
	  local voiceIndex = getChordVoiceIndex(chord)
	  
	  local identifier = "layerIndex_" .. x .. " category_notehead"
	  
	  if notationDoubleClickedChordPPQPOS then
		if chordGlobalData[CHORDGLOBALDATAINDEX_PPQPOS] == notationDoubleClickedChordPPQPOS and voiceIndex == notationDoubleClickedChordVoiceIndex then
		  addToSelectedItemList(identifier, xMin+scrollX, xMin+scrollX, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, "add")
		  end
		end
		
	  local hovering = isInRect(mouseX, mouseY, xMin, yMin, xMax, yMax)
	  
	  handleItemClicking(hovering, isLeftMouseClicked, identifier, xMin, xMax, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, ppqpos, chord)
	  
	  local selected = isInTable(filteredSelectedItemList, identifier)
	  
	  local tintColor
	  if selected then
		tintColor = COLOR_SELECTED
	  elseif hovering then
		tintColor = COLOR_HOVERING
		end
		
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  end
	for x=1, #notationLayer_gracenotehead do
	  local data = notationLayer_gracenotehead[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  local chord = data[7]
	  local chordNoteIndex = data[8]
	  
	  local chordGlobalData = chord[1]
	  local chordNotes = chord[2]
	  local noteData = chordNotes[chordNoteIndex]
	  local ppqpos = noteData[NOTELISTINDEX_STARTPPQPOS]
	  local voiceIndex = getChordVoiceIndex(chord)
	  
	  local identifier = "layerIndex_" .. x .. " category_gracenotehead"
	  
	  if notationDoubleClickedChordPPQPOS then
		if chordGlobalData[CHORDGLOBALDATAINDEX_PPQPOS] == notationDoubleClickedChordPPQPOS and voiceIndex == notationDoubleClickedChordVoiceIndex then
		  addToSelectedItemList(identifier, xMin+scrollX, xMin+scrollX, yMin, yMax, voiceIndex, nil, "add")
		  end
		end
		
	  local hovering = isInRect(mouseX, mouseY, xMin, yMin, xMax, yMax)
	  
	  handleItemClicking(hovering, isLeftMouseClicked, identifier, xMin, xMax, yMin, yMax, voiceIndex, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, ppqpos, chord)
	  
	  local selected = isInTable(filteredSelectedItemList, identifier)
	  
	  local tintColor
	  if selected then
		tintColor = COLOR_SELECTED
	  elseif hovering then
		tintColor = COLOR_HOVERING
		end
	  
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  end
	for x=1, #notationLayer_rest do
	  local data = notationLayer_rest[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  local voiceIndex = data[7]
	  local isRhythmOverride = data[8]
	  local currentRhythmWithoutTuplets = data[9]
	  local maxRhythmWithoutTuplets = data[10]
	  local minBeat = data[11]
	  local maxBeat = data[12]
	  local tupletFactorNum = data[13]
	  local tupletFactorDenom = data[14]
	  local beatTable = data[15]
	  local timeSigNum = data[16]
	  local timeSigDenom = data[17]
	  local measureIndex = data[18]
	  
	  local identifier = "layerIndex_" .. x .. " category_rest"
	  
	  local hovering = isInRect(mouseX, mouseY, xMin, yMin, xMax, yMax)

	  handleItemClicking(hovering, isLeftMouseClicked, identifier, xMin, xMax, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom)
	  
	  local selected = isInTable(filteredSelectedItemList, identifier)
	  
	  local tintColor
	  if selected then
		tintColor = COLOR_SELECTED
	  elseif hovering then
		tintColor = COLOR_HOVERING
		end
		
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  
	  if selected then
		local offsetChange
		if isUpArrowPressed then
		  offsetChange = -1
		  end
		if isDownArrowPressed then
		  offsetChange = 1
		  end
		if offsetChange and not isInTable(restOffsetMeasuresAffectedList, measureIndex) then
		  local header = "restoffset" .. voiceIndex .. " "
		  local measurePPQPOS = measureList[measureIndex][MEASURELISTINDEX_PPQPOS]
		  
		  local textEvtID, offset
		  local _, _, _, chartTextCount = reaper.MIDI_CountEvts(notesTake)
		  for testTextEvtID=0, chartTextCount-1 do
			local retval, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(notesTake, testTextEvtID)
			if evtType == TEXT_EVENT and string.sub(msg, 1, #header) == header and ppqpos == measurePPQPOS then
			  textEvtID = testTextEvtID
			  offset = tonumber(string.sub(msg, #header+1, #msg))
			  end
			end
		  
		  local refreshState
		  if textEvtID then
			setTextSysexEvt(notesTake, textEvtID, nil, nil, nil, TEXT_EVENT, header .. round(offset + offsetChange))
			refreshState = REFRESHSTATE_KEEPSELECTIONS
		  else
			insertTextSysexEvt(notesTake, false, false, measurePPQPOS, TEXT_EVENT, header .. offsetChange)
			refreshState = REFRESHSTATE_COMPLETE --just in case
			end
		  tableInsert(restOffsetMeasuresAffectedList, measureIndex)
		  
		  setRefreshState(refreshState)
		  end
		end
	  end
	for x=1, #notationLayer_wholeRest do
	  local data = notationLayer_wholeRest[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  local voiceIndex = data[7]
	  local emptyMeasure = data[8]
	  
	  local tintColor
	  if not emptyMeasure then
		local identifier = "layerIndex_" .. x .. " category_wholeRest"
		
		local hovering = isInRect(mouseX, mouseY, xMin, yMin, xMax, yMax)
		
		handleItemClicking(hovering, isLeftMouseClicked, identifier, xMin, xMax, yMin, yMax, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom)
		
		local selected = isInTable(filteredSelectedItemList, identifier)
		
		if selected then
		  tintColor = COLOR_SELECTED
		elseif hovering then
		  tintColor = COLOR_HOVERING
		  end
		end
		
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  end
	for x=1, #notationLayer_multirest_rect do
	  local data = notationLayer_multirest_rect[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  addRectFilled(drawList, xMin, yMin, xMax, yMax, COLOR_BLACK)
	  end
	for x=1, #notationLayer_multirest_line do
	  local data = notationLayer_multirest_line[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  addLine(drawList, xMin, yMin, xMax, yMax, COLOR_BLACK, 2)
	  end
	for x=1, #notationLayer_multirest_number do
	  local data = notationLayer_multirest_number[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax)
	  end
	for x=1, #notationLayer_dot do
	  local data = notationLayer_dot[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax)
	  end
	for x=1, #notationLayer_ghost do
	  local data = notationLayer_ghost[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax)
	  end
	for x=1, #notationLayer_flag do
	  local data = notationLayer_flag[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  end
	for x=1, #notationLayer_graceflag do
	  local data = notationLayer_graceflag[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addLine(drawList, xMin, yMin, xMax, yMax, COLOR_BLACK, STAFFLINETHICKNESS)
	  end
	for x=1, #notationLayer_graceline do
	  local data = notationLayer_graceline[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  addLine(drawList, xMin, yMin, xMax, yMax, COLOR_BLACK, STAFFLINETHICKNESS)
	  end
	for x=1, #notationLayer_beam do
	  local data = notationLayer_beam[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  addRectFilled(drawList, xMin, yMin, xMax, yMax, COLOR_BLACK)
	  end
	for x=1, #notationLayer_stem do
	  local data = notationLayer_stem[x]
	  local xPos = data[2] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  addLine(drawList, xPos, yMin, xPos, yMax, COLOR_BLACK, STAFFLINETHICKNESS)
	  end
	for x=1, #notationLayer_legerLine do
	  local data = notationLayer_legerLine[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yPos = data[4]
	  addLine(drawList, xMin, yPos, xMax, yPos, COLOR_BLACK, STAFFLINETHICKNESS)  
	  end
	for x=1, #notationLayer_tremolo do
	  local data = notationLayer_tremolo[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  end
	for x=1, #notationLayer_buzz do
	  local data = notationLayer_buzz[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  end
	for x=1, #notationLayer_choke do
	  local data = notationLayer_choke[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1, tintColor)
	  end
	for x=1, #notationLayer_tuplet_line do
	  local data = notationLayer_tuplet_line[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  addLine(drawList, xMin, yMin, xMax, yMax, COLOR_BLACK, STAFFLINETHICKNESS)
	  end
	for x=1, #notationLayer_tuplet_number do
	  local data = notationLayer_tuplet_number[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax)
	  end
	for x=1, #notationLayer_articulation do
	  local data = notationLayer_articulation[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax)
	  end
	for x=1, #notationLayer_tie do
	  local data = notationLayer_tie[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local voiceIndex = data[6]
	  
	  local tieXMin, tieXMax, tieY1, tieY2
	  local TIE_HEIGHT = STAFFSPACEHEIGHT*0.7
	  local TIE_XGAP = STAFFSPACEHEIGHT*0.75
	  local TIE_YGAP = STAFFSPACEHEIGHT/7
	  local tieXPercentage = 0.3
	  local tieYPercentageLeft = 0.9
	  local tieYPercentageRight = 1 - tieYPercentageLeft
	  if voiceIndex == 1 then
		tieXMin = xMin + TIE_XGAP
		tieXMax = xMax - TIE_XGAP*2
		tieY1 = yMin - TIE_YGAP
		tieY2 = tieY1 - TIE_HEIGHT
	  else
		tieXMin = xMin + TIE_XGAP*2
		tieXMax = xMax - TIE_XGAP
		tieY1 = yMax + TIE_YGAP
		tieY2 = tieY1 + TIE_HEIGHT
		tieYPercentageLeft = (-1)*tieYPercentageLeft
		tieYPercentageRight = (-1)*tieYPercentageRight
		end
	  local tieRadius = (tieXMax-tieXMin)/2
	  local centerX = tieXMin + tieRadius
	  
	  reaper.ImGui_DrawList_AddBezierQuadratic(drawList, tieXMin, tieY1, tieXMin+tieRadius*tieXPercentage, tieY1-TIE_HEIGHT*tieYPercentageLeft, centerX, tieY2, COLOR_BLACK, 2)
	  reaper.ImGui_DrawList_AddBezierQuadratic(drawList, centerX, tieY2, centerX+tieRadius*(1-tieXPercentage), tieY2+TIE_HEIGHT*tieYPercentageRight, tieXMax, tieY1, COLOR_BLACK, 2)
	  end
	for x=1, #notationLayer_timeSig do
	  local data = notationLayer_timeSig[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax)
	  end
	for x=1, #notationLayer_measureLine do
	  local data = notationLayer_measureLine[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1)
	  end
	for x=1, #notationLayer_beatNumber do
	  local data = notationLayer_beatNumber[x]
	  local textCenterX = data[2]
	  local beatNum = data[4]
	  local isStrongBeat = data[5]
	  local measureIndex = data[6]
	  
	  local currentValidBeatMeasureIndex, beatMeasureDiff
	  if currentMeasureIndex then
		currentValidBeatMeasureIndex = validBeatMeasureList[binarySearchClosestOrLess(validBeatMeasureList, currentMeasureIndex)]
		beatMeasureDiff = round(currentMeasureIndex - currentValidBeatMeasureIndex)
		end
	  local isCurrentMeasure = (currentValidBeatMeasureIndex == measureIndex)
	  
	  local font
	  if isStrongBeat then
		font = strongBeatFont
	  else
		font = weakBeatFont
		end
	  
	  local color
	  if beatNum > 1000 then
		color = COLOR_HIDDEN
	  elseif not isCurrentMeasure then
		color = COLOR_INACTIVEBEAT
	  elseif beatNum == currentMeasureData_flooredCurrentBeat then
		color = COLOR_YELLOW
	  else
		color = COLOR_WHITE
		end
	  
	  reaper.ImGui_PushFont(ctx, font)
	  
	  local beatText = round(beatNum+1)
	  local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, beatText)
  
	  local xPos = textCenterX - textSizeX/2
	  local yPos = NOTATION_YMAX-notationWindowY + ((notationWindowY+notationWindowSizeY)-NOTATION_YMAX)/2 - textSizeY/2
	  
	  reaper.ImGui_SetCursorPosX(ctx, xPos)
	  reaper.ImGui_SetCursorPosY(ctx, yPos)
	  reaper.ImGui_TextColored(ctx, color, beatText)
	  reaper.ImGui_PopFont(ctx)
	  end
	for x=1, #notationLayer_measureNumber do
	  local data = notationLayer_measureNumber[x]
	  local centerX = data[2]
	  local text = data[4]
  
	  local textSizeX = reaper.ImGui_CalcTextSize(ctx, text)
	  local xPos = centerX - textSizeX/2
	  local yPos = getStaffLinePosition(2)-notationWindowY - 20
	  
	  reaper.ImGui_PushFont(ctx, measureNumberFont)
	  reaper.ImGui_SetCursorPosX(ctx, xPos)
	  reaper.ImGui_SetCursorPosY(ctx, yPos)
	  reaper.ImGui_TextColored(ctx, COLOR_BLACK, text)
	  reaper.ImGui_PopFont(ctx)
	  end
	for x=1, #notationLayer_tempo do
	  local data = notationLayer_tempo[x]
	  local xOffset = data[2] - scrollX
	  local imgData = data[3]
	  
	  local yOffset = getStaffLinePosition(MAXSTAFFLINE-2)
	  
	  for x=1, #imgData do
		local data = imgData[x]
		
		local img = data[1]
		local xMin = data[2] + xOffset
		local yMin = data[3] + yOffset
		local xMax = data[4] + xOffset
		local yMax = data[5] + yOffset
		
		addImage(drawList, img, xMin, yMin, xMax, yMax)
		end
	  end
	for x=1, #notationLayer_dynamic do
	  local data = notationLayer_dynamic[x]
	  local xMin = data[2] - scrollX
	  local xMax = data[3] - scrollX
	  local yMin = data[4]
	  local yMax = data[5]
	  local centerY = data[6]
	  local startPPQPOS = data[7]
	  local offset = data[8]
	  local img = data[9]
	  
	  local identifier = "layerIndex_" .. x .. " category_dynamic"
	  
	  local hovering = isInRect(mouseX, mouseY, xMin, yMin, xMax, yMax)
	  
	  handleItemClicking(hovering, isLeftMouseClicked, identifier, xMin, xMax, yMin, yMax)
	  
	  local selected = isInTable(filteredSelectedItemList, identifier)
	  
	  local tintColor
	  if selected then
		tintColor = COLOR_SELECTED
	  elseif hovering then
		tintColor = COLOR_HOVERING
		end
		
	  if type(img) == "string" then
		local dynamic = img
		local color = COLOR_BLACK
		local thickness = STAFFLINETHICKNESS
		local force = true
		
		if dynamic == "crescendo" then
		  addLine(drawList, xMin, centerY, xMax, yMin, tintColor, thickness, force)
		  addLine(drawList, xMin, centerY, xMax, yMax, tintColor, thickness, force)
		  end
		if dynamic == "diminuendo" or dynamic == "decrescendo" then
		  addLine(drawList, xMin, yMin, xMax, centerY, tintColor, thickness, force)
		  addLine(drawList, xMin, yMax, xMax, centerY, tintColor, thickness, force)
		  end
	  else
		xMin = xMin - STAFFSPACEHEIGHT
		xMax = xMax - STAFFSPACEHEIGHT
		addImage(drawList, img, xMin, yMin, xMax, yMax, nil, nil, nil, nil, tintColor)
		end
	  
	  if selected then
		--used to be offset change
		end
	  end
	for x=1, #notationLayer_staffText do
	  reaper.ImGui_PushFont(ctx, staffTextFont)
	  
	  local data = notationLayer_staffText[x]
	  local xPos = data[2]
	  local yPos = data[4]
	  local staffTextListIndex = data[6]
	  
	  local staffTextData = staffTextList[staffTextListIndex]
	  
	  local text = staffTextData[STAFFTEXTLISTINDEX_TEXT]
	  local ppqpos = staffTextData[STAFFTEXTLISTINDEX_PPQPOS]
	  local offset = staffTextData[STAFFTEXTLISTINDEX_OFFSET]
	  local textEvtID = staffTextData[STAFFTEXTLISTINDEX_TEXTEVTID]
	  
	  local textSizeX, textSizeY = reaper.ImGui_CalcTextSize(ctx, text)
	  local textXMin = xPos - STAFFSPACEHEIGHT/2
	  local textYMin = yPos
	  local textXMax = textXMin + textSizeX
	  local textYMax = textYMin + textSizeY
	  
	  local identifier = "layerIndex_" .. x .. " category_staffText"
	  
	  local hovering = isInRect(mouseX, mouseY, textXMin, textYMin, textXMax, textYMax)
	  
	  handleItemClicking(hovering, isLeftMouseClicked, identifier, textXMin, textXMax, textYMin, textYMax)
	  
	  local selected = isInTable(filteredSelectedItemList, identifier)
	  
	  local tintColor
	  if selected then
		tintColor = COLOR_SELECTED
	  elseif hovering then
		tintColor = COLOR_HOVERING
	  else
		tintColor = COLOR_BLACK
		end
		
	  reaper.ImGui_SetCursorPos(ctx, textXMin - notationWindowX, textYMin - notationWindowY)
	  reaper.ImGui_TextColored(ctx, tintColor, text)

	  if selected then
		local offsetChange
		if isUpArrowPressed then
		  offsetChange = -1
		  end
		if isDownArrowPressed then
		  offsetChange = 1
		  end
		if offsetChange then
		  if not offset then
			offset = 0
			end
		  setTextEventParameter(notesTake, textEvtID, "offset", round(offset+offsetChange))
		  setRefreshState(REFRESHSTATE_KEEPSELECTIONS)
		  end
		end
	  
	  reaper.ImGui_PopFont(ctx)
	  end
	
	--hide scrolling notes
	local xMax = NOTATIONDRAWAREA_XMIN+NOTATION_BOUNDARYXMINOFFSET+5
	addRectFilled(drawList, NOTATION_XMIN, NOTATION_YMIN, xMax, NOTATION_YMAX, NOTATION_BGCOLOR)
	addRectFilled(drawList, NOTATION_XMIN, NOTATION_YMAX, xMax, notationWindowY+notationWindowSizeY, COLOR_BLACK)

	drawStaffLines()
	
	for x=1, #notationLayer_clef do
	  local data = notationLayer_clef[x]
	  local xMin = data[2]
	  local xMax = data[3]
	  local yMin = data[4]
	  local yMax = data[5]
	  local img = data[6]
	  local imgFileName = data[7]
	  addImage(drawList, img, xMin, yMin, xMax, yMax, 0, 0, 1, 1)
	  end
	end
  
  local function drawNotationToolbar()
	local movingRight = true
	
	local centerY = notationWindowY + (TOOLBAR_YMAX-notationWindowY)/2
	local buttonRadius = (centerY-notationWindowY)/2
	local buttonYMin = centerY - buttonRadius
	local buttonYMax = centerY + buttonRadius
	local buttonSizeY = buttonYMax - buttonYMin
	local buttonSizeX = buttonSizeY
	
	local buttonPadding = buttonSizeX/3
	local buttonXMin = NOTATION_XMIN + buttonPadding
	
	filteredSelectedItemList = {}
	local selectedCategories = {}
	for x=1, #masterSelectedItemList do
	  local selectedItem = masterSelectedItemList[x]
	  local voiceIndex = selectedItem[6]
	  if (voiceIndex == 1 and voice1Filter) or (voiceIndex == 2 and voice2Filter) or not voiceIndex then
		tableInsert(filteredSelectedItemList, selectedItem)
		local identifier = selectedItem[1]
		local category = getNotationItemData(identifier, "category")
		if not isInTable(selectedCategories, category) then
		  tableInsert(selectedCategories, category)
		  end
		end
	  end
	
	local function padSection()
	  local direction
	  if movingRight then
		direction = 1
	  else
		direction = -1
		end
		
	  buttonXMin = buttonXMin + buttonPadding*2*direction
	  end
	  
	local function toolbarButton(notationHeader, notationLabel, percentageFromCenter, defaultColor, buttonState, yOffsetFromCenter, noRefreshData)
	  local buttonXMax = buttonXMin + buttonSizeX
	  local centerX = buttonXMin + buttonSizeX/2
	  
	  local hovering = isInRect(mouseX, mouseY, buttonXMin, buttonYMin, buttonXMax, buttonYMax)

	  local fileName = notationLabel
	  if notationHeader then
		fileName = notationHeader .. "_" .. fileName
		end
		
	  local color
	  if buttonState == nil then
		color = COLOR_DISABLED
	  elseif hovering then
		if isLeftMouseDown then
		  color = COLOR_CLICKED
		else
		  color = COLOR_HOVERED
		  end
	  elseif buttonState then
		color = COLOR_ON
	  else
		color = defaultColor
		end
	  addRectFilled(drawList, buttonXMin, buttonYMin, buttonXMax, buttonYMax, color)
		
	  local img = getImageFromList(fileName)
	  local imgSizeX, imgSizeY = getImageSize(fileName)
	  local imgAspectRatio = imgSizeX/imgSizeY
	  
	  local xMin = centerX
	  local yMin = buttonYMin + buttonRadius*(1-percentageFromCenter)
	  local yMax = buttonYMax - buttonRadius*(1-percentageFromCenter)
	  local sizeY = yMax - yMin
	  local scalingFactor = sizeY/imgSizeY
	  local sizeX = imgSizeX*scalingFactor
	  local xMax = xMin + sizeX
	  xMin = xMin - sizeX/2
	  xMax = xMax - sizeX/2
	  if yOffsetFromCenter then
		yMin = yMin + buttonRadius*yOffsetFromCenter
		yMax = yMax + buttonRadius*yOffsetFromCenter
		end
		
	  addImage(drawList, img, xMin, yMin, xMax, yMax, nil, nil, nil, nil, COLOR_BLACK)
	  
	  if movingRight then
		buttonXMin = buttonXMax + buttonPadding
	  else
		buttonXMin = buttonXMin - buttonPadding - (buttonXMax - buttonXMin)
		end
		
	  local clickedButton = (isLeftMouseClicked and hovering)
	  if clickedButton then
		setClickedItem("toolbar_" .. fileName, xMin, xMax, yMin, yMax)
		end
		
	  local toolbarButtonActivated = (clickedButton and buttonState ~= nil)
	  if clickedButton and not noRefreshData then
		setRefreshState(REFRESHSTATE_KEEPSELECTIONS)
		end
	  
	  return toolbarButtonActivated
	  end
	
	--rhythms
	local color = TOOLBARCOLOR_RHYTHM
	for x=1, #TOOLBARRHYTHMLIST do
	  local rhythm = TOOLBARRHYTHMLIST[x]
	  local notationHeader, notationLabel, percentageFromCenter, yOffsetFromCenter
	  if rhythm == "dot" then
		notationHeader = "articulation"
		notationLabel = "staccato"
		percentageFromCenter = 0.15
		yOffsetFromCenter = 0.25
	  else
		notationHeader = "note"
		notationLabel = rhythm
		if rhythm == 32 then
		  percentageFromCenter = 0.85
		else
		  percentageFromCenter = 0.8
		  end
		end
		
	  local validItems = {}
	  local buttonState = true
	  for x=1, #filteredSelectedItemList do
		local selectedItem = filteredSelectedItemList[x]
		
		local identifier = selectedItem[1]
		local isRhythmOverride = selectedItem[7]
		local currentRhythmWithoutTuplets = selectedItem[8]
		local maxRhythmWithoutTuplets = selectedItem[9]
		
		local category = getNotationItemData(identifier, "category")
		local layerTable
		if category == "notehead" then
		  layerTable = notationLayer_notehead
		  end
		if category == "rest" then
		  layerTable = notationLayer_rest
		  end
		if layerTable then
		  local rhythmWithoutTuplets
		  if rhythm == "dot" then
			rhythmWithoutTuplets = roundFloatingPoint(currentRhythmWithoutTuplets * 1.5)
		  else
			rhythmWithoutTuplets = roundFloatingPoint(1/rhythm)
			end
		  
		  if rhythmWithoutTuplets <= maxRhythmWithoutTuplets and not isRhythmOverride then
			tableInsert(validItems, selectedItem)

			if rhythmWithoutTuplets ~= currentRhythmWithoutTuplets then
			  buttonState = false
			  end
			end
		  end
		end
	  
	  if #validItems == 0 then
		buttonState = nil
		end

	  if toolbarButton(notationHeader, notationLabel, percentageFromCenter, color, buttonState, yOffsetFromCenter) then
		for x=1, #validItems do
		  local selectedItem = validItems[x]
		  
		  local identifier = selectedItem[1]
		  local voiceIndex = selectedItem[6]
		  local isRhythmOverride = selectedItem[7]
		  local currentRhythmWithoutTuplets = selectedItem[8]
		  local maxRhythmWithoutTuplets = selectedItem[9]
		  local minBeat = selectedItem[10]
		  local maxBeat = selectedItem[11]
		  local tupletFactorNum = selectedItem[12]
		  local tupletFactorDenom = selectedItem[13]
		  local beatTable = selectedItem[14]
		  local timeSigNum = selectedItem[15]
		  local timeSigDenom = selectedItem[16]
		  
		  local rhythmWithoutTuplets
		  if rhythm == "dot" then
			rhythmWithoutTuplets = roundFloatingPoint(currentRhythmWithoutTuplets * 1.5)
		  else
			rhythmWithoutTuplets = roundFloatingPoint(1/rhythm)
			end
		  
		  --TODO: then factor in tuplets
		  local beatLen = roundFloatingPoint(timeSigDenom * rhythmWithoutTuplets * (tupletFactorNum/tupletFactorDenom))
		  local beatToInsert = roundFloatingPoint(minBeat + beatLen)
		  local qnStart = getQNFromBeat(beatTable, minBeat)
		  local qnMiddle = getQNFromBeat(beatTable, beatToInsert)
		  local qnEnd = getQNFromBeat(beatTable, maxBeat)
		  local splitStartPPQPOS = reaper.MIDI_GetPPQPosFromProjQN(notesTake, qnStart)
		  local splitMiddlePPQPOS = reaper.MIDI_GetPPQPosFromProjQN(notesTake, qnMiddle)
		  local splitEndPPQPOS = reaper.MIDI_GetPPQPosFromProjQN(notesTake, qnEnd)
		  
		  if math.abs(qnStart-qnEnd) > 0.0001 then --account for floating point inaccuracies
			local restMIDINoteNum
			for midiNoteNum=127, 0, -1 do
			  local laneOverride = isLaneOverride(midiNoteNum)
			  if laneOverride then
				local laneType = getNoteType(midiNoteNum)
				if laneType == "rhythm" .. voiceIndex then
				  restMIDINoteNum = midiNoteNum
				  break
				  end
				end
			  end
			
			if not restMIDINoteNum then
			  throwError("No valid rest voice " .. voiceIndex .. " lane!")
			  end
			
			--clear out other rest midi notes in lane
			--TODO: binary search optimize
			local _, noteCount = reaper.MIDI_CountEvts(notesTake)
			for noteID=noteCount-1, 0, -1 do
			  local _, _, _, startPPQPOS, endPPQPOS, channel, midiNoteNum = reaper.MIDI_GetNote(notesTake, noteID)
			  if channel == 0 and midiNoteNum == restMIDINoteNum then
				if startPPQPOS >= splitStartPPQPOS and endPPQPOS <= splitEndPPQPOS then
				  reaper.MIDI_DeleteNote(notesTake, noteID)
				elseif startPPQPOS >= splitStartPPQPOS and startPPQPOS <= splitEndPPQPOS then
				  reaper.MIDI_SetNote(notesTake, noteID, nil, nil, splitEndPPQPOS)
				elseif endPPQPOS >= splitStartPPQPOS and endPPQPOS <= splitEndPPQPOS then
				  reaper.MIDI_SetNote(notesTake, noteID, nil, nil, nil, splitStartPPQPOS)
				  end
				end
			  end
			
			--TODO: add rhythmoverride note as well before this
			if splitStartPPQPOS ~= splitMiddlePPQPOS then 
			--reaper.MIDI_InsertNote(notesTake, false, false, splitStartPPQPOS, splitMiddlePPQPOS, 0, restMIDINoteNum, 127)
			  end
			if splitMiddlePPQPOS ~= splitEndPPQPOS then 
			  reaper.MIDI_InsertNote(notesTake, false, false, splitMiddlePPQPOS, splitEndPPQPOS, 0, restMIDINoteNum, 127)
			  end
			end
		  end
		
		setRefreshState(REFRESHSTATE_COMPLETE)
		end
	  end
	padSection()
	
	--articulations
	local function articulationButton(articulationName, percentageFromCenter)
	  local color = TOOLBARCOLOR_ARTICULATION
	  local validItems = {}
	  local buttonState = true
	  for x=1, #filteredSelectedItemList do
		local selectedItem = filteredSelectedItemList[x]
		
		local identifier = selectedItem[1]
		
		local category = getNotationItemData(identifier, "category")
		local layerTable
		if category == "notehead" then
		  layerTable = notationLayer_notehead
		  end
		if category == "gracenotehead" then
		  layerTable = notationLayer_gracenotehead
		  end
		if layerTable then
		  local layerIndex = getNotationItemData(identifier, "layerIndex")
		  local layerData = layerTable[layerIndex]
		  local chord = layerData[7]
		  local chordGlobalData = chord[1]
		  local fakeChord = chordGlobalData[CHORDGLOBALDATAINDEX_FAKECHORD]
		  
		  if not fakeChord then
			tableInsert(validItems, identifier)
					  
			if not doesChordHaveArticulation(chord, articulationName)  then
			  buttonState = false
			  end
			end
		  end
		end
	  
	  if #validItems == 0 then
		buttonState = nil
		end
		
	  if toolbarButton("articulation", articulationName, percentageFromCenter, color, buttonState) then
		for x=1, #validItems do
		  local identifier = validItems[x]
		  local category = getNotationItemData(identifier, "category")
		  local layerTable
		  if category == "notehead" then
			layerTable = notationLayer_notehead
			end
		  if category == "gracenotehead" then
			layerTable = notationLayer_gracenotehead
			end
		
		  local layerIndex = getNotationItemData(identifier, "layerIndex")
		  local layerData = layerTable[layerIndex]
		  local chord = layerData[7]
		  
		  if string.sub(articulationName, 1, 8) == "sticking" then
			local stick = string.sub(articulationName, 9, 9)
			local oppositeStick
			if stick == "L" then
			  oppositeStick = "R"
			else
			  oppositeStick = "L"
			  end
			if not buttonState and doesChordHaveArticulation(chord, "sticking" .. oppositeStick) then --if adding LR
			  setArticulation(chord, "sticking" .. oppositeStick, false)
			  setArticulation(chord, "stickingLR", true)
			elseif buttonState and doesChordHaveArticulation(chord, "stickingLR") then --if removing LR to either L or R
			  setArticulation(chord, "stickingLR", false)
			  setArticulation(chord, "sticking" .. oppositeStick, true)
			else
			  setArticulation(chord, articulationName, not buttonState)
			  end
		  else
			setArticulation(chord, articulationName, not buttonState)
			end
		  end
		end
	  end
	  
	for x=4, #VALID_ARTICULATION_LIST do --skip stickings
	  local articulationData = VALID_ARTICULATION_LIST[x]
	  local articulationName = articulationData[1]
	  local percentageFromCenter = articulationData[3]
	  articulationButton(articulationName, percentageFromCenter)
	  end
	padSection()
	
	for x=1, 2 do --stickings
	  local articulationData = VALID_ARTICULATION_LIST[x]
	  local articulationName = articulationData[1]
	  local percentageFromCenter = articulationData[3]
	  articulationButton(articulationName, percentageFromCenter)
	  end
	padSection()
	
	local color = TOOLBARCOLOR_GHOST
	local validItems = {}
	local buttonState = true
	for x=1, #filteredSelectedItemList do
	  local selectedItem = filteredSelectedItemList[x]
	  
	  local identifier = selectedItem[1]
	  
	  local category = getNotationItemData(identifier, "category")
	  local layerTable
	  if category == "notehead" then
		layerTable = notationLayer_notehead
		end
	  if category == "gracenotehead" then
		layerTable = notationLayer_gracenotehead
		end
	  if layerTable then
		local layerIndex = getNotationItemData(identifier, "layerIndex")
		local layerData = layerTable[layerIndex]
		local chord = layerData[7]
		local chordGlobalData = chord[1]
		local fakeChord = chordGlobalData[CHORDGLOBALDATAINDEX_FAKECHORD]
		
		if not fakeChord then
		  tableInsert(validItems, identifier)
		  local chordNoteIndex = layerData[8]
		  
		  local chordNotes = chord[2]
		  local noteData = chordNotes[chordNoteIndex]
		  
		  if not isNoteGhost(noteData) then
			buttonState = false
			end
		  end
		end
	  end
	
	if #validItems == 0 then
	  buttonState = nil
	  end
	  
	if toolbarButton(nil, "ghosttoolbar", 0.75, color, buttonState) then
	  for x=1, #validItems do
		local identifier = validItems[x]
		local category = getNotationItemData(identifier, "category")
		local layerTable
		if category == "notehead" then
		  layerTable = notationLayer_notehead
		  end
		if category == "gracenotehead" then
		  layerTable = notationLayer_gracenotehead
		  end

		local layerIndex = getNotationItemData(identifier, "layerIndex")
		local layerData = layerTable[layerIndex]
		local chord = layerData[7]
		local chordNoteIndex = layerData[8]
		
		local chordNotes = chord[2]
		local noteData = chordNotes[chordNoteIndex]

		setNoteGhost(noteData, not buttonState)
		end
	  end    
	padSection()
	
	--sustains
	local function sustainButton(rollType, percentageFromCenter)
	  local color = TOOLBARCOLOR_SUSTAIN
	  local validItems = {}
	  local buttonState = true
	  for x=1, #filteredSelectedItemList do
		local selectedItem = filteredSelectedItemList[x]
		
		local identifier = selectedItem[1]
		local currentRhythmWithoutTuplets = selectedItem[8]
		
		local category = getNotationItemData(identifier, "category")
		local layerTable
		if category == "notehead" then
		  layerTable = notationLayer_notehead
		  end
	
		if layerTable then
		  local layerIndex = getNotationItemData(identifier, "layerIndex")
		  local layerData = layerTable[layerIndex]
		  local chord = layerData[7]
		  local chordGlobalData = chord[1]
		  local chordRollType = chordGlobalData[CHORDGLOBALDATAINDEX_ROLL]
		  local hasExtraTie = chordGlobalData[CHORDGLOBALDATAINDEX_EXTRATIE]
		  local fakeChord = chordGlobalData[CHORDGLOBALDATAINDEX_FAKECHORD]
		  
		  if not fakeChord and chordRollType then
			tableInsert(validItems, identifier)
			if rollType == "tie" then
			  if not hasExtraTie then
				buttonState = false
				end
			elseif chordRollType ~= rollType then
			  buttonState = false
			  end
			end
		  end
		end
					
	  if #validItems == 0 then
		buttonState = nil
		end
	  
	  if toolbarButton(nil, rollType, percentageFromCenter, color, buttonState) then
		if buttonState then
		  beamState = nil
		  end
		for x=1, #validItems do
		  local identifier = validItems[x]
		  local category = getNotationItemData(identifier, "category")
		  local layerTable
		  if category == "notehead" then
			layerTable = notationLayer_notehead
			end
	
		  local layerIndex = getNotationItemData(identifier, "layerIndex")
		  local layerData = layerTable[layerIndex]
		  local chord = layerData[7]
		  local chordGlobalData = chord[1]
		  local chordStartPPQPOS = chordGlobalData[CHORDGLOBALDATAINDEX_PPQPOS]
		  local voiceIndex = chordGlobalData[CHORDGLOBALDATAINDEX_VOICEINDEX]
		  local sustainMIDINoteNum = getSustainMIDINoteNum(voiceIndex)
		  local headerWithUnderscore, val, prevVal
		  if rollType ~= "tie" then
			headerWithUnderscore = "roll"
			end
		  if buttonState then
			if rollType == "tie" then
			  prevVal = "tie"
			else
			  val = "none"
			  end
		  else
			val = rollType
			end
		  setNotationTextEventParameter(chordStartPPQPOS, 0, sustainMIDINoteNum, headerWithUnderscore, val, prevVal)
		  end
		end
	  end
	sustainButton("tremolo", 0.85)
	sustainButton("buzz", 0.5)
	sustainButton("tie", 0.2)
	padSection()
	
	local color = TOOLBARCOLOR_BEAM
	local percentageFromCenter = 0.9
	for x=1, #VALID_BEAM_LIST do
	  local beamState = VALID_BEAM_LIST[x]
	  local notationHeader, notationLabel
	  if beamState == "none" then
		notationHeader = "note"
		notationLabel = 16
	  else
		notationHeader = "beam"
		notationLabel = beamState
		end
	  
	  local validItems = {}
	  local buttonState = true
	  for x=1, #filteredSelectedItemList do
		local selectedItem = filteredSelectedItemList[x]
		
		local identifier = selectedItem[1]
		local currentRhythmWithoutTuplets = selectedItem[8]
		
		local category = getNotationItemData(identifier, "category")
		local layerTable
		if category == "notehead" then
		  layerTable = notationLayer_notehead
		  end

		if layerTable then
		  if currentRhythmWithoutTuplets < 0.25 then
			tableInsert(validItems, identifier)
			
			local layerIndex = getNotationItemData(identifier, "layerIndex")
			local layerData = layerTable[layerIndex]
			local chord = layerData[7]
			
			local beamOverride = getBeamOverride(chord)
			
			if beamOverride ~= beamState then
			  buttonState = false
			  end
			end
		  end
		end
	  
	  if #validItems == 0 then
		buttonState = nil
		end
		
	  if toolbarButton(notationHeader, notationLabel, percentageFromCenter, color, buttonState) then
		if buttonState then
		  beamState = nil
		  end
		for x=1, #validItems do
		  local identifier = validItems[x]
		  local category = getNotationItemData(identifier, "category")
		  local layerTable
		  if category == "notehead" then
			layerTable = notationLayer_notehead
			end

		  local layerIndex = getNotationItemData(identifier, "layerIndex")
		  local layerData = layerTable[layerIndex]
		  local chord = layerData[7]
		  
		  setBeam(chord, beamState)
		  end
		end
	  end
	padSection()
	
	local color = TOOLBARCOLOR_GREEN
	local percentageFromCenter = 0.7
	if toolbarButton("tempo", 1, percentageFromCenter, color, voice1Filter) then
	  voice1Filter = not voice1Filter
	  if not voice1Filter then
		voice2Filter = true
		end
	  end
	if toolbarButton("tempo", 2, percentageFromCenter, color, voice2Filter) then
	  voice2Filter = not voice2Filter
	  if not voice2Filter then
		voice1Filter = true
		end
	  end
	padSection()
	
	---
	
	movingRight = false
	buttonXMin = NOTATION_XMAX - buttonPadding - buttonSizeX
	
	local color = TOOLBARCOLOR_GREEN
	if toolbarButton(nil, "arrow", 0.5, color, notationEditor_followPage, nil, true) then
	  notationEditor_followPage = not notationEditor_followPage
	  end
	padSection()
	
	local color = COLOR_WHITE
	local buttonState
	if NUMSUCCESSFULMEASURES == #measureList then
	  buttonState = false
	  end
	if toolbarButton(nil, "musescore", 0.95, color, buttonState, nil, true) then
	  --TODO: open file in musescore
	  end
	padSection()
	
	end
   
  drawNotationLayers()
  
  drawNotationToolbar()
  
  notationGroupSelect = false
  notationDoubleClickedChordPPQPOS = nil
  notationDoubleClickedChordVoiceIndex = nil
  
  if editCursorPPQPOS then
	local time = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, editCursorPPQPOS)
	if PLAYSTATE == 1 then
	  reaper.SetEditCurPos(time, false, true)
	else
	  reaper.SetEditCurPos(time, false, false)
	  end
	editCursorClickedXPos = nil
	editCursorPPQPOS = nil
	end
	
  if clickedItem then
	local clickedCategory = getNotationItemData(clickedItem, "category")

	local tableIndex = isInTable(masterSelectedItemList, clickedItem)
	if tableIndex then
	  if isCtrlDown then
		table.remove(masterSelectedItemList, tableIndex)
	  else
		if isLeftMouseDoubleClicked and (clickedCategory == "notehead" or clickedCategory == "gracenotehead") then
		  local chordGlobalData = clickedItemChord[1]
		  notationDoubleClickedChordPPQPOS = chordGlobalData[CHORDGLOBALDATAINDEX_PPQPOS]
		  notationDoubleClickedChordVoiceIndex = clickedItemVoiceIndex
		  end
		end
	else
	  if isCtrlDown or isShiftDown then
		addToSelectedItemList(clickedItem, clickedItemXMin, clickedItemYMin, clickedItemXMax, clickedItemYMax, clickedItemVoiceIndex, clickedItemIsRhythmOverride, clickedItemCurrentRhythmWithoutTuplets, clickedItemMaxRhythmWithoutTuplets, clickedItemMinBeat, clickedItemMaxBeat, clickedItemTupletFactorNum, clickedItemTupletFactorDenom, clickedItemBeatTable, clickedItemTimeSigNum, clickedItemTimeSigDenom, "add")
	  else
		addToSelectedItemList(clickedItem, clickedItemXMin, clickedItemYMin, clickedItemXMax, clickedItemYMax, clickedItemVoiceIndex, clickedItemIsRhythmOverride, clickedItemCurrentRhythmWithoutTuplets, clickedItemMaxRhythmWithoutTuplets, clickedItemMinBeat, clickedItemMaxBeat, clickedItemTupletFactorNum, clickedItemTupletFactorDenom, clickedItemBeatTable, clickedItemTimeSigNum, clickedItemTimeSigDenom, "reset")
		end
	  
	  if isShiftDown then
		notationGroupSelect = true
		notationGroupSelectXMin = getExtremeValueInTableList(masterSelectedItemList, "min", 2)
		notationGroupSelectYMin = getExtremeValueInTableList(masterSelectedItemList, "min", 3)
		notationGroupSelectXMax = getExtremeValueInTableList(masterSelectedItemList, "max", 4)
		notationGroupSelectYMax = getExtremeValueInTableList(masterSelectedItemList, "max", 5)
		end
	  end

  elseif isLeftMouseClicked then
	masterSelectedItemList = {}
	
	--move edit cursor
	if isInRect(mouseX, mouseY, NOTATION_XMIN, NOTATION_YMIN, NOTATION_XMAX, NOTATION_YMAX) then
	  editCursorClickedXPos = mouseX
	  editCursorMinXDistance = math.huge
	  end
	end
  
  if isRightMouseClicked then
	notationGroupSelectXMin = mouseX
	notationGroupSelectYMin = mouseY
	end
  if isRightMouseDown then
	notationGroupSelectXMax = mouseX
	notationGroupSelectYMax = mouseY
	if notationGroupSelectXMin and notationGroupSelectYMin and notationGroupSelectXMax and notationGroupSelectYMax then
	  addRectFilled(drawList, notationGroupSelectXMin, notationGroupSelectYMin, notationGroupSelectXMax, notationGroupSelectYMax, hexColor(50, 50, 50, 100))
	  end
	end
  if isRightMouseReleased then
	if notationGroupSelectXMin and notationGroupSelectYMin and notationGroupSelectXMax and notationGroupSelectYMax then
	  notationGroupSelectXMin = notationGroupSelectXMin + scrollX
	  notationGroupSelectXMax = notationGroupSelectXMax + scrollX
	  if notationGroupSelectXMin > notationGroupSelectXMax then
		local tempXMin = notationGroupSelectXMin
		notationGroupSelectXMin = notationGroupSelectXMax
		notationGroupSelectXMax = tempXMin
		end
	  if notationGroupSelectYMin > notationGroupSelectYMax then
		local tempYMin = notationGroupSelectYMin
		notationGroupSelectYMin = notationGroupSelectYMax
		notationGroupSelectYMax = tempYMin
		end
	  
	  if not (isCtrlDown or isShiftDown) then
		masterSelectedItemList = {}
		end
		
	  notationGroupSelect = true
	  end
	end
  
  if isSpacePressed then
	notationEditor_changedPlayState = true
	notationEditor_recentScrollX = nil
	end
  if isEscPressed then
	masterSelectedItemList = {}
	end
  
  end

--TODO: error if any time sig has a num/denom<1, or if a decimal

function getConfigTextEventID(midiNoteNum)
  local midiNoteNumStr = midiNoteNum .. " "
  
  local textEvtID = 0
  while true do
	local retval, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(configTake, textEvtID)
	if not retval then
	  break
	  end
	
	if evtType == TEXT_EVENT and isConfigEvent(msg) then
	  if string.sub(msg, 8, 8+#midiNoteNumStr-1) == midiNoteNumStr then
		return textEvtID
		end
	  end
	
	textEvtID = textEvtID + 1
	end
  end

function getDefaultStateParameter(stateIndex)
  if stateIndex == STATEINDEX_GEM then return "circle" end
  if stateIndex == STATEINDEX_COLOR then return -1 end
  if stateIndex == STATEINDEX_NOTEHEAD then return "normal" end
  if stateIndex == STATEINDEX_STAFFLINE then return 0 end
  if stateIndex == STATEINDEX_ARTICULATION then return "none" end
  if stateIndex == STATEINDEX_HHPEDAL then return "none" end
  end

function getStateHeader(stateIndex)
  if stateIndex == STATEINDEX_GEM then return "gem" end
  if stateIndex == STATEINDEX_COLOR then return "color" end
  if stateIndex == STATEINDEX_NOTEHEAD then return "notehead" end
  if stateIndex == STATEINDEX_STAFFLINE then return "staffline" end
  if stateIndex == STATEINDEX_ARTICULATION then return "articulation" end
  if stateIndex == STATEINDEX_HHPEDAL then return "hhpedal" end
  end
  
function addNote(midiNoteNum)
  insertTextSysexEvt(configTake, false, false, 0, TEXT_EVENT, "config_" .. round(midiNoteNum) .. " \"(new note)\" {0 \"normal\" staffline_0}")
  end

function deleteNote(midiNoteNum)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
	throwError("No config text event ID! " .. midiNoteNum)
	end
  
  deleteTextSysexEvt(configTake, textEvtID)
  end

function setNoteMIDINumber(originalMIDINoteNum, newMIDINoteNum)
  reaper.PreventUIRefresh(1)
  
  local textEvtID = 0
  while true do
	local retval, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(configTake, textEvtID)
	if not retval then
	  break
	  end
	
	if evtType == TEXT_EVENT and isConfigEvent(msg) then
	  local spaceIndex = string.find(msg, " ")
	  if not spaceIndex then
		throwError("Config error no space: " .. msg)
		end
		
	  local midiNoteNum = tonumber(string.sub(msg, 8, spaceIndex-1))
	  if midiNoteNum == originalMIDINoteNum then
		setTextSysexEvt(configTake, textEvtID, nil, nil, nil, evtType, "config_" .. round(newMIDINoteNum) .. string.sub(msg, spaceIndex, #msg))
		end
	  if midiNoteNum == newMIDINoteNum then
		setTextSysexEvt(configTake, textEvtID, nil, nil, nil, evtType, "config_" .. round(originalMIDINoteNum) .. string.sub(msg, spaceIndex, #msg))
		end
	  end
	  
	textEvtID = textEvtID + 1
	end
  
  local _, chartNoteCount = reaper.MIDI_CountEvts(notesTake)
  local originalNoteList, newNoteList = {}, {}
  local originalNotationTextEvtList, newNotationTextEvtList = {}, {}
  
  for noteID=chartNoteCount-1, 0, -1 do
	local _, selected, muted, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(notesTake, noteID)
	local noteList, notationTextEvtList, replacedMIDINoteNum
	if midiNoteNum == originalMIDINoteNum then
	  noteList = originalNoteList
	  notationTextEvtList = originalNotationTextEvtList
	  replacedMIDINoteNum = newMIDINoteNum
	  end
	if midiNoteNum == newMIDINoteNum then
	  noteList = newNoteList
	  notationTextEvtList = newNotationTextEvtList
	  replacedMIDINoteNum = originalMIDINoteNum
	  end
	  
	if noteList then
	  local notationTextEvtID = getNotationTextEventID(startPPQPOS, channel, midiNoteNum)
	  if notationTextEvtID then
		local _, selected, muted, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(notesTake, notationTextEvtID)
		local spaceIndexStart = string.find(msg, " ", 6)
		local spaceIndexEnd = string.find(msg, " ", spaceIndexStart+1)
		local replacedMsg = string.sub(msg, 1, spaceIndexStart) .. replacedMIDINoteNum .. string.sub(msg, spaceIndexEnd, #msg)
		
		local textEvtData = {selected, muted, ppqpos, evtType, replacedMsg}
		tableInsert(notationTextEvtList, textEvtData)
		deleteTextSysexEvt(notesTake, notationTextEvtID)
		end
		
	  local noteData = {selected, muted, startPPQPOS, endPPQPOS, channel, replacedMIDINoteNum, velocity}
	  tableInsert(originalNoteList, noteData)
	  reaper.MIDI_DeleteNote(notesTake, noteID)
	  end
	end
  
  local function addNotesBack(noteList)
	for x=1, #noteList do
	  local noteData = noteList[x]
	  
	  local selected = noteData[1]
	  local muted = noteData[2]
	  local startPPQPOS = noteData[3]
	  local endPPQPOS = noteData[4]
	  local channel = noteData[5]
	  local midiNoteNum = noteData[6]
	  local velocity = noteData[7]
	  
	  reaper.MIDI_InsertNote(notesTake, selected, muted, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity, true)
	  end
	end
  
  local function addTextEvtsBack(notationTextEvtList)
	for x=1, #notationTextEvtList do
	  local textEvtData = notationTextEvtList[x]
	  
	  local selected = textEvtData[1]
	  local muted = textEvtData[2]
	  local ppqpos = textEvtData[3]
	  local evtType = textEvtData[4]
	  local msg = textEvtData[5]
	  
	  insertTextSysexEvt(notesTake, selected, muted, ppqpos, evtType, msg)
	  end
	end
	  
  addNotesBack(originalNoteList)
  addNotesBack(newNoteList)
  
  addTextEvtsBack(originalNotationTextEvtList)
  addTextEvtsBack(newNotationTextEvtList)
  
  reaper.MIDI_Sort(notesTake)

  reaper.PreventUIRefresh(-1)
  end
  
function getNoteTypeSubTable(noteType)
  for x=1, #noteTypeTable do
	if noteTypeTable[x][1] == noteType then
	  return noteTypeTable[x]
	  end
	end
  end
  
function getRequiredNoteStateHeaders(noteType)
  return getNoteTypeSubTable(noteType)[2]
  end

function getRequiredNotePropertyHeaders(noteType)
  return getNoteTypeSubTable(noteType)[3]
  end
  
function drawConfigSettings()
  if checkError(ERROR_INVALIDREAPERSETUP) then return end
  
  local isLeftMouseDown = reaper.ImGui_IsMouseDown(ctx, 0)
	
  local white_key_color = 80
  local black_key_color = 40
  local rectHeight = 25
  local yOffset = 80
  
  local arrowUpPos = 4
  local arrowDownPos = 30
  local midiNoteNumPos = 60
  local collapsingHeaderPos = 105
  local xMin = chartWindowX + midiNoteNumPos-4
  local xMax = chartWindowX + chartWindowSizeX-18
  
  local SMALLBUTTONSIZE = 25
  
  local function notePropertyWidget(midiNoteNum, propertyHeader)
	reaper.ImGui_SetNextItemWidth(ctx, 70)
	local currentVal = getNoteProperty(midiNoteNum, propertyHeader)
	local propertyDisplayName = propertyHeader --TODO
	local retval, val = reaper.ImGui_InputText(ctx, propertyDisplayName .. "##NOTEPROPERTYFIELD" .. midiNoteNum, currentVal, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
	if retval then
	  local isValid = true
	  
	  if propertyHeader == "cc" then
		val = tonumber(val)
		if val then
		  val = round(val)
		  val = math.max(val, 0)
		  val = math.min(val, 119)
		else
		  isValid = false
		  end
		end
	  
	  if isValid then
		local textEvtID = getConfigTextEventID(midiNoteNum)
		setTextEventParameter(configTake, textEvtID, propertyHeader, val)
		end
	  end
	end
  
  local function noteStateWidget(midiNoteNum, stateHeader)
	reaper.ImGui_SetNextItemWidth(ctx, 30)
	local currentChannel
	for channel=0, 15 do
	  local val = getNoteState(midiNoteNum, channel)
	  if val == stateHeader then
		currentChannel = round(channel)
		break
		end
	  end
	  
	local retval, newChannel = reaper.ImGui_InputText(ctx, stateHeader .. "##NOTESTATEFIELD" .. midiNoteNum, currentChannel+1, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
	if retval then
	  local isValid = true
	  
	  newChannel = tonumber(newChannel)
	  if newChannel then
		newChannel = round(newChannel)
		newChannel = math.max(newChannel, 1)
		newChannel = math.min(newChannel, 16)
		newChannel = newChannel - 1
	  else
		isValid = false
		end
	  
	  if isValid then
		local textEvtID = getConfigTextEventID(midiNoteNum)
		setTextEventParameter(configTake, textEvtID, currentChannel, nil)
		setTextEventParameter(configTake, textEvtID, newChannel, stateHeader)
		end
	  end
	end
	
  -------------
  
  for midiNoteNum=127, 0, -1 do
	local laneOverride = not isLaneNormalNote(midiNoteNum)
	local noteType = getNoteType(midiNoteNum)
	local midiName = getNoteName(midiNoteNum)

	if midiName then
	  --add arrow buttons
	  if midiNoteNum < 127 then
		reaper.ImGui_SetCursorPosX(ctx, arrowUpPos)
		reaper.ImGui_SetNextItemWidth(ctx, ARROW_BUTTON_WIDTH)
		if button(COLOR_ARROWBUTTON, COLOR_ARROWBUTTON_HOVERED, COLOR_ARROWBUTTON_ACTIVE, "##NOTEORDER_ARROWUP" .. midiNoteNum, 2) then
		  setNoteMIDINumber(midiNoteNum, midiNoteNum+1)
		  setRefreshState(REFRESHSTATE_COMPLETE)
		  end
		reaper.ImGui_SameLine(ctx)
		end
	  if midiNoteNum > 0 then
		reaper.ImGui_SetCursorPosX(ctx, arrowDownPos)
		reaper.ImGui_SetNextItemWidth(ctx, ARROW_BUTTON_WIDTH)
		if button(COLOR_ARROWBUTTON, COLOR_ARROWBUTTON_HOVERED, COLOR_ARROWBUTTON_ACTIVE, "##NOTEORDER_ARROWDOWN" .. midiNoteNum, 3) then
		  setNoteMIDINumber(midiNoteNum, midiNoteNum-1)
		  setRefreshState(REFRESHSTATE_COMPLETE)
		  end
		end
	  reaper.ImGui_SameLine(ctx)
	  end
	
	reaper.ImGui_SetCursorPosX(ctx, midiNoteNumPos)
	reaper.ImGui_TextColored(ctx, COLOR_WHITE, "(" .. floor(midiNoteNum) .. ")")
	
	reaper.ImGui_SameLine(ctx)
	reaper.ImGui_SetCursorPosX(ctx, collapsingHeaderPos)
	reaper.ImGui_SetNextItemWidth(ctx, SMALLBUTTONSIZE)
	
	if midiName then
	  if not laneOverride then
		--delete note button
		if button(COLOR_DELETE, COLOR_DELETE_HOVERED, COLOR_DELETE_ACTIVE, "X##DELETENOTEBUTTON" .. midiNoteNum) then
		  deleteNote(midiNoteNum)
		  setRefreshState(REFRESHSTATE_COMPLETE)
		  end
		reaper.ImGui_SameLine(ctx)
		end
	  
	  reaper.ImGui_SetCursorPosX(ctx, collapsingHeaderPos+24)
	  if collapsingHeader(midiName .. "##COLLAPSINGHEADER" .. midiNoteNum) then
		reaper.ImGui_SetCursorPosX(ctx, collapsingHeaderPos)
		reaper.ImGui_SetNextItemWidth(ctx, 120)
		local retval, val = reaper.ImGui_InputText(ctx, "##NOTENAMETEXTFIELD" .. midiNoteNum, midiName, reaper.ImGui_InputTextFlags_EnterReturnsTrue())
		if retval and #val > 0 and doesNotContainSpecialChars(val) then
		  setNoteName(midiNoteNum, val)
		  setRefreshState(REFRESHSTATE_COMPLETE)
		  end
		reaper.ImGui_SameLine(ctx)
		local label = noteType
		local voiceIndex = tonumber(string.sub(noteType, #noteType, #noteType))
		if voiceIndex then
		  local voiceText
		  if voiceIndex == 1 then
			voiceText = "upper voice"
		  else
			voiceText = "lower voice"
			end
		  label =  string.sub(label, 1, #label-1) .. " (" .. voiceText .. ")"
		  end
		reaper.ImGui_TextColored(ctx, COLOR_WHITE, label)
		end
	else
	
	  --add note button
	  if button(COLOR_ADD, COLOR_ADD_HOVERED, COLOR_ADD_ACTIVE, "+##ADDNOTEBUTTON" .. midiNoteNum) then
		addNote(midiNoteNum)
		setRefreshState(REFRESHSTATE_COMPLETE)
		end
	  end
	end
  
  local extList = "Text Files (*.txt)\0*.txt\0\0"
  local dir = getConfigurationsDirectory()
  
  if button(COLOR_SAVE, COLOR_SAVE_HOVERED, COLOR_SAVE_ACTIVE, "Save##SAVECONFIG") then
	local retval, filePath = reaper.JS_Dialog_BrowseForSaveFile("Save Configuration", dir, "newConfig.txt", extList)
	if retval == 1 then
	  if getFileExtension(filePath) ~= "txt" then
		local dotIndex = string.find(filePath, ".")
		if dotIndex then
		  filePath = string.sub(filePath, 1, dotIndex) .. "txt"
		else
		  filePath = filePath .. ".txt"
		  end
		end
	  
	  local strTable = {}
	  for midiNoteNum=0, 127 do
		local textEvtID = getConfigTextEventID(midiNoteNum)
		if textEvtID then
		  local _, _, _, _, _, msg = reaper.MIDI_GetTextSysexEvt(configTake, textEvtID)
		  tableInsert(strTable, msg)
		  end
		end
 
	  local file = io.open(filePath, "w+")
	  file:write(table.concat(strTable, "\n"))
	  file:close()
	  end
	end
	
  reaper.ImGui_SameLine(ctx)
  if button(COLOR_LOAD, COLOR_LOAD_HOVERED, COLOR_LOAD_ACTIVE, "Load##LOADCONFIG") then
	local retval, filePath = reaper.JS_Dialog_BrowseForOpenFiles("Load Configuration", dir, "", extList, false)
	if retval == 1 and getFileExtension(filePath) == "txt" then
	  for midiNoteNum=0, 127 do
		local textEvtID = getConfigTextEventID(midiNoteNum)
		if textEvtID then
		  deleteTextSysexEvt(configTake, textEvtID)
		  end
		end
		
	  local file = io.open(filePath, "r")
	  local fileText = file:read("*all")
	  file:close()
	  
	  for line in fileText:gmatch("[^\r\n]+") do
		insertTextSysexEvt(configTake, false, false, 0, TEXT_EVENT, line)
		end
	  
	  setRefreshState(REFRESHSTATE_COMPLETE)
	  end
	end
  end
  
function button(color, colorHovered, colorActive, label, arrowDir, width, height)
  reaper.ImGui_PushID(ctx, 1)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), color)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonHovered(), colorHovered)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_ButtonActive(), colorActive)
  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Text(), COLOR_WHITE)
  local retval
  if arrowDir then
	retval = reaper.ImGui_ArrowButton(ctx, label, arrowDir)
  else
	retval = reaper.ImGui_Button(ctx, label, width, height)
	end
  reaper.ImGui_PopStyleColor(ctx, 4)
  reaper.ImGui_PopID(ctx)
  return retval
  end

function isConfigEvent(msg)
  return (string.sub(msg, 1, 7) == "config_")
  end

function getNoteType(midiNoteNum)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return end
  return noteTable[17]
  end
  
function isLaneOverride(midiNoteNum)
  return isInTable(VALID_LANEOVERRIDE_LIST, getNoteType(midiNoteNum))
  end

function isLaneJam(midiNoteNum)
  return isInTable(VALID_JAM_TYPE_LIST, getNoteType(midiNoteNum))
  end

function isLaneNormalNote(midiNoteNum)
  return not (isLaneOverride(midiNoteNum) or isLaneJam(midiNoteNum))
  end
	  
function getNoteTable(midiNoteNum)
  return configList[midiNoteNum+1]
  end

function getValidStateChannels(midiNoteNum)
  local validChannels = {}
  for channel=0, 15 do
	if getNoteState(midiNoteNum, channel) then
	  tableInsert(validChannels, channel)
	  end
	end
  return validChannels
  end
  
function getNoteState(midiNoteNum, channel)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return end
  return noteTable[channel+1]
  end
  
function getNoteName(midiNoteNum)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return end
  return noteTable[18]
  end

function setNoteName(midiNoteNum, noteName)
  local textEvtID = getConfigTextEventID(midiNoteNum)

  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(configTake, textEvtID)
  
  local openQuoteIndex = string.find(msg, '"')
  local closeQuoteIndex = string.find(msg, '"', openQuoteIndex+1)
  
  msg = string.sub(msg, 1, openQuoteIndex) .. noteName .. string.sub(msg, closeQuoteIndex, #msg)
  
  setTextSysexEvt(configTake, textEvtID, nil, nil, nil, evtType, msg)
  end
	
function getFirstEmptyMIDINoteLane()
  local validNoteLanes = {}
  local _, noteCount = reaper.MIDI_CountEvts(notesTake)
  for noteID=0, noteCount-1 do
	local _, _, _, _, _, _, midiNoteNum = reaper.MIDI_GetNote(notesTake, noteID)
	if not validNoteLanes[midiNoteNum+1] then 
	  validNoteLanes[midiNoteNum+1] = true
	  end
	end
  for midiNoteNum=0, 127 do
	if not validNoteLanes[midiNoteNum+1] and not getConfigTextEventID(midiNoteNum) then
	  return midiNoteNum
	  end
	end
  end
  
function storeImageListsIntoMemory()
  local function storeImageListIntoMemory(dir, lookingForSubDir)
	local imageList = {}
	
	local function addImageToImageList(name)
	  local periodIndex = string.find(name, "%.")
	  if periodIndex then
		name = string.sub(name, 1, periodIndex-1)
		end
	  
	  if string.find(name, " ") then
		throwError("\"" .. name .. "\" is an invalid gem folder name (no spaces!)")
		end
	  
	  tableInsert(imageList, name)
	  end
	  
	if lookingForSubDir then
	  reaper.EnumerateSubdirectories(dir, -1)
	else
	  reaper.EnumerateFiles(dir, -1)
	  end
	  
	local index = 0
	while true do
	  local name
	  if lookingForSubDir then
		name = reaper.EnumerateSubdirectories(dir, index)
	  else
		name = reaper.EnumerateFiles(dir, index)
		end
		
	  if not name then
		break
		end
	  
	  if lookingForSubDir or getFileExtension(name) == "png" then
		addImageToImageList(name)
		end
		
	  index = index + 1
	  end
	  
	return imageList
	end
  
  gemImageList = storeImageListIntoMemory(getGemsDirectory(), true)
  notationImageList = storeImageListIntoMemory(getNotationsDirectory(), false)
  end

function updateEventsMIDIEditor()
  reaper.PreventUIRefresh(1)
  
  for midiNoteNum=0, 127 do
	local name
	if midiNoteNum == MEASURE_PHRASE then
	  name = "Measure Phrase"
	  end
	if midiNoteNum == BEAT_MEASURE_CHART then
	  name = "Measure (Chart)"
	  end
	if midiNoteNum == BEAT_STRONG_CHART then
	  name = "Strong Beat (Chart)"
	  end
	if midiNoteNum == BEAT_WEAK_CHART then
	  name = "Weak Beat (Chart)"
	  end
	if midiNoteNum == BEAT_MEASURE_NOTATION then
	  name = "Measure (Notation)"
	  end
	if midiNoteNum == BEAT_STRONG_NOTATION then
	  name = "Strong Beat (Notation)"
	  end
	if midiNoteNum == BEAT_WEAK_NOTATION then
	  name = "Weak Beat (Notation)"
	  end
	if name then
	  reaper.SetTrackMIDINoteName(eventsTrackID, midiNoteNum, -1, name)
	else
	  reaper.SetTrackMIDINoteName(eventsTrackID, midiNoteNum, -1, "")
	  end
	end

  reaper.PreventUIRefresh(-1)
  end
  
function storeReaperTemposInTextFile()
  local list = {}

  local numMarkers = reaper.CountTempoTimeSigMarkers(0)
  for i=0, numMarkers-1 do
	local retval, time, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(0, i)
	if lineartempo then
	  throwError("No linear tempos allowed!", nil, time)
	  end
	  
	local qn = roundFloatingPoint(reaper.TimeMap2_timeToQN(0, time))
	local ppqpos = reaper.MIDI_GetPPQPosFromProjTime(notesTake, time)
	tableInsert(list, "qn=" .. qn .. " ppqpos=" .. ppqpos .. " time=" .. time .. " bpm=" .. bpm)
	
	if i == numMarkers-1 then
	  if qn >= END_TEXT_EVT_QN then
		throwError("Tempo markers found past the [end] event!")
		end
		
	  local ppqpos = reaper.MIDI_GetPPQPosFromProjQN(notesTake, END_TEXT_EVT_QN)
	  local time = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, ppqpos)
	  tableInsert(list, "qn=" .. END_TEXT_EVT_QN .. " ppqpos=" .. ppqpos .. " time=" .. time .. " bpm=" .. bpm)
	  end
	end
  
  local file = io.open(getTemposTextFilePath(), "w+")
  file:write(table.concat(list, "\n"))
  file:close()
  end

function storeReaperEventsInTextFile()
  local masterTable = {}
  
  local function add(val)
	tableInsert(masterTable, val)
	end
  
  measurePhraseList, chartBeatList, notationBeatList = {}, {}, {}
	
  local _, noteCount = reaper.MIDI_CountEvts(eventsTake)
  for noteID=0, noteCount-1 do
	local _, _, _, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(eventsTake, noteID)
	local startQN = getQNFromPPQPOS(eventsTake, startPPQPOS)
	local startTime = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, startPPQPOS)
	
	if startQN >= END_TEXT_EVT_QN then
	  throwError("Beat notes found after the end of the EVENTS item! (expand the item to find them?)")
	  end
	  
	local tableToInsert
	if midiNoteNum == MEASURE_PHRASE then
	  tableToInsert = measurePhraseList
	elseif midiNoteNum < BEAT_WEAK_CHART then
	  tableToInsert = notationBeatList
	  if #notationBeatList == 0 then
		if midiNoteNum == BEAT_MEASURE_NOTATION then
		  startEvtPPQPOS = startPPQPOS
		else
		  throwError("The first notation beat note MUST be a measure note!")
		  end
		end
	  if midiNoteNum == BEAT_MEASURE_NOTATION then
		endEvtPPQPOS = startPPQPOS
		endEvtQN = startQN
		endEvtTime = startTime
	  else
		endEvtPPQPOS = nil
		endEvtQN = nil
		endEvtTime = nil
		end
	else
	  tableToInsert = chartBeatList
	  end
	tableInsert(tableToInsert, {startPPQPOS, startTime, startQN, midiNoteNum})
	end
  if #notationBeatList == 0 then
	throwError("No notation beat events found!")
	end
  if #chartBeatList == 0 then
	throwError("No chart beat events found!")
	end
  if #measurePhraseList == 0 and isJamTrack() then
	throwError("No measure phrase markers found!")
	end
  if #measurePhraseList > 0 and not isJamTrack() then
	throwError("Measure phrase markers not allowed in a " .. CHART_TYPE .. "!")
	end
  if not endEvtPPQPOS then
	throwError("The last notation beat note MUST be a measure note (to determine where the last measure ends)!")
	end
  
  if isJamTrack() then
	for x=1, #measurePhraseList do
	  local measurePhraseData = measurePhraseList[x]
	  local measurePhrasePPQPOS = measurePhraseData[BEATLISTINDEX_PPQPOS]
	  local notationBeatIndex = exactBinarySearch(notationBeatList, measurePhrasePPQPOS, BEATLISTINDEX_PPQPOS)
	  if not notationBeatIndex or notationBeatList[notationBeatIndex][BEATLISTINDEX_BEATTYPE] ~= BEAT_MEASURE_NOTATION then
		local measurePhraseTime = measurePhraseData[BEATLISTINDEX_TIME]
		throwError("Measure phrase not aligned with notation measure!", nil, measurePhraseTime)
		end
	  end
	if measurePhraseList[1][BEATLISTINDEX_PPQPOS] ~= notationBeatList[1][BEATLISTINDEX_PPQPOS] then
	  local time = notationBeatList[1][BEATLISTINDEX_TIME]
	  throwError("First measure phrase does not start at first notation measure!", nil, time)
	  end
	end
	  
  ------------------------------------------------------
  
  tempoTextEvtList, sectionTextEvtList = {}, {}, {}
  
  local isTempoOverride = false
  
  local _, _, _, textCount = reaper.MIDI_CountEvts(eventsTake)
  for textEvtID=0, textCount-1 do
	local _, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(eventsTake, textEvtID)
	local qn = getQNFromPPQPOS(eventsTake, ppqpos)
	local time = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, ppqpos)
  
	if evtType == TEXT_EVENT then
	  local msgData = separateString(msg)
	  
	  local header = msgData[1]
	  table.remove(msgData, 1)
	  local valueStr = string.sub(msg, #header+2, #msg)
	  
	  if header == "tempo" then
		if msgData[1] == "default" then
		  isTempoOverride = false
		  local subList = tempoTextEvtList[#tempoTextEvtList]
		  tableInsert(subList, ppqpos)
		else
		  if not isTempoOverride then
			isTempoOverride = true
			tableInsert(tempoTextEvtList, {})
			end
		  local bpmStr = msgData[1]
		  local performanceDirection = msgData[2]
		  
		  local bpmBasis
		  local equalsSignIndex = string.find(bpmStr, "=")
		  if equalsSignIndex then
			bpmBasis = string.sub(bpmStr, 1, equalsSignIndex-1)
			bpm = tonumber(string.sub(bpmStr, equalsSignIndex+1, #bpmStr))
		  else
			bpmBasis = "q"
			bpm = tonumber(bpmStr)
			end
		  
		  --TODO: error if not valid bpmBasis
		  --TODO: error if not tonumber
		  
		  tableInsert(tempoTextEvtList[#tempoTextEvtList], {ppqpos, qn, bpmBasis, bpm, performanceDirection})
		  end
		end
	  
	  if header == "section" then
		tableInsert(sectionTextEvtList, {ppqpos, valueStr})
		end
	  end
	end
  
  tempoTextEvtList = getNotationTempos() --don't delete
  for x=1, #tempoTextEvtList do
	local data = tempoTextEvtList[x]
	local ppqpos = data[TEMPOLISTINDEX_QN]
	local qn = data[TEMPOLISTINDEX_QN]
	local bpmBasis = data[TEMPOLISTINDEX_BPMBASIS]
	local bpm = data[TEMPOLISTINDEX_BPM]
	local performanceDirection = data[TEMPOLISTINDEX_PERFORMANCEDIRECTION]
	--reaper.ShowConsoleMsg("TEST: " .. qn .. " " .. bpmBasis .. " " .. bpm .. "\n")
	end
	
  ------------------------------------------------------  
	
  getMeasureTextEvents()
  
  ------------------------------------------------------
  
  add("MISC")
  add("end_event_ppqpos=" .. endEvtPPQPOS .. " end_event_qn=" .. endEvtQN .. " end_event_time=" .. endEvtTime)
  
  add("MEASURE_PHRASE_LIST")
  for i, data in ipairs(measurePhraseList) do
	local ppqpos = data[1]
	local time = data[2]
	local qn = data[3]
	add("qn=" .. qn .. " ppqpos=" .. ppqpos .. " time=" .. time)
	end
	
  add("CHART_BEAT_LIST")
  for i, data in ipairs(chartBeatList) do
	local ppqpos = data[1]
	local time = data[2]
	local qn = data[3]
	local midiNoteNum = data[4]
	add("ppqpos=" .. ppqpos .. " time=" .. time .. " qn=" .. qn .. " beat_type=" .. midiNoteNum-BEAT_WEAK_CHART)
	end
	
  add("NOTATION_BEAT_LIST")
  for i, data in ipairs(notationBeatList) do
	local ppqpos = data[1]
	local time = data[2]
	local qn = data[3]
	local midiNoteNum = data[4]
	add("ppqpos=" .. ppqpos .. " time=" .. time .. " qn=" .. qn .. " beat_type=" .. midiNoteNum)
	end
	
  add("SECTION_LIST")
  for i, data in ipairs(sectionTextEvtList) do
	local ppqpos = data[1]
	local sectionName = data[2]
	add("ppqpos=" .. ppqpos .. " `name=" .. sectionName .. "`")
	end
  
  add("TEMPO_LIST")
  for i, data in ipairs(tempoTextEvtList) do
	local ppqpos = data[TEMPOLISTINDEX_PPQPOS]
	local qn = data[TEMPOLISTINDEX_QN]
	local bpmBasis = data[TEMPOLISTINDEX_BPMBASIS]
	local bpm = data[TEMPOLISTINDEX_BPM]
	local performanceDirection = data[TEMPOLISTINDEX_PERFORMANCEDIRECTION]
	local performanceDirectionStr
	if performanceDirection then
	  performanceDirectionStr = " `performance_direction=" .. performanceDirection .. "`"
	else
	  performanceDirectionStr = ""
	  end
	add("ppqpos=" .. ppqpos .. " qn=" .. qn .. " bpm_basis=" .. bpmBasis .. " bpm=" .. bpm .. performanceDirectionStr)
	end
  
  add("MEASURE_LIST")
  for i, data in ipairs(measureList) do
	local ppqpos = data[MEASURELISTINDEX_PPQPOS]
	local qn = data[MEASURELISTINDEX_QN]
	local time = data[MEASURELISTINDEX_TIME]
	local beamGroupings = data[MEASURELISTINDEX_BEAMGROUPINGS]
	local secondaryBeamGroupings = data[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS]
	local timeSigNum = data[MEASURELISTINDEX_TIMESIGNUM]
	local timeSigDenom = data[MEASURELISTINDEX_TIMESIGDENOM]
	local beatTable = data[MEASURELISTINDEX_BEATTABLE]
	local quantizeStr = data[MEASURELISTINDEX_QUANTIZESTR]
	local quantizeDenom = data[MEASURELISTINDEX_QUANTIZEDENOM]
	local quantizeTupletFactorNum = data[MEASURELISTINDEX_QUANTIZETUPLETFACTORNUM]
	local quantizeTupletFactorDenom = data[MEASURELISTINDEX_QUANTIZETUPLETFACTORDENOM]
	local quantizeModifier = data[MEASURELISTINDEX_QUANTIZEMODIFIER]
	
	local beatTableStr = " beats="
	for j, beatData in ipairs(beatTable) do
	  local qnBeat = beatData[1]
	  local isStrongBeat = beatData[2]
	  local strongBeatInt
	  if isStrongBeat then strongBeatInt = 1 else strongBeatInt = 0 end
	  local rhythm = beatData[3]
	  local num = beatData[4]
	  local denom = beatData[5]
	  beatTableStr = beatTableStr .. qnBeat .. "," .. strongBeatInt .. "," .. rhythm .. "," .. num .. "," .. denom
	  if j < #beatTable then
		beatTableStr = beatTableStr .. ";"
		end
	  end
	  
	add("ppqpos=" .. ppqpos .. " qn=" .. qn .. " time=" .. time .. " beam_groupings=" .. beamGroupings .. " secondary_beam_groupings=" .. secondaryBeamGroupings .. " time_sig=" .. timeSigNum .. "/" .. timeSigDenom .. beatTableStr .. " quantize_str=" .. quantizeStr .. " quantize_denom=" .. quantizeDenom .. " quantize_tuplet_factor_num=" .. quantizeTupletFactorNum .. " quantize_tuplet_factor_denom=" .. quantizeTupletFactorDenom .. " quantize_modifier=" .. quantizeModifier)
	end
	
  local file = io.open(getEventsTextFilePath(), "w+")
  file:write(table.concat(masterTable, "\n"))
  file:close()
  end
  
function storeReaperNotesInTextFile()
  local masterTable = {}
  
  local function add(val)
	tableInsert(masterTable, val)
	end
  
  local _, chartNoteCount, chartCCCount, chartTextCount = reaper.MIDI_CountEvts(notesTake)
  
  add("NOTES")
  for noteID=0, chartNoteCount-1 do
	local _, _, _, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(notesTake, noteID)
	local startQN = getQNFromPPQPOS(notesTake, startPPQPOS)
	local endQN = getQNFromPPQPOS(notesTake, endPPQPOS)
	local startTime = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, startPPQPOS)
	local endTime = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, endPPQPOS)
	local notationTextEvtID = getNotationTextEventID(startPPQPOS, channel, midiNoteNum)
	local notationTextEvtStr
	if notationTextEvtID then
	  local _, _, _, _, _, msg = reaper.MIDI_GetTextSysexEvt(notesTake, notationTextEvtID)
	  notationTextEvtStr = " text_event_id=" .. notationTextEvtID .. " `text_event_message=" .. msg .. "`"
	else
	  notationTextEvtStr = ""
	  end
	add("id=" .. noteID .. " ppqpos_start=" .. startPPQPOS .. " time_start=" .. startTime .. " qn_start=" .. startQN .. " ppqpos_end=" .. endPPQPOS .. " time_end=" .. endTime .. " qn_end=" .. endQN .. " channel=" .. channel .. " pitch=" .. midiNoteNum .. " velocity=" .. velocity .. notationTextEvtStr)
	if endQN >= endEvtQN then
	  throwError("Note(s) in DRUMS track found after the last notation measure!")
	  end
	end
	
  add("CCS")
  for ccID=0, chartCCCount-1 do
	local _, _, _, ppqpos, _, channel, ccNum, ccVal = reaper.MIDI_GetCC(notesTake, ccID)
	local qn = getQNFromPPQPOS(notesTake, ppqpos)
	local time = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, ppqpos)
	local _, shape = reaper.MIDI_GetCCShape(notesTake, ccID)
	add("id=" .. ccID .. " ppqpos=" .. ppqpos .. " time=" .. time .. " qn=" .. qn .. " channel=" .. channel .. " number=" .. ccNum .. " value=" .. ccVal .. " shape=" .. shape)
	if qn >= endEvtQN then
	  throwError("CC point(s) in DRUMS track found after the last notation measure!")
	  end
	end
  
  add("TEXTS")
  for textEvtID=0, chartTextCount-1 do
	local _, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(notesTake, textEvtID)
	local qn = getQNFromPPQPOS(notesTake, ppqpos)
	local time = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, ppqpos)
	add("id=" .. textEvtID .. " ppqpos=" .. ppqpos .. " time=" .. time .. " qn=" .. qn .. " event_type=" .. evtType .. " `message=" .. msg .. "`")
	if qn >= endEvtQN then
	  throwError("Text event(s) in DRUMS track found after the last notation measure!")
	  end
	end
  
  ---------------------------------------------------
  
  local file = io.open(getMIDIDataTextFilePath(), "w+")
  file:write(table.concat(masterTable, "\n"))
  file:close()
  end
  
function safeCall(func, errorCode, ...)
  local success, result = pcall(func, ...)
  if not success then
	setError(errorCode, result)
	end
  return result
  end
	
function refreshNoteData(initial)
  if not initial and not anyMainWindowVisible() then return end
  
  local function runRefresh()
	if not REFRESHCOUNT then
	  REFRESHCOUNT = 0
	  end
	REFRESHCOUNT = REFRESHCOUNT + 1
	--reaper.ShowConsoleMsg("REFRESHCOUNT: " .. REFRESHCOUNT .. "\n")
	
	CHART_TYPE = getChartType()
	
	local err = safeCall(defineTakes, ERROR_INVALIDTAKE) if err then return err end
	
	_, DRUM_NOTECOUNT, DRUM_CCCOUNT, DRUM_TEXTCOUNT = reaper.MIDI_CountEvts(notesTake)
	_, EVENTS_NOTECOUNT, EVENTS_CCCOUNT, EVENTS_TEXTCOUNT = reaper.MIDI_CountEvts(eventsTake)
	
	--only within REAPER - before ANYTHING else, convert reaper MIDI to text file
	local err = safeCall(storeReaperTemposInTextFile, ERROR_INVALIDREAPERSETUP) if err then return err end
	local err = safeCall(storeReaperEventsInTextFile, ERROR_INVALIDREAPERSETUP) if err then return err end
	local err = safeCall(storeReaperNotesInTextFile, ERROR_INVALIDREAPERSETUP) if err then return err end
	
	runChartCompiler()
	end
	
  if currentRefreshState ~= REFRESHSTATE_NOTREFRESHING then
	if ERRORCODE then
	  ERRORCODE = nil
	  ERRORMSG = nil
	  currentRefreshState = REFRESHSTATE_COMPLETE
	  end
	  
	local errorMsg = runRefresh()
	if errorMsg then return errorMsg end
	
	while currentRefreshStateLoop do
	  local errorMsg = runRefresh()
	  if errorMsg then return errorMsg end
	  end
	end
  
  currentRefreshState = REFRESHSTATE_NOTREFRESHING
  end

function defineTakes()
  local function defineTake(track, validTrackName)
	local take, trackID
	
	if not reaper.ValidatePtr(track, "MediaTrack*") then
	  track = nil
	  for testTrackID=0, reaper.GetNumTracks()-1 do
		local testTrack = reaper.GetTrack(0, testTrackID)
		local _, testTrackName = reaper.GetTrackName(testTrack)
		if testTrackName == validTrackName then
		  track = testTrack
		  break
		  end
		end
	  end
	
	if not track then
	  throwError("No valid " .. validTrackName .. " track!")
	  end
	  
	local _, trackName = reaper.GetTrackName(track)
	if trackName ~= validTrackName then
	  track = nil
	else
	  trackID = getTrackID(track)
	  end
	
	if not track then
	  throwError("No valid " .. validTrackName .. " track!")
	  end
	  
	local numMediaItems = reaper.CountTrackMediaItems(track)
	if numMediaItems == 0 then
	  throwError("No media items found on " .. validTrackName .. " track!")
	  end
	if numMediaItems > 1 then
	  throwError("Too many media items found on " .. validTrackName .. " track!")
	  end
	  
	local mediaItem = reaper.GetTrackMediaItem(track, 0)
	if reaper.GetMediaItemInfo_Value(mediaItem, "D_POSITION") ~= 0 then
	  throwError("Media item does not start at the beginning of the project on " .. validTrackName .. " track!")
	  end
	  
	local numTakes = reaper.CountTrackMediaItems(track)
	if numTakes == 0 then
	  throwError("No takes found on " .. validTrackName .. " media item!")
	  end
	if numTakes > 1 then
	  throwError("Too many takes found on " .. validTrackName .. " media item!")
	  end
	
	take = reaper.GetTake(mediaItem, 0)
	
	if not reaper.TakeIsMIDI(take) then
	  throwError("No MIDI take found on " .. validTrackName .. " media item!")
	  end
	
	if getPPQResolution(take) ~= PPQ_RESOLUTION then
	  throwError("MIDI take must have a PPQ resolution of 960! (" .. validTrackName .. " media item)")
	  end
	  
	return take, track, trackID
	end
  
  notesTake, notesTrack, notesTrackID = defineTake(notesTrack, VALID_NOTESTRACKNAME)
  eventsTake, eventsTrack, eventsTrackID = defineTake(eventsTrack, VALID_EVENTSTRACKNAME)
  
  END_TEXT_EVT_TIME = reaper.GetMediaItemInfo_Value(reaper.GetTrackMediaItem(eventsTrack, 0), "D_LENGTH")
  END_TEXT_EVT_PPQPOS = reaper.MIDI_GetPPQPosFromProjTime(eventsTake, END_TEXT_EVT_TIME)
  END_TEXT_EVT_QN = reaper.MIDI_GetProjQNFromPPQPos(eventsTake, END_TEXT_EVT_PPQPOS)
  updateEventsMIDIEditor()
  end

function getPPQResolution(take)
  local ppq0 = reaper.MIDI_GetPPQPosFromProjQN(take, 0.0)
  local ppq1 = reaper.MIDI_GetPPQPosFromProjQN(take, 1.0)
  return ppq1 - ppq0
  end
  
function listenToMIDIEditor()
  local midiEditor = reaper.MIDIEditor_GetActive()
  if reaper.MIDIEditor_GetTake(midiEditor) ~= notesTake then return end
  
  local function getClosestNoteBeforeCursor(activeNoteRow)
	local cursorPos = reaper.GetCursorPosition()
	local resultingNoteID
	
	local noteID = 0
	while true do
	  local retval, _, _, startppqpos, _, _, midiNoteNum = reaper.MIDI_GetNote(notesTake, noteID)
	  if not retval then
		break
		end
	  
	  if midiNoteNum == activeNoteRow then
		local time = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, startppqpos)
		if time >= cursorPos then
		  break
		  end
		resultingNoteID = noteID
		end
		
	  noteID = noteID + 1
	  end
	  
	return resultingNoteID
	end
	
  --preview playback
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  if window == "midi_editor" then
	if segment == "piano" then
	  local activeNoteRow = reaper.MIDIEditor_GetSetting_int(midiEditor, "active_note_row")
	  if mouseLeftReleased then
		local noteID = getClosestNoteBeforeCursor(activeNoteRow)
		if noteID then
		  reaper.PreventUIRefresh(1)
		  
		  local _, _, _, startppqpos = reaper.MIDI_GetNote(notesTake, noteID)
		  local initialTime = reaper.MIDI_GetProjTimeFromPPQPos(notesTake, startppqpos)
		  local originalCursorPos = reaper.GetCursorPosition()
		  reaper.SetEditCurPos(initialTime, false, false)
		  reaper.Main_OnCommand(1007, 0) --Transport: Play
		  for x=0, 70000000 do end
		  reaper.Main_OnCommand(1016, 0) --Transport: Stop
		  reaper.SetEditCurPos(originalCursorPos, true, false)
		  
		  reaper.PreventUIRefresh(-1)
		  end
		end
	  end
	end
  end

function checkGmem()
  local val = reaper.gmem_read(0)
  if val ~= 0 then
	reaper.PreventUIRefresh(1)
	
	local selectedNoteList = {}
	if noteList then
	  for x=1, #noteList do
		local noteData = noteList[x]
		local noteID = noteData[NOTELISTINDEX_NOTEID]
		local graceState = noteData[NOTELISTINDEX_GRACESTATE]
		local _, selected = reaper.MIDI_GetNote(notesTake, noteID)
		if selected then
		  tableInsert(selectedNoteList, noteData)
		  end
		end
	  end
	  
	if val == 1 then
	  local key = "window_config"
	  windowVisibility_CONFIG = writeSettingToFile(key, math.abs(windowVisibility_CONFIG-1))
	  end
	if val == 2 then
	  local key = "window_chart"
	  windowVisibility_CHART = writeSettingToFile(key, math.abs(windowVisibility_CHART-1))
	  end
	if val == 3 then
	  local key = "window_notation"
	  windowVisibility_NOTATION = writeSettingToFile(key, math.abs(windowVisibility_NOTATION-1))
	  end
	
	if not ERRORCODE or ERRORCODE > ERROR_MIDIINTOMEMORY then
	  local velocity
	  if val == 4 then velocity = 1 end
	  if val == 5 then velocity = 50 end
	  if val == 6 then velocity = 100 end
	  if val == 7 then velocity = 127 end
	  
	  if velocity then
		for x=1, #selectedNoteList do
		  local noteData = selectedNoteList[x]
		  local noteID = noteData[NOTELISTINDEX_NOTEID]
		  reaper.MIDI_SetNote(notesTake, noteID, nil, nil, nil, nil, nil, nil, velocity)
		  end
		end
	  
	  if val == 8 then
		local insertGrace = false
		for x=1, #selectedNoteList do
		  local noteData = selectedNoteList[x]
		  local graceState = noteData[NOTELISTINDEX_GRACESTATE]
		  if graceState ~= "grace" then
			insertGrace = true
			break
			end
		  end
		local valStr, prevValStr
		if insertGrace then
		  valStr = "grace"
		  prevValStr = "flamgrace"
		else
		  prevValStr = "grace"
		  end
		for x=1, #selectedNoteList do
		  local noteData = selectedNoteList[x]
		  local startPPQPOS = noteData[NOTELISTINDEX_STARTPPQPOS]
		  local channel = noteData[NOTELISTINDEX_CHANNEL]
		  local midiNoteNum = noteData[NOTELISTINDEX_MIDINOTENUM]
		  setNotationTextEventParameter(startPPQPOS, channel, midiNoteNum, nil, valStr, prevValStr)
		  end
		end
	  
	  if val == 9 then
		local function getNewFlamPPQPOS(take, ppqpos, offset_ms)
		  local FLAMTIMEOFFSET_MS = 35
		  local time = reaper.MIDI_GetProjTimeFromPPQPos(take, ppqpos)
		  return reaper.MIDI_GetPPQPosFromProjTime(take, time + FLAMTIMEOFFSET_MS/1000)
		  end
		  
		if #selectedNoteList == 1 then
		  local noteData = selectedNoteList[1]
		  local noteID = noteData[NOTELISTINDEX_NOTEID]
		  local _, selected, muted, startppqpos, endppqpos, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(notesTake, noteID)
		  local midppqpos = getNewFlamPPQPOS(notesTake, startppqpos)
		  reaper.MIDI_SetNote(notesTake, noteID, nil, nil, nil, midppqpos, nil, nil, nil)
		  setNotationTextEventParameter(startppqpos, channel, midiNoteNum, nil, "flamgrace", "grace")
		  reaper.MIDI_InsertNote(notesTake, selected, muted, midppqpos, endppqpos, channel, midiNoteNum, velocity)
		  setNotationTextEventParameter(midppqpos, channel, midiNoteNum, nil, "flam", "grace")
		elseif #selectedNoteList == 2 then
		  local noteData_1 = selectedNoteList[1]
		  local noteData_2 = selectedNoteList[2]
		  local noteID_1 = noteData_1[NOTELISTINDEX_NOTEID]
		  local _, _, _, startppqpos_1, endppqpos_1, _, midiNoteNum_1 = reaper.MIDI_GetNote(notesTake, noteID_1)
		  local noteID_2 = noteData_2[NOTELISTINDEX_NOTEID]
		  local _, _, _, startppqpos_2, endppqpos_2, _, midiNoteNum_2 = reaper.MIDI_GetNote(notesTake, noteID_2)
		
		  if midiNoteNum_1 == midiNoteNum_2 then
			return
			end
		  
		  local startppqpos = math.min(startppqpos_1, startppqpos_2)
		  local endppqpos = math.max(endppqpos_1, endppqpos_2)
		  local midppqpos = getNewFlamPPQPOS(notesTake, startppqpos)
		  
		  local earlyNoteData, earlyNoteID, lateNoteData, lateNoteID
		  if startppqpos_2 > startppqpos_1 then
			earlyNoteData = noteData_2
			earlyNoteID = noteID_2
			lateNoteData = noteData_1
			lateNoteID = noteID_1
		  else
			earlyNoteData = noteData_1
			earlyNoteID = noteID_1
			lateNoteData = noteData_2
			lateNoteID = noteID_2
			end
		  
		  reaper.MIDI_SetNote(notesTake, earlyNoteID, nil, nil, startppqpos, midppqpos, nil, nil, nil)
		  local channel = earlyNoteData[NOTELISTINDEX_CHANNEL]
		  local midiNoteNum = earlyNoteData[NOTELISTINDEX_MIDINOTENUM]
		  setNotationTextEventParameter(startppqpos, channel, midiNoteNum, nil, "flamgrace", "grace")
		  
		  reaper.MIDI_SetNote(notesTake, lateNoteID, nil, nil, midppqpos, endppqpos, nil, nil, nil)
		  local channel = lateNoteData[NOTELISTINDEX_CHANNEL]
		  local midiNoteNum = lateNoteData[NOTELISTINDEX_MIDINOTENUM]
		  setNotationTextEventParameter(midppqpos, channel, midiNoteNum, nil, "flam", "grace")
		  end
		end
	  
	  if val == 10 then
		local selectedNotes = {}
		local selectedNoteID = -1
		while true do
		  local noteID = reaper.MIDI_EnumSelNotes(notesTake, selectedNoteID)
		  if noteID == -1 then break end
		  tableInsert(selectedNotes, noteID)
		  selectedNoteID = noteID
		  end
		
		if #selectedNotes > 2 then
		  local firstNoteID = selectedNotes[1]
		  local lastNoteID = selectedNotes[#selectedNotes]
		  local _, _, _, firstNoteStartPPQPOS, _, _, _, firstNoteVelocity = reaper.MIDI_GetNote(notesTake, firstNoteID)
		  local _, _, _, lastNoteStartPPQPOS, _, _, _, lastNoteVelocity = reaper.MIDI_GetNote(notesTake, lastNoteID)
		  
		  for x=1, #selectedNotes do
			local noteID = selectedNotes[x]
			local _, _, _, startPPQPOS, _, _, _, velocity = reaper.MIDI_GetNote(notesTake, noteID)
			local newVelocity = round(convertRange(startPPQPOS, firstNoteStartPPQPOS, lastNoteStartPPQPOS, firstNoteVelocity, lastNoteVelocity))
			reaper.MIDI_SetNote(notesTake, noteID, nil, nil, nil, nil, nil, nil, newVelocity)
			end
		  end
		end
	  end
	  
	reaper.gmem_write(0, 0)
	setRefreshState(REFRESHSTATE_COMPLETE)
	
	reaper.PreventUIRefresh(-1)
	end
  end
  
function getCursorPosition()
  if PLAYSTATE == 1 then
	return PLAYPOSITION
	end
  return EDITPOSITION
  end
  
function updateFrameByFrameVariables()
  if PLAYSTATE == 0 and (reaper.GetPlayState() & 1 == 1 or notationEditor_changedPlayState) then
	setRefreshState(REFRESHSTATE_COMPLETE)
	refreshNoteData()
	end
  if notationEditor_changedPlayState then
	reaper.Main_OnCommand(40044, 0) --play/stop
	notationEditor_changedPlayState = false
	end
  PLAYSTATE = reaper.GetPlayState() & 1
  
  if mouseState then
	mouseLeftReleased = (mouseState == 1 and reaper.JS_Mouse_GetState(1) == 0)
	end
  mouseState = reaper.JS_Mouse_GetState(1)
  
  PLAYPOSITION = reaper.GetPlayPosition()
  EDITPOSITION = reaper.GetCursorPosition()
  
  local _, testDrumNoteCount, testDrumCCCount, testDrumTextCount = reaper.MIDI_CountEvts(notesTake)
  local _, testEventsNoteCount, testEventsCCCount, testEventsTextCount = reaper.MIDI_CountEvts(eventsTake)
  
  if testDrumNoteCount ~= DRUM_NOTECOUNT or testDrumCCCount ~= DRUM_CCCOUNT or testDrumTextCount ~= DRUM_TEXTCOUNT 
  or testEventsNoteCount ~= EVENTS_NOTECOUNT or testEventsCCCount ~= EVENTS_CCCOUNT or testEventsTextCount ~= EVENTS_TEXTCOUNT then
	if windowVisibility_NOTATION then
	  setRefreshState(REFRESHSTATE_COMPLETE)
	  refreshNoteData()
	  end
	end
  end

function beginWindow(windowTitle, xMin, yMin, xMax, yMax)
  local windowFlags = 0
  if windowTitle == "Notation" then
	windowFlags = windowFlags + reaper.ImGui_WindowFlags_NoResize() + reaper.ImGui_WindowFlags_NoMove() + reaper.ImGui_WindowFlags_NoTitleBar()
	end
	
  if windowTitle == "Config" then
	windowFlags = windowFlags + reaper.ImGui_WindowFlags_AlwaysVerticalScrollbar()
  else
	windowFlags = windowFlags + reaper.ImGui_WindowFlags_NoScrollbar() + reaper.ImGui_WindowFlags_NoScrollWithMouse()
	end
  if windowTitle == "Notation" then
	windowFlags = windowFlags + reaper.ImGui_WindowFlags_AlwaysHorizontalScrollbar()
	end
	
  reaper.ImGui_SetNextWindowBgAlpha(ctx, 1)
  local visible, open = reaper.ImGui_Begin(ctx, windowTitle, true, windowFlags)
  if firstFrame then
	--reaper.ImGui_SetWindowPos(ctx, xMin, yMin)
	--reaper.ImGui_SetWindowSize(ctx, xMax-xMin, yMax-yMin)
	end
  
  local windowX, windowY = reaper.ImGui_GetWindowPos(ctx)
  local windowSizeX, windowSizeY = reaper.ImGui_GetWindowSize(ctx)
  local scrollY = reaper.ImGui_GetScrollY(ctx)
	
  return visible, open, scrollY
  end

function endWindow()
  reaper.ImGui_SetCursorPosX(ctx, 0)
  reaper.ImGui_SetCursorPosY(ctx, 0)
  reaper.ImGui_End(ctx)
  end
	
function loop()
  CURRENT_ERRORCODE_CHECKPOINT = nil

  local success, err = pcall(function()
	defineTakes()
	end)
  if success then
	updateFrameByFrameVariables()
  else
	setError(ERROR_INVALIDTAKE, err)
	end
  
  reaper.ImGui_PushFont(ctx, defaultFont)
  
  if windowVisibility_CONFIG == 1 then
	windowVisible, windowOpen, scrollY = beginWindow("Config", initialConfigWindowX, initialConfigWindowY, initialConfigWindowSizeX, initialConfigWindowSizeY+150)
	if windowVisible then
	  --drawConfigSettings(ctx)
	  endWindow()
	  end
	if not windowOpen then
	  windowVisibility_CONFIG = writeSettingToFile("window_config", math.abs(windowVisibility_CONFIG-1))
	  end
	end
  
  if windowVisibility_CHART == 1 then
	windowVisible, windowOpen = beginWindow("Chart", chartWindowX, chartWindowY, chartWindowX+chartWindowSizeX, chartWindowY+chartWindowSizeY)
	if windowVisible then
	  local windowX, windowY = reaper.ImGui_GetWindowPos(ctx)
	  local windowSizeX, windowSizeY = reaper.ImGui_GetWindowSize(ctx)
	  chartWindowX = windowX
	  chartWindowY = windowY
	  chartWindowSizeX = windowSizeX
	  chartWindowSizeY = windowSizeY
	  drawChart(chartWindowSizeX/2, chartWindowSizeY-80, 1, 30, 30, 30, COLOR_PINK, 255, true, true, true, true)
	  endWindow()
	  end
	if not windowOpen then
	  windowVisibility_CHART = writeSettingToFile("window_chart", math.abs(windowVisibility_CHART-1))
	  end
	end
  
  if windowVisibility_NOTATION == 1 then
	windowVisible, windowOpen = beginWindow("Notation", notationWindowX, notationWindowY, notationWindowX+notationWindowSizeX, notationWindowY+notationWindowSizeY)
	if windowVisible then
	  drawNotation()
	  endWindow()
	  end
	if not windowOpen then
	  windowVisibility_NOTATION = writeSettingToFile("window_notation", math.abs(windowVisibility_NOTATION-1))
	  end
	end

  if ERRORCODE and anyMainWindowVisible() then
	local windowVisible, windowOpen, scrollY = beginWindow("Error", errorWindowX, errorWindowY, errorWindowSizeX, errorWindowSizeY)
	if windowVisible then
	  displayError()
	  endWindow()
	  end
	end
  
  reaper.ImGui_PopFont(ctx)
  
  checkGmem()
  
  if not ERRORCODE or ERRORCODE > ERROR_MIDIINTOMEMORY then
	listenToMIDIEditor()
	end
  
  if firstFrame then
	firstFrame = false
	end
  
  --globalLightingFrameID = incrementValue(globalLightingFrameID, 1, 0, MAX_LIGHTINGFRAMEID)
  
  globalFrameID = globalFrameID + 1
  
  globalLightingFrameID = floor(globalFrameID/2) % MAX_LIGHTINGFRAMEID
  
  refreshNoteData()

  TEST_COUNT = TEST_COUNT + 1
	
  reaper.defer(loop)
  end

------------------------------

defineErrorCodes()
defineIndeces()
defineRequiredNoteTypeTable()

initializeImages()

refreshNoteData(true)

--runProfiler() --after all functions have been defined

TEST_COUNT = 0
loop()

--TODO: error out if all relevant tracks (right now, REAL_DRUMS and REAL_EVENTS) have ~= 1 item, if not midi, AND if item start pos is not beginning of project
