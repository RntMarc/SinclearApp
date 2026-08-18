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
  direct_message: {
    title: 'Neue Nachricht',
    body: 'Du hast eine neue Nachricht.',
  },
  trip_user_added: {
    title: 'Du wurdest zu einer Reise hinzugefügt',
    body: 'Du wurdest zu einer Reise hinzugefügt.',
  },
  trip_user_added_others: {
    title: 'Neuer Teilnehmer auf der Reise',
    body: 'Ein neuer Teilnehmer wurde zur Reise hinzugefügt.',
  },
  trip_event_added: {
    title: 'Neues Event auf der Reise',
    body: 'Ein neues Event wurde zur Reise hinzugefügt.',
  },
  trip_event_user_added: {
    title: 'Du wurdest zu einem Event hinzugefügt',
    body: 'Du wurdest zu einem Event hinzugefügt.',
  },
  trip_event_user_added_others: {
    title: 'Neuer Teilnehmer beim Event',
    body: 'Ein neuer Teilnehmer wurde zum Event hinzugefügt.',
  },
  trip_event_info_changed: {
    title: 'Event-Informationen geändert',
    body: 'Die Event-Informationen wurden geändert.',
  },
  trip_event_ticket_added: {
    title: 'Neues Ticket für das Event',
    body: 'Ein neues Ticket wurde zum Event hinzugefügt.',
  },
  trip_ticket_added: {
    title: 'Neues Ticket für die Reise',
    body: 'Ein neues Ticket wurde zur Reise hinzugefügt.',
  },
  trip_accommodation_added: {
    title: 'Hotel-Zuweisung',
    body: 'Dir wurde ein Hotel zugewiesen.',
  },
  trip_subscription_added: {
    title: 'Neues Abo verknüpft',
    body: 'Ein Abo wurde mit der Reise verknüpft.',
  },
  trip_info_changed: {
    title: 'Reise-Informationen geändert',
    body: 'Die Reise-Informationen wurden geändert.',
  },
  standalone_event_user_added: {
    title: 'Du wurdest zu einem Event hinzugefügt',
    body: 'Du wurdest zu einem Event hinzugefügt.',
  },
  standalone_event_user_added_others: {
    title: 'Neuer Teilnehmer beim Event',
    body: 'Ein neuer Teilnehmer wurde zum Event hinzugefügt.',
  },
  standalone_event_info_changed: {
    title: 'Event-Informationen geändert',
    body: 'Die Event-Informationen wurden geändert.',
  },
  standalone_event_ticket_added: {
    title: 'Neues Ticket für das Event',
    body: 'Ein neues Ticket wurde zum Event hinzugefügt.',
  },
};

const FALLBACK_CONTENT = {
  title: 'Neue Mitteilung',
  body: 'Du hast eine neue Benachrichtigung.',
};

const TRIP_TYPES = new Set([
  'trip_user_added',
  'trip_user_added_others',
  'trip_event_added',
  'trip_event_user_added',
  'trip_event_user_added_others',
  'trip_event_info_changed',
  'trip_event_ticket_added',
  'trip_ticket_added',
  'trip_accommodation_added',
  'trip_subscription_added',
  'trip_info_changed',
]);

const STANDALONE_EVENT_TYPES = new Set([
  'standalone_event_user_added',
  'standalone_event_user_added_others',
  'standalone_event_info_changed',
  'standalone_event_ticket_added',
]);

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
  if (type === 'direct_message') {
    const conversationId = relationId(data, 'conversation');
    if (conversationId) return `/chat/${conversationId}`;
  }
  if (TRIP_TYPES.has(type)) {
    const tripId = relationId(data, 'trip');
    if (tripId) return `/reisen/${tripId}`;
  }
  if (STANDALONE_EVENT_TYPES.has(type)) {
    const eventId = relationId(data, 'event');
    if (eventId) return `/reisen/einzelevent/${eventId}`;
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
