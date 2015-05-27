{CompositeDisposable} = require 'atom'
{View}  = require 'atom-space-pen-views'
CSON = require 'season'
fs = require 'fs-plus'
later = require 'later'
moment = require 'moment'

PREFIX = 'event-watch'

# Public: Event watch element in status bar.
module.exports =
class EventWatchElement extends View
  @content: ->
    @div class:"#{PREFIX} inline-block", ->

  # Public: Initialize event watch indicator element.
  initialize: (configSpec, @statusBar) ->
    later.date.localTime()
    @config =                   # cache for package config values
      spec: configSpec
      schedules: {}
      subscriptions: []
    @disposables = []           # CompositeDisposable objects
    @hasWarning = false         # true iff any warning being displayed
    @overrideDatetime = false   # if a Date object, use as current time
    @parsedSchedules = {}       # parsed schedules { title: schedule, ...}
    @parsedSubscriptions = {}   # parsed subscriptions { title: schedule, ...}
    @tile = null                # status-bar tile element
    @timer = null               # timeout handler object
    @tooltip = null             # disposable tooltip object
    @tooltipTitle = ''          # cached tooltip title
    @visible = true             # true iff widget is toggled visible
    @attach()
    this

  # Public: Attach element to status bar and do initial setup.
  attach: ->
    @buildWidget()
    @handleEvents()
    @startTimer()
    @update()

  # Public: Destroys and removes this element.
  destroy: ->
    @tooltip?.dispose()
    @tooltip = null
    @stopTimer()
    @destroyWidget()
    @disposables?.dispose()
    @disposables = null

  # Private: Returns humanized remaining time string.
  formatTminus: (dt, fromTime) ->
    dt = moment.duration(dt - fromTime)
    if dt < moment.duration(1, 'seconds')
      return 'now'
    dt.humanize()

  # Private: Returns formatted time string.
  formatTime: (dt, fromTime) ->
    if dt.getDay() != fromTime.getDay()
      moment(dt).format(@config.timeFormatOtherDay)
    else
      moment(dt).format(@config.timeFormatSameDay)

  # Private: Return true iff given eventTime is within warning threshold from given fromTime.
  isPastWarningTime: (eventTime, fromTime) ->
    eventTime - fromTime <= @config.warnThresholdMinutes * 60000

  # Private: Gets all the events for a particular schedule.
  getEventsForSchedule: (title, schedule, count, format, fromTime) ->
    nexts = later.schedule(schedule).next(count, @getDatetime())
    nexts = [nexts] if count == 1
    events = []
    for next in nexts
      text = format.slice(0)
        .replace(/\$title/g, title)
        .replace(/\$time/g, @formatTime next, fromTime)
        .replace(/\$tminus/g, @formatTminus next, fromTime)
      events.push
        displayText: text
        isWarning: @isPastWarningTime next, fromTime
    events

  # Private: Returns count events with text formatted according to given display format.
  # Return value is dictionary of events objects like:
  #   title:
  #     displayText: string; formatted event text.
  #     isWarning: boolean; true iff event meets warning threshold.
  getEvents: (count, format, fromTime) ->
    events = {}
    for title, schedule of @parsedSubscriptions
      events[title] = @getEventsForSchedule title, schedule, count, format, fromTime
    for title, schedule of @parsedSchedules
      events[title] = @getEventsForSchedule title, schedule, count, format, fromTime
    events

  # Private: Warn the user about an issue with something using the given title and details.
  warnAboutSomething: (something, title, detail) ->
    atom.notifications.addWarning "#{PREFIX}: Issue with #{something} #{title}",
      detail: detail

  # Private: Warn the user about an issue with the subscription with the given title.
  warnAboutSubscription: (title, detail) ->
    @warnAboutSomething 'subscription', title, detail

  # Private: Warn the user about an issue with the schedule with the given title.
  warnAboutSchedule: (title, detail) ->
    @warnAboutSomething 'schedule', title, detail

  # Private: Destroies the widget status-bar tile element.
  destroyWidget: ->
    @empty()
    @tile?.destroy()
    @tile = null

  # Private: Builds and attaches tile element to status bar.
  buildWidget: ->
    @tile = @statusBar?.addLeftTile
      item: this
      priority: 200

  # Private: Adds observer for configuration item key.
  watchConfig: (key) ->
    configKey = "#{PREFIX}.#{key}"
    atom.config.observe configKey, => @updateConfig key

  # Private: Updates state for configuration item key.
  updateConfig: (key) ->
    configKey = "#{PREFIX}.#{key}"
    return if this.config[key] == atom.config.get configKey
    this.config[key] = atom.config.get configKey
    if key == 'schedules'
      @updateParsedSchedules()
    else if key == 'subscriptions'
      @updateParsedSubscriptions()

  # Private: Returns later.js parsed schedule object for given cron or text expression.
  parseScheduleExpression: (title, expr) ->
    if typeof expr isnt 'string'
      @warnAboutSchedule title, 'Schedule is not a String.'
      return null

    if @config.cronSchedules
      schedule = later.parse.cron(expr)
      # later.js has no way to detect parse error in cron expression :(
      return scheudle

    schedule = later.parse.text(expr)
    if schedule.error == -1
      return schedule

    @warnAboutSchedule title, "#{PREFIX}: #{title}: text parse failure at character #{text_schedule.error}."
    null

  # Private: Parses given scheudle expression data, stores parsed data in given store.
  parseSchedules: (store, data) ->
    for title, scheduleExpr of data
      parsedSchedule = @parseScheduleExpression title, scheduleExpr
      if parsedSchedule != null
        store[title] = parsedSchedule

  # Private: Updates parsed subscriptions with latest based on current configuration.
  updateParsedSubscriptions: ->
    subscriptionsData = []
    for sub in @config.subscriptions
      try
        data = CSON.readFileSync fs.normalize(sub)
        subscriptionsData.splice(subscriptionsData.length, 0, data)
      catch e
        @warnAboutSubscription sub, e.message

    @parsedSubscriptions = {}
    for data in subscriptionsData
      @parseSchedules @parsedSubscriptions, data

  # Private: Updates parsed scheudles with latest based on current configuration.
  updateParsedSchedules: ->
    @parsedSchedules = {}
    @parseSchedules @parsedSchedules, @config.schedules

  # Private: Updates state for all configuration items.
  updateAllConfig: ->
    for key, value of @config.spec
      @updateConfig key

  # Private: Attaches package command to callback.
  addCommand: (command) ->
    map = {}
    map["#{PREFIX}:#{command}"] = => this[command]()
    @disposables.add atom.commands.add 'atom-workspace', map

  # Private: Sets up the event handlers.
  handleEvents: ->
    @click => @update()
    @tooltip = atom.tooltips.add this,
      title: => @tooltipTitle
      html: true
      animation: false
      delay:
        show: 0
        hide: 0
    @disposables = new CompositeDisposable
    @addCommand 'toggle'
    @addCommand 'update'
    @addCommand 'reload'
    for key, value of @config.spec
      @watchConfig key

  # Private: Sets up timeout for next update.
  # Use optional interval (in minutes) if given, otherwise use configuration setting.
  startTimer: (interval) ->
    interval = @config.refreshIntervalMinutes if !interval
    @stopTimer()
    sched = later.parse.recur().every(interval).minute()
    @timer = later.setInterval (=> @update()), sched

  # Private: Stops timeout for next update.
  stopTimer: ->
    if @timer
      @timer.clear()

  # Private: Create DOM element of given type with given classes.
  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add classes...
    element

  getDatetime: ->
    return @config.overrideDatetime if @config.overrideDatetime
    return new Date

  # Private: Generate the content of the tooltip.
  generateTooltipTitle: ->
    now = @getDatetime()
    tip = @createElement 'ul', PREFIX
    currentSchedule = ''
    for title, events of @getEvents @config.tooltipDetails, @config.displayFormatTooltip, now
      for event in events
        text = event.displayText
        li = @createElement 'li'
        if event.isWarning
          li.classList.add 'warn'
          li.style.color = @config.displayColorWarning
        else
          li.style.color = @config.displayColorTooltip
        li.innerHTML = text
        tip.appendChild(li)
    @tooltipTitle = tip.outerHTML

  # Private: Toggles on or off the widget.
  toggle: ->
    @visible = !@visible
    if @visible
      @buildWidget()
      @startTimer()
      @update()
    else
      @stopTimer()
      @destroyWidget()

  # Private: Reload configuration and update widget.
  reload: ->
    @updateAllConfig()
    @update()

  # Private: Displays events in stasus bar.
  # Return true iff a displayed event is within warning threshold.
  displayEvents: ->
    now = @getDatetime()
    hasWarning = false
    for title, events of @getEvents 1, @config.displayFormat, now
      for event in events
        widget = @createElement 'span', 'inline-block'
        if event.isWarning
          widget.classList.add 'warn'
          widget.style.color = @config.displayColorWarning
          hasWarning = true
        else
          widget.style.color = @config.displayColorStatusbar
        widget.textContent = event.displayText
        @append widget
    hasWarning

  # Private: Refresh element with current event information.
  update: ->
    return if !@visible
    wasWarning = @hasWarning
    @empty()
    @hasWarning = @displayEvents()
    @generateTooltipTitle()
    if !wasWarning && @hasWarning
      @startTimer 1  # 1 minute refresh during warnings
    else if wasWarning && !@hasWarning
      @startTimer()
