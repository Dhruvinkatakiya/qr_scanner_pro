package com.qrscannerpro.qr_scanner_pro

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * A simple 1x1+ home-screen widget with "Scan" and "Create" buttons that deep
 * link into the app via the same actions used by the launcher shortcuts.
 */
class QuickScanWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_scan)
            views.setOnClickPendingIntent(
                R.id.widget_scan_button,
                launchIntent(context, MainActivity.ACTION_SCAN, 0)
            )
            views.setOnClickPendingIntent(
                R.id.widget_create_button,
                launchIntent(context, MainActivity.ACTION_CREATE, 1)
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun launchIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = action
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
