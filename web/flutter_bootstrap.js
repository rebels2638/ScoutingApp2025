let useHtml = true;

// Initialize loading UI
const loading = document.querySelector('#loading');
const loadingProgress = document.createElement('p');
loadingProgress.style.color = '#0175C2';
loadingProgress.style.marginTop = '16px';
loading.appendChild(loadingProgress);

// Track asset loading
let assetsLoaded = 0;
let assetsTotal = 0;

// Preload critical assets
const preloadAssets = async () => {
  const criticalAssets = [
    'main.dart.js',
    'flutter.js',
    'assets/fonts/MaterialIcons-Regular.otf'
  ];
  
  assetsTotal = criticalAssets.length;
  
  const preloadPromises = criticalAssets.map(async (asset) => {
    try {
      const response = await fetch(asset);
      if (!response.ok) throw new Error(`Failed to load ${asset}`);
      assetsLoaded++;
      loadingProgress.textContent = `Loading assets (${assetsLoaded}/${assetsTotal})...`;
    } catch (error) {
      console.error('Asset preload failed:', error);
    }
  });

  await Promise.all(preloadPromises);
};

// Initialize Flutter app with better error handling
const initFlutterApp = async () => {
  loadingProgress.textContent = 'Initializing Flutter...';
  
  try {
    // Load Flutter engine
    await _flutter.loader.loadEntrypoint({
      onEntrypointLoaded: async function(engineInitializer) {
        loadingProgress.textContent = 'Starting app...';
        try {
          // Initialize engine with basic settings
          const appRunner = await engineInitializer.initializeEngine();
          
          // Run the app
          await appRunner.runApp();
          
          // Remove loading indicator
          if (loading) {
            loading.style.opacity = '0';
            setTimeout(() => loading.remove(), 500);
          }
        } catch (error) {
          console.error('Flutter app initialization failed:', error);
          loadingProgress.textContent = 'App initialization failed. Please check console and refresh.';
          throw error;
        }
      }
    });
  } catch (error) {
    console.error('Flutter engine loading failed:', error);
    loadingProgress.textContent = 'Engine loading failed. Please check console and refresh.';
    throw error;
  }
};

// Main initialization
window.addEventListener('load', async () => {
  try {
    await preloadAssets();
    await initFlutterApp();
  } catch (error) {
    console.error('App initialization failed:', error);
    // Show detailed error in UI
    const errorDetails = document.createElement('pre');
    errorDetails.style.color = 'red';
    errorDetails.style.margin = '16px';
    errorDetails.style.maxWidth = '800px';
    errorDetails.style.whiteSpace = 'pre-wrap';
    errorDetails.textContent = `Error: ${error.message}\n\nStack: ${error.stack}`;
    loading.appendChild(errorDetails);
  }
});

// Service worker registration
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('flutter_service_worker.js', {
      scope: './'
    }).catch(function(error) {
      console.error('Service Worker registration failed:', error);
    });
  });
}