//
//  SysUtils.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the Unlicense, see LICENSE file
//

import UIKit

class SysUtils {
	
	
	class var deviceIsIPad: Bool {
	
		return UIDevice.current.userInterfaceIdiom == .pad
	}
	
	class var iosVersion: CGFloat {
	
		let iosVersion = UIDevice.current.systemVersion
		
		return CGFloat((iosVersion as NSString).floatValue)
	}
	
	class var iosVersionAtLeastSix: Bool {
		return self.iosVersion >= 6.0
	}
	
	class var iosVersionAtLeastSeven: Bool {
		return self.iosVersion >= 7.0
	}
    
    class var iosVersionAtLeastEight: Bool {
        return self.iosVersion >= 8.0
    }
    
    class var iosVersionAtLeastNine: Bool {
        return self.iosVersion >= 9.0
    }
}
