import Foundation
import Combine

actor SensorEventBus {
    private var subscriptions: [AnyCancellable] = []
    private var ingest: ((SensorSample) async -> Void)?

    func setIngest(_ ingest: @escaping (SensorSample) async -> Void) {
        self.ingest = ingest
    }

    nonisolated func attach(_ publisher: AnyPublisher<SensorSample, Never>) {
        Task { await self.attachAsync(publisher) }
    }

    private func attachAsync(_ publisher: AnyPublisher<SensorSample, Never>) {
        let sub = publisher.sink { [weak self] sample in
            Task { await self?.deliver(sample) }
        }
        subscriptions.append(sub)
    }

    private func deliver(_ sample: SensorSample) async {
        await ingest?(sample)
    }
}
