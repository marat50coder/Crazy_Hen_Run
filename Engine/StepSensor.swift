import CoreMotion
import Foundation

@Observable
final class StepSensor {
    private let pedometer = CMPedometer()
    private var demo: Timer?

    var available = CMPedometer.isStepCountingAvailable()
    var authorized = false
    var todaySteps = 0
    var liveSteps = 0
    var walking = false

    private var dayBaseline: Int?
    private var runAnchor: Int?
    private var lastRaw = 0

    func askAndStart() {
        guard CMPedometer.isStepCountingAvailable() else {
            authorized = false
            available = false
            return
        }
        pedometer.queryPedometerData(from: Date(), to: Date()) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.authorized = error == nil
                if error == nil { self?.listen() }
            }
        }
    }

    func listen() {
        available = CMPedometer.isStepCountingAvailable()
        guard available else { return }
        let from = Calendar.current.startOfDay(for: .now)
        pedometer.startUpdates(from: from) { [weak self] data, _ in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                let raw = data.numberOfSteps.intValue
                self.lastRaw = raw
                if self.dayBaseline == nil { self.dayBaseline = 0 }
                self.todaySteps = max(0, raw)
                if let anchor = self.runAnchor {
                    self.liveSteps = max(0, raw - anchor)
                }
            }
        }
        authorized = true
    }

    func markRunStart() {
        runAnchor = lastRaw
        liveSteps = 0
        #if targetEnvironment(simulator)
        startDemo()
        #endif
    }

    func markRunEnd() {
        runAnchor = nil
        stopDemo()
    }

    func stop() {
        pedometer.stopUpdates()
        stopDemo()
    }

    private func startDemo() {
        stopDemo()
        demo = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.lastRaw += Int.random(in: 1...2)
            self.todaySteps += 1
            self.liveSteps += 1
            self.walking = true
        }
    }

    private func stopDemo() {
        demo?.invalidate()
        demo = nil
        walking = false
    }
}
