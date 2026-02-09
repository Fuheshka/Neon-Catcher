// Minimal COOP/COEP service worker for static hosting (e.g., GitHub Pages).
self.addEventListener('install', (event) => {
	self.skipWaiting();
});

self.addEventListener('activate', (event) => {
	event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
	const request = event.request;
	if (request.cache === 'only-if-cached' && request.mode !== 'same-origin') {
		return;
	}
	if (request.url.startsWith('chrome-extension://')) {
		return;
	}
	event.respondWith((async () => {
		const response = await fetch(request);
		const newHeaders = new Headers(response.headers);
		newHeaders.set('Cross-Origin-Opener-Policy', 'same-origin');
		newHeaders.set('Cross-Origin-Embedder-Policy', 'require-corp');
		return new Response(response.body, {
			status: response.status,
			statusText: response.statusText,
			headers: newHeaders,
		});
	})());
});
