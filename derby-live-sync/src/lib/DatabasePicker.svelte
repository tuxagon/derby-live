<script lang="ts">
  import { onMount } from "svelte";
  import { databasePath } from "./stores";
  import { invoke } from "@tauri-apps/api/tauri";
  import { listen } from "@tauri-apps/api/event";

  onMount(() => {
    console.log("onMount Settings");
    invoke("fetch_database_path").then((savedDatabasePath) => {
      databasePath.set(savedDatabasePath as string);
    });

    return () => {};
  });

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

<div class="flex flex-col items-center justify-center">
  <button on:click={openDatabase}>Select database</button>
  <p>
    {chosenDatabasePath == "" ? "No database selected" : chosenDatabasePath}
  </p>
</div>

<style>
  p {
    @apply mt-5;
  }
</style>
