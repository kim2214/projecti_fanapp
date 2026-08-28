package com.devkim.honeyz_fan_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * "지금 방송 중" 홈스크린 위젯. Flutter(LiveWidgetService)가 home_widget 저장소에
 * 넣은 JSON({updatedAt, live:[{name,group,title,viewers,url}]})을 그린다.
 *
 * 데이터가 오래됐으면(5분↑ — 주기 갱신·위젯 첫 배치) Dart 백그라운드 콜백을 요청해
 * 서버 집계를 다시 읽게 한다. 갱신되면 updatedAt이 신선해져 재요청되지 않는다.
 */
class LiveStatusWidgetProvider : HomeWidgetProvider() {

    companion object {
        // LiveWidgetService.dataKey 와 반드시 일치
        const val DATA_KEY = "live_widget_json"
        private const val STALE_MS = 5 * 60 * 1000L
        private const val REFRESH_URI = "projectifanapp://widget/refresh"

        private val ROW_IDS = intArrayOf(R.id.row1, R.id.row2, R.id.row3, R.id.row4)
        private val NAME_IDS = intArrayOf(R.id.name1, R.id.name2, R.id.name3, R.id.name4)
        private val TITLE_IDS = intArrayOf(R.id.title1, R.id.title2, R.id.title3, R.id.title4)
        private val VIEWERS_IDS =
            intArrayOf(R.id.viewers1, R.id.viewers2, R.id.viewers3, R.id.viewers4)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = widgetData.getString(DATA_KEY, null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
        val updatedAt = payload?.optLong("updatedAt", 0L) ?: 0L
        val live: JSONArray? = payload?.optJSONArray("live")

        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, render(context, payload, live, updatedAt))
        }

        // 첫 배치(데이터 없음) 또는 주기 갱신으로 데이터가 오래됐을 때만 재조회 요청.
        if (System.currentTimeMillis() - updatedAt > STALE_MS) {
            runCatching {
                HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse(REFRESH_URI)).send()
            }
        }
    }

    private fun render(
        context: Context,
        payload: JSONObject?,
        live: JSONArray?,
        updatedAt: Long,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.live_status_widget)
        views.setTextViewText(R.id.updated, updatedLabel(context, updatedAt))
        // 헤더 탭 → 앱 실행
        views.setOnClickPendingIntent(
            R.id.header,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val count = live?.length() ?: 0
        when {
            payload == null -> {
                views.setViewVisibility(R.id.empty, View.VISIBLE)
                views.setTextViewText(R.id.empty, context.getString(R.string.widget_loading))
            }
            count == 0 -> {
                views.setViewVisibility(R.id.empty, View.VISIBLE)
                views.setTextViewText(R.id.empty, context.getString(R.string.widget_no_live))
            }
            else -> views.setViewVisibility(R.id.empty, View.GONE)
        }

        for (i in ROW_IDS.indices) {
            val item = if (i < count) live?.optJSONObject(i) else null
            if (item == null) {
                views.setViewVisibility(ROW_IDS[i], View.GONE)
                continue
            }
            views.setViewVisibility(ROW_IDS[i], View.VISIBLE)
            views.setTextViewText(NAME_IDS[i], item.optString("name"))
            views.setTextViewText(TITLE_IDS[i], item.optString("title"))
            views.setTextViewText(
                VIEWERS_IDS[i],
                context.getString(
                    R.string.widget_viewers,
                    String.format(Locale.KOREA, "%,d", item.optInt("viewers")),
                ),
            )
            // 행 탭 → 치지직 방송 (URL은 Dart의 Member.liveUrlOf에서 파생돼 전달됨)
            val url = item.optString("url")
            if (url.isNotEmpty()) {
                views.setOnClickPendingIntent(ROW_IDS[i], openUrlIntent(context, url, i))
            }
        }

        // 카드의 빈 영역 탭: 방송이 하나뿐이면 어디를 눌러도 그 방송으로, 아니면 앱으로.
        // (헤더·행은 자식 뷰의 PendingIntent가 우선하므로 나머지 영역만 이 동작을 탄다.)
        val soleUrl = if (count == 1) live?.optJSONObject(0)?.optString("url").orEmpty() else ""
        views.setOnClickPendingIntent(
            R.id.widget_root,
            if (soleUrl.isNotEmpty()) openUrlIntent(context, soleUrl, 99)
            else HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        val overflow = count - ROW_IDS.size
        if (overflow > 0) {
            views.setViewVisibility(R.id.more, View.VISIBLE)
            views.setTextViewText(R.id.more, context.getString(R.string.widget_more, overflow))
        } else {
            views.setViewVisibility(R.id.more, View.GONE)
        }
        return views
    }

    private fun updatedLabel(context: Context, updatedAt: Long): String {
        if (updatedAt <= 0L) return context.getString(R.string.widget_updated_pending)
        val minutes = ((System.currentTimeMillis() - updatedAt) / 60_000L).toInt()
        return if (minutes < 1) {
            context.getString(R.string.widget_updated_just)
        } else {
            context.getString(R.string.widget_updated_min, minutes)
        }
    }

    private fun openUrlIntent(context: Context, url: String, index: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= 23) flags = flags or PendingIntent.FLAG_IMMUTABLE
        // 행(100+i)·빈 영역(99)마다 requestCode를 달리 해야 PendingIntent가 서로 덮어쓰지 않는다.
        return PendingIntent.getActivity(context, 100 + index, intent, flags)
    }
}
