import AppKit
import InputMethodKit
import os

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var server: IMKServer?

    private let logger = Logger(
        subsystem: "dev.kaisol.Keysmash",
        category: "lifecycle"
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Input method process launched")

        guard
            let bundleIdentifier = Bundle.main.bundleIdentifier,
            let connectionName = Bundle.main.infoDictionary?[
                "InputMethodConnectionName"
            ] as? String
                else {
            logger.fault("Missing bundle identifier or connection name")
            return
        }

        logger.info("Creating IMKServer")

        server = IMKServer(
            name: connectionName,
            bundleIdentifier: bundleIdentifier
        )

        logger.info("IMKServer initialization returned")
    }
}

@objc(MyInputController)
final class MyInputController: IMKInputController {
    private let logger = Logger(
        subsystem: "dev.kaisol.Keysmash",
        category: "input"
    )

    override func activateServer(
        _ sender: Any!
    ) {
        super.activateServer(sender)
        logger.info("Input controller activated")
    }

    override func inputText(
        _ string: String!,
        key keyCode: Int,
        modifiers flags: Int,
        client sender: Any!
    ) -> Bool {
        logger.info("inputText called")
        return false
    }
}
