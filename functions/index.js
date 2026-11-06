/**
 * REPCAMPUSOFT - Notificaciones push.
 *
 * Cada vez que la app crea un documento en `notifications/{notifId}` (reporte
 * creado, cambio de estado, falla de la app), esta función envía el push por
 * FCM al usuario destino o a todos los usuarios del rol destinatario.
 */
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const CANAL_ANDROID = "notificaciones_repcampusoft";

/** Roles que comparten el buzón `administrativo`. */
function rolesDelDestino(destinoRol) {
  // Los reportes de estudiantes también se notifican al superadministrador,
  // que los supervisa en modo lectura.
  if (destinoRol === "administrativo") {
    return ["administrativo", "mantenimiento", "superadministrador"];
  }
  return [destinoRol];
}

/** Reúne los tokens FCM de los destinatarios de la notificación. */
async function tokensDestino(db, data) {
  const tokens = new Set();

  if (data.uidDestino) {
    const snap = await db.doc(`users/${data.uidDestino}`).get();
    const token = snap.get("fcmToken");
    if (token) tokens.add(token);
  } else if (data.destinoRol) {
    const roles = rolesDelDestino(data.destinoRol);
    const snap = await db.collection("users").where("rol", "in", roles).get();
    snap.forEach((doc) => {
      if (doc.get("activo") !== false) {
        const token = doc.get("fcmToken");
        if (token) tokens.add(token);
      }
    });
  }

  return tokens;
}

/** Borra los tokens que FCM reportó como inválidos. */
async function limpiarTokensInvalidos(db, tokensInvalidos) {
  if (tokensInvalidos.length === 0) return;
  for (let i = 0; i < tokensInvalidos.length; i += 30) {
    const lote = tokensInvalidos.slice(i, i + 30);
    const snap = await db
      .collection("users")
      .where("fcmToken", "in", lote)
      .get();
    await Promise.all(snap.docs.map((doc) => doc.ref.update({ fcmToken: null })));
  }
}

exports.enviarPushNotificacion = onDocumentCreated(
  "notifications/{notifId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() || {};
    const db = getFirestore();
    const tokens = await tokensDestino(db, data);
    if (tokens.size === 0) {
      console.log(`Sin tokens para ${event.params.notifId}`);
      return;
    }

    const listaTokens = [...tokens];
    const mensaje = {
      tokens: listaTokens,
      notification: {
        title: String(data.titulo || "REPCAMPUSOFT"),
        body: String(data.mensaje || ""),
      },
      data: {
        notifId: String(event.params.notifId),
        tipo: String(data.tipo || ""),
        evento: String(data.evento || ""),
        reportId: String(data.reportId || ""),
        fallaId: String(data.fallaId || ""),
      },
      android: {
        priority: "high",
        notification: {
          channelId: CANAL_ANDROID,
          sound: "default",
        },
      },
      apns: {
        payload: { aps: { sound: "default" } },
      },
    };

    const respuesta = await getMessaging().sendEachForMulticast(mensaje);

    const invalidos = [];
    respuesta.responses.forEach((r, i) => {
      if (!r.success) {
        const codigo = (r.error && r.error.code) || "";
        if (
          codigo.includes("registration-token-not-registered") ||
          codigo.includes("invalid-argument") ||
          codigo.includes("invalid-registration-token")
        ) {
          invalidos.push(listaTokens[i]);
        }
      }
    });
    await limpiarTokensInvalidos(db, invalidos);

    console.log(
      `Push ${event.params.notifId}: ${respuesta.successCount} enviados, ` +
        `${respuesta.failureCount} fallidos`
    );
  }
);
