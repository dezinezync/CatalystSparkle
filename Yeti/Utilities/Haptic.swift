//
//  Haptic.swift
//  Elytra
//
//  Created by Nikhil Nigade on 02/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//  https://gist.github.com/mrugeshtank/9d7fc3e2dbe5b4554d0169bb40128e5c
//

import Foundation
import CoreHaptics

class Haptics {
    
    enum HapticType {
        case impactLight
        case impactMedium
        case impactHeavy
        case selectionChange
        case notificationSuccess
        case notificationError
        case notificaitonWarning
    }
    
    static let shared = Haptics()
    
    private let impactMediumGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.medium)
    private let impactHeavyGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.heavy)
    private let impactLightGenerator = UIImpactFeedbackGenerator(style: UIImpactFeedbackGenerator.FeedbackStyle.light)
    
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    func generate(feedbackType type: HapticType) {
        switch type {
        case .impactLight:
            impactLightGenerator.prepare()
            impactLightGenerator.impactOccurred()
        case .impactMedium:
            impactMediumGenerator.prepare()
            impactMediumGenerator.impactOccurred()
        case .impactHeavy:
            impactHeavyGenerator.prepare()
            impactHeavyGenerator.impactOccurred()
        case .selectionChange:
            selectionGenerator.prepare()
            selectionGenerator.selectionChanged()
        case .notificationSuccess:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.success)
        case .notificationError:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.error)
        case .notificaitonWarning:
            notificationGenerator.prepare()
            notificationGenerator.notificationOccurred(.warning)
        }
    }
}
