use crate::settings::AppSettings;
use crate::synchronize::Synchronizer;

pub struct AppState {
    pub app_settings: AppSettings,
    pub synchronizer: Option<Synchronizer>,
}

impl Default for AppState {
    fn default() -> Self {
        Self {
            app_settings: Default::default(),
            synchronizer: Default::default(),
        }
    }
}
