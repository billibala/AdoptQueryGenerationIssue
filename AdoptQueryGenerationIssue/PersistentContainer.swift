//
//  HeadPinningAndAutoMergingPersistentContainer.swift
//  AdoptQueryGenerationIssue
//
//  Created by Bill on 5/25/17.
//  Copyright © 2017 Headnix. All rights reserved.
//

import Foundation
import CoreData

class HeadPinningAndAutoMergingPersistentContainer: NSPersistentContainer {
    let backgroundGroup = DispatchGroup()

    var importBackgroundContext: NSManagedObjectContext {
        if _importBackgroundContext == nil {
            // create the context
            _importBackgroundContext = newBackgroundContext()
            configure(managedObjectContext: _importBackgroundContext!)
            // we do NOT want server-side changes to overwrite user change when there's user change during the brief second when we are importing JSON from the server.
            _importBackgroundContext!.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        }
        return _importBackgroundContext!
    }

    /// When there's no import tasks, will be deallocated
    private var _importBackgroundContext: NSManagedObjectContext?

    fileprivate func configure(managedObjectContext context: NSManagedObjectContext) {
        // ======
        // Base on recommendation in WWDC 2016 - http://asciiwwdc.com/2016/sessions/242
        //
        // Speaking of common context work flows, the NSManagedObjectContext
        // has a new property this year called automatically merges changes from parent.
        //
        // It's a Boolean and when you set it to true the context will automatically
        // merge, save the change the data of its parent.
        //
        // This is really handy, it works for child context when the parent saves its
        // changes, and it also works for top level context when a sibling saves up to
        // the store.
        //
        // It works especially well with generation tokens which Melissa talked about
        // earlier.
        //
        // So your UIs can be maintenance free if you pin your UI context to the latest
        // generation and then enable automatic merging, your faults will be safe and
        // your object bindings and fetch results controllers will keep themselves up to
        // date.
        try! context.setQueryGenerationFrom(NSQueryGenerationToken.current)
        context.automaticallyMergesChangesFromParent = true
        // ======
    }

    override func loadPersistentStores(completionHandler block: @escaping (NSPersistentStoreDescription, Error?) -> Void) {
        backgroundGroup.enter()
        super.loadPersistentStores { (description, error) in
            self.configure(managedObjectContext: self.viewContext)
            self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            #if DEBUG
                print("Store location: \(description.url!.relativePath)")
            #endif
            block(description, error)
            self.backgroundGroup.leave()
        }
    }

    /*
     We want the contexts to complete wher there's no more queued blocks.
     i.e. we need to use "dispatch group" as barrier.

     Since persistent container has the "performBackgroundTask" pattern, we should explite this pattern and create a "perform background group task" method.
     */
    func performBackgroundGroupTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        backgroundGroup.enter()
        importBackgroundContext.perform { [unowned self] in
            // notify caller
            block(self.importBackgroundContext)
            self.backgroundGroup.leave()
        }
    }
}

//final class AutoMergingPersistentContainer: HeadPinningAndAutoMergingPersistentContainer {
//    override fileprivate func configure(managedObjectContext context: NSManagedObjectContext) {
//        context.automaticallyMergesChangesFromParent = true
//    }
//}
//
//final class SelfMergingPersistentContainer: HeadPinningAndAutoMergingPersistentContainer {
//    override fileprivate func configure(managedObjectContext context: NSManagedObjectContext) {
//        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: context, queue: nil) { [weak self] notification in
//            self?.handle(context: context, didSaveNotification: notification)
//        }
//    }
//
//    func handle(context: NSManagedObjectContext, didSaveNotification: Notification) {
//        if context === viewContext {
//            importBackgroundContext.performMergeChanges(from: didSaveNotification)
//        }
//        if context === importBackgroundContext {
//            viewContext.performMergeChanges(from: didSaveNotification)
//        }
//    }
//}

