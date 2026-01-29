import Foundation
import CoreData
import Combine

class ClipboardCleanupManager: ObservableObject {
    static let shared = ClipboardCleanupManager()

    @Published var nextCleanupDate: Date?
    @Published var timeUntilNextCleanup: String = ""

    private var timer: Timer?
    private var displayTimer: Timer?
    private let context: NSManagedObjectContext

    private let lastCleanupKey = "lastClipboardCleanupDate"

    private init() {
        self.context = PersistenceController.shared.container.viewContext
        setupCleanupTimer()
        setupDisplayTimer()
        calculateNextCleanupDate()
    }

    // MARK: - 设置清理定时器
    private func setupCleanupTimer() {
        // 每小时检查一次是否需要清理
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.checkAndPerformCleanup()
        }

        // 立即执行一次检查
        checkAndPerformCleanup()
    }

    // MARK: - 设置显示更新定时器
    private func setupDisplayTimer() {
        // 每分钟更新一次倒计时显示
        displayTimer?.invalidate()
        displayTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateTimeUntilNextCleanup()
        }

        // 立即更新一次
        updateTimeUntilNextCleanup()
    }

    // MARK: - 检查并执行清理
    private func checkAndPerformCleanup() {
        let autoCleanInterval = UserDefaults.standard.double(forKey: "autoCleanInterval")

        // 如果设置为0天，表示不自动清理
        guard autoCleanInterval > 0 else {
            nextCleanupDate = nil
            timeUntilNextCleanup = "未启用"
            return
        }

        let lastCleanupDate = getLastCleanupDate()
        let intervalInSeconds = autoCleanInterval * 24 * 60 * 60
        let nextCleanup = lastCleanupDate.addingTimeInterval(intervalInSeconds)

        // 如果当前时间已经超过下次清理时间，执行清理
        if Date() >= nextCleanup {
            performCleanup(olderThan: autoCleanInterval)
            saveLastCleanupDate(Date())
            calculateNextCleanupDate()
        } else {
            nextCleanupDate = nextCleanup
            updateTimeUntilNextCleanup()
        }
    }

    // MARK: - 执行清理
    private func performCleanup(olderThan days: Double) {
        let cutoffDate = Date().addingTimeInterval(-days * 24 * 60 * 60)

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "ClipboardItem")
        fetchRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)

        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchDeleteRequest.resultType = .resultTypeObjectIDs

        do {
            let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
            if let objectIDs = result?.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                print("✅ 自动清理完成：删除了 \(objectIDs.count) 条记录")
            }
        } catch {
            print("❌ 自动清理失败: \(error)")
        }
    }

    // MARK: - 计算下次清理日期
    private func calculateNextCleanupDate() {
        let autoCleanInterval = UserDefaults.standard.double(forKey: "autoCleanInterval")

        guard autoCleanInterval > 0 else {
            nextCleanupDate = nil
            timeUntilNextCleanup = "未启用"
            return
        }

        let lastCleanupDate = getLastCleanupDate()
        let intervalInSeconds = autoCleanInterval * 24 * 60 * 60
        nextCleanupDate = lastCleanupDate.addingTimeInterval(intervalInSeconds)
        updateTimeUntilNextCleanup()
    }

    // MARK: - 更新倒计时显示
    private func updateTimeUntilNextCleanup() {
        guard let nextCleanup = nextCleanupDate else {
            timeUntilNextCleanup = "未启用"
            return
        }

        let now = Date()
        let timeInterval = nextCleanup.timeIntervalSince(now)

        if timeInterval <= 0 {
            timeUntilNextCleanup = "即将清理"
            return
        }

        let days = Int(timeInterval / (24 * 60 * 60))
        let hours = Int((timeInterval.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
        let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 60 * 60)) / 60)

        if days > 0 {
            timeUntilNextCleanup = "\(days)天\(hours)小时后"
        } else if hours > 0 {
            timeUntilNextCleanup = "\(hours)小时\(minutes)分钟后"
        } else {
            timeUntilNextCleanup = "\(minutes)分钟后"
        }
    }

    // MARK: - 获取上次清理日期
    private func getLastCleanupDate() -> Date {
        if let lastCleanup = UserDefaults.standard.object(forKey: lastCleanupKey) as? Date {
            return lastCleanup
        }
        // 如果没有记录，返回当前时间作为初始值
        let now = Date()
        saveLastCleanupDate(now)
        return now
    }

    // MARK: - 保存上次清理日期
    private func saveLastCleanupDate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: lastCleanupKey)
    }

    // MARK: - 公共方法

    // 手动触发清理检查（当设置改变时调用）
    func refreshCleanupSchedule() {
        calculateNextCleanupDate()
        checkAndPerformCleanup()
    }

    // 立即执行清理（用于手动清理）
    func performImmediateCleanup() {
        let autoCleanInterval = UserDefaults.standard.double(forKey: "autoCleanInterval")
        guard autoCleanInterval > 0 else { return }

        performCleanup(olderThan: autoCleanInterval)
        saveLastCleanupDate(Date())
        calculateNextCleanupDate()
    }

    deinit {
        timer?.invalidate()
        displayTimer?.invalidate()
    }
}
