module.exports =
  config:
    data:
      type: 'object'
      properties: {}
    displayFormat:
      type: 'string'
      default: '$title: $tminus'
    tooltipDisplayFormat:
      type: 'string'
      default: '$title: $time [$tminus]'
    tooltipDetails:
      type: 'integer'
      default: 2
      minimum: 1
      description: 'Number of future occurances to display in tooltip.'
    refreshIntervalMinutes:
      type: 'integer'
      default: 5
      minimum: 1
    warnThresholdMinutes:
      type: 'integer'
      default: 15
      minimum: 1
      description: 'Events that will occur within this many minutes will be displayed in red.'
    sameDayTimeFormat:
      type: 'string'
      default: 'h:mma'
      description: 'Format of $time when it occurs sometime today.'
    otherDayTimeFormat:
      type: 'string'
      default: 'ddd h:mma'
      description: 'Format of $time when it does not occur later today.'
    cronSchedules:
      type: 'boolean'
      default: false
      description: 'If true, schedules are parsed as cron expressions.'
    displayColor:
      type: 'string'
      default: '#A07AFF'
    displayWarningColor:
      type: 'string'
      default: '#FF4444'

  activate: ->

  consumeStatusBar: (statusBar) ->
    EventWatchView = require './event-watch-view'
    @view = new EventWatchView()
    @view.initialize(statusBar)
    @view.attach()

  deactivate: ->
    @view?.destroy()
    @view = null
