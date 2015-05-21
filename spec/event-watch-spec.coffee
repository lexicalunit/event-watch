describe 'EventWatch', ->
  [view] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

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
      view.overrideDatetime = new Date(1982, 4, 24, 5, 30)
      atom.config.set 'event-watch.displayFormat', '$title,$time,$tminus'
      atom.config.set 'event-watch.schedules',
        test1: 'at 6:30'
        test2: 'at 5:55'
        test3: 'at 4:00'
        test4: 'every 7 mins'
      view.update()

      link = view.children[0]
      expect(link.classList.contains('event-watch')).toBeTruthy
      expect(link.classList.contains('inline-block')).toBeTruthy

      expect(link.childNodes[0].innerHTML).toContain 'test1,6:30am,an hour'
      expect(link.childNodes[0].style.cssText).toContain 'color: rgb(160, 122, 255);'

      expect(link.childNodes[1].innerHTML).toContain 'test2,5:55am,25 minutes'
      expect(link.childNodes[1].style.cssText).toContain 'color: rgb(160, 122, 255);'

      expect(link.childNodes[2].innerHTML).toContain 'test3,Tue 4:00am,a day'
      expect(link.childNodes[2].style.cssText).toContain 'color: rgb(160, 122, 255);'

      expect(link.childNodes[3].innerHTML).toContain 'test4,5:35am,5 minutes'
      expect(link.childNodes[3].style.cssText).toContain 'color: rgb(255, 68, 68);'

  describe 'deactivate', ->
    it 'removes the view', ->
      expect(view).toExist()
      atom.packages.deactivatePackage('event-watch')
      expect(view.parentElement).toBeNull()

    it 'can be executed twice', ->
      atom.packages.deactivatePackage('event-watch')
      atom.packages.deactivatePackage('event-watch')
