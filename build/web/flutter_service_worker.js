'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "d6a2a9ed8b3d7ff4e0900dc0bae27371",
"assets/AssetManifest.bin.json": "1f4a345ac171ae6f1d2747522a236a0c",
"assets/AssetManifest.json": "b4691f73e92ff3cb795d8508a857615c",
"assets/assets/DroidSans-Bold.ttf": "dcf628f6a96d050d6943492fad1b591c",
"assets/assets/good%2520times%2520rg.ttf": "39636dd7d7cd4a3a84d9a73a23b30770",
"assets/assets/logo.png": "91f42512334911cb7f3e3cf8d79e56d0",
"assets/assets/logo111.png": "c93cab2a6a664b6522bd9c0781bb90d6",
"assets/assets/logo12.png": "42169cfa8ef667970eb4992475a25481",
"assets/assets/logo121.png": "62075bb9af81b4ac41af7f3dbdbc04d5",
"assets/assets/logo13.png": "1df8ac5f6e05e321dd0e21142345c7e3",
"assets/assets/Lottie/blue%2520loading.json": "1684bbaaa56df75751376aa01fa03cac",
"assets/assets/Lottie/Bouncing%2520ball.json": "3b28313b37ac6da0dad07a9583292238",
"assets/assets/Lottie/Email%2520motion%2520loading.json": "34f53c197feea09e2913224a202d94d3",
"assets/assets/Lottie/error404.json": "ea930c44df70f4bebc90d9e2c4c54587",
"assets/assets/Lottie/Loading1.json": "bc3ba5ce1c23cdf70dcc340cf235492d",
"assets/assets/Lottie/NoData.json": "cb6f89e700b516f719cae5d46233aee0",
"assets/assets/Lottie/NoInternet.json": "de21c81e7deadf2bd03e0c72ad22e090",
"assets/assets/Lottie/Queue%2520Users%2520Search.json": "5a6cc7e655d3727d4952242a7aedbf20",
"assets/assets/Lottie/Sandy%2520Loading.json": "504ee20883574220ec5cf2af2a6db599",
"assets/assets/Lottie/Searching%2520File.json": "64cf56127aeb5285c1e13b7d352358b2",
"assets/assets/Lottie/Successful.json": "d851f164c5de374640f572ce6812a6d0",
"assets/assets/Lottie/Waiting.json": "21857210fb775d092fa904af0ab8dfd4",
"assets/assets/ramchinlogo.png": "28bfd6bd76b4c26ac348d6c93a0f3399",
"assets/assets/ramchinlogoB.png": "106422390acfddff7553a419b1fb181f",
"assets/assets/Roboto-Regular.ttf": "234b64c0278d3bd2fd4855d358ad642f",
"assets/assets/subrare.pdf": "4c78a36cbd2824059e3c8a21b4267165",
"assets/FontManifest.json": "880f569cf8aeb6a812c6c368cbe37fde",
"assets/fonts/MaterialIcons-Regular.otf": "d9836fe9e3a73ddcfdfad56da0780dea",
"assets/NOTICES": "ff247129f87060b7d37037ce09969984",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "1e5d47a0bc1559e57273e04652e4751f",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "262525e2081311609d1fdab966c82bfc",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "5738a7424d0f04095fc57d3058492bfa",
"assets/packages/health_icons/fonts/healthicons.ttf": "bca0aa18e82823eead65e23d1ee801dd",
"assets/packages/health_icons/fonts/health_icons_outline.ttf": "21c22c9074e42409a17b73a5e0a5143d",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "65c1ae4dfae5ebd7935bd9ee67cba128",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "e16a9569cc3dc557699b041bd1141a24",
"icons/Icon-192.png": "65c1ae4dfae5ebd7935bd9ee67cba128",
"icons/Icon-512.png": "65c1ae4dfae5ebd7935bd9ee67cba128",
"icons/Icon-maskable-192.png": "65c1ae4dfae5ebd7935bd9ee67cba128",
"icons/Icon-maskable-512.png": "65c1ae4dfae5ebd7935bd9ee67cba128",
"index.html": "39d1d0217543bb454e80e7a823452e13",
"/": "39d1d0217543bb454e80e7a823452e13",
"main.dart.js": "055444d68a600d202f855631bc4a0627",
"manifest.json": "d0732ffd84d46ab3a3f54978bc7c7735",
"version.json": "abc99648c36f66ed763530ae6a2bf962"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
