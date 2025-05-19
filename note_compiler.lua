function runCompiler(gamedataFileText, drumkitFileText, gemNameTable, configTextTable, outputTextFilePath)
	local gemConfigList = {}
	
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
	  
	local function getGemConfigProperty(gem, property)
	  local index = exactBinarySearch(gemConfigList, gem, 1)
	  local subTable = gemConfigList[index]
	  for x=2, #subTable do
		if subTable[x][1] == property then
		  return subTable[x][2]
		  end
		end
	  end
  
    local function trimTrailingSpaces(s)
	  return s:gsub("%s+$", "")
	  end

	local function separateString(str)
	  local list = {}
	  while true do
		local quotes = (string.sub(str, 1, 1) == "\"")
		
		local i
		if quotes then
		  i = string.find(str, "\" ", 2)
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
		  
		if quotes then
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

--------------------------------------------------------------

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
	print(outputTextFilePath)
  local file = io.open(outputTextFilePath, "w+")
  file:write(numLanes .. "\n" .. table.concat(masterList, "\n"))
  file:close()
  
  return {numLanes, timeList, velocityList, positionList, gemList, colorRList, colorGList, colorBList, colorAList, shiftXList, shiftYList, scaleList, zIndexList, padIndexList, sustainLineList, pedalList}
  end

_G.runCompiler = runCompiler