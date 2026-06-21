package com.example.enmkit

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

// Stockage persistant (SharedPreferences) de la file des SMS recus en
// arriere-plan et de la liste des numeros de kits a surveiller.
// Partage entre le BroadcastReceiver (ecriture) et le MethodChannel (lecture).
class SmsStore(context: Context) {
    private val prefs =
        context.getSharedPreferences("enmkit_sms_store", Context.MODE_PRIVATE)

    fun setKitNumbers(numbers: List<String>) {
        prefs.edit().putStringSet(KEY_KITS, numbers.toSet()).apply()
    }

    fun isKnownKit(sender: String): Boolean {
        val kits = prefs.getStringSet(KEY_KITS, emptySet()) ?: emptySet()
        if (kits.isEmpty()) return false
        val s = digits(sender)
        return kits.any { k ->
            val kd = digits(k)
            kd.isNotEmpty() && (kd.takeLast(8) == s.takeLast(8))
        }
    }

    @Synchronized
    fun enqueue(sender: String, body: String, timestamp: Long) {
        val arr = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
        val obj = JSONObject().apply {
            put("sender", sender)
            put("body", body)
            put("timestamp", timestamp)
        }
        arr.put(obj)
        prefs.edit().putString(KEY_QUEUE, arr.toString()).apply()
    }

    @Synchronized
    fun drain(): List<Map<String, Any>> {
        val arr = JSONArray(prefs.getString(KEY_QUEUE, "[]"))
        val out = ArrayList<Map<String, Any>>()
        for (i in 0 until arr.length()) {
            val o = arr.getJSONObject(i)
            out.add(
                mapOf(
                    "sender" to o.getString("sender"),
                    "body" to o.getString("body"),
                    "timestamp" to o.getLong("timestamp"),
                )
            )
        }
        prefs.edit().putString(KEY_QUEUE, "[]").apply()
        return out
    }

    private fun digits(s: String): String = s.replace(Regex("[^0-9]"), "")

    companion object {
        private const val KEY_KITS = "kit_numbers"
        private const val KEY_QUEUE = "sms_queue"
    }
}
