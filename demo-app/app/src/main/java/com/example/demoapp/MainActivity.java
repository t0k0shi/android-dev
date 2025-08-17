package com.example.demoapp;

import android.os.Build;
import android.os.Bundle;
import android.view.WindowManager;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
  @Override protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);

    // 画面点灯・ロック画面越え・常時点灯（API差分吸収）
    if (Build.VERSION.SDK_INT >= 27) {
      setTurnScreenOn(true);
      setShowWhenLocked(true);
    } else {
      getWindow().addFlags(
          WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        | WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
        | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
      );
    }

    setContentView(R.layout.activity_main);
  }
}
