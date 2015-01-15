{ConfigObserver} = require 'atom'

class EventWatchView extends HTMLElement

  # Create initial view state and element.
  initialize: (@statusBar, subscriptions) ->
    @view = @createElement('a', 'event-watch', 'inline-block')
    @data = {}
    @refreshIntervalMiliseconds = 0
    @warnThresholdMiliseconds = 0
    @displayFormat = ''
    @eventFormat = /([0123456]{1,7})?\s*(\d+)(?::(\d\d))?\s*(am|pm)?/i
    @timer = null
    @hasWarning = false
    @tooltip = atom.tooltips.add(@view,
      title: => @tooltipTile()
      html: true
    )
    subscriptions.add atom.commands.add 'atom-workspace', 'event-watch:update': => @update()

  # Destroys and removes this view.
  destroy: ->
    @clickSubscription?.dispose()
    @tooltip?.dispose()
    @remove()

  # Attach view element to status bar and do initial setup.
  attach: ->
    @statusBar?.addLeftTile(item: this, priority: 200) # far right side
    @setup()
    @update() # immediate initial update

  # Do all initial setup for view and configuration.
  setup: (interval) ->
    @setupView()

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

  # Do initial setup for this view.
  setupView: ->
    @view.href = '#'

    clickHandler = ->
      @update()
      return false

    @addEventListener('click', clickHandler)
    @clickSubscription = dispose: => @removeEventListener('click', clickHandler)

    @classList.add('inline-block') # necessiary to make this view visible
    @appendChild(@view)

  # Tries to parse an event spec and return a Date object.
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

  # Tries to parse an event spec for a days of the week list.
  parseDays: (timeStr) ->
    time = timeStr.match(@eventFormat)
    if !time
      return ''
    return time[1]

  # Returns time remaining string formatted as 'T-[D days] HH:MM'.
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
    # seconds = (distance % MINUTE) // SECOND

    if minutes < 10
      minutes = "0#{minutes}"

    rvalue = "#{hours}:#{minutes}"
    if days > 0
      rvalue = "#{days}days " + rvalue
    rvalue = 'T-' + rvalue
    return rvalue

  # Returns time string formatted as 'HH:MM[p]'.
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

  # Create DOM element of given type with given classes.
  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add(classes...)
    return element

  # Return next closest time from times to the current time, NaN otherwise.
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

  # Grab given key from Atom config, or set it to fallback if not there.
  getConfig: (key, fallback) ->
    value = atom.config.get(key)
    if !value
      value = fallback
      atom.config.set(key, value)
    return value

  # Generate the content of the tooltip.
  tooltipTile: ->
    tip = ''
    for event in @getEvents()
      text = '$title: $time [$tminus]<br />'
        .replace(/\$title/g, event.title)
        .replace(/\$time/g, @formatTime(event.next))
        .replace(/\$tminus/g, @formatTminus(event.next))
      if event.warn
        text = "<b><font color='red'>#{text}</font></b>"
      tip += text
    return tip

  # Returns event data based on the current date and time.
  # The event data is an array of objects with these properties:
  #   title: Title of this event.
  #   next:  Next occuring datetime of this event.
  #   warn:  True if this is within the warning threshold.
  getEvents: ->
    events = []
    currentDate = new Date
    for title, times of @data
      # ignore missing titles and those starting with -
      continue if !title.length or title[0] == '-'

      # find next closest recurring event time
      next = @nextClosestTime(currentDate, times)
      continue if !next

      events.push
        title: title
        next: next
        warn: next - currentDate <= @warnThresholdMiliseconds
    return events

  # Refresh view with current event information.
  update: ->
    # warning state
    wasWarning = @hasWarning
    @hasWarning = false

    # remove existing widgets first
    while @view.firstChild
      @view.removeChild(@view.firstChild)

    # generate widgets from events
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
      @view.appendChild(widget)

    if !wasWarning && @hasWarning
      @setup(60000) # 1 minute refresh during warnings
    else if wasWarning && !@hasWarning
      @setup()

module.exports = document.registerElement('event-watch',
                                          prototype: EventWatchView.prototype,
                                          extends: 'div')
