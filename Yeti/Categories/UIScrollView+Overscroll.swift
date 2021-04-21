//
//  UIScrollView+Overscroll.swift
//  Elytra
//
//  Created by Nikhil Nigade on 21/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import UIKit

// MARK: - Overscrolling Bug

enum ScrollAxis {
  case vertical
  case horizontal
}

extension UIScrollView {
    
    /// Whether or not the calendar's scroll view is currently overscrolling, i.e, whether the rubber-banding or bouncing effect is in
    /// progress.
    ///
    /// We only scroll vertically in Elytra, so I've disabled horizontal scrolling code in here.
    func offset(for scrollAxis: ScrollAxis) -> CGFloat {
        switch scrollAxis {
        case .vertical: return contentOffset.y
        case .horizontal: return contentOffset.x
        }
    }
    
    func minimumOffset(for scrollAxis: ScrollAxis) -> CGFloat {
        switch scrollAxis {
            case .vertical: return -contentInset.top
            case .horizontal: return -contentInset.left
        }
    }

    func maximumOffset(for scrollAxis: ScrollAxis) -> CGFloat {
        switch scrollAxis {
            case .vertical: return contentSize.height + contentInset.bottom - bounds.height
            case .horizontal: return contentSize.width + contentInset.right - bounds.width
        }
    }
    
}

// MARK: Scroll View Silent Updating
extension UIScrollView {

  func performWithoutNotifyingDelegate(_ operations: () -> Void) {
    let delegate = self.delegate
    self.delegate = nil

    operations()

    self.delegate = delegate
  }

}
