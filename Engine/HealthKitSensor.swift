import Foundation
import HealthKit

/// Reads step + walking distance totals from the system Health app.
/// Read-only: Crazy Hen Run never writes anything back to Health.
///
/// The authorization prompt is intentionally *not* fired at process launch —
/// callers decide when to ask (see `Yard.connectHealth()`), which the app
/// only does once the boot screen is gone and the user is looking at the
/// first onboarding guide (or, for returning users, the moment the tabs
/// appear). That keeps the system dialog off the splash screen entirely.
@Observable
final class HealthKitSensor {
    private let store = HKHealthStore()
    private let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
    private let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!

    private static let requestedKey = "hyard.health.requested.v1"

    /// False on iPad and other devices without a Health store.
    let available = HKHealthStore.isHealthDataAvailable()
    var authorized = false
    var todaySteps = 0

    private var didAskBefore: Bool {
        get { UserDefaults.standard.bool(forKey: Self.requestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.requestedKey) }
    }

    /// Fires the system prompt exactly once per install. Safe to call many
    /// times — every call after the first is a no-op.
    func connectOnce() {
        guard available, !didAskBefore else { return }
        didAskBefore = true
        requestAuthorization()
    }

    /// Lets the user retry from Settings or the Steps board after an initial
    /// decline, or after Health access changes in the Settings app.
    func requestAgain(completion: @escaping (Bool) -> Void = { _ in }) {
        guard available else { completion(false); return }
        requestAuthorization(completion: completion)
    }

    private func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        store.requestAuthorization(toShare: [], read: [stepType, distanceType]) { [weak self] ok, _ in
            DispatchQueue.main.async {
                self?.authorized = ok
                if ok { self?.refreshToday() }
                completion(ok)
            }
        }
    }

    /// Pulls today's cumulative step count. Cheap enough to call whenever a
    /// screen that shows steps appears.
    func refreshToday() {
        guard available else { return }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, _ in
            let sum = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async {
                self?.todaySteps = Int(sum.rounded())
            }
        }
        store.execute(query)
    }

    /// Backfills the local day-by-day chart with real Health totals so the
    /// Steps board matches the Health app even on days the run engine never
    /// touched the pedometer directly.
    func fetchDailySteps(days: Int, completion: @escaping ([String: Int]) -> Void) {
        guard available else { completion([:]); return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let start = cal.date(byAdding: .day, value: -(days - 1), to: today),
              let end = cal.date(byAdding: .day, value: 1, to: today) else {
            completion([:])
            return
        }
        var interval = DateComponents()
        interval.day = 1
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: today,
            intervalComponents: interval
        )
        query.initialResultsHandler = { _, results, _ in
            var byDay: [String: Int] = [:]
            results?.enumerateStatistics(from: start, to: end) { stats, _ in
                let sum = stats.sumQuantity()?.doubleValue(for: .count()) ?? 0
                if sum > 0 {
                    byDay[DayKey.make(stats.startDate)] = Int(sum.rounded())
                }
            }
            DispatchQueue.main.async { completion(byDay) }
        }
        store.execute(query)
    }
}
