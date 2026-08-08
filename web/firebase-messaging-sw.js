importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBlL5ieWo7KdI5wPU0Y6RfgpLevAFTXQFo',
  appId: '1:814959952725:web:3dc12b5415fc11fd1e25dc',
  messagingSenderId: '814959952725',
  projectId: 'sinclear-beyond',
  authDomain: 'sinclear-beyond.firebaseapp.com',
  storageBucket: 'sinclear-beyond.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification('Sinclear', {
    body: 'Du hast eine neue Benachrichtigung.',
    icon: '/icons/icon-192x192.png',
    data: payload.data,
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const notificationId = (event.notification.data || {}).notificationId;
  const url = notificationId ? `/?notification=${notificationId}` : '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if ('navigate' in client) {
          return client.navigate(url).then(() => client.focus());
        }
      }
      return clients.openWindow(url);
    })
  );
});