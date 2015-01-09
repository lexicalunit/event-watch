EventWatch = require '../lib/event-watch'

describe 'EventWatch', ->
  [view, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    atom.config.set 'event-watch.refreshIntervalMinutes', 5
    atom.config.set 'event-watch.warnThresholdMinutes', 15
    atom.config.set 'event-watch.data', {
        'One': ['1:00', '2:00'],
        'Two': ['5:00', '14:00']
    }

    waitsForPromise -> atom.packages.activatePackage('status-bar')
    waitsForPromise -> atom.packages.activatePackage('event-watch')

    runs ->
      atom.packages.emitter.emit('did-activate-all')
      view = EventWatch.view

  describe '.initialize', ->
    it 'displays in the status bar', ->
      expect(view).toBeDefined()
      expect(view.querySelector('.event-watch')).toBeTruthy()

    it 'has view text', ->
      # TODO: Better test for content (be able to simulate current time?)
      expect(view.textContent).toContain 'One'
      expect(view.textContent).toContain 'Two'

  describe '.deactivate', ->
    it 'removes the view', ->
      expect(view).toExist()
      atom.packages.deactivatePackage('event-watch')
      expect(EventWatch.view).toBeNull()

    it 'can be executed twice', ->
      atom.packages.deactivatePackage('event-watch')
      atom.packages.deactivatePackage('event-watch')
