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
    @tooltipDisplayFormat = atom.config.get('event-watch.tooltipDisplayFormat')
    @tooltipDetails = atom.config.get('event-watch.tooltipDetails')
    @sameDayTimeFormat = atom.config.get('event-watch.sameDayTimeFormat')
    @otherDayTimeFormat = atom.config.get('event-watch.otherDayTimeFormat')
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

  # Private: Returns humanized time remaining string.
  formatTminus: (dt) ->
    now = new Date()
    return moment.duration(dt - now).humanize()

  # Private: Returns time formatted time string.
  formatTime: (dt, fromTime) ->
    @sameDayTimeFormat = atom.config.get('event-watch.sameDayTimeFormat')
    @otherDayTimeFormat = atom.config.get('event-watch.otherDayTimeFormat')
    if dt.getDay() != fromTime.getDay()
      return moment(dt).format(@otherDayTimeFormat)
    return moment(dt).format(@sameDayTimeFormat)

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
        text = (@tooltipDisplayFormat + '<br />')
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
