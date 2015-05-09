describe 'EventWatch', ->
  [view] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    atom.config.set 'event-watch.data', {
      'One': 'at 1:00 and 2:00',
      'Two': 'at 5:00 and 14:00'
    }

    waitsForPromise -> atom.packages.activatePackage('status-bar')
    waitsForPromise -> atom.packages.activatePackage('event-watch')

    runs ->
      view = document.querySelector('event-watch')
      expect(view).toExist()

  describe 'after initialization', ->
    it 'view is in the status bar', ->
      expect(view).toBeDefined()
      expect(view.querySelector('.event-watch')).toBeTruthy()

    it 'view has expected data', ->
      expect(view.textContent).toContain 'One'
      expect(view.textContent).toContain 'Two'

  describe 'deactivate', ->
    it 'removes the view', ->
      expect(view).toExist()
      atom.packages.deactivatePackage('event-watch')
      expect(view.parentElement).toBeNull()

    it 'can be executed twice', ->
      atom.packages.deactivatePackage('event-watch')
      atom.packages.deactivatePackage('event-watch')
