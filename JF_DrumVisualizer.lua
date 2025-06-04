reaper.gmem_attach("JF_DrumVisualizer")

function errorHandler(err)
  return debug.traceback("Error: " .. tostring(err), 2)
  end

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
  
function getInstrumentsDirectory()
  local dir = getScriptDirectory() .. "instruments/"
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
  --local y = x // 1
  --if x < 0 and x ~= y then
    --return y - 1 -- Adjust for negatives
    --end
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
    num = floor(num)
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
  
local qnEventList
local configList
--local noteList, chartBeatList, notationBeatList, measureList
--local sectionTextEvtList, tempoTextEvtList, ghostThresholdTextEvtList, accentThresholdTextEvtList, beamOverRestsTextEvtList
local gemImageList, masterImageList, notationImageList
--local restListBothVoices, rhythmOverrideListBothVoices, tupletListBothVoices, sustainListBothVoices, dynamicList, staffTextList
--local masterSelectedItemList, filteredSelectedItemList, voice1Filter, voice2Filter, currentGradualDynamicXMin

local VALID_LANEOVERRIDE_LIST = {"tuplet1", "tuplet2", "rhythm1", "rhythm2", "sustain1", "sustain2", "dynamics"}
local VALID_DYNAMICS_LIST = {"ppp", "pp", "p", "mp", "mf", "f", "ff", "fff", "sf", "sfz", "rfz", "fp", "n", "crescendo", "cresc.", "diminuendo", "decrescendo", "dim."}
local VALID_RHYTHM_DENOM_LIST = {1, 2, 4, 8, 16, 32, 64, 128}
local VALID_NOTEHEAD_LIST = {
  {"normal", 0.33},
  {"diamond", 0.45},
  {"square", 0.5},
  {"x", 0.1},
  {"circle-x", 0.1}
}

local SPECIAL_MEASURE_HEADER_LIST = {"gaps"}

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
  ERROR_CONFIGINTOMEMORY = 1
  ERROR_MIDIINTOMEMORY = 2
  ERROR_RHYTHMLIST = 3
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
  BEATLISTINDEX_BEATTYPE = 3
  
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

local BEAT_MEASURE_CHART = 14
local BEAT_STRONG_CHART = 13
local BEAT_WEAK_CHART = 12
local BEAT_MEASURE_NOTATION = 2
local BEAT_STRONG_NOTATION = 1
local BEAT_WEAK_NOTATION = 0

local firstFrame = true
local MIDIMAPPING_FILEPATH = getScriptDirectory() .. "\\midi_mapping.txt"
local CONFIG_FILEPATH = getScriptDirectory() .. "\\drum_config.txt"
local VALID_DRUMTRACKNAME = "PART REAL_DRUMS"
local VALID_EVENTSTRACKNAME = "PART REAL_EVENTS"
local TEXT_EVENT = 1
local NOTATION_EVENT = 15
local TRACKNAME_EVENT = 3
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
    time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, measurePPQPOS)
    end
  
  if time then
    reaper.SetEditCurPos(time, true, false)
    end
        
  debug_printStack()
  --reaper.ShowConsoleMsg(text .. "\n")
  error(text)
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
    error("Denominator cannot be zero")
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
  
function addIntegerFractions(num1, den1, num2, den2)
  -- Find the least common denominator (LCM of den1 and den2)
  local common_den = lcm(den1, den2)
  
  -- Scale the numerators to the common denominator
  local scaled_num1 = num1 * (common_den // den1)
  local scaled_num2 = num2 * (common_den // den2)
  
  -- Add the numerators
  local result_num = scaled_num1 + scaled_num2
  
  -- Simplify the result using GCD
  local common_divisor = gcd(result_num, common_den)
  local simplified_num = result_num // common_divisor
  local simplified_den = common_den // common_divisor
  
  return round(simplified_num), round(simplified_den)
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
  return floor(val+0.5)
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

function exactBinarySearch(list, target, subTableIndex)
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

function getListsWithTextEvtIDs()
  local list = {}
  
  if articulationListBothVoices then --not defined yet if populalting missing config override lanes (really dumb)
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
    end
  
  setRefreshState(REFRESHSTATE_KEEPSELECTIONS)
  end

function setTextSysexEvt(take, textEvtID, selectedIn, mutedIn, ppqposIn, evtTypeIn, msg)
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
  
function getEventsTextFilePath()
  return getGodotUserDirectory() .. "events.txt"
  end
  
function getMIDIDataTextFilePath()
  return getGodotUserDirectory() .. "midi.txt"
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
  
function storeImageSizesIntoMemory()
  imgSizeList = {}
  
  local file = io.open(getAssetsDirectory() .. "sizes.txt", "r")
  local fileText = file:read("*all")
  file:close()
  
  for line in fileText:gmatch("[^\r\n]+") do
    local values = separateString(line)
    tableInsert(imgSizeList, values)
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

function defineNotationVariables()
  notationDrawList = {}
  masterBeamListBothVoices = {{}, {}}
  masterCurrentlyBeamingBothVoices = {false, false}
  masterRecentBeamValueBothVoices = {nil, nil}
  masterRecentStemXPosBothVoices = {nil, nil}
  
  NOTATION_BGCOLOR = hexColor(255, 255, 200)
  NOTATION_BOUNDARYXMINOFFSET = -12
  
  CURRENTMEASURECOLOR = hexColor(255, 105, 180, 100)
  
  STAFFSPACEHEIGHT = 10
  MIN_NOTATION_X_GAP = STAFFSPACEHEIGHT * 0.7
  
  NUMLOWERLEGERLINES = 8 --edit this
  NUMHIGHERLEGERLINES = 12 --edit this
  MINSTAFFLINE = -(NUMLOWERLEGERLINES+2)
  MAXSTAFFLINE = NUMHIGHERLEGERLINES+2
  NUM_STAFFLINES = 5 + NUMLOWERLEGERLINES + NUMHIGHERLEGERLINES
  LEGERLINELEN = STAFFSPACEHEIGHT * 2
  TREMOLO_HEIGHT = STAFFSPACEHEIGHT*2.15
  BUZZ_HEIGHT = STAFFSPACEHEIGHT*1.05
  
  NOTATION_XMIN = notationWindowX
  NOTATION_XMAX = notationWindowX + notationWindowSizeX
  NOTATION_SIZEX = NOTATION_XMAX - NOTATION_XMIN
  NOTATION_YMAX = notationWindowY + notationWindowSizeY - 60
  NOTATION_SIZEY = STAFFSPACEHEIGHT*(NUM_STAFFLINES-1)
  NOTATION_YMIN = NOTATION_YMAX - NOTATION_SIZEY
  TOOLBAR_YMAX = notationWindowY + (NOTATION_YMIN-notationWindowY)
  CENTERSTAFFLINEY = NOTATION_YMIN + STAFFSPACEHEIGHT*(2 + NUMHIGHERLEGERLINES)
  
  staffLinePositionList = {}
  for staffLine=NUM_STAFFLINES-1, 0, -1 do
    local yPos = NOTATION_YMIN + NOTATION_SIZEY*(staffLine/(NUM_STAFFLINES-1))
    tableInsert(staffLinePositionList, yPos)
    end
  
  STEMYPOS_VOICE1 = 7
  STEMYPOS_VOICE2 = -5
  TUPLETLEVELSIZEY = STAFFSPACEHEIGHT
  
  EIGHTHFLAGHEIGHT_VOICE1 = STAFFSPACEHEIGHT * 2.6
  EIGHTHFLAGHEIGHT_VOICE2 = STAFFSPACEHEIGHT * 2.9
  BEAMSIZEY = STAFFSPACEHEIGHT*0.45
  BEAMSPACINGY = (STAFFSPACEHEIGHT*2 - BEAMSIZEY*3)/2
  BEAMSTUBX = BEAMSIZEY*2.5
  DOTSPACING = 10
  GHOSTSPACING = STAFFSPACEHEIGHT * 0.65
  CLEFOFFSET = 20
  ARTICULATIONSPACING = STAFFSPACEHEIGHT/2
  
  local clefXMin = CLEFOFFSET
  local clefYMin = getStaffLinePosition(1)
  local clefYMax = getStaffLinePosition(-1)
  local imgFileName = "clef_percussion"
  local img = getImageFromList(imgFileName)
  local imgSizeX, imgSizeY = getImageSize(imgFileName)
  local imgAspectRatio = imgSizeX/imgSizeY
  local sizeY = clefYMax - clefYMin
  local scalingFactor = sizeY/imgSizeY
  local sizeX = imgSizeX*scalingFactor
  local clefXMax = clefXMin + sizeX
  addToNotationDrawList({"clef", clefXMin, clefXMax, clefYMin, clefYMax, img, imgFileName})
  
  NOTATIONDRAWAREA_XMIN = clefXMax + 30

  RESTYCOOR_LIST = {
    {getStaffLinePosition(1), getStaffLinePosition(1) + STAFFSPACEHEIGHT*0.5}, --1
    {getStaffLinePosition(1) + STAFFSPACEHEIGHT*0.5, getStaffLinePosition(0)}, --2
    {getStaffLinePosition(2) + STAFFSPACEHEIGHT*0.5, getStaffLinePosition(-1) + STAFFSPACEHEIGHT*0.5}, --4
    {getStaffLinePosition(1) + STAFFSPACEHEIGHT*0.25, getStaffLinePosition(-1)}, --8
    {getStaffLinePosition(1) + STAFFSPACEHEIGHT*0.25, getStaffLinePosition(-1) + STAFFSPACEHEIGHT*0.9}, --16
    {getStaffLinePosition(2) + STAFFSPACEHEIGHT*0.3, getStaffLinePosition(-1) + STAFFSPACEHEIGHT*0.95}, --32
    {getStaffLinePosition(2) + STAFFSPACEHEIGHT*0.25, getStaffLinePosition(-3)}, --64
    {getStaffLinePosition(3) + STAFFSPACEHEIGHT*0.25, getStaffLinePosition(-3)}, --128
    {getStaffLinePosition(3) + STAFFSPACEHEIGHT*0.25, getStaffLinePosition(-4)}, --256
    {getStaffLinePosition(4) + STAFFSPACEHEIGHT*0.25, getStaffLinePosition(-4)} --512
  }
  
  FLAGYSIZE_LIST = {
    {STAFFSPACEHEIGHT*2.6}, --8
    {STAFFSPACEHEIGHT*3}, --16
    {STAFFSPACEHEIGHT*3.7}, --32
    {STAFFSPACEHEIGHT*4.5}, --64
    {STAFFSPACEHEIGHT*5.2}, --128
    {STAFFSPACEHEIGHT*6}, --256
    {STAFFSPACEHEIGHT*6.7} --512
  }
  
  DOTRADIUS = STAFFSPACEHEIGHT/5
  RESTDOTCENTERY = getStaffLinePosition(1) + STAFFSPACEHEIGHT/2
  
  DYNAMICCENTERY = getStaffLinePosition(-4)
  DYNAMICSIZEY = STAFFSPACEHEIGHT*2
  
  NOTATIONSCROLLTIME = 0.1
  SECTIONNAMESCROLLTIME = 0.35
  
  VALID_ARTICULATION_LIST = {
    {"stickingL", STAFFSPACEHEIGHT*1, 0.5},
    {"stickingR", STAFFSPACEHEIGHT*1, 0.5},
    {"stickingLR", STAFFSPACEHEIGHT*1, 0.45},
    {"staccato", STAFFSPACEHEIGHT/3.5, 0.15}, 
    {"accent", STAFFSPACEHEIGHT*0.9, 0.3},
    {"circleplus", STAFFSPACEHEIGHT*0.8, 0.4},  
    {"circle", STAFFSPACEHEIGHT*0.8, 0.4}, 
    {"plus", STAFFSPACEHEIGHT*1.25, 0.4}
    }
  
  VALID_BEAM_LIST = {"start", "continue", "secondary", "end", "none"} 
  end

function drawPreviousMeasureLine(measureIndex)
  if not currentMeasureLineData then return end
  if not gettingCurrentValues then end
  
  local xMin = currentMeasureLineData[1]
  local xMax = currentMeasureLineData[2]
  local yMin = currentMeasureLineData[3]
  local yMax = currentMeasureLineData[4]
  local img = currentMeasureLineData[5]
  local imgFileName = currentMeasureLineData[6]
  local measureLabel = currentMeasureLineData[7]
  
  if measureIndex <= #measureList then
    measureList[measureIndex][MEASURELISTINDEX_VALIDCURRENTMEASURE] = true
    end
    
  if measureLabel ~= "end" then
    local measureNumberText = tostring(measureIndex)
    local centerX = xMin + (xMax-xMin)/2
    addToNotationDrawList({"measureNumber", centerX, centerX, measureNumberText})
    addToGameData("notation", {"measure_number", nil, "\"" .. measureNumberText .. "\"", centerX, 0, centerX, 0})
    end
  
  addToNotationDrawList({"measureLine", xMin, xMax, yMin, yMax, img})
  addToGameData("notation", {"measure_line", nil, imgFileName, xMin, yMin, xMax, yMax})
  
  local xmlIdentifier
  if measureLabel == "dashed" then xmlIdentifier = "dashed" end
  if measureLabel == "double" then xmlIdentifier = "light-light" end
  if measureLabel == "end" then xmlIdentifier = "light-heavy" end
  if measureLabel == "normal" then xmlIdentifier = "regular" end
  
  addToXML("      <barline>")
  addToXML("        <bar-style>" .. xmlIdentifier .. "</bar-style>")
  addToXML("      </barline>")
  addToXML()
  end
      
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
  
function runChartCompiler()
  local fileName = "gamedata.txt"
  
  local file = io.open(getGameDataDirectory() .. fileName, "r")
  local gamedataFileText = file:read("*all")
  file:close()
  
  local drumKitName = getSettingFromFile("drumkit")
  local file = io.open(getDrumKitsDirectory() .. drumKitName .. ".txt", "r")
  local drumkitFileText = file:read("*all")
  file:close()
  
  local gemNameTable = {}
  local configTextTable = {}
  for x=1, #gemImageList do
    local gemFolderName = gemImageList[x]
    local configFilePath = getGemsDirectory() .. gemFolderName .. "/config.txt"
    local file = io.open(configFilePath, "r")
    local fileText = file:read("*all")
    file:close()
    
    tableInsert(gemNameTable, gemFolderName)
    tableInsert(configTextTable, fileText)
    end
  
  dofile(getGodotDirectory() .. "godot_reaper_environment.lua")
  local outputTextFilePath = getGodotUserDirectory() .. "output.txt"
  
  local file = io.open(getAssetsDirectory() .. "sizes.txt", "r")
  local imgSizesFileText = file:read("*all")
  file:close()
  
  local file = io.open(getTemposTextFilePath(), "r")
  local temposFileText = file:read("*all")
  file:close()
  
  local file = io.open(getEventsTextFilePath(), "r")
  local eventsFileText = file:read("*all")
  file:close()
  
  local file = io.open(getMIDIDataTextFilePath(), "r")
  local midiFileText = file:read("*all")
  file:close()
  
  local fileText = runGodotReaperEnvironment(
    true, 
    nil, 
    masterImageList,
    drumkitFileText, 
    gemNameTable, 
    configTextTable, 
    outputTextFilePath, 
    imgSizesFileText, 
    temposFileText,
    eventsFileText, 
    midiFileText,
    drumTake,
    drumTrack,
    drumTrackID,
    eventsTake,
    eventsTrack,
    eventsTrackID
    )
  
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
  
function uploadGameData()
  local str = ""
  
  local function addToStr(header, gameDataTable)
    str = str .. header .. "\n" .. table.concat(gameDataTable, "\n") .. "\n"
    end
  
  for x=#gameDataTable_notations-1-#SPECIAL_MEASURE_HEADER_LIST, 1, -1 do
    if gameDataTable_notations[x] == "measure" and gameDataTable_notations[x+1+#SPECIAL_MEASURE_HEADER_LIST] == "measure" then
      for y=0, #SPECIAL_MEASURE_HEADER_LIST do
        table.remove(gameDataTable_notations, x)
        end
      end
    end
    
  addToStr("GENERAL", gameDataTable_general)
  addToStr("STATES", gameDataTable_states)
  addToStr("NOTES", gameDataTable_notes)
  addToStr("BEAT_LINES", gameDataTable_beatLines)
  addToStr("HIHAT_PEDALS", gameDataTable_hihatPedals)
  addToStr("SUSTAINS", gameDataTable_sustains)
  addToStr("NOTATIONS", gameDataTable_notations)
  
  local fileName = "gamedata.txt"
  
  local file = io.open(getGameDataDirectory() .. fileName, "w+")
  file:write(str)
  file:close()
  
  local file = io.open(getGodotProjectDirectory() .. fileName, "w+")
  file:write(str)
  file:close()
  
  uploadedGameData = true
  end

function addToGameData(dataType, values)
  if uploadedGameData then return end
  
  if dataType == "general" then
    tableInsert(gameDataTable_general, table.concat(values, " "))
    end
  if dataType == "state" then
    tableInsert(gameDataTable_states, table.concat(values, " "))
    end
  if dataType == "note" then
    tableInsert(gameDataTable_notes, table.concat(values, " "))
    end
  if dataType == "beatline" then
    tableInsert(gameDataTable_beatLines, table.concat(values, " "))
    end
  if dataType == "hihatpedal" then
    tableInsert(gameDataTable_hihatPedals, table.concat(values, " "))
    end
  if dataType == "sustain" then
    tableInsert(gameDataTable_sustains, table.concat(values, " "))
    end
  if dataType == "notation" then
    local header = values[1]
    if header ~= "measure" and not isInTable(SPECIAL_MEASURE_HEADER_LIST, header) then
      if not values[2] then --qnQuantized to time
        values[2] = -1
        end
      if not values[3] then --imgFileName
        values[3] = "nil"
        if values[1] == "sprite" then
          debug_printStack()
          end
        end
      values[4] = (values[4] - NOTATION_XMIN) / STAFFSPACEHEIGHT
      values[5] = (values[5] - NOTATION_YMIN) / STAFFSPACEHEIGHT
      values[6] = (values[6] - NOTATION_XMIN) / STAFFSPACEHEIGHT
      values[7] = (values[7] - NOTATION_YMIN) / STAFFSPACEHEIGHT
      end
    tableInsert(gameDataTable_notations, table.concat(values, " "))
    end
  end

function initializeGameData()
  uploadedGameData = false
  
  gameDataTable_general = {}
  gameDataTable_states = {}
  gameDataTable_notes = {}
  gameDataTable_beatLines = {}
  gameDataTable_hihatPedals = {}
  gameDataTable_sustains = {}
  gameDataTable_notations = {}
  end
  
function getXMLDirectory()
  return getScriptDirectory()
  end
  
function uploadXML()
  local str = table.concat(xmlTable, "\n")
  
  local dir = getXMLDirectory()
  local fileName = "generatedXML.xml"
  local filePath = dir .. fileName
  
  local file = io.open(filePath, "w+")
  file:write(str)
  file:close()
  end

function addToXML(str)
  if gettingCurrentValues then return end
  
  if not str then
    str = ""
    end
  tableInsert(xmlTable, str)
  end

function initializeXML()
  xmlTable = {}
  
  xmlSlurNumber = 0
  xmlTupletNumber = 0
  end
  
function processNotationMeasures()
  initializeXML()
  
  addToXML("<?xml version=\"1.0\" encoding='UTF-8' standalone='no' ?>")
  addToXML("<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 3.0 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">")
  addToXML()
  
  addToXML("<score-partwise version=\"3.0\">")
  
  addToXML("  <part-list>")
  addToXML("    <score-part id=\"P1\">")
  addToXML("      <part-name>Violin</part-name>")
  addToXML("      <score-instrument id=\"P1-I1\">")
  addToXML("        <instrument-name>Violin</instrument-name>")
  addToXML("      </score-instrument>")
  addToXML("    </score-part>")
  addToXML("  </part-list>")
  addToXML()
  
  addToXML("  <part id=\"P1\">")
  addToXML()
  
  if currentRefreshState ~= REFRESHSTATE_KEEPSELECTIONS then
    masterSelectedItemList = {}
    filteredSelectedItemList = {}
    voice1Filter = true
    voice2Filter = true
    end
  currentGradualDynamicXMin = nil
  currentMeasureLineData = nil
  currentNumEmptyMeasures = 0
  prevTextCenterX = nil
  validBeatMeasureList = {}
  
  measureBoundXMin = NOTATIONDRAWAREA_XMIN
  
  measurePageList = {}
  local currentXOffset = measureBoundXMin
  local currentPageXPos = measureBoundXMin

  local function setPage(index, boundXMin)
    if measurePageList[#measurePageList] == index then
      error("Measure is too long to fit on page!")
      end
    tableInsert(measurePageList, {index, {boundXMin, measureBoundXMin}})
    currentXOffset = NOTATIONDRAWAREA_XMIN
    currentPageXPos = boundXMin
    end

  for measureIndex=1, #measureList do
    measureList[measureIndex][MEASURELISTINDEX_TUPLETLIST] = {{}, {}}
    end
    
  masterRhythmListBothVoices = {{}, {}}
  for measureIndex=1, #measureList do
    --getMeasureRhythmList(measureIndex, 1)
    local success, result = pcall(getMeasureRhythmList, measureIndex, 1)
    if success then masterRhythmListBothVoices[1][measureIndex] = result else setError(ERROR_RHYTHMLIST, result) break end
    end
  for measureIndex=1, #measureList do
    local success, result = pcall(getMeasureRhythmList, measureIndex, 2)
    if success then masterRhythmListBothVoices[2][measureIndex] = result else setError(ERROR_RHYTHMLIST, result) break end
    end
    
  NUMSUCCESSFULMEASURES = math.min(#masterRhythmListBothVoices[1], #masterRhythmListBothVoices[2])
  
  local function truncateList(list)
    while #list > NUMSUCCESSFULMEASURES do
      table.remove(list)
      end
    end
    
  local function addChokes(voiceIndex)
    local chokeList = chokeListBothVoices[voiceIndex]
    local masterRhythmList = masterRhythmListBothVoices[voiceIndex]
    
    --TODO: optimize
    for chokeListIndex=#chokeList, 1, -1 do
      local chokeQN = chokeList[chokeListIndex]
      local found = false
      for measureIndex=#masterRhythmList, 1, -1 do
        local measureRhythmList = masterRhythmList[measureIndex]
        for rhythmListIndex=#measureRhythmList, 1, -1 do
          local rhythmData = measureRhythmList[rhythmListIndex]
          local rhythmQN = rhythmData[RHYTHMLISTINDEX_QN]
          if rhythmQN < chokeQN and rhythmData[RHYTHMLISTINDEX_CHORD] then
            rhythmData[RHYTHMLISTINDEX_CHOKE] = true
            found = true
            break
            end
          if rhythmQN == chokeQN then
            throwError("Choke event on another note/rest!", measureIndex)
            end
          end
        if found then
          break
          end
        end
      end
    end
    
  truncateList(masterRhythmListBothVoices[1])
  truncateList(masterRhythmListBothVoices[2])
  
  addChokes(1)
  addChokes(2)
  
  storeDrawBeamStates(1)
  storeDrawBeamStates(2)
  
  masterRecentTiePosDataBothVoices = {{}, {}}
  for measureIndex=1, NUMSUCCESSFULMEASURES do
    local prevMeasureBoundXMin = measureBoundXMin
    processMeasure(measureIndex)
    currentXOffset = (measureBoundXMin - currentPageXPos)
    if measureIndex==1 or currentXOffset>=NOTATION_XMAX-100 then --current measure is page
      setPage(measureIndex, prevMeasureBoundXMin)
    else
      tableInsert(measurePageList[#measurePageList], {prevMeasureBoundXMin, measureBoundXMin})
      end
    end
  
  addToXML("  </part>")
  addToXML("</score-partwise>")
  
  uploadXML()
  
  addToGameData("general", {"center_staff_line", (getStaffLinePosition(0) - NOTATION_YMIN) / STAFFSPACEHEIGHT})
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

function getStemYPercentageDownTheNote(notationLabel)
  for x=1, #VALID_NOTEHEAD_LIST do
    local data = VALID_NOTEHEAD_LIST[x]
    if data[1] == notationLabel then
      return data[2]
      end
    end
  
  throwError("No intersection data defined! " .. notationLabel)
  end
  
function findIndexInListEqualOrGreaterThan(list, target, subTableIndex)
  local low = 1
  local high = #list
  local result = nil -- To store the index of the first value >= target

  while low <= high do
    local mid = floor((low + high) / 2)
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
    local mid = floor((low + high) / 2)
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

function isTupletOverride(rhythmList, rhythmListIndex, measureTupletList)
  local startQN = rhythmList[rhythmListIndex][RHYTHMLISTINDEX_QN]
  
  if measureTupletList then
    local noteTupletList = getNoteTupletList(startQN, measureTupletList)
    if #noteTupletList > 0 then
      return true
      end
    end
  
  return false
  end
  
function isRhythmOverriden(rhythmList, rhythmListIndex, voiceIndex, measureTupletList)
  local rhythmOverrideList = rhythmOverrideListBothVoices[voiceIndex]
  local startQN = rhythmList[rhythmListIndex][RHYTHMLISTINDEX_QN]
  
  local rhythmNum, rhythmDenom
  for x=1, #rhythmOverrideList do --TODO: binary search optimize
    local data = rhythmOverrideList[x]
    local rhythmOverrideQNStart = data[RHYTHMOVERRIDELISTINDEX_STARTQN]
    local rhythmOverrideQNEnd = data[RHYTHMOVERRIDELISTINDEX_ENDQN]
    
    if startQN >= rhythmOverrideQNStart and startQN < rhythmOverrideQNEnd then
      return true
      end
    end
  
  if isTupletOverride(rhythmList, rhythmListIndex, measureTupletList) then
    return true
    end
  
  return false
  end

function getTupletFactorNumDenom(tupletModifier)
  if not tupletModifier then return 1, 1 end
  
  if tupletModifier == "t" then return 2, 3 end
  if tupletModifier == "q" then return 4, 5 end
  if tupletModifier == "s" then return 4, 7 end
  
  throwError("Not a valid tuplet modifier!")
  end
  
function getFlagOrRestLabel(simplifiedRhythmNum, simplifiedRhythmDenom, isRest, rhythmList, rhythmListIndex, voiceIndex, measureTupletList)
  local function getSimplifiedTupletModifier()
    local data = rhythmList[rhythmListIndex]
    
    local rhythmNum = data[RHYTHMLISTINDEX_NUM]
    local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
    local tupletFactorNum = data[RHYTHMLISTINDEX_TUPLETFACTORNUM]
    local tupletFactorDenom = data[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
    local hasDot = data[RHYTHMLISTINDEX_HASDOT]
    
    local actualRhythmNum, actualRhythmDenom = getActualRhythmNumDenom(data)
    
    local tupletModifier
    local tupletFactorNum = 1
    local tupletFactorDenom = 1
    if actualRhythmDenom % 3 == 0 then
      tupletModifier = "t"
      end
    if actualRhythmDenom % 5 == 0 then
      tupletModifier = "q"
      end
    if actualRhythmDenom % 7 == 0 then
      tupletModifier = "s"
      end
    
    local tupletFactorNum, tupletFactorDenom = getTupletFactorNumDenom(tupletModifier)
    
    local baseRhythmNum = rhythmNum
    local baseRhythmDenom = rhythmDenom
    
    --local baseRhythmNum, baseRhythmDenom = simplifyFraction(actualRhythmNum*tupletFactorDenom, actualRhythmDenom*tupletFactorNum)
    return tupletModifier, baseRhythmNum, baseRhythmDenom
    end
    
  local function getNumberAndDot(rhythmNum, rhythmDenom)
    if rhythmNum == 1 then
      return rhythmDenom, false
      end
    end
  
  local tupletModifier, baseRhythmNum, baseRhythmDenom = getSimplifiedTupletModifier()

  local num, hasDot = getNumberAndDot(baseRhythmNum, baseRhythmDenom)
  
  if not num then
    return
    end
  
  local header
  if isRest then
    header = "rest"
  else
    header = "flag"
    end
  
  local label = header .. "_" .. removeExcessZeroes(num)
  
  local notatedRhythmDenom = baseRhythmDenom
  if hasDot then
    notatedRhythmDenom = round(notatedRhythmDenom/2)
    end
    
  return label, notatedRhythmDenom, tupletModifier, hasDot
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
  local _, _, _, chartTextCount = reaper.MIDI_CountEvts(drumTake)
  
  local originalTextEvtID = findAnyTextEventIDAtPPQPOS(drumTake, noteStartPPQPOS)
  if not originalTextEvtID then
    return
    end
  
  local indexOffset = 0
  local doneWithLeftSide, doneWithRightSide
  local testCount = 0

  while true do
    local textEvtID = originalTextEvtID + indexOffset
    local retval, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
    
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
    
function getBeamGroupingsTable(beamGroupingsStr, secondaryBeamGroupingsStr, timeSigNum, timeSigDenom, measureIndex)
  beamGroupingsStr = cleanPunctuationFromStr(beamGroupingsStr)
  secondaryBeamGroupingsStr = cleanPunctuationFromStr(secondaryBeamGroupingsStr)
  
  if getNumCharsInString(secondaryBeamGroupingsStr, ";") > getNumCharsInString(beamGroupingsStr, ";") then
    throwError("More secondary beam groupings than main beam groupings! " .. beamGroupingsStr .. " " .. secondaryBeamGroupingsStr)
    end
    
  --reaper.ShowConsoleMsg("---------\nMETER: " .. timeSigNum .. "/" .. timeSigDenom .. "\n")
  --reaper.ShowConsoleMsg("BEFORE: " .. beamGroupingsStr .. " " .. secondaryBeamGroupingsStr .. "\n")
  
  --add missing defaults
  local beamGroupingsTable = {{}, {}, {}, {}, {}} --8ths, 16ths, 32nds, 64ths, 128ths
  local firstMainBeamGroupingTableIndex = math.max(round(timeSigDenom/8), 1)
  local firstSecondaryBeamGroupingTableIndex = math.max(firstMainBeamGroupingTableIndex, 2)
  
  local numMainGroupings
  if #beamGroupingsStr > 0 then
    numMainGroupings = getNumCharsInString(beamGroupingsStr, ";") + 1
  else
    numMainGroupings = 0
    end
  local numSecondaryGroupings
  if #secondaryBeamGroupingsStr > 0 then
    numSecondaryGroupings = getNumCharsInString(secondaryBeamGroupingsStr, ";") + 1
  else
    numSecondaryGroupings = 0
    end
  local numValidGroupings = #beamGroupingsTable - firstMainBeamGroupingTableIndex + 1
  
  local function getGroupingStr(str, semicolonIndex)
    local startIndex = 1
    local endIndex
    for y=firstMainBeamGroupingTableIndex, semicolonIndex do
      if y == semicolonIndex then
        local endSemicolonIndex = string.find(str, ";", startIndex)
        if endSemicolonIndex then
          endIndex = endSemicolonIndex - 1
        else
          endIndex = #str
          end
      else
        startIndex = string.find(str, ";", startIndex) + 1
        end
      end
      
    return string.sub(str, startIndex, endIndex)
    end
  
  local function getBeamValuesInGroupingStr(groupingStr)
    local list = {}
    
    local exitLoop = false
    local totalMainBeamedNotes = 0
    while not exitLoop do
      local commaIndex = string.find(groupingStr, ",")
      local numBeamedNotes
      if commaIndex then
        numBeamedNotes = string.sub(groupingStr, 1, commaIndex-1)
        groupingStr = string.sub(groupingStr, commaIndex+1, #groupingStr)
      else
        numBeamedNotes = groupingStr
        exitLoop = true
        end
      numBeamedNotes = tonumber(numBeamedNotes)
      if not numBeamedNotes then
        throwError("Invalid beam grouping syntax! " .. beamGroupingsStr)
        end
      
      tableInsert(list, numBeamedNotes)
      end
    
    return list
    end
    
  local function addMissingMainBeamsToMainStr()
    local startIndex = findCharFromEnd(beamGroupingsStr, ";")
    if startIndex then
      startIndex = startIndex + 1
    else
      startIndex = 1
      end
    local endIndex = #beamGroupingsStr

    local groupingStr = string.sub(beamGroupingsStr, startIndex, endIndex)

    local beamValues = getBeamValuesInGroupingStr(groupingStr)
    
    for beamGroupingTableIndex=firstMainBeamGroupingTableIndex+numMainGroupings, #beamGroupingsTable do
      for x=1, #beamValues do
        beamValues[x] = round(beamValues[x] * 2)
        end
      beamGroupingsStr = beamGroupingsStr .. ";" .. table.concat(beamValues, ",")
      end
      
    beamGroupingsStr = cleanPunctuationFromStr(beamGroupingsStr)
    
    if getNumCharsInString(beamGroupingsStr, ";") ~= numValidGroupings-1 then
      throwError("Bad number of semicolons in beamGroupingsStr! " .. beamGroupingsStr)
      end
    end
  
  local function addMissingSecondaryBeamsToSecondaryStr()
    --add missing secondary beams after
    local numSecondaryGroupingsAdded
    if #secondaryBeamGroupingsStr == 0 then
      numSecondaryGroupingsAdded = 0
    else
      numSecondaryGroupingsAdded = getNumCharsInString(secondaryBeamGroupingsStr, ";") + 1
      end

    for beamGroupingTableIndex=firstSecondaryBeamGroupingTableIndex+numSecondaryGroupings, #beamGroupingsTable do
      local groupingStr = getGroupingStr(beamGroupingsStr, beamGroupingTableIndex)
      secondaryBeamGroupingsStr = secondaryBeamGroupingsStr .. ";" .. groupingStr
      numSecondaryGroupingsAdded = numSecondaryGroupingsAdded + 1
      end
    
    secondaryBeamGroupingsStr = cleanPunctuationFromStr(secondaryBeamGroupingsStr)
    
    --add placeholder identical secondary beams before for 8th notes, etc.
    for beamGroupingTableIndex=firstMainBeamGroupingTableIndex, numValidGroupings-numSecondaryGroupingsAdded do
      local groupingStr = getGroupingStr(beamGroupingsStr, beamGroupingTableIndex)
      secondaryBeamGroupingsStr = groupingStr .. ";" .. secondaryBeamGroupingsStr
      end
    
    if getNumCharsInString(secondaryBeamGroupingsStr, ";") ~= numValidGroupings-1 then
      throwError("Bad number of semicolons in secondaryBeamGroupingsStr! " .. secondaryBeamGroupingsStr)
      end
    end
  
  local function storeAllBeamGroupingsInTable()
    for x=0, numValidGroupings-1 do
      local beamGroupingTableIndex = firstMainBeamGroupingTableIndex + x
      local rhythmDenom = round(2^(2+beamGroupingTableIndex))
      
      local beamGroupingTable = beamGroupingsTable[beamGroupingTableIndex]
      
      local semicolonIndex = string.find(beamGroupingsStr, ";")
      local groupingStr
      if semicolonIndex then
        groupingStr = string.sub(beamGroupingsStr, 1, semicolonIndex-1)
        beamGroupingsStr = string.sub(beamGroupingsStr, semicolonIndex+1, #beamGroupingsStr)
      else
        groupingStr = beamGroupingsStr
        beamGroupingsStr = ""
        end

      local mainBeamValues = getBeamValuesInGroupingStr(groupingStr)
      local totalMainBeamedNotes = 0
      local mainBeamRhythmValues = {}
      --reaper.ShowConsoleMsg("\n" .. timeSigNum .. "/" .. timeSigDenom .. ": " .. rhythmDenom .. "\n")
      for x=1, #mainBeamValues do 
        local numBeamedNotes = mainBeamValues[x]
        local rhythmNum, rhythmDenom = simplifyFraction(totalMainBeamedNotes, rhythmDenom)
        totalMainBeamedNotes = round(totalMainBeamedNotes + numBeamedNotes)
        --reaper.ShowConsoleMsg("TEST: " .. rhythmNum .. "/" .. rhythmDenom .. "\n")
        tableInsert(mainBeamRhythmValues, {rhythmNum, rhythmDenom})
        end
        
      local numNotesInMeasure = round(timeSigNum * (rhythmDenom / timeSigDenom))
      if totalMainBeamedNotes ~= numNotesInMeasure then
        throwError("Main beams don't add up to time signature! " .. beamGroupingsStr .. " " .. beamGroupingTableIndex .. " " .. totalMainBeamedNotes .. " " .. numNotesInMeasure, measureIndex)
        end
      
      local semicolonIndex = string.find(secondaryBeamGroupingsStr, ";")
      local secondaryGroupingStr
      if semicolonIndex then
        secondaryGroupingStr = string.sub(secondaryBeamGroupingsStr, 1, semicolonIndex-1)
        secondaryBeamGroupingsStr = string.sub(secondaryBeamGroupingsStr, semicolonIndex+1, #secondaryBeamGroupingsStr)
      else
        secondaryGroupingStr = secondaryBeamGroupingsStr
        secondaryBeamGroupingsStr = ""
        end
    
      local secondaryBeamValues = getBeamValuesInGroupingStr(secondaryGroupingStr)
      local totalSecondaryBeamedNotes = 0
      local currentMainBeamIndex = 1
      for x=1, #secondaryBeamValues do 
        local numBeamedNotes = secondaryBeamValues[x]
        local totalRhythmNum, totalRhythmDenom = simplifyFraction(totalSecondaryBeamedNotes, rhythmDenom)
        totalSecondaryBeamedNotes = round(totalSecondaryBeamedNotes + numBeamedNotes)
        
        local isSecondaryBeam = true
        for y=1, #mainBeamRhythmValues do
          local data = mainBeamRhythmValues[y]
          if data[1] == totalRhythmNum and data[2] == totalRhythmDenom then
            if y ~= currentMainBeamIndex then
              throwError("Secondary beams in main beam #" .. y .. " do not add up!" .. secondaryGroupingStr)
              end
            isSecondaryBeam = false
            currentMainBeamIndex = currentMainBeamIndex + 1
            break
            end
          end
        
        --reaper.ShowConsoleMsg(tostring(isSecondaryBeam) .. ": " .. totalRhythmNum .. "/" .. totalRhythmDenom .. "\n")
        tableInsert(beamGroupingTable, {isSecondaryBeam, totalRhythmNum, totalRhythmDenom})
        end
        
      if totalSecondaryBeamedNotes ~= totalMainBeamedNotes then
        throwError("Secondary beams do not add up to main beams! " .. secondaryGroupingStr .. " " .. totalSecondaryBeamedNotes .. " " .. totalMainBeamedNotes)
        end
      end
    end
    
  ----
  
  addMissingMainBeamsToMainStr()
  
  addMissingSecondaryBeamsToSecondaryStr()
  
  storeAllBeamGroupingsInTable()
  
  return beamGroupingsTable
  end

function getMIDINoteVoice(noteID)
  local data = MIDI_DRUMS_noteEvents[noteID+1]
  
  local startPPQPOS = getValueFromTable(data, "ppqpos_start")
  local channel = getValueFromTable(data, "channel")
  local midiNoteNum = getValueFromTable(data, "pitch")
  local notationTextEvtID = getValueFromTable(data, "text_event_id")
  local notationTextEvtMsg = getValueFromTable(data, "text_event_message")
  
  if not notationTextEvtID then
    return 1
    end
    
  local data = separateString(notationTextEvtMsg)
  
  local header = data[1]
  local channel = data[2]
  local midiNoteNum = data[3]
  local str = string.sub(notationTextEvtMsg, 6 + #tostring(channel) + 1 + #tostring(midiNoteNum) + 1, #notationTextEvtMsg)
    
  local notationValues = separateString(str)
  local voice, articulation, ornament, text, notehead
  for x=1, #notationValues, 2 do
    local header = notationValues[x]
    local val = removeQuotes(notationValues[x+1])
    
    if header == "voice" then
      return val
      end
    end
    
  return 1
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
  
function getNotationProperties(midiNoteNum, channel)
  local notehead, staffLine, articulation

  local noteType = getNoteType(midiNoteNum)
  local noteState = getNoteState(midiNoteNum, channel)
  
  local side = getNoteProperty(midiNoteNum, "side")
  if side == "left" then
    staffLine = 3
    end
  if side == "center" then
    staffLine = 3.5
    end
  if side == "right" then
    staffLine = 4
    end
    
  if noteType == "kick" then
    local foot = getNoteProperty(midiNoteNum, "foot")
    if foot == "right" then
      staffLine = -1.5
      end
    if foot == "left" then
      staffLine = -2
      end
    if noteState == "head" then
      notehead = "normal"
      end
    end
  
  if noteType == "snare" then
    staffLine = 0.5
    if noteState == "head" then
      notehead = "normal"
      end
    if noteState == "sidestick" then
      notehead = "x"
      end
    if noteState == "rim" then
      notehead = "x"
      end
    end
  
  if noteType == "racktom" then
    local pitch = getNoteProperty(midiNoteNum, "pitch")
    if pitch == "F" then
      staffLine = 2
      end
    if pitch == "E" then
      staffLine = 1.5
      end
    if pitch == "D" then
      staffLine = 1
      end
    if noteState == "head" then
      notehead = "normal"
      end
    if noteState == "rim" then
      notehead = "x"
      end
    end
  
  if noteType == "floortom" then
    local pitch = getNoteProperty(midiNoteNum, "pitch")
    if pitch == "A" then
      staffLine = -0.5
      end
    if pitch == "G" then
      staffLine = -1
      end
    if noteState == "head" then
      notehead = "normal"
      end
    if noteState == "rim" then
      notehead = "x"
      end
    end
  
  if noteType == "octoban" then
    local pitch = getNoteProperty(midiNoteNum, "pitch")
    if pitch == "G" then
      staffLine = 2.5
      end
    if pitch == "F" then
      staffLine = 2
      end
    if pitch == "E" then
      staffLine = 1.5
      end
    if pitch == "D" then
      staffLine = 1
      end
    if noteState == "head" then
      notehead = "square"
      end
    end
    
  if noteType == "hihat" then
    if noteState == "closed" then
      notehead = "x"
      staffLine = 2.5
      end
    if noteState == "open" then
      notehead = "x"
      staffLine = 2.5
      articulation = "circle"
      end
    if noteState == "halfopen" then
      notehead = "x"
      staffLine = 2.5
      end
    if noteState == "stomp" then
      notehead = "x"
      staffLine = -2.5
      end
    if noteState == "splash" then
      notehead = "circle_x"
      staffLine = -2.5
      end
    
    if noteState == "lift" then
      notehead = "none"
      staffLine = 0
      end
    end
  
  if noteType == "ride" then
    staffLine = 2
    if noteState == "normal" then
      notehead = "x"
      end
    if noteState == "bell" then
      notehead = "diamond"
      end  
    end
  
  if noteType == "crash" then
    if noteState == "normal" then
      notehead = "x"
      end
    end
    
  if noteType == "china" then
    if noteState == "normal" then
      notehead = "x"
      end
    end
  
  if noteType == "splash" then
    if noteState == "normal" then
      notehead = "x"
      end
    end
  
  if noteType == "stack" then
    if noteState == "normal" then
      notehead = "x"
      end
    end
  
  if noteType == "bell" then
    if noteState == "normal" then
      notehead = "diamond"
      staffLine = 2.5
      end
    end
    
  if not notehead or not staffLine then
    throwError("Missing note state! " .. midiNoteNum .. " " .. channel)
    end
    
  return notehead, staffLine, articulation
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
    
    local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
    
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
      setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, newMsg)
      end
  else
    if valToInsert then
      local msg = "NOTE " .. noteChannel .. " " .. noteMIDINoteNum .. " text " .. valToInsert
      insertTextSysexEvt(drumTake, false, false, noteStartPPQPOS, NOTATION_EVENT, msg)
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
  
function isBeamingOverRests(qn)
  if not qn then
    debug_printStack()
    end
  local index = findIndexInListEqualOrLessThan(beamOverRestsTextEvtList, qn, 1)
  return beamOverRestsTextEvtList[index][2]
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
    local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, articulationTextEvtID)
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
      deleteTextSysexEvt(drumTake, articulationTextEvtID, articulationList, ARTICULATIONLISTINDEX_TEXTEVTID)
    else
      setTextSysexEvt(drumTake, articulationTextEvtID, nil, nil, nil, evtType, table.concat(values, " "))
      end
  else
    if valStr then
      insertTextSysexEvt(drumTake, false, false, chordPPQPOS, TEXT_EVENT, "articulation_" .. voiceIndex .. " " .. valStr, articulationList, ARTICULATIONLISTINDEX_PPQPOS, ARTICULATIONLISTINDEX_TEXTEVTID)
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
      setTextSysexEvt(drumTake, beamOverrideTextEvtID, nil, nil, nil, TEXT_EVENT, valStr)
    else
      insertTextSysexEvt(drumTake, false, false, chordPPQPOS, TEXT_EVENT, valStr, beamOverrideList, BEAMOVERRIDELISTINDEX_PPQPOS, BEAMOVERRIDELISTINDEX_TEXTEVTID)
      end
  elseif beamOverrideTextEvtID then
    deleteTextSysexEvt(drumTake, beamOverrideTextEvtID, beamOverrideList, BEAMOVERRIDELISTINDEX_TEXTEVTID)
    end
  end
  
function getRestYCoordinates(restLabel)
  local num = tonumber(string.sub(restLabel, 6, #restLabel))
  local index = round(math.log(num)/math.log(2) + 1)
  local data = RESTYCOOR_LIST[index]
  return data[1], data[2]
  end

function getFlagYSize(flagLabel)
  local num = tonumber(string.sub(flagLabel, 6, #flagLabel))
  local index = round(math.log(num)/math.log(2) - 2)
  local data = FLAGYSIZE_LIST[index]
  if not data then reaper.ShowConsoleMsg("ERR: " .. flagLabel .. " " .. index .. "\n") debug_printStack() end
  return data[1], data[2]
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
    local percentageImageStart = time/timeRange - floor(time/timeRange)
    local yOffset = floor(convertRange(percentageImageStart, 1, 0, yMin, yMax))
    
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
        addImage(drawList, imgRing, gemXMin-factor, gemYMin-factor, gemXMax+factor, gemYMax+factor, 0, 0, 1, 1, hexColor(color_r, color_g, color_b))
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
    if reaper.MIDIEditor_GetTake(midiEditor) ~= drumTake then return end
    
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

function addNotationStrToList()
  local function findAnIndex(list, target)
    local low = 1
    local high = #list
    local result = nil -- To store the index of the first value >= target
  
    while low <= high do
      local mid = floor((low + high) / 2)
      local midValue = list[mid][1] -- First value in the subtable
  
      if midValue == target then
        return mid -- Return immediately if an exact match is found
      elseif midValue > target then
        result = mid -- Potential candidate
        high = mid - 1 -- Continue searching the left half
      else
        low = mid + 1 -- Search the right half
        end
      end
    end
    
  local function getNoteIndex(noteList, targetPPQPOS, targetChannel, targetMIDINoteNum)
    local index = findAnIndex(noteList, targetPPQPOS)
    
    local testCount = 0
    while true do
      local data = noteList[index]
      if not data then
        throwError("Invalid note/channel in MIDI! Ch" .. targetChannel .. " #" .. targetMIDINoteNum)
        end
      local ppqpos = data[NOTELISTINDEX_STARTPPQPOS]
      if ppqpos < targetPPQPOS or index == 1 then
        break
        end
      index = index - 1
      testCount = testCount + 1
      if testCount == 100 then
        throwError("ERROR1 GETNOTEINDEX\n")
        end
      end
    
    --reaper.ShowConsoleMsg("-------\n")
    local testCount = 0
    while true do
      local data = noteList[index]
      local ppqpos = data[NOTELISTINDEX_STARTPPQPOS]
      local channel = data[NOTELISTINDEX_CHANNEL]
      local midiNoteNum = data[NOTELISTINDEX_MIDINOTENUM]
      if ppqpos == targetPPQPOS and channel == targetChannel and midiNoteNum == targetMIDINoteNum then
        return index
        end
      index = index + 1
      testCount = testCount + 1
      
      --reaper.ShowConsoleMsg(ppqpos .. " == " .. targetPPQPOS .. ", " .. channel .. " == " .. targetChannel .. ", " .. midiNoteNum .. " == " .. targetMIDINoteNum .. "\n")
      
      if testCount == 100 then
        reaper.ShowConsoleMsg("PPQPOS: " .. targetPPQPOS .. " Ch: " .. targetChannel .. " MIDI #: " .. targetMIDINoteNum .. "\n")
        throwError("ERROR2 GETNOTEINDEX\n")
        end
      end
    end
  
  local function getArticulationIndex(list, targetPPQPOS)
    local index = findAnIndex(list, targetPPQPOS)
    return index
    end
  
  local function getBeamIndex(list, targetPPQPOS)
    local index = findAnIndex(list, targetPPQPOS)
    return index
    end
    
  local function getTupletIndex(list, targetPPQPOS, targetChannel)
    local index = findAnIndex(list, targetPPQPOS)

    local testCount = 0
    while true do
      local data = list[index]
      local ppqpos = data[TUPLETLISTINDEX_STARTPPQPOS]
      if ppqpos < targetPPQPOS or index == 1 then
        break
        end
      index = index - 1
      testCount = testCount + 1
      if testCount == 100 then
        error("ERROR1 GETNOTEINDEX\n")
        end
      end
    
    local testCount = 0
    while true do
      local data = list[index]
      local ppqpos = data[TUPLETLISTINDEX_STARTPPQPOS]
      local channel = data[TUPLETLISTINDEX_CHANNEL]
      if ppqpos == targetPPQPOS and channel == targetChannel then
        return index
        end
      index = index + 1
      testCount = testCount + 1
      if testCount == 100 then
        error("ERROR2 GETTUPLETINDEX\n")
        end
      end
    end
  
  local function getRhythmOverrideIndex(list, targetPPQPOS)
    local index = findAnIndex(list, targetPPQPOS)
    return index
    end
  
  local function getSustainIndex(list, targetPPQPOS)
    local index = findAnIndex(list, targetPPQPOS)
    return index
    end
    
  local function getDynamicsIndex(list, targetPPQPOS)
    local index = findAnIndex(list, targetPPQPOS)
    return index
    end
    
  for i, data in ipairs(MIDI_DRUMS_textEvents) do
    local ppqpos = getValueFromTable(data, "ppqpos")
    local time = getValueFromTable(data, "time")
    local evtType = getValueFromTable(data, "event_type")
    local msg = getValueFromTable(data, "message")
    
    if evtType == NOTATION_EVENT then
      local data = separateString(msg)
      
      local header = data[1]
      
      if header == "NOTE" then
        local channel = data[2]
        local midiNoteNum = data[3]
        
        local list, index
        local laneType, voiceIndex
        if isLaneOverride(midiNoteNum) then
          laneType = getNoteType(midiNoteNum)
          voiceIndex = tonumber(string.sub(laneType, #laneType, #laneType))
          
          if laneType == "tuplet1" or laneType == "tuplet2" then
            list = tupletListBothVoices[voiceIndex]
            index = getTupletIndex(list, ppqpos, channel)
            end
          if laneType == "rhythm1" or laneType == "rhythm2" then
            list = rhythmOverrideListBothVoices[voiceIndex]
            index = getRhythmOverrideIndex(list, ppqpos)
            end
          if laneType == "sustain1" or laneType == "sustain2" then
            list = sustainListBothVoices[voiceIndex]
            index = getSustainIndex(list, ppqpos)
            end
            
          if laneType == "dynamics" then
            list = dynamicList
            index = getDynamicsIndex(list, ppqpos)
            end
        else
          list = noteList
          index = getNoteIndex(list, ppqpos, channel, midiNoteNum)
          end
          
        local str = string.sub(msg, 6 + #tostring(channel) + 1 + #tostring(midiNoteNum) + 1, #msg)
          
        local notationValues = separateString(str)
        local voice, articulation, ornament, text, notehead
        for x=1, #notationValues, 2 do
          local header = notationValues[x]
          local val = removeQuotes(notationValues[x+1])
          
          if not isLaneOverride(midiNoteNum) then
            if header == "voice" then
              local voiceIndex
              if val == 2 then
                voiceIndex = 2
              else
                voiceIndex = 1
                end
              list[index][NOTELISTINDEX_VOICEINDEX] = voiceIndex
              end
              
            if header == "text" then
              local values = separateString(val)
              for x=1, #values do
                local value = values[x]

                if value == "ghost" then
                  list[index][NOTELISTINDEX_GHOST] = true
                  end
                if value == "noghost" then
                  list[index][NOTELISTINDEX_GHOST] = false
                  end
                if value == "grace" or value == "flamgrace" or value == "flam" then
                  list[index][NOTELISTINDEX_GRACESTATE] = value
                  end
                end
              end
          
          elseif header == "text" then
            if laneType == "tuplet1" or laneType == "tuplet2" then
              local values = separateString(val)
          
              local baseDenom = tonumber(values[1])
              local ratioStr = values[2]
              local tupletNum, tupletDenom
              
              if not isInTable(VALID_RHYTHM_DENOM_LIST, baseDenom) then
                reaper.ShowConsoleMsg(val .. " " .. midiNoteNum .. "\n")
                throwError("Invalid tuplet base rhythm!", nil, time)
                end
              if not ratioStr then
                throwError("No tuplet ratio detected on MIDI note!", nil, time)
                end
                
              local colonIndex = string.find(ratioStr, ":")
              if colonIndex then
                tupletNum = tonumber(string.sub(ratioStr, 1, colonIndex-1))
                tupletDenom = tonumber(string.sub(ratioStr, colonIndex+1, #ratioStr))
              else
                if ratioStr == "triplet" then
                  tupletNum = 3
                  tupletDenom = 2
                elseif ratioStr == "quintuplet" then
                  tupletNum = 5
                  tupletDenom = 4
                elseif ratioStr == "sextuplet" then
                  tupletNum = 6
                  tupletDenom = 4
                elseif ratioStr == "septuplet" then
                  tupletNum = 7
                  tupletDenom = 4
                else
                  tupletNum = tonumber(string.sub(ratioStr, 1, #ratioStr))
                  if not tupletNum then
                    error("Invalid tuplet num!")
                    end
                  if tupletNum == 2 or tupletNum == 4 then
                    tupletDenom = 3
                  else
                    tupletDenom = 2^closestPowerOfTwo(tupletNum)
                    end
                  end
                end
              
              if not tupletNum or not tupletDenom then
                throwError("Invalid tuplet denom!", nil, time)
                end
  
              list[index][TUPLETLISTINDEX_BASERHYTHM] = baseDenom
              list[index][TUPLETLISTINDEX_NUM] = tupletNum
              list[index][TUPLETLISTINDEX_DENOM] = tupletDenom
              list[index][TUPLETLISTINDEX_SHOWCOLON] = (type(colonIndex) == "number")
              end
              
            if laneType == "rhythm1" or laneType == "rhythm2" then
              local rhythmNum, rhythmDenom
              local slashIndex = string.find(val, "/")
              if slashIndex then
                rhythmNum = tonumber(string.sub(val, 1, slashIndex-1))
                rhythmDenom = tonumber(string.sub(val, slashIndex+1, #val))
              else
                rhythmNum = tonumber(val)
                if rhythmNum ~= 0 then
                  rhythmDenom = rhythmNum
                  rhythmNum = 1
                  end
                end
              if rhythmNum == 0 then
                rhythmDenom = 1
                end
                
              if not rhythmNum then
                throwError("Invalid rhythm num!", nil, time)
                end
              if not isInTable(VALID_RHYTHM_DENOM_LIST, rhythmDenom) then
                throwError("Invalid rhythm denom!", nil, time)
                end
              
              list[index][RHYTHMOVERRIDELISTINDEX_NUM] = rhythmNum
              list[index][RHYTHMOVERRIDELISTINDEX_DENOM] = rhythmDenom
              end
            
            if laneType == "sustain1" or laneType == "sustain2" then
              local values = separateString(val)
              for x=1, #values do
                local value = values[x]
                if string.sub(value, 1, 5) == "roll_" then
                  list[index][SUSTAINLISTINDEX_ROLLTYPE] = string.sub(value, 6, #value)
                  end
                if value == "tie" then
                  list[index][SUSTAINLISTINDEX_TIE] = true
                  end
                end
              end
              
            if laneType == "dynamics" then
              local values = separateString(val)
              for x=1, #values do
                local value = values[x]
                if x == 1 then
                  if not isInTable(VALID_DYNAMICS_LIST, value) then
                    throwError("Invalid dynamic! " .. value, nil, time)
                    end
                  list[index][DYNAMICLISTINDEX_TYPE] = value
                else
                  if string.sub(value, 1, 7) == "offset_" then
                    list[index][DYNAMICLISTINDEX_OFFSET] = tonumber(string.sub(value, 8, #value))
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  
  for x=#dynamicList, 1, -1 do
    local data = dynamicList[x]
    local dynamic = data[DYNAMICLISTINDEX_TYPE]
    if isGradualDynamic(dynamic) then
      local copy = deepCopy(data)
      copy[DYNAMICLISTINDEX_STARTPPQPOS] = copy[DYNAMICLISTINDEX_ENDPPQPOS]
      copy[DYNAMICLISTINDEX_STARTQN] = copy[DYNAMICLISTINDEX_ENDQN]
      table.insert(dynamicList, x+1, copy)
      end
    end
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
  
  END_TEXT_EVT_QN = nil
  
  local _, _, _, textCount = reaper.MIDI_CountEvts(eventsTake)
  for textEvtID=0, textCount-1 do
    local _, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(eventsTake, textEvtID)
    local qn = getQNFromPPQPOS(eventsTake, ppqpos)
    local time = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, ppqpos)

    if evtType == TEXT_EVENT then
      if ppqpos >= startEvtPPQPOS and ppqpos < endEvtPPQPOS then
        if ppqpos ~= currentPPQPOS then
          if isAtMeasure then --process previous measure values
            if timeSigNum == "default" then
              isMeasureOverride = false
              timeSigNum, timeSigDenom = getDefaultTimeSigNumDenom(currentMeasureListIndex)
            elseif timeSigDenom then
              isMeasureOverride = true
            else
              timeSigNum, timeSigDenom = getDefaultTimeSigNumDenom(currentMeasureListIndex)
              end
            
            if not beamGroupings then
              beamGroupings = getDefaultBeamGroupingsStr(currentMeasureListIndex, timeSigNum, timeSigDenom)
              end
            if not secondaryBeamGroupings then
              secondaryBeamGroupings = getDefaultSecondaryBeamGroupingsStr(timeSigNum, timeSigDenom)
              end
            if not quantizeStr or quantizeStr == "default" then
              quantizeStr = getDefaultQuantizeStr()
              end
              
            local currentTable = measureList[currentMeasureListIndex]
            
            currentTable[MEASURELISTINDEX_TIMESIGNUM] = timeSigNum
            currentTable[MEASURELISTINDEX_TIMESIGDENOM] = timeSigDenom
            currentTable[MEASURELISTINDEX_BEAMGROUPINGS] = beamGroupings
            currentTable[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS] = secondaryBeamGroupings
            currentTable[MEASURELISTINDEX_QUANTIZESTR] = quantizeStr
            
            updateRecentBeamGrouping(timeSigNum, timeSigDenom, beamGroupings, secondaryBeamGroupings)
            end
          
          --update to new measure
          currentPPQPOS = ppqpos
          timeSigNum, timeSigDenom, beamGroupings, secondaryBeamGroupings, quantizeStr = nil, nil, nil, nil, nil, nil
          isAtMeasure = false
          while currentMeasureListIndex <= #measureList do
            local measurePPQPOS = measureList[currentMeasureListIndex][MEASURELISTINDEX_PPQPOS]
            if currentPPQPOS == measurePPQPOS then
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
                error("Invalid time signature (no slash)!")
                end
              end
            end
          
          if header == "beamgroupings" then
            beamGroupings = val
            end
          if header == "secondarybeamgroupings" then
            secondaryBeamGroupings = val
            end
          if header == "quantize" then
            quantizeStr = val
            end
          end
        end
      if msg == "[end]" then
        END_TEXT_EVT_QN = qn
        end
      end
    end
  
  if not END_TEXT_EVT_QN then
    throwError("[end] text event not found!")
    end
    
  --TODO: measure 1 should always have everything
  local currentTimeSigNum, currentTimeSigDenom, currentBeamGroupings, currentSecondaryBeamGroupings, currentQuantizeStr
  for measureIndex=1, #measureList do
    local data = measureList[measureIndex]
    
    local timeSigNum = data[MEASURELISTINDEX_TIMESIGNUM]
    if timeSigNum then
      currentTimeSigNum = timeSigNum
    else
      data[MEASURELISTINDEX_TIMESIGNUM] = currentTimeSigNum
      if measureIndex == 1 then
        throwError("No time signature defined on first measure!")
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
        error()
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

function getLaneOverrideNameAndVoiceIndex(midiNoteNum)
  debug_printStack()
  local msg = configList[midiNoteNum+1]
  
  local laneLabel, laneName, ccNum
  local spaceIndex = string.find(msg, " ")
  if spaceIndex then
    laneLabel = string.sub(msg, 1, spaceIndex-1)
    local endQuoteIndex = string.find(msg, "\"", spaceIndex+2)
    laneName = string.sub(msg, spaceIndex+2, endQuoteIndex-1)
    local _, ccUnderscoreIndex = string.find(msg, "cc_")
    if ccUnderscoreIndex then
      local endIndex
      local spaceIndex = string.find(msg, " ", ccUnderscoreIndex)
      if spaceIndex then
        endIndex = spaceIndex - 1
      else
        endIndex = #msg
        end
      ccNum = tonumber(string.sub(msg, ccUnderscoreIndex+1, endIndex))
      end
  else
    laneLabel = msg
    laneName = laneLabel
    end
  if not isInTable(VALID_LANEOVERRIDE_LIST, laneLabel) then
    throwError("Invalid config lane override label! " .. midiNoteNum .. " " .. msg)
    end
    
  local voiceIndex = tonumber(string.sub(laneLabel, #laneLabel, #laneLabel))
  
  return laneLabel, voiceIndex, laneName, ccNum
  end

function setLaneOverrideName(midiNoteNum, name)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
    throwError("No config text event ID! " .. midiNoteNum)
    end
  
  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
  local quoteIndex = string.find(msg, "\"")
  local newMsg
  if quoteIndex then
    newMsg = string.sub(msg, 1, quoteIndex) .. name .. "\""
  else
    newMsg = msg .. " \"" .. name .. "\""
    end
  
  setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, newMsg)
  end

function getActualRhythmNumDenom(rhythmListData)
  local rhythmNum = rhythmListData[RHYTHMLISTINDEX_NUM]
  local rhythmDenom = rhythmListData[RHYTHMLISTINDEX_DENOM]
  local tupletFactorNum = rhythmListData[RHYTHMLISTINDEX_TUPLETFACTORNUM]
  local tupletFactorDenom = rhythmListData[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
  local hasDot = rhythmListData[RHYTHMLISTINDEX_HASDOT]
  
  if hasDot then
    rhythmNum = 3
    rhythmDenom = round(rhythmDenom*2)
    end
    
  local actualRhythmNum, actualRhythmDenom = simplifyFraction(rhythmNum*tupletFactorNum, rhythmDenom*tupletFactorDenom)
  
  return actualRhythmNum, actualRhythmDenom
  end
    
function getXmlRhythmType(rhythmDenom)
  if rhythmDenom == 1 then return "whole" end
  if rhythmDenom == 2 then return "half" end
  if rhythmDenom == 4 then return "quarter" end
  if rhythmDenom == 8 then return "eighth" end
  if rhythmDenom == 16 then return "16th" end
  if rhythmDenom == 32 then return "32nd" end
  
  if rhythmDenom > 32 then return rhythmDenom .. "th" end
  end

function getXmlDuration(rhythmListData)
  local actualRhythmNum, actualRhythmDenom = getActualRhythmNumDenom(rhythmListData)
  return round(actualRhythmNum/actualRhythmDenom * 4 * xmlDivisionsPerQN)
  end
  
function addNoteAttributesToXML(noteData)
  local noteNameList = {"C", "D", "E", "F", "G", "A", "B"}
  local staffLineOffset = round(noteData[NOTELISTINDEX_STAFFLINE]*2)
  local noteNameListIndex = (staffLineOffset+6)%7 + 1
  
  local trebleNoteName = noteNameList[noteNameListIndex]
  local trebleOctave = 5 + floor((staffLineOffset-1)/7)
    
  local voiceIndex = noteData[NOTELISTINDEX_VOICEINDEX]
  local notehead = noteData[NOTELISTINDEX_NOTEHEAD]
  local parenthesesStr
  if isNoteGhost(noteData) then
    parenthesesStr = " parentheses=\"yes\""
  else
    parenthesesStr = ""
    end
  
  local xmlStemDir
  if voiceIndex == 1 then
    xmlStemDir = "up" 
    end
  if voiceIndex == 2 then
    xmlStemDir = "down"
    end 
    
  addToXML("        <unpitched>")
  addToXML("          <display-step>" .. trebleNoteName .. "</display-step>")
  addToXML("          <display-octave>" .. trebleOctave .. "</display-octave>")
  addToXML("        </unpitched>")
  addToXML("        <voice>" .. voiceIndex .. "</voice>")
  addToXML("        <stem>" .. xmlStemDir .. "</stem>")
  addToXML("        <notehead" .. parenthesesStr .. ">" .. notehead .. "</notehead>")
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

function getBeat(beatTable, qn, isRhythmicValue)
  local subTableIndex
  if isRhythmicValue then
    subTableIndex = 3
  else
    subTableIndex = 1
    end
  local result = findIndexInListEqualOrLessThan(beatTable, qn, subTableIndex)

  if result == #beatTable then
    result = result - 1
    end
  
  if not result then
    debug_printStack()
    reaper.ShowConsoleMsg("QN: " .. qn .. "\n")
    for x=1, #beatTable do
      reaper.ShowConsoleMsg(beatTable[x][1] .. " " .. beatTable[x][3] .. "\n")
      end
    local ppqpos = reaper.MIDI_GetPPQPosFromProjQN(drumTake, qn)
    local time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, ppqpos)
    throwError("No beat found!", nil, time)
    end
  
  local boundStart = beatTable[result][subTableIndex]
  local boundEnd = beatTable[result+1][subTableIndex]
  
  return roundFloatingPoint(convertRange(qn, boundStart, boundEnd, result-1, result))
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

function isStrongBeat(beatTable, beat)
  local flooredBeat = floor(beat)
  if flooredBeat < 0 or flooredBeat >= #beatTable then
    return false
    end
  return beatTable[flooredBeat+1][2]
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

function addToEventList(data)
  local qn = data[2]
  
  local function getClosestIndex()
    if #qnEventList == 0 then
      return 0, false
      end
      
    local low = 1
    local high = #qnEventList
    local exactMatch = false
    local closestLowerIndex = nil
  
    while low <= high do
      local mid = floor((low + high) / 2)
      local midValue = qnEventList[mid][1][2] -- First value in the subtable
      
      if midValue == qn then
        return mid, true -- Return the exact match index and true
      elseif midValue < qn then
        closestLowerIndex = mid -- Potential closest lower value
        low = mid + 1 -- Search the right half
      else
        high = mid - 1 -- Search the left half
        end
      end
  
    -- If no exact match is found, return the closest lower index and false
    return closestLowerIndex, false
    end
  
  local index, exactMatch = getClosestIndex()
  local subList
  if not index then --gracenote
    table.insert(qnEventList, 1, {})
    subList = qnEventList[1]
  elseif exactMatch then
    subList = qnEventList[index]
  else
    table.insert(qnEventList, index+1, {})
    subList = qnEventList[index+1]
    end
  tableInsert(subList, data)
  end
      
function getMeasureData(measureIndex, isActiveMeasure)
  local data = measureList[measureIndex]
  if not data then return end
  
  local startPPQPOS = data[MEASURELISTINDEX_PPQPOS]
  local endPPQPOS
  local qnStart = data[MEASURELISTINDEX_QN]
  local qnEnd
  if measureIndex == #measureList then
    endPPQPOS = endEvtPPQPOS
    qnEnd = endEvtQN
  else
    endPPQPOS = measureList[measureIndex+1][MEASURELISTINDEX_PPQPOS]
    qnEnd = measureList[measureIndex+1][MEASURELISTINDEX_QN]
    end
  
  local measureTime = data[MEASURELISTINDEX_TIME]
  
  local beamGroupingsStr = data[MEASURELISTINDEX_BEAMGROUPINGS]
  local secondaryBeamGroupingsStr = data[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS]
  local timeSigNum = data[MEASURELISTINDEX_TIMESIGNUM]
  local timeSigDenom = data[MEASURELISTINDEX_TIMESIGDENOM]
    
  local beamGroupingsTable = getBeamGroupingsTable(beamGroupingsStr, secondaryBeamGroupingsStr, timeSigNum, timeSigDenom, measureIndex)
  
  local beatTable = data[MEASURELISTINDEX_BEATTABLE]
  
  local quantizeNum = 1
  local quantizeDenom = data[MEASURELISTINDEX_QUANTIZEDENOM]
  local quantizeTupletFactorNum = data[MEASURELISTINDEX_QUANTIZETUPLETFACTORNUM]
  local quantizeTupletFactorDenom = data[MEASURELISTINDEX_QUANTIZETUPLETFACTORDENOM]
  local quantizeModifier = data[MEASURELISTINDEX_QUANTIZEMODIFIER]
  
  local restOffsets = {data[MEASURELISTINDEX_RESTOFFSET1], data[MEASURELISTINDEX_RESTOFFSET2]}
  
  local currentTime, currentPPQPOS, currentQN, currentBeat
  if isActiveMeasure then
    currentTime = getCursorPosition()
    currentPPQPOS = reaper.MIDI_GetPPQPosFromProjTime(eventsTake, currentTime)
    currentQN = getQNFromPPQPOS(eventsTake, currentPPQPOS)
    currentBeat = getBeat(beatTable, currentQN)
    end
  
  local index = findClosestIndexAtOrBelow(sectionTextEvtList, startPPQPOS, 1)
  --local index = findIndexInListEqualOrGreaterThan(sectionTextEvtList, startPPQPOS, 1) --TODO: TEST ON A SONG?
  local measureSectionName
  if index then
    measureSectionName = sectionTextEvtList[index][2]
    end
  
  local numTicks = roundFloatingPoint(timeSigNum * (quantizeDenom/timeSigDenom))
  if round(numTicks) ~= numTicks then
    throwError("Bad numTicks! " .. numTicks .. " " .. timeSigNum .. "/" .. timeSigDenom, measureIndex)
    end
  local subdivisionsPerBeat = roundFloatingPoint(numTicks/(#beatTable-1))
  if round(subdivisionsPerBeat) ~= subdivisionsPerBeat then
    throwError("Bad subdivisionsPerBeat! " .. subdivisionsPerBeat .. " " .. timeSigNum .. "/" .. timeSigDenom, measureIndex)
    end
  
  local measureTupletListBothVoices = {{}, {}}
  
  local function calculateMeasureTupletList(voiceIndex)
    local measureTupletList = measureTupletListBothVoices[voiceIndex]
    
    local tupletList = tupletListBothVoices[voiceIndex]
    local tupletListIndex = findIndexInListEqualOrGreaterThan(tupletList, startPPQPOS, 1)
    
    local tupletCount = 0
    local searching = false
    for x=1, #tupletList do
      local data = tupletList[x]
      
      local tupletStartPPQPOS = data[TUPLETLISTINDEX_STARTPPQPOS]
      local tupletEndPPQPOS = data[TUPLETLISTINDEX_ENDPPQPOS]
      local tupletStartQN = data[TUPLETLISTINDEX_STARTQN]
      local tupletEndQN = data[TUPLETLISTINDEX_ENDQN]
      local baseDenom = data[TUPLETLISTINDEX_BASERHYTHM]
      local tupletNum = data[TUPLETLISTINDEX_NUM]
      local tupletDenom = data[TUPLETLISTINDEX_DENOM]
      local showColon = data[TUPLETLISTINDEX_SHOWCOLON]
      
      if not baseDenom then
        throwError("Missing text inside tuplet MIDI note!", nil, measureTime)
        end
            
      if tupletStartQN >= qnStart then
        searching = true
        end
      if tupletStartQN >= qnEnd then
        break
        end
      
      if searching then
        if tupletEndQN > qnEnd then
          throwError("Tuplet ends after measure end! " .. tupletEndQN .. " > " .. qnEnd, measureIndex)
          end
        
        for y=1, #measureTupletList do
          local prevData = measureTupletList[y]
          
          local prevTupletStartPPQPOS = prevData[1]
          local prevTupletEndPPQPOS = prevData[2]
          
          if tupletStartPPQPOS >= prevTupletStartPPQPOS and tupletStartPPQPOS < prevTupletEndPPQPOS then --inside prev tuplet
            if tupletEndPPQPOS > prevTupletEndPPQPOS then
              throwError("Tuplet extends past another tuplet!", measureIndex)
              end
            end
          end
        
        tableInsert(measureTupletList, {tupletStartPPQPOS, tupletEndPPQPOS, tupletStartQN, tupletEndQN, baseDenom, tupletNum, tupletDenom, showColon})
        end
      end
    
    local maxLevel = 0
    for i=1, #measureTupletList do
      local outerRegion = measureTupletList[i]
      local outerStart, outerEnd = outerRegion[1], outerRegion[2]
      local level = 0
  
      -- Compare the current region with all others
      for j=1, #measureTupletList do
        local innerRegion = measureTupletList[j]
        if i ~= j then
          local innerStart, innerEnd = innerRegion[1], innerRegion[2]
          -- Check if innerRegion is inside outerRegion
          if innerStart > outerStart and innerEnd < outerEnd then
            level = level + 1
            end
          end
        end
  
      -- Store the level for the current region
      outerRegion[9] = level
      maxLevel = math.max(level, maxLevel)
      end

    for x=1, #measureTupletList do
      local data = measureTupletList[x]
      data[9] = maxLevel - data[9]
      end
    end
  
  calculateMeasureTupletList(1)
  calculateMeasureTupletList(2)
  
  local qnTickTableBothVoices = {{}, {}}
  for x=1, #beatTable-1 do
    local startBeatQN = beatTable[x][1]
    local endBeatQN = beatTable[x+1][1]
    for subdivision=0, subdivisionsPerBeat-1 do
      --get tuplet at this point
      local qnTick = convertRange(subdivision, 0, subdivisionsPerBeat, startBeatQN, endBeatQN)
      tableInsert(qnTickTableBothVoices[1], qnTick)
      tableInsert(qnTickTableBothVoices[2], qnTick)
      end
    end
  
  return startPPQPOS, endPPQPOS, measureSectionName, qnStart, qnEnd, currentQN, timeSigNum, timeSigDenom, beatTable, beamGroupingsTable, currentBeat, quantizeNum, quantizeDenom, quantizeTupletFactorNum, quantizeTupletFactorDenom, quantizeModifier, restOffsets, qnTickTableBothVoices, measureTupletListBothVoices
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

function getDynamicImageData(dynamic)
  if dynamic == "crescendo" or dynamic == "diminuendo" or dynamic == "decrescendo" then
    return
    end
  
  local imgFileName = "dynamic_" .. dynamic
  local img = getImageFromList(imgFileName)
  if not img then
    throwError("Missing dynamic image! " .. dynamic)
    end
    
  local imgSizeX, imgSizeY = getImageSize(imgFileName)
  local imgAspectRatio = imgSizeX/imgSizeY
  
  local sizeY = DYNAMICSIZEY
  local yMin = DYNAMICCENTERY
  local yMax = yMin + sizeY
  
  local scalingFactor = sizeY/imgSizeY
  local sizeX = imgSizeX*scalingFactor
  
  yMin = yMin - sizeY/2
  yMax = yMax - sizeY/2
  
  return sizeX, yMin, yMax, img, imgFileName
  end
  
function getTempoImagesAndBoundaries(bpmBasis, bpm, performanceDirection)
  local imgTable = {}
  local imgFileName
  local hasDot
  
  if bpmBasis and bpm then
    local bpmBasisFileName
    if bpmBasis == "1/1" or bpmBasis == "1" or bpmBasis == "whole" or bpmBasis == "w" then
      bpmBasisFileName = 1
      end
    if bpmBasis == "1/2" or bpmBasis == "2" or bpmBasis == "half" or bpmBasis == "h" then
      bpmBasisFileName = 2
      end
    if bpmBasis == "1/2d" or bpmBasis == "3/4" or bpmBasis == "dottedhalf" or bpmBasis == "dotted_half" or bpmBasis == "dh" then
      bpmBasisFileName = 2
      hasDot = true
      end
    if bpmBasis == "1/4" or bpmBasis == "4" or bpmBasis == "quarter" or bpmBasis == "q" then
      bpmBasisFileName = 4
      end
    if bpmBasis == "1/4d" or bpmBasis == "3/8" or bpmBasis == "dottedquarter" or bpmBasis == "dotted_quarter" or bpmBasis == "dq" then
      bpmBasisFileName = 4
      hasDot = true
      end
    if bpmBasis == "1/8" or bpmBasis == "8" or bpmBasis == "eighth" or bpmBasis == "e" then
      bpmBasisFileName = 8
      end
    if bpmBasis == "1/8d" or bpmBasis == "3/16" or bpmBasis == "dottedeighth" or bpmBasis == "dotted_eighth" or bpmBasis == "de" then
      bpmBasisFileName = 8
      hasDot = true
      end
    if bpmBasis == "1/16" or bpmBasis == "16" or bpmBasis == "sixteenth" or bpmBasis == "s" then
      bpmBasisFileName = 16
      end
    if bpmBasis == "1/16d" or bpmBasis == "3/32" or bpmBasis == "dottedsixteenth" or bpmBasis == "dotted_sixteenth" or bpmBasis == "ds" then
      bpmBasisFileName = 16
      hasDot = true
      end
    if bpmBasis == "1/32" or bpmBasis == "32" or bpmBasis == "thirtysecond" or bpmBasis == "t" then
      bpmBasisFileName = 32
      end
    if bpmBasis == "1/32d" or bpmBasis == "3/64" or bpmBasis == "dottedthirtysecond" or bpmBasis == "dotted_thirtysecond" or bpmBasis == "dt" then
      bpmBasisFileName = 32
      hasDot = true
      end
    if bpmBasis == "1/64" or bpmBasis == "64" or bpmBasis == "sixtyfourth" then
      bpmBasisFileName = 64
      end
    if bpmBasis == "1/64d" or bpmBasis == "3/128" or bpmBasis == "dottedsixtyfourth" or bpmBasis == "dotted_sixtyfourth" then
      bpmBasisFileName = 64
      hasDot = true
      end
    
    imgFileName = "note_" .. bpmBasisFileName
    local img = getImageFromList(imgFileName)
    if not img then
      throwError("Invalid BPM basis! " .. bpmBasis)
      end
    tableInsert(imgTable, {img, "bpmBasis", imgFileName})
    
    local img = getImageFromList("equals")
    tableInsert(imgTable, {img, "equals", "equals"})
    
    local bpmStr = tostring(bpm)
    for x=1, #bpmStr do
      local char = string.sub(bpmStr, x, x)
      local fileName, dataType
      if char == "." then
        fileName = "dot"
        dataType = "dot"
      elseif tonumber(char) then
        fileName = "tempo_" .. char
        dataType = "tempoNumber"
      else
        throwError("Invalid BPM number! " .. bpm)
        end
      local img = getImageFromList(fileName)
      tableInsert(imgTable, {img, dataType, fileName})
      end
    
    --TODO: performance direction
    end
    
  local imgData = {}
  
  local sizeYDefault = STAFFSPACEHEIGHT*1.3
  local sizeYBPMBasis = sizeYDefault*1.5
  local sizeYEquals = sizeYDefault*0.5
  local sizeYDot = sizeYDefault*0.2
  local xMin = 0
  for x=1, #imgTable do
    local img = imgTable[x][1]
    local dataType = imgTable[x][2]
    local fileName = imgTable[x][3]
    
    local imgSizeX, imgSizeY = getImageSize(fileName)
    local imgAspectRatio = imgSizeX/imgSizeY
    
    local yMax = sizeYDefault
    local sizeY
    if dataType == "equals" then
      sizeY = sizeYEquals
    elseif dataType == "bpmBasis" then
      sizeY = sizeYBPMBasis
    elseif dataType == "dot" then
      sizeY = sizeYDot
    else
      sizeY = sizeYDefault
      end
    local yMin = yMax - sizeY
    
    if dataType == "equals" then
      yMin = yMin - (sizeYDefault-sizeY)/2
      yMax = yMax - (sizeYDefault-sizeY)/2
      end
      
    local scalingFactor = sizeY/imgSizeY
    local sizeX = imgSizeX*scalingFactor
    
    local xMax = xMin + sizeX
    
    tableInsert(imgData, {img, xMin, yMin, xMax, yMax})
    
    local paddingX
    if dataType == "tempoNumber" then
      paddingX = STAFFSPACEHEIGHT/10
    else
      paddingX = STAFFSPACEHEIGHT/3
      end
    xMin = xMax + paddingX
    end
  
  return imgData, imgFileName, hasDot
  end

function getNumberImagesAndBoundaries(num)
  num = tostring(num)
  local imgTable = {}
  for x=1, #num do
    local imgFileName = "timesig_" .. string.sub(num, x, x)
    local img = getImageFromList(imgFileName)
    tableInsert(imgTable, {img, imgFileName})
    end
  
  local numberData = {}
  
  local yMin = 0
  local yMax = STAFFSPACEHEIGHT*2 - STAFFSPACEHEIGHT/10
  
  local xMin = 0
  for x=1, #imgTable do
    local img = imgTable[x][1]
    local imgFileName = imgTable[x][2]
    
    local imgSizeX, imgSizeY = getImageSize(imgFileName)
    local imgAspectRatio = imgSizeX/imgSizeY
  
    local sizeY = yMax - yMin
    
    local scalingFactor = sizeY/imgSizeY
    local sizeX = imgSizeX*scalingFactor
    
    local xMax = xMin + sizeX
    
    tableInsert(numberData, {img, xMin, yMin, xMax, yMax, imgFileName})
    
    xMin = xMax + STAFFSPACEHEIGHT/10
    end
  
  return numberData
  end
  
function getTimeSignatureImagesAndBoundaries(timeSigNum, timeSigDenom)
  local numData = getNumberImagesAndBoundaries(timeSigNum)
  local denomData = getNumberImagesAndBoundaries(timeSigDenom) 
  
  local lastNumXMax = numData[#numData][4]
  local lastDenomXMax = numData[#denomData][4]
  local smallerData, biggerData
  if lastNumXMax < lastDenomXMax then
    smallerData = numData
    biggerData = denomData
  else
    smallerData = denomData
    biggerData = numData
    end
  local smallerXMax = numData[#smallerData][4]
  local biggerXMax = numData[#biggerData][4]
  
  local increment = (biggerXMax-smallerXMax)/2
  for x=1, #smallerData do
    smallerData[x][2] = smallerData[x][2] + increment
    smallerData[x][4] = smallerData[x][4] + increment
    end
  
  local centerXPos = biggerXMax/2
  return numData, denomData, centerXPos
  end

function getNoteTupletList(startQN, measureTupletList)
  local list = {}
  
  for x=1, #measureTupletList do --TODO: binary search optimize
    local data = measureTupletList[x]
    local tupletQNStart = data[3]
    local tupletQNEnd = data[4]
    
    if startQN >= tupletQNStart and startQN < tupletQNEnd then
      tableInsert(list, data)
      end
    end
  
  return list
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
  
function getRhythmOverride(startQN, endQN, beatTable, timeSigDenom, voiceIndex, measureTupletList, chord)
  local tupletFactorNum = 1
  local tupletFactorDenom = 1
  local hasDot = false
  
  if chord then
    local chordNotes = chord[2]
    local firstNoteData = chordNotes[1]
    local firstNoteGraceState = firstNoteData[NOTELISTINDEX_GRACESTATE]
    if firstNoteGraceState == "grace" or firstNoteGraceState == "flamgrace" then
      return 0, 0, tupletFactorNum, tupletFactorDenom, hasDot
      end
    end
    
  local rhythmOverrideList = rhythmOverrideListBothVoices[voiceIndex]
  
  local rhythmNum, rhythmDenom
  for x=1, #rhythmOverrideList do --TODO: binary search optimize
    local data = rhythmOverrideList[x]
    local rhythmOverrideQNStart = data[RHYTHMOVERRIDELISTINDEX_STARTQN]
    local rhythmOverrideQNEnd = data[RHYTHMOVERRIDELISTINDEX_ENDQN]
    
    if startQN >= rhythmOverrideQNStart and startQN < rhythmOverrideQNEnd then
      rhythmNum = data[RHYTHMOVERRIDELISTINDEX_NUM]
      rhythmDenom = data[RHYTHMOVERRIDELISTINDEX_DENOM]

      if not isInTable(VALID_RHYTHM_DENOM_LIST, rhythmDenom) then
        throwError("Invalid rhythm denom! " .. voiceIndex .. " " .. rhythmDenom)
        end
        
      break
      end
    end
  
  if measureTupletList then
    local noteTupletList = getNoteTupletList(startQN, measureTupletList)
    if #noteTupletList > 0 then
      if not rhythmNum then
        local startBeat = getBeat(beatTable, startQN)
        local endBeat = getBeat(beatTable, endQN)
        local beatDifference = endBeat - startBeat
        
        local rhythmDecimal = roundFloatingPoint(beatDifference/timeSigDenom)
        
        rhythmNum = 1
        rhythmDenom = MAX_RHYTHM
        while rhythmDenom >= 2 do
          if rhythmDecimal < roundFloatingPoint(rhythmNum/rhythmDenom) then
            break
            end
          rhythmDenom = round(rhythmDenom/2)
          end
        
        if rhythmDenom == 1 then
          throwError("Bad tuplet rhythm denom! ", measureIndex)
          end
        end
      
      for x=1, #noteTupletList do
        local data = noteTupletList[x]

        local tupletNum = data[6]
        local tupletDenom = data[7]
        
        tupletFactorNum = round(tupletFactorNum * tupletDenom)
        tupletFactorDenom = round(tupletFactorDenom * tupletNum)
        end
      end
    end
      
  if rhythmNum then
    rhythmNum, rhythmDenom, hasDot = attemptToGetDot(rhythmNum, rhythmDenom)
    end
  tupletFactorNum, tupletFactorDenom = simplifyFraction(tupletFactorNum, tupletFactorDenom)
  
  return rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom, hasDot
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

function attemptToGetDot(rhythmNum, rhythmDenom)
  rhythmNum, rhythmDenom = simplifyFraction(rhythmNum, rhythmDenom)
  local hasDot = (rhythmNum == 3)
  if hasDot then
    rhythmNum = 1 
    rhythmDenom = round(rhythmDenom/2)
    end
  return rhythmNum, rhythmDenom, hasDot
  end
    
function drawTimeSignature(timeSigNum, timeSigDenom)
  addToXML("        <time>")
  addToXML("          <beats>" .. timeSigNum .. "</beats>")
  addToXML("          <beat-type>" .. timeSigDenom .. "</beat-type>")
  addToXML("        </time>")
  
  local numData, denomData, centerXPos = getTimeSignatureImagesAndBoundaries(timeSigNum, timeSigDenom)
  
  local timeSigBound = math.mininteger
  
  local function drawData(data, isDenom)
    local topStaffLine
    if isDenom then
      topStaffLine = 0
    else
      topStaffLine = 2
      end
      
    for x=1, #data do
      local imgValues = data[x]
      
      local img = imgValues[1]
      local xMin = imgValues[2] + measureBoundXMin
      local yMin = imgValues[3] + getStaffLinePosition(topStaffLine)
      local xMax = imgValues[4] + measureBoundXMin
      local yMax = imgValues[5] + getStaffLinePosition(topStaffLine)
      local imgFileName = imgValues[6]
      
      addToNotationDrawList({"timeSig", xMin, xMax, yMin, yMax, img})
      addToGameData("notation", {"timesig", nil, imgFileName, xMin, yMin, xMax, yMax})
      
      timeSigBound = math.max(timeSigBound, xMax)
      end
    end
  
  drawData(numData, false)
  drawData(denomData, true)
  
  measureTimeSigOffset = timeSigBound + 30 - measureBoundXMin
  measureBoundXMin = measureBoundXMin + measureTimeSigOffset
  
  stopMultiMeasure = true
  end
    
function addToNotationDrawList(dataTable)
  if not gettingCurrentValues then
    tableInsert(notationDrawList, dataTable)
    end
  end

function storeDrawBeamStates(voiceIndex)
  local masterBeamList = masterBeamListBothVoices[voiceIndex]
  for x=1, #masterBeamList do
    local beamTable = masterBeamList[x]
    local numBeamEvents = 0
    for y=1, #beamTable do
      local secondaryBeamTable = beamTable[y]
      numBeamEvents = numBeamEvents + #secondaryBeamTable
      end
    
    if numBeamEvents >= 2 then
    
      local function getBeamData(beamTableIndex, secondaryBeamTableIndex, offset)
        if offset > 0 then
          for x=1, offset do
            local secondaryBeamTable = beamTable[beamTableIndex]
            secondaryBeamTableIndex = secondaryBeamTableIndex + 1
            local nextBeamData = secondaryBeamTable[secondaryBeamTableIndex]
            if not nextBeamData then
              beamTableIndex = beamTableIndex + 1
              local secondaryBeamTable = beamTable[beamTableIndex]
              secondaryBeamTableIndex = 1
              end
            end
          end
        if offset < 0 then
          for x=1, math.abs(offset) do
            local secondaryBeamTable = beamTable[beamTableIndex]
            secondaryBeamTableIndex = secondaryBeamTableIndex - 1
            local prevBeamData = secondaryBeamTable[secondaryBeamTableIndex]
            if not prevBeamData then
              beamTableIndex = beamTableIndex - 1
              local secondaryBeamTable = beamTable[beamTableIndex]
              secondaryBeamTableIndex = #secondaryBeamTable
              end
            end
          end
        
        local secondaryBeamTable = beamTable[beamTableIndex]
        local beamData = secondaryBeamTable[secondaryBeamTableIndex]
        return beamData
        end
        
      for y=1, #beamTable do
        local secondaryBeamTable = beamTable[y]
        
        for z=1, #secondaryBeamTable do
          local isBeamStart = (y == 1 and z == 1)
          local isBeamEnd = (y == #beamTable and z == #secondaryBeamTable)
          local isSecondaryBeamStart = (z == 1)
          local isSecondaryBeamEnd = (z == #secondaryBeamTable)
          
          local currentBeamData = getBeamData(y, z, 0)
  
          local chord = currentBeamData[1]
          local currentBaseRhythm = currentBeamData[2]
          local currentNumBeams = getNumBeams(currentBaseRhythm)
          local prevBaseRhythm, prevNumBeams, prevMeasureIndex, prevRhythmListIndex, prevRhythmList
          if not isBeamStart then
            local prevBeamData = getBeamData(y, z, -1)
            prevBaseRhythm = prevBeamData[2]
            prevNumBeams = getNumBeams(prevBaseRhythm)
            prevMeasureIndex = prevBeamData[3]
            prevRhythmListIndex = prevBeamData[4]
            prevRhythmList = masterRhythmListBothVoices[voiceIndex][prevMeasureIndex]
            end
          local nextBaseRhythm, nextNumBeams
          if not isBeamEnd then
            local nextBeamData = getBeamData(y, z, 1)
            nextBaseRhythm = nextBeamData[2]
            nextNumBeams = getNumBeams(nextBaseRhythm)
            end
          local measureIndex = currentBeamData[3]
          local rhythmListIndex = currentBeamData[4]
          local rhythmList = masterRhythmListBothVoices[voiceIndex][measureIndex]
          
          if not rhythmList then return end --if errored before finishing
          
          --get beam XMLs here
          local beamXmlData = {}
          if isBeamStart then
            for beamNum=1, currentNumBeams do
              tableInsert(beamXmlData, "begin")
              end
          elseif isBeamEnd then
            for beamNum=1, currentNumBeams do
              tableInsert(beamXmlData, "end")
              end
          elseif isSecondaryBeamStart then
            tableInsert(beamXmlData, "continue")
            for beamNum=2, currentNumBeams do
              tableInsert(beamXmlData, "begin")
              end
          elseif isSecondaryBeamEnd then
            tableInsert(beamXmlData, "continue")
            for beamNum=2, currentNumBeams do
              tableInsert(beamXmlData, "end")
              end
          else --continue
            for beamNum=1, currentNumBeams do
              local state
              if beamNum > prevNumBeams then --add new additional beam
                state = "begin"
              elseif beamNum > nextNumBeams then
                state = "end"
              else
                state = "continue"
                end
              tableInsert(beamXmlData, state)
              end
            end
          rhythmList[rhythmListIndex][RHYTHMLISTINDEX_BEAMXMLDATA] = beamXmlData
          
          local drawBeamState
          
          if isBeamStart then
            drawBeamState = DRAWBEAM_START
          else
            if isSecondaryBeamStart then
              local prevSecondaryBeamTable = beamTable[y-1]
              if prevSecondaryBeamTable and #prevSecondaryBeamTable == 1 then
                drawBeamState = DRAWBEAM_STUBRIGHTSECONDARY
                end
              if y == #beamTable and #secondaryBeamTable == 1 then
                if drawBeamState == DRAWBEAM_STUBRIGHTSECONDARY then
                  drawBeamState = DRAWBEAM_STUBRIGHTLEFTSECONDARY
                else
                  drawBeamState = DRAWBEAM_STUBLEFTSECONDARY
                  end
                end
              if not drawBeamState then
                drawBeamState = DRAWBEAM_SECONDARY
                end
            else
              if currentBaseRhythm < prevBaseRhythm then
                if z == 2 or getBeamData(y, z, -2)[2] < prevBaseRhythm then
                  drawBeamState = DRAWBEAM_STUBRIGHT
                else
                  drawBeamState = DRAWBEAM_FULLCURRENT
                  end
              elseif currentBaseRhythm > prevBaseRhythm then
                if isBeamEnd then
                  drawBeamState = DRAWBEAM_STUBLEFT
                else
                  drawBeamState = DRAWBEAM_FULLPREV
                  end
              else
                drawBeamState = DRAWBEAM_FULLCURRENT
                end
              end
            
            if isBeamEnd then
              drawBeamState = drawBeamState + DRAWBEAM_END
              end
            end
          
          chord[CHORDGLOBALDATAINDEX_DRAWBEAMSTATE] = drawBeamState
          end
        end
      end
    end
  end

function binarySearchClosest(tbl, target)
  local low, high = 1, #tbl

  -- If target is outside range, return boundary values
  if target <= tbl[low] then return tbl[low] end
  if target >= tbl[high] then return tbl[high] end

  while low <= high do
    local mid = math.floor((low + high) / 2)
    
    if tbl[mid] == target then
        return tbl[mid]  -- Exact match found
    elseif tbl[mid] < target then
        low = mid + 1
    else
        high = mid - 1
      end
    end

  -- Now low > high, find the closest between tbl[low] and tbl[high]
  local low_val = tbl[math.max(1, high)]
  local high_val = tbl[math.min(#tbl, low)]

  -- Return the closest of the two
  return (math.abs(low_val - target) <= math.abs(high_val - target)) and low_val or high_val
  end

function isNoteInsideRhythmOverride(startQN, voiceIndex)
  local rhythmOverrideList = rhythmOverrideListBothVoices[voiceIndex]
  for x=1, #rhythmOverrideList do --TODO: binary search optimize
    local data = rhythmOverrideList[x]
    local rhythmOverrideQNStart = data[RHYTHMOVERRIDELISTINDEX_STARTQN]
    local rhythmOverrideQNEnd = data[RHYTHMOVERRIDELISTINDEX_ENDQN]
    
    if startQN >= rhythmOverrideQNStart and startQN < rhythmOverrideQNEnd then
      return true
      end
    end
  
  return false
  end

function isNoteInsideTuplet(startQN, voiceIndex)
  local tupletList = tupletListBothVoices[voiceIndex]
  for x=1, #tupletList do --TODO: binary search optimize
    local data = tupletList[x]
    local tupletQNStart = data[TUPLETLISTINDEX_STARTQN]
    local tupletQNEnd = data[TUPLETLISTINDEX_ENDQN]
    
    if startQN >= tupletQNStart and startQN < tupletQNEnd then
      return true
      end
    end
  
  return false
  end
  
function getMeasureNoteList(measureIndex, voiceIndex)
  local measureStartPPQPOS, measureEndPPQPOS, _, measureQNStart, measureQNEnd, _, timeSigNum, timeSigDenom, beatTable, _, _, quantizeNum, quantizeDenom, quantizeTupletFactorNum, quantizeTupletFactorDenom, quantizeModifier, restOffsets, qnTickTableBothVoices = getMeasureData(measureIndex)
  local prevMeasureStartPPQPOS, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, prevQNTickTableBothVoices = getMeasureData(measureIndex-1)
  local _, nextMeasureEndPPQPOS, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, nextQNTickTableBothVoices = getMeasureData(measureIndex+1)
  
  local qnTickTable = qnTickTableBothVoices[voiceIndex]
  
  local prevQNTick, nextQNTick
  local visiblePPQPOSMin = prevMeasureStartPPQPOS
  if visiblePPQPOSMin then
    local prevQNTickTable = prevQNTickTableBothVoices[voiceIndex]
    prevQNTick = prevQNTickTable[#prevQNTickTable]
    table.insert(qnTickTable, 1, prevQNTick)
  else
    visiblePPQPOSMin = 0
    end
  local visiblePPQPOSMax = nextMeasureEndPPQPOS
  if visiblePPQPOSMax then
    local nextQNTickTable = nextQNTickTableBothVoices[voiceIndex]
    nextQNTick = nextQNTickTable[1]
    tableInsert(qnTickTable, nextQNTick)
  else
    visiblePPQPOSMax = measureEndPPQPOS
    end
  
  local restList = restListBothVoices[voiceIndex]
  
  local measureNoteList = {}
  
  local function processList(noteOrRestList, isNoteList)
    local noteIndex = findIndexInListEqualOrLessThan(noteOrRestList, visiblePPQPOSMax, 1)
    if not noteIndex then
      return
      end
      
    local currentNumGraceNotes, currentNoteQNQuantized, currentFlamIndex, currentFlamGraceIndex, currentFlamGraceQNQuantized
    local testCount = 0
    while true do
      if noteIndex < 1 then
        break
        end
        
      local data = noteOrRestList[noteIndex]
        
      local startPPQPOS, endPPQPOS, startQN, endQN, noteVoiceIndex, midiNoteNum, graceState, notehead, gem
      if isNoteList then
        startPPQPOS = data[NOTELISTINDEX_STARTPPQPOS]
        endPPQPOS = data[NOTELISTINDEX_ENDPPQPOS]
        startQN = data[NOTELISTINDEX_STARTQN]
        endQN = data[NOTELISTINDEX_ENDQN]
        noteVoiceIndex = data[NOTELISTINDEX_VOICEINDEX]
        midiNoteNum = data[NOTELISTINDEX_MIDINOTENUM]
        graceState = data[NOTELISTINDEX_GRACESTATE]
        notehead = data[NOTELISTINDEX_NOTEHEAD]
        gem = data[NOTELISTINDEX_GEM]
      else
        startPPQPOS = data[RESTLISTINDEX_STARTPPQPOS]
        endPPQPOS = data[RESTLISTINDEX_ENDPPQPOS]
        startQN = data[RESTLISTINDEX_STARTQN]
        endQN = data[RESTLISTINDEX_ENDQN]
        end
        
      --get quantized qn at this point
      local qnQuantized
      if isNoteInsideRhythmOverride(startQN, voiceIndex) or isNoteInsideTuplet(startQN, voiceIndex) then
        qnQuantized = startQN
      else
        qnQuantized = binarySearchClosest(qnTickTable, startQN)
        end
    
      local isValidNote = (not isNoteList) or (noteVoiceIndex == voiceIndex and not isLaneOverride(midiNoteNum) and notehead ~= "none" and gem ~= "choke")
      if isValidNote and qnQuantized < measureQNEnd then
        if graceState == "flamgrace" then
          currentFlamGraceIndex = 0
          currentFlamGraceQNQuantized = qnQuantized
          end
          
        if graceState == "grace" or graceState == "flamgrace" then
          qnQuantized = roundFloatingPoint(currentNoteQNQuantized-GRACEQNDIFF*(currentNumGraceNotes+1))
          data[NOTELISTINDEX_STARTQN] = qnQuantized
          currentNumGraceNotes = currentNumGraceNotes + 1
        else
          if currentFlamGraceQNQuantized and qnQuantized < currentFlamGraceQNQuantized then --shift flam QNs
            for index=1, currentFlamIndex do
              if index == currentFlamGraceIndex then
                measureNoteList[index][NOTELISTINDEX_QNQUANTIZED] = roundFloatingPoint(currentFlamGraceQNQuantized-GRACEQNDIFF)
              else
                measureNoteList[index][NOTELISTINDEX_QNQUANTIZED] = currentFlamGraceQNQuantized
                end
              end
              
            currentFlamIndex = nil
            currentFlamGraceIndex = nil
            currentFlamGraceQNQuantized = nil
            end
          
          if qnQuantized < measureQNStart then
            break
            end
            
          currentNumGraceNotes = 0
          currentNoteQNQuantized = qnQuantized
          end
        
        --insert quantized QN (if it's any different) as new data point?
        data[NOTELISTINDEX_QNQUANTIZED] = qnQuantized
        table.insert(measureNoteList, 1, data)
        if not isNoteList then
          data[NOTELISTINDEX_CHANNEL] = nil
          end
          
        if currentFlamIndex then
          currentFlamIndex = currentFlamIndex + 1
          end
        if currentFlamGraceIndex then
          currentFlamGraceIndex = currentFlamGraceIndex + 1
          end
          
        if graceState == "flam" then
          currentFlamIndex = 1
          end
        end
        
      noteIndex = noteIndex - 1
    
      testCount = testCount + 1
      if testCount == 10000 then
        error("Too many")
        end
      end
    
    table.sort(measureNoteList, function(a, b) --incase of flams
      return a[NOTELISTINDEX_QNQUANTIZED] < b[NOTELISTINDEX_QNQUANTIZED]
      end)
    end
    
  processList(noteList, true)
  processList(restList, false)
  
  return measureNoteList
  end
  
function getMeasureRhythmList(measureIndex, voiceIndex)
  local measureStartPPQPOS, measureEndPPQPOS, measureSectionName, measureQNStart, measureQNEnd, currentQN, timeSigNum, timeSigDenom, beatTable, beamGroupingsTable, currentBeat, quantizeNum, quantizeDenom, quantizeTupletFactorNum, quantizeTupletFactorDenom, quantizeModifier, restOffsets, qnTickTableBothVoices, measureTupletListBothVoices = getMeasureData(measureIndex)
  
  local qnTickTable = qnTickTableBothVoices[voiceIndex]
  local measureTupletList = measureTupletListBothVoices[voiceIndex]
  
  local measureNoteList = getMeasureNoteList(measureIndex, voiceIndex)
  
  --reaper.ShowConsoleMsg("----------------\n")
  local chordList = {}
  
  --group chords
  for x=1, #measureNoteList do
    local currentNote = measureNoteList[x]
    local qnQuantizedCurrent = currentNote[NOTELISTINDEX_QNQUANTIZED]
    local qnQuantizedPrev
    if x > 1 then
      local prevNote = measureNoteList[x-1]
      qnQuantizedPrev = prevNote[NOTELISTINDEX_QNQUANTIZED]
      end
      
    if qnQuantizedPrev ~= qnQuantizedCurrent then
      local ppqpos = currentNote[NOTELISTINDEX_STARTPPQPOS]
      local isRest = (currentNote[NOTELISTINDEX_CHANNEL] == nil)
      tableInsert(chordList, { {qnQuantizedCurrent, ppqpos, voiceIndex, isRest, {} }, {} })
      end
    
    tableInsert(chordList[#chordList][2], currentNote)
    end
    
  local rhythmList = {}
  
  local function getRhythmStr(rhythmData)
    local rhythmNum = rhythmData[RHYTHMLISTINDEX_NUM]
    local rhythmDenom = rhythmData[RHYTHMLISTINDEX_DENOM]
    local tupletFactorNum = rhythmData[RHYTHMLISTINDEX_TUPLETFACTORNUM]
    local tupletFactorDenom = rhythmData[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
    local hasDot = rhythmData[RHYTHMLISTINDEX_HASDOT]
    
    local dotStr
    if hasDot then
      dotStr = "d"
    else
      dotStr = ""
      end
    
    return rhythmNum .. "/" .. rhythmDenom .. dotStr .. " (" .. tupletFactorNum .. ":" .. tupletFactorDenom .. ")"
    end
    
  local function printRhythmList()
    reaper.ShowConsoleMsg("RHYTHMLIST " .. voiceIndex .. " m." .. measureIndex .. ": ")
    for rhythmListIndex=1, #rhythmList do
      local data = rhythmList[rhythmListIndex]
      reaper.ShowConsoleMsg(getRhythmStr(data))
      if rhythmListIndex < #rhythmList then
        reaper.ShowConsoleMsg(", ")
        end
      end
    reaper.ShowConsoleMsg("\n")
    end
  
  local function attemptToCancelTupletFactor(rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom)
    local simplifiedNum, simplifiedDenom = simplifyFraction(rhythmNum*tupletFactorNum, rhythmDenom*tupletFactorDenom)
    if isInTable(VALID_RHYTHM_DENOM_LIST, simplifiedDenom) then
      rhythmNum = simplifiedNum
      rhythmDenom = simplifiedDenom
      tupletFactorNum = 1
      tupletFactorDenom = 1
      end
    
    return rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom
    end
    
  local function getQuantizedRhythmNumDenom(qnBoundStart, qnBoundEnd)
    local startBeat = getBeat(beatTable, qnBoundStart)
    local endBeat = getBeat(beatTable, qnBoundEnd)
    local beatDifference = endBeat - startBeat
    
    local rhythmNum = round(beatDifference * quantizeDenom / timeSigDenom)
    local rhythmDenom = round(quantizeDenom)
    
    rhythmNum = rhythmNum * quantizeTupletFactorDenom
    rhythmDenom = rhythmDenom * quantizeTupletFactorNum
    rhythmNum, rhythmDenom = simplifyFraction(rhythmNum, rhythmDenom)
    
    local tupletFactorNum = quantizeTupletFactorNum
    local tupletFactorDenom = quantizeTupletFactorDenom
    
    rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom = attemptToCancelTupletFactor(rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom)
    
    local rhythmNum, rhythmDenom, hasDot = attemptToGetDot(rhythmNum, rhythmDenom)
    
    return rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom, hasDot
    end
  
  local function getTotalRhythmUpTo(startIndex, endIndex)
    local denom = 1
    local numeratorList = {}
    local denominatorList = {}
    for x=startIndex, endIndex-1 do
      local data = rhythmList[x]
      local actualRhythmNum, actualRhythmDenom = getActualRhythmNumDenom(data)
      tableInsert(numeratorList, actualRhythmNum)
      tableInsert(denominatorList, actualRhythmDenom)
      end
    
    if #numeratorList == 0 then return 0, 1 end
    
    local rhythmDenom = lcmOfTable(denominatorList)
    local rhythmNum = 0
    for x=1, #numeratorList do
      local originalNum = numeratorList[x]
      local originalDenom = denominatorList[x]
      local factor = roundFloatingPoint(rhythmDenom/originalDenom)
      rhythmNum = rhythmNum + originalNum*factor
      end
    
    rhythmNum, rhythmDenom = simplifyFraction(rhythmNum, rhythmDenom)
    return rhythmNum, rhythmDenom
    end
  
  local function splitRhythm(index, crossPointNum, crossPointDenom)
    local data = rhythmList[index]
    local rhythmNum = data[RHYTHMLISTINDEX_NUM]
    local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
    local tupletFactorNum = data[RHYTHMLISTINDEX_TUPLETFACTORNUM]
    local tupletFactorDenom = data[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
    local hasDot = data[RHYTHMLISTINDEX_HASDOT]
    
    if hasDot then
      rhythmNum = round(rhythmNum * 3)
      rhythmDenom = round(rhythmDenom * 2)
      end
      
    local rhythmNumBefore, rhythmDenomBefore = getTotalRhythmUpTo(1, index)
    local rhythmBefore = roundFloatingPoint(rhythmNumBefore/rhythmDenomBefore)
    local rhythmNumAfter, rhythmDenomAfter = addIntegerFractions(rhythmNumBefore, rhythmDenomBefore, rhythmNum, rhythmDenom)
    local rhythmAfter = roundFloatingPoint(rhythmNumAfter/rhythmDenomAfter)
    
    local earlyRhythmNum, earlyRhythmDenom = addIntegerFractions(crossPointNum, crossPointDenom, -1*(rhythmNumBefore), rhythmDenomBefore)
    local laterRhythmNum, laterRhythmDenom = addIntegerFractions(rhythmNumAfter, rhythmDenomAfter, (-1)*crossPointNum, crossPointDenom)
    
    local earlyRhythmNum, earlyRhythmDenom, earlyTupletFactorNum, earlyTupletFactorDenom = attemptToCancelTupletFactor(earlyRhythmNum, earlyRhythmDenom, tupletFactorNum, tupletFactorDenom)
    local laterRhythmNum, laterRhythmDenom, laterTupletFactorNum, laterTupletFactorDenom = attemptToCancelTupletFactor(laterRhythmNum, laterRhythmDenom, tupletFactorNum, tupletFactorDenom)
    
    local earlyRhythmNum, earlyRhythmDenom, earlyHasDot = attemptToGetDot(earlyRhythmNum, earlyRhythmDenom)
    local laterRhythmNum, laterRhythmDenom, laterHasDot = attemptToGetDot(laterRhythmNum, laterRhythmDenom)
      
    data[RHYTHMLISTINDEX_NUM] = earlyRhythmNum
    data[RHYTHMLISTINDEX_DENOM] = earlyRhythmDenom
    data[RHYTHMLISTINDEX_TUPLETFACTORNUM] = earlyTupletFactorNum
    data[RHYTHMLISTINDEX_TUPLETFACTORDENOM] = earlyTupletFactorDenom
    data[RHYTHMLISTINDEX_HASDOT] = earlyHasDot
    
    local testEarlyHasDotStr = ""
    if earlyHasDot then testEarlyHasDotStr = "d" end
    local testLaterHasDotStr = ""
    if laterHasDot then testLaterHasDotStr = "d" end
    --reaper.ShowConsoleMsg("TEST: " .. earlyRhythmNum .. "/" .. earlyRhythmDenom .. testEarlyHasDotStr .. ", " .. laterRhythmNum .. "/" .. laterRhythmDenom .. testLaterHasDotStr .. "\n")
    
    local beat = getBeat(beatTable, roundFloatingPoint(crossPointNum/crossPointDenom), true)
    local crossPointQN = getQNFromBeat(beatTable, beat)
    table.insert(rhythmList, index+1, {laterRhythmNum, laterRhythmDenom, laterTupletFactorNum, laterTupletFactorDenom, laterHasDot, crossPointQN})
    end
  
  local restList = restListBothVoices[voiceIndex]
  local restListIndex = findIndexInListEqualOrLessThan(restList, measureEndPPQPOS-1, 1)
  local sustainList = sustainListBothVoices[voiceIndex]
      
  --calculate rhythms from measureNoteList
  local graceChordList
  for chordID=1, #chordList do
    local chord = chordList[chordID]
    local chordGlobalData = chord[1]
    local chordNotes = chord[2]
    
    local qnQuantizedCurrent = chordGlobalData[CHORDGLOBALDATAINDEX_QN]
    
    local qnQuantizedNext
    if chordID < #chordList then
      local nextChord = chordList[chordID+1]
      local nextChordGlobalData = nextChord[1]
      qnQuantizedNext = nextChordGlobalData[CHORDGLOBALDATAINDEX_QN]
    else
      qnQuantizedNext = measureQNEnd
      end
    
    local isRest = chordGlobalData[CHORDGLOBALDATAINDEX_ISREST]
    if isRest then
      chord = nil
      end
      
    local rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom, hasDot = getRhythmOverride(qnQuantizedCurrent, qnQuantizedNext, beatTable, timeSigDenom, voiceIndex, measureTupletList, chord)
    
    if rhythmNum == 0 then --if gracenote
      if not graceChordList then
        graceChordList = {}
        end
      tableInsert(graceChordList, chord)
    else
      if not rhythmNum then
        rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom, hasDot = getQuantizedRhythmNumDenom(qnQuantizedCurrent, qnQuantizedNext)
        end
      
      tableInsert(rhythmList, {rhythmNum, rhythmDenom, tupletFactorNum, tupletFactorDenom, hasDot, qnQuantizedCurrent, chord})
      if graceChordList then
        rhythmList[#rhythmList][RHYTHMLISTINDEX_GRACECHORDLIST] = {}
        for x=1, #graceChordList do
          tableInsert(rhythmList[#rhythmList][RHYTHMLISTINDEX_GRACECHORDLIST], graceChordList[x])
          end
        graceChordList = nil
        end
      end
    end
  
   --add potential rest at beginning, or return if empty measure
  if #rhythmList == 0 then
    return {}
    end
  local firstQN = rhythmList[1][RHYTHMLISTINDEX_QN]
  if firstQN ~= measureQNStart then
    local rhythmNumInitialRest, rhythmDenomInitialRest, tupletFactorNum, tupletFactorDenom, hasDot = getRhythmOverride(measureQNStart, firstQN, beatTable, timeSigDenom, voiceIndex, measureTupletList)
    if not rhythmNumInitialRest then
      rhythmNumInitialRest, rhythmDenomInitialRest, tupletFactorNum, tupletFactorDenom, hasDot = getQuantizedRhythmNumDenom(measureQNStart, firstQN)
      end
    table.insert(rhythmList, 1, {rhythmNumInitialRest, rhythmDenomInitialRest, tupletFactorNum, tupletFactorDenom, hasDot, measureQNStart})
    end
  
  --delete 0-length rests (important for start-of-measure grace notes)
  for index=#rhythmList, 1, -1 do
    local data = rhythmList[index]
    local rhythmNum = data[RHYTHMLISTINDEX_NUM]
    if rhythmNum == 0 then
      table.remove(rhythmList, index) --unnecessary now?
      reaper.ShowConsoleMsg("DELETED 0: " .. measureIndex .. " " .. voiceIndex .. " " .. index .. "\n")
      end
    end
  
  local function checkRhythmsEqualMeasureLength(rhythmList)
    local total = 0
    for x=1, #rhythmList do
      local data = rhythmList[x]
      local actualRhythmNum, actualRhythmDenom = getActualRhythmNumDenom(data)
      total = total + actualRhythmNum/actualRhythmDenom
      end
      
    local measureTotal = roundFloatingPoint(total)
    local timeSigTotal = roundFloatingPoint(timeSigNum/timeSigDenom)
      
    if measureTotal ~= timeSigTotal and measureTotal ~= 0 then
      printRhythmList()
      throwError("Rhythms in measure " .. measureIndex .. " do not add up to time signature!\n\nMeasure = " .. measureTotal .. ", Time Signature = " .. timeSigTotal .. " (" .. timeSigNum .. "/" .. timeSigDenom .. ")", measureIndex)
      end
    end
  
  local function checkValidRhythmNumDenoms(rhythmList)
    for x=1, #rhythmList do
      local data = rhythmList[x]
      local rhythmNum = data[RHYTHMLISTINDEX_NUM]
      local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
      if rhythmNum ~= 1 then
        reaper.ShowConsoleMsg("RHYTHMNUM NOT 1: " .. getRhythmStr(data) .. "\n")
        end
      if not isInTable(VALID_RHYTHM_DENOM_LIST, rhythmDenom) then
        reaper.ShowConsoleMsg("INVALID RHYTHMDENOM: " .. getRhythmStr(data) .. "\n")
        end
      end
    end
    
  checkRhythmsEqualMeasureLength(rhythmList)
  
  local function splitRhythmsAtEndOfSustainLanes()
    local testCount = 0
    local rhythmListIndex = 1
    while rhythmListIndex <= #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      local qnStart = data[RHYTHMLISTINDEX_QN]
      local qnEnd
      if rhythmListIndex == #rhythmList then
        qnEnd = measureQNEnd
      else
        qnEnd = rhythmList[rhythmListIndex+1][RHYTHMLISTINDEX_QN]
        end
      
      local split = false
      for x=1, #sustainList do
        local sustainData = sustainList[x]
        local sustainEndQN = sustainData[SUSTAINLISTINDEX_ENDQN]
        if sustainEndQN > qnStart and sustainEndQN < qnEnd then
          split = true
          local crossPointNum, crossPointDenom, _, _, hasDot = getQuantizedRhythmNumDenom(measureQNStart, sustainEndQN) --from the start of measure
          if hasDot then
            crossPointNum = crossPointNum * 3
            crossPointDenom = crossPointDenom * 2
            end
          --reaper.ShowConsoleMsg("CROSS: " .. crossPointNum .. "/" .. crossPointDenom .. " " .. measureQNStart .. " " .. sustainEndQN .. " " .. qnStart .. " " .. qnEnd .. "\n")
          splitRhythm(rhythmListIndex, crossPointNum, crossPointDenom)
          break
          end
        end
        
      if not split then
        rhythmListIndex = rhythmListIndex + 1
        end
      
      testCount = testCount + 1
      if testCount == 1000 then
        error("ERROR: further splitting rhythm list sustain lanes\n")
        break
        end
      end
    end
    
  local function splitRhythmsAcrossStrongBeats()
    local testCount = 0
    local rhythmListIndex = 1
    while rhythmListIndex <= #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      local rhythmNum = data[RHYTHMLISTINDEX_NUM]
      local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
      local tupletFactorNum = data[RHYTHMLISTINDEX_TUPLETFACTORNUM]
      local tupletFactorDenom = data[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
      
      local crossPointBeat
      if tupletFactorNum == 1 and tupletFactorDenom == 1 then
        local rhythmNumBefore, rhythmDenomBefore = getTotalRhythmUpTo(1, rhythmListIndex)
        local rhythmBefore = roundFloatingPoint(rhythmNumBefore/rhythmDenomBefore)
        local rhythmNumAfter, rhythmDenomAfter = addIntegerFractions(rhythmNumBefore, rhythmDenomBefore, rhythmNum, rhythmDenom)
        local rhythmAfter = roundFloatingPoint(rhythmNumAfter/rhythmDenomAfter)

        local boundStart = rhythmBefore
        local boundEnd = roundFloatingPoint(boundStart+rhythmNum/rhythmDenom)
        
        local startBeat = getBeat(beatTable, boundStart, true)
        local endBeat = getBeat(beatTable, boundEnd, true)
        local flooredStartBeat = floor(startBeat)
        local flooredEndBeat = floor(endBeat)
        
        local foundFirstStrongBeat = false
        for beatID=flooredStartBeat+1, flooredEndBeat do
          if beatTable[beatID+1][2] then
            if not (beatTable[beatID+1][3] == boundEnd) then
              crossPointBeat = beatID
              end
            break
            end
          end
        end
      
      if crossPointBeat then
        --split note and rest
        local beatData = beatTable[crossPointBeat+1]
        local crossPointNum = beatData[4]
        local crossPointDenom = beatData[5]
        splitRhythm(rhythmListIndex, crossPointNum, crossPointDenom)
      else
        rhythmListIndex = rhythmListIndex + 1
        end
      
      testCount = testCount + 1
      if testCount == 1000 then
        error("ERROR: further splitting rhythm list\n")
        break
        end
      end
    end
  
  local function splitInvalidRhythmValues()
    --reaper.ShowConsoleMsg("---SPLIT INVALID RHYTHM VALUES---\n")
    local testCount = 0
    local rhythmListIndex = 1
    while rhythmListIndex <= #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      local rhythmNum = data[RHYTHMLISTINDEX_NUM]
      local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
      local tupletFactorNum = data[RHYTHMLISTINDEX_TUPLETFACTORNUM]
      local tupletFactorDenom = data[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
      local hasDot = data[RHYTHMLISTINDEX_HASDOT]
      
      local chord = data[RHYTHMLISTINDEX_CHORD]
      
      local isRest = (chord == nil)
      
      local label, notatedRhythmDenom, tupletModifier = getFlagOrRestLabel(rhythmNum, rhythmDenom, isRest, rhythmList, rhythmListIndex, voiceIndex, measureTupletList)
      
      if not label then
        local rhythmNumBefore, rhythmDenomBefore = getTotalRhythmUpTo(1, rhythmListIndex)
        local rhythmBefore = roundFloatingPoint(rhythmNumBefore/rhythmDenomBefore)
        
        local splitNum = math.ceil(rhythmNum/2)
        local splitDenom = rhythmDenom
        
        local crossPointNum, crossPointDenom = addIntegerFractions(rhythmNumBefore, rhythmDenomBefore, splitNum, splitDenom)
        
        splitRhythm(rhythmListIndex, crossPointNum, crossPointDenom)
      else
        data[RHYTHMLISTINDEX_LABEL] = label
        data[RHYTHMLISTINDEX_NOTATEDRHYTHMDENOM] = notatedRhythmDenom
        data[RHYTHMLISTINDEX_TUPLETMODIFIER] = tupletModifier
        data[RHYTHMLISTINDEX_HASDOT] = hasDot
        
        rhythmListIndex = rhythmListIndex + 1
        end
      
      testCount = testCount + 1
      if testCount == 1000 then
        error("ERROR: further splitting invalid rhythm list\n")
        break
        end
      end
    end
  
  local function replaceRestsUnderSustainLanesWithChords()
    for rhythmListIndex=1, #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      if not data[RHYTHMLISTINDEX_CHORD] then
        local qnStart = data[RHYTHMLISTINDEX_QN]
        
        for x=1, #sustainList do
          local sustainData = sustainList[x]
          local sustainStartQN = sustainData[SUSTAINLISTINDEX_STARTQN]
          local sustainEndQN = sustainData[SUSTAINLISTINDEX_ENDQN]
          if qnStart >= sustainStartQN and qnStart < sustainEndQN then
            local prevRhythmListData
            if rhythmListIndex == 1 then
              local prevRhythmList = masterRhythmListBothVoices[voiceIndex][measureIndex-1]
              prevRhythmListData = prevRhythmList[#prevRhythmList]
            else
              prevRhythmListData = rhythmList[rhythmListIndex-1]
              end
            
            local prevChord = prevRhythmListData[RHYTHMLISTINDEX_CHORD]
            data[RHYTHMLISTINDEX_CHORD] = deepCopy(prevChord)
            local prevLabel = data[RHYTHMLISTINDEX_LABEL]
            data[RHYTHMLISTINDEX_LABEL] = "flag_" .. string.sub(prevLabel, 6, #prevLabel)
            prevRhythmListData[RHYTHMLISTINDEX_STARTTIE] = true
            data[RHYTHMLISTINDEX_FAKECHORD] = true
            
            local chord = data[RHYTHMLISTINDEX_CHORD]
            local chordGlobalData = chord[1]
            chordGlobalData[CHORDGLOBALDATAINDEX_FAKECHORD] = true
            break
            end
          end
        end
      end
    end
  
  local function addExtraTieAtEndOfSustainLanes()
    for rhythmListIndex=1, #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      local qnStart = data[RHYTHMLISTINDEX_QN]
      
      for x=1, #sustainList do
        local sustainData = sustainList[x]
        local sustainEndQN = sustainData[SUSTAINLISTINDEX_ENDQN]
        local sustainTie = sustainData[SUSTAINLISTINDEX_TIE]
        if qnStart == sustainEndQN and sustainTie then
          local prevRhythmListData
          if rhythmListIndex == 1 then
            local prevRhythmList = masterRhythmListBothVoices[voiceIndex][measureIndex-1]
            prevRhythmListData = prevRhythmList[#prevRhythmList]
          else
            prevRhythmListData = rhythmList[rhythmListIndex-1]
            end
          
          local prevChord = prevRhythmListData[RHYTHMLISTINDEX_CHORD]
          if prevChord then
            prevRhythmListData[RHYTHMLISTINDEX_STARTTIE] = true
            end
          break
          end
        end
      end
    end
  
  local function markChordsThatHaveExtraTie()
    --TODO: optimize
    for rhythmListIndex=1, #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      local qnStart = data[RHYTHMLISTINDEX_QN]
      
      for x=1, #sustainList do
        local sustainData = sustainList[x]
        local sustainStartQN = sustainData[SUSTAINLISTINDEX_STARTQN]
        local sustainTie = sustainData[SUSTAINLISTINDEX_TIE]
        if sustainStartQN == qnStart then
          local chord = data[RHYTHMLISTINDEX_CHORD]
          local chordGlobalData = chord[1]
          chordGlobalData[CHORDGLOBALDATAINDEX_EXTRATIE] = sustainTie
          end
        if sustainStartQN >= qnStart then
          break
          end
        end
      end
    end
    
  --TODO: check elsewhere that timeSigDenom is always a power of 2, from 1 up to MAX_RHYTHM
    
  splitRhythmsAtEndOfSustainLanes()
  
  splitRhythmsAcrossStrongBeats()
    
  splitInvalidRhythmValues()
  
  replaceRestsUnderSustainLanesWithChords()
  
  addExtraTieAtEndOfSustainLanes()
  
  markChordsThatHaveExtraTie()
  
  checkValidRhythmNumDenoms(rhythmList)
  
  checkRhythmsEqualMeasureLength(rhythmList)
  
  local function assignBeamStatesToEachChordInMeasure()
    local masterBeamList = masterBeamListBothVoices[voiceIndex]
    local isFirstNote
    
    local function endBeam()
      masterCurrentlyBeamingBothVoices[voiceIndex] = false
      end
      
    local function addBeam(chord, baseRhythm, rhythmListIndex)
      if not chord then
        return
        end
        
      local beamTable = masterBeamList[#masterBeamList]
      local secondaryBeamTable = beamTable[#beamTable]
      tableInsert(secondaryBeamTable, {chord, baseRhythm, measureIndex, rhythmListIndex})
      end
    
    local function beginSecondaryBeam(chord, baseRhythm, rhythmListIndex)
      rhythmList[rhythmListIndex][RHYTHMLISTINDEX_NEWBEAM] = true
      
      if not chord then
        return
        end
        
      local beamTable = masterBeamList[#masterBeamList]
      tableInsert(beamTable, {})
      addBeam(chord, baseRhythm, rhythmListIndex)
      end
      
    local function beginBeam(chord, baseRhythm, rhythmListIndex)
      if not chord then
        rhythmList[rhythmListIndex][RHYTHMLISTINDEX_NEWBEAM] = true
        return
        end
        
      tableInsert(masterBeamList, {})
      beginSecondaryBeam(chord, baseRhythm, rhythmListIndex)
      masterCurrentlyBeamingBothVoices[voiceIndex] = true
      end
  
    for rhythmListIndex=1, #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      local rhythmNum = data[RHYTHMLISTINDEX_NUM]
      local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
      local qnQuantized = data[RHYTHMLISTINDEX_QN]
      local chord = data[RHYTHMLISTINDEX_CHORD]
      
      local isRest = (chord == nil)
      local totalRhythmNum, totalRhythmDenom = getTotalRhythmUpTo(1, rhythmListIndex)
      
      if rhythmDenom < 8 or (isRest and not isBeamingOverRests(qnQuantized)) then
        endBeam()
      else
        isFirstNote = (#masterBeamList == 0)
        
        local flagLabel = data[RHYTHMLISTINDEX_LABEL]
        local baseRhythm = tonumber(string.sub(flagLabel, 6, #flagLabel))
        local beamOverrideState
        if chord then
          beamOverrideState = getBeamOverride(chord)
          end
        
        local beamGroupingTableIndex = round(math.log(math.max(baseRhythm, timeSigDenom))/math.log(2) - 2)
        local beamGroupingTable = beamGroupingsTable[beamGroupingTableIndex]
          
        local addedBeam = false
        if not beamOverrideState then
          for x=1, #beamGroupingTable do
            local data = beamGroupingTable[x]
            local isSecondaryBeam = data[1]
            local totalBeamRhythmNum = data[2]
            local totalBeamRhythmDenom = data[3]
            
            if totalBeamRhythmNum == totalRhythmNum and totalBeamRhythmDenom == totalRhythmDenom then
              if isSecondaryBeam then
                if isFirstNote then
                  beginBeam(chord, baseRhythm, rhythmListIndex)
                else
                  beginSecondaryBeam(chord, baseRhythm, rhythmListIndex)
                  end
                addedBeam = true
              else
                endBeam()
                end
              break
              end
            end
          end
        
        if isFirstNote and beamOverrideState and beamOverrideState ~= "none" then
          beginBeam(chord, baseRhythm, rhythmListIndex)
        elseif beamOverrideState == "none" then
          endBeam()
        elseif beamOverrideState == "start" then
          beginBeam(chord, baseRhythm, rhythmListIndex)
        elseif beamOverrideState == "secondary" then
          beginSecondaryBeam(chord, baseRhythm, rhythmListIndex)
        elseif beamOverrideState == "continue" then
          addBeam(chord, baseRhythm, rhythmListIndex)
        elseif beamOverrideState == "end" then
          addBeam(chord, baseRhythm, rhythmListIndex)
          endBeam()
        elseif not addedBeam then --if no override, then default beaming scheme
          if not masterCurrentlyBeamingBothVoices[voiceIndex] then
            beginBeam(chord, baseRhythm, rhythmListIndex)
          else
            addBeam(chord, baseRhythm, rhythmListIndex)
            end
          end
        end
      end
    end
  
  assignBeamStatesToEachChordInMeasure()
  
  --update QN positions to reflect rhythm values
  local newRhythmQNList = {}
  for rhythmIndex=1, #rhythmList do
    local totalRhythmNum, totalRhythmDenom = getTotalRhythmUpTo(1, rhythmIndex)
    local beat = getBeat(beatTable, roundFloatingPoint(totalRhythmNum/totalRhythmDenom), true)
    local rhythmQN = getQNFromBeat(beatTable, beat)
    tableInsert(newRhythmQNList, rhythmQN)
    end
  
  for rhythmListIndex=1, #rhythmList do
    local data = rhythmList[rhythmListIndex]
    data[RHYTHMLISTINDEX_ISRHYTHMOVERRIDE] = isRhythmOverriden(rhythmList, rhythmListIndex, voiceIndex, measureTupletList)
    end
    
  --define bounds of tuplet brackets (quantized)
  local currentTupletStartRhythmIndex, currentTupletModifier, currentTotalRhythmNum, currentTotalRhythmDenom, currentBaseDenom
  local quantizedTupletList = {}
  for rhythmListIndex=1, #rhythmList do
    local data = rhythmList[rhythmListIndex]
    
    local notatedRhythmDenom = data[RHYTHMLISTINDEX_NOTATEDRHYTHMDENOM]
    local tupletModifier = data[RHYTHMLISTINDEX_TUPLETMODIFIER]
    local isRhythmOverride = data[RHYTHMLISTINDEX_ISRHYTHMOVERRIDE]
    
    --end tuplet
    if currentTupletStartRhythmIndex then
      currentBaseDenom = math.max(currentBaseDenom, notatedRhythmDenom)
      local tupletDenom = roundFloatingPoint(currentBaseDenom/currentTotalRhythmDenom)
      
      if currentTotalRhythmNum == 1 and isInTable(VALID_RHYTHM_DENOM_LIST, currentTotalRhythmDenom) and (tupletModifier ~= currentTupletModifier or (data[RHYTHMLISTINDEX_NEWBEAM] and tupletDenom == round(tupletDenom)) or isRhythmOverride) then
        local endQN = rhythmList[rhythmListIndex][RHYTHMLISTINDEX_QN]
        tableInsert(quantizedTupletList[#quantizedTupletList], endQN)
        tableInsert(quantizedTupletList[#quantizedTupletList], currentBaseDenom)
        currentTupletStartRhythmIndex = nil
        currentTupletModifier = nil
      else
        quantizedTupletList[#quantizedTupletList][2] = quantizedTupletList[#quantizedTupletList][2] + 1
        local actualRhythmNum, actualRhythmDenom = getActualRhythmNumDenom(data)
        currentTotalRhythmNum, currentTotalRhythmDenom = addIntegerFractions(currentTotalRhythmNum, currentTotalRhythmDenom, actualRhythmNum, actualRhythmDenom)
        end
      end
    
    --start tuplet
    if not currentTupletModifier and tupletModifier and not isRhythmOverride then
      currentTupletStartRhythmIndex = rhythmListIndex
      currentTupletModifier = tupletModifier
      local startQN = rhythmList[rhythmListIndex][RHYTHMLISTINDEX_QN]
      tableInsert(quantizedTupletList, {rhythmListIndex, 1, tupletModifier, startQN})
      currentTotalRhythmNum, currentTotalRhythmDenom = getActualRhythmNumDenom(data)
      currentBaseDenom = notatedRhythmDenom
      end
    
    data[RHYTHMLISTINDEX_TUPLETXMLDATA] = {}
    end
  
  for x=1, #quantizedTupletList do
    local data = quantizedTupletList[x]
    
    local startRhythmListIndex = data[1]
    local numNotes = data[2]
    local tupletModifier = data[3]
    local startQN = data[4]
    local endQN = data[5]
    if not endQN then
      endQN = measureQNEnd
      end
    local baseDenom = data[6]
    if not baseDenom then
      baseDenom = currentBaseDenom
      end
      
    local endRhythmListIndex = startRhythmListIndex+numNotes-1
    
    local notatedTupletFactorNum, notatedTupletFactorDenom = getTupletFactorNumDenom(tupletModifier)
    
    local totalRhythmNum = 0
    local totalRhythmDenom = 1
    for rhythmListIndex=startRhythmListIndex, endRhythmListIndex do
      local data = rhythmList[rhythmListIndex]

      local actualRhythmNum, actualRhythmDenom = getActualRhythmNumDenom(data)
      totalRhythmNum, totalRhythmDenom = addIntegerFractions(totalRhythmNum, totalRhythmDenom, actualRhythmNum, actualRhythmDenom)
      --todo: if tupletFactorNum or tupletFactorDenom are not the same as the tuplet, renotate in terms of the tuplet?
      
      local rhythmNum = data[RHYTHMLISTINDEX_NUM]
      local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
      local tupletFactorNum = data[RHYTHMLISTINDEX_TUPLETFACTORNUM]
      local tupletFactorDenom = data[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
      local hasDot = data[RHYTHMLISTINDEX_HASDOT]
      
      rhythmNum = round(rhythmNum * (notatedTupletFactorDenom/tupletFactorDenom))
      rhythmDenom = round(rhythmDenom * (notatedTupletFactorNum/tupletFactorNum))
      rhythmNum, rhythmDenom, hasDot = attemptToGetDot(rhythmNum, rhythmDenom)
        
      data[RHYTHMLISTINDEX_NUM] = rhythmNum
      data[RHYTHMLISTINDEX_DENOM] = rhythmDenom
      data[RHYTHMLISTINDEX_TUPLETFACTORNUM] = notatedTupletFactorNum
      data[RHYTHMLISTINDEX_TUPLETFACTORDENOM] = notatedTupletFactorDenom
      data[RHYTHMLISTINDEX_HASDOT] = hasDot
      end
      
    totalRhythmNum, totalRhythmDenom = simplifyFraction(totalRhythmNum, totalRhythmDenom)
    if totalRhythmNum ~= 1 then --check should only be relevant for last index in quantizedTupletList
      printRhythmList()
      throwError("totalRhythmNum not equal to 1! " .. totalRhythmNum .. "/" .. totalRhythmDenom .. " " .. x .. " == " .. #quantizedTupletList, measureIndex)
      end
    local tupletDenom = roundFloatingPoint(baseDenom/totalRhythmDenom)
    if tupletDenom ~= round(tupletDenom) then
      printRhythmList()
      throwError("Bad tupletDenom! " .. baseDenom .. "/" .. totalRhythmDenom, measureIndex)
      end
    tupletDenom = round(tupletDenom)
    local logFactor = round(math.log(tupletDenom)/math.log(2))
    
    local tupletNum
    if tupletModifier == "t" then
      tupletNum = round(3*(2^(logFactor-1)))
      end
    if tupletModifier == "q" then
      tupletNum = round(5*(2^(logFactor-2)))
      end
    if tupletModifier == "s" then
      tupletNum = round(7*(2^(logFactor-2)))
      end
    
    if not tupletNum then
      throwError("Tuplet does not add up! " .. voiceIndex, measureIndex)
    else
      tableInsert(measureTupletList, {})
      local subList = measureTupletList[#measureTupletList]
      subList[3] = startQN
      subList[4] = endQN
      subList[5] = baseDenom
      subList[6] = tupletNum
      subList[7] = tupletDenom
      subList[8] = false
      subList[9] = 0
      end
    end
    
  --define bounds of tuplet brackets (override)
  local function getTotalTupletBaseDenom(startQN, endQN, tupletLevel, baseDenom)
    tupletLevel = tupletLevel - 1
    
    local testCount = 0
    while tupletLevel >= 0 do
      for x=1, #measureTupletList do
        local data = measureTupletList[x]
        
        local testStartQN = data[3]
        local testEndQN = data[4]
        local testBaseDenom = data[5]
        local testTupletNum = data[6]
        local testTupletDenom = data[7]
        local testTupletLevel = data[9]
        
        if testTupletLevel == tupletLevel and startQN >= testStartQN and endQN <= testEndQN then
          baseDenom = roundFloatingPoint(baseDenom * (testBaseDenom/baseDenom) * (testTupletNum/testTupletDenom))

          startQN = testStartQN
          endQN = testEndQN
          end
        end
        
      tupletLevel = tupletLevel - 1
      
      testCount = testCount + 1
      if testCount == 100 then
        throwError("Bad totalTupletNumDenom calculation!", measureIndex)
        end
      end
    
    return baseDenom
    end
  
  for x=1, #measureTupletList do
    local data = measureTupletList[x]
    
    local startPPQPOS = data[1]
    local endPPQPOS = data[2]
    local startQN = data[3]
    local endQN = data[4]
    local baseDenom = data[5]
    local tupletNum = data[6]
    local tupletDenom = data[7]
    local showColon = data[8]
    local tupletLevel = data[9]
    
    local totalBaseDenom = getTotalTupletBaseDenom(startQN, endQN, tupletLevel, baseDenom)
    
    local xmlTupletNum = tupletLevel + 1
    
    local oldTupletStartQN = startQN
    local oldTupletEndQN = endQN
    local newTupletStartQN, newTupletEndQN
    
    local insideXmlTuplet = false
    local currentTimeModificationData
    local startRhythmIndex, totalRhythmNum, totalRhythmDenom
    
    local function storeXmlTuplet(rhythmIndex, state)
      local rhythmData = rhythmList[rhythmIndex]
      
      if state == "stop" then
        local currentTupletTable = rhythmData[RHYTHMLISTINDEX_TUPLETXMLDATA]
        currentTupletTable[#currentTupletTable][1] = state
        insideXmlTuplet = false
        
        local totalRhythmNumNotated, totalRhythmDenomNotated = getTotalRhythmUpTo(startRhythmIndex, rhythmIndex+1)
        local totalRhythmNumExpected, totalRhythmDenomExpected = simplifyFraction(tupletDenom, totalBaseDenom)
        
        if totalRhythmNumNotated ~= totalRhythmNumExpected or totalRhythmDenomNotated ~= totalRhythmDenomExpected then
          reaper.ShowConsoleMsg("NOTATED: " .. totalRhythmNumNotated .. "/" .. totalRhythmDenomNotated .. ", EXPECTED: " .. totalRhythmNumExpected .. "/" .. totalRhythmDenomExpected .. " m." .. measureIndex .. ", voice " .. voiceIndex .. ", " .. totalBaseDenom .. "\n")
          reaper.ShowConsoleMsg(tupletNum .. ":" .. tupletDenom .. ", " .. baseDenom .. "\n")
          throwError("Tuplet rhythmic error! " .. totalRhythmNumNotated .. "/" .. totalRhythmDenomNotated .. " ~= " .. totalRhythmNumExpected .. "/" .. totalRhythmDenomExpected, measureIndex)
          end
        
        rhythmData[RHYTHMLISTINDEX_ENDSTUPLET] = true
      else
        if state == "start" then
          local timeModificationData = rhythmData[RHYTHMLISTINDEX_TIMEMODIFICATIONXMLDATA]
          if not timeModificationData then
            rhythmData[RHYTHMLISTINDEX_TIMEMODIFICATIONXMLDATA] = {tupletNum, tupletDenom, baseDenom}
            timeModificationData = {tupletNum, tupletDenom, baseDenom}
          else
            timeModificationData[1] = round(timeModificationData[1] * tupletNum)
            timeModificationData[2] = round(timeModificationData[2] * tupletDenom)
            end
          currentTimeModificationData = timeModificationData
          insideXmlTuplet = true
          startRhythmIndex = rhythmIndex
          rhythmData[RHYTHMLISTINDEX_BEGINSTUPLET] = true
          end
        rhythmData[RHYTHMLISTINDEX_TIMEMODIFICATIONXMLDATA] = {}
        for x=1, #currentTimeModificationData do
          rhythmData[RHYTHMLISTINDEX_TIMEMODIFICATIONXMLDATA][x] = currentTimeModificationData[x]
          end
        tableInsert(rhythmData[RHYTHMLISTINDEX_TUPLETXMLDATA], {state, xmlTupletNum, showColon})
        end
      end
    
    for rhythmIndex=1, #rhythmList do
      local rhythmData = rhythmList[rhythmIndex]
      local oldRhythmQN = rhythmData[RHYTHMLISTINDEX_QN]
      local newRhythmQN = newRhythmQNList[rhythmIndex]
        
      if oldRhythmQN == oldTupletStartQN then
        newTupletStartQN = newRhythmQN
        storeXmlTuplet(rhythmIndex, "start")
      elseif oldRhythmQN == oldTupletEndQN then
        newTupletEndQN = newRhythmQN
        storeXmlTuplet(rhythmIndex-1, "stop")
      elseif insideXmlTuplet then
        storeXmlTuplet(rhythmIndex, nil)
        end
      end
    if oldTupletEndQN == measureQNEnd then
      newTupletEndQN = oldTupletEndQN
      storeXmlTuplet(#rhythmList, "stop")
      end
    
    if not newTupletStartQN then
      throwError(oldTupletStartQN .. " No newTupletStartQN", measureIndex)
      end
    if not newTupletEndQN then
      throwError(oldTupletEndQN .. " No newTupletEndQN", measureIndex)
      end

    data[10] = newTupletStartQN
    data[11] = newTupletEndQN
    end
  
  measureList[measureIndex][MEASURELISTINDEX_TUPLETLIST][voiceIndex] = measureTupletList
  
  for rhythmIndex=1, #newRhythmQNList do
    rhythmList[rhythmIndex][RHYTHMLISTINDEX_QN] = newRhythmQNList[rhythmIndex]
    end
  
  --get maximum rhythm length
  local function getRhythmWithoutTuplets(rhythmListIndex)
    local data = rhythmList[rhythmListIndex]
    
    local rhythmNum = data[RHYTHMLISTINDEX_NUM]
    local rhythmDenom = data[RHYTHMLISTINDEX_DENOM]
    local hasDot = data[RHYTHMLISTINDEX_HASDOT]
    if hasDot then
      rhythmNum = round(rhythmNum*3)
      rhythmDenom = round(rhythmDenom*2)
      end
    return rhythmNum, rhythmDenom
    end
    
  local function getMaximumAllowedRhythmicValueWithoutTuplets(startRhythmListIndex)
    local totalRhythmNum = 0
    local totalRhythmDenom = 1

    for rhythmListIndex=startRhythmListIndex, #rhythmList do
      local data = rhythmList[rhythmListIndex]
      
      local rhythmNum, rhythmDenom = getRhythmWithoutTuplets(rhythmListIndex)
      totalRhythmNum, totalRhythmDenom = addIntegerFractions(totalRhythmNum, totalRhythmDenom, rhythmNum, rhythmDenom)

      local nextData = rhythmList[rhythmListIndex+1]
      if data[RHYTHMLISTINDEX_ENDSTUPLET] or not nextData or nextData[RHYTHMLISTINDEX_CHORD] or nextData[RHYTHMLISTINDEX_BEGINSTUPLET] or nextData[RHYTHMLISTINDEX_ISRHYTHMOVERRIDE] then
        local minQN = rhythmList[startRhythmListIndex][RHYTHMLISTINDEX_QN]
        local maxQN
        if not nextData then
          maxQN = measureQNEnd
        else
          maxQN = nextData[RHYTHMLISTINDEX_QN]
          end
        local minBeat = getBeat(beatTable, minQN)
        local maxBeat = getBeat(beatTable, maxQN)

        return totalRhythmNum, totalRhythmDenom, minBeat, maxBeat
        end
      end
    end
    
  for rhythmListIndex=1, #rhythmList do
    local data = rhythmList[rhythmListIndex]
    local currentRhythmNum, currentRhythmDenom = getRhythmWithoutTuplets(rhythmListIndex)
    local maxRhythmNum, maxRhythmDenom, minBeat, maxBeat = getMaximumAllowedRhythmicValueWithoutTuplets(rhythmListIndex)
    data[RHYTHMLISTINDEX_CURRENTRHYTHMWITHOUTTUPLETS] = roundFloatingPoint(currentRhythmNum/currentRhythmDenom)
    data[RHYTHMLISTINDEX_MAXRHYTHMWITHOUTTUPLETS] = roundFloatingPoint(maxRhythmNum/maxRhythmDenom)
    data[RHYTHMLISTINDEX_MINBEAT] = minBeat
    data[RHYTHMLISTINDEX_MAXBEAT] = maxBeat
    end
  
  if measureIndex == 2 and voiceIndex == 1 then
    --printRhythmList()
    end
    
  return rhythmList
  end
    
function processMeasure(measureIndex, isActiveMeasure)
  local qnStart, qnEnd, qnStepList, quantizeNum, quantizeDenom, quantizeTupletFactorNum, quantizeTupletFactorDenom, quantizeModifier, qnStepSize, currentQN, timeSigNum, timeSigDenom, beatTable, currentBeat
  
  stopMultiMeasure = false
  
  local function getQNXPos(qn, isDrawList)
    local beat = getBeat(beatTable, qn)
    local val = measureBoundXMin + beat*QUARTERBEATXLEN/(timeSigDenom/4)

    if not isDrawList then
      val = val - notationWindowX
      end
    return val
    end
    
  local function drawNotes()
    local stemList = {}
    local measureChordList = {}
      
    function addToMeasureChordList(data)
      local qn = data[2]
      
      local function getClosestIndex()
        if #measureChordList == 0 then
          return 0, false
          end
          
        local low = 1
        local high = #measureChordList
        local exactMatch = false
        local closestLowerIndex = nil
      
        while low <= high do
          local mid = floor((low + high) / 2)
          local midValue = measureChordList[mid][1][2] -- First value in the subtable
          
          if midValue == qn then
            return mid, true -- Return the exact match index and true
          elseif midValue < qn then
            closestLowerIndex = mid -- Potential closest lower value
            low = mid + 1 -- Search the right half
          else
            high = mid - 1 -- Search the left half
            end
          end
      
        -- If no exact match is found, return the closest lower index and false
        return closestLowerIndex, false
        end
      
      local index, exactMatch = getClosestIndex()
      local subList
      if not index then --gracenote
        table.insert(measureChordList, 1, {})
        subList = measureChordList[1]
      elseif exactMatch then
        subList = measureChordList[index]
      else
        table.insert(measureChordList, index+1, {})
        subList = measureChordList[index+1]
        end
      tableInsert(subList, data)
      end
      
    local function storeRestInEventList(qnQuantized, restLabel, tupletModifier, hasDot, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, voiceIndex, isSingularVoice)
      local imgFileName = restLabel
      local img = getImageFromList(imgFileName)
      if not img then
        throwError("Bad rest label! ", measureIndex)
        end
      local imgSizeX, imgSizeY = getImageSize(imgFileName)
      local imgAspectRatio = imgSizeX/imgSizeY
      
      local xMin = getQNXPos(qnQuantized, true)
      
      local yMin, yMax = getRestYCoordinates(restLabel)
      
      local sizeY = yMax - yMin
      local scalingFactor = sizeY/imgSizeY
      local sizeX = imgSizeX*scalingFactor
      local xMax = xMin + sizeX
      
      xMin = xMin - sizeX/2
      xMax = xMax - sizeX/2
      
      local dotCenterX, dotCenterY
      if hasDot then
        dotCenterX = xMax + DOTSPACING
        dotCenterY = RESTDOTCENTERY
        end
      
      if not isSingularVoice then
        if voiceIndex == 1 then
          yMin = yMin - STAFFSPACEHEIGHT*2
          yMax = yMax - STAFFSPACEHEIGHT*2
          if hasDot then
            dotCenterY = dotCenterY - STAFFSPACEHEIGHT*2
            end
        else
          yMin = yMin + STAFFSPACEHEIGHT*2
          yMax = yMax + STAFFSPACEHEIGHT*2
          if hasDot then
            dotCenterY = dotCenterY + STAFFSPACEHEIGHT*2
            end
          end
        end
      
      local restOffset = restOffsets[voiceIndex]
      if restOffset then
        restOffset = restOffset*STAFFSPACEHEIGHT
        yMin = yMin + restOffset
        yMax = yMax + restOffset
        if hasDot then
          dotCenterY = dotCenterY + restOffset
          end
        end
        
      addToEventList({voiceIndex, qnQuantized, "rest", xMin, yMin, xMax, yMax, img, imgFileName, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, measureIndex})
      
      --if previous event was a tie, draw the tie
      if #masterRecentTiePosDataBothVoices[voiceIndex] > 0 then
        local tieXMin = masterRecentTiePosDataBothVoices[voiceIndex][1]
        for x=2, #masterRecentTiePosDataBothVoices[voiceIndex] do
          local tieXMax = xMin
          local tieYPos = masterRecentTiePosDataBothVoices[voiceIndex][x]
          addToEventList({voiceIndex, qnQuantized, "tie", tieXMin, tieYPos, tieXMax, tieYPos})
          end
        end
        
      if hasDot then
        local dotXMin = dotCenterX - DOTRADIUS
        local dotYMin = dotCenterY - DOTRADIUS
        local dotXMax = dotCenterX + DOTRADIUS
        local dotYMax = dotCenterY + DOTRADIUS
        addToEventList({voiceIndex, qnQuantized, "dot", dotXMin, dotYMin, dotXMax, dotYMax})
        end
      end
      
    local function storeChordInEventList(qnQuantized, chord, graceChordList, flagLabel, tupletModifier, hasDot, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, hasTie, fakeChord, choke, voiceIndex)

      local function processChord(chord, graceQN, graceNoteID)
        local chordNoteheadData = {}
        
        local chordGlobalData = chord[1]
        local chordNotes = chord[2]
        
        local chordQN = chordGlobalData[CHORDGLOBALDATAINDEX_QN]
        local chordArticulationList = chordGlobalData[CHORDGLOBALDATAINDEX_ARTICULATIONLIST]
        
        local stemXPos, stemYPos, lowestStaffLine, highestStaffLine
        
        for chordNoteIndex=1, #chordNotes do
          local noteData = chordNotes[chordNoteIndex]
          
          local noteID = noteData[NOTELISTINDEX_NOTEID]
          local noteStartPPQPOS = noteData[NOTELISTINDEX_STARTPPQPOS]
          local noteStartQN = noteData[NOTELISTINDEX_STARTQN]
          local notationLabel = noteData[NOTELISTINDEX_NOTEHEAD]
          local notationPos = noteData[NOTELISTINDEX_STAFFLINE]
          local noteArticulation = noteData[NOTELISTINDEX_ARTICULATION]
          local velocity = noteData[NOTELISTINDEX_VELOCITY]
          local noteRollType = noteData[NOTELISTINDEX_ROLL]
          
          chordGlobalData[CHORDGLOBALDATAINDEX_ROLL] = noteRollType
          
          local isGhost = isNoteGhost(noteData)
          
          local index = findIndexInListEqualOrLessThan(accentThresholdTextEvtList, noteStartQN, 1)
          local accentThresh = accentThresholdTextEvtList[index][2]
          local isAccent = (accentThresh >= 0 and velocity >= accentThresh)
          if isAccent and not isInTable(chordArticulationList, "accent") then
            tableInsert(chordArticulationList, "accent")
            end
          
          local articulationList = articulationListBothVoices[voiceIndex]
          local articulationListIndex = findClosestIndexAtOrBelow(articulationList, noteStartPPQPOS, ARTICULATIONLISTINDEX_PPQPOS)
          
          if articulationListIndex then
            local articulationPPQPOS = articulationList[articulationListIndex][ARTICULATIONLISTINDEX_PPQPOS]
            if articulationPPQPOS == noteStartPPQPOS then
              local values = articulationList[articulationListIndex][ARTICULATIONLISTINDEX_TABLE]
              for x=1, #values do
                local articulationName = values[x]
                if isInTable(VALID_ARTICULATION_LIST, articulationName) and not isInTable(chordArticulationList, articulationName) then
                  tableInsert(chordArticulationList, articulationName)
                  end
                if articulationName == "noaccent" then
                  local index = isInTable(chordArticulationList, "accent")
                  if index then
                    table.remove(chordArticulationList, index)
                    end
                  end
                end
              end
            end
            
          if not isInTable(chordArticulationList, noteArticulation) then
            tableInsert(chordArticulationList, noteArticulation)
            end
            
          local staffLine, isSpaceAbove = notationPosToStaffLine(notationPos)
          
          local imgFileName = "notehead_" .. notationLabel
          local img = getImageFromList(imgFileName)
          local imgSizeX, imgSizeY = getImageSize(imgFileName)
          local imgAspectRatio = imgSizeX/imgSizeY
          
          local xMin = getQNXPos(qnQuantized, true)
            
          local yMax = getStaffLinePosition(staffLine, isSpaceAbove) + STAFFSPACEHEIGHT/2 
          local yMin = yMax - STAFFSPACEHEIGHT
          if graceNoteID then
            xMin = xMin - graceNoteID*12
            yMin = yMin + STAFFSPACEHEIGHT/6
            yMax = yMax - STAFFSPACEHEIGHT/6
            end
          local sizeY = yMax - yMin
          
          local scalingFactor = sizeY/imgSizeY
          local sizeX = imgSizeX*scalingFactor
          
          local xMax = xMin + sizeX
          
          xMin = xMin - sizeX/2
          xMax = xMax - sizeX/2
            
          if graceNoteID then
            tableInsert(chordNoteheadData, {img, xMin, yMin, xMax, yMax, noteID, chord, chordNoteIndex, graceQN, isGhost, imgFileName})
          else
            tableInsert(chordNoteheadData, {img, xMin, yMin, xMax, yMax, noteID, chord, chordNoteIndex, isSpaceAbove, isGhost, hasTie, fakeChord, imgFileName})
            if hasTie then
              local tieYPos
              if voiceIndex == 1 then
                tieYPos = yMin
              else
                tieYPos = yMax
                end
              tableInsert(currentTiePosData, tieYPos)
              end
            end
            
          local adjustedStemYPercentage = getStemYPercentageDownTheNote(notationLabel)
          if voiceIndex == 2 then
            local adjustedStemX = xMin
            if not stemXPos or adjustedStemX < stemXPos then
              stemXPos = adjustedStemX
              end
            local adjustedStemY = yMax - STAFFSPACEHEIGHT*adjustedStemYPercentage
            if not stemYPos or adjustedStemY < stemYPos then
              stemYPos = adjustedStemY
              end
          else
            local adjustedStemX = xMax
            if not stemXPos or adjustedStemX > stemXPos then
              stemXPos = adjustedStemX
              end
            local adjustedStemY = yMin + STAFFSPACEHEIGHT*adjustedStemYPercentage
            if not stemYPos or adjustedStemY > stemYPos then
              stemYPos = adjustedStemY
              end
            end
          
          local testStaffLine = staffLine
          if not highestStaffLine or testStaffLine > highestStaffLine then
            highestStaffLine = testStaffLine
            end
          if isSpaceAbove then
            testStaffLine = testStaffLine + 1
            end
          if not lowestStaffLine or testStaffLine < lowestStaffLine then
            lowestStaffLine = testStaffLine
            end
          end
        
        --shift notes horisontally to align with stem
        for x=1, #chordNoteheadData do
          local data = chordNoteheadData[x]
          local xOffset
          if voiceIndex == 2 then
            xOffset = stemXPos - data[2]
          else
            xOffset = stemXPos - data[4]
            end
          data[2] = data[2] + xOffset
          data[4] = data[4] + xOffset
          end
          
        --draw stem
        local stemYMin, stemYMax
        if voiceIndex == 2 then
          stemXPos = stemXPos + STEM_XSHIFT
          stemYMin = stemYPos
          if graceNoteID then
            stemYMax = getStaffLinePosition(STEMYPOS_VOICE2+2)
          else
            stemYMax = getStaffLinePosition(STEMYPOS_VOICE2)
            end
        else
          stemXPos = stemXPos - STEM_XSHIFT
          if graceNoteID then
            stemYMin = getStaffLinePosition(STEMYPOS_VOICE1-2)
          else
            stemYMin = getStaffLinePosition(STEMYPOS_VOICE1)
            end
          stemYMax = stemYPos
          end
          
        local category = "stem" .. voiceIndex
        if graceNoteID then
          category = "grace" .. category
          end
        
        local stemQN
        if graceNoteID then
          stemQN = graceQN
        else
          stemQN = qnQuantized
          end
        local chordRollType = chordGlobalData[CHORDGLOBALDATAINDEX_ROLL]
        tableInsert(stemList, {voiceIndex, stemQN, category, stemXPos, stemYMin, stemXPos, stemYMax, lowestStaffLine, highestStaffLine, nil, chordRollType, choke})
        if #currentTiePosData > 0 then
          table.insert(currentTiePosData, 1, stemXPos)
          end
          
        --if previous event was a tie, draw the tie
        if #masterRecentTiePosDataBothVoices[voiceIndex] > 0 then
          local tieXMin = masterRecentTiePosDataBothVoices[voiceIndex][1]
          for x=2, #masterRecentTiePosDataBothVoices[voiceIndex] do
            local tieXMax = stemXPos
            local tieYPos = masterRecentTiePosDataBothVoices[voiceIndex][x]
            addToEventList({voiceIndex, stemQN, "tie", tieXMin, tieYPos, tieXMax, tieYPos})
            end
          end
          
        local function sortArticulationList()
          local list = {}
          for x=1, #VALID_ARTICULATION_LIST do
            local articulationData = VALID_ARTICULATION_LIST[x]
            local articulationName = articulationData[1]
            if isInTable(chordArticulationList, articulationName) then
              tableInsert(list, articulationData)
              end
            end
          return list
          end
        
        chordArticulationList = sortArticulationList()
        local yMin, yMax
        if voiceIndex == 2 then
          yMin = stemYMax + STAFFSPACEHEIGHT/2
        else
          yMax = stemYMin - STAFFSPACEHEIGHT/2
          end
          
        for x=0, #chordArticulationList-1 do
          local articulationData = chordArticulationList[x+1]
          
          local articulationName = articulationData[1]
          local sizeY = articulationData[2]
          
          local imgFileName = "articulation_" .. articulationName
          local img = getImageFromList(imgFileName)
          local imgSizeX, imgSizeY = getImageSize(imgFileName)
          local imgAspectRatio = imgSizeX/imgSizeY
          
          local xMin = stemXPos
          
          if voiceIndex == 2 then
            yMax = yMin + sizeY
          else
            yMin = yMax - sizeY
            end
          
          local scalingFactor = sizeY/imgSizeY
          local sizeX = imgSizeX*scalingFactor
          
          local xMax = xMin + sizeX
          
          xMin = xMin - sizeX/2
          xMax = xMax - sizeX/2
          
          addToEventList({voiceIndex, stemQN, "articulation", xMin, yMin, xMax, yMax, img, imgFileName})
          
          if voiceIndex == 2 then
            yMin = yMax + STAFFSPACEHEIGHT/3
          else
            yMax = yMin - STAFFSPACEHEIGHT/3
            end
          end

        if graceNoteID then
          for x=1, #chordNoteheadData do
            local data = chordNoteheadData[x]
            
            local img = data[1]
            local xMin = data[2]
            local yMin = data[3]
            local xMax = data[4]
            local yMax = data[5]
            local noteID = data[6]
            local chord = data[7]
            local chordNoteIndex = data[8]
            local graceQN = data[9]
            local isGhost = data[10]
            local imgFileName = data[11]
            
            addToMeasureChordList({voiceIndex, graceQN, "gracenotehead", xMin, yMin, xMax, yMax, noteID, img, imgFileName, chord, chordNoteIndex, isGhost})
            end
        else
          for x=1, #chordNoteheadData do
            local data = chordNoteheadData[x]
            
            local img = data[1]
            local xMin = data[2]
            local yMin = data[3]
            local xMax = data[4]
            local yMax = data[5]
            local noteID = data[6]
            local chord = data[7]
            local chordNoteIndex = data[8]
            local isSpaceAbove = data[9]
            local isGhost = data[10]
            local hasTie = data[11]
            local fakeChord = data[12]
            local imgFileName = data[13]
            
            addToMeasureChordList({voiceIndex, qnQuantized, "notehead", xMin, yMin, xMax, yMax, noteID, img, imgFileName, chord, chordNoteIndex, isGhost, hasDot, isSpaceAbove, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, hasTie, fakeChord})
            end
            
          --draw rhythm (flag and dot)
          local drawBeamState = chord[CHORDGLOBALDATAINDEX_DRAWBEAMSTATE]
          if not drawBeamState then
            local img = getImageFromList(flagLabel)
            local imgSizeX, imgSizeY = getImageSize(flagLabel)
            
            if imgSizeX then
              local imgAspectRatio = imgSizeX/imgSizeY
              
              local xMin = stemXPos
              
              local yMin, yMax
              
              local sizeY = getFlagYSize(flagLabel)
              if voiceIndex == 2 then
                yMin = stemYMax
                yMax = yMin - sizeY
              else
                yMin = stemYMin
                yMax = yMin + sizeY
                end
              
              local scalingFactor = sizeY/imgSizeY
              local sizeX = imgSizeX*scalingFactor
              local xMax = xMin + sizeX
              
              addToEventList({voiceIndex, qnQuantized, "flag", xMin, yMin, xMax, yMax, img, flagLabel})
              end
          else
            local function addToStemBeamTable(currentBeamValue, prevBeamValue, currentDrawBeamState)
              local stemListSubTable = stemList[#stemList]
              stemListSubTable[10] = {}
              local stemBeamTable = stemListSubTable[10]
              
              if currentDrawBeamState > DRAWBEAM_END then
                currentDrawBeamState = currentDrawBeamState - DRAWBEAM_END
                end
                
              local function addPerBeamValue(beamValue, beamCategory)
                local numBeams = getNumBeams(beamValue)
                for x=0, numBeams-1 do
                  local beamYMin, beamYMax
                  local yOffset = x*(BEAMSIZEY+BEAMSPACINGY)
                  if voiceIndex == 2 then
                    beamYMax = stemYMax - yOffset
                    beamYMin = beamYMax - BEAMSIZEY
                  else
                    beamYMin = stemYMin + yOffset
                    beamYMax = beamYMin + BEAMSIZEY
                    end
                  
                  tableInsert(stemBeamTable, {beamCategory, beamYMin, beamYMax})
                  end
                end
              
              if currentDrawBeamState == DRAWBEAM_FULLPREV then
                addPerBeamValue(prevBeamValue, "full")
              elseif currentDrawBeamState == DRAWBEAM_FULLCURRENT then
                addPerBeamValue(currentBeamValue, "full")
              elseif currentDrawBeamState == DRAWBEAM_STUBLEFT then
                addPerBeamValue(prevBeamValue, "full")
                addPerBeamValue(currentBeamValue, "stubleft")
              elseif currentDrawBeamState == DRAWBEAM_STUBRIGHT then
                addPerBeamValue(prevBeamValue, "stubright")
                addPerBeamValue(currentBeamValue, "full")
              elseif currentDrawBeamState == DRAWBEAM_SECONDARY then
                addPerBeamValue(8, "full")
              elseif currentDrawBeamState == DRAWBEAM_STUBLEFTSECONDARY then
                addPerBeamValue(8, "full")
                addPerBeamValue(currentBeamValue, "stubleft")
              elseif currentDrawBeamState == DRAWBEAM_STUBRIGHTSECONDARY then
                addPerBeamValue(prevBeamValue, "stubright")
                addPerBeamValue(8, "full")
              elseif currentDrawBeamState == DRAWBEAM_STUBRIGHTLEFTSECONDARY then
                addPerBeamValue(prevBeamValue, "stubright")
                addPerBeamValue(currentBeamValue, "stubleft")
                addPerBeamValue(8, "full")
                end
              end
              
            --draw beam
            local currentBeamValue = tonumber(string.sub(flagLabel, 6, #flagLabel))
            addToStemBeamTable(currentBeamValue, masterRecentBeamValueBothVoices[voiceIndex], drawBeamState)
            if drawBeamState > DRAWBEAM_END then
              masterRecentBeamValueBothVoices[voiceIndex] = nil
            else
              masterRecentBeamValueBothVoices[voiceIndex] = currentBeamValue
              end
            end
          end
        end
      
      processChord(chord)
      if graceChordList then
        for x=1, #graceChordList do
          local graceChord = graceChordList[x]
          local graceQN = roundFloatingPoint(qnQuantized - (GRACEQNDIFF*(#graceChordList-x + 1) ) )
          processChord(graceChord, graceQN, x)
          end
        end
      end
      
    local function storeVoiceInEventList(voiceIndex, isSingularVoice)
      if voiceIndex == 1 and not isSingularVoice then
        addToXML("      <backup>")
        addToXML("        <duration>" .. xmlDivisionsPerMeasure .. "</duration>")
        addToXML("      </backup>")
        addToXML()
        end
        
      local rhythmList = masterRhythmListBothVoices[voiceIndex][measureIndex]
      if #rhythmList == 0 then
        return true
        end
      
      local slurOrientation
      if voiceIndex == 1 then
        slurOrientation = "under"
        end
      if voiceIndex == 2 then
        slurOrientation = "over"
        end 
      
      local totalXmlDurationCheck = 0
      
      for x=1, #rhythmList do
        local rhythmData = rhythmList[x]
        
        local rhythmNum = rhythmData[RHYTHMLISTINDEX_NUM]
        local rhythmDenom = rhythmData[RHYTHMLISTINDEX_DENOM]
        local tupletFactorNum = rhythmData[RHYTHMLISTINDEX_TUPLETFACTORNUM]
        local tupletFactorDenom = rhythmData[RHYTHMLISTINDEX_TUPLETFACTORDENOM]
        local qnQuantized = rhythmData[RHYTHMLISTINDEX_QN]
        local chord = rhythmData[RHYTHMLISTINDEX_CHORD]
        local graceChordList = rhythmData[RHYTHMLISTINDEX_GRACECHORDLIST]
        local label = rhythmData[RHYTHMLISTINDEX_LABEL]
        local tupletModifier = rhythmData[RHYTHMLISTINDEX_TUPLETMODIFIER]
        local hasDot = rhythmData[RHYTHMLISTINDEX_HASDOT]
        local beamXmlData = rhythmData[RHYTHMLISTINDEX_BEAMXMLDATA]
        local tupletXmlData = rhythmData[RHYTHMLISTINDEX_TUPLETXMLDATA]
        local timeModificationXmlData = rhythmData[RHYTHMLISTINDEX_TIMEMODIFICATIONXMLDATA]
        local isRhythmOverride = rhythmData[RHYTHMLISTINDEX_ISRHYTHMOVERRIDE]
        local currentRhythmWithoutTuplets = rhythmData[RHYTHMLISTINDEX_CURRENTRHYTHMWITHOUTTUPLETS]
        local maxRhythmWithoutTuplets = rhythmData[RHYTHMLISTINDEX_MAXRHYTHMWITHOUTTUPLETS]
        local minBeat = rhythmData[RHYTHMLISTINDEX_MINBEAT]
        local maxBeat = rhythmData[RHYTHMLISTINDEX_MAXBEAT]
        local hasTie = rhythmData[RHYTHMLISTINDEX_STARTTIE]
        local fakeChord = rhythmData[RHYTHMLISTINDEX_FAKECHORD]
        local choke = rhythmData[RHYTHMLISTINDEX_CHOKE]
        
        currentTiePosData = {}
        
        local xmlRhythmType = getXmlRhythmType(rhythmDenom)
        local xmlDuration = getXmlDuration(rhythmData)
        totalXmlDurationCheck = round(totalXmlDurationCheck + xmlDuration)

        local function addXmlTupletTimeModificationData()
          if timeModificationXmlData then
            local actualNotes = timeModificationXmlData[1]
            local normalNotes = timeModificationXmlData[2]
            local normalType = timeModificationXmlData[3]

            addToXML("        <time-modification>")
            addToXML("          <actual-notes>" .. actualNotes .. "</actual-notes>")
            addToXML("          <normal-notes>" .. normalNotes .. "</normal-notes>")
            addToXML("          <normal-type>" .. getXmlRhythmType(normalType) .. "</normal-type>")
            addToXML("        </time-modification>")
            end
          end
        
        local function addXmlTupletStartStopData()
          if #tupletXmlData > 0 then
            for tupletID=1, #tupletXmlData do
              local data = tupletXmlData[tupletID]
              
              local xmlTupletState = data[1] --start, stop, nil
              local xmlTupletNum = data[2]
              local showColon = data[3]
              
              local xmlShowNumber
              if showColon then
                xmlShowNumber = "both"
              else
                --xmlShowNumber = "actual"
                xmlShowNumber = "both"
                end
              if xmlTupletState then
                addToXML("          <tuplet type=\"" .. xmlTupletState .. "\" bracket=\"yes\" number=\"" .. xmlTupletNum .. "\" show-number=\"" .. xmlShowNumber .. "\"/>")
                end
              end
            end
          end
          
        --check for total xml duration rounding error
        if x == #rhythmList then
          local offset = round(xmlDivisionsPerMeasure - totalXmlDurationCheck)
          xmlDuration = round(xmlDuration + offset)
          end
          
        if chord then
          storeChordInEventList(qnQuantized, chord, graceChordList, label, tupletModifier, hasDot, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, hasTie, fakeChord, choke, voiceIndex)
          
          --grace note XML
          local multipleGraceNotes
          if graceChordList then
            multipleGraceNotes = (#graceChordList > 1)
            local graceXmlRhythmType
            if multipleGraceNotes then graceXmlRhythmType = getXmlRhythmType(16) else graceXmlRhythmType = getXmlRhythmType(8) end
            
            for graceChordIndex=1, #graceChordList do
              local chord = graceChordList[graceChordIndex]
              local chordGlobalData = chord[1]
              local chordNotes = chord[2]
              for noteIndex=1, #chordNotes do
                local noteData = chordNotes[noteIndex]
                
                addToXML("      <note>")
                if noteIndex > 1 then
                  addToXML("        <chord/>")
                  end
                addToXML("        <grace/>")
                addNoteAttributesToXML(noteData)
                addToXML("        <type>" .. graceXmlRhythmType .. "</type>")
                addToXML("        <notations>")
                
                if graceChordIndex == 1 and noteIndex == 1 then
                  xmlSlurNumber = xmlSlurNumber + 1
                  addToXML("          <slur type=\"start\" orientation=\"" .. slurOrientation .. "\" number=\"" .. xmlSlurNumber .. "\"/>")
                  end
                  
                addToXML("        </notations>")
                addToXML("      </note>")
                addToXML()
                end
              end
            end
            
          --note XML
          local chordGlobalData = chord[1]
          local chordNotes = chord[2]
          for noteIndex=1, #chordNotes do
            local noteData = chordNotes[noteIndex]
          
            addToXML("      <note>")
            if noteIndex > 1 then
              addToXML("        <chord/>")
              end
            addNoteAttributesToXML(noteData)
            addToXML("        <type>" .. xmlRhythmType .. "</type>")
            if hasDot then
              addToXML("        <dot/>")
              end
            addToXML("        <duration>" .. xmlDuration .. "</duration>")
            
            if beamXmlData then
              for beamNum=1, #beamXmlData do
                local state = beamXmlData[beamNum]
                addToXML("        <beam number=\"" .. beamNum .. "\">" .. state .. "</beam>")
                end
              end
              
            addXmlTupletTimeModificationData()
              
            addToXML("        <notations>")
            if multipleGraceNotes and noteIndex == 1 then
              addToXML("          <slur type=\"end\" orientation=\"" .. slurOrientation .. "\" number=\"" .. xmlSlurNumber .. "\"/>")
              xmlSlurNumber = xmlSlurNumber - 1
              end
            addXmlTupletStartStopData()
            addToXML("        </notations>")
            
            addToXML("      </note>")
            addToXML()
            end
        else
          storeRestInEventList(qnQuantized, label, tupletModifier, hasDot, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, voiceIndex, isSingularVoice)
          
          --rest XML
          addToXML("      <note>")
          addToXML("        <rest/>")
          addToXML("        <voice>" .. voiceIndex .. "</voice>")
          addToXML("        <type>" .. xmlRhythmType .. "</type>")
          if hasDot then
            addToXML("        <dot/>")
            end
          addToXML("        <duration>" .. xmlDuration .. "</duration>")
          
          addXmlTupletTimeModificationData()
          
          addToXML("        <notations>")
          addXmlTupletStartStopData()
          addToXML("        </notations>")
          
          addToXML("      </note>")
          addToXML()
          end
        
        masterRecentTiePosDataBothVoices[voiceIndex] = {}
        for x=1, #currentTiePosData do
          tableInsert(masterRecentTiePosDataBothVoices[voiceIndex], currentTiePosData[x])
          end
        end
      
      --add tuplets to event list
      local measureTupletList = measureList[measureIndex][MEASURELISTINDEX_TUPLETLIST][voiceIndex]
      local maxTupletLevel = 0
      for x=1, #measureTupletList do
        local data = measureTupletList[x]
        local tupletLevel = data[9]
        maxTupletLevel = math.max(tupletLevel, maxTupletLevel)
        end
        
      for x=1, #measureTupletList do
        local data = measureTupletList[x]
        
        local tupletNum = data[6]
        local tupletDenom = data[7]
        local showColon = data[8]
        local tupletLevel = data[9]
        local newTupletStartQN = data[10]
        local newTupletEndQN = data[11]
        
        local bracketYPoint, bracketYLong
        if voiceIndex == 1 then
          bracketYPoint = getStaffLinePosition(STEMYPOS_VOICE1) - ((maxTupletLevel-tupletLevel)+1)*TUPLETLEVELSIZEY + STAFFSPACEHEIGHT/2
          bracketYLong = bracketYPoint - STAFFSPACEHEIGHT
        else
          bracketYPoint = getStaffLinePosition(STEMYPOS_VOICE2) + ((maxTupletLevel-tupletLevel)+1)*TUPLETLEVELSIZEY - STAFFSPACEHEIGHT/2
          bracketYLong = bracketYPoint + STAFFSPACEHEIGHT
          end
        
        local bracketXMin = getQNXPos(newTupletStartQN)
        local bracketXMax = getQNXPos(newTupletEndQN)
        
        local imgData = getTupletImagesAndBoundaries(tupletNum, tupletDenom, showColon)
        
        local inProgressTupletIndex = x
        if voiceIndex == 2 then
          inProgressTupletIndex = -x
          end
          
        addToEventList({voiceIndex, newTupletStartQN, "tuplet_start_" .. inProgressTupletIndex, bracketXMin, bracketYPoint, bracketXMin, bracketYLong})
        addToEventList({voiceIndex, newTupletEndQN, "tuplet_end_" .. inProgressTupletIndex, bracketXMax, bracketYPoint, bracketXMax, bracketYLong, imgData})
        end
      end
    
    local function storeSystemItemsInEventList()
      local tempoIndex = findIndexInListEqualOrGreaterThan(tempoTextEvtList, qnStart, TEMPOLISTINDEX_QN)
      if tempoIndex then
        for x=tempoIndex, #tempoTextEvtList do
          local tempoData = tempoTextEvtList[x]
          local qn = tempoData[TEMPOLISTINDEX_QN]
          if qn >= qnEnd then
            break
            end

          local bpmBasis = tempoData[TEMPOLISTINDEX_BPMBASIS]
          local bpm = tempoData[TEMPOLISTINDEX_BPM]
          local performanceDirection = tempoData[TEMPOLISTINDEX_PERFORMANCEDIRECTION]
          
          --TODO: performanceDirection
          
          if x > 1 then
            local prevTempoData = tempoTextEvtList[x-1]
            if prevTempoData[TEMPOLISTINDEX_BPMBASIS] == bpmBasis and prevTempoData[TEMPOLISTINDEX_BPM] == bpm then
              bpmBasis = nil
              bpm = nil
              end
            end
            
          local imgData, imgFileName, hasDot = getTempoImagesAndBoundaries(bpmBasis, bpm, performanceDirection)
          
          local xMin = getQNXPos(qn, true)
          
          addToEventList({nil, qn, "tempo", xMin, imgData, imgFileName, hasDot, bpmBasis, bpm, performanceDirection})
          end
        end
      
      local dynamicsIndex = findIndexInListEqualOrGreaterThan(dynamicList, qnStart, DYNAMICLISTINDEX_STARTQN)
      if dynamicsIndex then
        for x=dynamicsIndex, #dynamicList do
          local dynamicsData = dynamicList[x]
          local qn = dynamicsData[DYNAMICLISTINDEX_STARTQN]
          if qn >= qnEnd then
            break
            end
      
          local dynamic = dynamicsData[DYNAMICLISTINDEX_TYPE]
          if not dynamic then
            local ppqpos = dynamicsData[DYNAMICLISTINDEX_STARTPPQPOS]
            throwError("No dynamic attached to note! ", nil, reaper.MIDI_GetProjTimeFromPPQPos(drumTake, ppqpos))
            end
          
          local xPos = getQNXPos(qn, true)
          local startPPQPOS = dynamicsData[DYNAMICLISTINDEX_STARTPPQPOS]
          
          if isGradualDynamic(dynamic) then
            if currentGradualDynamicXMin then
              local prevDynamicsData = dynamicList[x-1]
              local prevStartPPQPOS = prevDynamicsData[DYNAMICLISTINDEX_STARTPPQPOS]
              local prevEndPPQPOS = prevDynamicsData[DYNAMICLISTINDEX_ENDPPQPOS]
              local prevStartQN = prevDynamicsData[DYNAMICLISTINDEX_STARTQN]
              local prevEndQN = prevDynamicsData[DYNAMICLISTINDEX_ENDQN]
              local prevDynamic = prevDynamicsData[DYNAMICLISTINDEX_TYPE]
              
              addToEventList({nil, prevStartQN, "dynamic_hairpin", currentGradualDynamicXMin, DYNAMICCENTERY-DYNAMICSIZEY/2, xPos, DYNAMICCENTERY+DYNAMICSIZEY/2, DYNAMICCENTERY, prevStartPPQPOS, prevEndPPQPOS, 0, prevDynamic})
              currentGradualDynamicXMin = nil
            else
              currentGradualDynamicXMin = xPos
              end
            
            addToEventList({nil, qn, "dynamic_hairpin_game", xPos, DYNAMICCENTERY, xPos, DYNAMICCENTERY, dynamic})
          else
            local sizeX, yMin, yMax, img, imgFileName = getDynamicImageData(dynamic)
            addToEventList({nil, qn, "dynamic_sprite", xPos, yMin, xPos+sizeX, yMax, nil, startPPQPOS, 0, img, imgFileName})
            end
          end
        end
      
      local staffTextIndex = findIndexInListEqualOrGreaterThan(staffTextList, qnStart, STAFFTEXTLISTINDEX_QN)
      if staffTextIndex then
        for x=staffTextIndex, #staffTextList do
          local staffTextData = staffTextList[x]
          local qn = staffTextData[STAFFTEXTLISTINDEX_QN]
          if qn >= qnEnd then
            break
            end
      
          local xPos = getQNXPos(qn, true)
          local yPos = getStaffLinePosition(MAXSTAFFLINE-2)

          addToEventList({nil, qn, "staffText", xPos, yPos, xPos, yPos, x})
          end
        end
      end
    
    ----drawNotes()----
    
    local emptyVoice2 = storeVoiceInEventList(2)
    local emptyVoice1 = storeVoiceInEventList(1, emptyVoice2)
          
    if not emptyVoice1 or not emptyVoice2 then
      stopMultiMeasure = true
      end
    
    if stopMultiMeasure then
      local beginningMeasureQN
      if not uploadedGameData then
        local beginningMeasureIndex = measureIndex - currentNumEmptyMeasures
        beginningMeasureQN = measureList[beginningMeasureIndex][MEASURELISTINDEX_QN]
        end
        
      if currentNumEmptyMeasures > 1 then
        local prevMeasureBoundXMin = currentMeasureLineData[8]
        local prevMeasureBoundXMax = currentMeasureLineData[9]
        local numberData = getNumberImagesAndBoundaries(currentNumEmptyMeasures)
        
        local xMin = prevMeasureBoundXMin
        local xMax = prevMeasureBoundXMax-MEASURESTARTSPACING
        
        local centerY = getStaffLinePosition(0)
        local yMin = getStaffLinePosition(-1)
        local yMax = getStaffLinePosition(1)
        local endGap = STAFFSPACEHEIGHT/4
        
        local rectYMin = centerY-STAFFSPACEHEIGHT/3
        local rectYMax = centerY+STAFFSPACEHEIGHT/3
        addToNotationDrawList({"multirest_rect", xMin, xMax, rectYMin, rectYMax})
        addToGameData("notation", {"multirest_rect", nil, nil, xMin, rectYMin, xMax, rectYMax, beginningMeasureStartTime})
        
        addToNotationDrawList({"multirest_line", xMin, xMin, yMin, yMax})
        addToGameData("notation", {"multirest_line", qnToTimeFromTempoMap(beginningMeasureQN), nil, xMin, yMin, xMin, yMax})
        addToNotationDrawList({"multirest_line", xMax, xMax, yMin, yMax})
        addToGameData("notation", {"multirest_line", nil, nil, xMax, yMin, xMax, yMax})
        
        local centerX = (xMin + xMax) / 2
        local numberXLen = numberData[#numberData][4]
        local numberXMin = centerX - numberXLen/2
        local numberYMin = getStaffLinePosition(5)
        for x=1, #numberData do
          local imgValues = numberData[x]
          
          local img = imgValues[1]
          local xMin = imgValues[2] + numberXMin
          local yMin = imgValues[3] + numberYMin
          local xMax = imgValues[4] + numberXMin
          local yMax = imgValues[5] + numberYMin
          local imgFileName = imgValues[6]
          
          addToNotationDrawList({"multirest_number", xMin, xMax, yMin, yMax, img})
          addToGameData("notation", {"multirest_number", nil, imgFileName, xMin, yMin, xMax, yMax})
          end
          
        if not gettingCurrentValues then
          for x=1, currentNumEmptyMeasures do
            measureList[measureIndex-x][MEASURELISTINDEX_MULTIREST] = true
            end
          end
      elseif currentNumEmptyMeasures == 1 then
        local prevMeasureBoundXMin = currentMeasureLineData[8]
        local prevMeasureBoundXMax = currentMeasureLineData[9]
        
        local voiceIndex = 1
        
        local img = getImageFromList("rest_1")
        local imgSizeX, imgSizeY = getImageSize("rest_1")
        local imgAspectRatio = imgSizeX/imgSizeY
        
        local yMin = getStaffLinePosition(1)
        local yMax = getStaffLinePosition(0, true)
        
        local sizeY = yMax - yMin
        local scalingFactor = sizeY/imgSizeY
        local sizeX = imgSizeX*scalingFactor
        
        local measureXLen = prevMeasureBoundXMax - prevMeasureBoundXMin
        local measureCenterX = prevMeasureBoundXMin + measureXLen/2
        local xMin = measureCenterX - sizeX/2
        local xMax = measureCenterX + sizeX/2
        if not emptyVoice2 then
          yMin = yMin + STAFFSPACEHEIGHT/2
          yMax = yMax + STAFFSPACEHEIGHT/2
          end
        
        addToNotationDrawList({"wholeRest", xMin, xMax, yMin, yMax, img, voiceIndex, emptyVoice2})
        addToGameData("notation", {"wholerest", nil, "rest_1", xMin, yMin, xMax, yMax, beginningMeasureStartTime})
        end
      currentNumEmptyMeasures = 0
      end
    
    if emptyVoice1 and emptyVoice2 then
      currentNumEmptyMeasures = currentNumEmptyMeasures + 1
      end
    
    if currentNumEmptyMeasures >= 2 then
      local prevMeasureBoundXMin = currentMeasureLineData[8]
      local prevMeasureBoundXMax = currentMeasureLineData[9]
      measureBoundXMin = prevMeasureBoundXMin
      measureBoundXMax = prevMeasureBoundXMax
    else
      drawPreviousMeasureLine(measureIndex)
      end
    
    for x=1, #measureChordList do
      local masterChordData = measureChordList[x]
      
      table.sort(masterChordData, function(a, b) --sort by yMax (or yMin)
        return a[7] < b[7]
        end)
      
      local masterXMin = math.huge
      local masterXMax = -math.huge
      
      --looping from lowest note to highest note
      for y=#masterChordData, 1, -1 do
        local data = masterChordData[y]

        local voiceIndex = data[1]
        local qn = data[2]
        local category = data[3]
        local xMin = data[4]
        local yMin = data[5]
        local xMax = data[6]
        local yMax = data[7]
        local noteID = data[8]
        local img = data[9]
        local imgFileName = data[10]
        local chord = data[11]
        local chordNoteIndex = data[12]
        local isGhost = data[13]
        local hasDot = data[14]
        local isSpaceAbove = data[15]
        local isRhythmOverride = data[16]
        local currentRhythmWithoutTuplets = data[17]
        local maxRhythmWithoutTuplets = data[18]
        local minBeat = data[19]
        local maxBeat = data[20]
        local tupletFactorNum = data[21]
        local tupletFactorDenom = data[22]
        local beatTable = data[23]
        local timeSigNum = data[24]
        local timeSigDenom = data[25]
        local hasTie = data[26]
        local fakeChord = data[27]
        
        local sizeX = xMax - xMin
        
        if y < #masterChordData then
          local prevData = masterChordData[y+1]
          
          local prevXMin = prevData[4]
          local prevYMin = prevData[5]
          local prevXMax = prevData[6]
          local prevYMax = prevData[7]
          
          if xMax == prevXMax and roundFloatingPoint(prevYMax - yMax) == roundFloatingPoint(STAFFSPACEHEIGHT/2) then--stagger 2nds
            data[4] = data[4] + sizeX
            data[6] = data[6] + sizeX
            end
          end
        
        if hasDot then
          local dotCenterX = xMax + DOTSPACING
          local dotCenterY = yMin + (yMax-yMin)/2
          if not isSpaceAbove then
            dotCenterY = dotCenterY - STAFFSPACEHEIGHT/2
            end
          local dotXMin = dotCenterX - DOTRADIUS
          local dotYMin = dotCenterY - DOTRADIUS
          local dotXMax = dotCenterX + DOTRADIUS
          local dotYMax = dotCenterY + DOTRADIUS
          
          masterXMax = math.max(masterXMax, dotXMax)
          end

        masterXMin = math.min(masterXMin, data[4])
        masterXMax = math.max(masterXMax, data[6])
        end
      
      for y=1, #masterChordData do
        local data = masterChordData[y]
      
        local voiceIndex = data[1]
        local qn = data[2]
        local category = data[3]
        local xMin = data[4]
        local yMin = data[5]
        local xMax = data[6]
        local yMax = data[7]
        local noteID = data[8]
        local img = data[9]
        local imgFileName = data[10]
        local chord = data[11]
        local chordNoteIndex = data[12]
        local isGhost = data[13]
        local hasDot = data[14]
        local isSpaceAbove = data[15]
        local isRhythmOverride = data[16]
        local currentRhythmWithoutTuplets = data[17]
        local maxRhythmWithoutTuplets = data[18]
        local minBeat = data[19]
        local maxBeat = data[20]
        local tupletFactorNum = data[21]
        local tupletFactorDenom = data[22]
        local beatTable = data[23]
        local timeSigNum = data[24]
        local timeSigDenom = data[25]
        local hasTie = data[26]
        local fakeChord = data[27]
        
        addToEventList(data)
        
        if hasDot then
          local dotCenterX = xMax + DOTSPACING
          local dotCenterY = yMin + (yMax-yMin)/2
          if not isSpaceAbove then
            dotCenterY = dotCenterY - STAFFSPACEHEIGHT/2
            end
          local dotXMax = masterXMax
          local dotXMin = dotXMax - DOTRADIUS*2
          local dotYMin = dotCenterY - DOTRADIUS
          local dotYMax = dotCenterY + DOTRADIUS
          
          addToEventList({voiceIndex, qn, "dot", dotXMin, dotYMin, dotXMax, dotYMax})
          end
        
        if isGhost then
          local img = getImageFromList("ghost_left")
          local imgSizeX, imgSizeY = getImageSize("ghost_left")
          local imgAspectRatio = imgSizeX/imgSizeY
          
          local ghostLeftXMin = masterXMin - GHOSTSPACING
          local ghostRightXMax = masterXMax + GHOSTSPACING
          
          local ghostYMin = yMin - STAFFSPACEHEIGHT/4
          local ghostYMax = yMax + STAFFSPACEHEIGHT/4
          
          local sizeY = ghostYMax - ghostYMin
          local scalingFactor = sizeY/imgSizeY
          local sizeX = imgSizeX*scalingFactor
          local ghostLeftXMax = ghostLeftXMin + sizeX
          local ghostRightXMin = ghostRightXMax - sizeX
          
          addToEventList({voiceIndex, qn, "ghostleft", ghostLeftXMin, ghostYMin, ghostLeftXMax, ghostYMax, img})
          addToEventList({voiceIndex, qn, "ghostright", ghostRightXMin, ghostYMin, ghostRightXMax, ghostYMax, img})
          end
        end
      end

    for x=1, #stemList do
      local data = stemList[x]
      addToEventList(data)
      end
    
    storeSystemItemsInEventList()
    
    local flooredCurrentBeat
    if currentBeat then
      flooredCurrentBeat = floor(currentBeat)
      end
    local validCurrentMeasure = true
    for beatNum=0, timeSigNum-1 do
      local data = beatTable[beatNum+1]
      local beatQN = data[1]
      local isStrongBeat = data[2]
      
      local textCenterX = getQNXPos(beatQN, false)
      
      if beatNum == 0 then
        if prevTextCenterX == textCenterX then
          validCurrentMeasure = false
        else
          prevTextCenterX = textCenterX
          if not gettingCurrentValues then
            tableInsert(validBeatMeasureList, measureIndex)
            end
          end
        end
        
      if validCurrentMeasure then
        addToEventList({nil, beatQN, "beat_number", textCenterX, beatNum, isStrongBeat, measureIndex, flooredCurrentBeat})
        end
      end
    
    local function neatenEvents()
      local currentBeatQN, currentBeatXPos
      if isActiveMeasure then
        currentBeatQN = convertRange(currentBeat, flooredCurrentBeat, flooredCurrentBeat+1, beatTable[flooredCurrentBeat+1][1], beatTable[flooredCurrentBeat+2][1])
        currentBeatXPos = getQNXPos(currentBeatQN, true)
        end
    
      for x=1, #qnEventList do
        local dataInQuantizedQN = qnEventList[x]
        
        local lowestXMin_upperVoice = math.huge
        local lowestXMin_lowerVoice = math.huge
        local highestXMax_upperVoice = -math.huge
        local highestXMax_lowerVoice = -math.huge
        
        for y=1, #dataInQuantizedQN do
          local data = dataInQuantizedQN[y]
          local voiceIndex = data[1]
          local category = data[3]
          if category ~= "tempo" and string.sub(category, 1, 8) ~= "dynamic_" and category ~= "staffText" and category ~= "articulation" and category ~= "tie" and string.sub(category, 1, 7) ~= "tuplet_" and string.sub(category, 1, 5) ~= "beat_" then
            local xMin = data[4]
            local xMax = data[6]
            if not voiceIndex then
              throwError("No voice index! " .. category)
              end
            if voiceIndex == 1 then
              lowestXMin_upperVoice = math.min(xMin, lowestXMin_upperVoice)
              highestXMax_upperVoice = math.max(xMax, highestXMax_upperVoice)
            else
              lowestXMin_lowerVoice = math.min(xMin, lowestXMin_lowerVoice)
              highestXMax_lowerVoice = math.max(xMax, highestXMax_lowerVoice)
              end
            end
          end
        
        local function setToNilIfDefault(val, defaultVal)
          if val == defaultVal then
            return nil
            end
          return val
          end
        
        lowestXMin_upperVoice = setToNilIfDefault(lowestXMin_upperVoice, math.huge)
        lowestXMin_lowerVoice = setToNilIfDefault(lowestXMin_lowerVoice, math.huge)
        highestXMax_upperVoice = setToNilIfDefault(highestXMax_upperVoice, -math.huge)
        highestXMax_lowerVoice = setToNilIfDefault(highestXMax_lowerVoice, -math.huge)
        
        tableInsert(dataInQuantizedQN, {lowestXMin_upperVoice, highestXMax_upperVoice, lowestXMin_lowerVoice, highestXMax_lowerVoice})
        end
        
      local function moveEventsInVoiceToMinimumGap(voiceIndex)
        local min_measure_x_gap = 10000
        
        for x=#qnEventList, 1, -1 do
          local laterDataInQuantizedQN = qnEventList[x]
          local lowestCurrentXMin, highestEarlierXMax
          
          if voiceIndex == 1 then
            lowestCurrentXMin = laterDataInQuantizedQN[#laterDataInQuantizedQN][1]
          else
            lowestCurrentXMin = laterDataInQuantizedQN[#laterDataInQuantizedQN][3]
            end
          
          if lowestCurrentXMin then
            local earlierIndex = x-1
            while highestEarlierXMax == nil do
              if earlierIndex < 1 then
                local measureSpaceGap = measureBoundXMin - 10
                highestEarlierXMax = measureSpaceGap
              else
                local earlierDataInQuantizedQN = qnEventList[earlierIndex]
                if voiceIndex == 1 then
                  highestEarlierXMax = earlierDataInQuantizedQN[#earlierDataInQuantizedQN][2]
                else
                  highestEarlierXMax = earlierDataInQuantizedQN[#earlierDataInQuantizedQN][4]
                  end
                end
              earlierIndex = earlierIndex - 1
              end
              
            local xGap = lowestCurrentXMin - highestEarlierXMax

            if x > 1 then --2 and up because the first event is a very small gap???
              min_measure_x_gap = math.min(min_measure_x_gap, xGap)
              if not uploadedGameData and measureIndex == 4 then
                --reaper.ShowConsoleMsg(measureIndex .. " " .. xGap .. "\n")
                end
              end
                
            if xGap < MIN_NOTATION_X_GAP then
              local xIncrease = MIN_NOTATION_X_GAP - xGap
              measureBoundXMax = measureBoundXMax + xIncrease
              if currentBeatQN and currentBeatQN >= qnEventList[x][1][2] then
                currentBeatXPos = currentBeatXPos + xIncrease
                end
              for y=x, #qnEventList do
                local dataInQuantizedQN = qnEventList[y]
                for z=1, #dataInQuantizedQN-1 do
                  local data = dataInQuantizedQN[z]
                  local category = data[3]
                  data[4] = data[4] + xIncrease --xMin
                  if category ~= "tempo" and string.sub(category, 1, 5) ~= "beat_" then
                    data[6] = data[6] + xIncrease --xMax
                    end
                  end
                end
              end
            end
          end
        
        min_measure_x_gap = math.max(min_measure_x_gap, MIN_NOTATION_X_GAP)
        
        if not uploadedGameData then
          --reaper.ShowConsoleMsg("FINAL: " .. measureIndex .. " " .. min_measure_x_gap .. "\n")
          end
          
        --TODO: store minimum gap in both voices AS A PROPORTION of the MIN_NOTATION_X_GAP in Lua,
        --then after justification attempt, if that proportion goes below 1, then justification fails
        return min_measure_x_gap
        end
      local min_measure_x_gap_voice1 = moveEventsInVoiceToMinimumGap(1)
      local min_measure_x_gap_voice2 = moveEventsInVoiceToMinimumGap(2)
      
      addToGameData("notation", {"gaps", min_measure_x_gap_voice1/MIN_NOTATION_X_GAP, min_measure_x_gap_voice2/MIN_NOTATION_X_GAP})
      
      if currentBeatXPos then
        currentMeasureData_qnEnd = qnEnd
        currentMeasureData_flooredCurrentBeat = flooredCurrentBeat
        currentMeasureData_cursorXPos = currentBeatXPos
        end
      end
    
    neatenEvents()
    
    --store components to draw into notation draw list
    
    local prevGraceNoteQNVoice1, prevGraceNoteQNVoice2, prevGraceNoteXPosVoice1, prevGraceNoteXPosVoice2
    local inProgressTupletList = {}
    
    for x=1, #qnEventList do
      local dataInQuantizedQN = qnEventList[x]
      
      for y=1, #dataInQuantizedQN-1 do
        local data = dataInQuantizedQN[y]
        
        local voiceIndex = data[1]
        local qnQuantized = data[2]
        local category = data[3]
        local xMin = data[4]
        local yMin = data[5]
        local xMax = data[6]
        local yMax = data[7]
        
        if category == "tempo" then
          local imgData = data[5]
          addToNotationDrawList({"tempo", xMin, imgData})
          local imgFileName = data[6]
          local hasDot = data[7]
          local bpmBasis = data[8]
          local bpm = data[9]
          local performanceDirection = data[10]
          local values = {"tempo", nil, nil, xMin, -1, xMin, -1}
          if bpm then
            if hasDot then
              imgFileName = imgFileName .. "d"
              end
            tableInsert(values, "bpm=" .. imgFileName .. "," .. bpm)
            end
          if performanceDirection then
            tableInsert(values, "\"direction=" .. performanceDirection .. "\"")
            end
          addToGameData("notation", values)
          end
        if category == "dynamic_sprite" then
          local centerY = data[8]
          local startPPQPOS = data[9]
          local offset = data[10]
          local img = data[11]
          local imgFileName = data[12]
          addToNotationDrawList({"dynamic", xMin, xMax, yMin, yMax, centerY, startPPQPOS, offset, img})
          local xMin = xMin - STAFFSPACEHEIGHT --TODO: get rid of this math in notationDrawList function
          local xMax = xMax - STAFFSPACEHEIGHT
          addToGameData("notation", {"dynamic_sprite", nil, imgFileName, xMin, yMin, xMax, yMax})
          end
        if category == "dynamic_hairpin_game" then
          local dynamicType = data[8]
          addToGameData("notation", {"dynamic_hairpin", nil, nil, xMin, yMin, xMax, yMax, dynamicType})
          end
        if category == "dynamic_hairpin" then
          local centerY = data[8]
          local startPPQPOS = data[9]
          local endPPQPOS = data[10]
          local offset = data[11]
          local dynamic = data[12]
          addToNotationDrawList({"dynamic", xMin, xMax, yMin, yMax, centerY, startPPQPOS, offset, dynamic})
          end
        if category == "staffText" then
          local staffTextListIndex = data[8]
          addToNotationDrawList({"staffText", xMin, xMax, yMin, yMax, staffTextListIndex})
          local staffTextData = staffTextList[staffTextListIndex]
          local text = staffTextData[STAFFTEXTLISTINDEX_TEXT]
          addToGameData("notation", {"staff_text", nil, nil, xMin, yMin, xMin, yMin, "\"" .. text .. "\""})
          end
        if category == "beat_number" then
          local textCenterX = data[4]
          local beatNum = data[5]
          local isStrongBeat = data[6]
          local measureIndex = data[7]
          local flooredCurrentBeat = data[8]
          addToNotationDrawList({"beatNumber", textCenterX, textCenterX, beatNum, isStrongBeat, measureIndex, flooredCurrentBeat})
          end
        if category == "notehead" then
          local noteID = data[8]
          local img = data[9]
          local imgFileName = data[10]
          local chord = data[11]
          local chordNoteIndex = data[12]
          local isRhythmOverride = data[16]
          local currentRhythmWithoutTuplets = data[17]
          local maxRhythmWithoutTuplets = data[18]
          local minBeat = data[19]
          local maxBeat = data[20]
          local tupletFactorNum = data[21]
          local tupletFactorDenom = data[22]
          local beatTable = data[23]
          local timeSigNum = data[24]
          local timeSigDenom = data[25]
          local hasTie = data[26]
          local fakeChord = data[27]
          addToNotationDrawList({category, xMin, xMax, yMin, yMax, img, chord, chordNoteIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, fakeChord})
          local hasTieInt
          if hasTie then hasTieInt = 1 else hasTieInt = 0 end
          addToGameData("notation", {"notehead", qnToTimeFromTempoMap(qnQuantized), imgFileName, xMin, yMin, xMax, yMax, voiceIndex .. hasTieInt .. noteID})
          end
        if category == "gracenotehead" then
          local noteID = data[8]
          local img = data[9]
          local imgFileName = data[10]
          local chord = data[11]
          local chordNoteIndex = data[12]
          addToNotationDrawList({category, xMin, xMax, yMin, yMax, img, chord, chordNoteIndex})
          local hasTieInt = 0
          addToGameData("notation", {"notehead", qnToTimeFromTempoMap(qnQuantized), imgFileName, xMin, yMin, xMax, yMax, voiceIndex .. hasTieInt .. noteID})
          end
        if category == "flag" then
          local img = data[8]
          local imgFileName = data[9]
          addToNotationDrawList({category, xMin, xMax, yMin, yMax, img})
          addToGameData("notation", {"flag", nil, imgFileName, xMin, yMin, xMax, yMax})
          end
        if category == "rest" then
          local img = data[8]
          local imgFileName = data[9]
          local voiceIndex = data[10]
          local isRhythmOverride = data[11]
          local currentRhythmWithoutTuplets = data[12]
          local maxRhythmWithoutTuplets = data[13]
          local minBeat = data[14]
          local maxBeat = data[15]
          local tupletFactorNum = data[16]
          local tupletFactorDenom = data[17]
          local beatTable = data[18]
          local timeSigNum = data[19]
          local timeSigDenom = data[20]
          local measureIndex = data[21]
          addToNotationDrawList({category, xMin, xMax, yMin, yMax, img, voiceIndex, isRhythmOverride, currentRhythmWithoutTuplets, maxRhythmWithoutTuplets, minBeat, maxBeat, tupletFactorNum, tupletFactorDenom, beatTable, timeSigNum, timeSigDenom, measureIndex})
          addToGameData("notation", {"rest", qnToTimeFromTempoMap(qnQuantized), imgFileName, xMin, yMin, xMax, yMax, voiceIndex})
          end
        if category == "dot" then
          local dotCenterX = xMin + DOTRADIUS
          local dotCenterY = yMin + DOTRADIUS
          local imgFileName = "dot"
          local img = getImageFromList(imgFileName)
          addToNotationDrawList({category,  xMin, xMax, yMin, yMax, img})
          addToGameData("notation", {"dot", nil, imgFileName, xMin, yMin, xMax, yMax})
          end
        if category == "ghostleft" then
          local img = data[8]
          addToNotationDrawList({"ghost", xMin, xMax, yMin, yMax, img})
          addToGameData("notation", {"ghost", nil, "ghost_left", xMin, yMin, xMax, yMax})
          end
        if category == "ghostright" then
          local img = data[8]
          addToNotationDrawList({"ghost", xMax, xMin, yMin, yMax, img})
          addToGameData("notation", {"ghost", nil, "ghost_right", xMin, yMin, xMax, yMax})
          end
        if string.sub(category, 1, 9) == "gracestem" then
          local stemXPos = xMin
          local stemYMin = yMin
          local stemYMax = yMax
          addToNotationDrawList({"stem", stemXPos, stemXPos, stemYMin, stemYMax})
          addToGameData("notation", {"gracestem", nil, nil, stemXPos, stemYMin, stemXPos, stemYMax})
          
          local testGraceQN
          if voiceIndex == 2 then
            testGraceQN = prevGraceNoteQNVoice2
          else
            testGraceQN = prevGraceNoteQNVoice1
            end

          if testGraceQN and roundFloatingPoint(qnQuantized-testGraceQN) == GRACEQNDIFF then
            local beamSizeY = STAFFSPACEHEIGHT/3.5
            local prevXPos
            local beamYMin1, beamYMax_1, beamYMin2, beamYMax_2
            if voiceIndex == 2 then
              prevXPos = prevGraceNoteXPosVoice2
              beamYMin_1 = stemYMax
              beamYMax_1 = beamYMin_1 - beamSizeY
              beamYMin_2 = beamYMax_1 - beamSizeY
              beamYMax_2 = beamYMin_2 - beamSizeY
            else
              prevXPos = prevGraceNoteXPosVoice1
              beamYMin_1 = stemYMin
              beamYMax_1 = beamYMin_1 + beamSizeY
              beamYMin_2 = beamYMax_1 + beamSizeY
              beamYMax_2 = beamYMin_2 + beamSizeY
              end
            for z=#notationDrawList, 1, -1 do
              local data = notationDrawList[z]
              if data[1] == "graceflag" and data[7] == testGraceQN then
                table.remove(notationDrawList, z)
                break
                end
              end
            addToNotationDrawList({"beam", prevXPos, stemXPos, beamYMin_1, beamYMax_1})
            addToGameData("notation", {"gracebeam", nil, nil, prevXPos, beamYMin_1, stemXPos, beamYMax_1})
            addToNotationDrawList({"beam", prevXPos, stemXPos, beamYMin_2, beamYMax_2})
            addToGameData("notation", {"gracebeam", nil, nil, prevXPos, beamYMin_2, stemXPos, beamYMax_2})
          else
            local imgFileName = "flag_8"
            local img = getImageFromList(imgFileName)
            
            if img then
              local imgSizeX, imgSizeY = getImageSize("flag_8")
              local imgAspectRatio = imgSizeX/imgSizeY
              
              local flagXMin = stemXPos
              local flagYMin, flagYMax
              local flagSizeY = STAFFSPACEHEIGHT*1.5
              local scalingFactor = flagSizeY/imgSizeY
              local flagSizeX = imgSizeX*scalingFactor
              local flagXMax = flagXMin + flagSizeX
              
              local slashLineXMin, slashLineYMin, slashLineXMax, slashLineYMax
              if voiceIndex == 2 then
                flagYMin = stemYMax
                flagYMax = flagYMin - flagSizeY
                slashLineXMax = stemXPos-flagSizeX/1.5
                slashLineYMax = flagYMin - STAFFSPACEHEIGHT
                slashLineXMin = flagXMax
                slashLineYMin = flagYMin - STAFFSPACEHEIGHT/4
              else
                flagYMin = stemYMin
                flagYMax = flagYMin + flagSizeY
                slashLineXMin = stemXPos-flagSizeX/1.5
                slashLineYMax = flagYMin + STAFFSPACEHEIGHT/4
                slashLineXMax = flagXMax
                slashLineYMin = flagYMax
                end
              
              addToNotationDrawList({"graceflag", flagXMin, flagXMax, flagYMin, flagYMax, img, qnQuantized})
              addToGameData("notation", {"graceflag", nil, imgFileName, flagXMin, flagYMin, flagXMax, flagYMax})
              addToNotationDrawList({"graceline", slashLineXMin, slashLineXMax, slashLineYMin, slashLineYMax})
              addToGameData("notation", {"graceline", nil, nil, slashLineXMin, slashLineYMin, slashLineXMax, slashLineYMax})
              end
            end
            
          if voiceIndex == 2 then
            prevGraceNoteQNVoice2 = qnQuantized
            prevGraceNoteXPosVoice2 = stemXPos
          else
            prevGraceNoteQNVoice1 = qnQuantized
            prevGraceNoteXPosVoice1 = stemXPos
            end
            
          local lowestStaffLine = data[8]
          local highestStaffLine = data[9]
          
          local function drawLegerLine(staffLine)
            local legerLineYPos = getStaffLinePosition(staffLine)
            local legerLineXMin, legerLineXMax
            if category == "stem1" then
              legerLineXMax = stemXPos + STAFFSPACEHEIGHT/2
              legerLineXMin = legerLineXMax - LEGERLINELEN
            else
              legerLineXMin = stemXPos - STAFFSPACEHEIGHT/2
              legerLineXMax = legerLineXMin + LEGERLINELEN
              end
            addToNotationDrawList({"legerLine", legerLineXMin, legerLineXMax, legerLineYPos})
            addToGameData("notation", {"leger_line", nil, nil, legerLineXMin, legerLineYPos, legerLineXMax, legerLineYPos})
            end
            
          for staffLine=-3, lowestStaffLine, -1 do
            drawLegerLine(staffLine)
            end
          for staffLine=3, highestStaffLine do
            drawLegerLine(staffLine)
            end
            
          end
        if string.sub(category, 1, 4) == "stem" then
          local stemXPos = xMin
          addToNotationDrawList({"stem", stemXPos, stemXPos, yMin, yMax})
          local beamGameDataTable = {}
          
          local lowestStaffLine = data[8]
          local highestStaffLine = data[9]
          local rollType = data[11]
          local choke = data[12]
          
          local function drawLegerLine(staffLine)
            local legerLineYPos = getStaffLinePosition(staffLine)
            local legerLineXMin, legerLineXMax
            if category == "stem1" then
              legerLineXMax = stemXPos + STAFFSPACEHEIGHT/2
              legerLineXMin = legerLineXMax - LEGERLINELEN
            else
              legerLineXMin = stemXPos - STAFFSPACEHEIGHT/2
              legerLineXMax = legerLineXMin + LEGERLINELEN
              end
            addToNotationDrawList({"legerLine", legerLineXMin, legerLineXMax, legerLineYPos})
            addToGameData("notation", {"leger_line", nil, nil, legerLineXMin, legerLineYPos, legerLineXMax, legerLineYPos})
            end
            
          for staffLine=-3, lowestStaffLine, -1 do
            drawLegerLine(staffLine)
            end
          for staffLine=3, highestStaffLine do
            drawLegerLine(staffLine)
            end
            
          local stemBeamTable = data[10]
          if stemBeamTable then
            local prevStemXPos
            if category == "stem1" then
              prevStemXPos = masterRecentStemXPosBothVoices[1]
            else
              prevStemXPos = masterRecentStemXPosBothVoices[2]
              end
            
            for z=1, #stemBeamTable do
              local beamData = stemBeamTable[z]
              
              local beamCategory = beamData[1]
              local beamYMin = beamData[2]
              local beamYMax = beamData[3]
              
              local beamXMin, beamXMax
              local beamIntType
              if beamCategory == "full" then
                beamXMin = prevStemXPos
                beamXMax = stemXPos
                beamIntType = 0
                end
              if beamCategory == "stubright" then
                beamXMin = prevStemXPos
                beamXMax = beamXMin + BEAMSTUBX
                beamIntType = 1
                end
              if beamCategory == "stubleft" then
                beamXMax = stemXPos
                beamXMin = beamXMax - BEAMSTUBX
                beamIntType = 2
                end
              
              addToNotationDrawList({"beam", beamXMin, beamXMax, beamYMin, beamYMax})
              tableInsert(beamGameDataTable, beamIntType)
              end
            end
          
          table.sort(beamGameDataTable)
          local beamGameDataStr = voiceIndex .. table.concat(beamGameDataTable)
          addToGameData("notation", {"stem", nil, nil, stemXPos, yMin, stemXPos, yMax, beamGameDataStr})
          
          if rollType then
            local imgFileName = rollType
            local img = getImageFromList(imgFileName)
            
            if img then
              local imgSizeX, imgSizeY = getImageSize(imgFileName)
              local imgAspectRatio = imgSizeX/imgSizeY
              local rollHeight
              if rollType == "buzz" then
                rollHeight = BUZZ_HEIGHT
              else
                rollHeight = TREMOLO_HEIGHT
                end
                
              local rollYMin, rollYMax
              if category == "stem1" then
                rollYMin = yMin + STAFFSPACEHEIGHT*1
                rollYMax = rollYMin + rollHeight
              else
                rollYMax = yMax - STAFFSPACEHEIGHT*1
                rollYMin = rollYMax - rollHeight
                end
              
              local scalingFactor = rollHeight/imgSizeY
              local rollSizeX = imgSizeX*scalingFactor
              local rollXMin = stemXPos - rollSizeX/2
              local rollXMax = stemXPos + rollSizeX/2

              addToNotationDrawList({rollType, rollXMin, rollXMax, rollYMin, rollYMax, img})
              addToGameData("notation", {"roll", nil, imgFileName, rollXMin, rollYMin, rollXMax, rollYMax})
              end
            end
          
          if choke then
            local imgFileName = "choke"
            local img = getImageFromList(imgFileName)
            
            if img then
              local imgSizeX, imgSizeY = getImageSize(imgFileName)
              local imgAspectRatio = imgSizeX/imgSizeY
              
              local chokeHeight = STAFFSPACEHEIGHT
              
              local chokeXMin = stemXPos + STAFFSPACEHEIGHT*0.75
              local chokeYMin, chokeYMax
              if category == "stem1" then
                chokeYMax = yMin - STAFFSPACEHEIGHT/2
                chokeYMin = chokeYMax - chokeHeight
              else
                chokeYMin = yMax + STAFFSPACEHEIGHT/2
                chokeYMax = chokeYMin + chokeHeight
                end
              
              local scalingFactor = chokeHeight/imgSizeY
              local sizeX = imgSizeX*scalingFactor
              local chokeXMax = chokeXMin + sizeX
              
              addToNotationDrawList({"choke", chokeXMin, chokeXMax, chokeYMin, chokeYMax, img})
              addToGameData("notation", {"choke", nil, imgFileName, chokeXMin, chokeYMin, chokeXMax, chokeYMax})
              end
            end
          
          if category == "stem1" then
            masterRecentStemXPosBothVoices[1] = stemXPos
          else
            masterRecentStemXPosBothVoices[2] = stemXPos
            end
          end
        if string.sub(category, 1, 7) == "tuplet_" then
          local underscoreIndex = string.find(category, "_", 8)
          local inProgressTupletIndex = string.sub(category, underscoreIndex+1, #category)
          if string.sub(category, 8, underscoreIndex) == "start_" then
            tableInsert(inProgressTupletList, {inProgressTupletIndex, xMin})
          else
            local index = isInTable(inProgressTupletList, inProgressTupletIndex)
            local xMin = inProgressTupletList[index][2]
            local imgData = data[8]
            table.remove(inProgressTupletList, index)

            local bracketXMin = xMin - 5
            local bracketXMax = xMax - 12
            local bracketYPoint = yMin
            local bracketYLong = yMax
              
            local distanceFromCenterX = (imgData[#imgData][4])/2
            local centerX = bracketXMin + (bracketXMax-bracketXMin)/2
            local paddingX = 10
            local bracketSubXMin = centerX - distanceFromCenterX - paddingX
            local bracketSubXMax = centerX + distanceFromCenterX + paddingX
            
            addToNotationDrawList({"tuplet_line", bracketXMin, bracketXMin, bracketYPoint, bracketYLong})
            addToGameData("notation", {"tuplet_line", nil, nil, bracketXMin, bracketYPoint, bracketXMin, bracketYLong})
            addToNotationDrawList({"tuplet_line", bracketXMin, bracketSubXMin, bracketYLong, bracketYLong})
            addToGameData("notation", {"tuplet_line", nil, nil, bracketXMin, bracketYLong, bracketSubXMin, bracketYLong})
            addToNotationDrawList({"tuplet_line", bracketSubXMax, bracketXMax, bracketYLong, bracketYLong})
            addToGameData("notation", {"tuplet_line", nil, nil, bracketSubXMax, bracketYLong, bracketXMax, bracketYLong})
            addToNotationDrawList({"tuplet_line", bracketXMax, bracketXMax, bracketYPoint, bracketYLong})
            addToGameData("notation", {"tuplet_line", nil, nil, bracketXMax, bracketYPoint, bracketXMax, bracketYLong})
                
            for x=1, #imgData do
              local data = imgData[x]
              
              local img = data[1]
              local xMin = data[2] + bracketSubXMin + paddingX
              local yMin = data[3]
              local xMax = data[4] + bracketSubXMin + paddingX
              local yMax = data[5]
              local imgFileName = data[6]
              
              local sizeY = yMax - yMin
              yMin = bracketYLong - sizeY/2
              yMax = bracketYLong + sizeY/2
              
              addToNotationDrawList({"tuplet_number", xMin, xMax, yMin, yMax, img})
              addToGameData("notation", {"tuplet_number", nil, imgFileName, xMin, yMin, xMax, yMax})
              end
            end
          end
        if category == "articulation" then
          local img = data[8]
          local imgFileName = data[9]
          addToNotationDrawList({"articulation", xMin, xMax, yMin, yMax, img})
          addToGameData("notation", {"articulation", nil, imgFileName, xMin, yMin, xMax, yMax})
          end
        if category == "tie" then
          addToNotationDrawList({"tie", xMin, xMax, yMin, yMax, voiceIndex})
          end
        end
      end
    end
  
  local function storeMeasureLine()
    local xMin = measureBoundXMax + MEASUREENDSPACING
    
    local measureLabel
    if measureIndex == #measureList then
      measureLabel = "end"
      addToNotationDrawList({"beatNumber", xMin, xMin, 100000})
    else
      local _, _, nextMeasureSectionName = getMeasureData(measureIndex+1)
      if measureSectionName ~= nextMeasureSectionName then
        measureLabel = "double"
      else
        measureLabel = "normal"
        end
      end
    
    local imgFileName = "measure_" .. measureLabel
    local img = getImageFromList(imgFileName)
    local imgSizeX, imgSizeY = getImageSize(imgFileName)
    local imgAspectRatio = imgSizeX/imgSizeY
    
    local yMin = getStaffLinePosition(2)
    local yMax = getStaffLinePosition(-2)
    local sizeY = yMax - yMin
    
    local scalingFactor = sizeY/imgSizeY
    local sizeX = imgSizeX*scalingFactor
    
    local xMax = xMin + sizeX
    if not gettingCurrentValues then
      ENDMEASUREXMAX = xMax
      end
    
    currentMeasureLineData = {xMin, xMax, yMin, yMax, img, imgFileName, measureLabel, measureBoundXMin, measureBoundXMax}
    
    measureBoundXMin = xMax + MEASURESTARTSPACING --for next measure
    
    if measureIndex == #measureList then
      drawPreviousMeasureLine(measureIndex+1)
      end
    end
    
  ---
  
  qnEventList = {}
      
  measureStartPPQPOS, measureEndPPQPOS, measureSectionName, qnStart, qnEnd, currentQN, timeSigNum, timeSigDenom, beatTable, beamGroupingsTable, currentBeat, quantizeNum, quantizeDenom, quantizeTupletFactorNum, quantizeTupletFactorDenom, quantizeModifier, restOffsets = getMeasureData(measureIndex, isActiveMeasure)
  
  addToGameData("notation", {"measure"})
  
  addToXML("    <measure number=\"" .. measureIndex .. "\">")
  addToXML()
  addToXML("      <attributes>")
  xmlDivisionsPerQN = 256
  xmlDivisionsPerMeasure = round(xmlDivisionsPerQN * timeSigNum / (timeSigDenom/4))
  addToXML("        <divisions>" .. xmlDivisionsPerQN .. "</divisions>")
  measureTimeSigOffset = 0
  if measureIndex == 1 then
    addToXML("        <clef><sign>percussion</sign><line>2</line></clef>")
    
    addToXML("        <key><fifths>0</fifths></key>")
    
    lastSectionName = measureSectionName
    drawTimeSignature(timeSigNum, timeSigDenom)
  else
    if measureSectionName ~= lastSectionName then
      lastSectionName = measureSectionName
      end
    
    local _, _, _, _, _, _, prevTimeSigNum, prevTimeSigDenom, _, prevBeamGroupingsTable = getMeasureData(measureIndex-1)
    
    if not deepEquals(beamGroupingsTable, prevBeamGroupingsTable) then
      stopMultiMeasure = true
      end
      
    if timeSigNum ~= prevTimeSigNum or timeSigDenom ~= prevTimeSigDenom then
      drawTimeSignature(timeSigNum, timeSigDenom)
    else
      measureBoundXMin = measureBoundXMin + MEASURESTARTSPACING*0.75
      end
    end
  measureBoundXMax = getQNXPos(qnEnd, true)
  
  addToXML("      </attributes>")
  addToXML()
  
  drawNotes()
  
  local timeSigOffsetX
  if measureTimeSigOffset ~= 0 then
    timeSigOffsetX = measureTimeSigOffset - MEASURESTARTSPACING/2
  else
    timeSigOffsetX = 0
    end
  if not isActiveMeasure then
    measureList[measureIndex][MEASURELISTINDEX_MEASUREBOUNDARYXMIN] = measureBoundXMin - timeSigOffsetX
    measureList[measureIndex][MEASURELISTINDEX_MEASUREBOUNDARYXMAX] = measureBoundXMax
    end
  
  storeMeasureLine()
  
  addToXML("    </measure>")
  addToXML()
  end
    
function drawNotation()
  addRectFilled(drawList, NOTATION_XMIN, NOTATION_YMIN, NOTATION_XMAX, NOTATION_YMAX, NOTATION_BGCOLOR)
  addToGameData("notation", {"staffbackground", nil, nil, NOTATION_XMIN, NOTATION_YMIN, NOTATION_XMAX, NOTATION_YMAX})
  
  if checkError(ERROR_MIDIINTOMEMORY) then return end
   
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
    processMeasure(currentMeasureIndex, true)
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
          local _, _, _, chartTextCount = reaper.MIDI_CountEvts(drumTake)
          for testTextEvtID=0, chartTextCount-1 do
            local retval, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, testTextEvtID)
            if evtType == TEXT_EVENT and string.sub(msg, 1, #header) == header and ppqpos == measurePPQPOS then
              textEvtID = testTextEvtID
              offset = tonumber(string.sub(msg, #header+1, #msg))
              end
            end
          
          local refreshState
          if textEvtID then
            setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, TEXT_EVENT, header .. round(offset + offsetChange))
            refreshState = REFRESHSTATE_KEEPSELECTIONS
          else
            insertTextSysexEvt(drumTake, false, false, measurePPQPOS, TEXT_EVENT, header .. offsetChange)
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
      --[[
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
          setTextEventParameter(drumTake, textEvtID, "offset", round(offset+offsetChange))
          setRefreshState(REFRESHSTATE_KEEPSELECTIONS)
          end
        end
      
      reaper.ImGui_PopFont(ctx)
      --]]
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
          local splitStartPPQPOS = reaper.MIDI_GetPPQPosFromProjQN(drumTake, qnStart)
          local splitMiddlePPQPOS = reaper.MIDI_GetPPQPosFromProjQN(drumTake, qnMiddle)
          local splitEndPPQPOS = reaper.MIDI_GetPPQPosFromProjQN(drumTake, qnEnd)
          
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
            local _, noteCount = reaper.MIDI_CountEvts(drumTake)
            for noteID=noteCount-1, 0, -1 do
              local _, _, _, startPPQPOS, endPPQPOS, channel, midiNoteNum = reaper.MIDI_GetNote(drumTake, noteID)
              if channel == 0 and midiNoteNum == restMIDINoteNum then
                if startPPQPOS >= splitStartPPQPOS and endPPQPOS <= splitEndPPQPOS then
                  reaper.MIDI_DeleteNote(drumTake, noteID)
                elseif startPPQPOS >= splitStartPPQPOS and startPPQPOS <= splitEndPPQPOS then
                  reaper.MIDI_SetNote(drumTake, noteID, nil, nil, splitEndPPQPOS)
                elseif endPPQPOS >= splitStartPPQPOS and endPPQPOS <= splitEndPPQPOS then
                  reaper.MIDI_SetNote(drumTake, noteID, nil, nil, nil, splitStartPPQPOS)
                  end
                end
              end
            
            --TODO: add rhythmoverride note as well before this
            if splitStartPPQPOS ~= splitMiddlePPQPOS then 
            --reaper.MIDI_InsertNote(drumTake, false, false, splitStartPPQPOS, splitMiddlePPQPOS, 0, restMIDINoteNum, 127)
              end
            if splitMiddlePPQPOS ~= splitEndPPQPOS then 
              reaper.MIDI_InsertNote(drumTake, false, false, splitMiddlePPQPOS, splitEndPPQPOS, 0, restMIDINoteNum, 127)
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
      local dir = getXMLDirectory()
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
    local time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, editCursorPPQPOS)
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
    local retval, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
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
  insertTextSysexEvt(drumTake, false, false, 0, TEXT_EVENT, "config_" .. round(midiNoteNum) .. " \"(new note)\" {0 \"normal\" staffline_0}")
  end

function deleteNote(midiNoteNum)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
    throwError("No config text event ID! " .. midiNoteNum)
    end
  
  deleteTextSysexEvt(drumTake, textEvtID)
  end

function setNoteMIDINumber(originalMIDINoteNum, newMIDINoteNum)
  reaper.PreventUIRefresh(1)
  
  local textEvtID = 0
  while true do
    local retval, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
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
        setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, "config_" .. round(newMIDINoteNum) .. string.sub(msg, spaceIndex, #msg))
        end
      if midiNoteNum == newMIDINoteNum then
        setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, "config_" .. round(originalMIDINoteNum) .. string.sub(msg, spaceIndex, #msg))
        end
      end
      
    textEvtID = textEvtID + 1
    end
  
  local _, chartNoteCount = reaper.MIDI_CountEvts(drumTake)
  local originalNoteList, newNoteList = {}, {}
  local originalNotationTextEvtList, newNotationTextEvtList = {}, {}
  
  for noteID=chartNoteCount-1, 0, -1 do
    local _, selected, muted, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(drumTake, noteID)
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
        local _, selected, muted, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, notationTextEvtID)
        local spaceIndexStart = string.find(msg, " ", 6)
        local spaceIndexEnd = string.find(msg, " ", spaceIndexStart+1)
        local replacedMsg = string.sub(msg, 1, spaceIndexStart) .. replacedMIDINoteNum .. string.sub(msg, spaceIndexEnd, #msg)
        
        local textEvtData = {selected, muted, ppqpos, evtType, replacedMsg}
        tableInsert(notationTextEvtList, textEvtData)
        deleteTextSysexEvt(drumTake, notationTextEvtID)
        end
        
      local noteData = {selected, muted, startPPQPOS, endPPQPOS, channel, replacedMIDINoteNum, velocity}
      tableInsert(originalNoteList, noteData)
      reaper.MIDI_DeleteNote(drumTake, noteID)
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
      
      reaper.MIDI_InsertNote(drumTake, selected, muted, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity, true)
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
      
      insertTextSysexEvt(drumTake, selected, muted, ppqpos, evtType, msg)
      end
    end
      
  addNotesBack(originalNoteList)
  addNotesBack(newNoteList)
  
  addTextEvtsBack(originalNotationTextEvtList)
  addTextEvtsBack(newNotationTextEvtList)
  
  reaper.MIDI_Sort(drumTake)

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
  if checkError(ERROR_INVALIDTAKE) then return end
  
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
  
  local STATE_XGAP = 8
  local CHANNELTEXT_XPOS = collapsingHeaderPos - 35
  local CHANNELSELECTOR_XPOS = CHANNELTEXT_XPOS + 32
  local CHANNELSELECTOR_WIDTH = 25
  local STATENAMEFIELD_XPOS = CHANNELSELECTOR_XPOS + CHANNELSELECTOR_WIDTH + STATE_XGAP
  local STATENAMEFIELD_WIDTH = 120
  local GEMSELECTOR_XPOS = STATENAMEFIELD_XPOS + STATENAMEFIELD_WIDTH + STATE_XGAP
  local GEMSELECTOR_WIDTH = 80
  local GEMCOLOR_XPOS = GEMSELECTOR_XPOS + GEMSELECTOR_WIDTH + STATE_XGAP
  local GEMCOLOR_WIDTH = 20
  local NOTEHEADSELECTOR_XPOS = GEMCOLOR_XPOS + GEMCOLOR_WIDTH + STATE_XGAP
  local NOTEHEADSELECTOR_WIDTH = 80
  local STAFFLINESELECTOR_XPOS = NOTEHEADSELECTOR_XPOS + NOTEHEADSELECTOR_WIDTH + STATE_XGAP
  local STAFFLINESELECTOR_WIDTH = 60
  local ARTICULATIONSELECTOR_XPOS = STAFFLINESELECTOR_XPOS + STAFFLINESELECTOR_WIDTH + STATE_XGAP
  local ARTICULATIONSELECTOR_WIDTH = 100
  local HIHATCCSELECTOR_XPOS = ARTICULATIONSELECTOR_XPOS + ARTICULATIONSELECTOR_WIDTH + STATE_XGAP
  local HIHATCCSELECTOR_WIDTH = 30
  local DELETESTATEBUTTON_XPOS = HIHATCCSELECTOR_XPOS + HIHATCCSELECTOR_WIDTH + STATE_XGAP
  
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
        setTextEventParameter(drumTake, textEvtID, propertyHeader, val)
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
        setTextEventParameter(drumTake, textEvtID, currentChannel, nil)
        setTextEventParameter(drumTake, textEvtID, newChannel, stateHeader)
        end
      end
    end
    
  -------------
  
  for midiNoteNum=127, 0, -1 do
    local laneOverride = isLaneOverride(midiNoteNum)
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
        
        if not laneOverride then
          local extList = "Text Files (*.txt)\0*.txt\0\0"
          local dir = getInstrumentsDirectory()
          
          reaper.ImGui_SameLine(ctx)
          if button(COLOR_SAVE, COLOR_SAVE_HOVERED, COLOR_SAVE_ACTIVE, "Save##SAVEINSTRUMENT") then
            local retval, filePath = reaper.JS_Dialog_BrowseForSaveFile("Save Instrument", dir, midiName .. ".txt", extList)
            if retval == 1 then
              if getFileExtension(filePath) ~= "txt" then
                local dotIndex = string.find(filePath, ".")
                if dotIndex then
                  filePath = string.sub(filePath, 1, dotIndex) .. "txt"
                else
                  filePath = filePath .. ".txt"
                  end
                end
              
              local textEvtID = getConfigTextEventID(midiNoteNum)
              local _, _, _, _, _, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
              local spaceIndex = string.find(msg, " ")
          
              local file = io.open(filePath, "w+")
              file:write(string.sub(msg, spaceIndex+1, #msg))
              file:close()
              end
            end
          
          reaper.ImGui_SameLine(ctx)
          if button(COLOR_LOAD, COLOR_LOAD_HOVERED, COLOR_LOAD_ACTIVE, "Load##LOADINSTRUMENT") then
            local retval, filePath = reaper.JS_Dialog_BrowseForOpenFiles("Load Instrument", dir, "", extList, false)
            if retval == 1 and getFileExtension(filePath) == "txt" then
              local file = io.open(filePath, "r")
              local fileText = file:read("*all")
              file:close()
  
              local textEvtID = getConfigTextEventID(midiNoteNum)
              local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
              local spaceIndex = string.find(msg, " ")
              setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, string.sub(msg, 1, spaceIndex) .. fileText)
              
              setRefreshState(REFRESHSTATE_COMPLETE)
              end
            end
          
          local noteStateHeaders
          local notePropertyHeaders
          if laneOverride then
            noteStateHeaders = {}
            if noteType == "sustain1" or noteType == "sustain2" then
              notePropertyHeaders = {"cc"}
            else
              notePropertyHeaders = {}
              end
          else
            noteStateHeaders = getRequiredNoteStateHeaders(noteType)
            notePropertyHeaders = getRequiredNotePropertyHeaders(noteType)
            end
          
          for x=1, #notePropertyHeaders do
            local propertyHeader = notePropertyHeaders[x]
            if x == 1 then
              reaper.ImGui_SetCursorPosX(ctx, collapsingHeaderPos+40)
            else
              reaper.ImGui_SameLine(ctx)
              end
            notePropertyWidget(midiNoteNum, propertyHeader)
            end
          
          for x=1, #noteStateHeaders do
            local stateHeader = noteStateHeaders[x]
            reaper.ImGui_SetCursorPosX(ctx, collapsingHeaderPos+40)
            noteStateWidget(midiNoteNum, stateHeader)
            end
          end
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
          local _, _, _, _, _, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
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
          deleteTextSysexEvt(drumTake, textEvtID)
          end
        end
        
      local file = io.open(filePath, "r")
      local fileText = file:read("*all")
      file:close()
      
      for line in fileText:gmatch("[^\r\n]+") do
        insertTextSysexEvt(drumTake, false, false, 0, TEXT_EVENT, line)
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
  
function getNoteTable(midiNoteNum)
  debug_printStack()
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

  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
  
  local openQuoteIndex = string.find(msg, '"')
  local closeQuoteIndex = string.find(msg, '"', openQuoteIndex+1)
  
  msg = string.sub(msg, 1, openQuoteIndex) .. noteName .. string.sub(msg, closeQuoteIndex, #msg)
  
  setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, msg)
  end
    
function getHiHatCC(midiNoteNum)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return false end
  
  return noteTable[19]
  end
  
function setHiHatCC(midiNoteNum, ccVal)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
    throwError("No config text event ID! " .. midiNoteNum)
    end
  
  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
  
  local headerIndex, underscoreIndex = string.find(msg, "hihatcc_")
  if underscoreIndex then
    local spaceIndex = string.find(msg, " ", underscoreIndex)
    if ccVal then
      msg = string.sub(msg, 1, underscoreIndex) .. ccVal .. string.sub(msg, spaceIndex, #msg)
    else
      msg = string.sub(msg, 1, headerIndex-1) .. string.sub(msg, spaceIndex+1, #msg)
      end
  elseif ccVal then
    local openBraceSpaceIndex = string.find(msg, " {")
    msg = string.sub(msg, 1, openBraceSpaceIndex) .. "hihatcc_" .. ccVal .. string.sub(msg, openBraceSpaceIndex, #msg)
    end
    
  setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, msg)
  end

function getLaneStart(midiNoteNum)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return false end
  
  return noteTable[20]
  end
  
function setLaneStart(midiNoteNum, val)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
    throwError("No config text event ID! " .. midiNoteNum)
    end
  
  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
  
  local headerIndex, underscoreIndex = string.find(msg, "lanestart_")
  if underscoreIndex then
    local spaceIndex = string.find(msg, " ", underscoreIndex)
    msg = string.sub(msg, 1, underscoreIndex) .. val .. string.sub(msg, spaceIndex, #msg)
  else
    local openBraceSpaceIndex = string.find(msg, " {")
    msg = string.sub(msg, 1, openBraceSpaceIndex) .. "lanestart_" .. val .. string.sub(msg, openBraceSpaceIndex, #msg)
    end
    
  setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, msg)
  end

function getLaneEnd(midiNoteNum)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return false end
  
  return noteTable[21]
  end
  
function setLaneEnd(midiNoteNum, val)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
    throwError("No config text event ID! " .. midiNoteNum)
    end
  
  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
  
  local headerIndex, underscoreIndex = string.find(msg, "laneend_")
  if underscoreIndex then
    local spaceIndex = string.find(msg, " ", underscoreIndex)
    msg = string.sub(msg, 1, underscoreIndex) .. val .. string.sub(msg, spaceIndex, #msg)
  else
    local openBraceSpaceIndex = string.find(msg, " {")
    msg = string.sub(msg, 1, openBraceSpaceIndex) .. "laneend_" .. val .. string.sub(msg, openBraceSpaceIndex, #msg)
    end
    
  setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, msg)
  end
  
function getSpecialType(midiNoteNum)
  local noteTable = getNoteTable(midiNoteNum)
  if not noteTable then return false end
  
  return noteTable[22]
  end
  
function setSpecialType(midiNoteNum, val)
  local textEvtID = getConfigTextEventID(midiNoteNum)
  if not textEvtID then
    throwError("No config text event ID! " .. midiNoteNum)
    end
  
  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
  
  local headerIndex, underscoreIndex = string.find(msg, "specialtype_")
  if underscoreIndex then
    local spaceIndex = string.find(msg, " ", underscoreIndex)
    if val ~= "[none]" then
      msg = string.sub(msg, 1, underscoreIndex) .. val .. string.sub(msg, spaceIndex, #msg)
    else
      msg = string.sub(msg, 1, headerIndex-1) .. string.sub(msg, spaceIndex+1, #msg)
      end
  elseif val ~= "[none]" then
    local openBraceSpaceIndex = string.find(msg, " {")
    msg = string.sub(msg, 1, openBraceSpaceIndex) .. "specialtype_" .. val .. string.sub(msg, openBraceSpaceIndex, #msg)
    end
    
  setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, msg)
  end

function anyNonOverrideDrumNotesInRange(rangeStartPPQPOS, rangeEndPPQPOS, originalNoteID, originalVoiceIndex)
  local indexOffset = 0
  local doneWithLeftSide, doneWithRightSide
  local testCount = 0
  
  while true do
    local noteID = originalNoteID + indexOffset
    
    local retval = (noteID >= 0 and noteID < #MIDI_DRUMS_noteEvents)
    
    local data = MIDI_DRUMS_noteEvents[noteID+1]
    
    local startPPQPOS
    local channel
    local midiNoteNum
    if retval then
      startPPQPOS = getValueFromTable(data, "ppqpos_start")
      channel = getValueFromTable(data, "channel")
      midiNoteNum = getValueFromTable(data, "pitch")
      end
    
    if indexOffset < 0 and (not retval or startPPQPOS < rangeStartPPQPOS) then
      doneWithLeftSide = true
    elseif (not retval or startPPQPOS >= rangeEndPPQPOS) then
      doneWithRightSide = true
    else
      if not isLaneOverride(midiNoteNum) and getMIDINoteVoice(noteID) == originalVoiceIndex then
        return true
        end
      end
    
    if doneWithLeftSide and doneWithRightSide then
      return false
      end
    
    if indexOffset >= 0 then
      indexOffset = indexOffset * (-1) - 1
    else
      indexOffset = indexOffset * (-1)
      end
    
    testCount = testCount + 1
    if testCount == 1000 then
      throwError("anyNonOverrideDrumNotesInRange")
      end
    end
  
  return false
  end
  
function storeConfigIntoMemory()
  currentRefreshStateLoop = false
  
  configList = {}
  validHiHatCCs = {}
  
  for i, msg in ipairs(MIDI_configMessages) do
    local originalMsg = msg
    local newMsg = originalMsg --if missing state parameters
    
    local spaceIndex = string.find(msg, " ")
    if not spaceIndex then
      throwError("Config error no space: " .. msg)
      end
      
    local midiNoteNum = tonumber(string.sub(msg, 8, spaceIndex-1))
    if not midiNoteNum then
      throwError("Config error: missing MIDI note number! " .. msg)
      end
    if not isValidMIDINote(midiNoteNum) then
      throwError("Config error: MIDI #" .. midiNoteNum)
      end
    msg = string.sub(msg, spaceIndex+1, #msg)
    
    configList[midiNoteNum+1] = {}
    local noteTable = configList[midiNoteNum+1]
    
    --laneType
    local spaceIndex = string.find(msg, " ")
    local laneType = string.sub(msg, 1, spaceIndex-1)
    noteTable[17] = laneType
    
    if laneType == "sustain1" or laneType == "sustain2" then
      local _, ccUnderscoreIndex = string.find(msg, "cc_")
      
      if not ccUnderscoreIndex then
        if laneType == "sustain1" then ccNum = 1 end
        if laneType == "sustain2" then ccNum = 2 end
    
        setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, TEXT_EVENT, msg .. " cc_" .. ccNum)
        
        currentRefreshStateLoop = true
        return
        end
      
      local endIndex
      local spaceIndex = string.find(msg, " ", ccUnderscoreIndex)
      if spaceIndex then
        endIndex = spaceIndex - 1
      else
        endIndex = #msg
        end
      local ccNum = tonumber(string.sub(msg, ccUnderscoreIndex+1, endIndex))
      if laneType == "sustain1" then SUSTAINLANE1_CC = ccNum end
      if laneType == "sustain2" then SUSTAINLANE2_CC = ccNum end
      end  
      
    if laneType == "dynamics" then
      DYNAMICSMIDINOTENUM = midiNoteNum
      end
    
    msg = string.sub(msg, spaceIndex+1, #msg)
    
    --noteName
    local closeQuoteIndex = string.find(msg, '"', 2)
    if not closeQuoteIndex then
      throwError("Config error no close quote: MIDI #" .. midiNoteNum)
      end
    local noteName = string.sub(msg, 2, closeQuoteIndex-1)
    if not noteName or noteName == "" then
      throwError("Config error invalid note name: MIDI #" .. midiNoteNum)
      end
    msg = string.sub(msg, closeQuoteIndex+2, #msg)
    
    noteTable[18] = noteName

    noteTable[19] = {}
    
    local values = separateString(msg)
    for x=1, #values do
      local str = trimTrailingSpaces(values[x])
      if #str > 0 then
        local underscoreIndex = string.find(str, "_")
        local header = string.sub(str, 1, underscoreIndex-1)
        local val = string.sub(str, underscoreIndex+1, #str)
        if tonumber(val) then
          val = tonumber(val)
          end
          
        if tonumber(header) then
          local channel = tonumber(header)
          local stateName = val
          if channel < 0 or channel > 15 or floor(channel) ~= channel then
            throwError("Config MIDI channel error: MIDI #" .. midiNoteNum)
            end
          noteTable[channel+1] = stateName
        else
          tableInsert(noteTable[19], {header, val})
          if laneType == "hihat" and header == "pedal" then
            tableInsert(validHiHatCCs, val)
            end
          end
        end
      end
    end
  
  --
  
  --populate missing override lanes
  for x=1, #VALID_LANEOVERRIDE_LIST do
    local laneOverrideLabel = VALID_LANEOVERRIDE_LIST[x]
    local isValid = false
    for midiNoteNum=0, 127 do
      if getNoteType(midiNoteNum) == laneOverrideLabel then
        isValid = true
        break
        end
      end
    
    if not isValid then
      local emptyMIDINoteLane = getFirstEmptyMIDINoteLane()
      if not emptyMIDINoteLane then
        throwError("Missing lane override config " .. laneOverrideName .. ", but no more available MIDI lanes!")
        end
      
      insertTextSysexEvt(drumTake, false, false, 0, TEXT_EVENT, "config_" .. emptyMIDINoteLane .. " " .. laneOverrideLabel .. " \"" .. laneOverrideLabel .. "\"")
      currentRefreshStateLoop = true
      return
      end
    end
  
  updateMIDIEditor()
  end

function getFirstEmptyMIDINoteLane()
  local validNoteLanes = {}
  local _, noteCount = reaper.MIDI_CountEvts(drumTake)
  for noteID=0, noteCount-1 do
    local _, _, _, _, _, _, midiNoteNum = reaper.MIDI_GetNote(drumTake, noteID)
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

function updateMIDIEditor()
  reaper.PreventUIRefresh(1)
  
  for midiNoteNum=0, 127 do
    local name = getNoteName(midiNoteNum)
    if isLaneOverride(midiNoteNum) then
      local laneType = getNoteName(midiNoteNum)
      reaper.SetTrackMIDINoteName(drumTrackID, midiNoteNum, -1, string.upper(name))
    else
      if name then
        reaper.SetTrackMIDINoteName(drumTrackID, midiNoteNum, -1, name)
        end
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
    local ppqpos = reaper.MIDI_GetPPQPosFromProjTime(drumTake, time)
    tableInsert(list, "qn=" .. qn .. " ppqpos=" .. ppqpos .. " time=" .. time .. " bpm=" .. bpm)
    
    if i == numMarkers-1 then
      if qn >= END_TEXT_EVT_QN then
        throwError("Tempo markers found past the [end] event!")
        end
        
      local ppqpos = reaper.MIDI_GetPPQPosFromProjQN(drumTake, END_TEXT_EVT_QN)
      local time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, ppqpos)
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
  
  chartBeatList, notationBeatList = {}, {}
    
  local _, noteCount = reaper.MIDI_CountEvts(eventsTake)
  for noteID=0, noteCount-1 do
    local _, _, _, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(eventsTake, noteID)
    local startQN = getQNFromPPQPOS(eventsTake, startPPQPOS)
    local startTime = reaper.MIDI_GetProjTimeFromPPQPos(eventsTake, startPPQPOS)
    
    local tableToInsert
    if midiNoteNum < BEAT_WEAK_CHART then
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
    tableInsert(tableToInsert, {startPPQPOS, startTime, midiNoteNum})
    end
  if not endEvtPPQPOS then
    throwError("The last notation beat note MUST be a measure note (to determine where the last measure ends)!")
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
  
  add("CHART_BEAT_LIST")
  for i, data in ipairs(chartBeatList) do
    local ppqpos = data[1]
    local time = data[2]
    local midiNoteNum = data[3]
    add("ppqpos=" .. ppqpos .. " time=" .. time .. " beat_type=" .. midiNoteNum-BEAT_WEAK_CHART)
    end
    
  add("NOTATION_BEAT_LIST")
  for i, data in ipairs(notationBeatList) do
    local ppqpos = data[1]
    local time = data[2]
    local midiNoteNum = data[3]
    add("ppqpos=" .. ppqpos .. " time=" .. time .. " beat_type=" .. midiNoteNum)
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
  
function convertReaperNotesToTextFile()
  local masterTable = {}
  
  local function add(val)
    tableInsert(masterTable, val)
    end
  
  add("CONFIG")
  for midiNoteNum=0, 127 do
    local textEvtID = getConfigTextEventID(midiNoteNum)
    if textEvtID then
      local _, _, _, _, _, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
      if string.sub(msg, 1, 7) ~= "config_" then
        throwError("Bad config event! " .. msg)
        end
      add(msg)
      end
    end
  
  local _, chartNoteCount, chartCCCount, chartTextCount = reaper.MIDI_CountEvts(drumTake)
  
  add("NOTES")
  for noteID=0, chartNoteCount-1 do
    local _, _, _, startPPQPOS, endPPQPOS, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(drumTake, noteID)
    local startQN = getQNFromPPQPOS(drumTake, startPPQPOS)
    local endQN = getQNFromPPQPOS(drumTake, endPPQPOS)
    local startTime = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, startPPQPOS)
    local endTime = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, endPPQPOS)
    local notationTextEvtID = getNotationTextEventID(startPPQPOS, channel, midiNoteNum)
    local notationTextEvtStr
    if notationTextEvtID then
      local _, _, _, _, _, msg = reaper.MIDI_GetTextSysexEvt(drumTake, notationTextEvtID)
      notationTextEvtStr = " text_event_id=" .. notationTextEvtID .. " `text_event_message=" .. msg .. "`"
    else
      notationTextEvtStr = ""
      end
    add("id=" .. noteID .. " ppqpos_start=" .. startPPQPOS .. " time_start=" .. startTime .. " qn_start=" .. startQN .. " ppqpos_end=" .. endPPQPOS .. " time_end=" .. endTime .. " qn_end=" .. endQN .. " channel=" .. channel .. " pitch=" .. midiNoteNum .. " velocity=" .. velocity .. notationTextEvtStr)
    end
    
  add("CCS")
  for ccID=0, chartCCCount-1 do
    local _, _, _, ppqpos, _, channel, ccNum, ccVal = reaper.MIDI_GetCC(drumTake, ccID)
    local qn = getQNFromPPQPOS(drumTake, ppqpos)
    local time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, ppqpos)
    local _, shape = reaper.MIDI_GetCCShape(drumTake, ccID)
    add("id=" .. ccID .. " ppqpos=" .. ppqpos .. " time=" .. time .. " qn=" .. qn .. " channel=" .. channel .. " number=" .. ccNum .. " value=" .. ccVal .. " shape=" .. shape)
    end
  
  add("TEXTS")
  for textEvtID=0, chartTextCount-1 do
    local _, _, _, ppqpos, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
    local qn = getQNFromPPQPOS(drumTake, ppqpos)
    local time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, ppqpos)
    add("id=" .. textEvtID .. " ppqpos=" .. ppqpos .. " time=" .. time .. " qn=" .. qn .. " event_type=" .. evtType .. " `message=" .. msg .. "`")
    end
  
  ---------------------------------------------------
  
  local file = io.open(getMIDIDataTextFilePath(), "w+")
  file:write(table.concat(masterTable, "\n"))
  file:close()
  end

function storeTemposIntoMemory()
  local file = io.open(getTemposTextFilePath(), "r")
  local fileText = file:read("*all")
  file:close()
  
  tempoMap = {}
  for line in fileText:gmatch("[^\r\n]+") do
    local values = separateString(line)
    
    tableInsert(tempoMap, {})
    local subTable = tempoMap[#tempoMap]
    
    subTable[TEMPOMAPINDEX_QN] = getValueFromTable(values, "qn")
    subTable[TEMPOMAPINDEX_PPQPOS] = getValueFromTable(values, "ppqpos")
    subTable[TEMPOMAPINDEX_TIME] = getValueFromTable(values, "time")
    subTable[TEMPOMAPINDEX_BPM] = getValueFromTable(values, "bpm")
    end
  end
  
function storeEventsIntoMemory()
  local file = io.open(getEventsTextFilePath(), "r")
  local fileText = file:read("*all")
  file:close()
  
  endEvtPPQPOS = nil
  endEvtQN = nil
  endEvtTime = nil
  
  chartBeatList = {}
  notationBeatList = {}
  sectionTextEvtList = {}
  tempoTextEvtList = {}
  measureList = {}
  
  local currentHeader
  for line in fileText:gmatch("[^\r\n]+") do
    local values = separateString(line)
    if #values == 1 then
      currentHeader = line
    else
      if currentHeader == "MISC" then
        endEvtPPQPOS = getValueFromTable(values, "end_event_ppqpos")
        endEvtQN = getValueFromTable(values, "end_event_qn")
        endEvtTime = getValueFromTable(values, "end_event_time")
        end
      if currentHeader == "CHART_BEAT_LIST" then
        tableInsert(chartBeatList, {})
        local subTable = chartBeatList[#chartBeatList]
        subTable[BEATLISTINDEX_PPQPOS] = getValueFromTable(values, "ppqpos")
        subTable[BEATLISTINDEX_TIME] = getValueFromTable(values, "time")
        subTable[BEATLISTINDEX_BEATTYPE] = getValueFromTable(values, "beat_type")
        end
      if currentHeader == "NOTATION_BEAT_LIST" then
        tableInsert(notationBeatList, {})
        local subTable = notationBeatList[#notationBeatList]
        subTable[BEATLISTINDEX_PPQPOS] = getValueFromTable(values, "ppqpos")
        subTable[BEATLISTINDEX_TIME] = getValueFromTable(values, "time")
        subTable[BEATLISTINDEX_BEATTYPE] = getValueFromTable(values, "beat_type")
        end
      if currentHeader == "SECTION_LIST" then
        tableInsert(sectionTextEvtList, {})
        local subTable = sectionTextEvtList[#sectionTextEvtList]
        subTable[1] = getValueFromTable(values, "ppqpos")
        subTable[2] = getValueFromTable(values, "name")
        end
      if currentHeader == "TEMPO_LIST" then
        tableInsert(tempoTextEvtList, {})
        local subTable = tempoTextEvtList[#tempoTextEvtList]
        subTable[TEMPOLISTINDEX_PPQPOS] = getValueFromTable(values, "ppqpos")
        subTable[TEMPOLISTINDEX_QN] = getValueFromTable(values, "qn")
        subTable[TEMPOLISTINDEX_BPMBASIS] = getValueFromTable(values, "bpm_basis")
        subTable[TEMPOLISTINDEX_BPM] = getValueFromTable(values, "bpm")
        subTable[TEMPOLISTINDEX_PERFORMANCEDIRECTION] = getValueFromTable(values, "performance_direction")
        end
      if currentHeader == "MEASURE_LIST" then
        tableInsert(measureList, {})
        local subTable = measureList[#measureList]
        subTable[MEASURELISTINDEX_PPQPOS] = getValueFromTable(values, "ppqpos")
        subTable[MEASURELISTINDEX_QN] = getValueFromTable(values, "qn")
        subTable[MEASURELISTINDEX_TIME] = getValueFromTable(values, "time")
        subTable[MEASURELISTINDEX_BEAMGROUPINGS] = getValueFromTable(values, "beam_groupings")
        subTable[MEASURELISTINDEX_SECONDARYBEAMGROUPINGS] = getValueFromTable(values, "secondary_beam_groupings")
        local timeSigStr = getValueFromTable(values, "time_sig")
        local slashIndex = string.find(timeSigStr, "/")
        subTable[MEASURELISTINDEX_TIMESIGNUM] = tonumber(string.sub(timeSigStr, 1, slashIndex-1))
        subTable[MEASURELISTINDEX_TIMESIGDENOM] = tonumber(string.sub(timeSigStr, slashIndex+1, #timeSigStr))
        
        local beatsStr = getValueFromTable(values, "beats")
        local beatTable = {}
        while true do
          local semicolonIndex = string.find(beatsStr, ";")
          local currentStr
          if semicolonIndex then
            currentStr = string.sub(beatsStr, 1, semicolonIndex-1)
          else
            currentStr = beatsStr
            end
            
          local commaIndex_1 = string.find(currentStr, ",")
          local commaIndex_2 = string.find(currentStr, ",", commaIndex_1+1)
          local commaIndex_3 = string.find(currentStr, ",", commaIndex_2+1)
          local commaIndex_4 = string.find(currentStr, ",", commaIndex_3+1)
          
          local qnBeat = tonumber(string.sub(currentStr, 1, commaIndex_1-1))
          local isStrongBeat = (string.sub(currentStr, commaIndex_1+1, commaIndex_2-1) == "1")
          local rhythm = tonumber(string.sub(currentStr, commaIndex_2+1, commaIndex_3-1))
          local num = tonumber(string.sub(currentStr, commaIndex_3+1, commaIndex_4-1))
          local denom = tonumber(string.sub(currentStr, commaIndex_4+1, #currentStr))
          tableInsert(beatTable, {qnBeat, isStrongBeat, rhythm, num, denom})
          
          if semicolonIndex then
            beatsStr = string.sub(beatsStr, semicolonIndex+1, #beatsStr)
          else
            break
            end
          end
        
        subTable[MEASURELISTINDEX_BEATTABLE] = beatTable
        subTable[MEASURELISTINDEX_QUANTIZESTR] = getValueFromTable(values, "quantize_str")
        subTable[MEASURELISTINDEX_QUANTIZEDENOM] = getValueFromTable(values, "quantize_denom")
        subTable[MEASURELISTINDEX_QUANTIZETUPLETFACTORNUM] = getValueFromTable(values, "quantize_tuplet_factor_num")
        subTable[MEASURELISTINDEX_QUANTIZETUPLETFACTORDENOM] = getValueFromTable(values, "quantize_tuplet_factor_denom")
        subTable[MEASURELISTINDEX_QUANTIZEMODIFIER] = getValueFromTable(values, "quantize_modifier")
        end
      end
    end
  end
  
function storeMIDIIntoMemory()
  initializeGameData()
  
  for x=1, #chartBeatList do
    local data = chartBeatList[x]
    local time = data[BEATLISTINDEX_TIME]
    local beatType = data[BEATLISTINDEX_BEATTYPE]
    addToGameData("beatline", {time, beatType})
    end
  
  noteList = {}
  hihatCCList = {}
  
  articulationListBothVoices = { {}, {} }
  beamOverrideListBothVoices = { {}, {} }
  tupletListBothVoices = { {}, {} }
  rhythmOverrideListBothVoices = { {}, {} }
  sustainListBothVoices = { {}, {} }
  restListBothVoices = { {}, {} }
  dynamicList = {}
  staffTextList = {}
  restOffsetListBothVoices = {{}, {}}
  
  ghostThresholdTextEvtList = {}
  accentThresholdTextEvtList = {}
  beamOverRestsTextEvtList = {}
  
  hhOverrideSegments, hhLaneValueList = {}, {}, {}
  for x=1, #validHiHatCCs do
    tableInsert(hhOverrideSegments, {})
    end
  
  for i, data in ipairs(MIDI_DRUMS_ccEvents) do
    local ccNum = getValueFromTable(data, "number")
    local channel = getValueFromTable(data, "channel")
    
    local hhTableIndex = isInTable(validHiHatCCs, ccNum)
    if channel == 1 and hhTableIndex then
      local overrideSegmentTable = hhOverrideSegments[hhTableIndex]
      local lastLaneSubTable = overrideSegmentTable[#overrideSegmentTable]
      
      local time = getValueFromTable(data, "time")
      local ccVal = getValueFromTable(data, "value")
      
      if ccVal >= 64 then
        if #overrideSegmentTable == 0 or #lastLaneSubTable == 2 then
          tableInsert(overrideSegmentTable, {time})
          end
      else
        if #lastLaneSubTable == 1 then
          lastLaneSubTable[2] = time
          end
        end
      end
    end
  
  for i, data in ipairs(MIDI_DRUMS_noteEvents) do
    local noteID = getValueFromTable(data, "id")
    local startPPQPOS = getValueFromTable(data, "ppqpos_start")
    local endPPQPOS = getValueFromTable(data, "ppqpos_end")
    local startQN = getValueFromTable(data, "qn_start")
    local endQN = getValueFromTable(data, "qn_end")
    local startTime = getValueFromTable(data, "time_start")
    local endTime = getValueFromTable(data, "time_end")
    local channel = getValueFromTable(data, "channel")
    local midiNoteNum = getValueFromTable(data, "pitch")
    local velocity = getValueFromTable(data, "velocity")
    local notationTextEvtID = getValueFromTable(data, "text_event_id")
    local notationTextEvtMsg = getValueFromTable(data, "text_event_message")
    
    if isLaneOverride(midiNoteNum) then
      local laneType = getNoteType(midiNoteNum)
      local voiceIndex = tonumber(string.sub(laneType, #laneType, #laneType))
      
      if laneType == "tuplet1" or laneType == "tuplet2" then
        tableInsert(tupletListBothVoices[voiceIndex], {startPPQPOS, endPPQPOS, startQN, endQN, startTime, endTime, channel})
        end
        
      if channel == 0 and (laneType == "rhythm1" or laneType == "rhythm2") then
        if notationTextEvtMsg and string.find(notationTextEvtMsg, "text ") then
          tableInsert(rhythmOverrideListBothVoices[voiceIndex], {startPPQPOS, endPPQPOS, startQN, endQN, startTime, endTime})
          end
        
        if not anyNonOverrideDrumNotesInRange(startPPQPOS, endPPQPOS, noteID, voiceIndex) then
          tableInsert(restListBothVoices[voiceIndex], {startPPQPOS, endPPQPOS, startQN, endQN, startTime, endTime})
          end
        end
      
      --TODO: collision between rhythm/tuplet and sustain
      if channel == 0 and (laneType == "sustain1" or laneType == "sustain2") then
        tableInsert(sustainListBothVoices[voiceIndex], {startPPQPOS, endPPQPOS, startQN, endQN, startTime, endTime})
        end
        
      if channel == 0 and (laneType == "dynamics") and notationTextEvtMsg then
        tableInsert(dynamicList, {startPPQPOS, endPPQPOS, startQN, endQN, startTime, endTime})
        end
    else
      local noteName = getNoteName(midiNoteNum)
      local hihatCC = getNoteProperty(midiNoteNum, "pedal")
      
      local noteState = getNoteState(midiNoteNum, channel)
      if noteState then
        local notehead, staffLine, articulation = getNotationProperties(midiNoteNum, channel)
        
        tableInsert(noteList, {startPPQPOS, endPPQPOS, startQN, endQN, startTime, endTime, nil, channel, midiNoteNum, noteState, nil, nil, nil, 1, nil, nil, nil, notehead, staffLine, articulation, velocity, noteID})
        
        --process sustains and chokes?
      
        local hhTableIndex = isInTable(validHiHatCCs, hihatCC)
        if hhTableIndex then
          local laneIndex
          for x=1, #hhLaneValueList do
            local subTable = hhLaneValueList[x]
            if subTable[1] == hihatCC then
              laneIndex = x
              break
              end
            end
          if not laneIndex then
            tableInsert(hhLaneValueList, {hihatCC})
            laneIndex = #hhLaneValueList
            end
          local subTable = hhLaneValueList[laneIndex]
          local prevCCVal
          if #subTable == 1 then
            prevCCVal = 0
          else
            prevCCVal = subTable[#subTable][2]
            end
          if noteState == "stomp" then
            tableInsert(subTable, {startTime, 0, false})
          elseif noteState == "lift" then
            tableInsert(subTable, {startTime, 127, false})
          elseif noteState == "splash" then
            tableInsert(subTable, {startTime, 0, true})
            tableInsert(subTable, {startTime+0.5, 127, false})
          elseif noteState == "closed" then
            tableInsert(subTable, {startTime, 0, false})
          elseif noteState == "open" then
            tableInsert(subTable, {startTime, 127, false})
          elseif noteState == "halfopen" then
            tableInsert(subTable, {startTime, 64, false})
          else
            throwError("No valid hi-hat state! " .. noteState, nil, startTime)
            end
          end
        
      else
        throwError("Invalid note (does not match any current state!) " .. midiNoteNum .. " " .. channel, nil, startTime)
        end
      end
    end
  
  --clear space for overrides before adding them
  for x=1, #hhLaneValueList do
    local subTable = hhLaneValueList[x]
    local overrideSegmentTable = hhOverrideSegments[x]
    --local overrideSegmentIndex = #overrideSegmentTable
    for y=#subTable, 2, -1 do
      local data = subTable[y]
      local time = data[1]
      for z=1, #overrideSegmentTable do
        local overrideStartTime = overrideSegmentTable[z][1]
        local overrideEndTime = overrideSegmentTable[z][2]
        if time >= overrideStartTime and (not overrideEndTime or time < overrideEndTime) then
          table.remove(subTable, y)
          break
          end
        end
      end
    
    --check for CC points at start of all overrides
    for y=1, #overrideSegmentTable do
      local overrideStartTime = overrideSegmentTable[y][1]
      local foundPoint = false
      
      --TODO: binary optimization
      for i, data in ipairs(MIDI_DRUMS_ccEvents) do
        local ppqpos = getValueFromTable(data, "ppqpos")
        local time = getValueFromTable(data, "time")
        local channel = getValueFromTable(data, "channel")
        local ccNum = getValueFromTable(data, "number")
        local ccVal = getValueFromTable(data, "value")

        local hhTableIndex = isInTable(validHiHatCCs, ccNum)
        if channel == 0 and hhTableIndex == x then
          if time == overrideStartTime then
            foundPoint = true
            break
            end
          if time > overrideStartTime then
            break
            end
          end
        end
      
      if not foundPoint then
        throwError("No hi-hat override start point!", nil, overrideStartTime)
        end
      end
    end
  
  --loop through override CC ch0 points and check if they are in an override zone, then add
  for i, data in ipairs(MIDI_DRUMS_ccEvents) do
    local ppqpos = getValueFromTable(data, "ppqpos")
    local time = getValueFromTable(data, "time")
    local channel = getValueFromTable(data, "channel")
    local ccNum = getValueFromTable(data, "number")
    local ccVal = getValueFromTable(data, "value")
    local shape = getValueFromTable(data, "shape")
    
    local hhTableIndex = isInTable(validHiHatCCs, ccNum)
    if channel == 0 and hhTableIndex then
      local overrideSegmentTable = hhOverrideSegments[hhTableIndex]
      local subTable = hhLaneValueList[hhTableIndex]
      
      for y=1, #overrideSegmentTable do
        local overrideStartTime = overrideSegmentTable[y][1]
        local overrideEndTime = overrideSegmentTable[y][2]
        if time >= overrideStartTime and (not overrideEndTime or time < overrideEndTime) then
          tableInsert(subTable, {time, ccVal, shape>0})
          break
          end
        end
      end
    end
  
  --sort hi-hat subTables
  local hihatCCs = {}
  for hhTableIndex=1, #hhLaneValueList do
    local hihatCC = hhLaneValueList[hhTableIndex][1]
    tableInsert(hihatCCs, hihatCC)
    table.remove(hhLaneValueList[hhTableIndex], 1)
    end
    
  for hhTableIndex=1, #hhLaneValueList do
    local subTable = hhLaneValueList[hhTableIndex]
    table.sort(subTable, function(a, b)
      return a[1] < b[1]
      end)
    end
  
  --add to game data
  for hhTableIndex=1, #hhLaneValueList do
    local subTable = hhLaneValueList[hhTableIndex]
    
    local hihatCC = hihatCCs[hhTableIndex]
    local values = {}
    
    for x=1, #subTable do
      local data = subTable[x]
      
      local time = data[1]
      local ccVal = data[2]
      local isGradient = data[3]
      
      local gradientInt
      if isGradient then gradientInt = 1 else gradientInt = 0 end
      
      tableInsert(values, time)
      tableInsert(values, ccVal)
      tableInsert(values, gradientInt)
      end
    
    if #subTable > 1 and subTable[2][1] ~= 0 then
      table.insert(values, 1, 0)
      table.insert(values, 1, 0)
      table.insert(values, 1, 0)
      end
    
    table.insert(values, 1, "cc=" .. hihatCC)
    
    addToGameData("hihatpedal", values)
    end
  
  --print override segments
  local function printOverrideSegments()
    for hhTableIndex=1, #hhLaneValueList do
      reaper.ShowConsoleMsg("----------HI-HAT INDEX " .. hhTableIndex .. "----------\n")
      
      local subTable = hhLaneValueList[hhTableIndex]

      for x=2, #subTable do
        local data = subTable[x]
        local time = data[1]
        local ccVal = data[2]
        local isGradient = data[3]
        reaper.ShowConsoleMsg("(" .. time .. ", " .. ccVal .. ")")
        if x < #subTable then
          reaper.ShowConsoleMsg(", ")
        else
          reaper.ShowConsoleMsg("\n")
          end
        end
      reaper.ShowConsoleMsg("\n")
      end
    end
  
  --printOverrideSegments()
  --]]
  
  for i, data in ipairs(MIDI_DRUMS_textEvents) do
    local ppqpos = getValueFromTable(data, "ppqpos")
    local qn = getValueFromTable(data, "qn")
    local time = getValueFromTable(data, "time")
    local evtType = getValueFromTable(data, "event_type")
    local msg = getValueFromTable(data, "message")
    
    if evtType == TEXT_EVENT then
      if string.sub(msg, 1, 12) == "ghostthresh " then
        local val = tonumber(string.sub(msg, 13, #msg))
        if not val or val < 0 or val > 127 then
          throwError("Invalid ghost note threshold!", nil, time)
          end
        tableInsert(ghostThresholdTextEvtList, {qn, val})
        end
      if string.sub(msg, 1, 13) == "accentthresh " then
        local val = tonumber(string.sub(msg, 14, #msg))
        if not val then
          throwError("Invalid accent note threshold!", nil, time)
          end
        tableInsert(accentThresholdTextEvtList, {qn, val})
        end
      if string.sub(msg, 1, 14) == "beamoverrests " then
        local val = string.sub(msg, 15, #msg)
        if not (val == "on" or val == "off") then
          throwError("Invalid beam over rests value!", nil, time)
          end
        if val == "on" then
          val = true
        else
          val = false
          end
        tableInsert(beamOverRestsTextEvtList, {qn, val})
        end
      if string.sub(msg, 1, 13) == "articulation_" then
        local voiceIndex
        if string.sub(msg, 14, 15) == "1 " then
          voiceIndex = 1
          end
        if string.sub(msg, 14, 15) == "2 " then
          voiceIndex = 2
          end
        local data = separateString(string.sub(msg, 16, #msg))
        if not voiceIndex or not data then
          throwError("Invalid articulation text event!", nil, time)
          end
        tableInsert(articulationListBothVoices[voiceIndex], {ppqpos, qn, textEvtID, data})
        end
      if string.sub(msg, 1, 5) == "beam_" then
        local voiceIndex
        if string.sub(msg, 6, 7) == "1 " then
          voiceIndex = 1
          end
        if string.sub(msg, 6, 7) == "2 " then
          voiceIndex = 2
          end
        local val = string.sub(msg, 8, #msg)
        if not voiceIndex or not val then
          throwError("Invalid beam text event!", nil, time)
          end
        tableInsert(beamOverrideListBothVoices[voiceIndex], {ppqpos, qn, textEvtID, val})
        end
      if string.sub(msg, 1, 1) == "\"" then
        local endQuoteIndex = string.find(msg, "\"", 2)
        if not endQuoteIndex then
          throwError("No end quote for staff text event!", nil, time)
          end
        local text = string.sub(msg, 2, endQuoteIndex-1)
        local values = separateString(string.sub(msg, endQuoteIndex+1, #msg))
        local offset
        for x=1, #values do
          local value = values[x]
          if string.sub(value, 1, 7) == "offset_" then
            offset = tonumber(string.sub(value, 8, #value))
            end
          end
        tableInsert(staffTextList, {ppqpos, qn, text, offset, textEvtID})
        end
      if string.sub(msg, 1, 12) == "restoffset1 " or string.sub(msg, 1, 12) == "restoffset2 " then
        local voiceIndex = tonumber(string.sub(msg, 11, 11))
        local offset = tonumber(string.sub(msg, 13, #msg))
        tableInsert(restOffsetListBothVoices[voiceIndex], {ppqpos, qn, offset, textEvtID})
        end
      end
    end
  
  if #ghostThresholdTextEvtList == 0 or ghostThresholdTextEvtList[1][1] > 0 then
    table.insert(ghostThresholdTextEvtList, 1, {0, -1})
    end
  if #accentThresholdTextEvtList == 0 or accentThresholdTextEvtList[1][1] > 0 then
    table.insert(accentThresholdTextEvtList, 1, {0, 128})
    end
  if #beamOverRestsTextEvtList == 0 or beamOverRestsTextEvtList[1][1] > 0 then
    table.insert(beamOverRestsTextEvtList, 1, {0, false})
    end
  
  addNotationStrToList()
  
  sustainLaneChartListBothVoices = {{}, {}}
  chokeListBothVoices = {{}, {}}
  
  for x=1, #noteList do
    local noteData = noteList[x]

    local startPPQPOS = noteData[NOTELISTINDEX_STARTPPQPOS]
    local endPPQPOS = noteData[NOTELISTINDEX_ENDPPQPOS]
    local startQN = noteData[NOTELISTINDEX_STARTQN]
    local endQN = noteData[NOTELISTINDEX_ENDQN]
    local laneStart = noteData[NOTELISTINDEX_LANESTART]
    local laneEnd = noteData[NOTELISTINDEX_LANEEND]
    local gem = noteData[NOTELISTINDEX_GEM]
    local color = noteData[NOTELISTINDEX_COLOR]
    local velocity = noteData[NOTELISTINDEX_VELOCITY]
    local voiceIndex = noteData[NOTELISTINDEX_VOICEINDEX]
    
    if gem == "choke" then
      tableInsert(chokeListBothVoices[voiceIndex], startQN)
      end
      
    --todo: binary search optimization
    local sustainList = sustainListBothVoices[voiceIndex]
    for y=1, #sustainList do
      local sustainData = sustainList[y]
      
      local sustainStartPPQPOS = sustainData[SUSTAINLISTINDEX_STARTPPQPOS]
      local sustainEndPPQPOS = sustainData[SUSTAINLISTINDEX_ENDPPQPOS]
      local sustainStartTime = sustainData[SUSTAINLISTINDEX_STARTTIME]
      local sustainEndTime = sustainData[SUSTAINLISTINDEX_ENDTIME]
      local rollType = sustainData[SUSTAINLISTINDEX_ROLLTYPE]
      if not rollType then
        rollType = "tremolo"
        sustainData[SUSTAINLISTINDEX_ROLLTYPE] = rollType
        local sustainMIDINoteNum = getSustainMIDINoteNum(voiceIndex)
        setNotationTextEventParameter(sustainStartPPQPOS, 0, sustainMIDINoteNum, "roll", "tremolo")
        end
        
      if startPPQPOS == sustainStartPPQPOS then
        noteData[NOTELISTINDEX_ROLL] = rollType
        noteData[NOTELISTINDEX_SUSTAINID] = #sustainLaneChartListBothVoices[voiceIndex]
        noteData[NOTELISTINDEX_SUSTAINVOICEINDEX] = voiceIndex
        tableInsert(sustainLaneChartListBothVoices[voiceIndex], {sustainStartTime, sustainEndTime, rollType, {{sustainStartTime, velocity, false}}})
        end
      
      if startPPQPOS > sustainStartPPQPOS and startPPQPOS < sustainEndPPQPOS then
        throwError("Note starts in the middle of a sustain lane!", nil, sustainStartTime)
        end
      end
    end
    
  --loop through sustain lane CC and log values
  for i, data in ipairs(MIDI_DRUMS_ccEvents) do
    local ppqpos = getValueFromTable(data, "ppqpos")
    local time = getValueFromTable(data, "time")
    local channel = getValueFromTable(data, "channel")
    local ccNum = getValueFromTable(data, "number")
    local ccVal = getValueFromTable(data, "value")
    local shape = getValueFromTable(data, "shape")

    if channel == 0 and (ccNum == SUSTAINLANE1_CC or ccNum == SUSTAINLANE2_CC) then
      local voiceIndex
      if ccNum == SUSTAINLANE1_CC then voiceIndex = 1 end
      if ccNum == SUSTAINLANE2_CC then voiceIndex = 2 end
  
      for x=1, #sustainLaneChartListBothVoices[voiceIndex] do
        local subTable = sustainLaneChartListBothVoices[voiceIndex][x]
        
        local sustainLaneStartTime = subTable[1]
        local sustainLaneEndTime = subTable[2]
        local values = subTable[4]
        
        local value = {time, ccVal, shape>0}
        if time == sustainLaneStartTime then
          values[1] = value
        elseif time > sustainLaneStartTime and time <= sustainLaneEndTime then
          tableInsert(values, value)
          end
        end
      end
    end
  
  --add endpoint and add to game data
  for voiceIndex=1, 2 do
    local sustainChartList = sustainLaneChartListBothVoices[voiceIndex]
    for sustainID=1, #sustainChartList do
      local subTable = sustainChartList[sustainID]
      
      local sustainLaneEndTime = subTable[2]
      local rollType = subTable[3]
      
      local values = {rollType}
      
      local pointTables = subTable[4]
      local x = 1
      while x <= #pointTables do
        local data = pointTables[x]
        
        local time = data[1]
        local ccVal = data[2]
        local isGradient = data[3]
        
        local gradientInt
        if isGradient then gradientInt = 1 else gradientInt = 0 end
        
        tableInsert(values, time)
        tableInsert(values, ccVal)
        tableInsert(values, gradientInt)
        
        if x == #pointTables and time ~= sustainLaneEndTime then
          tableInsert(pointTables, {sustainLaneEndTime, ccVal, false})
          end
        
        x = x + 1
        end
      
      table.insert(values, 1, "voice=" .. voiceIndex)
      table.insert(values, 1, "id=" .. sustainID-1)
      values[3] = "type=" .. values[3]
      addToGameData("sustain", values)
      end
    end
  
  for midiNoteNum=0, 127 do
    local noteType = getNoteType(midiNoteNum)
    local noteTable = getNoteTable(midiNoteNum)
    for channel=0, 15 do
      local noteState = getNoteState(midiNoteNum, channel)
      if noteState then
        local data = {"note=" .. midiNoteNum, "channel=" .. channel, "type=" .. noteType, "state=" .. noteState}
        local notePropertyTable = noteTable[19]
        for x=1, #notePropertyTable do
          local property = notePropertyTable[x]
          local propertyHeader = property[1]
          local propertyValue = property[2]
          tableInsert(data, propertyHeader .. "=" .. propertyValue)
          end
        addToGameData("state", data)
        end
      end
    end

  for x=1, #noteList do
    local noteData = noteList[x]
    
    local time = noteData[NOTELISTINDEX_STARTTIME]
    local midiNoteNum = noteData[NOTELISTINDEX_MIDINOTENUM]
    local channel = noteData[NOTELISTINDEX_CHANNEL]
    local velocity = noteData[NOTELISTINDEX_VELOCITY]
    local voiceIndex = noteData[NOTELISTINDEX_VOICEINDEX]
    local noteID = noteData[NOTELISTINDEX_NOTEID]
    
    local values = {"time=" .. time, "note=" .. midiNoteNum, "channel=" .. channel, "velocity=" .. velocity, "voice=" .. voiceIndex, "id=" .. noteID}
    
    local sustainID = noteData[NOTELISTINDEX_SUSTAINID]
    if sustainID then
      tableInsert(values, "sustain=" .. sustainID)
      end
      
    addToGameData("note", values)
    end
  end

function safeCall(func, errorCode, ...)
  local success, result = pcall(func, ...)
  if not success then
    setError(errorCode, result)
    end
  return result
  end

function storeMIDITextFileIntoTables()
  local file = io.open(getMIDIDataTextFilePath(), "r")
  local fileText = file:read("*all")
  file:close()
  
  MIDI_configMessages = {}
  MIDI_DRUMS_noteEvents = {}
  MIDI_DRUMS_ccEvents = {}
  MIDI_DRUMS_textEvents = {}
  
  local currentHeader
  for line in fileText:gmatch("[^\r\n]+") do
    local values = separateString(line)
    if #values == 1 then
      currentHeader = line
    else
      if currentHeader == "CONFIG" then
        tableInsert(MIDI_configMessages, line)
        end
      if currentHeader == "NOTES" then
        tableInsert(MIDI_DRUMS_noteEvents, values)
        end
      if currentHeader == "CCS" then
        tableInsert(MIDI_DRUMS_ccEvents, values)
        end
      if currentHeader == "TEXTS" then
        tableInsert(MIDI_DRUMS_textEvents, values)
        end
      end
    end
  end

function getValueFromTable(tbl, key)
  for x=1, #tbl do
    local str = tbl[x]
    local equalsIndex = string.find(str, "=")
    if equalsIndex and string.sub(str, 1, equalsIndex-1) == key then
      local val = string.sub(str, equalsIndex+1, #str)
      if tonumber(val) then
        val = tonumber(val)
        end
      return val
      end
    end
  end
    
function refreshNoteData(initial)
  if not initial and not anyMainWindowVisible() then return end
  
  local function runRefresh()
    if not REFRESHCOUNT then
      REFRESHCOUNT = 0
      end
    REFRESHCOUNT = REFRESHCOUNT + 1
    --reaper.ShowConsoleMsg("REFRESHCOUNT: " .. REFRESHCOUNT .. "\n")
    
    local err = safeCall(defineTakes, ERROR_INVALIDTAKE) if err then return err end
    
    
    
    _, DRUM_NOTECOUNT, DRUM_CCCOUNT, DRUM_TEXTCOUNT = reaper.MIDI_CountEvts(drumTake)
    _, EVENTS_NOTECOUNT, EVENTS_CCCOUNT, EVENTS_TEXTCOUNT = reaper.MIDI_CountEvts(eventsTake)
    
    storeReaperEventsInTextFile() --only within REAPER - before ANYTHING else, convert reaper MIDI to text file
    
    storeReaperTemposInTextFile() --only within REAPER - before ANYTHING else, convert reaper MIDI to text file
        
    convertReaperNotesToTextFile() --only within REAPER - before ANYTHING else, convert reaper MIDI to text file
    
    --------------------------------
    
    --[[
    storeImageSizesIntoMemory()
    
    storeTemposIntoMemory()
    
    defineNotationVariables()
    
    storeMIDITextFileIntoTables()
    
    storeConfigIntoMemory()
    --local err = safeCall(storeConfigIntoMemory, ERROR_CONFIGINTOMEMORY) if err then return err end
    
    storeEventsIntoMemory()
    
    storeMIDIIntoMemory()
    --local err = safeCall(storeMIDIIntoMemory, ERROR_MIDIINTOMEMORY) if err then return err end
    
    processNotationMeasures()
    
    uploadGameData()
    ]]--
    
    --------------------------------
    
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
      
    local foundTake = false
    local textEvtID = 0
    while true do
      local retval, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(take, textEvtID)
      if not retval then
        break
        end
        
      if evtType == TRACKNAME_EVENT and msg == validTrackName then
        foundTake = true
        break
        end
      textEvtID = textEvtID + 1
      end
    if not foundTake then
      take = nil
      end
    
    return take, track, trackID
    end
  
  drumTake, drumTrack, drumTrackID = defineTake(drumTrack, VALID_DRUMTRACKNAME)
  eventsTake, eventsTrack, eventsTrackID = defineTake(eventsTrack, VALID_EVENTSTRACKNAME)
  end

function getPPQResolution(take)
  local ppq0 = reaper.MIDI_GetPPQPosFromProjQN(take, 0.0)
  local ppq1 = reaper.MIDI_GetPPQPosFromProjQN(take, 1.0)
  return ppq1 - ppq0
  end

function getPPQPOSFromQN(qn)
  local trueVal = roundFloatingPoint(qn*PPQ_RESOLUTION)
  local reaperVal = roundFloatingPoint(reaper.MIDI_GetPPQPosFromProjQN(drumTake, qn))
  if trueVal ~= reaperVal then
    reaper.ShowConsoleMsg("Bad PPQPOS from QN calculation! " .. qn .. " " .. trueVal .. "~=" .. reaperVal .. "\n")
    throwError("Bad PPQPOS from QN calculation! " .. qn .. " " .. trueVal .. "~=" .. reaperVal)
    end
  return trueVal
  end

function qnToTimeFromTempoMap(qn)
  local reaperVal = roundFloatingPoint(reaper.MIDI_GetProjTimeFromPPQPos(drumTake, reaper.MIDI_GetPPQPosFromProjQN(drumTake, qn)))
  
  for x=1, #tempoMap-1 do
    local currentData = tempoMap[x]
    local currentQN = currentData[TEMPOMAPINDEX_QN]
    local currentPPQPOS = currentData[TEMPOMAPINDEX_PPQPOS]
    local currentTime = currentData[TEMPOMAPINDEX_TIME]
    local currentBPM = currentData[TEMPOMAPINDEX_BPM]
    
    local nextData = tempoMap[x+1]
    local nextQN = nextData[TEMPOMAPINDEX_QN]
    local nextPPQPOS = nextData[TEMPOMAPINDEX_PPQPOS]
    local nextTime = nextData[TEMPOMAPINDEX_TIME]
    local nextBPM = nextData[TEMPOMAPINDEX_BPM]
    
    if qn <= nextQN then
      local trueVal = roundFloatingPoint(convertRange(qn, currentQN, nextQN, currentTime, nextTime))
      
      if math.abs(trueVal - reaperVal) > 0.000001 then
        reaper.ShowConsoleMsg("BAD: " .. qn .. " " .. currentQN .. " " .. nextQN .. " (" .. trueVal .. "~=" .. reaperVal .. ")\n")
        end
      
      return trueVal
      end
    end
  
  throwError("Trying to calculate position past [end] event! (" .. ppqpos .. ")")
  end
  
function listenToMIDIEditor()
  local midiEditor = reaper.MIDIEditor_GetActive()
  if reaper.MIDIEditor_GetTake(midiEditor) ~= drumTake then return end
  
  local function getClosestNoteBeforeCursor(activeNoteRow)
    local cursorPos = reaper.GetCursorPosition()
    local resultingNoteID
    
    local noteID = 0
    while true do
      local retval, _, _, startppqpos, _, _, midiNoteNum = reaper.MIDI_GetNote(drumTake, noteID)
      if not retval then
        break
        end
      
      if midiNoteNum == activeNoteRow then
        local time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, startppqpos)
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
          
          local _, _, _, startppqpos = reaper.MIDI_GetNote(drumTake, noteID)
          local initialTime = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, startppqpos)
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
    for x=1, #noteList do
      local noteData = noteList[x]
      local noteID = noteData[NOTELISTINDEX_NOTEID]
      local graceState = noteData[NOTELISTINDEX_GRACESTATE]
      local _, selected = reaper.MIDI_GetNote(drumTake, noteID)
      if selected then
        tableInsert(selectedNoteList, noteData)
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
          reaper.MIDI_SetNote(drumTake, noteID, nil, nil, nil, nil, nil, nil, velocity)
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
          local _, selected, muted, startppqpos, endppqpos, channel, midiNoteNum, velocity = reaper.MIDI_GetNote(drumTake, noteID)
          local midppqpos = getNewFlamPPQPOS(drumTake, startppqpos)
          reaper.MIDI_SetNote(drumTake, noteID, nil, nil, nil, midppqpos, nil, nil, nil)
          setNotationTextEventParameter(startppqpos, channel, midiNoteNum, nil, "flamgrace", "grace")
          reaper.MIDI_InsertNote(drumTake, selected, muted, midppqpos, endppqpos, channel, midiNoteNum, velocity)
          setNotationTextEventParameter(midppqpos, channel, midiNoteNum, nil, "flam", "grace")
        elseif #selectedNoteList == 2 then
          local noteData_1 = selectedNoteList[1]
          local noteData_2 = selectedNoteList[2]
          local noteID_1 = noteData_1[NOTELISTINDEX_NOTEID]
          local _, _, _, startppqpos_1, endppqpos_1, _, midiNoteNum_1 = reaper.MIDI_GetNote(drumTake, noteID_1)
          local noteID_2 = noteData_2[NOTELISTINDEX_NOTEID]
          local _, _, _, startppqpos_2, endppqpos_2, _, midiNoteNum_2 = reaper.MIDI_GetNote(drumTake, noteID_2)
        
          if midiNoteNum_1 == midiNoteNum_2 then
            return
            end
          
          local startppqpos = math.min(startppqpos_1, startppqpos_2)
          local endppqpos = math.max(endppqpos_1, endppqpos_2)
          local midppqpos = getNewFlamPPQPOS(drumTake, startppqpos)
          
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
          
          reaper.MIDI_SetNote(drumTake, earlyNoteID, nil, nil, startppqpos, midppqpos, nil, nil, nil)
          local channel = earlyNoteData[NOTELISTINDEX_CHANNEL]
          local midiNoteNum = earlyNoteData[NOTELISTINDEX_MIDINOTENUM]
          setNotationTextEventParameter(startppqpos, channel, midiNoteNum, nil, "flamgrace", "grace")
          
          reaper.MIDI_SetNote(drumTake, lateNoteID, nil, nil, midppqpos, endppqpos, nil, nil, nil)
          local channel = lateNoteData[NOTELISTINDEX_CHANNEL]
          local midiNoteNum = lateNoteData[NOTELISTINDEX_MIDINOTENUM]
          setNotationTextEventParameter(midppqpos, channel, midiNoteNum, nil, "flam", "grace")
          end
        end
      
      if val == 10 then
        local selectedNotes = {}
        local selectedNoteID = -1
        while true do
          local noteID = reaper.MIDI_EnumSelNotes(drumTake, selectedNoteID)
          if noteID == -1 then break end
          tableInsert(selectedNotes, noteID)
          selectedNoteID = noteID
          end
        
        if #selectedNotes > 2 then
          local firstNoteID = selectedNotes[1]
          local lastNoteID = selectedNotes[#selectedNotes]
          local _, _, _, firstNoteStartPPQPOS, _, _, _, firstNoteVelocity = reaper.MIDI_GetNote(drumTake, firstNoteID)
          local _, _, _, lastNoteStartPPQPOS, _, _, _, lastNoteVelocity = reaper.MIDI_GetNote(drumTake, lastNoteID)
          
          for x=1, #selectedNotes do
            local noteID = selectedNotes[x]
            local _, _, _, startPPQPOS, _, _, _, velocity = reaper.MIDI_GetNote(drumTake, noteID)
            local newVelocity = round(convertRange(startPPQPOS, firstNoteStartPPQPOS, lastNoteStartPPQPOS, firstNoteVelocity, lastNoteVelocity))
            reaper.MIDI_SetNote(drumTake, noteID, nil, nil, nil, nil, nil, nil, newVelocity)
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
  
  local _, testDrumNoteCount, testDrumCCCount, testDrumTextCount = reaper.MIDI_CountEvts(drumTake)
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
      drawConfigSettings(ctx)
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
  reaper.defer(loop)
  end

------------------------------

defineErrorCodes()
defineIndeces()
defineRequiredNoteTypeTable()

initializeImages()

refreshNoteData(true)

--runProfiler() --after all functions have been defined

loop()

--TODO: error out if all relevant tracks (right now, REAL_DRUMS and REAL_EVENTS) have ~= 1 item, if not midi, AND if item start pos is not beginning of project
