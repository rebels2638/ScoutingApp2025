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

// Initialize Flutter app
const initFlutterApp = async () => {
  loadingProgress.textContent = 'Loading Flutter engine...';

  try {
    // Load the Flutter engine
    await _flutter.loader.loadEntrypoint({
      serviceWorker: {
        serviceWorkerVersion: serviceWorkerVersion,
      },
      onEntrypointLoaded: async function(engineInitializer) {
        loadingProgress.textContent = 'Initializing engine...';
        
        try {
          const appRunner = await engineInitializer.initializeEngine({
            useColorEmoji: true,
            renderer: "canvaskit"
          });

          loadingProgress.textContent = 'Starting app...';
          await appRunner.runApp();
          
          // Remove loading indicator with fade
          if (loading) {
            loading.style.transition = 'opacity 0.5s ease-out';
            loading.style.opacity = '0';
            setTimeout(() => loading.remove(), 500);
          }
        } catch (error) {
          console.error('Failed to initialize engine:', error);
          loadingProgress.textContent = 'Failed to initialize engine. Please refresh the page.';
          throw error;
        }
      }
    });
  } catch (error) {
    console.error('Failed to load Flutter engine:', error);
    loadingProgress.textContent = 'Failed to load Flutter engine. Please refresh the page.';
    const errorDetails = document.createElement('pre');
    errorDetails.style.color = 'red';
    errorDetails.style.margin = '16px';
    errorDetails.textContent = error.toString();
    loading.appendChild(errorDetails);
  }
};

// Start initialization when the page is loaded
window.addEventListener('load', initFlutterApp);

// Register service worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function() {
    navigator.serviceWorker.register('flutter_service_worker.js', {
      scope: './'
    }).then(function(registration) {
      console.log('Service Worker registered');
    }).catch(function(error) {
      console.error('Service Worker registration failed:', error);
    });
  });
}