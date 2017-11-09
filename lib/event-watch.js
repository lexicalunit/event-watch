/** @babel */

export default {
  config: require('./config.coffee').config,

  consumeStatusBar (statusBar) {
    let EventWatchElement = require('./event-watch-element')
    this.element = new EventWatchElement({configSpec: this.config, statusBar: statusBar})
  },

  deactivate () {
    if (this.element) {
      this.element.destroy()
      this.element = null
    }
  }
}
