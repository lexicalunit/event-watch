# Event Watch

Based on the current time, displays the time of the next recurring event.

For example, I use this to keep track of when my Southbound and Northbound trains are next leaving, so I know when I need to pack up my laptop and head over to the station.

![morning-screenshot](https://cloud.githubusercontent.com/assets/1903876/5672524/a2be36da-9756-11e4-9fde-581aaa2f7c38.png)

## Installation

### Command Line

```bash
apm install event-watch
```

### Atom

```
Command Palette ➔ Settings View: Install Packages And Themes ➔ Event Watch
```

## Configuration

| Configuration key | Description |
| --- | --- |
| `refreshIntervalMinutes` | The time between updates in minutes. |
| `warnThresholdMinutes` | Events that will occur within this many minutes will be displayed in red. |
| `displayFormat` | The display format for events; Both `$title` and `$time` will be interpolated with real values. |
| `data` | A list of event titles each with their own list of recurring event times in 24-hour format. |
| `data` time format | `'[0123456] HH:MM [am/pm]'` - The `0123456` part indicates on what days this event occurs on. Leave off to indicate every day of the week. |

My configuration, for example:

```cson
'event-watch':
  'refreshIntervalMinutes': 5
  'warnThresholdMinutes': 15
  'displayFormat': '$title: $time'
  'data':
    'Northbound': [
      '12345 7:03'
      '12345 7:34'
      '12345 8:05'
      '12345 8:41'
      '12345 9:15'
      '12345 9:44'
      '12345 10:15'
      '12345 11:15'
      '12345 12:15'
      '12345 1:15pm'
      '12345 2:15pm'
      '12345 3:15pm'
      '12345 3:44pm'
      '12345 4:19pm'
      '12345 4:55pm'
      '12345 5:27pm'
      '12345 5:57pm'
      '12345 6:30pm'
    ]
    'Southbound': [
      '12345 6:24'
      '12345 6:56'
      '12345 7:27'
      '12345 7:58'
      '12345 8:34'
      '12345 9:09'
      '12345 9:38'
      '12345 10:38'
      '12345 11:38'
      '12345 12:38'
      '12345 1:38pm'
      '12345 2:38pm'
      '12345 3:09pm'
      '12345 3:38pm'
      '12345 4:13pm'
      '12345 4:43pm'
      '12345 5:19pm'
      '12345 5:51pm'
    ]
```

So if my current time is `9:25 AM`:

![morning-screenshot](https://cloud.githubusercontent.com/assets/1903876/5672524/a2be36da-9756-11e4-9fde-581aaa2f7c38.png)

And if my current time is `6:15 PM`:

![evening-screenshot](https://cloud.githubusercontent.com/assets/1903876/5673870/7bac361c-9767-11e4-884a-a047154410c8.png)
