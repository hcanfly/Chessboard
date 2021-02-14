//
//  Game.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the Unlicense, see LICENSE file
//

import UIKit


struct SquarePosition : Codable {
	let rowNum: Int
	let columnNum: Int
}

struct PieceInfo {
	let square: SquarePosition
	let isBlack: Bool
	let type: ChessPiece.PieceType
}

// which pieces, if any, for which to enable gestures for turns
enum EnableColor: Int {
	case forBlack,
	forWhite,
	forNone
}

struct Move: Codable {
    
    var fromSquare: SquarePosition?
    var toSquare: SquarePosition?
    
}


protocol GameDelegate: class {

	func pieceAdded(_ piece: ChessPiece, toSquare: SquarePosition)
}



final class Game {
	
	private var chessBoardPieces = [[ChessPiece?]]()                   // data model. array is [row][column]
	private weak var delegate: GameDelegate?
	
	var didCastle = false
	

	//MARK: Piece positioning
	
	func movePiece(_ piece: ChessPiece, toSquare:SquarePosition) {
		self.chessBoardPieces[toSquare.rowNum][toSquare.columnNum] = piece
	}
	
	func getCurrentPieceForSquare(_ square: SquarePosition) -> ChessPiece? {
		return self.chessBoardPieces[square.rowNum][square.columnNum]
	}
	
	func removePieceFromSquare(_ square: SquarePosition) {
		self.chessBoardPieces[square.rowNum][square.columnNum] = nil
	}
	
	// when doing castling, get the current position of the rook based on the king's move
	func currentRookPositionForKingCastlingMoveTo(_ square: SquarePosition) -> SquarePosition {
	
		let rookSquare = SquarePosition(rowNum: square.rowNum, columnNum: square.columnNum == 1 ? 0 : 7)
		
		return rookSquare
	}
	
	// when doing castling, get the new position of the rook based on the king's move
	func newRookPositionForKingCastlingMoveTo(_ square: SquarePosition) -> SquarePosition {
	
		let castleSquare = SquarePosition(rowNum: square.rowNum, columnNum: square.columnNum == 1 ? 2 : 5)
	
		return castleSquare
	}
	
	
	
	//MARK: - Legal Move Rules
	
	private func moveIsRowOrColumnFromSquare(_ square: SquarePosition, toSquare: SquarePosition) -> Bool {
	
		return ( (toSquare.rowNum == square.rowNum) || (toSquare.columnNum == square.columnNum) )
	}
	
	private func isRowOrColumnEmptyFromSquare(_ square: SquarePosition, toSquare: SquarePosition) -> Bool {
	
		if square.rowNum == toSquare.rowNum  {       // checking same row
			let fromColumn = min(toSquare.columnNum, square.columnNum) + 1    // don't check starting or ending squares
			let toColumn = max(toSquare.columnNum, square.columnNum)
			for c in fromColumn ..< toColumn {
				if chessBoardPieces[toSquare.rowNum][c] != nil {
                    return false
				}
			}
		}
		else {                                             // check column
			let fromRow = min(toSquare.rowNum, square.rowNum) + 1
			let toRow = max(toSquare.rowNum, square.rowNum)
			for r in fromRow ..< toRow {
				if chessBoardPieces[r][square.columnNum] != nil {
                    return false
				}
			}
		}
	
		return true
	}
	
	private func moveIsDiagonalFromSquare(_ square: SquarePosition, toSquare: SquarePosition) -> Bool {
	
		return ( abs(toSquare.rowNum - square.rowNum) == (abs(toSquare.columnNum - square.columnNum)) )
	}
	
	private func isDiagonalEmptyFromSquare(_ square: SquarePosition, toSquare: SquarePosition) -> Bool {  // square column must be less than toSquare column
	
		var fromRow: Int
		var fromColumn: Int
		var toColumn: Int
		
		// orient so test is always going down
		if square.rowNum < toSquare.rowNum {
			fromRow = square.rowNum
			fromColumn = square.columnNum
			//toRow = toSquare.rowNum
			toColumn = toSquare.columnNum
		}
		else {
			fromRow = toSquare.rowNum
			fromColumn = toSquare.columnNum
			toColumn = square.columnNum
		}
		
		if toColumn > (fromColumn + 1) {                        // diagonal is down to right
            var r = fromRow + 1
            for c in (fromColumn + 1)...(toColumn - 1) {        // don't check starting or ending squares
				if chessBoardPieces[r][c] != nil {
					return false
				}
                r += 1
			}
		}
		else {                                      // diagonal is down to left
            var r = fromRow + 1
            var c = fromColumn - 1
            while c >= (toColumn + 1) {
				if chessBoardPieces[r][c] != nil {
					return false
				}
                c -= 1
                r += 1
			}
		}
	
		return true
	}
	
	
    // TODO: I know that several minor rules are not being enforced. 1) En Passant is not supported at all, 2) the tests for a valid Castle are not complete,
    // 3) it's been a long time since I've played chess seriously so I may have forgotten something else.
    // This app has been a learning experience, not an attempt to create a complete commercial app.
	func isLegalMoveForPiece(_ pieceView: ChessPiece, fromSquare: SquarePosition, toSquare: SquarePosition) -> Bool {
	
		let destinationPiece = chessBoardPieces[toSquare.rowNum][toSquare.columnNum]					// is there a piece on the square we're moving to?
	
		if (destinationPiece != nil) && (destinationPiece!.isBlack == pieceView.isBlack) {				// can't move if piece of same color is there
			return false
        }
	
		self.didCastle = false
		var isLegal = false
		let numRowsMoved = abs(toSquare.rowNum - fromSquare.rowNum)
		let numColumnsMoved = abs(toSquare.columnNum - fromSquare.columnNum)
	
		switch (pieceView.pieceType) {
			case ChessPiece.PieceType.pawn:
				// the basics: pawn can move one or two rows from start pos else only one
				if ( (pieceView.isBlack && ((toSquare.rowNum > fromSquare.rowNum) && ( (fromSquare.rowNum == 1) ? numRowsMoved < 3 : (numRowsMoved == 1) )) )
						|| ( !pieceView.isBlack && ((toSquare.rowNum < fromSquare.rowNum) && ( (fromSquare.rowNum == 6) ? (numRowsMoved < 3) : (numRowsMoved == 1) ))) ) {
				
					// not bothering with en passant moves because it requires too much state info to bother with
					// must be in same column unless taking a piece, then can be in column on either side
					if ( (destinationPiece == nil) && (toSquare.columnNum != fromSquare.columnNum)) || (numColumnsMoved > 1) {
						return isLegal
                    }
					
					if ( (numRowsMoved == 2) && (self.isRowOrColumnEmptyFromSquare(fromSquare, toSquare: toSquare) == false ) ) {
						return isLegal
					}
					
					isLegal = true
				}
			
			case ChessPiece.PieceType.knight:
				isLegal = ( (numColumnsMoved == 2) && (numRowsMoved == 1) ) || ( (numRowsMoved == 2) && (numColumnsMoved == 1) )
			
			case ChessPiece.PieceType.bishop:
				isLegal = self.moveIsDiagonalFromSquare(fromSquare, toSquare:toSquare) && self.isDiagonalEmptyFromSquare(fromSquare, toSquare:toSquare)
			
			case ChessPiece.PieceType.rook:
				isLegal = self.moveIsRowOrColumnFromSquare(fromSquare, toSquare:toSquare) && self.isRowOrColumnEmptyFromSquare(fromSquare, toSquare:toSquare)
			
			case ChessPiece.PieceType.queen:
				isLegal = (self.moveIsDiagonalFromSquare(fromSquare, toSquare:toSquare) && self.isDiagonalEmptyFromSquare(fromSquare, toSquare:toSquare)) ||
					(self.moveIsRowOrColumnFromSquare(fromSquare, toSquare:toSquare) && self.isRowOrColumnEmptyFromSquare(fromSquare, toSquare:toSquare))
			
			case ChessPiece.PieceType.king:
				isLegal = ( (numColumnsMoved < 2) && (numRowsMoved < 2) )
				// really, really crude, incomplete test for castling
				if ( !isLegal && (fromSquare.columnNum == 4) && (numColumnsMoved > 1) && (numRowsMoved == 0) && ( ( (toSquare.rowNum == 0) && (fromSquare.rowNum == 0) ) || ( (toSquare.rowNum == 7) && (fromSquare.rowNum == 7) ) )  ) {
					isLegal = true
					self.didCastle = true		// controller will create another move for rook
				}
		}
	
        // TODO! this is commented off to conveniently allow viewing the end-of-game graphics. The best solution for making this a real application would be
        // to add a way to allow a user to resign.
		// Lastly, see if the move leaves the player in Check.
//        if isLegal {
//            isLegal = !isKingInCheckForColor(pieceView.isBlack)
//        }
	
		return isLegal
	}
	
    // completely brute force, but more than fast enough
	func isKingInCheckForColor(_ isBlack: Bool) -> Bool {
	
        var kingsSquare = SquarePosition(rowNum: -1,columnNum: -1)
		
		// get square that king of color is on
		for c in 0..<8 {
			for r in 0..<8 {
				if ( (chessBoardPieces[r][c] != nil) && (chessBoardPieces[r][c]!.pieceType == ChessPiece.PieceType.king) && (chessBoardPieces[r][c]!.isBlack == isBlack) ) {
                    kingsSquare = SquarePosition(rowNum: r, columnNum: c)
					break
				}
			}
		}
		
		// iterate through pieces, if piece is of other color - is king's square a legal move?
		for c in 0..<8 {
			for r in 0..<8 {
				if (chessBoardPieces[r][c] != nil) && (chessBoardPieces[r][c]!.isBlack != isBlack) {
					let pieceSquare = SquarePosition(rowNum: r, columnNum: c)
					if self.isLegalMoveForPiece(chessBoardPieces[r][c]!, fromSquare:pieceSquare, toSquare:kingsSquare) {
						return true
						}
				}
			}
		}
		
		return false
	}
	
	
	//MARK: initialization
	
	init(delegate: GameDelegate) {

		self.delegate = delegate
		
		for _ in 0..<8 {
			chessBoardPieces.append(Array(repeating: nil, count: 8))
		}
		
		let pi: [PieceInfo] = [
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 0), isBlack: true, type: ChessPiece.PieceType.rook),
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 1), isBlack: true, type: ChessPiece.PieceType.knight),
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 2), isBlack: true, type: ChessPiece.PieceType.bishop),
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 3), isBlack: true, type: ChessPiece.PieceType.queen),
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 4), isBlack: true, type: ChessPiece.PieceType.king),
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 5), isBlack: true, type: ChessPiece.PieceType.bishop),
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 6), isBlack: true, type: ChessPiece.PieceType.knight),
			PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 7), isBlack: true, type: ChessPiece.PieceType.rook),

			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 0), isBlack: true, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 1), isBlack: true, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 2), isBlack: true, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 3), isBlack: true, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 4), isBlack: true, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 5), isBlack: true, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 6), isBlack: true, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 1, columnNum: 7), isBlack: true, type: ChessPiece.PieceType.pawn),
			
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 0), isBlack: false, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 1), isBlack: false, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 2), isBlack: false, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 3), isBlack: false, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 4), isBlack: false, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 5), isBlack: false, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 6), isBlack: false, type: ChessPiece.PieceType.pawn),
			PieceInfo(square: SquarePosition(rowNum: 6, columnNum: 7), isBlack: false, type: ChessPiece.PieceType.pawn),

			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 0), isBlack: false, type: ChessPiece.PieceType.rook),
			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 1), isBlack: false, type: ChessPiece.PieceType.knight),
			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 2), isBlack: false, type: ChessPiece.PieceType.bishop),
			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 3), isBlack: false, type: ChessPiece.PieceType.queen),
			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 4), isBlack: false, type: ChessPiece.PieceType.king),
			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 5), isBlack: false, type: ChessPiece.PieceType.bishop),
			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 6), isBlack: false, type: ChessPiece.PieceType.knight),
			PieceInfo(square: SquarePosition(rowNum: 7, columnNum: 7), isBlack: false, type: ChessPiece.PieceType.rook),
		]
	
		for p in pi {
			let piece = ChessPiece(pieceType: p.type, isBlack: p.isBlack)
			self.movePiece(piece, toSquare: p.square)
			self.delegate!.pieceAdded(piece, toSquare: p.square)
		}
	}
}
