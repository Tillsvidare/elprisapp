package com.elpris.elprisapp

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Color as AndroidColor
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import kotlin.math.max
import kotlin.math.min

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

        // Generate and set chart image
        val chartData = widgetData.getString("chart_data", null)
        val chartCount = widgetData.getString("chart_count", "0")

        Log.d("HomeScreenWidget", "Chart data: ${chartData?.length ?: 0} bytes, count: $chartCount")

        if (chartData != null && chartData.isNotEmpty()) {
            try {
                val chartBitmap = generateChartBitmap(chartData, 800, 240)
                views.setImageViewBitmap(R.id.price_chart_image, chartBitmap)
                Log.d("HomeScreenWidget", "Chart bitmap generated successfully")
            } catch (e: Exception) {
                Log.e("HomeScreenWidget", "Error generating chart bitmap", e)
                e.printStackTrace()
            }
        } else {
            Log.w("HomeScreenWidget", "No chart data available")
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

    private fun generateChartBitmap(chartDataJson: String, width: Int, height: Int): Bitmap {
        Log.d("HomeScreenWidget", "Generating chart bitmap from JSON: ${chartDataJson.take(100)}...")

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Parse chart data
        val jsonArray = JSONArray(chartDataJson)
        val prices = mutableListOf<Double>()
        val times = mutableListOf<String>()

        for (i in 0 until jsonArray.length()) {
            val obj = jsonArray.getJSONObject(i)
            prices.add(obj.getDouble("price"))
            val timeStr = obj.getString("time")
            // Extract hour from ISO string (e.g., "2026-01-11T14:00:00.000" -> "14")
            val hour = timeStr.substring(11, 13)
            times.add(hour)
        }

        Log.d("HomeScreenWidget", "Parsed ${prices.size} price points")

        if (prices.isEmpty()) {
            Log.w("HomeScreenWidget", "No prices in chart data, returning blank bitmap")
            return bitmap
        }

        val minPrice = prices.minOrNull() ?: 0.0
        val maxPrice = prices.maxOrNull() ?: 1.0
        val priceRange = maxPrice - minPrice
        val padding = 40f
        val bottomPadding = 50f // Extra space for time labels

        // Setup paint for line
        val linePaint = Paint().apply {
            color = AndroidColor.parseColor("#87CEEB") // Light blue
            strokeWidth = 4f
            style = Paint.Style.STROKE
            isAntiAlias = true
        }

        // Setup paint for fill area
        val fillPaint = Paint().apply {
            color = AndroidColor.parseColor("#4087CEEB") // Semi-transparent light blue
            style = Paint.Style.FILL
            isAntiAlias = true
        }

        // Setup paint for grid lines
        val gridPaint = Paint().apply {
            color = AndroidColor.parseColor("#33FFFFFF") // Semi-transparent white
            strokeWidth = 1f
            style = Paint.Style.STROKE
        }

        // Draw horizontal grid lines
        for (i in 0..3) {
            val y = padding + (height - 2 * padding) * i / 3
            canvas.drawLine(padding, y, width - padding, y, gridPaint)
        }

        // Create path for line chart
        val linePath = Path()
        val fillPath = Path()

        val chartWidth = width - 2 * padding
        val chartHeight = height - 2 * padding

        for (i in prices.indices) {
            val x = padding + (chartWidth * i / (prices.size - 1).coerceAtLeast(1))
            val normalizedPrice = if (priceRange > 0) {
                (prices[i] - minPrice) / priceRange
            } else {
                0.5
            }
            val y = padding + chartHeight - (normalizedPrice * chartHeight).toFloat()

            if (i == 0) {
                linePath.moveTo(x, y)
                fillPath.moveTo(x, height - padding)
                fillPath.lineTo(x, y)
            } else {
                linePath.lineTo(x, y)
                fillPath.lineTo(x, y)
            }
        }

        // Complete fill path
        fillPath.lineTo(width - padding, height - padding)
        fillPath.close()

        // Draw fill and line
        canvas.drawPath(fillPath, fillPaint)
        canvas.drawPath(linePath, linePaint)

        // Draw price labels
        val textPaint = Paint().apply {
            color = AndroidColor.parseColor("#B3FFFFFF") // Semi-transparent white
            textSize = 20f
            isAntiAlias = true
        }

        // Min price
        canvas.drawText(
            String.format("%.2f", minPrice),
            5f,
            height - padding + 5f,
            textPaint
        )

        // Max price
        canvas.drawText(
            String.format("%.2f", maxPrice),
            5f,
            padding + 20f,
            textPaint
        )

        // Draw time labels on x-axis (show every 6 hours to avoid clutter)
        val timeInterval = 24 // Show every 24 data points (6 hours, since 4 points per hour)
        for (i in times.indices step timeInterval) {
            val x = padding + (chartWidth * i / (prices.size - 1).coerceAtLeast(1))
            canvas.drawText(
                times[i],
                x - 10f, // Center the text approximately
                height - bottomPadding + 35f,
                textPaint
            )
        }

        // Always show the last time
        if (times.isNotEmpty() && times.size > 1) {
            val lastIndex = times.size - 1
            val x = width - padding
            canvas.drawText(
                times[lastIndex],
                x - 15f,
                height - bottomPadding + 35f,
                textPaint
            )
        }

        Log.d("HomeScreenWidget", "Chart drawn: ${prices.size} points, range $minPrice-$maxPrice")
        return bitmap
    }
}
