extern crate notify;
extern crate rusqlite;
extern crate serde;
extern crate tauri;

use log::info;
use rusqlite::{params, Connection};
use serde::Serialize;
use std::path::PathBuf;

pub struct Client {
    conn: Connection,
}

#[derive(Debug, Serialize)]
pub struct Racer {
    racer_id: i32,
    last_name: String,
    first_name: String,
    car_number: i32,
    car_name: Option<String>,
    group: String,
    rank: String,
}

#[derive(Debug, Serialize)]
pub struct RacerHeat {
    car_number: i32,
    racer_id: i32,
    heat_number: i32,
    finish_seconds: Option<f64>,
    finish_place: Option<i32>,
    group: String,
    lane_number: i32,
    finished_at_unix: Option<i64>,
    result_id: i32,
}

impl Client {
    pub fn new(path: PathBuf) -> Client {
        let conn = Connection::open(path).expect("Failed to open database");
        Client { conn }
    }

    pub fn collect_data(&self) -> Result<(Vec<Racer>, Vec<RacerHeat>), rusqlite::Error> {
        info!(target: "sync", "collect_data");

        let racers = self.select_racers()?;
        let racer_heats = self.select_racer_heats_with_times()?;

        Ok((racers, racer_heats))
    }

    pub fn select_racers(&self) -> Result<Vec<Racer>, rusqlite::Error> {
        info!(target: "sync", "select_racers");
        let mut stmt = self.conn.prepare(
            "SELECT
                  RacerID as 'racer_id',
                  LastName as 'last_name',
                  FirstName as 'first_name',
                  CarNumber as 'car_number',
                  CarName as 'car_name',
                  Class as 'group',
                  Rank as 'rank'
                FROM qryRoster qr",
        )?;
        let racer_iter = stmt.query_map(params![], |row| {
            Ok(Racer {
                racer_id: row.get(0)?,
                last_name: row.get(1)?,
                first_name: row.get(2)?,
                car_number: row.get(3)?,
                car_name: row.get(4)?,
                group: row.get(5)?,
                rank: row.get(6)?,
            })
        })?;

        let mut racers = Vec::new();
        for racer in racer_iter {
            racers.push(racer?);
        }

        Ok(racers)
    }

    pub fn select_racer_heats_with_times(&self) -> Result<Vec<RacerHeat>, rusqlite::Error> {
        info!(target: "sync", "select_racer_heats_with_times");
        let mut stmt = self.conn.prepare(
            "SELECT
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
                INNER JOIN Ranks rk ON rk.RankID = ri.RankID",
        )?;

        let racer_heat_iter = stmt.query_map(params![], |row| {
            Ok(RacerHeat {
                car_number: row.get(0)?,
                racer_id: row.get(1)?,
                heat_number: row.get(2)?,
                finish_seconds: row.get(3)?,
                finish_place: row.get(4)?,
                group: row.get(5)?,
                lane_number: row.get(6)?,
                finished_at_unix: row.get(7)?,
                result_id: row.get(8)?,
            })
        })?;

        let mut racer_heats = Vec::new();
        for racer_heat in racer_heat_iter {
            racer_heats.push(racer_heat?);
        }

        Ok(racer_heats)
    }
}
