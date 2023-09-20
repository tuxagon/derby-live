<script lang="ts">
  import Fa from "svelte-fa";
  import { faGear } from "@fortawesome/free-solid-svg-icons";
  import Settings from "./Settings.svelte";

  let isSpinning = false;
  let settingsOpen = false;

  const startSpinning = () => (isSpinning = true);
  const stopSpinning = () => (isSpinning = false);
  const toggleSettings = () => (settingsOpen = !settingsOpen);
</script>

<section class="py-4">
  <div class="flex flex-row-reverse">
    <ul>
      <li>
        <button
          on:mouseover={startSpinning}
          on:focus={startSpinning}
          on:mouseout={stopSpinning}
          on:blur={stopSpinning}
          on:click={toggleSettings}
        >
          <Fa
            icon={faGear}
            class="text-orange-600"
            scale={1.4}
            spin={isSpinning}
          /></button
        >
      </li>
    </ul>
  </div>
  {#if settingsOpen}
    <Settings bind:settingsOpen />
  {/if}
</section>

<style>
  button {
    @apply rounded-full cursor-pointer p-3;
  }
</style>
