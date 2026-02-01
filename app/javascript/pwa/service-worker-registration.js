// Service Worker Registration
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/service-worker.js')
            .then(registration => {
                console.log('✅ Service Worker registered successfully:', registration.scope);

                // Check for updates periodically
                setInterval(() => {
                    registration.update();
                }, 60000); // Check every minute
            })
            .catch(error => {
                console.error('❌ Service Worker registration failed:', error);
            });
    });

    // Handle service worker updates
    navigator.serviceWorker.addEventListener('controllerchange', () => {
        console.log('🔄 Service Worker updated, reloading page...');
        window.location.reload();
    });
}

// PWA Install Prompt
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
    // Prevent the mini-infobar from appearing on mobile
    e.preventDefault();
    // Stash the event so it can be triggered later
    deferredPrompt = e;

    console.log('💾 PWA install prompt available');

    // You can show your own install button here
    // Example: showInstallButton();
});

window.addEventListener('appinstalled', () => {
    console.log('✅ PWA installed successfully');
    deferredPrompt = null;
});

// Function to trigger install prompt (can be called from a button)
window.showPWAInstallPrompt = async () => {
    if (!deferredPrompt) {
        console.log('Install prompt not available');
        return;
    }

    // Show the install prompt
    deferredPrompt.prompt();

    // Wait for the user to respond to the prompt
    const { outcome } = await deferredPrompt.userChoice;
    console.log(`User response to install prompt: ${outcome}`);

    // Clear the deferred prompt
    deferredPrompt = null;
};
