# Event Watch

Based on the current time, displays the time of the next recurring event.

For example, I use this to keep track of when my Southbound and Northbound trains are next leaving, so I know when I need to pack up my laptop and head over to the station.

![9_15](https://cloud.githubusercontent.com/assets/1903876/7494968/8f9965f8-f3d0-11e4-84e4-e884f70065b5.png)

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

Most configuration options can be set by opening this package's settings once it is installed. Configuring your schedules data is handled by editing your Atom configuration file. You can open it using

```
Command Palette ➔ Application: Open Your Config
```

Within this config you should see various settings, for example you might see `core`, `editor`, `minimap` (if you have it installed), as well as other package configurations. You will need to provide schedule data for `event-watch` specifying your recurring event schedules.

### Time and Display Formats

Time formats such as `timeFormatSameDay` and `timeFormatOtherDay` are specified using [moment.js's format specification](http://momentjs.com/docs/#/displaying/format/). Display formats like `Display Format` and `Display Format Tooltip` are strings that specify how your event times should be displayed in the status bar or tooltip areas. The following values are permitted and will be interpolated automatically in display formats:

- `$title`: The title of the event as defined by its key in `schedules` or `subscriptions`.
- `$time`: The time of the next occurring event, formatted according to either `timeFormatSameDay` or `timeFormatOtherDay` as appropriate.
- `$tminus`: The time remaining until the next occurring event.

### Configuring Schedule Data

The `schedules` configuration should be a simple key/value object. Its keys are the titles of your event, and its values are are schedules. For example:

```cson
schedules:
  "Standup Meeting": "at 9:00 am on Mon,Tue,Wed,Thu,Fri"
  "Happy Hour": "at 5:00 pm on Fri"
```

If you'd rather put your schedules in their own separate configuration files, you can instead use the `subscriptions` configuration, which should be an array of file paths to load schedule data from. For example, you could put

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

Either or both methods of configuring schedule data may be used. Use whichever method is more convenient for your purposes.

### Writing a Schedule

Schedules are strings parsed using [later.js's text parser](http://bunkat.github.io/later/parsers.html#text). If `cronSchedules` is enabled, event-watch will use [later.js's cron parser](http://bunkat.github.io/later/parsers.html#cron) instead. Please see their extensive documentation for further details and examples. If event-watch encounters a problem in parsing your schedule, it will warn you with a short notification.

| Example Schedule | Description |
| ---------------- | ----------- |
| `"at 10:15 am"`  | fires at 10:15am every day |
| `"every 5 mins"` | fires every 5 minutes every day |
| `"at 7:03 am on Mon,Fri"` | fires at 7:03 am every Monday and Friday |

### Example Config

The following is what my configuration looks like. Everything that's not related to Event Watch has been omitted.

```cson
"*":
  "event-watch":
    schedules:
      Northbound: "at 7:03am and 7:34am and 8:05am and 8:41am and 9:15am and 9:44am and 10:15am and 11:15am and 12:15am and  1:15pm and 2:15pm and 3:15pm and 3:44pm and 4:19pm and 4:55pm and 5:27pm and 5:57pm and 6:30pm on Mon,Tue,Wed,Thu,Fri also at 7:30pm and 8:30pm and 9:30pm and 10:30pm and 11:30pm on Fri also at 12:30am on Sat also at 4:41pm and 5:15pm and 5:15pm and 5:49pm and 6:23pm and 6:57pm and 7:31pm and 8:05pm and 8:39pm and 9:13pm and 9:47pm and 10:21pm and 10:55pm and 11:29pm on Sat also at 12:03am on Sun"
      Southbound: "at 6:24am and 6:56am and 7:27am and 7:58am and 8:34am and 9:09am and  9:38am and 10:38am and 11:38am and 12:38am and 1:38pm and 2:38pm and 3:09pm and 3:38pm and 4:13pm and 4:43pm and 5:19pm and 5:51pm on Mon,Tue,Wed,Thu,Fri also at 6:53pm and 7:53pm and 8:24pm and 9:24pm and 10:24pm and 11:24pm on Fri also at 4:00pm and 4:34pm and 5:08pm and 5:42pm and 6:16pm and 6:50pm and 7:24pm and 7:58pm and 8:32pm and 9:06pm and 9:40pm and 10:14pm and 10:48pm and 11:22pm on Sat"
```

So if my current time is `9:09 AM`:

![9_09](https://cloud.githubusercontent.com/assets/1903876/7494974/9435bee0-f3d0-11e4-8000-705086a56860.png)

And if I hover over the widget at `9:11 AM` I would see:

![9_11 tool](https://cloud.githubusercontent.com/assets/1903876/7494970/91ba24e4-f3d0-11e4-9d25-aacc276a1eb7.png)

## Future Work

I would like to add the following features in future versions of event-watch.

- Support schedule data being provided by remote configuration file.
- Time formatting options for `$tminus` besides [humanized durations](http://momentjs.com/docs/#/durations/humanize/).
