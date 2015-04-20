{CompositeDisposable} = require 'atom'
{ConfigObserver} = require 'atom'

# Public: Event watch view element in status bar.
class EventWatchView extends HTMLDivElement

  # Public: Initialize event watch indicator element.
  initialize: (@statusBar) ->
    @classList.add('inline-block')
    @link = @createElement('a', 'event-watch', 'inline-block')
    @data = {}
    @refreshIntervalMiliseconds = 0
    @warnThresholdMiliseconds = 0
    @displayFormat = ''
    @eventFormat = /([0123456]{1,7})?\s*(\d+)(?::(\d\d))?\s*(am|pm)?/i
    @timer = null
    @hasWarning = false
    @tooltip = atom.tooltips.add(@link,
      title: => @tooltipTile()
      html: true
    )

  # Public: Attach view element to status bar and do initial setup.
  attach: ->
    @tile = @statusBar?.addLeftTile(item: this, priority: 200)
    @setup()
    @update()

  # Public: Destroys and removes this element.
  destroy: ->
    @clickSubscription?.dispose()
    @tooltip?.dispose()
    @tile?.destroy()
    @tile = null

  # Private: Sets up the event handlers.
  handleEvents: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'event-watch:update': => @update()

  # Private: Do all initial setup for view and configuration.
  setup: (interval) ->
    @setupLink()
    @data = atom.config.get('event-watch.data')
    refreshIntervalMinutes = @getConfig('event-watch.refreshIntervalMinutes', 5)
    @refreshIntervalMiliseconds = refreshIntervalMinutes * 60000
    warnThresholdMinutes = @getConfig('event-watch.warnThresholdMinutes', 3 * refreshIntervalMinutes)
    @warnThresholdMiliseconds = warnThresholdMinutes * 60000
    @displayFormat = @getConfig('event-watch.displayFormat', '$title: $time')
    if !interval
      interval = @refreshIntervalMiliseconds
    if @timer
      clearInterval(@timer)
    @timer = setInterval((=> @update()), interval)

  # Private: Do initial setup for the link element.
  setupLink: ->
    clickHandler = ->
      @update()
      return false
    @link.href = '#'
    @addEventListener('click', clickHandler)
    @clickSubscription = dispose: => @removeEventListener('click', clickHandler)
    @classList.add('inline-block') # necessiary to make this view visible
    @appendChild(@link)

  # Private: Tries to parse an event spec and return a Date object.
  parseTime: (timeStr, day) ->
    dt = day
    if !dt
      dt = new Date()
    time = timeStr.match(@eventFormat)
    if !time
      return NaN
    hour = parseInt(time[2], 10)
    minute = parseInt(time[3], 10) || 0
    ampm = time[4]
    am = (!ampm || ampm.toLowerCase() == 'am')
    pm = (!!ampm && ampm.toLowerCase() == 'pm')
    if hour == 12 && am
        hour = 0
    else if hour < 12 && pm
      hour = hour + 12
    dt.setHours(hour)
    dt.setMinutes(minute)
    dt.setSeconds(0, 0)
    return dt

  # Private: Tries to parse an event spec for a days of the week list.
  parseDays: (timeStr) ->
    time = timeStr.match(@eventFormat)
    if !time
      return ''
    return time[1]

  # Private: Returns time remaining string formatted as 'T-[D days] HH:MM'.
  formatTminus: (date) ->
    now = new Date()
    distance = date - now
    SECOND = 1000
    MINUTE = SECOND * 60
    HOUR = MINUTE * 60
    DAY = HOUR * 24
    days = distance // DAY
    hours = (distance % DAY) // HOUR
    minutes = (distance % HOUR) // MINUTE
    if minutes < 10
      minutes = "0#{minutes}"
    rvalue = "#{hours}:#{minutes}"
    if days > 0
      rvalue = "#{days}days " + rvalue
    rvalue = 'T-' + rvalue
    return rvalue

  # Private: Returns time string formatted as 'HH:MM[p]'.
  formatTime: (dt) ->
    hour = dt.getHours()
    minute = dt.getMinutes()
    pm = ''
    if hour >= 12
      pm = 'p'
      hour = hour - 12
    if minute < 10
      minute = "0#{minute}"
    return "#{hour}:#{minute}#{pm}"

  # Private: Create DOM element of given type with given classes.
  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add(classes...)
    return element

  # Private: Return next closest time from times to the current time, NaN otherwise.
  nextClosestTime: (currentDate, times) ->
    today = new Date()
    for time in times
      dt = @parseTime(time)
      days = @parseDays(time)
      if dt > currentDate && (!days || days.indexOf(today.getDay()) != -1)
        return dt

    # fallback to earliest time tomorrow
    tomorrow = new Date()
    tomorrow.setDate(tomorrow.getDate() + 1)
    if times.length
      dt = @parseTime(times[0], tomorrow)
      days = @parseDays(times[0])
      if !days || days.indexOf(tomorrow.getDay()) != -1
        return dt

    return NaN

  # Private: Grab given key from Atom config, or set it to fallback if not there.
  getConfig: (key, fallback) ->
    value = atom.config.get(key)
    if !value
      value = fallback
      atom.config.set(key, value)
    return value

  # Private: Return true iff given eventTime is within warning threshold from given fromTime.
  warnForTime: (eventTime, fromTime) ->
    return eventTime - fromTime <= @warnThresholdMiliseconds

  # Private: Generate an item for the tooltip.
  tooltipItem: (event) ->
    text = '$title: $time [$tminus]<br />'
      .replace(/\$title/g, event.title)
      .replace(/\$time/g, @formatTime(event.next))
      .replace(/\$tminus/g, @formatTminus(event.next))
    if event.warn
      text = "<b><font color='red'>#{text}</font></b>"
    return text

  # Private: Generate the content of the tooltip.
  tooltipTile: ->
    currentTime = new Date
    tip = ''
    for event in @getEvents(currentTime)
      tip += @tooltipItem(event)
      event.next = @nextClosestTime(event.next, event.times)
      event.warn = @warnForTime(event.next, currentTime)
      tip += @tooltipItem(event)
    return tip

  # Private: Returns event data based on the current date and time.
  # The event data is an array of objects with these properties:
  #   title: Title of this event.
  #          Zero length titles or titles starting with - are ignored.
  #   next:  Next occuring datetime of this event.
  #   warn:  True if this is within the warning threshold.
  getEvents: (fromTime) ->
    events = []
    if !fromTime
        fromTime = new Date
    for title, times of @data
      continue if !title.length or title[0] == '-'
      next = @nextClosestTime(fromTime, times)
      continue if !next
      events.push
        title: title
        times: times
        next: next
        warn: @warnForTime(next, fromTime)
    return events

  # Private: Refresh view with current event information.
  update: ->
    wasWarning = @hasWarning
    @hasWarning = false

    # remove existing widgets first
    while @link.firstChild
      @link.removeChild(@link.firstChild)

    # then generate new widgets
    currentDate = new Date
    for event in @getEvents()
      # apply display format
      text = @displayFormat.slice(0)
        .replace(/\$title/g, event.title)
        .replace(/\$time/g, @formatTime(event.next))
        .replace(/\$tminus/g, @formatTminus(event.next))

      # create and display widget element
      eventClasses = ['inline-block']
      if event.warn
        eventClasses.push('warn')
        @hasWarning = true
      widget = @createElement('span', eventClasses...)
      widget.textContent = text
      @link.appendChild(widget)

    if !wasWarning && @hasWarning
      @setup(60000) # 1 minute refresh during warnings
    else if wasWarning && !@hasWarning
      @setup()

module.exports = document.registerElement('event-watch',
                                          prototype: EventWatchView.prototype)
