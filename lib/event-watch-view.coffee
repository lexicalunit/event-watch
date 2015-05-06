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
    atom.config.observe 'event-watch.displayFormat', => @updateConfig()
    atom.config.observe 'event-watch.refreshIntervalMinutes', => @updateConfig()
    atom.config.observe 'event-watch.warnThresholdMinutes', => @updateConfig()
    atom.config.observe 'event-watch.tooltipDisplayFormat', => @updateConfig()
    atom.config.observe 'event-watch.tooltipDetails', => @updateConfig()
    atom.config.observe 'event-watch.sameDayTimeFormat', => @updateConfig()
    atom.config.observe 'event-watch.otherDayTimeFormat', => @updateConfig()
    atom.config.observe 'event-watch.data', => @updateConfig()

  # Private: Sets up timeout for next update.
  # Use optional interval (in miliseconds) if given, otherwise use configuration setting.
  startTimer: (interval) ->
    if !interval
      interval = @refreshIntervalMinutes * 60000
    if @timer
      clearInterval(@timer)
    @timer = setInterval((=> @update()), interval)

  # Private: Grabs current configuration from atom config.
  updateConfig: ->
    @displayFormat = atom.config.get('event-watch.displayFormat')
    @refreshIntervalMinutes = atom.config.get('event-watch.refreshIntervalMinutes')
    @warnThresholdMinutes = atom.config.get('event-watch.warnThresholdMinutes')
    @tooltipDisplayFormat = atom.config.get('event-watch.tooltipDisplayFormat')
    @tooltipDetails = atom.config.get('event-watch.tooltipDetails')
    @sameDayTimeFormat = atom.config.get('event-watch.sameDayTimeFormat')
    @otherDayTimeFormat = atom.config.get('event-watch.otherDayTimeFormat')
    @data = atom.config.get('event-watch.data')

  # Private: Do initial setup, create the link element, etc.
  setup: ->
    @updateConfig()
    clickHandler = ->
      @update()
      return false
    @link.href = '#'
    @addEventListener('click', clickHandler)
    @clickSubscription = dispose: => @removeEventListener('click', clickHandler)
    @classList.add('inline-block') # necessiary to make this view visible
    @appendChild(@link)

  # Private: Returns humanized time remaining string.
  formatTminus: (dt, fromTime) ->
    return moment.duration(dt - fromTime).humanize()

  # Private: Returns time formatted time string.
  formatTime: (dt, fromTime) ->
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
    return eventTime - fromTime <= @warnThresholdMinutes * 60000

  # Private: Generate the content of the tooltip.
  tooltipTile: ->
    now = new Date
    tip = ''
    for title, times of @data
      event = later.parse.text(times)
      if event.error != -1
        console.log('error in schedule ' + title + ' at character ' + event.error)
        continue
      nexts = later.schedule(event).next(@tooltipDetails)
      for next in nexts
        text = (@tooltipDisplayFormat + '<br />')
          .replace(/\$title/g, title)
          .replace(/\$time/g, @formatTime(next, now))
          .replace(/\$tminus/g, @formatTminus(next, now))
        if @warnForTime(next, now)
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
    for title, times of @data
      event = later.parse.text(times)
      if event.error != -1
        console.log('error in schedule ' + title + ' at character ' + event.error)
        continue
      next = later.schedule(event).next(1)
      text = @displayFormat.slice(0)
        .replace(/\$title/g, title)
        .replace(/\$time/g, @formatTime(next, now))
        .replace(/\$tminus/g, @formatTminus(next, now))

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
