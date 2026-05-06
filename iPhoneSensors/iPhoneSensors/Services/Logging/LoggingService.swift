import Foundation
import Combine

@MainActor
final class LoggingService: ObservableObject {
    let storage: LogStorageManager
    let configStore: LoggingConfigStore
    let bus: SensorEventBus
    let coordinator: LoggingCoordinator

    init(storage: LogStorageManager? = nil,
         configStore: LoggingConfigStore? = nil) {
        let s = storage ?? LogStorageManager()
        let c = configStore ?? LoggingConfigStore()
        self.storage = s
        self.configStore = c
        self.bus = SensorEventBus()
        self.coordinator = LoggingCoordinator(storage: s, configStore: c)
    }

    func bootstrap() async {
        let coord = self.coordinator
        await bus.setIngest { sample in await coord.ingest(sample) }
        await coordinator.start()
    }

    func attach(_ publisher: AnyPublisher<SensorSample, Never>) {
        bus.attach(publisher)
    }

    /// Wire the `SensorManager`'s throttle state into the coordinator.
    func attachThrottleSource(_ sensorManager: SensorManager) {
        sensorManager.loggingCoordinator = coordinator
    }

    /// Smoke helper for tests / preview.
    func enableContinuousAccelerometer() {
        configStore.set(LoggingConfiguration(
            continuous: .on(format: .jsonl, intervalMs: 100, options: .default),
            session: .off), for: .accelerometer)
    }

    func flush() async { await coordinator.flushAll() }
}
