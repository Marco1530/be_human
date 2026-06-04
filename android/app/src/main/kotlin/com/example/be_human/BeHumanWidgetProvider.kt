package com.example.be_human

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class BeHumanWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {

        val prefs = HomeWidgetPlugin.getData(context)

        val author = prefs.getString(
            "author",
            "Sin mensajes"
        )

        val message = prefs.getString(
            "message",
            "Deja tu primer post 💌"
        )

        for (appWidgetId in appWidgetIds) {

            val views = RemoteViews(
                context.packageName,
                R.layout.behuman_widget
            )

            views.setTextViewText(
                R.id.author,
                author
            )

            views.setTextViewText(
                R.id.message,
                message
            )

            appWidgetManager.updateAppWidget(
                appWidgetId,
                views
            )
        }
    }
}