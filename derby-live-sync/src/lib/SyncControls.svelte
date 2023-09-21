<script lang="ts">
  import SyncLog from "./SyncLog.svelte";
  import { invoke } from "@tauri-apps/api/tauri";
  import { listen } from "@tauri-apps/api/event";

  let isSyncRunning = false;
  let logs: string[] = [];

  const unlistenStart = listen("sync_started", (event) => {
    isSyncRunning = true;
  });

  const unlistenStop = listen("sync_stopped", (event) => {
    isSyncRunning = false;
  });

  const unlistenLog = listen("file_changed", (event) => {
    logs = [...logs, event.payload as string];
  });

  async function startSync() {
    await invoke("start_sync");
  }

  async function stopSync() {
    await invoke("stop_sync");
  }
</script>

<section class="m-0 mt-6 flex flex-col border-2 border-solid border-orange-600">
  <div class="m-0 flex flex-row justify-between items-center">
    <button disabled={isSyncRunning} on:click={startSync}>Start Sync </button>
    <button disabled={!isSyncRunning} on:click={stopSync}>Stop Sync </button>
  </div>
  <div class="sync-log">
    {#if logs.length === 0}
      <p class="self-center p-2 text-orange-600 font-bold">
        Click "Start Sync" to get logs
      </p>
    {:else}
      {#each logs as log}
        <div class="log-entry">
          <SyncLog {log} />
        </div>
      {/each}
    {/if}
  </div>
</section>

<style>
  button {
    @apply mx-2 mt-2;
  }
  button:disabled {
    @apply bg-gray-600 cursor-not-allowed;
  }
  button:disabled:hover {
    @apply border-gray-600;
  }

  .log-entry {
    @apply mt-2 border-orange-600 border-dashed border-b py-2;
  }
  .log-entry:last-child {
    @apply border-b-0;
  }

  .sync-log {
    @apply m-0 mt-8 px-4 flex flex-col justify-items-start;
  }
</style>
