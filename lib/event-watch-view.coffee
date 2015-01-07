{ConfigObserver} = require 'atom'

class EventWatchView extends HTMLElement

  initialize: (@statusBar) ->
    @classList.add('inline-block')

    # TODO: Way to do this that won't change event order on warn?
    div = @createElement('div', 'event-watch', 'inline-block')
    @warn_label = @createElement('span', 'warn', 'inline-block')
    @info_label = @createElement('span', 'info', 'inline-block')
    div.appendChild(@warn_label)
    div.appendChild(@info_label)
    @appendChild(div)

    @data = atom.config.get('event-watch.data')
    @interval = 0

  attach: ->
    @statusBar?.appendRight(this)
    @setUpdate()
    @update() # inital update

  createElement: (type, classes...) ->
    element = document.createElement(type)
    element.classList.add(classes...)
    return element

  parseTime: (timeStr) ->
    # tries to parse a time string and return a Date object
    # TODO: isn't there a library function I could use instead?
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

  formatTime: (date) ->
    # returns time string formatted as HH:MM[p]
    # TODO: isn't there a library function I could use instead?
    hour = date.getHours()
    minute = date.getMinutes()
    suffix = '';
    if hour >= 12
      suffix = 'p';
      hour = hour - 12;
    if minute < 10
      minute = "0#{minute}"
    return "#{hour}:#{minute}#{suffix}"

  nextClosestTime: (currentDate, times) ->
    # gets the next closest time following the currentDate, NaN otherwise
    for time in times
      dt = @parseTime(time)
      if dt > currentDate
        return dt
    return NaN

  setUpdate: ->
    # get interval from config, or set and save default
    @interval = atom.config.get('event-watch.intervalMinutes')
    if @interval
      @interval = @interval * 60 * 1000
    else
      @interval = 300000 # 5 minute default
      atom.config.set('event-watch.intervalMinutes', @interval / 60000)
    setInterval (=> @update()), @interval

  update: ->
    currentDate = new Date
    warn = []
    info = []
    for name, times of @data
      next = @nextClosestTime(currentDate, times)
      if !next
        continue

      # TODO: Make the format configurable
      if name.length and name[0] != '-'
        text = name + '[' + @formatTime(next) + ']'
      else
        text = @formatTime(next)

      # TODO: Make alert threshold configurable
      if next - currentDate <= 3 * @interval
        warn.push text
      else
        info.push text

    if info.length
      @info_label.textContent = info.join(' ')
    if warn.length
      @warn_label.textContent = warn.join(' ')

module.exports = document.registerElement('event-watch',
                                          prototype: EventWatchView.prototype,
                                          extends: 'div')
