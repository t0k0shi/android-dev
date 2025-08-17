package com.example.demoapp;

import static androidx.test.espresso.Espresso.onView;
import static androidx.test.espresso.assertion.ViewAssertions.matches;
import static androidx.test.espresso.matcher.ViewMatchers.withId;
import static androidx.test.espresso.matcher.ViewMatchers.withText;

import android.os.SystemClock;

import androidx.lifecycle.Lifecycle;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.uiautomator.UiDevice;

import org.junit.Test;
import org.junit.runner.RunWith;

import androidx.test.core.app.ActivityScenario;

@RunWith(AndroidJUnit4.class)
public class HelloUiTest {

  private void wakeAndUnlock() throws Exception {
    UiDevice device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());
    if (!device.isScreenOn()) device.wakeUp();
    // 念のためホーム→フォアグラウンド遷移を安定化
    device.pressHome();
    SystemClock.sleep(500);
  }

  @Test
  public void showsHelloText() throws Exception {
    wakeAndUnlock();

    ActivityScenario<MainActivity> scenario = ActivityScenario.launch(MainActivity.class);
    scenario.moveToState(Lifecycle.State.RESUMED);
    SystemClock.sleep(500); // レイアウト安定待ちの保険

    onView(withId(R.id.hello)).check(matches(withText("Hello UI Test")));
  }
}
