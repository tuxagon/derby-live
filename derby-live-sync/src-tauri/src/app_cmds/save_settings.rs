use crate::app_state::AppState;
use crate::settings::AppSettings;
use log::info;
use std::sync::{Arc, Mutex};

pub async fn handle(
    api_key: String,
    event_key: String,
    app_state: tauri::State<'_, Arc<Mutex<AppState>>>,
) -> Result<(), ()> {
    info!(target: "save_settings", "handle");
    let state = Arc::clone(&app_state);

    info!(target: "save_settings", "handled: api_key:{:?}, event_key:{:?}", api_key, event_key);

    {
        match state.lock() {
            Ok(mut state_locked) => {
                state_locked.app_settings.api_key = Some(api_key.clone());
                state_locked.app_settings.event_key = Some(event_key.clone());
            }
            Err(_) => {
                info!(target: "save_settings", "handle: failed to lock app_state");
            }
        }
    }

    match state.lock() {
        Ok(state_locked) => {
            tauri::async_runtime::spawn(AppSettings::write(state_locked.app_settings.clone()));
        }
        Err(_) => {
            info!(target: "save_settings", "handle: failed to lock app_state");
        }
    }

    Ok(())
}
