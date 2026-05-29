package gr.webdevelopment.metaiospot

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.google.android.gms.ads.nativead.NativeAdOptions
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.widget.TextView
import android.view.LayoutInflater
import android.widget.ImageView
import android.view.View

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            ListTileNativeAdFactory(context)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

class ListTileNativeAdFactory(private val context: android.content.Context) :
    GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val nativeAdView = NativeAdView(context)
        val containerView = android.widget.LinearLayout(context).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(32, 24, 32, 24)
            setBackgroundColor(android.graphics.Color.parseColor("#162035"))
        }

        val headlineView = TextView(context).apply {
            text = nativeAd.headline
            setTextColor(android.graphics.Color.WHITE)
            textSize = 14f
            setTypeface(null, android.graphics.Typeface.BOLD)
        }

        val bodyView = TextView(context).apply {
            text = nativeAd.body
            setTextColor(android.graphics.Color.parseColor("#8899AA"))
            textSize = 12f
            setPadding(0, 8, 0, 0)
        }

        val ctaView = TextView(context).apply {
            text = nativeAd.callToAction
            setTextColor(android.graphics.Color.WHITE)
            textSize = 12f
            setPadding(32, 16, 32, 16)
            setBackgroundColor(android.graphics.Color.parseColor("#1D6FA4"))
            val shape = android.graphics.drawable.GradientDrawable()
            shape.cornerRadius = 40f
            shape.setColor(android.graphics.Color.parseColor("#1D6FA4"))
            background = shape
        }

        containerView.addView(headlineView)
        containerView.addView(bodyView)
        containerView.addView(ctaView)
        nativeAdView.addView(containerView)

        nativeAdView.headlineView = headlineView
        nativeAdView.bodyView = bodyView
        nativeAdView.callToActionView = ctaView
        nativeAdView.setNativeAd(nativeAd)

        return nativeAdView
    }
}
