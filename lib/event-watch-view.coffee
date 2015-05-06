{CompositeDisposable, ConfigObserver} = require 'atom'
later = require 'later'
moment = require 'moment'

# Public: Event watch view element in status bar.
class EventWatchView extends HTMLDivElement

  # Public: Initialize event watch indicator element.
  initialize: (@statusBar) ->
    later.date.localTime()
    @classList.add('inline-block')
    @link = @createElement('a', 'event-watch', 'inline-block')
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
    @startTimer()
    @update()
    @handleEvents()

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

  # Private: Sets up timeout for next update.
  # Use optional interval if given, otherwise use configuration setting.
  startTimer: (interval) ->
    # TODO: add observers for these settings
    refreshIntervalMinutes = atom.config.get('event-watch.refreshIntervalMinutes')
    @refreshIntervalMiliseconds = refreshIntervalMinutes * 60000
    warnThresholdMinutes = atom.config.get('event-watch.warnThresholdMinutes')
    @warnThresholdMiliseconds = warnThresholdMinutes * 60000
    @displayFormat = atom.config.get('event-watch.displayFormat')
    @tooltipFormat = atom.config.get('event-watch.tooltipFormat')
    @tooltipDetails = atom.config.get('event-watch.tooltipDetails')
    if !interval
      interval = @refreshIntervalMiliseconds
    if @timer
      clearInterval(@timer)
    @timer = setInterval((=> @update()), interval)

  # Private: Do initial setup for the link element.
  setup: ->
    clickHandler = ->
      @update()
      return false
    @link.href = '#'
    @addEventListener('click', clickHandler)
    @clickSubscription = dispose: => @removeEventListener('click', clickHandler)
    @classList.add('inline-block') # necessiary to make this view visible
    @appendChild(@link)

  # Private: Returns time remaining string formatted as 'T-[D days] HH:MM'.
  # D days is only included if date given is more than a day away.
  formatTminus: (dt) ->
    now = new Date()
    distance = dt - now
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

  # Private: Returns time string formatted as '[Day] HH:MM[p]'.
  # Day is only included if date given is not today, and p indicates pm.
  formatTime: (dt, fromTime) ->
    hour = dt.getHours()
    minute = dt.getMinutes()
    day = ''
    pm = ''
    if hour >= 12
      pm = 'p'
      hour = hour - 12
    if minute < 10
      minute = "0#{minute}"
    if dt.getDay() != fromTime.getDay()
      day = moment(dt).format('ddd') + ' '
    return "#{day}#{hour}:#{minute}#{pm}"

  # Private: Create DOM element of given type with given classes.
  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add(classes...)
    return element

  # Private: Return true iff given eventTime is within warning threshold from given fromTime.
  warnForTime: (eventTime, fromTime) ->
    return eventTime - fromTime <= @warnThresholdMiliseconds

  # Private: Generate the content of the tooltip.
  tooltipTile: ->
    currentTime = new Date
    tip = ''
    for title, times of @data
      event = later.parse.text(times)
      nexts = later.schedule(event).next(@tooltipDetails)
      for next in nexts
        text = (@tooltipFormat + '<br />')
          .replace(/\$title/g, title)
          .replace(/\$time/g, @formatTime(next, currentTime))
          .replace(/\$tminus/g, @formatTminus(next))
        if @warnForTime(next, currentTime)
          text = "<b><font color='red'>#{text}</font></b>"
        tip += text
    return tip

  # Private: Refresh view with current event information.
  update: ->
    now = new Date
    wasWarning = @hasWarning
    @hasWarning = false

    # remove existing widgets first
    while @link.firstChild
      @link.removeChild(@link.firstChild)

    # then generate new widgets
    # TODO: Get this once, then set up an observer
    @data = atom.config.get('event-watch.data')
    for title, times of @data
      event = later.parse.text(times)
      next = later.schedule(event).next(1)
      text = @displayFormat.slice(0)
        .replace(/\$title/g, title)
        .replace(/\$time/g, @formatTime(next, now))
        .replace(/\$tminus/g, @formatTminus(next))

      # create and display widget element
      eventClasses = ['inline-block']
      if @warnForTime(next, now)
        eventClasses.push('warn')
        @hasWarning = true
      widget = @createElement('span', eventClasses...)
      widget.textContent = text
      @link.appendChild(widget)

    if !wasWarning && @hasWarning
      @startTimer(60000) # 1 minute refresh during warnings
    else if wasWarning && !@hasWarning
      @startTimer()

module.exports = document.registerElement('event-watch',
                                          prototype: EventWatchView.prototype)
