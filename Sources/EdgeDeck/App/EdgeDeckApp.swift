import SwiftUI

@main
struct EdgeDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate: AppDelegate

    var body: some Scene {
        // Ayarlar penceresi AppRuntimeController.openSettingsWindow() tarafından yönetilir;
        // SwiftUI App bir sahne gerektirdiği için boş Settings sahnesi tutulur
        Settings {
            EmptyView()
        }
    }
}
