package com.example.hris_flutter

import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.runners.Parameterized
import org.junit.runners.Parameterized.Parameters
import pl.leancode.patrol.PatrolJUnitRunner

@RunWith(Parameterized::class)
class MainActivityTest(private val dartTestName: String) {

    @Test
    fun runDartTest() {
        val instrumentation = InstrumentationRegistry.getInstrumentation() as PatrolJUnitRunner
        instrumentation.runDartTest(dartTestName)
    }

    companion object {
        @JvmStatic
        @Parameters(name = "{0}")
        fun testCases(): List<String> {
            val instrumentation = InstrumentationRegistry.getInstrumentation() as PatrolJUnitRunner
            instrumentation.setUp(MainActivity::class.java)
            instrumentation.waitForPatrolAppService()
            return instrumentation.listDartTests()
        }
    }
}
