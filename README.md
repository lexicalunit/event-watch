# Event Watch

Based on the current time, displays the time of the next recurring event.

For example, I use this to keep track of when my Southbound and Northbound trains are next leaving, so I know when I need to pack up my laptop and head over to the station.

My configuration:

```cson
'event-watch':
  'intervalMinutes': 5
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

So, for example, if the current time is `9:30`:

![alt tag](https://cloud.githubusercontent.com/assets/1903876/5638980/a283802c-95d4-11e4-8731-0eae860752d6.png)

And if the current time is `6:15pm`:

![alt tag](https://cloud.githubusercontent.com/assets/1903876/5638979/a15a228c-95d4-11e4-9d05-ff901fef1955.png)
