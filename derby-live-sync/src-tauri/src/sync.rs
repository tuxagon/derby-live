use rusqlite::{params, Connection};
use serde::ser::{Serialize, SerializeStruct, Serializer};
use std::path::PathBuf;

struct DatabaseConnector {
    conn: Connection,
}

impl DatabaseConnector {
    fn new(path: PathBuf) -> DatabaseConnector {
        let conn = Connection::open(path).expect("Failed to open database");
        DatabaseConnector { conn }
    }

    fn select_racers(&self) -> rusqlite::Result<Vec<String>> {
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
        let racer_iter = stmt.query_map(params![], |row| row.get(0))?;
        let mut racers = Vec::new();
        for racer in racer_iter {
            racers.push(racer?);
        }
        Ok(racers)
    }

    fn select_racer_heats_with_times(&self) -> rusqlite::Result<Vec<String>> {
        let mut stmt = self.conn.prepare(
            "SELECT
                  ri.CarNumber as 'car_number',
                  ri.RacerID as 'racer_id',
                  rc.RacerHeat as 'racer_heat_number',
                  rc.FinishTime as 'finish_seconds',
                  rc.FinishPlace as 'finish_place',
                  c.Class as 'group',
                  rk.Rank as 'rank',
                  rc.Lane as 'lane_number',
                  rc.Completed as 'finished_at'
                FROM RaceChart rc
                INNER JOIN RegistrationInfo ri ON rc.RacerID = ri.RacerID
                INNER JOIN Classes c ON c.ClassID = rc.ClassID
                INNER JOIN Ranks rk ON rk.RankID = ri.RankID",
        )?;
        let racer_heat_iter = stmt.query_map(params![], |row| row.get(0))?;
        let mut racer_heats = Vec::new();
        for racer_heat in racer_heat_iter {
            racer_heats.push(racer_heat?);
        }
        Ok(racer_heats)
    }
}

struct RequestBody {
    event_key: String,
    racers: Vec<String>,
    racer_heats: Vec<String>,
}

impl Serialize for RequestBody {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut s = serializer.serialize_struct("RequestBody", 3)?;
        s.serialize_field("event_key", &self.event_key)?;
        s.serialize_field("racers", &self.racers)?;
        s.serialize_field("racer_heats", &self.racer_heats)?;
        s.end()
    }
}

async fn upload_racers(db: &DatabaseConnector) -> Result<(), String> {
    let racers = db.select_racers();
    println!("racers: {:?}", racers);
    let api_key = "XAkUz3S6e8Kcae6Ks14QYmIMD9aZUtT4G3azdOyuOn8bGhyiHc1W4yGhw42KfKcV";
    let event_key = "demo";
    let server_url = "http://localhost:4000/api/data";
    let data = RequestBody {
        event_key: event_key.to_string(),
        racers: racers.map_err(|e| e.to_string())?,
        racer_heats: Vec::new(),
    };
    // TODO: convert racers to the JSON format expected by the server in the POST
    // TODO: provide way to configure event_key and api_key and server_url
    let resp = reqwest::Client::new()
        .post(server_url)
        .header("x-api-key", api_key)
        .json(&data)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    println!("{:#?}", resp);
    Ok(())
}

async fn upload_racer_heats(db: &DatabaseConnector) -> Result<(), String> {
    let racer_heats = db.select_racer_heats_with_times();
    println!("racer_heats: {:?}", racer_heats);
    let api_key = "XAkUz3S6e8Kcae6Ks14QYmIMD9aZUtT4G3azdOyuOn8bGhyiHc1W4yGhw42KfKcV";
    let event_key = "demo";
    let server_url = "http://localhost:4000/api/data";
    let data = RequestBody {
        event_key: event_key.to_string(),
        racers: Vec::new(),
        racer_heats: racer_heats.map_err(|e| e.to_string())?,
    };
    let resp = reqwest::Client::new()
        .post(server_url)
        .header("x-api-key", api_key)
        .json(&data)
        .send()
        .await
        .map_err(|e| e.to_string())?;
    println!("{:#?}", resp);
    Ok(())
}
