module.exports =
  config:
    data:
      type: 'object'
      properties: {}
    displayFormat:
      type: 'string'
      default: '$title: $tminus'
    tooltipFormat:
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

  activate: ->

  consumeStatusBar: (@statusBar) ->
    EventWatchView = require './event-watch-view'
    @view = new EventWatchView()
    @view.initialize(statusBar)
    @view.attach()

  deactivate: ->
    @view?.destroy()
    @view = null
