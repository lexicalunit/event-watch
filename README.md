# Event Watch

Based on the current time, displays the time of the next recurring event.

For example, I use this to keep track of when my Southbound and Northbound trains are next leaving, so I know when I need to pack up my laptop and head over to the station.

![morning-screenshot](https://cloud.githubusercontent.com/assets/1903876/5672524/a2be36da-9756-11e4-9fde-581aaa2f7c38.png)

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

Most configuration options can be set by opening this package's settings once it is installed. Additional configuration is handled by your Atom configuration file. You can open it using

```
Command Palette ➔ Application: Open Your Config
```

Within this config you should see various settings, for example you might see `core`, `editor`, `minimap` (if you have it installed), as well as other package configurations. You will need to add settings for `event-watch`. Below is a specification of the supported configuration keys and values, and for those that learn best by example, a copy of my configuration.

### Specification

| Configuration key        | Description                                                 | Default                     |
| ------------------------:|:----------------------------------------------------------- |:--------------------------- |
| `refreshIntervalMinutes` | The time between updates in minutes.                        | `5`                         |
| `warnThresholdMinutes`   | Events occurring within this many minutes are shown in red. | `15`                        |
| `displayFormat`          | The display format for events.                              | `'$title: $tminus'`         |
| `tooltipDisplayFormat`   | The tooltip display format for events.                      | `'$title: $time [$tminus]'` |
| `tooltipDetails`         | How many occurrences to show in the tooltip.                | `2`                         |
| `sameDayTimeFormat`      | Format of `$time` when it occurs later today.               | `'H:mma'`                   |
| `otherDayTimeFormat`     | Format of `$time` when it does NOT occur later today.       | `'ddd H:mma'`               |
| `data`                   | Defines recurring events and their schedules. See below.    | `{}`                        |

> Whenever any event is within `warnThresholdMinutes`, `refreshIntervalMinutes` changes to `1` minute automatically.

#### Time and Display Formats

Time formats such as `sameDayTimeFormat` and `otherDayTimeFormat` are specified using [moment.js's format specification](http://momentjs.com/docs/#/displaying/format/). Display formats like `displayFormat` and `tooltipFormat` are strings that specify how your event times should be displayed in the status bar or tooltip areas. The following values are permitted and will be interpolated automatically in display formats:

- `$title`: The title of the event as defined by the key in `data`.
- `$time`: The time of the next occurring event, formatted according to either `sameDayTimeFormat` or `otherDayTimeFormat` as appropriate.
- `$tminus`: The time remaining until the next occurring event.

#### Configuring `data`

The `data` configuration should be a simple key/value object. Its keys are the titles of your event, and its values are are schedules. For example:

```cson
'data':
  'Standup Meeting': 'at 9:00 am on Mon,Tue,Wed,Thu,Fri'
  'Happy Hour': 'at 5:00 pm on Fri'
```

#### Writing a Schedule

Schedules are strings parsed using [later.js's text parser](http://bunkat.github.io/later/parsers.html#text). Please see their extensive documentation for further details and examples.

| Example Schedule | Description |
| ---------------- | ----------- |
| `"at 10:15 am"`  | fires at 10:15am every day |
| `"every 5 mins"` | fires every 5 minutes every day |
| `"at 7:03 am on Mon,Fri"` | fires at 7:03 am every Monday and Friday |

### Example Config

The following is what my configuration looks like. Everything that's not related to Event Watch has been omitted.

```cson
*:
  'event-watch':
    'data':
      Northbound: "at 7:03am and 7:34am and 8:05am and 8:41am and 9:15am and 9:44am and 10:15am and 11:15am and 12:15am and  1:15pm and 2:15pm and 3:15pm and 3:44pm and 4:19pm and 4:55pm and 5:27pm and 5:57pm and 6:30pm on Mon,Tue,Wed,Thu,Fri also at 7:30pm and 8:30pm and 9:30pm and 10:30pm and 11:30pm on Fri also at 12:30am on Sat also at 4:41pm and 5:15pm and 5:15pm and 5:49pm and 6:23pm and 6:57pm and 7:31pm and 8:05pm and 8:39pm and 9:13pm and 9:47pm and 10:21pm and 10:55pm and 11:29pm on Sat also at 12:03am on Sun"
      Southbound: "at 6:24am and 6:56am and 7:27am and 7:58am and 8:34am and 9:09am and  9:38am and 10:38am and 11:38am and 12:38am and 1:38pm and 2:38pm and 3:09pm and 3:38pm and 4:13pm and 4:43pm and 5:19pm and 5:51pm on Mon,Tue,Wed,Thu,Fri"
```

So if my current time is `9:25 AM`:

![morning-screenshot](https://cloud.githubusercontent.com/assets/1903876/5672524/a2be36da-9756-11e4-9fde-581aaa2f7c38.png)

And if my current time is `6:15 PM`:

![evening-screenshot](https://cloud.githubusercontent.com/assets/1903876/5673870/7bac361c-9767-11e4-884a-a047154410c8.png)
