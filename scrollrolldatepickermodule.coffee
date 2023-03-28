############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("scrollrolldatepickermodule")
#endregion

############################################################
template = ""

############################################################
#region DOM Cache
inputElement = null
outerContainer = null
datepickerContainer = null

acceptButton = null

dayPicker = null
monthPicker = null
yearPicker = null

#endregion

############################################################
#region Day, Month and Year Values
allDayStrings = [
    "01"
    "02"
    "03"
    "04"
    "05"
    "06"
    "07"
    "08"
    "09"
    "10"
    "11"
    "12"
    "13"
    "14"
    "15"
    "16"
    "17"
    "18"
    "19"
    "20"
    "21"
    "22"
    "23"
    "24"
    "25"
    "26"
    "27"
    "28"
    "29"
    "30"
    "31"
]

############################################################
allMonthStrings = [
    "01"
    "02"
    "03"
    "04"
    "05"
    "06"
    "07"
    "08"
    "09"
    "10"
    "11"
    "12"
]

############################################################
currentYear = new Date().getFullYear()
oldestYear = currentYear - 150
allYears = [oldestYear..currentYear]

daysForMonth = [
    31, # jan
    28, # feb
    31, # mar
    30, # apr
    31, # may
    30, # jun
    31, # jul
    31, # aug
    30, # sep
    31, # oct
    30, # nov
    31 # dec
]

#endregion

############################################################
isInputElement = false
inputHeight = 0

############################################################
visibleElements = 0

############################################################
nexHeartbeat = () -> return

############################################################
export setUp = (id) ->
    inputElement = document.getElementById(id)
    isInputElement = (inputElement.tagName == "INPUT" or inputElement.tagName == "input")

    if isInputElement and inputElement.getAttribute("type") != "text"
        inputElement.setAttribute("type", "text")
        inputElement.setAttribute("placeholder", "dd.mm.yyyy")
        inputElement.setAttribute("readonly", "readonly")
    
    ## creating the container Elements
    outerContainer = document.createElement("div")
    datepickerContainer = document.createElement("div")
    calendarIcon = document.createElement("div")

    ## adding the expected classes
    inputElement.classList.add("scrollroll-input")
    outerContainer.classList.add("scrollroll-container")
    datepickerContainer.classList.add("scrollroll-datepicker-container")
    calendarIcon.classList.add("scrollroll-calendar")

    ## arrange the DOM 
    inputElement.replaceWith(outerContainer)
    outerContainer.append(inputElement)
    outerContainer.append(datepickerContainer)
    outerContainer.append(calendarIcon)

    ## inject the HTML
    template = scrollrolldatepickerHiddenTemplate.innerHTML
    datepickerContainer.innerHTML = template
    calendarIcon.innerHTML = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M19,19H5V8H19M16,1V3H8V1H6V3H5C3.89,3 3,3.89 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,3.89 20.1,3 19,3H18V1" /></svg>'

    ## further setup
    inputHeight = Math.ceil(inputElement.getBoundingClientRect().height)
    if inputHeight % 2 then inputHeight += 1
    log inputHeight
    outerContainer.style.setProperty("--scrollroll-input-height", "#{inputHeight}px")

    outerHeight = datepickerContainer.getBoundingClientRect().height
    log "outerHeight #{outerHeight}"    
    visibleElements = Math.ceil(outerHeight / (2 * inputHeight))
    log "visibleElements: #{visibleElements}"
    
    acceptButton = datepickerContainer.getElementsByClassName("scrollroll-accept-button")[0]

    dayPicker = datepickerContainer.getElementsByClassName("scrollroll-day-picker")[0]
    monthPicker = datepickerContainer.getElementsByClassName("scrollroll-month-picker")[0]
    yearPicker = datepickerContainer.getElementsByClassName("scrollroll-year-picker")[0]

    addDayElements(dayPicker)
    addMonthElements(monthPicker)
    addYearElements(yearPicker)

    yearPos = allYears.length - 43
    previousYearScroll = scrollFromPos(yearPos)
    yearPicker.scrollTo(0, previousYearScroll)
    
    monthPos = Math.ceil(allMonthStrings.length / 2) - 1
    previousMonthScroll = scrollFromPos(monthPos)
    monthPicker.scrollTo(0, previousMonthScroll)

    daysPos = Math.floor(allDayStrings.length / 2) - 1
    previousDayScroll = scrollFromPos(daysPos)
    dayPicker.scrollTo(0, previousDayScroll)

    inputElement.addEventListener("click", inputElementClicked)
    inputElement.addEventListener("focus", inputElementFocused)
    acceptButton.addEventListener("click", acceptButtonClicked)
    return

############################################################
inputElementFocused = (evnt) ->
    log "inputElementFocused"
    evnt.preventDefault()
    this.blur()
    return false

acceptButtonClicked = (evnt) ->
    log "acceptButtonClicked"
    day = allDayStrings[dayPos]
    month = allMonthStrings[monthPos]
    year = allYears[yearPos]

    date = "#{year}-#{month}-#{day}"
    inputValue = "#{day}.#{month}.#{year}"
    if isInputElement
        inputElement.value = inputValue
    else
        inputElement.innerText = inputValue
    # inputElement.value = date
    closeScrollRollDatepicker()
    return

inputElementClicked = (evnt) ->
    log "inputElementClicked"
    evnt.preventDefault()
    openScrollRollDatepicker()
    return false


closeScrollRollDatepicker = ->
    log "closeScrollRollDatepicker"
    if dayPos > (maxDays - 1) # invalid day
        dayElements[dayPos].style.color = "red"
        return
    datepickerContainer.classList.remove("shown")
    nexHeartbeat = () -> return
    return

openScrollRollDatepicker = ->
    log "openScrollRollDatepicker"
    datepickerContainer.classList.add("shown")

    nexHeartbeat = heartbeat
    requestAnimationFrame(nexHeartbeat)
    return

############################################################
#region adding scrollrollElements
dayElements = []

############################################################
addDayElements = (picker) ->
    log "addDayElements"
    html = "<div class='scrollroll-element-space'></div>"    
    for day in allDayStrings
        html += "<div class='scrollroll-element'>#{day}</div>"
    html += "<div class='scrollroll-element-space'></div>"
    picker.innerHTML = html

    dayElements = picker.getElementsByClassName("scrollroll-element")
    return

addMonthElements = (picker) ->
    log "addMonthElements" 
    html = "<div class='scrollroll-element-space'></div>"
    for month in allMonthStrings
        html += "<div class='scrollroll-element'>#{month}</div>"
    html += "<div class='scrollroll-element-space'></div>"
    picker.innerHTML = html
    return

addYearElements = (picker) ->
    log "addYearElements"
    html = "<div class='scrollroll-element-space'></div>"
    for year in allYears
        html += "<div class='scrollroll-element'>#{year}</div>"
    html += "<div class='scrollroll-element-space'></div>"
    picker.innerHTML = html
    return

#endregion

############################################################
heartbeat = ->
    # log "heartbeat"
    checkDayScroll()
    checkMonthScroll()
    checkYearScroll()
    adjustMaxDays()

    # setTimeout(heartbeat, 1000)
    requestAnimationFrame(nexHeartbeat)
    return

############################################################
previousDayScroll = 0
dayPos = 0
maxDays = 31

############################################################
checkDayScroll = ->
    # log "checkDayScroll"
    currentScroll = dayPicker.scrollTop 
    posScroll = scrollFromPos(dayPos)
    
    log "scroll:  #{currentScroll}"
    log "pos: #{dayPos}"
    log "posSCroll: #{posScroll}"

    ## when scroll did not change and we we are not on our valid scroll position
    if previousDayScroll == currentScroll and currentScroll != posScroll
        # then we snap to the next valid scroll position
        dayPos = posFromScroll(currentScroll)
        if dayPos > (maxDays - 1) then dayPos = maxDays - 1
        currentScroll = scrollFromPos(dayPos)
        dayPicker.scrollTo(0, currentScroll)
        for pos in [28..30] 
            dayElements[pos].style.removeProperty("color")

    previousDayScroll = currentScroll
    return

############################################################
previousMonthScroll = 0
monthPos = 0

############################################################
checkMonthScroll = ->
    # log "checkMonthScroll"
    currentScroll = monthPicker.scrollTop 
    
    # log "scroll:  #{currentScroll}"
    # log "pos: #{montallDayElhPos}"

    posScroll = scrollFromPos(monthPos)
    ## when scroll did not change and we we are not on our valid scroll position
    if previousMonthScroll == currentScroll and currentScroll != posScroll
        # then we snap to the next valid scroll position
        monthPos = posFromScroll(currentScroll)
        if monthPos > 11 then monthPos = 11 # 11 is last position
        currentScroll = scrollFromPos(monthPos)
        monthPicker.scrollTo(0, currentScroll)

    previousMonthScroll = currentScroll
    return

############################################################
adjustMaxDays = ->
    # log "adjustMaxDays"
    maxDays = daysForMonth[monthPos]

    if !(allYears[yearPos] % 4) and (maxDays == 28) then maxDays++ # leap year
    
    for pos in [28..30]
        dayElements[pos].style.removeProperty("color")
        if maxDays <= pos then dayElements[pos].style.opacity = "0.5"
        else dayElements[pos].style.removeProperty("opacity")
    return

############################################################
previousYearScroll = 0
yearPos = 0

############################################################
checkYearScroll = ->
    # log "checkYearScroll"
    currentScroll = yearPicker.scrollTop 
    
    # log "scroll:  #{currentScroll}"
    # log "pos: #{yearPos}"

    posScroll = scrollFromPos(yearPos)
    ## when scroll did not change and we we are not on our valid scroll position
    if previousYearScroll == currentScroll and currentScroll != posScroll
        # then we snap to the next valid scroll position
        yearPos = posFromScroll(currentScroll)
        if yearPos > 150 then yearPos = 150 # 150 is last position
        currentScroll = scrollFromPos(yearPos)
        yearPicker.scrollTo(0, currentScroll)

    previousYearScroll = currentScroll
    return

############################################################
scrollFromPos = (pos) -> (inputHeight / 2) + (pos * inputHeight)
posFromScroll = (scroll) -> (scroll - ( scroll % inputHeight)) / inputHeight 