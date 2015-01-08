class EventWatch
  view: null

  activate: ->
    atom.packages.once 'activated', ->
      statusBar = document.querySelector('status-bar')
      if statusBar?
        EventWatchView = require './event-watch-view'
        @view = new EventWatchView
        @view.initialize(statusBar)
        @view.attach()

  deactivate: ->
    @view?.destroy()

module.exports = new EventWatch()
