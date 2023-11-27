//
//  FTPopOverMenuModel.swift
//  FTPopOverMenu_Swift
//
//  Created by liufengting on 2019/12/20.
//  Copyright © 2019 LiuFengting. All rights reserved.
//

import UIKit

public class FTPopOverMenuModel: NSObject {
    public var title: String = ""
    public var attributeTitle: NSMutableAttributedString? = nil  // icon_audition_draft_discRed 红点
    public var image: Imageable?
    public var selected: Bool = false
    public var extraInfo: Any?
    
    public convenience init(title: String, attributeTitle: NSMutableAttributedString? = nil, image: Imageable?, selected: Bool, extraInfo: Any? = nil) {
        self.init()
        self.title = title
        self.attributeTitle = attributeTitle
        self.image = image
        self.selected = selected
        self.extraInfo = extraInfo
    }
}
