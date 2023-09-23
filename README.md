# DerbyLive

This app is a live front end for [Gran Prix Race Manager](https://grandprix-software-central.com/).

## Environment setup

```
SENDGRID_API_KEY=
```

## Dev notes

- `fswatch -o tmp/example.sqlite | xargs -n1 -I{} ruby -e 'puts "changed @ #{Time.now}"'` was not triggering a change for unknown reasons. To get it working, add `-m poll_monitor` to the command, like `fswatch -m poll_monitor -o tmp/example.sqlite | xargs -n1 -I{} ruby -e 'puts "changed @ #{Time.now}"'`.

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

For grabbing racer_heats and times

```sql
SELECT
  ri.CarNumber as 'car_number',
  ri.RacerID as 'racer_id',
  rc.Heat as 'heat_number',
  rc.FinishTime as 'finish_seconds',
  rc.FinishPlace as 'finish_place',
  c.Class as 'group',
  rc.Lane as 'lane_number',
  STRFTIME('%s', rc.Completed) as 'finished_at_unix'
FROM RaceChart rc
INNER JOIN RegistrationInfo ri ON rc.RacerID = ri.RacerID
INNER JOIN Classes c ON c.ClassID = rc.ClassID
INNER JOIN Ranks rk ON rk.RankID = ri.RankID
```
