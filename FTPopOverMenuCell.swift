//
//  FTPopOverMenuCell.swift
//  FTPopOverMenu_Swift
//
//  Created by Abdullah Selek on 28/07/2017.
//  Copyright © 2016 LiuFengting (https://github.com/liufengting) . All rights reserved.
//

import UIKit

class FTPopOverMenuCell: UITableViewCell {
    fileprivate lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = UIColor.clear
        imageView.contentMode = UIView.ContentMode.scaleAspectFit
        self.contentView.addSubview(imageView)
        return imageView
    }()

    fileprivate lazy var nameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = UIColor.clear
        self.contentView.addSubview(label)
        return label
    }()

    func setupCellWith(menuName: FTMenuObject, menuImage: Imageable?, configuration: FTConfiguration) {
        backgroundColor = UIColor.clear
        
        // Configure cell text
        nameLabel.font = configuration.textFont
        nameLabel.textColor = configuration.textColor
        nameLabel.textAlignment = configuration.textAlignment
        nameLabel.frame = CGRect(x: FT.DefaultCellMargin, y: 0, width: configuration.menuWidth - FT.DefaultCellMargin * 2, height: configuration.menuRowHeight)

        var iconImage: UIImage?
        if menuName is String {
            nameLabel.text = menuName as? String
            iconImage = menuImage?.getImage()
        } else if menuName is FTPopOverMenuModel {
            if let attributeTitle = (menuName as! FTPopOverMenuModel).attributeTitle {
                if (menuName as! FTPopOverMenuModel).selected == true {
                    attributeTitle.addAttribute(.foregroundColor, value: configuration.selectedTextColor, range: NSRange(location: 0, length: attributeTitle.length))
                    attributeTitle.addAttribute(.font, value: configuration.selectedTextFont, range: NSRange(location: 0, length: attributeTitle.length))
                }
                nameLabel.attributedText = attributeTitle
            } else {
                nameLabel.text = (menuName as! FTPopOverMenuModel).title
                if (menuName as! FTPopOverMenuModel).selected == true {
                    nameLabel.textColor = configuration.selectedTextColor
                    nameLabel.font = configuration.selectedTextFont
                }
            }
            backgroundColor = configuration.selectedCellBackgroundColor
            iconImage = (menuName as! FTPopOverMenuModel).image?.getImage()
        }

        // Configure cell icon if available
        if iconImage != nil {
            if configuration.ignoreImageOriginalColor {
                iconImage = iconImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            }
            iconImageView.tintColor = configuration.textColor
            iconImageView.frame = CGRect(x: FT.DefaultCellMargin, y: (configuration.menuRowHeight - configuration.menuIconSize) / 2, width: configuration.menuIconSize, height: configuration.menuIconSize)
            iconImageView.image = iconImage
            nameLabel.frame = CGRect(x: FT.DefaultCellMargin + configuration.menuIconSize + 8, y: (configuration.menuRowHeight - configuration.menuIconSize) / 2, width: configuration.menuWidth - configuration.menuIconSize - FT.DefaultCellMargin - 8, height: configuration.menuIconSize)
        }

        nameLabel.alpha = configuration.cellAlaph
        iconImageView.alpha = configuration.cellAlaph
    }
}
