//
//  UnreadEntries.swift
//  Elytra
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import Foundation
import Models
import WidgetKit

struct UnreadEntries: TimelineEntry, Decodable {
    public let date: Date
    public var entries: [WidgetArticle]
}
