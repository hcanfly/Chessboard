//
//  ChessBoardSquareView.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the Unlicense, see LICENSE file
//

import UIKit

final class ChessBoardSquareView: UIView {

	var row = 0
	var column = 0
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		let gradient = CAGradientLayer()
		gradient.frame = self.bounds
		gradient.colors = [UIColor.gray.cgColor, UIColor.clear.cgColor]
		self.layer.insertSublayer(gradient, at: 0)
	}

	required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}

}
