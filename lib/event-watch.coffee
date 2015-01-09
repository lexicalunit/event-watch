{CompositeDisposable} = require 'atom'

class EventWatch
  view: null
  subscriptions: null

  activate: ->
    atom.packages.onDidActivateAll =>
      @subscriptions = new CompositeDisposable
      statusBar = document.querySelector('status-bar')
      if statusBar?
        EventWatchView = require './event-watch-view'
        @view = new EventWatchView()
        @view.initialize(statusBar, @subscriptions)
        @view.attach()

  deactivate: ->
    @subscriptions.dispose()
    @view?.destroy()
    @view = null

module.exports = new EventWatch()
