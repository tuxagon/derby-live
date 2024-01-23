use crate::app_state::AppState;
use crate::settings::AppSettings;
use log::info;
use std::sync::{Arc, Mutex};

pub fn handle(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) -> AppSettings {
    info!(target: "fetch_app_settings", "handle");
    let app_settings = match app_state.lock() {
        Ok(state_locked) => state_locked.app_settings.clone(),
        Err(_) => AppSettings::default(),
    };
    info!(target: "fetch_app_settings", "handle: app_settings {:?}", app_settings);

    app_settings
}
