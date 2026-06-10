package com.hack.toolbox

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.View
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        applySystemBarStyle()
        super.onCreate(savedInstanceState)
        applySystemBarStyle()
    }

    private fun applySystemBarStyle() {
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = APP_BACKGROUND_COLOR

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.navigationBarDividerColor = SYSTEM_BAR_DIVIDER_COLOR
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }

        var systemUiVisibility = window.decorView.systemUiVisibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            systemUiVisibility = systemUiVisibility or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            systemUiVisibility =
                systemUiVisibility or View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
        }
        window.decorView.systemUiVisibility = systemUiVisibility
    }

    companion object {
        private val APP_BACKGROUND_COLOR = Color.rgb(247, 249, 252)
        private val SYSTEM_BAR_DIVIDER_COLOR = Color.rgb(226, 232, 240)
    }
}
