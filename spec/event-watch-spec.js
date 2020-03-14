'use babel'

describe('EventWatch', function () {
  let EventWatch

  beforeEach(function () {
    const workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    let statusBar
    waitsForPromise(() => atom.packages.activatePackage('status-bar').then(function (pack) {
      statusBar = workspaceElement.querySelector('status-bar')
    }))

    waitsForPromise(() => atom.packages.activatePackage('event-watch').then(function (pack) {
      EventWatch = pack.mainModule
      EventWatch.consumeStatusBar(statusBar)
    }))

    waitsForPromise(() => atom.workspace.open())
  })

  describe('after initialization', function () {
    it('has the element in the status bar', () =>
      expect(EventWatch.element).toBeDefined())

    it('has an element with the expected data', function () {
      EventWatch.element.getDatetime = () => new Date(1982, 4, 24, 5, 30)
      atom.config.set('event-watch.displayFormat', '$title,$time,$tminus')
      atom.config.set('event-watch.schedules', {
        test1: 'at 6:30',
        test2: 'at 5:55',
        test3: 'at 4:00',
        test4: 'every 7 mins'
      })
      EventWatch.element.update()
      const e = EventWatch.element.element
      expect(e.classList.contains('event-watch')).toBeTruthy()
      expect(e.classList.contains('inline-block')).toBeTruthy()
      expect(e.children[0].innerHTML).toContain('test1,6:30am,an hour')
      expect(e.children[0].style.cssText).toContain('color: rgb(160, 122, 255);')
      expect(e.children[1].innerHTML).toContain('test2,5:55am,25 minutes')
      expect(e.children[1].style.cssText).toContain('color: rgb(160, 122, 255);')
      expect(e.children[2].innerHTML).toContain('test3,Tue 4:00am,a day')
      expect(e.children[2].style.cssText).toContain('color: rgb(160, 122, 255);')
      expect(e.children[3].innerHTML).toContain('test4,5:35am,5 minutes')
      expect(e.children[3].style.cssText).toContain('color: rgb(255, 68, 68);')
    })
  })

  describe('after deactivate', function () {
    it('removes the element', function () {
      expect(EventWatch.element).toBeTruthy()
      atom.packages.deactivatePackage('event-watch')
      expect(EventWatch.element).toBeNull()
    })

    it('can be deactivated again', function () {
      atom.packages.deactivatePackage('event-watch')
      atom.packages.deactivatePackage('event-watch')
    })
  })
})
