importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: '***REMOVED***',
  appId: '***REMOVED***',
  messagingSenderId: '***REMOVED***',
  projectId: '***REMOVED***',
  authDomain: '***REMOVED***.firebaseapp.com',
  storageBucket: '***REMOVED***.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification('Sinclear', {
    body: 'Du hast eine neue Benachrichtigung.',
    icon: '/icons/icon-192x192.png',
    data: payload.data,
  });
});
