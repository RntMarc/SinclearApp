// Push-Payload der API: { id, type, title, text, data: [{relation, object, identifier}], createdAt }.
// `title`/`text` sind API-generiert; der Service Worker bevorzugt sie und
// fällt ohne sie auf die generalisierten Fallback-Texte zurück (Spiegelung
// von NotificationTypeLabel.title/fallbackBody in Dart).

const CONTENT_BY_TYPE = {
  forum_reply: {
    title: 'Neue Antwort auf deinen Kommentar',
    body: 'Jemand hat auf deinen Kommentar geantwortet.',
  },
  forum_comment: {
    title: 'Neuer Kommentar zu deinem Beitrag',
    body: 'Jemand hat deinen Beitrag kommentiert.',
  },
  story_post: {
    title: 'Neue Story',
    body: 'Jemand hat eine neue Story veröffentlicht.',
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
  if (type === 'forum_reply' || type === 'forum_comment') {
    const forumId = relationId(data, 'parent_forum');
    const postId = relationId(data, 'parent_post');
    if (forumId && postId) return `/forum/${forumId}/beitrag/${postId}`;
  }
  if (type === 'story_post') {
    const storyId = relationId(data, 'story');
    if (storyId) return `/stories/${storyId}`;
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
  const fallback = CONTENT_BY_TYPE[payload.type] || FALLBACK_CONTENT;
  const options = {
    body: payload.text || fallback.body,
    icon: '/pwa-icons/icon-192x192.png',
    badge: '/pwa-icons/icon-192x192.png',
    data: { type: payload.type, data: payload.data },
  };
  event.waitUntil(
    self.registration.showNotification(payload.title || fallback.title, options),
  );
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
