# Event Watch

Based on the current time, displays the time of the next recurring event.

For example, I use this to keep track of when my Southbound and Northbound trains are next leaving, so I know when I need to pack up my laptop and head over to the station.

## Configuration

| Configuration key | Description |
| --- | --- |
| `refreshIntervalMinutes` | The time between updates in minutes. |
| `warnThresholdMinutes` | Events that will occur within this many minutes will be displayed in red. |
| `displayFormat` | The display format for events; Both `$title` and `$time` will be interpolated with real values. |
| `data` | A list of event titles each with their own list of recurring event times in 24-hour format. |

My configuration, for example:

```cson
'event-watch':
  'refreshIntervalMinutes': 5
  'warnThresholdMinutes': 15
  'displayFormat': '$title: $time'
  'data':
    'Northbound': [
      '7:03'
      '7:34'
      '8:05'
      '8:41'
      '9:15'
      '9:44'
      '10:15'
      '11:15'
      '12:15'
      '13:15'
      '14:15'
      '15:15'
      '15:44'
      '16:19'
      '16:55'
      '17:27'
      '17:57'
      '18:30'
    ]
    'Southbound': [
      '6:24'
      '6:56'
      '7:27'
      '7:58'
      '8:34'
      '9:09'
      '9:38'
      '10:38'
      '11:38'
      '12:38'
      '13:38'
      '14:38'
      '15:09'
      '15:38'
      '16:13'
      '16:43'
      '17:19'
      '17:51'
    ]
```

So if my current time is `9:25`:

![alt tag](https://cloud.githubusercontent.com/assets/1903876/5672524/a2be36da-9756-11e4-9fde-581aaa2f7c38.png)

And if my current time is `6:15pm`:

![alt tag](https://cloud.githubusercontent.com/assets/1903876/5672525/a408b218-9756-11e4-94f2-9ffc62aa13b7.png)
