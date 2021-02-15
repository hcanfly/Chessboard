//
//  GameController.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the Unlicense, see LICENSE file
//

import UIKit



final class GameController: UIViewController {

	private var gameSession = GameSession()
	private var game: Game!
	
	@IBOutlet weak private var messageView: MessageView!
	@IBOutlet weak private var chessboardView: ChessBoardView!
	@IBOutlet weak private var capturedBlackPiecesView: CapturedPiecesView!
	@IBOutlet weak private var capturedWhitePiecesView: CapturedPiecesView!
    @IBOutlet weak private var backgroundImageView: UIImageView!
	
	
	private let kBoardWidth = (8.0 * ChessBoardView.squareSize)										// avoid calculating these during Pan operation
	private let kHalfSquareWidth = (ChessBoardView.squareSize / 2.0)
	
	
	private var capturedPiece: PieceImageView?
	private var imageViewForAnimation: UIImageView?
	private var currentInfoForPieceBeingMoved: PieceInfo											// info saved off at start of move so we can validate/move/remove piece at end of move
	
	private var gameIsEnding = false
	private var kingIsInCheck = false
	private var isBlack = false
	
	
	//MARK: - Initialization
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// also have to add "View controller-based status bar appearance" to plist, set to YES, and override preferredStatusBarStyle. Sets text in status bar to white so it can be seen.
        self.setNeedsStatusBarAppearanceUpdate()
		
		var frame = self.messageView.frame
		frame = CGRect(x: 0.0, y: frame.origin.y, width: self.view.frame.width, height: frame.size.height)
		self.messageView.frame = frame
		self.messageView.messageLabelView?.frame = frame
        self.backgroundImageView.frame = self.view.bounds
		
        let chessboardSize: CGFloat = self.view.frame.width < 700.0 ? 288.0 : 576.0
        let yOffset : CGFloat = self.view.frame.height < 360.0 ? 110.0 : 160.0
        self.chessboardView.frame = CGRect(x: (self.view.frame.width - chessboardSize) / 2.0, y: yOffset, width: chessboardSize, height: chessboardSize)
        
        let isiPad = SysUtils.deviceIsIPad
        frame = CGRect(x: self.chessboardView.frame.origin.x, y: yOffset + chessboardSize +  30.0, width: self.chessboardView.frame.size.width, height: isiPad ? 40.0 : 20.0)
        self.capturedBlackPiecesView.frame = frame
        
        frame = frame.offsetBy(dx: 0.0, dy: isiPad ? 56.0 : 28.0)
        self.capturedWhitePiecesView.frame = frame
		
		self.setupBoard(true)
		self.gameSession.startSession(self)
		
		self.messageView.setStatusDisplay(.connecting)
	}
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
	
	private func setupBoard(_ firstTime: Bool) {
		
		self.chessboardView.setupBoard(firstTime, panDelegate: self)
		self.game = Game(delegate: self)
		
		var subviews = self.capturedBlackPiecesView.subviews
		for s in subviews {
			s.removeFromSuperview()
		}
		subviews = self.capturedWhitePiecesView.subviews
		for s in subviews {
			s.removeFromSuperview()
		}
		
	}
    
    func startNewGame() {
    
        self.gameIsEnding = false
        
        self.setupBoard(false)
        self.messageView.setStatusDisplay(.connecting)
        
        self.gameSession.endSession()
        self.gameSession.startSession(self)
    }
	
	required init?(coder aDecoder: NSCoder)	{
		
		self.currentInfoForPieceBeingMoved = PieceInfo(square: SquarePosition(rowNum: 0, columnNum: 0), isBlack: false, type: .pawn)

		super.init(coder: aDecoder)
	}
	
	
	deinit {
		self.gameSession.endSession()
	}
    
    private func setStatusDisplay(_ status: DisplayStatus) {
    
        self.messageView.setStatusDisplay(status)
    }

}


//MARK: - Recognizer, piece being moved
extension GameController {
        
    @objc func handlePan(_ recognizer :UIPanGestureRecognizer) {
    
        if (recognizer.state == .ended) {
            let newSquare = self.chessboardView.getSquareFromView(recognizer.view!)
            let fromSquare = self.currentInfoForPieceBeingMoved.square
            let piece = self.game.getCurrentPieceForSquare(fromSquare)
            let toSquare = SquarePosition(rowNum: newSquare.rowNum, columnNum: newSquare.columnNum)
            
            if (self.game.isLegalMoveForPiece(piece!, fromSquare:fromSquare, toSquare:toSquare)) {
            
                let didCastle = self.game.didCastle        // save off because movePiece sees if King is in check which calls isLegalMoveForPiece which will reset game value
                // constrain position to be in a square
                recognizer.view!.frame = CGRect(x: CGFloat(newSquare.columnNum)*ChessBoardView.squareSize, y: CGFloat(newSquare.rowNum)*ChessBoardView.squareSize, width: ChessBoardView.squareSize, height: ChessBoardView.squareSize)
                
                self.movePiece(fromSquare, toSquare:toSquare)
                
                var moves = [Move]()
                
                var m = Move()
                m.fromSquare = fromSquare
                m.toSquare = toSquare

                moves.append(m)
                
                if didCastle {                  // king moved to legal castle position, move rook accordingly

                    let rookSquare = self.game.currentRookPositionForKingCastlingMoveTo(toSquare)
                    let castleSquare = self.game.newRookPositionForKingCastlingMoveTo(toSquare)
                    
                    self.movePiece(rookSquare, toSquare:castleSquare)
                    var rookMove = Move()
                    rookMove.fromSquare = rookSquare
                    rookMove.toSquare = castleSquare
                    moves.append(rookMove)
                }
                
                self.gameSession.sendMove(moves)
                if self.gameIsEnding == false {
                    self.enableMoveFor(.forNone)
                    self.setStatusDisplay(.waitForTurn)
                    if self.kingIsInCheck == true {
                        self.messageView.addCheck()
                    }
                }
            } else {
                // not a legal move. put the piece back where it came from
                recognizer.view!.frame = CGRect(x: CGFloat(self.currentInfoForPieceBeingMoved.square.columnNum)*ChessBoardView.squareSize, y: CGFloat(self.currentInfoForPieceBeingMoved.square.rowNum)*ChessBoardView.squareSize, width: ChessBoardView.squareSize, height: ChessBoardView.squareSize)
            }
            
            self.currentInfoForPieceBeingMoved = PieceInfo(square: SquarePosition(rowNum: -1, columnNum: -1), isBlack: self.currentInfoForPieceBeingMoved.isBlack, type: self.currentInfoForPieceBeingMoved.type)
        } else if (recognizer.state == .began) {
            let startSquare = self.chessboardView.getSquareFromView(recognizer.view!)
            let piece = self.game.getCurrentPieceForSquare(startSquare)

            self.currentInfoForPieceBeingMoved = PieceInfo(square: startSquare, isBlack: piece!.isBlack, type: piece!.pieceType)
        } else {
            recognizer.view!.superview!.bringSubviewToFront(recognizer.view!)
            let translation = recognizer.translation(in: self.view)
            
            let newCenter = CGPoint(x: recognizer.view!.center.x + translation.x, y: recognizer.view!.center.y + translation.y)
            
            // See if the new position is in bounds.
            if ( (newCenter.y - kHalfSquareWidth >= 0.0) && ( (newCenter.y + kHalfSquareWidth) <= kBoardWidth ) &&
            ( (newCenter.x - kHalfSquareWidth >= 0.0) && ( (newCenter.x + kHalfSquareWidth) <= kBoardWidth ) )) {
                recognizer.view!.center = newCenter
                recognizer.setTranslation(CGPoint.zero, in:self.view)
            }
        }
    }
    
}


//MARK: - Moves
extension GameController {
        
    // allow moves for only the appropriate type - white, black or none (other player's turn)
    private func enableMoveFor(_ color: EnableColor) {
    
        self.chessboardView.enableMoveFor(color)
    }
    
    private func movePiece(_ fromSquare: SquarePosition, toSquare:SquarePosition) {
    
        self.kingIsInCheck = false
        
        // if there is another piece on the square we're moving to - remove it from chessboard view
        let pieceToRemove = self.game.getCurrentPieceForSquare(toSquare)
        if pieceToRemove != nil {
            let pIV = self.chessboardView.getPieceImageViewForSquare(toSquare)
            
            self.chessboardView.removePieceFromSquare(toSquare)                    // remove piece from view
            self.animatePieceToCapturedPieces(pIV!)                                // animate move to captured pieces tray
        }
        
        let movePiece = self.game.getCurrentPieceForSquare(fromSquare)
        if movePiece == nil {
            print("movePiece is nil for square: row:\(fromSquare.rowNum) and column: \(fromSquare.columnNum).")
            return
        }
        self.game.movePiece(movePiece!, toSquare:toSquare)                            // update the model
        self.chessboardView.movePieceFromSquare(fromSquare, toSquare:toSquare)        // update the view
        self.game.removePieceFromSquare(fromSquare)                                 // finish updating the model
        
        if pieceToRemove != nil && pieceToRemove!.pieceType == ChessPiece.PieceType.king {    // game over
            self.doEndGame(pieceToRemove!.isBlack != self.isBlack)
        } else {
            if self.game.isKingInCheckForColor(movePiece!.isBlack == false) {
                self.kingIsInCheck = true
            }
        }
    }
    
    private func doEndGame(_ wonGame: Bool) {
    
        self.gameIsEnding = true
        self.enableMoveFor(.forNone)
        
        self.showGameOverView(wonGame)
        if wonGame == true {
            self.messageView.setStatusDisplay(.gameWon)
        } else {
            self.messageView.setStatusDisplay(.gameLost)
        }
    }
    
}


//MARK: GameSession delegate
extension GameController: GameSessionDelegate {
        
    func connectedAsBlack(_ isBlack: Bool) {
    
        self.isBlack = isBlack
        self.messageView.setStatusDisplay(isBlack ? .waitForTurn : .usersTurn)

        if isBlack == false  {
            self.enableMoveFor(.forWhite)
        }
    }
    
    func connectionLost() {
    
        self.enableMoveFor(.forNone)
        
        self.startNewGame()
    }
    
    func receivedMove(_ moves: [Move])
    {
        for m in moves {
            self.movePiece(m.fromSquare!, toSquare:m.toSquare!)
        }
        
        if self.gameIsEnding == false {
            self.enableMoveFor(self.isBlack ? .forBlack : .forWhite)
            self.messageView.setStatusDisplay(.usersTurn)
            if self.kingIsInCheck == true {
                self.messageView.addCheck()
            }
        }
    }
    
}

//MARK: - CaptureAnimation
extension GameController: CAAnimationDelegate {
        
    private func animatePieceToCapturedPieces(_ piece: PieceImageView) {
    
        self.capturedPiece = piece            // so we can remove it on completion
        
        let captureView = piece.piece.isBlack ? self.capturedBlackPiecesView : self.capturedWhitePiecesView
        
        self.imageViewForAnimation = piece
        self.imageViewForAnimation!.alpha = 1.0
        
        var viewOrigin = piece.frame.origin
        viewOrigin.x += self.chessboardView.frame.origin.x
        viewOrigin.y += self.chessboardView.frame.origin.y
        
        
        self.imageViewForAnimation!.frame = piece.frame
        self.imageViewForAnimation!.layer.position = viewOrigin
        self.view.addSubview(self.imageViewForAnimation!)
        
        // Set up fade out effect
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.toValue = 0.3
        fadeOutAnimation.fillMode = CAMediaTimingFillMode.forwards
        fadeOutAnimation.isRemovedOnCompletion = false
        
        // Set up path movement
        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.calculationMode = CAAnimationCalculationMode.paced
        pathAnimation.fillMode = CAMediaTimingFillMode.forwards
        pathAnimation.isRemovedOnCompletion = false
        
        let midPoint = CGPoint(x: self.chessboardView.frame.origin.x, y: viewOrigin.y)
        let endPoint = CGPoint(x: (captureView?.frame.origin.x)!, y: (captureView?.frame.origin.y)! - 20.0)
        
        let curvedPath = CGMutablePath()
        curvedPath.move(to: CGPoint(x: viewOrigin.x, y: viewOrigin.y))
        curvedPath.addCurve(to: CGPoint(x: midPoint.x, y: viewOrigin.y), control1: CGPoint(x: midPoint.x, y: viewOrigin.y), control2: CGPoint(x: midPoint.x, y: midPoint.y))
        curvedPath.addQuadCurve(to: endPoint, control: CGPoint(x: midPoint.x, y: midPoint.y + 100.0))
        pathAnimation.path = curvedPath
        
        let group = CAAnimationGroup()
        group.fillMode = CAMediaTimingFillMode.forwards
        group.isRemovedOnCompletion = false
        group.animations = [fadeOutAnimation, pathAnimation]
        group.duration = 2.5
        group.delegate = self
        group.setValue(imageViewForAnimation, forKey:"imageViewBeingAnimated")
        
        imageViewForAnimation!.layer.add(group, forKey:"savingAnimation")
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    
        self.addCapturedPieceToCollection()        // after animation is done add piece to captured pieces tray
    }
    
    private func addCapturedPieceToCollection() {
    
        let captureView = self.capturedPiece!.piece.isBlack ? self.capturedBlackPiecesView : self.capturedWhitePiecesView
        let temp = self.imageViewForAnimation!.image!
        
        captureView?.addCapturedPieceToCollection(temp, capturedPiece: self.capturedPiece!)
        
        self.imageViewForAnimation!.removeFromSuperview()
        self.imageViewForAnimation = nil
        self.capturedPiece = nil
    }
}


//MARK: - Game delegate
extension GameController: GameDelegate {
        
    func pieceAdded(_ piece: ChessPiece, toSquare: SquarePosition)
    {
        self.chessboardView.addPiece(piece, square: toSquare)
    }
    
}
