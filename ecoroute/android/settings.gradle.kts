pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withReader { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null : "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()
    // … rest omitted for brevity, Flutter generates this
}

include ":app"
