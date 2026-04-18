package ai.pipecat.client.flutter.pipecat

import kotlin.test.Test
import kotlin.test.assertNotNull

internal class PipecatFlutterPluginTest {
    @Test
    fun pluginInstantiates() {
        val plugin = PipecatFlutterPlugin()
        assertNotNull(plugin)
    }
}
