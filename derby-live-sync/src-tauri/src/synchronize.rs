extern crate notify;
extern crate rusqlite;
extern crate serde;
extern crate tauri;

use log::info;
use notify::{Config, PollWatcher, RecursiveMode, Watcher};
use serde::Serialize;
use std::{
    fmt,
    path::PathBuf,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
    time::Duration,
};
use tauri::AppHandle;

use crate::client_notify;
use crate::database;

#[derive(Clone)]
pub struct SyncState {
    app_handle: Arc<AppHandle>,
    watched_path: PathBuf,
    api_key: String,
    event_key: String,
    server_url: String,
}

#[derive(Debug)]
pub enum SyncCreationError {
    MissingWatchedPath,
    MissingApiKey,
    MissingEventKey,
    MissingServerUrl,
    NonExistentWatchedPath,
}

impl SyncState {
    pub fn try_new(
        app_handle: AppHandle,
        watched_path: Option<PathBuf>,
        api_key: Option<String>,
        event_key: Option<String>,
        server_url: Option<String>,
    ) -> Result<Self, SyncCreationError> {
        let watched_path = watched_path.ok_or(SyncCreationError::MissingWatchedPath)?;
        let api_key = api_key.ok_or(SyncCreationError::MissingApiKey)?;
        let event_key = event_key.ok_or(SyncCreationError::MissingEventKey)?;
        let server_url = server_url.ok_or(SyncCreationError::MissingServerUrl)?;

        if !watched_path.exists() {
            return Err(SyncCreationError::NonExistentWatchedPath);
        }

        Ok(Self {
            app_handle: Arc::new(app_handle),
            watched_path,
            api_key,
            event_key,
            server_url,
        })
    }
}

#[derive(Clone)]
pub struct Synchronizer {
    running: Arc<AtomicBool>,
    sync_state: Arc<SyncState>,
    watcher: Arc<Mutex<Option<PollWatcher>>>,
}

#[derive(Debug, Serialize)]
struct RequestData {
    event_key: String,
    racers: Vec<database::Racer>,
    racer_heats: Vec<database::RacerHeat>,
}

enum SyncMessage {
    SyncEvent(notify::Result<notify::Event>),
    SyncScan(notify::poll::ScanEvent),
}

#[derive(Debug)]
pub enum SyncError {
    DatabaseError(rusqlite::Error),
    UploadError(reqwest::Error),
    NotifyError(notify::Error),
}

impl fmt::Display for SyncError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            SyncError::DatabaseError(e) => write!(f, "DatabaseError: {}", e),
            SyncError::UploadError(e) => write!(f, "UploadError: {}", e),
            SyncError::NotifyError(e) => write!(f, "NotifyError: {}", e),
        }
    }
}

struct Uploader {
    api_key: String,
    event_key: String,
    server_url: String,
}

impl Synchronizer {
    pub fn new(sync_state: SyncState) -> Synchronizer {
        Synchronizer {
            running: Arc::new(AtomicBool::new(false)),
            sync_state: Arc::new(sync_state),
            watcher: Arc::new(Mutex::new(None)),
        }
    }

    async fn run_sync(sync_state: &SyncState) -> Result<(), SyncError> {
        info!(target: "sync", "run_sync");

        let database_path = sync_state.watched_path.clone();
        let db = database::Client::new(database_path.clone());
        let (racers, racer_heats) = match db.collect_data() {
            Ok(data) => data,
            Err(e) => {
                client_notify::sync_error(sync_state.app_handle.clone(), e.to_string());
                return Err(SyncError::DatabaseError(e));
            }
        };

        let (racer_count, racer_heat_count) = (racers.len(), racer_heats.len());
        info!(target: "sync", "run_sync: {} racers & {} racer heats", racer_count, racer_heat_count);

        let uploader = Uploader::new(
            sync_state.api_key.clone(),
            sync_state.event_key.clone(),
            sync_state.server_url.clone(),
        );
        uploader
            .upload(racers, racer_heats)
            .await
            .map_err(|e| client_notify::sync_error(sync_state.app_handle.clone(), e.to_string()))
            .ok();

        info!(target: "sync", "run_sync: complete");

        let message = format!(
            "Synced {} racers & {} racer heats",
            racer_count, racer_heat_count
        );
        client_notify::sync_updated(sync_state.app_handle.clone(), message);

        Ok(())
    }

    pub fn is_running(&self) -> bool {
        self.running.load(Ordering::Relaxed)
    }

    pub fn stop(&self) {
        self.set_running(false);
        client_notify::sync_stopped(self.sync_state.app_handle.clone());
    }

    pub fn start(&self) -> Result<(), SyncError> {
        if self.is_running() {
            return Ok(());
        }

        self.set_running(true);
        info!(target: "sync", "start_sync");

        // Standard channel for notify
        let (std_tx, std_rx) = std::sync::mpsc::channel();
        // Async channel for sync
        let (async_tx, mut async_rx) =
            tokio::sync::mpsc::channel::<Result<notify::Event, notify::Error>>(32);

        let sync_state_clone = self.sync_state.clone();
        let std_running_clone = self.running.clone();
        let async_running_clone = self.running.clone();

        let sync_state_clone_for_initial_sync = self.sync_state.clone();
        tauri::async_runtime::spawn(async move {
            let _ = Synchronizer::run_sync(&sync_state_clone_for_initial_sync).await;
        });

        // Start watching and add the watcher to self for broader lifetime
        self.try_create_watcher(std_tx)?;
        self.start_watch()?;

        client_notify::sync_started(sync_state_clone.app_handle.clone());

        std::thread::spawn(move || loop {
            while std_running_clone.load(Ordering::Relaxed) {
                match std_rx.recv_timeout(Duration::from_secs(1)) {
                    Ok(SyncMessage::SyncEvent(event)) => {
                        info!(target: "sync", "Received on std_rx: {:?}", event);
                        let _ = async_tx.blocking_send(event);
                    }
                    Ok(SyncMessage::SyncScan(scan_event)) => {
                        info!(target: "sync", "Received on std_rx: {:?}", scan_event);
                    }
                    Err(e) => {
                        info!(target: "sync", "std_rx error: {:?}", e);
                    }
                }
            }
        });

        tauri::async_runtime::spawn(async move {
            while async_running_clone.load(Ordering::Relaxed) {
                if let Some(Ok(event)) = async_rx.recv().await {
                    println!("Received on async_rx: {:?}", event);

                    let _ = Synchronizer::run_sync(&sync_state_clone).await;
                }
            }
        });

        Ok(())
    }

    fn start_watch(&self) -> Result<(), SyncError> {
        let watcher_clone = Arc::clone(&self.watcher);

        if let Some(watcher) = watcher_clone.lock().unwrap().as_mut() {
            let path = self.sync_state.watched_path.clone();

            info!(target: "sync", "start_watch: {:?}", path);

            watcher
                .watch(path.as_ref(), RecursiveMode::NonRecursive)
                .map_err(|e| SyncError::NotifyError(e))?;
        }

        Ok(())
    }

    fn try_create_watcher(
        &self,
        tx: std::sync::mpsc::Sender<SyncMessage>,
    ) -> Result<(), SyncError> {
        let watcher = Arc::clone(&self.watcher);
        let mut watcher_locked = watcher.lock().unwrap();

        let tx_clone = tx.clone();

        if watcher_locked.is_none() {
            info!(target: "sync", "try_create_watcher");
            let config = Config::default().with_poll_interval(Duration::from_secs(1));

            let new_watcher = PollWatcher::with_initial_scan(
                move |watch_event| {
                    tx_clone.send(SyncMessage::SyncEvent(watch_event)).unwrap();
                },
                config,
                move |scan_event| {
                    tx.send(SyncMessage::SyncScan(scan_event)).unwrap();
                },
            )
            .map_err(|e| SyncError::NotifyError(e))?;

            *watcher_locked = Some(new_watcher);
        }

        Ok(())
    }

    fn set_running(&self, running: bool) {
        self.running.store(running, Ordering::Relaxed);
    }
}

impl Uploader {
    fn new(api_key: String, event_key: String, server_url: String) -> Uploader {
        Uploader {
            api_key,
            event_key,
            server_url,
        }
    }

    async fn upload(
        &self,
        racers: Vec<database::Racer>,
        racer_heats: Vec<database::RacerHeat>,
    ) -> Result<(), SyncError> {
        let client = reqwest::Client::new();
        let request_data = RequestData {
            event_key: self.event_key.clone(),
            racers,
            racer_heats,
        };
        info!(target: "sync", "upload: event_key:{:?}, server_url:{:?}, api_key:{:?}", self.event_key, self.server_url, self.api_key);

        let url = format!("{}/api/data", self.server_url);

        let _resp = client
            .post(url)
            .header("x-api-key", &self.api_key)
            .json(&request_data)
            .send()
            .await
            .map_err(|e| SyncError::UploadError(e))?;

        Ok(())
    }
}
