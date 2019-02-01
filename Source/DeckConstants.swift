//
//  Constants.swift
//  DeckTransition
//
//  Created by Harshil Shah on 04/08/17.
//  Copyright © 2017 Harshil Shah. All rights reserved.
//

import UIKit

public struct DeckConstants {
    
    /// The initial alpha value of the presented view controller's view
    static let alphaValueForDimView: CGFloat = 0.4
    
    /// On iPhone X/X Plus this will have additional space for safe area
    public static let topInsetForPresentedView: CGFloat = 8

    /// Describes how many pt user has to scroll in order to dismiss
    public static let translationRequiredToDismiss: CGFloat = 200
    
    /// After this distance dismissing of modal window is slowing down, if not set dismissing is linear
    public static let translationElasticThreshold: CGFloat? = nil
}
