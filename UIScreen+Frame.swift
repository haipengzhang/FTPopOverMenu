//
//  UIScreen+Frame.swift
//  FTPopOverMenu_Swift
//
//  Created by Abdullah Selek on 27/07/2017.
//  Copyright © 2016 LiuFengting (https://github.com/liufengting) . All rights reserved.
//

import UIKit

public extension UIScreen {
    static func ft_width() -> CGFloat {
        return main.bounds.size.width
    }

    static func ft_height() -> CGFloat {
        return main.bounds.size.height
    }
}
