//
//  MessageView.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//

import UIKit

enum DisplayStatus: Int {
	case connecting,
	waitForTurn,
	usersTurn,
	gameWon,
	gameLost
}



final class MessageView: UIView {

	var messageLabelView: UILabel!
	
    
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.commonInit()
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.commonInit()
	}
	
	private func commonInit() {
		
		self.messageLabelView = UILabel(frame: self.bounds)
		var font: UIFont
		if SysUtils.deviceIsIPad {
			font = UIFont(name: "HelveticaNeue", size: 24.0)!
		} else {
			font = UIFont(name: "HelveticaNeue", size: 18.0)!
		}
		self.messageLabelView.font = font
		
		self.messageLabelView.textAlignment = NSTextAlignment.center
		self.messageLabelView.textColor = UIColor.green
		
		self.addSubview(self.messageLabelView)
		
		self.setStatusDisplay(.connecting)
	}
	
	func setMessage(_ statusMessage: String) {
	
		self.messageLabelView.text = statusMessage
	}
	
	func setStatusDisplay(_ status: DisplayStatus) {
		var statusString: String
		
		switch (status) {
			case .connecting:
			statusString = "Seeking worthy opponent..."
			break
			
			case .waitForTurn:
			statusString = "Waiting..."
			break
			
			case .usersTurn:
			statusString = "Your turn..."
			break
			
			case .gameWon:
			statusString = "Game Over - You Won!"
			break
			
			case .gameLost:
			statusString = "Game Over - You Lost!"
			break
		}
			
		self.setMessage(statusString)
	}
	
	func addCheck() {
		self.messageLabelView.text = "Check! - " + self.messageLabelView.text!
	}

}
