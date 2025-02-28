let useHtml = true;

window.addEventListener('load', function() {
  let loading = document.querySelector('#loading');
  _flutter.loader.loadEntrypoint({
    serviceWorker: {
      serviceWorkerVersion: serviceWorkerVersion,
    },
    onEntrypointLoaded: async function(engineInitializer) {
      let appRunner = await engineInitializer.initializeEngine({
        useColorEmoji: true,
      });
      await appRunner.runApp();
      if (loading) {
        loading.remove();
      }
    }
  });
});