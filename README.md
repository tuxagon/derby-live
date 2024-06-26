# DerbyLive

This app is a live front end for [Gran Prix Race Manager](https://grandprix-software-central.com/).

## Environment setup

```
SENDGRID_API_KEY=
MAILER_FROM_NAME=
MAILER_FROM_ADDRESS=
```

## Dev notes for Derby Live Sync

- `fswatch -o tmp/example.sqlite | xargs -n1 -I{} ruby -e 'puts "changed @ #{Time.now}"'` was not triggering a change for unknown reasons. To get it working, add `-m poll_monitor` to the command, like `fswatch -m poll_monitor -o tmp/example.sqlite | xargs -n1 -I{} ruby -e 'puts "changed @ #{Time.now}"'`.

### Releases

#### Website

Deploying to Fly until deploy is in CI

```
fly deploy
```

IEx

```
fly ssh console --pty --select -C "/app/bin/derby_live remote"
```

#### Sync app

This is handled with the Release Sync workflow, which is manually triggered for now.

To build a release,

1. Bump the version in `src-tauri/tauri.conf.json`
2. Kick off the workflow with the same version as in `tauri.conf.json`

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
  CAST(STRFTIME('%s', rc.Completed) as bigint) as 'finished_at_unix',
  rc.ResultID as 'result_id'
FROM RaceChart rc
INNER JOIN RegistrationInfo ri ON rc.RacerID = ri.RacerID
INNER JOIN Classes c ON c.ClassID = rc.ClassID
INNER JOIN Ranks rk ON rk.RankID = ri.RankID
```
