# Event Watch

[![apm package][apm-ver-link]][releases]
[![travis-ci][travis-ci-badge]][travis-ci]
[![appveyor][appveyor-badge]][appveyor]
[![circle-ci][circle-ci-badge]][circle-ci]
[![david][david-badge]][david]
[![download][dl-badge]][apm-pkg-link]
[![mit][mit-badge]][mit]

Create notifications for all your recurring events! For example, I use this to keep track of when my
Southbound and Northbound trains are next leaving. That way I know when I need to pack up my laptop
and head over to the station.

![9_15][img_9_15]

## Installation

### Via Command Line

```shell
apm install event-watch
```

### Via Atom

```
Command Palette ➔ Settings View: Install Packages And Themes ➔ Event Watch
```

## Configuration

Most configuration options for this package are available through your Atom settings panel. You must
edit schedule data directly. To do this, first open your Atom configuration file:

```
Command Palette ➔ Application: Open Your Config
```

Within this config you should see configuration data for installed packages, for example you will
see `core`, `editor`, `minimap` (if you have it installed), as well as other package configurations.
You will need to provide schedule data for `event-watch` specifying your recurring event schedules.

### Configuring Schedule Data

The `schedules` configuration should be a simple key/value object. Its keys are the titles of your
events, and its values are the schedules. For example:

```cson
schedules:
  "Standup Meeting": "at 9:00 am on Mon,Tue,Wed,Thu,Fri"
  "Happy Hour": "at 5:00 pm on Fri"
```

If you'd like to put your schedules in their own separate configuration files, you can instead use
the `subscriptions` configuration, which should be an array of file paths to load schedule data
from. For example,

```cson
"Standup Meeting": "at 9:00 am on Mon,Tue,Wed,Thu,Fri"
"Happy Hour": "at 5:00 pm on Fri"
```

in a file at `/path/to/your/data.cson` and then set your `subscriptions` configuration as follows.

```cson
subscriptions: [
    "/path/to/your/data.cson"
]
```

Either or both methods of configuring schedule data are valid. Use whichever method is more
convenient for your purposes.

> The files listed in the `subscriptions` configuration parse at startup time and if the
> configuration changes. You can force a reload and update of event-watch using the command
> `Command Palette ➔ Event Watch: Reload`.

### Writing a Schedule

Schedules are strings parsed using [later.js's text or cron parser][parser]. Please see their
extensive documentation for further details and examples. If event-watch encounters a problem in
parsing your schedule, it will warn you with a short notification. Note that later.js can not detect
errors in cron expressions.

| Example Schedule | Description |
| ---------------- | ----------- |
| `"at 10:15 am"`  | fires at 10:15am every day |
| `"every 5 mins"` | fires every 5 minutes every day |
| `"at 7:03 am on Mon,Fri"` | fires at 7:03 am every Monday and Friday |

### Time and Display Formats

Time formats such as `timeFormatSameDay` and `timeFormatOtherDay` must fit
[moment.js's format specification][format]. Display formats like `Display Format` and
`Display Format Tooltip` are strings that specify how to display your event times in the status bar
or tooltip areas. The following values interpolate automatically in display formats:

- `$title`: The title of the event as defined by its key in `schedules` or `subscriptions`.
- `$time`: The time of the next occurring event, formatted according to either `timeFormatSameDay`
  or `timeFormatOtherDay` as appropriate.
- `$tminus`: The time remaining until the next occurring event.

### Example Config

The following is what my configuration looks like.

```cson
"*":
  "event-watch":
    schedules:
      Northbound: '''
        at 7:03am and 7:34am and 8:05am and 8:41am and 9:15am and 9:44am and
        10:15am and 11:15am and 12:15am and  1:15pm and 2:15pm and 3:15pm
        and 3:44pm and 4:19pm and 4:55pm and 5:27pm and 5:57pm and 6:30pm on
        Mon,Tue,Wed,Thu,Fri also at 7:30pm and 8:30pm and 9:30pm and 10:30pm
        and 11:30pm on Fri also at 12:30am on Sat also at 4:41pm and 5:15pm
        and 5:15pm and 5:49pm and 6:23pm and 6:57pm and 7:31pm and 8:05pm
        and 8:39pm and 9:13pm and 9:47pm and 10:21pm and 10:55pm and 11:29pm
        on Sat also at 12:03am on Sun
      '''
      Southbound: '''
        at 6:24am and 6:56am and 7:27am and 7:58am and 8:34am and 9:09am and
        9:38am and 10:38am and 11:38am and 12:38am and 1:38pm and 2:38pm and
        3:09pm and 3:38pm and 4:13pm and 4:43pm and 5:19pm and 5:51pm on
        Mon,Tue,Wed,Thu,Fri also at 6:53pm and 7:53pm and 8:24pm and 9:24pm
        and 10:24pm and 11:24pm on Fri also at 4:00pm and 4:34pm and 5:08pm
        and 5:42pm and 6:16pm and 6:50pm and 7:24pm and 7:58pm and 8:32pm
        and 9:06pm and 9:40pm and 10:14pm and 10:48pm and 11:22pm on Sat
      '''
```

So if my current time is `9:09 AM`:

![9_09][img_9_09]

And if I hover over the widget at `9:11 AM` I would see:

![9_11 tool][img_9_11]

## Future Work

I would like to add the following features in future versions of event-watch.

- Option to configure certain events to display in-editor notifications.
- Detect "last event of the day" and display in-editor warning.
- Time formatting options for `$tminus` besides [humanized durations][humanize].
- More unit tests. Tests for every configuration option. Tests for tooltip and commands.
- Add more screenshots other than my Northbound/Southbound train example.
- Refactor and unify creation of tooltip and status-bar label?
- Support schedule data provided by remote configuration file? Or from a common dot file?

---

[MIT][mit] © [lexicalunit][author] et [al][contributors]

[mit]:              http://opensource.org/licenses/MIT
[author]:           http://github.com/lexicalunit
[contributors]:     https://github.com/lexicalunit/event-watch/graphs/contributors
[releases]:         https://github.com/lexicalunit/event-watch/releases
[mit-badge]:        https://img.shields.io/apm/l/event-watch.svg
[apm-pkg-link]:     https://atom.io/packages/event-watch
[apm-ver-link]:     https://img.shields.io/apm/v/event-watch.svg
[dl-badge]:         http://img.shields.io/apm/dm/event-watch.svg
[travis-ci-badge]:  https://travis-ci.org/lexicalunit/event-watch.svg?branch=master
[travis-ci]:        https://travis-ci.org/lexicalunit/event-watch
[appveyor]:         https://ci.appveyor.com/project/lexicalunit/event-watch?branch=master
[appveyor-badge]:   https://ci.appveyor.com/api/projects/status/5c5kwql6e5bvca1y/branch/master?svg=true
[circle-ci]:        https://circleci.com/gh/lexicalunit/event-watch/tree/master
[circle-ci-badge]:  https://circleci.com/gh/lexicalunit/event-watch/tree/master.svg?style=shield
[david-badge]:      https://david-dm.org/lexicalunit/event-watch.svg
[david]:            https://david-dm.org/lexicalunit/event-watch
[img_9_15]:         https://cloud.githubusercontent.com/assets/1903876/7494968/8f9965f8-f3d0-11e4-84e4-e884f70065b5.png
[img_9_09]:         https://cloud.githubusercontent.com/assets/1903876/7494974/9435bee0-f3d0-11e4-8000-705086a56860.png
[img_9_11]:         https://cloud.githubusercontent.com/assets/1903876/7494970/91ba24e4-f3d0-11e4-9d25-aacc276a1eb7.png
[parser]:           http://bunkat.github.io/later/parsers.html#text
[format]:           http://momentjs.com/docs/#/displaying/format/
[humanize]:         http://momentjs.com/docs/#/durations/humanize/
