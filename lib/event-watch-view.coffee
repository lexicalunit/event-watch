{ConfigObserver} = require 'atom'

class EventWatchView extends HTMLElement

  initialize: (@statusBar) ->
    @classList.add('inline-block')
    @label = @createSpan()
    @data = atom.config.get('event-watch.data')

  attach: ->
    @statusBar?.appendRight(this)
    @setUpdate()
    @update() # inital update

  createSpan: ->
    span = document.createElement('span')
    span.classList.add('event-watch', 'inline-block')
    span.textContent = ''
    @appendChild(span)

  parseTime: (timeStr) ->
    # parse time string returning Date object
    time = timeStr.match(/(\d+)(?::(\d\d))?\s*(p?)/i)
    if !time
      return NaN

    hours = parseInt(time[1], 10)
    if hours == 12 && !time[3]
        hours = 0
    else
      hours += (hours < 12 && time[3]) ? 12 : 0

    dt = new Date()
    dt.setHours(hours)
    dt.setMinutes(parseInt(time[2], 10) || 0)
    dt.setSeconds(0, 0)
    return dt

  forceTwoDigits: (val) ->
    if val < 10
      return "0#{val}"
    return val

  formatTime: (date) ->
    # Formate date object as HH:MM(p)
    hour = date.getHours()
    minute = date.getMinutes()
    suffix = '';
    if hour >= 12
      suffix = 'p';
      hour = hour - 12;
    return "#{hour}:#{minute}#{suffix}"

  nextClosestTime: (currentDate, times) ->
    # gets the next closest time following the currentDate, NaN otherwise
    for time in times
      dt = @parseTime(time)
      if dt > currentDate
        return @formatTime(dt)
    return NaN

  setUpdate: ->
    # get interval from config, or set and save default
    interval = atom.config.get('event-watch.intervalMinutes')
    if interval
      interval = interval * 60 * 1000
    else
      interval = 300000 # 5 minute default
      atom.config.set('event-watch.intervalMinutes', interval / 60000)
    setInterval (=> @update()), interval

  update: ->
    currentDate = new Date
    info = []
    for name, times of @data
      next = @nextClosestTime(currentDate, times)
      if next
        info.push name + '[' + next + ']'
    if info.length
      @label.textContent = info.join(' ')

module.exports = document.registerElement('event-watch',
                                          prototype: EventWatchView.prototype,
                                          extends: 'div')
