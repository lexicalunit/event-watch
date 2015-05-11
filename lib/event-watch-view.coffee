{CompositeDisposable} = require 'atom'
later = require 'later'
moment = require 'moment'

# Public: Event watch view element in status bar.
class EventWatchView extends HTMLDivElement

  # Public: Initialize event watch indicator element.
  initialize: (@statusBar) ->
    later.date.localTime()
    @classList.add('inline-block')
    @hasWarning = false
    @visible = true
    @timer = null

  # Public: Attach view element to status bar and do initial setup.
  attach: ->
    @updateConfig()
    @buildWidget()
    @handleEvents()

  # Public: Destroys and removes this element.
  destroy: ->
    @destroyWidget()
    @subscriptions?.dispose()

  # Public: Returns humanized remaining time string.
  formatTminus: (dt, fromTime) ->
    return moment.duration(dt - fromTime).humanize()

  # Public: Returns formatted time string.
  formatTime: (dt, fromTime) ->
    if dt.getDay() != fromTime.getDay()
      return moment(dt).format(@otherDayTimeFormat)
    return moment(dt).format(@sameDayTimeFormat)

  # Public: Return true iff given eventTime is within warning threshold from given fromTime.
  isPastWarningTime: (eventTime, fromTime) ->
    return eventTime - fromTime <= @warnThresholdMinutes * 60000

  # Public: Returns count events with text formatted according to given display format.
  # Return value is array of events objects like:
  #   {
  #     displayText: string; formatted event text.
  #     isWarning: boolean; true iff event meets warning threshold.
  #   }
  getEvents: (count, format, fromTime) ->
    events = []
    for title, textSchedule of @data
      if typeof textSchedule isnt 'string'
        @warnAboutSchedule(title, 'Schedule is not a String.')
        continue
      schedule = later.parse.text(textSchedule)
      if schedule.error != -1
        @warnAboutSchedule(title, 'Parse failure at character ' + schedule.error + '.')
        continue
      nexts = later.schedule(schedule).next(count)
      nexts = [nexts] if count == 1
      for next in nexts
        text = format.slice(0)
          .replace(/\$title/g, title)
          .replace(/\$time/g, @formatTime(next, fromTime))
          .replace(/\$tminus/g, @formatTminus(next, fromTime))
        events.push
          displayText: text
          isWarning: @isPastWarningTime(next, fromTime)
    return events

  # Private: Warn the user about an issue with the schedule with the given title.
  warnAboutSchedule: (title, detail) ->
    atom.notifications.addWarning 'event-watch: Issue with schedule "' + title + '"',
      detail: detail

  # Private: Destroies the widget elements.
  destroyWidget: ->
    @stopTimer()
    @clickSubscription?.dispose()
    @tooltip?.dispose()
    while @firstChild
      @removeChild(@firstChild)
    @tile?.destroy()
    @tile = null

  # Private: Builds and attaches view element to status bar.
  buildWidget: ->
    @tile = @statusBar?.addLeftTile(item: this, priority: 200)
    @setupLink()
    @startTimer()
    @update()

  # Private: Do inital setup for and create link element.
  setupLink: ->
    @link = @createElement('a', 'event-watch', 'inline-block')
    clickHandler = ->
      @update()
      return false
    @link.href = '#'
    @addEventListener('click', clickHandler)
    @clickSubscription = dispose: => @removeEventListener('click', clickHandler)
    @appendChild(@link)
    @tooltip = atom.tooltips.add @link,
      title: => @tooltipTitle()
      html: true

  # Private: Sets up the event handlers.
  handleEvents: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'event-watch:update': => @update()
    @subscriptions.add atom.commands.add 'atom-workspace', 'event-watch:toggle': => @toggle()
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
    interval = @refreshIntervalMinutes * 60000 if !interval
    if @timer
      clearInterval(@timer)
    @timer = setInterval((=> @update()), interval)

  # Private: Stops timeout for next update.
  stopTimer: ->
    clearInterval(@timer)

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

  # Private: Create DOM element of given type with given classes.
  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add(classes...)
    return element

  # Private: Generate the content of the tooltip.
  tooltipTitle: ->
    now = new Date
    tip = ''
    for event in @getEvents(@tooltipDetails, @tooltipDisplayFormat + '<br />', now)
      text = event.displayText
      text = "<b><font color='red'>#{text}</font></b>" if event.isWarning
      tip += text
    return tip

  # Private: Toggles on or off the event-watch widget.
  toggle: ->
    @visible = !@visible
    if @visible
      @buildWidget()
    else
      @destroyWidget()

  # Private: Removes all elements in main link widget.
  removeEvents: ->
    while @link.firstChild
      @link.removeChild(@link.firstChild)

  # Private: Displays events in stasus bar.
  # Return true iff a displayed event is within warning threshold.
  displayEvents: ->
    now = new Date
    hasWarning = false
    for event in @getEvents(1, @displayFormat, now)
      eventClasses = ['inline-block']
      if event.isWarning
        eventClasses.push('warn')
        hasWarning = true
      widget = @createElement('span', eventClasses...)
      widget.textContent = event.displayText
      @link.appendChild(widget)
    return hasWarning

  # Private: Refresh view with current event information.
  update: ->
    return if !@visible
    wasWarning = @hasWarning
    @removeEvents()
    @hasWarning = @displayEvents()
    if !wasWarning && @hasWarning
      @startTimer(60000) # 1 minute refresh during warnings
    else if wasWarning && !@hasWarning
      @startTimer()

module.exports = document.registerElement('event-watch',
                                          prototype: EventWatchView.prototype)
