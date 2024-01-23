<script lang="ts">
  import Fa from "svelte-fa";
  import { faGear } from "@fortawesome/free-solid-svg-icons";
  import { WebviewWindow } from "@tauri-apps/api/window";

  let isSpinning = false;

  const startSpinning = () => (isSpinning = true);
  const stopSpinning = () => (isSpinning = false);
  const toggleSettings = () => {
    stopSpinning();
    let window = WebviewWindow.getByLabel("manageAppSettings");
    if (window) {
      window.setFocus();
      return;
    } else {
      const webview = new WebviewWindow("manageAppSettings", {
        url: "screen/settings.html",
        title: "App Settings",
        alwaysOnTop: true,
      });

      webview.once("tauri://created", function () {
        console.log("webview window successfully created");
      });
      webview.once("tauri://error", function (e) {
        console.log("an error occurred during webview window creation", e);
      });
    }
  };
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
</section>

<style>
  button {
    @apply rounded-full cursor-pointer p-3;
  }
</style>
