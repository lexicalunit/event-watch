module.exports =
  config:
    cronSchedules:
      type: 'boolean'
      default: false
      description: 'If true, schedules are parsed as cron expressions.'
    data:
      type: 'object'
      properties: {}
    displayColor:
      type: 'string'
      default: '#A07AFF'
      description: 'A valid CSS color expression for font color.'
    displayColorWarning:
      type: 'string'
      default: '#FF4444'
      description: 'A valid CSS color expression for warning font color.'
    displayFormat:
      type: 'string'
      default: '$title: $tminus'
      description: 'The display format for events.'
    displayFormatTooltip:
      type: 'string'
      default: '$title: $time [$tminus]'
      description: 'The tooltip display format for events.'
    refreshIntervalMinutes:
      type: 'integer'
      default: 5
      minimum: 1
      description: 'The time between updates in minutes. Automatically changes to 1 minute while any warning threshold is met.'
    timeFormatOtherDay:
      type: 'string'
      default: 'ddd h:mma'
      description: 'Format of $time when it does NOT occur later today.'
    timeFormatSameDay:
      type: 'string'
      default: 'h:mma'
      description: 'Format of $time when it occurs sometime today.'
    tooltipDetails:
      type: 'integer'
      default: 2
      minimum: 1
      description: 'Number of future occurances to display in the tooltip.'
    warnThresholdMinutes:
      type: 'integer'
      default: 15
      minimum: 1
      description: 'Events occurring within this many minutes are shown in warning color.'

  activate: ->

  consumeStatusBar: (statusBar) ->
    EventWatchView = require './event-watch-view'
    @view = new EventWatchView()
    @view.initialize(statusBar)
    @view.attach()

  deactivate: ->
    @view?.destroy()
    @view = null
