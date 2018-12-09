//
//  UIImageExtensions.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//

import UIKit


public extension UIImage {
    
    func thumbnail(ofSize: CGSize, scale: CGFloat) -> UIImage? {

        let imageData = UIImagePNGRepresentation(self)! as CFData
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        let imageSource = CGImageSourceCreateWithData(imageData, imageSourceOptions)
        let downsampledImageSize = max(ofSize.width, ofSize.height)
        let options = [ kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceThumbnailMaxPixelSize: downsampledImageSize ] as CFDictionary
        
        let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource!, 0, options)!
        
        return UIImage(cgImage: downsampledImage)
    }
    
	
    private func DegreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat.pi / 180.0
    }
    
    private func RadiansToDegrees(_ radians: CGFloat) -> CGFloat {
        return radians * 180.0 / CGFloat.pi
    }
    
	func rotatedBy(_ degrees: CGFloat) -> UIImage {
	
		let rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
		let transform = CGAffineTransform(rotationAngle: DegreesToRadians(degrees))
        
		rotatedViewBox.transform = transform
		let rotatedSize = rotatedViewBox.frame.size
		
		UIGraphicsBeginImageContext(rotatedSize)
		let bitmap = UIGraphicsGetCurrentContext()
		
		// Move the origin to the middle of the image to rotate and scale around the center.
		bitmap?.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
		
		bitmap?.rotate(by: DegreesToRadians(degrees))
		
		// Now, draw the rotated/scaled image into the context
		bitmap?.scaleBy(x: 1.0, y: -1.0)
        bitmap?.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))
		
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
        
		return newImage!
	}
	
}

