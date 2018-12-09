//
//  ChessBoardView.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//

import UIKit

private extension Selector {
    static let handlePan = #selector(GameController.handlePan(_:))

}


final class ChessBoardView: UIView {

	private var panDelegate: AnyObject?
	
	
	class var squareSize: CGFloat {
		return SysUtils.deviceIsIPad ? 72.0 : 36.0
	}

	
	//MARK: utilities for getting square and piece info
	
	func movePieceFromSquare(_ fromSquare: SquarePosition, toSquare: SquarePosition) {

		if let pIV = self.getPieceImageViewForSquare(fromSquare) {
			pIV.frame = self.getFrameForSquare(toSquare)
		}
	}
		
	func removePieceFromSquare(_ square: SquarePosition) {
		
		if let pIV = self.getPieceImageViewForSquare(square) {
			pIV.removeFromSuperview()
		}
	}
	
	func getPieceImageViewForSquare(_ square: SquarePosition) -> PieceImageView? {
	
		let squareFrame = self.getFrameForSquare(square)
		let squareCenter = CGPoint(x: squareFrame.midX, y: squareFrame.midY)
		
		var pIV: PieceImageView?
		
		for subview in self.subviews {
			if let temp = subview as? PieceImageView {
				let contains = temp.frame.contains(squareCenter)
				if contains {
					pIV = temp
					break
				}
			}
		}
	
		return pIV
	}
	
	func addPiece(_ piece: ChessPiece, square:SquarePosition) {
		
		let frame = self.getFrameForSquare(square)
		let pIV = PieceImageView(frame: frame, type: piece.pieceType, isBlack: piece.isBlack)
		
		self.addSubview(pIV)
		let recognizer = UIPanGestureRecognizer(target: self.panDelegate!, action: .handlePan)
		recognizer.isEnabled = false		// multi-player will always initialize to false to wait for connection
		pIV.addGestureRecognizer(recognizer)
	}
	
	private func getFrameForSquare(_ square: SquarePosition) -> CGRect {
		return CGRect(x: CGFloat(square.columnNum) * ChessBoardView.squareSize, y: CGFloat(square.rowNum) * ChessBoardView.squareSize, width: ChessBoardView.squareSize, height: ChessBoardView.squareSize)
	}
	
	// allow moves for only the appropriate type - white, black or none (other player's turn)
	func enableMoveFor(_ color: EnableColor) {
	
		for subview in self.subviews {
			if let pIV = subview as? PieceImageView {
				if let pg: UIPanGestureRecognizer = pIV.gestureRecognizers!.first as? UIPanGestureRecognizer {
					pg.isEnabled = (color != .forNone) && ( (pIV.piece.isBlack && color == .forBlack) || (!pIV.piece.isBlack && color != .forBlack) )
				}
			}
		}
	}
	
	func getSquareFromView(_ view: UIView) -> SquarePosition {
	
		var square = SquarePosition(rowNum: -1, columnNum: -1)
		let squareCenter = CGPoint(x: view.frame.midX, y: view.frame.midY)
		
		for subview in self.subviews {
			if let squareView = subview as? ChessBoardSquareView,
				squareView.frame.contains(squareCenter) {
                square = SquarePosition(rowNum: squareView.row, columnNum: squareView.column)
            }
		}
	
		return square
	}
	
	
	
	//MARK: Initialization
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.layer.borderColor = UIColor.white.cgColor
		self.layer.borderWidth = 1.0
	}
	
	func setupBoard( _ firstTime : Bool, panDelegate: AnyObject ) {
		self.panDelegate = panDelegate
		
		if firstTime {
		
			var left: CGFloat = 0.0
			var top: CGFloat = 0.0
			var squareId = 0
			var rowNum = 0
			var colNum = 0
			
			for _ in 0...63 {
				squareId += 1
				let frame = CGRect(x: left, y: top, width: ChessBoardView.squareSize, height: ChessBoardView.squareSize)
                let squareView = ChessBoardSquareView(frame: frame)
				
                squareView.row = rowNum
                squareView.column = colNum

				if (squareId % 2) == 0  {
					squareView.backgroundColor = UIColor.white
				} else {
					squareView.backgroundColor = UIColor.darkGray
				}
                
                colNum += 1
				self.addSubview(squareView)
				
				left += ChessBoardView.squareSize
				if left > ( 7 * ChessBoardView.squareSize ) {
					left = 0.0
					top += ChessBoardView.squareSize
					squareId += 1
					rowNum += 1
					colNum = 0
				}
			}
		} else {
			// remove the piece views, but leave the square views
			for p in self.subviews {
				if p.isKind(of: PieceImageView.self) {
					p.removeFromSuperview()
				}
			}
		}
	}
	
}
