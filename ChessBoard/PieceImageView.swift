//
//  PieceImageView.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the Unlicense, see LICENSE file
//

import UIKit



final class PieceImageView: UIImageView {
	
	var piece: ChessPiece

	
	// For ordering pieces in the captured pieces tray
	func compare(_ rhs: PieceImageView) -> ComparisonResult {

		if self.piece.pieceType.rawValue > rhs.piece.pieceType.rawValue {
			return .orderedAscending
		}
		
		return .orderedDescending
	}
	
	init(frame:CGRect, type:ChessPiece.PieceType, isBlack:Bool) {
	
		self.piece = ChessPiece(pieceType: type, isBlack: isBlack)
		super.init(frame: frame)
		
        let imageName = "Images/Pieces/" + self.piece.name + (isBlack ? "-black" : "") + ".png"
		var image = UIImage(named: imageName)
		if isBlack {
			image = image!.rotatedBy(180.0)        // so Black gets to see its pieces right side up
		}
		self.image = image
		self.isUserInteractionEnabled = true
	}
	
	// used by captured items views
	init(frame:CGRect, image:UIImage, type:ChessPiece.PieceType, isBlack:Bool) {

		self.piece = ChessPiece(pieceType: type, isBlack: isBlack)
		super.init(frame: frame)
		
		var localImage = image
		if isBlack {
			localImage = image.rotatedBy(180.0)
		}
		self.image = localImage
	}

	required init?(coder aDecoder: NSCoder) {
		self.piece = ChessPiece(pieceType: ChessPiece.PieceType.pawn, isBlack: false)
	    super.init(coder: aDecoder)
	}
	
}
