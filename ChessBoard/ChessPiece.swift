//
//  ChessPiece.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the Unlicense, see LICENSE file
//

import UIKit



struct ChessPiece {
	
	enum PieceType: Int {
		case pawn = 0,
		knight,
		bishop,
		rook,
		queen,
		king
	}
	
	let isBlack: Bool
	let pieceType: PieceType
	
	init(pieceType: PieceType, isBlack: Bool) {
		self.isBlack = isBlack
		self.pieceType = pieceType
	}
    
    var name:String {
        var pieceName = ""
        
        switch (self.pieceType) {
            case .rook:
                pieceName = "Rook"
                
            case .bishop:
                pieceName = "Bishop"
                
            case .knight:
                pieceName = "Knight"
                
            case .queen:
                pieceName = "Queen"
                
            case .king:
                pieceName = "King"
                
            case .pawn:
                pieceName = "Pawn"
            }
        
        return pieceName
    }
}
