package com.elpris.elprisapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class HomeScreenWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.price_widget)

        // Get data from Flutter
        val currentPrice = widgetData.getString("current_price", "--")
        val currentTime = widgetData.getString("current_time", "--")
        val region = widgetData.getString("region", "SE3")

        // Extract start time only (e.g., "14:00" from "14:00-14:15")
        val startTime = currentTime?.split("-")?.firstOrNull() ?: currentTime

        // Set current price data
        views.setTextViewText(R.id.widget_title, "Elpris - $region")
        views.setTextViewText(R.id.current_price, currentPrice)
        views.setTextViewText(R.id.current_time, startTime)

        // Set upcoming prices (6 periods)
        for (i in 0 until 6) {
            val timeId = context.resources.getIdentifier("upcoming_time_$i", "id", context.packageName)
            val priceId = context.resources.getIdentifier("upcoming_price_$i", "id", context.packageName)

            val time = widgetData.getString("upcoming_time_$i", null)
            val price = widgetData.getString("upcoming_price_$i", null)

            if (timeId != 0 && priceId != 0) {
                if (time != null && price != null) {
                    views.setTextViewText(timeId, time)
                    views.setTextViewText(priceId, price)
                } else {
                    views.setTextViewText(timeId, "--")
                    views.setTextViewText(priceId, "--")
                }
            }
        }

        // Set up click listener to open app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
