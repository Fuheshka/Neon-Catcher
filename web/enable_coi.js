/* Registers a COOP/COEP-enabling service worker to unlock SharedArrayBuffer on GitHub Pages builds. */
(() => {
	if (globalThis.crossOriginIsolated) {
		return;
	}
	if (!('serviceWorker' in navigator)) {
		console.warn('COOP/COEP service worker not available: serviceWorker API missing.');
		return;
	}
	const alreadyReloaded = sessionStorage.getItem('coi-reloaded');
	navigator.serviceWorker.register('./coi-serviceworker.js').then((registration) => {
		if (alreadyReloaded) {
			return;
		}
		registration.addEventListener('updatefound', () => {
			const installingWorker = registration.installing;
			if (!installingWorker) {
				return;
			}
			installingWorker.addEventListener('statechange', () => {
				if (installingWorker.state === 'activated' || installingWorker.state === 'redundant') {
					sessionStorage.setItem('coi-reloaded', '1');
					location.reload();
				}
			});
		});
	}).catch((err) => {
		console.warn('COOP/COEP service worker registration failed:', err);
	});
})();
