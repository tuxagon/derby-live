# DerbyLive

This app is a live front end for [Gran Prix Race Manager](https://grandprix-software-central.com/).

## Dev Notes about Gran Prix Race Manager

SQLite is used for the database and here are some relevant queries.

For grabbing racers

```sql
SELECT
  RacerID as 'racer_id',
  LastName as 'last_name',
  FirstName as 'first_name',
  CarNumber as 'car_number',
  CarName as 'car_name',
  Class as 'group',
  Rank as 'rank'
FROM qryRoster qr
```

For grabbing heats and times

```sql
SELECT
  ri.CarNumber as 'car_number',
  ri.RacerID as 'racer_id',
  rc.Heat as 'heat_number',
  rc.FinishTime as 'finish_seconds',
  rc.FinishPlace as 'finish_place',
  c.Class as 'group',
  rk.Rank as 'rank',
  rc.Lane as 'lane_number',
  rc.Completed as 'finished_at'
FROM RaceChart rc
INNER JOIN RegistrationInfo ri ON rc.RacerID = ri.RacerID
INNER JOIN Classes c ON c.ClassID = rc.ClassID
INNER JOIN Ranks rk ON rk.RankID = ri.RankID
```
