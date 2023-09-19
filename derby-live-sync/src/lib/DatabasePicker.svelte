<script lang="ts">
  import { databasePath } from "./stores";
  import { invoke } from "@tauri-apps/api/tauri";
  import { listen } from "@tauri-apps/api/event";

  let chosenDatabasePath = "";

  databasePath.subscribe((path) => {
    chosenDatabasePath = path;
  });

  async function openDatabase() {
    const unlisten = listen("database_chosen", (event) => {
      databasePath.set(event.payload as string);
      unlisten;
    });

    invoke("open_database");
  }
</script>

<div>
  <button on:click={openDatabase}>Select database</button>
  <p>
    {chosenDatabasePath == "" ? "No database selected" : chosenDatabasePath}
  </p>
</div>
