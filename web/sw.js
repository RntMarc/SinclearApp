// Push-Payload der API: { id, type, data: [{relation, object, identifier}], createdAt }.
// Die API liefert bewusst keine Titel, Texte oder Routen — der Service
// Worker hat keinen API-Zugriff (kein Auth-Token) und kann daher keine
// Daten nachladen. Er zeigt die generalisierten Fallback-Texte an
// (Spiegelung von NotificationTypeLabel.title/fallbackBody in Dart).

const CONTENT_BY_TYPE = {
  forum_reply: {
    title: 'Neue Antwort',
    body: 'Jemand hat auf deinen Kommentar geantwortet',
  },
};

const FALLBACK_CONTENT = {
  title: 'Neue Mitteilung',
  body: 'Du hast eine neue Benachrichtigung.',
};

function relationId(data, relation) {
  if (!Array.isArray(data)) return null;
  const entry = data.find((e) => e && e.relation === relation && e.identifier);
  return entry ? entry.identifier : null;
}

// Deutsche Route lokal aus den Relation-IDs aufbauen (Spiegelung von
// NotificationTypeLabel.route). Fallback: '/home'.
function resolveRoute(type, data) {
  if (type === 'forum_reply') {
    const forumId = relationId(data, 'parent_forum');
    const postId = relationId(data, 'parent_post');
    if (forumId && postId) return `/forum/${forumId}/beitrag/${postId}`;
  }
  return '/home';
}

self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (e) {
    payload = {};
  }
  const content = CONTENT_BY_TYPE[payload.type] || FALLBACK_CONTENT;
  const options = {
    body: content.body,
    icon: '/pwa-icons/icon-192x192.png',
    badge: '/pwa-icons/icon-192x192.png',
    data: { type: payload.type, data: payload.data },
  };
  event.waitUntil(self.registration.showNotification(content.title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const payload = event.notification.data || {};
  const route = resolveRoute(payload.type, payload.data);

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.navigate(route);
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(route);
      }
    }),
  );
});
