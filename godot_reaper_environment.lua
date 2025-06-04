function runGodotReaperEnvironment(isReaper, reaperProcessingCurrentMeasureIndex, reaperMasterImageList, drumkitFileText, gemNameTable, configTextTable, outputTextFilePath, imgSizesFileText, temposFileText, eventsFileText, midiFileText, drumTake, drumTrack, drumTrackID, eventsTake, eventsTrack, eventsTrackID)
	
	---------------------------CONSTANTS----------------------------
	
	TEXT_EVENT = 1
	NOTATION_EVENT = 15
	TRACKNAME_EVENT = 3
	MAX_RHYTHM = 128
	
	MEASUREENDSPACING = 5
	MEASURESTARTSPACING = 12
	STEM_XSHIFT = 1
	GRACEQNDIFF = 0.00001
	
	QUARTERBEATXLEN = 110

	DRAWBEAM_START = 0
	DRAWBEAM_FULLCURRENT = 1
	DRAWBEAM_FULLPREV = 2
	DRAWBEAM_STUBLEFT = 3
	DRAWBEAM_STUBRIGHT = 4
	DRAWBEAM_SECONDARY = 5
	DRAWBEAM_STUBLEFTSECONDARY = 6
	DRAWBEAM_STUBRIGHTSECONDARY = 7
	DRAWBEAM_STUBRIGHTLEFTSECONDARY = 8
	DRAWBEAM_END = 10

	SPECIAL_MEASURE_HEADER_LIST = {"gaps"}

	-----
	
	ERROR_INVALIDTAKE = 0
	ERROR_CONFIGINTOMEMORY = 1
	ERROR_MIDIINTOMEMORY = 2
	ERROR_RHYTHMLIST = 3

	-----
	
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

	REFRESHSTATE_NOTREFRESHING = 0
	REFRESHSTATE_COMPLETE = 1
	REFRESHSTATE_KEEPSELECTIONS = 2
	REFRESHSTATE_ERROR = 3

	VALID_LANEOVERRIDE_LIST = {"tuplet1", "tuplet2", "rhythm1", "rhythm2", "sustain1", "sustain2", "dynamics"}
	VALID_DYNAMICS_LIST = {"ppp", "pp", "p", "mp", "mf", "f", "ff", "fff", "sf", "sfz", "rfz", "fp", "n", "crescendo", "cresc.", "diminuendo", "decrescendo", "dim."}
	VALID_RHYTHM_DENOM_LIST = {1, 2, 4, 8, 16, 32, 64, 128}
	VALID_NOTEHEAD_LIST = {
	  {"normal", 0.33},
	  {"diamond", 0.45},
	  {"square", 0.5},
	  {"x", 0.1},
	  {"circle-x", 0.1}
	}

	-----------------------HELPER FUNCTIONS-------------------------
	
	local function debug_printStack()
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
	
	  if isReaper then
		reaper.ShowConsoleMsg(str .. "-----\n")
	  else
		print(str .. "-----")
		end
	  end

	local function throwError(text, measureIndex, time)
	  if not text then
		text = ""
		end
	
	  if isReaper then
		  if measureIndex then
			text = "m." .. measureIndex .. ": " .. text
			local measurePPQPOS = measureList[measureIndex][MEASURELISTINDEX_PPQPOS]
			time = reaper.MIDI_GetProjTimeFromPPQPos(drumTake, measurePPQPOS)
			end
		  
		  if time then
			reaper.SetEditCurPos(time, true, false)
			end
				
		  debug_printStack()
		  end

	  error(text)
	  end
  
	local function deepCopy(orig)
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

	local function deepEquals(t1, t2)
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
	
	local function cleanPunctuationFromStr(str)
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
	
	local function getNumCharsInString(str, char)
	  return select(2, str:gsub(char, ""))
	  end
	
	local function gcd(a, b)
	  while b ~= 0 do
		  a, b = b, a % b
		end
	  return math.abs(a)
	  end

	local function lcm(a, b)
	  if not a or not b then
		debug_printStack()
		end
		
	  return math.abs(a * b) // gcd(a, b) -- Use integer division
	  end
	  
	local function lcmOfTable(denominators)
	  if #denominators == 0 then
		return nil -- No LCM for an empty table
		end
	  local result = denominators[1]
	  for i = 2, #denominators do
		result = lcm(result, denominators[i])
		end
	  return result
	  end

	local function simplifyFraction(num, denom)
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
	  
	local function addIntegerFractions(num1, den1, num2, den2)
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
	  
	local function convertRange(val, oldMin, oldMax, newMin, newMax)
	  if not val then debug_printStack() end
	  
	  return ( (val - oldMin) / (oldMax - oldMin) ) * (newMax - newMin) + newMin
	  end
  
	local function findClosestIndexAtOrBelow(list, target, subTableIndex)
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
	
	local function findIndexInListEqualOrGreaterThan(list, target, subTableIndex)
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
	  
	local function findIndexInListEqualOrLessThan(list, target, subTableIndex)
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
	
	local function binarySearchClosest(tbl, target)
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
	
	local function removeExcessZeroes(num)
	  return tostring(num):gsub("%.?0+$", "")
	  end

	local function removeQuotes(str)
	  if tonumber(str) then return str end
	  return string.gsub(str, '"', "")
	  end
  
	local function findCharFromEnd(str, char, startIndex)
	  if not startIndex then
		startIndex = #str
		end
		
	  for i = startIndex, 1, -1 do
		if str:sub(i, i) == char then
		  return i  -- Return the first match found
		  end
		end
	  end

	local function round(num, decimals)
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

	local function roundFloatingPoint(qn)
	  return round(qn, 9)
	  end
  
	local function closestPowerOfTwo(n)
	  if n < 2 then return nil end
	  
	  local power = 1
	  while true do
		if 2^power > n then
		  return 2^(power-1)
		  end
		power = power + 1
		end
	  end
	
	local function getNumBeams(beamValue)
	  return round(math.log(beamValue)/math.log(2) - 2)
	  end

	local function hexColor(r, g, b, a) --optional a
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
  
	local function getLabel(line)
	  local i = string.find(line, " ")
	  if i == nil then
		return line
		end

	  return string.sub(line, 1, i-1)
	  end

	local function getValue(line, quotes)
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
  
	local function isInTable(t, data)
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
  
	local function tableInsert(t, data)
	  if not t then
		debug_printStack()
		end
	  t[#t+1] = data
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
	
	local function trimTrailingSpaces(s)
	  return s:gsub("%s+$", "")
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
  
	local function getKeyAndValue(str)
	  local equalsIndex = string.find(str, "=")
	  local spaceIndex = string.find(str, " ")
	  if spaceIndex or not equalsIndex then
		throwError("Bad line in getKey()! " .. str)
		end
	  local key = string.sub(str, 1, equalsIndex-1)
	  local value = string.sub(str, equalsIndex+1, #str)
	  return key, value
	  end
	  
	local function getValueFromKey(line, key)
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
	
	local function getValueFromTable(tbl, key)
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
	
	local function qnToTimeFromTempoMap(qn)
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
		  return roundFloatingPoint(convertRange(qn, currentQN, nextQN, currentTime, nextTime))
		  end
		end
	  
	  throwError("Trying to calculate position past [end] event! (" .. qn .. ")")
	  end
	
	local function getRestYCoordinates(restLabel)
	  local num = tonumber(string.sub(restLabel, 6, #restLabel))
	  local index = round(math.log(num)/math.log(2) + 1)
	  local data = RESTYCOOR_LIST[index]
	  return data[1], data[2]
	  end
	
	local function getFlagYSize(flagLabel)
	  local num = tonumber(string.sub(flagLabel, 6, #flagLabel))
	  local index = round(math.log(num)/math.log(2) - 2)
	  local data = FLAGYSIZE_LIST[index]
	  if not data then reaper.ShowConsoleMsg("ERR: " .. flagLabel .. " " .. index .. "\n") debug_printStack() end
	  return data[1], data[2]
	  end
  
	--------------SUB-HELPER FUNCTIONS-------------------
	
	local function addToNotationDrawList(dataTable)
	  if not isReaper then return end
	  
	  if not gettingCurrentValues then
		tableInsert(notationDrawList, dataTable)
		end
	  end
	  
	local function addToGameData(dataType, values)
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
	
	local function addToXML(str)
	  if gettingCurrentValues then return end
	  
	  if not str then
		str = ""
		end
	  tableInsert(xmlTable, str)
	  end
	  
	local function drawPreviousMeasureLine(measureIndex)
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
  
	local function addToEventList(data)
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
	
	local function uploadXML()
	  if not isReaper then return end
	  
	  local str = table.concat(xmlTable, "\n")
	  
	  local dir = reaper.GetResourcePath() .. "/JF_DrumVisualizer/"
	  reaper.RecursiveCreateDirectory(dir, 0)
	  
	  local fileName = "generatedXML.xml"
	  local filePath = dir .. fileName
	  
	  local file = io.open(filePath, "w+")
	  file:write(str)
	  file:close()
	  end
	  
	local function notationPosToStaffLine(notationPos)
	  local staffLine = math.floor(notationPos)
	  return staffLine, staffLine ~= notationPos
	  end

	local function getStemYPercentageDownTheNote(notationLabel)
	  for x=1, #VALID_NOTEHEAD_LIST do
		local data = VALID_NOTEHEAD_LIST[x]
		if data[1] == notationLabel then
		  return data[2]
		  end
		end
	  
	  throwError("No intersection data defined! " .. notationLabel)
	  end
  
	local function isNoteDefaultGhost(noteData)
	  local noteStartQN = noteData[NOTELISTINDEX_STARTQN]
	  local velocity = noteData[NOTELISTINDEX_VELOCITY]
	  
	  local index = findIndexInListEqualOrLessThan(ghostThresholdTextEvtList, noteStartQN, 1)
	  local ghostThresh = ghostThresholdTextEvtList[index][2]
	  return (velocity <= ghostThresh)
	  end
	  
	local function isNoteGhost(noteData)
	  local isGhost = noteData[NOTELISTINDEX_GHOST]
	  if isGhost == nil then
		isGhost = isNoteDefaultGhost(noteData)
		end
	  
	  return isGhost
	  end

	local function isChordDefaultAccent(chord)
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
  
	local function getActualRhythmNumDenom(rhythmListData)
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
	
	local function getXmlRhythmType(rhythmDenom)
	  if rhythmDenom == 1 then return "whole" end
	  if rhythmDenom == 2 then return "half" end
	  if rhythmDenom == 4 then return "quarter" end
	  if rhythmDenom == 8 then return "eighth" end
	  if rhythmDenom == 16 then return "16th" end
	  if rhythmDenom == 32 then return "32nd" end
	  
	  if rhythmDenom > 32 then return rhythmDenom .. "th" end
	  end
 
	local function getXmlDuration(rhythmListData)
	  local actualRhythmNum, actualRhythmDenom = getActualRhythmNumDenom(rhythmListData)
	  return round(actualRhythmNum/actualRhythmDenom * 4 * xmlDivisionsPerQN)
	  end
	  
	local function addNoteAttributesToXML(noteData)
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

	local function attemptToGetDot(rhythmNum, rhythmDenom)
	  rhythmNum, rhythmDenom = simplifyFraction(rhythmNum, rhythmDenom)
	  local hasDot = (rhythmNum == 3)
	  if hasDot then
		rhythmNum = 1 
		rhythmDenom = round(rhythmDenom/2)
		end
	  return rhythmNum, rhythmDenom, hasDot
	  end
	
	local function getNoteTupletList(startQN, measureTupletList)
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
	  
	local function isTupletOverride(rhythmList, rhythmListIndex, measureTupletList)
	  local startQN = rhythmList[rhythmListIndex][RHYTHMLISTINDEX_QN]
	  
	  if measureTupletList then
		local noteTupletList = getNoteTupletList(startQN, measureTupletList)
		if #noteTupletList > 0 then
		  return true
		  end
		end
	  
	  return false
	  end
	  
	local function isRhythmOverriden(rhythmList, rhythmListIndex, voiceIndex, measureTupletList)
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

	local function getTupletFactorNumDenom(tupletModifier)
	  if not tupletModifier then return 1, 1 end
	  
	  if tupletModifier == "t" then return 2, 3 end
	  if tupletModifier == "q" then return 4, 5 end
	  if tupletModifier == "s" then return 4, 7 end
	  
	  throwError("Not a valid tuplet modifier!")
	  end
	  
	local function getFlagOrRestLabel(simplifiedRhythmNum, simplifiedRhythmDenom, isRest, rhythmList, rhythmListIndex, voiceIndex, measureTupletList)
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
  
	local function getBeat(beatTable, qn, isRhythmicValue)
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

	local function getQNFromBeat(beatTable, beat)
	  local flooredBeat = floor(beat)
	  local flooredBeatStart = flooredBeat
	  
	  flooredBeatStart = math.max(flooredBeatStart, 0)
	  flooredBeatStart = math.min(flooredBeatStart, #beatTable-2)
	  
	  local flooredBeatEnd = flooredBeatStart+1
	  
	  local boundStart = beatTable[flooredBeatStart+1][1]
	  local boundEnd = beatTable[flooredBeatEnd+1][1]
	  
	  return convertRange(beat, flooredBeatStart, flooredBeatEnd, boundStart, boundEnd)
	  end

	local function isStrongBeat(beatTable, beat)
	  local flooredBeat = floor(beat)
	  if flooredBeat < 0 or flooredBeat >= #beatTable then
		return false
		end
	  return beatTable[flooredBeat+1][2]
	  end
  
	local function isGradualDynamic(dynamic)
	  return (string.sub(dynamic, 1, 5) == "cresc" or string.sub(dynamic, 1, 3) == "dim" or string.sub(dynamic, 1, 7) == "decresc")
	  end
	
	local function getImageFromList(fileName)
	  if not isReaper then return end
	  
	  for _, v in ipairs(reaperMasterImageList) do
		if v[1] == fileName then
		  return table.unpack(v, 2)
		  end
		end
	  end
	 
	local function getImageSize(imgFileName)
	  for i, v in ipairs(imgSizeList) do
		if v[1] == imgFileName then
		  return v[2], v[3]
		  end
		end
	  end
  
	local function getStaffLinePosition(staffLine, isSpaceAbove)
	  local centerStaffLineIndex = NUMLOWERLEGERLINES + 3
	  local index = centerStaffLineIndex + staffLine
	  local pos = staffLinePositionList[index]
	  if isSpaceAbove then
		pos = pos - STAFFSPACEHEIGHT/2
		end
	  return pos
	  end
	 
	local function isValidMIDINote(midiNoteNum)
	  return midiNoteNum >= 0 and midiNoteNum <= 127 and math.floor(midiNoteNum) == midiNoteNum
	  end
	
	local function isConfigEvent(msg)
	  return (string.sub(msg, 1, 7) == "config_")
	  end
	
	local function getNoteTable(midiNoteNum)
	  return configList[midiNoteNum+1]
	  end
	  
	local function getNoteType(midiNoteNum)
	  local noteTable = getNoteTable(midiNoteNum)
	  if not noteTable then return end
	  return noteTable[17]
	  end
	  
	local function isLaneOverride(midiNoteNum)
	  return isInTable(VALID_LANEOVERRIDE_LIST, getNoteType(midiNoteNum))
	  end
	  

	local function getValidStateChannels(midiNoteNum)
	  local validChannels = {}
	  for channel=0, 15 do
		if getNoteState(midiNoteNum, channel) then
		  tableInsert(validChannels, channel)
		  end
		end
	  return validChannels
	  end
	  
	local function getNoteState(midiNoteNum, channel)
	  local noteTable = getNoteTable(midiNoteNum)
	  if not noteTable then return end
	  return noteTable[channel+1]
	  end
	  
	local function getNoteName(midiNoteNum)
	  local noteTable = getNoteTable(midiNoteNum)
	  if not noteTable then return end
	  return noteTable[18]
	  end

	local function setNoteName(midiNoteNum, noteName)
	  local textEvtID = getConfigTextEventID(midiNoteNum)

	  local _, _, _, _, evtType, msg = reaper.MIDI_GetTextSysexEvt(drumTake, textEvtID)
	  
	  local openQuoteIndex = string.find(msg, '"')
	  local closeQuoteIndex = string.find(msg, '"', openQuoteIndex+1)
	  
	  msg = string.sub(msg, 1, openQuoteIndex) .. noteName .. string.sub(msg, closeQuoteIndex, #msg)
	  
	  setTextSysexEvt(drumTake, textEvtID, nil, nil, nil, evtType, msg)
	  end
		
	local function getHiHatCC(midiNoteNum)
	  local noteTable = getNoteTable(midiNoteNum)
	  if not noteTable then return false end
	  
	  return noteTable[19]
	  end
	  
	local function setHiHatCC(midiNoteNum, ccVal)
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
	
	local function getMIDINoteVoice(noteID)
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

	local function getNoteProperty(midiNoteNum, property)
	  local noteTable = getNoteTable(midiNoteNum)
	  if not noteTable then return end
	  
	  local notePropertyTable = noteTable[19]
	  local index = isInTable(notePropertyTable, property)
	  if index then
		return notePropertyTable[index][2]
		end
	  end
	  
	local function getNotationProperties(midiNoteNum, channel)
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
	
	local function anyNonOverrideDrumNotesInRange(rangeStartPPQPOS, rangeEndPPQPOS, originalNoteID, originalVoiceIndex)
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
	
	local function getSustainMIDINoteNum(voiceIndex)
	  for midiNoteNum=0, 127 do
		if getNoteName(midiNoteNum) == "sustain" .. voiceIndex then
		  return midiNoteNum
		  end
		end
	  end
  
	----------------REAPER FUNCTIONS---------------------
	
	local function setError(errorCode, errorMsg)
	  ERRORCODE = errorCode
	  ERRORMSG = errorMsg
	  currentRefreshState = REFRESHSTATE_NOTREFRESHING
	  end
  
	local function getListsWithTextEvtIDs()
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

	local function updateMIDIEditor()
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
  
	local function getMatchingTextEvtID(take, targetPPQPOS, targetEvtType, targetMsg)
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
	  
	local function insertTextSysexEvt(take, selected, muted, ppqpos, evtType, msg, relevantList, relevantListPPQPOSIndex, relevantListTextEvtIDIndex)
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

	local function setTextSysexEvt(take, textEvtID, selectedIn, mutedIn, ppqposIn, evtTypeIn, msg)
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
	  
	local function deleteTextSysexEvt(take, textEvtID, relevantList, relevantListTextEvtIDIndex)
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
	
	local function setRefreshState(refreshState)
	  if CURRENT_ERRORCODE_CHECKPOINT then return end
	  
	  currentRefreshState = refreshState
	  end
	
	local function findAnyTextEventIDAtPPQPOS(take, targetPPQPOS)
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
	  
	local function getNotationTextEventID(noteStartPPQPOS, noteChannel, noteMIDINoteNum)
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
  
	local function setNotationTextEventParameter(noteStartPPQPOS, noteChannel, noteMIDINoteNum, headerWithUnderscore, val, prevVal)
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
  
	---------------SUB-MAIN FUNCTIONS--------------------
	
	local function initializeGameData()
	  uploadedGameData = false
	  
	  gameDataTable_general = {}
	  gameDataTable_states = {}
	  gameDataTable_notes = {}
	  gameDataTable_beatLines = {}
	  gameDataTable_hihatPedals = {}
	  gameDataTable_sustains = {}
	  gameDataTable_notations = {}
	  end
  
	local function storeImageSizesIntoMemory()
	  imgSizeList = {}
	  
	  for line in imgSizesFileText:gmatch("[^\r\n]+") do
		local values = separateString(line)
		tableInsert(imgSizeList, values)
		end
	  end
	
	local function defineNotationVariables()
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

	  initialConfigWindowX = 0
	  initialConfigWindowY = 45
	  initialConfigWindowSizeX = 1050
	  initialConfigWindowSizeY = 200

	  chartWindowX = 500
	  chartWindowSizeX = 810
	  chartWindowY = initialConfigWindowY
	  chartWindowSizeY = 455

	  notationWindowX = 0
	  notationWindowSizeX = 1460
	  notationWindowY = chartWindowY+chartWindowSizeY-130
	  notationWindowSizeY = 355

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
	
	local function storeMIDITextFileIntoTables()
	  MIDI_configMessages = {}
	  MIDI_DRUMS_noteEvents = {}
	  MIDI_DRUMS_ccEvents = {}
	  MIDI_DRUMS_textEvents = {}
	  
	  local currentHeader
	  for line in midiFileText:gmatch("[^\r\n]+") do
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
	
	local function storeConfigIntoMemory()
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
			  if channel < 0 or channel > 15 or math.floor(channel) ~= channel then
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
	  
	  if isReaper then
	  
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
	  end
	
	local function storeTemposIntoMemory()
	  tempoMap = {}
	  for line in temposFileText:gmatch("[^\r\n]+") do
	    local values = separateString(line)
		
		tableInsert(tempoMap, {})
		local subTable = tempoMap[#tempoMap]
		
		subTable[TEMPOMAPINDEX_QN] = getValueFromTable(values, "qn")
		subTable[TEMPOMAPINDEX_PPQPOS] = getValueFromTable(values, "ppqpos")
		subTable[TEMPOMAPINDEX_TIME] = getValueFromTable(values, "time")
		subTable[TEMPOMAPINDEX_BPM] = getValueFromTable(values, "bpm")
		end
	  end
  
	local function storeEventsIntoMemory()
	  endEvtPPQPOS = nil
	  endEvtQN = nil
	  endEvtTime = nil
	  
	  chartBeatList = {}
	  notationBeatList = {}
	  sectionTextEvtList = {}
	  tempoTextEvtList = {}
	  measureList = {}
	  
	  local currentHeader
	  for line in eventsFileText:gmatch("[^\r\n]+") do
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
	
	local function addNotationStrToList()
	  local function findAnIndex(list, target)
		local low = 1
		local high = #list
		local result = nil -- To store the index of the first value >= target
	  
		while low <= high do
		  local mid = math.floor((low + high) / 2)
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
	
	local function storeMIDIIntoMemory()
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
	
	local function initializeXML()
	  xmlTable = {}
	  
	  xmlSlurNumber = 0
	  xmlTupletNumber = 0
	  end
	
	local function storeDrawBeamStates(voiceIndex)
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
	
	local function getBeamGroupingsTable(beamGroupingsStr, secondaryBeamGroupingsStr, timeSigNum, timeSigDenom, measureIndex)
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
  
	local function getMeasureData(measureIndex, isActiveMeasure)
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
	
	local function isNoteInsideRhythmOverride(startQN, voiceIndex)
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

	local function isNoteInsideTuplet(startQN, voiceIndex)
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
  
	local function getMeasureNoteList(measureIndex, voiceIndex)
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
	  
	local function getBeamOverride(chord)
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
  
	local function getRhythmOverride(startQN, endQN, beatTable, timeSigDenom, voiceIndex, measureTupletList, chord)
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
	
	local function isBeamingOverRests(qn)
	  if not qn then
		debug_printStack()
		end
	  local index = findIndexInListEqualOrLessThan(beamOverRestsTextEvtList, qn, 1)
	  return beamOverRestsTextEvtList[index][2]
	  end
  
	local function getMeasureRhythmList(measureIndex, voiceIndex)
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

	local function getTupletImagesAndBoundaries(tupletNum, tupletDenom, showColon)
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

	local function getDynamicImageData(dynamic)
	  if dynamic == "crescendo" or dynamic == "diminuendo" or dynamic == "decrescendo" then
		return
		end
	  
	  local imgFileName = "dynamic_" .. dynamic
	  local img = getImageFromList(imgFileName)
	  if isReaper and not img then
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
	  
	local function getTempoImagesAndBoundaries(bpmBasis, bpm, performanceDirection)
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
		if isReaper and not img then
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

	local function getNumberImagesAndBoundaries(num)
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
	  
	local function getTimeSignatureImagesAndBoundaries(timeSigNum, timeSigDenom)
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
	  
	local function drawTimeSignature(timeSigNum, timeSigDenom)
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
  
	local function processMeasure(measureIndex, isActiveMeasure)
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
		  if isReaper and not img then
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
				local imgSizeX, imgSizeY = getImageSize(imgFileName)
				
				if imgSizeX then
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
				local imgSizeX, imgSizeY = getImageSize(imgFileName)
				
				if imgSizeX then
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
				local imgSizeX, imgSizeY = getImageSize(imgFileName)
				
				if imgSizeX then
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
	  
	local function processNotationMeasures()
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
		if isReaper then
		  local success, result = pcall(getMeasureRhythmList, measureIndex, 1)
		  if success then masterRhythmListBothVoices[1][measureIndex] = result else setError(ERROR_RHYTHMLIST, result) break end
		else
		  masterRhythmListBothVoices[1][measureIndex] = getMeasureRhythmList(measureIndex, 1)
		  end
		end
	  for measureIndex=1, #measureList do
	    if isReaper then
		  local success, result = pcall(getMeasureRhythmList, measureIndex, 2)
		  if success then masterRhythmListBothVoices[2][measureIndex] = result else setError(ERROR_RHYTHMLIST, result) break end
		else
		  masterRhythmListBothVoices[2][measureIndex] = getMeasureRhythmList(measureIndex, 2)
		  end
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
	
	local function uploadGameData()
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
	  
	  --[[
	  local fileName = "gamedata.txt"
	  
	  local file = io.open(getGameDataDirectory() .. fileName, "w+")
	  file:write(str)
	  file:close()
	  
	  local file = io.open(getGodotProjectDirectory() .. fileName, "w+")
	  file:write(str)
	  file:close()
	  ]]--
	  
	  gamedataFileText = str
	  
	  uploadedGameData = true
	  end
 
	local function convertToUserDrumKit()
		local gemConfigList = {}
				
		local function getGemConfigProperty(gem, property)
		  local index = exactBinarySearch(gemConfigList, gem, 1)
		  local subTable = gemConfigList[index]
		  for x=2, #subTable do
			if subTable[x][1] == property then
			  return subTable[x][2]
			  end
			end
		  end

		for x=1, #gemNameTable do
		  local gemLabel = gemNameTable[x]
		  local subTable = {gemLabel}
		  tableInsert(gemConfigList, subTable)
		  local fileText = configTextTable[x]

		  for line in fileText:gmatch("[^\r\n]+") do
			line = trimTrailingSpaces(line)
			local label = string.lower(getLabel(line))
			local value =  tonumber(getValue(line))
			if value then
			  tableInsert(subTable, {label, value})
			  end
			end
		  end
		
		table.sort(gemConfigList, function(a, b)
		  return a[1] < b[1]  -- Or a[subTableIndex] < b[subTableIndex]
		  end)
		
		local stateList = {}
		for midiNoteNum=0, 127 do
		  stateList[midiNoteNum+1] = {}
		  end
	  
		local midiNoteList = {}
		local sustainLinesBothVoices = {{}, {}}
	  
		local VALID_TOM_LIST = {
		  {"octoban", "G"},
		  {"octoban", "F"},
		  {"octoban", "E"},
		  {"octoban", "D"},
		  {"racktom", "F"},
		  {"racktom", "E"},
		  {"racktom", "D"},
		  {"floortom", "A"},
		  {"floortom", "G"}
		}
	  
		local currentHeader
		for line in gamedataFileText:gmatch("[^\r\n]+") do
		  line = trimTrailingSpaces(line)
		  local values = separateString(line)
		  if #values == 1 then
			currentHeader = line
		  else
			if currentHeader == "STATES" then
			  local midiNoteNum = getValueFromKey(line, "note")
			  local channel = getValueFromKey(line, "channel")
			  for x=#values, 1, -1 do
				local param = values[x]
				local key, value = getKeyAndValue(param)
				if key == "note" or key == "channel" then
				  table.remove(values, x)
				  end
				end
			  stateList[midiNoteNum+1][channel+1] = table.concat(values, " ")
			  end
			if currentHeader == "SUSTAINS" then
			  local sustainID = getValueFromKey(line, "id")
			  local sustainVoiceIndex = getValueFromKey(line, "voice")
			  local sustainType = getValueFromKey(line, "type")
			  sustainLinesBothVoices[sustainVoiceIndex][sustainID+1] = line
			  end
			if currentHeader == "NOTES" then
			  tableInsert(midiNoteList, line)
			  end
			end
		  end
	 
		--get drum kit (numLanes, padList, tomPadList)

		local numLanes
		local padList = {}
		local tomPadLines = {}
		for line in drumkitFileText:gmatch("[^\r\n]+") do
		  line = trimTrailingSpaces(line)
		  local values = separateString(line)
		  for x=1, #values do
			if #values > 0 then
			  local param = values[x]
			  local key, value = getKeyAndValue(param)
			  if key == "lanes" then
				numLanes = value
				end
			  if key == "type" then
				tableInsert(padList, line)
				end
			  end
			end
		  end
		
		local octobanIndeces = {}
		local racktomIndeces = {}
		local floortomIndeces = {}
		for padIndex=1, #padList do
		  local padLine = padList[padIndex]
		  local padType = getValueFromKey(padLine, "type")
		  local padOrder = getValueFromKey(padLine, "order")
		
		  local tableToInsert
		  if padType == "octoban" then
			tableToInsert = octobanIndeces
			end
		  if padType == "racktom" then
			tableToInsert = racktomIndeces
			end
		  if padType == "floortom" then
			tableToInsert = floortomIndeces
			end
		  if tableToInsert then
			tableInsert(tableToInsert, {padIndex, padOrder})
			end
		  end
	  
		local tomPadIndeces = {}
		local function sortByOrderAndAddToTomIndeces(list)
		  table.sort(list, function(a, b)
			return a[2] < b[2]
			end)
		  for x=1, #list do
			tableInsert(tomPadIndeces, list[x][1])
			end
		  end
		sortByOrderAndAddToTomIndeces(octobanIndeces)
		sortByOrderAndAddToTomIndeces(racktomIndeces)
		sortByOrderAndAddToTomIndeces(floortomIndeces)
	  
		--now, we've listed the tom pads in order of pitch!
	  
		--next, group toms into zones for reduction
	  
		local function getValidTomIndex(noteType, notePitch)
		  for validTomIndex=1, #VALID_TOM_LIST do
			if VALID_TOM_LIST[validTomIndex][1] == noteType and VALID_TOM_LIST[validTomIndex][2] == notePitch then
			  return validTomIndex
			  end
			end
		  end
		
		local prevTomTime
		local tomZones = {}
	  
		for midiNoteIndex=1, #midiNoteList do
		  local noteLine = midiNoteList[midiNoteIndex]
		
		  local time = getValueFromKey(noteLine, "time")
		  local midiNoteNum = getValueFromKey(noteLine, "note")
		  local channel = getValueFromKey(noteLine, "channel")
		  local padIndex = getValueFromKey(noteLine, "pad")
	  
		  local stateLine = stateList[midiNoteNum+1][channel+1]
		  local noteType = getValueFromKey(stateLine, "type")
		  local notePitch = getValueFromKey(stateLine, "pitch")
		
		  local validTomIndex = getValidTomIndex(noteType, notePitch)
		  if validTomIndex then
			if not prevTomTime or time > prevTomTime + 2 then --if 2 or more seconds have elapsed since last tom
			  tableInsert(tomZones, {time, {}})
			  end
			prevTomTime = time
		  
			local currentZoneValidTomIndeces = tomZones[#tomZones][2]
			if not isInTable(currentZoneValidTomIndeces, validTomIndex) then
			  tableInsert(currentZoneValidTomIndeces, validTomIndex)
			  end
			end
		  end
	  
		for x=#tomZones, 2, -1 do
		  local tomZone = tomZones[x]
		  local time = tomZone[1]
		  local validTomIndeces = tomZone[2]
		
		  local prevTomZone = tomZones[x-1]
		  local prevTime = prevTomZone[1]
		  local prevValidTomIndeces = prevTomZone[2]
		
		  local extraTomCount = 0
		  for y=1, #validTomIndeces do
			if not isInTable(prevValidTomIndeces, validTomIndeces[y]) then
			  extraTomCount = extraTomCount + 1
			  end
			end
		  if #prevValidTomIndeces + extraTomCount <= #tomPadIndeces then
			for y=1, #validTomIndeces do
			  if not isInTable(prevValidTomIndeces, validTomIndeces[y]) then
				tableInsert(prevValidTomIndeces, validTomIndeces[y])
				end
			  end
			table.remove(tomZones, x)
			end
		  end
	  
		--push everything to the right
		for x=1, #tomZones do
		  local tomZone = tomZones[x]
		  local time = tomZone[1]
		  local validTomIndeces = tomZone[2]
		
		  table.sort(validTomIndeces)
		
		  for y=1, #validTomIndeces do
			local validTomIndex = validTomIndeces[y]
			local normalizedTomPadIndex = #tomPadIndeces + (y-#validTomIndeces)
			validTomIndeces[y] = {validTomIndex, normalizedTomPadIndex}
			end
		  end
	  
		for x=1, #tomZones do
		  local tomZone = tomZones[x]
		  local time = tomZone[1]
		  local validTomIndecesData = tomZone[2]
		
		  if #validTomIndecesData > #tomPadIndeces then
			--find splits then push all hanging toms to normalized index of 0
			for y=#validTomIndecesData, 2, -1 do
			  local validTomIndex = validTomIndecesData[y][1]
			  local normalizedTomPadIndex = validTomIndecesData[y][2]
			  local validTomType = VALID_TOM_LIST[validTomIndex][1]
			
			  local prevValidTomIndex = validTomIndecesData[y-1][1]
			  local prevnormalizedTomPadIndex = validTomIndecesData[y-1][2]
			  local prevValidTomType = VALID_TOM_LIST[prevValidTomIndex][1]
			
			  if validTomType ~= prevValidTomType then
				for z=1, y-1 do
				  validTomIndecesData[z][2] = validTomIndecesData[z][2] + 1
				  end
				end
			  end
		  
			for y=1, #validTomIndecesData do
			  validTomIndecesData[y][2] = math.max(validTomIndecesData[y][2], 1)
			  end
			end
		  
		  --push octobans and racktoms to the left if not enough pads in the zone
		  if #validTomIndecesData < #tomPadIndeces then
			for y=1, #validTomIndecesData do
			  local validTomIndex = validTomIndecesData[y][1]
			  local normalizedTomPadIndex = validTomIndecesData[y][2]
			
			  local validTomType = VALID_TOM_LIST[validTomIndex][1]
			  if validTomType == "octoban" or validTomType == "racktom" then
				validTomIndecesData[y][2] = validTomIndecesData[y][2] - validTomIndecesData[1][2] + 1
				end
			  end
			end
		  end
	  
		--print tom zones and normalized pad indeces
		--[[
		for x=1, #tomZones do
		  local tomZone = tomZones[x]
		  local time = tomZone[1]
		  local validTomIndecesData = tomZone[2]
		
		  reaper.ShowConsoleMsg("ZONE " .. time .. ": {")
		  for y=1, #validTomIndecesData do
			local validTomIndex = validTomIndecesData[y][1]
			local normalizedTomPadIndex = validTomIndecesData[y][2]
		  
			reaper.ShowConsoleMsg("[" .. validTomIndex .. ", " .. normalizedTomPadIndex .. "]")
			if y < #validTomIndecesData then
			  reaper.ShowConsoleMsg(", ")
			  end
			end
		  reaper.ShowConsoleMsg("}\n")
		  end
		]]--
	  
		local function getPadFromType(padType)
		  for padIndex=1, #padList do
			local padLine = padList[padIndex]
			if getValueFromKey(padLine, "type") == padType then
			  return pad, padIndex
			  end
			end
		  end
	  
		local function setPadIndex(midiNoteIndex, padIndex)
		  midiNoteList[midiNoteIndex] = midiNoteList[midiNoteIndex] .. " pad=" .. padIndex
		  end
		
		local function attemptToSetPad(midiNoteIndex, func)
		  local noteLine = midiNoteList[midiNoteIndex]
		
		  local time = getValueFromKey(noteLine, "time")
		  local midiNoteNum = getValueFromKey(noteLine, "note")
		  local channel = getValueFromKey(noteLine, "channel")
		  local padIndex = getValueFromKey(noteLine, "pad")
		
		  local stateLine = stateList[midiNoteNum+1][channel+1]
		  local noteType = getValueFromKey(stateLine, "type")
		  local noteState = getValueFromKey(stateLine, "state")
		
		  if padIndex then return end
		
		  if func == "force_required_pads" then
			if noteType == "kick" then
			  local pad, padIndex = getPadFromType("kick")
			  setPadIndex(midiNoteIndex, padIndex)
			  end
			if noteType == "snare" then
			  local pad, padIndex = getPadFromType("snare")
			  setPadIndex(midiNoteIndex, padIndex)
			  end
			if noteType == "hihat" then
			  local pad, padIndex = getPadFromType("hihat")
			  setPadIndex(midiNoteIndex, padIndex)
			  end
			if noteType == "ride" then
			  local pad, padIndex = getPadFromType("ride")
			  setPadIndex(midiNoteIndex, padIndex)
			  end
			end
		
		  if func == "force_toms" then
			local notePitch = getValueFromKey(stateLine, "pitch")
			local validTomIndex = getValidTomIndex(noteType, notePitch)
			if validTomIndex then
			  for x=#tomZones, 1, -1 do
				local tomZone = tomZones[x]
				local tomZoneTime = tomZone[1]
				local validTomIndecesData = tomZone[2]
			  
				if time >= tomZoneTime then
				  for y=1, #validTomIndecesData do
					if validTomIndecesData[y][1] == validTomIndex then
					  local normalizedTomPadIndex = validTomIndecesData[y][2]
					  local padIndex = tomPadIndeces[normalizedTomPadIndex]
					  setPadIndex(midiNoteIndex, padIndex)
					  end
					end
				  break
				  end
				end
			  end
			end
		
		  if func == "debug_force_crashes" then
			if noteType == "crash" or noteType == "china" or noteType == "splash" or noteType == "stack" or noteType == "bell" then
			  local pad, padIndex = getPadFromType("crash")
			  setPadIndex(midiNoteIndex, padIndex)
			  end
			end
		  end
	  
		for midiNoteIndex=1, #midiNoteList do
		  attemptToSetPad(midiNoteIndex, "force_toms")
		  end
		for midiNoteIndex=1, #midiNoteList do
		  attemptToSetPad(midiNoteIndex, "force_required_pads")
		  end
		for midiNoteIndex=1, #midiNoteList do
		  attemptToSetPad(midiNoteIndex, "debug_force_crashes")
		  end
	  
		--populate chartNoteList, or throe error if missing pad indeces
		chartNoteList = {}
	   
		local masterList = {}
	  
		local function insertInMasterList(val, defaultVal)
		  if not val then
			if not defaultVal then
			  reaper.ShowConsoleMsg(index .. "\n")
			else
			  val = defaultVal
			  end
			end
		  tableInsert(masterList, val)
		  end
		
		local missingPadTable = {}
		for midiNoteIndex=1, #midiNoteList do
		  local noteLine = midiNoteList[midiNoteIndex]
		
		  local time = getValueFromKey(noteLine, "time")
		  local midiNoteNum = getValueFromKey(noteLine, "note")
		  local channel = getValueFromKey(noteLine, "channel")
		  local velocity = getValueFromKey(noteLine, "velocity")
		  local padIndex = getValueFromKey(noteLine, "pad")
		  local voiceIndex = getValueFromKey(noteLine, "voice")
		  local midiID = getValueFromKey(noteLine, "id")
		  local sustainID = getValueFromKey(noteLine, "sustain")
		
		  local stateLine = stateList[midiNoteNum+1][channel+1]
		  local noteType = getValueFromKey(stateLine, "type")
		  local noteState = getValueFromKey(stateLine, "state")
		  local notePedal = getValueFromKey(stateLine, "pedal")
		
		  if padIndex then
			insertInMasterList(time)
			insertInMasterList(velocity)
			insertInMasterList(getValueFromKey(padList[padIndex], "position"), -1)
		  
			local gem = noteType
			if noteType == "ride" and noteState == "bell" then
			  gem = "ride" --TODO: ride bell
			  end
			if noteState == "sidestick" or noteState == "rim" then
			  gem = noteType .. "_" .. noteState
			  end
			if noteState == "stomp" or noteState == "splash" then
			  gem = noteType .. "_pedal"
			  end
			insertInMasterList(gem)

			local color_r = getGemConfigProperty(gem, "color_r") * 255
			local color_g = getGemConfigProperty(gem, "color_g") * 255
			local color_b = getGemConfigProperty(gem, "color_b") * 255
			local color_a = getGemConfigProperty(gem, "color_a") * 255
			insertInMasterList(color_r)
			insertInMasterList(color_g)
			insertInMasterList(color_b)
			insertInMasterList(color_a)
		  
			local notation_color_r = getGemConfigProperty(gem, "notation_color_r")
			if not notation_color_r then
			  notation_color_r = color_r
			  end
			notation_color_r = notation_color_r * 255
			local notation_color_g = getGemConfigProperty(gem, "notation_color_g")
			if not notation_color_g then
			  notation_color_g = color_g
			  end
			notation_color_g = notation_color_g * 255
			local notation_color_b = getGemConfigProperty(gem, "notation_color_b")
			if not notation_color_b then
			  notation_color_b = color_b
			  end
			notation_color_b = notation_color_b * 255
			insertInMasterList(notation_color_r, color_r)
			insertInMasterList(notation_color_g, color_g)
			insertInMasterList(notation_color_b, color_b)
		  
			insertInMasterList(getGemConfigProperty(gem, "shiftx"), 0)
			insertInMasterList(getGemConfigProperty(gem, "shifty"), 0)
			insertInMasterList(getGemConfigProperty(gem, "scale"), 1)
			insertInMasterList(getGemConfigProperty(gem, "zorder"))
		  
			insertInMasterList(padIndex - 1)
		  
			local sustainLine
			if sustainID then
			  sustainLine = sustainLinesBothVoices[voiceIndex][sustainID+1]
			  end
			insertInMasterList(sustainLine, -1)
		  
			insertInMasterList(notePedal, -1)
		  
			insertInMasterList(midiID)
		  
		  else
			tableInsert(missingPadTable, noteType .. " (" .. noteState .. ") [" .. noteLine .. "]")
			end
		  end
	  
		if #missingPadTable > 0 then
		  reaper.ShowConsoleMsg("---MISSING PADS (" .. #missingPadTable .. ")---\n")
		  reaper.ShowConsoleMsg(table.concat(missingPadTable, "\n"))
		  throwError("Missing pads!")
		  end
	  
		--TODO: check for 2 of the same pad at the same time
	  
		local file = io.open(outputTextFilePath, "w+")
		local fileText = numLanes .. "\n" .. table.concat(masterList, "\n")
		file:write(fileText)
		file:close()
	  
		return fileText
		end
	
	-------------------MAIN FUNCTIONS--------------------
	
	if reaperProcessingCurrentMeasureIndex then
		gettingCurrentValues = true
		processMeasure(reaperProcessingCurrentMeasureIndex, true)
		gettingCurrentValues = false -- unnecessary?
		return
		end
		
	initializeGameData()
	
	storeImageSizesIntoMemory()
    
	storeTemposIntoMemory()
	
    defineNotationVariables()
    
    storeMIDITextFileIntoTables()
    
    storeConfigIntoMemory()

    storeEventsIntoMemory()
    
    storeMIDIIntoMemory()
	
    processNotationMeasures()
    
    uploadGameData()
	
	return convertToUserDrumKit()
	
	end

_G.runGodotReaperEnvironment = runGodotReaperEnvironment