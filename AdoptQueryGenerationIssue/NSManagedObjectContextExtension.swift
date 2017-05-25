//
//  NSManagedObjectContextExtension.swift
//  AdoptQueryGenerationIssue
//
//  Created by Bill on 5/25/17.
//  Copyright © 2017 Headnix. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    func saveAndCatch() {
        do {
            try save()
        } catch {
            let contextError = error as NSError
            dump(contextError)
        }
    }

}
