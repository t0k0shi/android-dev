package com.example.demo

import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.assertIsDisplayed
import org.junit.Rule
import org.junit.Test

class HelloComposeTest {
  @get:Rule val composeRule = createAndroidComposeRule<MainActivity>()

  @Test
  fun showsHelloText() {
    composeRule.onNodeWithText("Hello from Gradle + Compose!").assertIsDisplayed()
  }
}
