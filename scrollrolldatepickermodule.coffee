############################################################
#region debug
import { createLogFunctions } from "thingy-debug"
{log, olog} = createLogFunctions("scrollrolldatepickermodule")
#endregion

############################################################
## TODO change the way how we build the basic datepicker
#  - adjustable formate of ddmmyyyy
#  - adjustable separator
template = document.getElementById("scrollrolldatepicker-hidden-template").innerHTML

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
defaultOptions =  {
    format: "dmy" # not used currently
    separator: "." # not used currently
    yearRange: "125" # "X" years backwards or "YYYY-YYYY"
    height: "auto" # "auto" takes height of element | "X" height in px 
    width: "auto" # not used currently
    dayPos: 14 # position index of day array 0 -> 01 ... 30 -> 31
    monthPos: 6 # position index of month array 0 -> 01 ... 11 -> 12
    yearPos: "middle" # position index of year | specific year in Range | "start", "middle" or "end"
}

############################################################
export class ScrollRollDatepicker
    constructor: (o) -> setOptions(this, o)

    ########################################################
    initialize: ->
        checkElement(this)
        digestOptions(this)

        adjustHTML(this)
        setPickerPositions(this)
        adjustMaxDays(this)
        # outerHeight = datepickerContainer.getBoundingClientRect().height
        # log "outerHeight #{outerHeight}"    
        # visibleElements = Math.ceil(outerHeight / (2 * inputHeight))
        # log "visibleElements: #{visibleElements}"

        attachEventListeners(this)
        return

    ########################################################
    heartbeat: ->
        # log "heartbeat"
        checkDayScroll(this)
        checkMonthScroll(this)
        checkYearScroll(this)
        adjustMaxDays(this)

        # setTimeout(@nexHeartbeat, 1000) ## slower debug heartbeat
        requestAnimationFrame(@nexHeartbeat)
        return

    ########################################################
    reset: ->
        @value = ""
        setPickerPositions(this)
        @datepickerContainer.classList.remove("shown")
        @nexHeartbeat = () -> return
        return

    ########################################################
    destroy: ->
        ## TODO implement
        # restoreHTML(this)
        return

############################################################
#region initialization functions

############################################################
checkElement = (I) -> # I is the instance
    log "checkElement"
    if typeof I.element == "string" then I.element = document.getElementById(I.element)
    if !isConnectedElement(I.element) then throw new Error("Provided Element is not a connected DOM Element!")

    I.isInputElement = (I.element.tagName == "INPUT" or I.element.tagName == "input")

    sanitizeElement(I)
    return

sanitizeElement = (I) -> # I is the instance
    log "sanitizeElement"
    # We cannot use a real Date input thanks to fkn Apple
    if I.isInputElement and I.element.getAttribute("type") != "text"
        I.element.setAttribute("type", "text")
        I.element.setAttribute("placeholder", "dd.mm.yyyy")
        I.element.setAttribute("readonly", "readonly")
    return

############################################################
digestOptions = (I) -> # I is the instance
    log "digestOptions"
    ## digest format TODO

    ## digest height
    if I.height == "auto"
        I.height = Math.ceil(I.element.getBoundingClientRect().height)
        if I.height % 2 then I.height++
        log I.height

    ## digest width TODO

    ## digest yearRange
    tokens = I.yearRange.split("-")
    if tokens.length == 1
        endYear = new Date().getFullYear()
        range = parseInt(tokens[0])
        startYear = endYear - range
        I.allYears = [startYear..endYear]
    if tokens.length == 2
        startYear = parseInt(tokens[0])
        endYear = parseInt(tokens[0])
        I.allYears = [startYear..endYear]
    
    rangeLength = endYear - startYear
    
    ## digest yearPos
    switch I.yearPos
        when "start" then I.yearPos = 0
        when "middle" then I.yearPos = Math.floor(rangeLength / 2 )
        when "end" then I.yearPos = rangeLength
        else
            I.yearPos = parseInt(I.yearPos)
            if isNan(I.yearPos) then throw new Error("Invalid yearPos provided!")
            if I.yearPos <= endYear and I.yearPos >= startYear
                I.yearPos = I.yearPos - startYear
            else if I.yearPos > rangeLength then I.yearPos = rangeLength
            else if I.yearPos < 0 then I.yearPos = 0
    return

############################################################
adjustHTML = (I) -> # I is the instance
    log "adjustHTML"
    ## creating the container Elements
    I.outerContainer = document.createElement("div")
    I.datepickerContainer = document.createElement("div")
    calendarIcon = document.createElement("div")

    ## add specific styles
    I.outerContainer.style.setProperty("--scrollroll-input-height", "#{I.height}px")
    # I.outerContainer.style.setProperty("--scrollroll-input-width", "#{I.width}px")

    ## adding the expected classes
    I.element.classList.add("scrollroll-input")
    I.outerContainer.classList.add("scrollroll-container")
    I.datepickerContainer.classList.add("scrollroll-datepicker-container")
    calendarIcon.classList.add("scrollroll-calendar")

    ## arrange the DOM 
    I.element.replaceWith(I.outerContainer)
    I.outerContainer.append(I.element)
    I.outerContainer.append(I.datepickerContainer)
    I.outerContainer.append(calendarIcon)

    ## inject the HTML
    I.datepickerContainer.innerHTML = template
    calendarIcon.innerHTML = '<svg viewBox="0 0 24 24"><path fill="currentColor" d="M19,19H5V8H19M16,1V3H8V1H6V3H5C3.89,3 3,3.89 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,3.89 20.1,3 19,3H18V1" /></svg>'

    ## cache used DOM Elements
    I.acceptButton = I.datepickerContainer.getElementsByClassName("scrollroll-accept-button")[0]

    I.dayPicker = I.datepickerContainer.getElementsByClassName("scrollroll-day-picker")[0]
    I.monthPicker = I.datepickerContainer.getElementsByClassName("scrollroll-month-picker")[0]
    I.yearPicker = I.datepickerContainer.getElementsByClassName("scrollroll-year-picker")[0]

    ## Adding Elements to the picker
    addDayElements(I.dayPicker)
    addMonthElements(I.monthPicker)
    addYearElements(I.yearPicker, I.allYears)

    I.dayElements = I.dayPicker.getElementsByClassName("scrollroll-element")
    return

setPickerPositions = (I) -> # I is the instance
    log "setInitialPositions"
    I.previousYearScroll = scrollFromPos(I.yearPos, I.height)
    I.yearPicker.scrollTo(0, I.previousYearScroll)
    
    I.previousMonthScroll = scrollFromPos(I.monthPos, I.height)
    I.monthPicker.scrollTo(0, I.previousMonthScroll)

    I.previousDayScroll = scrollFromPos(I.dayPos, I.height)
    I.dayPicker.scrollTo(0, I.previousDayScroll)
    return

adjustMaxDays = (I) -> # I is the instance
    # log "adjustMaxDays"
    I.maxDays = daysForMonth[I.monthPos]

    if !(I.allYears[I.yearPos] % 4) and (I.maxDays == 28) then I.maxDays++ # leap year
    
    for pos in [28..30]
        if I.maxDays <= pos then I.dayElements[pos].style.opacity = "0.5"
        else I.dayElements[pos].style.removeProperty("opacity")
    return

############################################################
attachEventListeners = (I) -> # I is the instance
    log "attachEventListeners"    
    I.element.addEventListener("click", (evnt) -> inputElementClicked(evnt, I))
    I.element.addEventListener("focus", (evnt) -> inputElementFocused(evnt, I))
    I.acceptButton.addEventListener("click", (evnt) -> acceptButtonClicked(evnt, I))
    return

#endregion

############################################################
#region heartbeat functions

checkDayScroll = (I) ->
    # log "checkDayScroll"
    scroll = I.dayPicker.scrollTop 
    posScroll = scrollFromPos(I.dayPos, I.height)
    
    # log "scroll:  #{scroll}"
    # log "pos: #{I.dayPos}"
    # log "posSCroll: #{posScroll}"

    ## when scroll did not change and we we are not on our valid scroll position
    if I.previousDayScroll == scroll and scroll != posScroll
        # then we snap to the next valid scroll position
        I.dayPos = posFromScroll(scroll, I.height)
        if I.dayPos > (I.maxDays - 1) then I.dayPos = I.maxDays - 1
        scroll = scrollFromPos(I.dayPos, I.height)
        I.dayPicker.scrollTo(0, scroll)
        ## this is a hack - being exact this should be done on every change of the UI
        resetImpossibleDayColor(I)

    I.previousDayScroll = scroll
    return

checkMonthScroll = (I) ->
    # log "checkMonthScroll"

    scroll = I.monthPicker.scrollTop 
    posScroll = scrollFromPos(I.monthPos, I.height)
    
    # log "scroll:  #{scroll}"
    # log "pos: #{I.monthPos}"
    # log "posSCroll: #{posScroll}"

    ## when scroll did not change and we we are not on our valid scroll position
    if I.previousMonthScroll == scroll and scroll != posScroll
        # then we snap to the next valid scroll position
        I.monthPos = posFromScroll(scroll, I.height)
        if I.monthPos > 11 then I.monthPos = 11 # 11 is last position
        scroll = scrollFromPos(I.monthPos, I.height)
        I.monthPicker.scrollTo(0, scroll)
        ## this is a hack - being exact this should be done on every change of the UI
        resetImpossibleDayColor(I)

    I.previousMonthScroll = scroll
    return

checkYearScroll = (I) ->
    # log "checkYearScroll"
    scroll = I.yearPicker.scrollTop 
    posScroll = scrollFromPos(I.yearPos, I.height)
    
    # log "scroll:  #{currentScroll}"
    # log "pos: #{I.yearPos}"
    # log "posSCroll: #{posScroll}"

    ## when scroll did not change and we we are not on our valid scroll position
    if I.previousYearScroll == scroll and scroll != posScroll
        # then we snap to the next valid scroll position
        I.yearPos = posFromScroll(scroll, I.height)
        if I.yearPos >= I.allYears.length then I.yearPos = I.allYears.length - 1
        scroll = scrollFromPos(I.yearPos, I.height)
        I.yearPicker.scrollTo(0, scroll)
        ## this is a hack - being exact this should be done on every change of the UI
        resetImpossibleDayColor(I)

    I.previousYearScroll = scroll
    return

#endregion

############################################################
#region event Listeners

############################################################
inputElementClicked = (evnt, I) ->
    log "inputElementClicked"
    evnt.preventDefault()
    openScrollRollDatepicker(I)
    return false

############################################################
inputElementFocused = (evnt, I) ->
    log "inputElementFocused"
    evnt.preventDefault()
    evnt.target.blur()
    return false

############################################################
acceptButtonClicked = (evnt, I) ->
    log "acceptButtonClicked"

    if I.dayPos > (I.maxDays - 1) # mark imposslble day
        I.dayElements[I.dayPos].style.color = "red"
        I.dayElements[I.dayPos].style.fontWeight = "bold"
        return

    day = allDayStrings[I.dayPos]
    month = allMonthStrings[I.monthPos]
    year = I.allYears[I.yearPos]

    date = "#{year}-#{month}-#{day}"
    inputValue = "#{day}.#{month}.#{year}"
    if I.isInputElement
        I.element.value = inputValue
    else
        I.element.innerText = inputValue
    I.value = date

    closeScrollRollDatepicker(I)
    return

#endregion

############################################################
#region helper functions

############################################################
#region adding scrollrollElements

addDayElements = (picker) ->
    log "addDayElements"
    html = "<div class='scrollroll-element-space'></div>"    
    for day in allDayStrings
        html += "<div class='scrollroll-element'>#{day}</div>"
    html += "<div class='scrollroll-element-space'></div>"
    picker.innerHTML = html
    return

addMonthElements = (picker) ->
    log "addMonthElements" 
    html = "<div class='scrollroll-element-space'></div>"
    for month in allMonthStrings
        html += "<div class='scrollroll-element'>#{month}</div>"
    html += "<div class='scrollroll-element-space'></div>"
    picker.innerHTML = html
    return

addYearElements = (picker, allYears) ->
    log "addYearElements"
    html = "<div class='scrollroll-element-space'></div>"
    for year in allYears
        html += "<div class='scrollroll-element'>#{year}</div>"
    html += "<div class='scrollroll-element-space'></div>"
    picker.innerHTML = html
    return

#endregion

resetImpossibleDayColor = (I) ->
    for pos in [28..30]
        I.dayElements[pos].style.removeProperty("color")
        I.dayElements[pos].style.removeProperty("font-weight")
    return

############################################################
closeScrollRollDatepicker = (I) ->
    log "closeScrollRollDatepicker"
    I.outerContainer.classList.remove("shown")

    I.nexHeartbeat = () -> return
    return

openScrollRollDatepicker = (I) ->
    log "openScrollRollDatepicker"
    I.outerContainer.classList.add("shown")

    I.nexHeartbeat = I.heartbeat.bind(I)
    requestAnimationFrame(I.nexHeartbeat)
    return

############################################################
scrollFromPos = (pos, height) -> (height / 2) + (pos * height)
posFromScroll = (scroll, height) -> (scroll - ( scroll % height)) / height 

############################################################
isConnectedElement = (el) ->
    if typeof HTMLElement == "object"
        return el instanceof HTMLElement and el.isConnected
    else
        return el? and el.nodeType == 1 and el.isConnected
    return

############################################################
setOptions = (I, options) ->
    Object.assign(I, defaultOptions)
    Object.assign(I, options)
    return

#endregion


