package com.example.enmkit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

// BroadcastReceiver natif : capte les SMS entrants meme quand l'app est fermee.
// Filtre sur les numeros de kits connus puis empile le message dans SmsStore.
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        // Reconstruit les messages (un SMS long arrive en plusieurs PDUs).
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
        if (messages.isEmpty()) return

        val sender = messages[0].originatingAddress ?: ""
        val body = buildString {
            for (m in messages) append(m.messageBody ?: "")
        }

        // Filtre : ne garder que les SMS des numeros de kits connus.
        val store = SmsStore(context)
        if (!store.isKnownKit(sender)) return

        store.enqueue(sender, body, System.currentTimeMillis())
        // Reveille Flutter si l'app est vivante (sinon le message reste en file).
        SmsEventBridge.notifyNewSms()
    }
}
