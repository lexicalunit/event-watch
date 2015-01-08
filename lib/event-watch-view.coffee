{ConfigObserver} = require 'atom'

class EventWatchView extends HTMLElement

  # Create initial view state and element.
  initialize: (@statusBar) ->
    @classList.add('inline-block') # necessiary to make this view visible
    @view = @createElement('div', 'event-watch', 'inline-block')
    @data = {}
    @refreshIntervalMiliseconds = 0
    @warnThresholdMiliseconds = 0
    @displayFormat = ''

  # Attach view element to status bar and do initial setup.
  attach: ->
    @statusBar?.addLeftTile(item: this, priority: 200) # far right side
    @setup()

  # Do initial setup steps for view, such as configuration and update.
  setup: ->
    @appendChild(@view)

    @data = atom.config.get('event-watch.data')

    refreshIntervalMinutes = @getConfig('event-watch.refreshIntervalMinutes', 5)
    @refreshIntervalMiliseconds = refreshIntervalMinutes * 60000

    warnThresholdMinutes = @getConfig('event-watch.warnThresholdMinutes', 3 * refreshIntervalMinutes)
    @warnThresholdMiliseconds = warnThresholdMinutes * 60000

    @displayFormat = @getConfig('event-watch.displayFormat', '$title: $time')

    @update() # immediate initial update
    setInterval((=> @update()), @refreshIntervalMiliseconds)

  # Tries to parse a time string and return a Date object.
  parseTime: (timeStr) ->
    time = timeStr.match(/(\d+)(?::(\d\d))?\s*(p?)/i)
    if !time
      return NaN

    hours = parseInt(time[1], 10)
    if hours == 12 && !time[3]
        hours = 0
    else
      hours += (hours < 12 && time[3]) ? 12 : 0

    dt = new Date()
    dt.setHours(hours)
    dt.setMinutes(parseInt(time[2], 10) || 0)
    dt.setSeconds(0, 0)
    return dt

  # Returns time string formatted as HH:MM[p].
  formatTime: (date) ->
    hour = date.getHours()
    minute = date.getMinutes()
    pm = '';
    if hour >= 12
      pm = 'p';
      hour = hour - 12;
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
    for time in times
      dt = @parseTime(time)
      if dt > currentDate
        return dt
    return NaN

  # Grab given key from Atom config, or set it to fallback if not there.
  getConfig: (key, fallback) ->
    value = atom.config.get(key)
    if !value
      value = fallback
      atom.config.set(key, value)
    return value

  # Refresh view with current event information.
  update: ->
    currentDate = new Date
    events = []

    for title, times of @data
      # ignore missing titles and those starting with -
      if !title.length or title[0] == '-'
        continue

      # find next closest recurring event time
      next = @nextClosestTime(currentDate, times)
      if !next
        continue

      # apply display format
      text = @displayFormat.slice(0)
        .replace(/\$time/g, @formatTime(next))
        .replace(/\$title/g, title)

      # create event view element
      eventClasses = ['inline-block']
      if next - currentDate <= @warnThresholdMiliseconds
        eventClasses.push('warn')
      event = @createElement('span', eventClasses...)
      event.textContent = text

      events.push(event)

    # remove existing view elements first
    while @view.firstChild
      @view.removeChild(@view.firstChild)

    for event in events
      @view.appendChild(event)

module.exports = document.registerElement('event-watch',
                                          prototype: EventWatchView.prototype,
                                          extends: 'div')
