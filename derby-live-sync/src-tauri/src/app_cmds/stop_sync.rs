use crate::app_state::AppState;
use log::info;
use std::sync::{Arc, Mutex};

pub fn handle(app_state: tauri::State<'_, Arc<Mutex<AppState>>>) {
    info!(target: "stop_sync", "handle");
    match app_state.lock() {
        Ok(state_locked) => {
            if let Some(synchronizer) = &state_locked.synchronizer {
                synchronizer.stop();
            }
        }
        Err(_) => {
            info!(target: "stop_sync", "handle: failed to lock app_state");
        }
    }
}
