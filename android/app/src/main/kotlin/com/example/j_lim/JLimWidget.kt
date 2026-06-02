package com.example.j_lim

import android.app.ActivityManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.widget.RemoteViews
import kotlin.math.roundToInt

class JLimWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
        val views = RemoteViews(context.packageName, R.layout.jlim_widget)

        // RAM
        try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val mi = ActivityManager.MemoryInfo()
            am.getMemoryInfo(mi)
            val usedPct = ((mi.totalMem - mi.availMem).toFloat() / mi.totalMem * 100).roundToInt()
            val ramColor = when {
                usedPct < 50  -> 0xFF00E87A.toInt()
                usedPct < 75  -> 0xFFFFB800.toInt()
                else          -> 0xFFFF3B3B.toInt()
            }
            views.setTextViewText(R.id.widget_ram_value, "$usedPct%")
            views.setTextColor(R.id.widget_ram_value, ramColor)
        } catch (_: Exception) {
            views.setTextViewText(R.id.widget_ram_value, "--")
        }

        // Bateria + Temperatura
        try {
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val intent = context.registerReceiver(null, filter)
            if (intent != null) {
                val level  = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale  = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val temp   = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
                val pct    = if (scale > 0) (level.toFloat() / scale * 100).roundToInt() else 0
                val tempC  = temp / 10.0

                val batColor = when {
                    pct > 50  -> 0xFF00E87A.toInt()
                    pct > 20  -> 0xFFFFB800.toInt()
                    else      -> 0xFFFF3B3B.toInt()
                }
                val tempColor = when {
                    tempC < 40 -> 0xFF00E87A.toInt()
                    tempC < 45 -> 0xFFFFB800.toInt()
                    else       -> 0xFFFF3B3B.toInt()
                }

                views.setTextViewText(R.id.widget_bat_value, "$pct%")
                views.setTextColor(R.id.widget_bat_value, batColor)
                views.setTextViewText(R.id.widget_temp_value, "${tempC.toInt()}°C")
                views.setTextColor(R.id.widget_temp_value, tempColor)
            }
        } catch (_: Exception) {
            views.setTextViewText(R.id.widget_bat_value, "--")
            views.setTextViewText(R.id.widget_temp_value, "--°C")
        }

        manager.updateAppWidget(id, views)
    }
}
