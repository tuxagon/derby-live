use crate::app_state::AppState;
use crate::settings::AppSettings;
use log::info;
use std::sync::{Arc, Mutex};

pub fn handle(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> String {
    info!(target: "command", "fetch_database_path");
    let app_settings = match app_state.lock() {
        Ok(state_locked) => state_locked.app_settings.clone(),
        Err(_) => AppSettings::default(),
    };
    let database_path = app_settings.current_database_path();
    info!(target: "fetch_app_settings", "handle: database_path {:?}", database_path);

    database_path
}
