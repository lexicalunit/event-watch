describe 'EventWatch', ->
  [EventWatch, statusBar, statusBarService, workspaceElement] = []

  beforeEach ->
    workspaceElement = atom.views.getView atom.workspace
    jasmine.attachToDOM(workspaceElement)
    waitsForPromise ->
      atom.packages.activatePackage('status-bar').then (pack) ->
        statusBar = workspaceElement.querySelector 'status-bar'
        statusBarService = pack.mainModule.provideStatusBar()
    waitsForPromise ->
      atom.packages.activatePackage('event-watch').then (pack) ->
        EventWatch = pack.mainModule
        EventWatch.consumeStatusBar statusBar
    waitsForPromise ->
      atom.workspace.open()

  describe 'after initialization', ->
    it 'element is in the status bar', ->
      expect(EventWatch.element).toBeDefined()

    it 'element has expected data', ->
      EventWatch.element.getDatetime = ->
        new Date(1982, 4, 24, 5, 30)
      atom.config.set 'event-watch.displayFormat', '$title,$time,$tminus'
      atom.config.set 'event-watch.schedules',
        test1: 'at 6:30'
        test2: 'at 5:55'
        test3: 'at 4:00'
        test4: 'every 7 mins'
      EventWatch.element.update()
      expect(EventWatch.element.hasClass('event-watch')).toBeTruthy
      expect(EventWatch.element.hasClass('inline-block')).toBeTruthy
      expect(EventWatch.element.children()[0].innerHTML).toContain 'test1,6:30am,an hour'
      expect(EventWatch.element.children()[0].style.cssText).toContain 'color: rgb(160, 122, 255);'
      expect(EventWatch.element.children()[1].innerHTML).toContain 'test2,5:55am,25 minutes'
      expect(EventWatch.element.children()[1].style.cssText).toContain 'color: rgb(160, 122, 255);'
      expect(EventWatch.element.children()[2].innerHTML).toContain 'test3,Tue 4:00am,a day'
      expect(EventWatch.element.children()[2].style.cssText).toContain 'color: rgb(160, 122, 255);'
      expect(EventWatch.element.children()[3].innerHTML).toContain 'test4,5:35am,5 minutes'
      expect(EventWatch.element.children()[3].style.cssText).toContain 'color: rgb(255, 68, 68);'

  describe 'deactivate', ->
    it 'removes the element', ->
      expect(EventWatch.element).toExist()
      atom.packages.deactivatePackage 'event-watch'
      expect(EventWatch.element).toBeNull()

    it 'can be executed twice', ->
      atom.packages.deactivatePackage 'event-watch'
      atom.packages.deactivatePackage 'event-watch'
