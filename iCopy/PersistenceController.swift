import CoreData

class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ClipboardHistory")
        
        // 设置存储选项
        let storeDescription = NSPersistentStoreDescription()
        storeDescription.type = NSSQLiteStoreType
        
        // 获取应用支持目录
        if let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let storeURL = applicationSupportURL
                .appendingPathComponent("iCopy")
                .appendingPathComponent("ClipboardHistory.sqlite")
            
            // 确保目录存在
            try? FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            storeDescription.url = storeURL
        }
        
        // 设置存储选项
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        container.persistentStoreDescriptions = [storeDescription]
        
        container.loadPersistentStores { [self] (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data store failed to load: \(error.localizedDescription)")
                print("Detail: \(error.userInfo)")
                
                // 如果加载失败，尝试删除现有的存储文件
                if let url = storeDescription.url {
                    try? FileManager.default.removeItem(at: url)
                    try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
                    try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
                    
                    // 重新尝试加载
                    do {
                        try self.container.persistentStoreCoordinator.addPersistentStore(
                            ofType: NSSQLiteStoreType,
                            configurationName: nil,
                            at: storeDescription.url,
                            options: [
                                NSMigratePersistentStoresAutomaticallyOption: true,
                                NSInferMappingModelAutomaticallyOption: true
                            ]
                        )
                    } catch {
                        print("Failed to recover from Core Data load error: \(error)")
                        // 不要使用 fatalError，而是打印错误
                        print("Unresolved error \(error)")
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
} 