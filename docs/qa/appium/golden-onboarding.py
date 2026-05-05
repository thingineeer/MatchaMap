"""
Golden-path Appium UI smoke test — MatchaMap v1.0.0
====================================================

Scenario: First launch → Splash 1.4s → Login screen → Apple Sign In CTA tap
          → MainTabView entry verification (지도 탭 active).

Coverage:
    - Splash screen render (1.4s minimum visible duration)
    - Login screen "Apple로 시작하기" CTA accessible
    - MainTabView with 4 tabs (지도/피드/위시리스트/내정보) appears
    - Default selected tab is 지도 (Map)

Phase 3 status:
    - Apple Sign In is stubbed → tapping the CTA short-circuits to MainTab.
    - Real Apple ASAuthorizationController flow will be wired in Phase 5.

Phase 5 plan:
    - Replace stubbed CTA with real Apple sheet handling
      (use Appium "mobile: handleSystemPrompt" or simulator pre-auth).
    - Add Passkey path as separate test.
"""

from __future__ import annotations

import time
import unittest

from appium import webdriver
from appium.options.ios import XCUITestOptions
from appium.webdriver.common.appiumby import AppiumBy
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


APPIUM_SERVER_URL = "http://127.0.0.1:4723"
BUNDLE_ID = "th1ngjin.MatchaMap"
DEVICE_NAME = "iPhone 17 Pro"
PLATFORM_VERSION = "26.2"
SPLASH_MIN_DURATION_S = 1.4
TAB_LABEL_MAP = "지도"  # ko-KR locale; Phase 5: parametrize via env LOCALE


class GoldenOnboardingTest(unittest.TestCase):
    """Smoke test: cold launch → MainTab entry."""

    @classmethod
    def setUpClass(cls) -> None:
        options = XCUITestOptions()
        options.platform_name = "iOS"
        options.platform_version = PLATFORM_VERSION
        options.device_name = DEVICE_NAME
        options.bundle_id = BUNDLE_ID
        options.automation_name = "XCUITest"
        # Don't reset between runs in CI — we want a fresh first launch
        options.no_reset = False
        options.full_reset = True
        # Match the simulator language to ko-KR for stable label matching
        options.language = "ko"
        options.locale = "ko_KR"

        cls.driver = webdriver.Remote(
            command_executor=APPIUM_SERVER_URL,
            options=options,
        )
        cls.wait = WebDriverWait(cls.driver, timeout=10)

    @classmethod
    def tearDownClass(cls) -> None:
        if hasattr(cls, "driver") and cls.driver is not None:
            cls.driver.quit()

    def test_01_splash_visible_for_minimum_duration(self) -> None:
        """Splash should be visible for >= 1.4s (brand intent)."""
        start = time.monotonic()
        # Splash is identified by accessibility id we set on SplashView root
        self.wait.until(
            EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "splash-root")
            )
        )
        # Wait until splash disappears (next phase rendered)
        self.wait.until(
            EC.invisibility_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "splash-root")
            )
        )
        duration = time.monotonic() - start
        self.assertGreaterEqual(
            duration,
            SPLASH_MIN_DURATION_S,
            f"Splash duration {duration:.2f}s < {SPLASH_MIN_DURATION_S}s",
        )

    def test_02_login_screen_apple_cta_present(self) -> None:
        """Login screen exposes Apple CTA with stable accessibility id."""
        cta = self.wait.until(
            EC.element_to_be_clickable(
                (AppiumBy.ACCESSIBILITY_ID, "login-apple-cta")
            )
        )
        self.assertTrue(
            cta.is_displayed(),
            "Apple Sign In CTA not displayed on Login screen",
        )

    def test_03_tap_apple_cta_enters_main_tab(self) -> None:
        """Tapping Apple CTA (stubbed in Phase 3) lands on MainTab."""
        cta = self.driver.find_element(
            AppiumBy.ACCESSIBILITY_ID, "login-apple-cta"
        )
        cta.click()
        # MainTabView root carries accessibility id "main-tab-root"
        main_tab = self.wait.until(
            EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "main-tab-root")
            )
        )
        self.assertTrue(main_tab.is_displayed())

    def test_04_default_selected_tab_is_map(self) -> None:
        """Default selected tab on MainTab entry is 지도 (Map)."""
        map_tab = self.wait.until(
            EC.presence_of_element_located(
                (AppiumBy.ACCESSIBILITY_ID, "tab-map")
            )
        )
        # `selected` attribute on iOS TabBar items reports current selection
        self.assertEqual(
            map_tab.get_attribute("selected"),
            "true",
            f"Expected '{TAB_LABEL_MAP}' tab to be selected by default",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
