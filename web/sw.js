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
  forum_post: {
    title: 'Neuer Beitrag im Forum',
    body: 'Jemand hat einen neuen Beitrag im Forum veröffentlicht.',
  },
  forum_upvote: {
    title: 'Neue Bewertung',
    body: 'Jemand hat deinen Beitrag positiv bewertet.',
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
  trip_leader_appointed: {
    title: 'Du bist jetzt Reiseleiter',
    body: 'Du bist jetzt Reiseleiter der Reise.',
  },
  trip_leader_appointed_others: {
    title: 'Neuer Reiseleiter auf der Reise',
    body: 'Ein Teilnehmer wurde zum Reiseleiter ernannt.',
  },
  trip_leader_removed: {
    title: 'Du bist nicht mehr Reiseleiter',
    body: 'Du bist nicht mehr Reiseleiter der Reise.',
  },
  trip_leader_removed_others: {
    title: 'Reiseleiter geändert',
    body: 'Ein Reiseleiter wurde geändert.',
  },
  standalone_event_leader_appointed: {
    title: 'Du bist jetzt Veranstalter',
    body: 'Du bist jetzt Veranstalter des Events.',
  },
  standalone_event_leader_appointed_others: {
    title: 'Neuer Veranstalter beim Event',
    body: 'Ein Teilnehmer wurde zum Veranstalter ernannt.',
  },
  standalone_event_leader_removed: {
    title: 'Du bist nicht mehr Veranstalter',
    body: 'Du bist nicht mehr Veranstalter des Events.',
  },
  standalone_event_leader_removed_others: {
    title: 'Veranstalter geändert',
    body: 'Ein Veranstalter wurde geändert.',
  },
  standalone_event_converted_to_trip: {
    title: 'Event wurde zu einer Reise hinzugefügt',
    body: 'Ein Event wurde zu einer Reise hinzugefügt.',
  },
  trip_event_converted_to_standalone: {
    title: 'Event wurde von der Reise gelöst',
    body: 'Ein Event wurde von der Reise gelöst.',
  },
  poll_invite: {
    title: 'Neue Umfrage-Einladung',
    body: 'Du wurdest zu einer Umfrage eingeladen.',
  },
  poll_counter_proposal: {
    title: 'Neuer Gegenvorschlag',
    body: 'Zu einer Terminfindung wurde ein neuer Gegenvorschlag abgegeben.',
  },
  poll_finalized: {
    title: 'Umfrage aktualisiert',
    body: 'Eine Umfrage wurde aktualisiert.',
  },
  poll_deadline_reminder: {
    title: 'Erinnerung: Umfrage endet bald',
    body: 'Eine Umfrage endet bald.',
  },
  trip_planning_invite: {
    title: 'Einladung zur Reiseplanung',
    body: 'Du wurdest zu einer Reiseplanung eingeladen.',
  },
  trip_planning_response: {
    title: 'Rückmeldung zur Reiseplanung',
    body: 'Ein Planungsmitglied hat sich zurückgemeldet.',
  },
  trip_planning_finalized: {
    title: 'Festlegung in der Reiseplanung',
    body: 'In der Reiseplanung wurde etwas festgelegt.',
  },
  trip_planning_activated: {
    title: 'Reiseplanung abgeschlossen',
    body: 'Die Reiseplanung wurde abgeschlossen.',
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
  'trip_leader_appointed',
  'trip_leader_appointed_others',
  'trip_leader_removed',
  'trip_leader_removed_others',
  'standalone_event_converted_to_trip',
]);

const STANDALONE_EVENT_TYPES = new Set([
  'standalone_event_user_added',
  'standalone_event_user_added_others',
  'standalone_event_info_changed',
  'standalone_event_ticket_added',
  'standalone_event_leader_appointed',
  'standalone_event_leader_appointed_others',
  'standalone_event_leader_removed',
  'standalone_event_leader_removed_others',
  'trip_event_converted_to_standalone',
]);

const POLL_TYPES = new Set([
  'poll_invite',
  'poll_counter_proposal',
  'poll_finalized',
  'poll_deadline_reminder',
]);

// Planungs-Typen tragen die `trip`-Relation, liegen aber unter
// `/reisen/planung/{trip}` statt `/reisen/{trip}`. Daher VOR TRIP_TYPES prüfen.
const PLANNING_TYPES = new Set([
  'trip_planning_invite',
  'trip_planning_response',
  'trip_planning_finalized',
  'trip_planning_activated',
]);

function relationId(data, relation) {
  if (!Array.isArray(data)) return null;
  const entry = data.find((e) => e && e.relation === relation && e.identifier);
  return entry ? entry.identifier : null;
}

// Deutsche Route lokal aus den Relation-IDs aufbauen (Spiegelung von
// NotificationTypeLabel.route). Fallback: '/home'.
function resolveRoute(type, data) {
  if (
    type === 'forum_reply' ||
    type === 'forum_comment' ||
    type === 'forum_post' ||
    type === 'forum_upvote'
  ) {
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
  if (PLANNING_TYPES.has(type)) {
    const tripId = relationId(data, 'trip');
    if (tripId) return `/reisen/planung/${tripId}`;
  }
  if (TRIP_TYPES.has(type)) {
    const tripId = relationId(data, 'trip');
    if (tripId) return `/reisen/${tripId}`;
  }
  if (STANDALONE_EVENT_TYPES.has(type)) {
    const eventId = relationId(data, 'event');
    if (eventId) return `/reisen/einzelevent/${eventId}`;
  }
  if (POLL_TYPES.has(type)) {
    const pollId = relationId(data, 'poll');
    if (pollId) return `/umfragen/${pollId}`;
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
