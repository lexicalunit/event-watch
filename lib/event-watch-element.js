/** @babel */
/** @jsx etch.dom */

import etch from 'etch'

import { CompositeDisposable } from 'atom'
import CSON from 'season'
import fs from 'fs-plus'
import later from 'later'
import moment from 'moment'

const PREFIX = 'event-watch'

// Public: Event watch element in status bar.
export default class EventWatchElement {
  // Public: Initialize event watch indicator element.
  // Requires both a configSpec and statusBar prop.
  constructor (props, children) {
    this.statusBar = props.statusBar
    later.date.localTime()
    this.config = { // cache for package config values
      spec: props.configSpec,
      schedules: {},
      subscriptions: []
    }
    this.disposables = [] // CompositeDisposable objects
    this.hasWarning = false // true iff any warning being displayed
    this.parsedSchedules = {} // parsed schedules { title: schedule, ...}
    this.parsedSubscriptions = {} // parsed subscriptions { title: schedule, ...}
    this.tile = null // status-bar tile element
    this.timer = null // timeout handler object
    this.tooltip = null // disposable tooltip object
    this.tooltipTitle = '' // cached tooltip title
    this.visible = true // true iff widget is toggled visible

    etch.initialize(this)

    this.buildWidget()
    this.handleEvents()
    this.startTimer()
    this.update()
  }

  render () {
    return (<div on={{ click: this.didClick }} className={`${PREFIX} inline-block`}></div>)
  }

  // Public: Destroys and removes this element.
  async destroy () {
    __guard__(this.tooltip, x => x.dispose())
    this.tooltip = null
    this.stopTimer()
    this.destroyWidget()
    __guard__(this.disposables, x1 => x1.dispose())
    this.disposables = null
    await etch.destroy(this)
  }

  // Private: Returns humanized remaining time string.
  formatTminus (dt, fromTime) {
    dt = moment.duration(dt - fromTime)
    if (dt < moment.duration(1, 'seconds')) {
      return 'now'
    }
    return dt.humanize()
  }

  // Private: Returns formatted time string.
  formatTime (dt, fromTime) {
    if (dt.getDay() !== fromTime.getDay()) {
      return moment(dt).format(this.config.timeFormatOtherDay)
    } else {
      return moment(dt).format(this.config.timeFormatSameDay)
    }
  }

  // Private: Return true iff given eventTime is within warning threshold from given fromTime.
  isPastWarningTime (eventTime, fromTime) {
    return eventTime - fromTime <= this.config.warnThresholdMinutes * 60000
  }

  // Private: Gets all the events for a particular schedule.
  getEventsForSchedule (title, schedule, count, format, fromTime) {
    let nexts = later.schedule(schedule).next(count, this.getDatetime())
    if (count === 1) { nexts = [nexts] }
    const events = []
    for (let i = 0; i < nexts.length; i++) {
      const next = nexts[i]
      const text = format.slice(0)
        .replace(/\$title/g, title)
        .replace(/\$time/g, this.formatTime(next, fromTime))
        .replace(/\$tminus/g, this.formatTminus(next, fromTime))
      events.push({
        displayText: text,
        isWarning: this.isPastWarningTime(next, fromTime)
      })
    }
    return events
  }

  // Private: Returns count events with text formatted according to given display format.
  // Return value is dictionary of events objects like:
  //   title:
  //     displayText: string; formatted event text.
  //     isWarning: boolean; true iff event meets warning threshold.
  getEvents (count, format, fromTime) {
    const events = {}
    var schedule
    for (var title in this.parsedSubscriptions) {
      schedule = this.parsedSubscriptions[title]
      events[title] = this.getEventsForSchedule(title, schedule, count, format, fromTime)
    }
    for (title in this.parsedSchedules) {
      schedule = this.parsedSchedules[title]
      events[title] = this.getEventsForSchedule(title, schedule, count, format, fromTime)
    }
    return events
  }

  // Private: Warn the user about an issue with something using the given title and details.
  warnAboutSomething (something, title, detail) {
    atom.notifications.addWarning(`${PREFIX}: Issue with ${something} ${title}`, { detail })
  }

  // Private: Warn the user about an issue with the subscription with the given title.
  warnAboutSubscription (title, detail) {
    this.warnAboutSomething('subscription', title, detail)
  }

  // Private: Warn the user about an issue with the schedule with the given title.
  warnAboutSchedule (title, detail) {
    this.warnAboutSomething('schedule', title, detail)
  }

  // Private: Destroies the widget status-bar tile element.
  destroyWidget () {
    while (this.element.firstChild) {
      this.element.removeChild(this.element.firstChild)
    }
    this.element.remove()
    __guard__(this.tile, x => x.destroy())
    this.tile = null
  }

  // Private: Builds and attaches tile element to status bar.
  buildWidget () {
    this.tile = __guard__(this.statusBar, x => x.addLeftTile({
      item: this.element,
      priority: 200
    }))
  }

  // Private: Adds observer for configuration item key.
  watchConfig (key) {
    const configKey = `${PREFIX}.${key}`
    atom.config.observe(configKey, () => this.updateConfig(key))
  }

  // Private: Updates state for configuration item key.
  updateConfig (key) {
    const configKey = `${PREFIX}.${key}`
    if (this.config[key] === atom.config.get(configKey)) { return }
    this.config[key] = atom.config.get(configKey)
    if (key === 'schedules') {
      return this.updateParsedSchedules()
    } else if (key === 'subscriptions') {
      return this.updateParsedSubscriptions()
    }
  }

  // Private: Returns later.js parsed schedule object for given cron or text expression.
  parseScheduleExpression (title, expr) {
    var schedule
    if (typeof expr !== 'string') {
      this.warnAboutSchedule(title, 'Schedule is not a String.')
      return null
    }

    if (this.config.cronSchedules) {
      schedule = later.parse.cron(expr)
      // later.js has no way to detect parse error in cron expression :(
      return schedule
    }

    schedule = later.parse.text(expr)
    if (schedule.error === -1) {
      return schedule
    }

    this.warnAboutSchedule(title, `${PREFIX}: ${title}: text parse failure at character ${schedule.error}.`)
    return null
  }

  // Private: Parses given schedule expression data, stores parsed data in given store.
  parseSchedules (store, data) {
    for (const title in data) {
      const scheduleExpr = data[title]
      const parsedSchedule = this.parseScheduleExpression(title, scheduleExpr)
      if (parsedSchedule !== null) {
        store[title] = parsedSchedule
      }
    }
  }

  // Private: Updates parsed subscriptions with latest based on current configuration.
  updateParsedSubscriptions () {
    const subscriptionsData = []
    for (let i = 0; i < this.config.subscriptions.length; i++) {
      const sub = this.config.subscriptions[i]
      try {
        const data = CSON.readFileSync(fs.normalize(sub))
        subscriptionsData.splice(subscriptionsData.length, 0, data)
      } catch (e) {
        this.warnAboutSubscription(sub, e.message)
      }
    }

    this.parsedSubscriptions = {}
    return subscriptionsData.map((data) =>
      this.parseSchedules(this.parsedSubscriptions, data))
  }

  // Private: Updates parsed scheudles with latest based on current configuration.
  updateParsedSchedules () {
    this.parsedSchedules = {}
    return this.parseSchedules(this.parsedSchedules, this.config.schedules)
  }

  // Private: Updates state for all configuration items.
  updateAllConfig () {
    for (const key in this.config.spec) {
      this.updateConfig(key)
    }
  }

  // Private: Attaches package command to callback.
  addCommand (command) {
    const map = {}
    map[`${PREFIX}:${command}`] = () => this[command]()
    this.disposables.add(atom.commands.add('atom-workspace', map))
  }

  // Private: Handles etch element clicks.
  didClick (event) {
    this.update()
  }

  // Private: Sets up the event handlers.
  handleEvents () {
    this.tooltip = atom.tooltips.add(this.element, {
      title: () => this.tooltipTitle,
      html: true,
      animation: false,
      delay: {
        show: 0,
        hide: 0
      }
    })
    this.disposables = new CompositeDisposable()
    this.addCommand('toggle')
    this.addCommand('update')
    this.addCommand('reload')
    for (const key in this.config.spec) {
      this.watchConfig(key)
    }
  }

  // Private: Sets up timeout for next update.
  // Use optional interval (in minutes) if given, otherwise use configuration setting.
  startTimer (interval) {
    if (!interval) { interval = this.config.refreshIntervalMinutes }
    this.stopTimer()
    const sched = later.parse.recur().every(interval).minute()
    this.timer = later.setInterval(() => this.update(), sched)
  }

  // Private: Stops timeout for next update.
  stopTimer () {
    if (this.timer) {
      this.timer.clear()
    }
  }

  // Private: Create DOM element of given type with given classes.
  createElement (type, ...classes) {
    const element = document.createElement(type)
    element.classList.add(...classes)
    return element
  }

  // Private: Gets the current time (provides an override hook for testing).
  getDatetime () {
    return new Date()
  }

  // Private: Generate the content of the tooltip.
  generateTooltipTitle () {
    const now = this.getDatetime()
    const tip = this.createElement('ul', `${PREFIX}-tooltip`)
    const object = this.getEvents(this.config.tooltipDetails, this.config.displayFormatTooltip, now)
    for (const title in object) {
      const events = object[title]
      for (let i = 0; i < events.length; i++) {
        const event = events[i]
        const text = event.displayText
        const li = this.createElement('li')
        li.style.fontWeight = this.config.displayFontWeightStatusbar
        if (event.isWarning) {
          li.classList.add('warn')
          li.style.color = this.config.displayColorWarningTooltip
        } else {
          li.style.color = this.config.displayColorTooltip
        }
        li.innerHTML = text
        tip.appendChild(li)
      }
    }
    this.tooltipTitle = tip.outerHTML
  }

  // Private: Toggles on or off the widget.
  toggle () {
    this.visible = !this.visible
    if (this.visible) {
      this.buildWidget()
      this.startTimer()
      this.update()
    } else {
      this.stopTimer()
      this.destroyWidget()
    }
  }

  // Private: Reload configuration and update widget.
  reload () {
    this.updateAllConfig()
    this.update()
  }

  // Private: Displays events in stasus bar.
  // Return true iff a displayed event is within warning threshold.
  displayEvents () {
    const now = this.getDatetime()
    let hasWarning = false
    const object = this.getEvents(1, this.config.displayFormat, now)
    for (const title in object) {
      const events = object[title]
      for (let i = 0; i < events.length; i++) {
        const event = events[i]
        const widget = this.createElement('span', 'event-watch-item')
        widget.style.fontWeight = this.config.displayFontWeightStatusbar
        if (event.isWarning) {
          widget.classList.add('warn')
          widget.style.color = this.config.displayColorWarningStatusbar
          hasWarning = true
        } else {
          widget.style.color = this.config.displayColorStatusbar
        }
        widget.textContent = event.displayText
        this.element.append(widget)
      }
    }
    return hasWarning
  }

  // Private: Refresh element with current event information.
  update (props, children) {
    if (!this.visible) { return }
    const wasWarning = this.hasWarning
    while (this.element.firstChild) {
      this.element.removeChild(this.element.firstChild)
    }
    this.hasWarning = this.displayEvents()
    this.generateTooltipTitle()
    if (!wasWarning && this.hasWarning) {
      // 1 minute refresh during warnings
      this.startTimer(1)
    } else if (wasWarning && !this.hasWarning) {
      this.startTimer()
    }
    etch.update(this)
  }
}

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
