module.exports =
  activate: ->

  consumeStatusBar: (@statusBar) ->
    EventWatchView = require './event-watch-view'
    @view = new EventWatchView()
    @view.initialize(statusBar)
    @view.attach()

  deactivate: ->
    @view?.destroy()
    @view = null
