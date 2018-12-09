//
//  CapturedPiecesView.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//

import UIKit





final class CapturedPiecesView: UIView {

	private var capturedPieces = [PieceImageView]()
	
	
	func addCapturedPieceToCollection(_ pieceImage: UIImage, capturedPiece: PieceImageView) {
		
		let isiPad = SysUtils.deviceIsIPad
		let thumbnailSize: CGFloat = isiPad ? 36.0 : 18.0
		let xOffset: CGFloat = isiPad ? 40.0 : 20.0
        let scaledImage = pieceImage.thumbnail(ofSize: CGSize(width: thumbnailSize, height: thumbnailSize), scale: UIScreen.main.scale)
		
		let newFrame = CGRect(x: CGFloat(self.subviews.count) * xOffset, y: 0.0, width: thumbnailSize, height: thumbnailSize)
		let pieceIV = PieceImageView(frame: newFrame, image: scaledImage!, type: capturedPiece.piece.pieceType, isBlack: capturedPiece.piece.isBlack)
		
		self.capturedPieces.append(pieceIV)
		
		if pieceIV.piece.pieceType == ChessPiece.PieceType.pawn {
			self.addSubview(pieceIV)	// pawns are drawn at the end of the list, so no need to re-sort
		} else {
			self.capturedPieces.sort(by: { $0.piece.pieceType.rawValue > $1.piece.pieceType.rawValue })
			let subViews = self.subviews
			for subview in subViews {
				subview.removeFromSuperview()
			}
			for p in self.capturedPieces {
				let newFrame = CGRect(x: 6.0 + (CGFloat(self.subviews.count) * xOffset), y: 0.0, width: thumbnailSize, height: thumbnailSize)
				p.frame = newFrame
				self.addSubview(p)
			}
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
}
