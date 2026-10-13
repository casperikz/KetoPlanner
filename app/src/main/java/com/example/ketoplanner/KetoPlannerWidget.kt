package com.example.ketoplanner

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

class KetoPlannerWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "KetoPlannerWidgetPrefs"
        const val KEY_DAY = "widget_day"
        const val KEY_KCAL = "widget_kcal"
        const val KEY_TARGET_KCAL = "widget_target_kcal"
        const val KEY_PROTEIN = "widget_protein"
        const val KEY_TARGET_PROTEIN = "widget_target_protein"
        const val KEY_MEALS_JSON = "widget_meals_json"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val day = prefs.getString(KEY_DAY, "Day 1") ?: "Day 1"
            val kcal = prefs.getInt(KEY_KCAL, 0)
            val targetKcal = prefs.getInt(KEY_TARGET_KCAL, 2000)
            val protein = prefs.getInt(KEY_PROTEIN, 0)
            val targetProtein = prefs.getInt(KEY_TARGET_PROTEIN, 140)
            val mealsJson = prefs.getString(KEY_MEALS_JSON, "[]") ?: "[]"

            val views = RemoteViews(context.packageName, R.layout.widget_keto_planner)
            views.setTextViewText(R.id.widgetDay, day)
            views.setTextViewText(R.id.widgetKcal, "$kcal / $targetKcal kcal")
            views.setTextViewText(R.id.widgetProtein, "$protein / ${targetProtein}g")

            val mealsSummary = StringBuilder()
            try {
                val array = JSONArray(mealsJson)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val slot = obj.optString("slot", "")
                    val name = obj.optString("name", "—")
                    if (name.isNotEmpty() && name != "—") {
                        if (mealsSummary.isNotEmpty()) mealsSummary.append("\n")
                        mealsSummary.append("• $slot: $name")
                    }
                }
            } catch (e: Exception) {
                // Ignore parse errors
            }

            if (mealsSummary.isEmpty()) {
                views.setTextViewText(R.id.widgetMealsText, "No meals planned today")
            } else {
                views.setTextViewText(R.id.widgetMealsText, mealsSummary.toString())
            }

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, KetoPlannerWidget::class.java))
            for (id in ids) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }
    }
}
