//
//  GameControllerEndGame.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//

import UIKit

extension GameController {
	
	func showGameOverView(_ didWin: Bool) {
	
        if didWin {
            self.showGameWonView()
        }
        else {
            self.showGameLostView()
        }

        let delayInSeconds: Int64 = 15 * Int64(NSEC_PER_SEC)
        let delayInNanoseconds = DispatchTime.now() + Double(delayInSeconds) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayInNanoseconds) {
            self.finishAndResetGame()
        }
	}
	
	private func finishAndResetGame() {
			
		for subLayer in self.view.layer.sublayers! {
			if let el = subLayer as? CAEmitterLayer {
				el.removeFromSuperlayer()
			}
		}
			
		self.startNewGame()
	}
	
	private func showGameWonView() {
	
		// Cells spawn in the bottom, moving up
		let fireworksEmitter = CAEmitterLayer()
		let viewBounds = self.view.layer.bounds
		fireworksEmitter.emitterPosition = CGPoint(x: viewBounds.size.width/2.0, y: viewBounds.size.height)
		fireworksEmitter.emitterSize	= CGSize(width: viewBounds.size.width/2.0, height: 0.0)
		fireworksEmitter.emitterMode	= CAEmitterLayerEmitterMode.outline
		fireworksEmitter.emitterShape	= CAEmitterLayerEmitterShape.line
		fireworksEmitter.renderMode		= CAEmitterLayerRenderMode.additive
		fireworksEmitter.seed = (arc4random()%100)+1
		
		// Create the rocket
		let rocket = CAEmitterCell()
		
		rocket.birthRate		= 1.3
		rocket.emissionRange	= CGFloat(0.25 * .pi)  // 0.25 * .pi // some variation in angle
		rocket.velocity			= 500
		rocket.velocityRange	= 100
		rocket.yAcceleration	= 75
		rocket.lifetime			= SysUtils.deviceIsIPad ? 2.2 : 1.4	// 1.02	// we cannot set the birthrate < 1.0 for the burst
		
		rocket.contents			= UIImage(named: "EmitterImages/DazRing")?.cgImage
		rocket.scale			= 0.2
		rocket.color			= UIColor.red.cgColor
		rocket.greenRange		= 1.0		// different colors
		rocket.redRange			= 1.0
		rocket.blueRange		= 1.0
		rocket.spinRange		= CGFloat(Float.pi)		// slow spin
		
		// the burst object cannot be seen, but will spawn the sparks
		// we change the color here, since the sparks inherit its value
		let burst = CAEmitterCell()
		
		burst.birthRate			= 1.0		// at the end of travel
		burst.velocity			= 0
		burst.scale				= 2.5
		burst.redSpeed			= -1.5		// shifting
		burst.blueSpeed			= +1.5		// shifting
		burst.greenSpeed		= +1.0		// shifting
		burst.lifetime			= 0.35
		
		// and finally, the sparks
		let spark = CAEmitterCell()
		
		spark.birthRate			= 400
		spark.velocity			= 125
		spark.emissionRange		= CGFloat(2.0 * .pi)	// 360 deg
		spark.yAcceleration		= 75		// gravity
		spark.lifetime			= 3
		
		spark.contents			= UIImage(named: "EmitterImages/DazStarOutline")?.cgImage
		spark.scaleSpeed		= -0.2
		spark.greenSpeed		= -0.1
		spark.redSpeed			= 0.4
		spark.blueSpeed			= -0.1
		spark.alphaSpeed		= -0.25
		spark.spin				= CGFloat(2.0 * .pi)
		spark.spinRange			= CGFloat(2.0 * .pi)
		
		// putting it together
		fireworksEmitter.emitterCells	= [rocket]
		rocket.emitterCells				= [burst]
		burst.emitterCells				= [spark]
		self.view.layer.addSublayer(fireworksEmitter)
	}
	
	private func showGameLostView() {
	
		let viewBounds = self.view.layer.bounds
		
		// Create the emitter layers
		let fireEmitter = CAEmitterLayer()
		let smokeEmitter = CAEmitterLayer()
		
		let horizontalOffset: CGFloat = SysUtils.deviceIsIPad ? 160.0 : 80.0
		fireEmitter.emitterPosition = CGPoint(x: viewBounds.size.width/2.0, y: viewBounds.size.height - horizontalOffset)
		fireEmitter.emitterSize	= CGSize(width: viewBounds.size.width/2.0, height: 0)
		fireEmitter.emitterMode	= CAEmitterLayerEmitterMode.outline
		fireEmitter.emitterShape	= CAEmitterLayerEmitterShape.line
		// with additive rendering the dense cell distribution will create "hot" areas
		fireEmitter.renderMode		= CAEmitterLayerRenderMode.additive
		
		smokeEmitter.emitterPosition = CGPoint(x: viewBounds.size.width/2.0, y: viewBounds.size.height - horizontalOffset)
		smokeEmitter.emitterMode	= CAEmitterLayerEmitterMode.points
		
		// Create the fire emitter cell
		let fire = CAEmitterCell()
		fire.name = "fire"
		
		fire.birthRate			= 100
		fire.emissionLongitude  = CGFloat(Float.pi)
		fire.velocity			= -80
		fire.velocityRange		= 30
		fire.emissionRange		= 1.1
		fire.yAcceleration		= -200
		fire.scaleSpeed			= 0.3
		fire.lifetime			= 50
		fire.lifetimeRange		= (50.0 * 0.35)
		
		fire.color = UIColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 0.1).cgColor
		fire.contents = UIImage(named: "EmitterImages/DazFire")?.cgImage
		
		
		// Create the smoke emitter cell
		let smoke = CAEmitterCell()
		smoke.name = "smoke"
		
		smoke.birthRate			= 11
		smoke.emissionLongitude = CGFloat(-.pi / 2.0)
		smoke.lifetime			= 10
		smoke.velocity			= -40
		smoke.velocityRange		= 20
		smoke.emissionRange		= CGFloat(.pi / 4.0)
		smoke.spin				= 1
		smoke.spinRange			= 6
		smoke.yAcceleration		=  -160
		smoke.contents			= UIImage(named: "EmitterImages/DazSmoke")?.cgImage
		smoke.scale				= 0.1
		smoke.alphaSpeed		= -0.12
		smoke.scaleSpeed		= 0.7
		
		
		// Add the smoke emitter cell o the smoke emitter layer
		smokeEmitter.emitterCells	= [smoke]
		fireEmitter.emitterCells	= [fire]
		self.view.layer.addSublayer(smokeEmitter)
		self.view.layer.addSublayer(fireEmitter)
		
		let fireAmount = SysUtils.deviceIsIPad ? 2.2 : 1.4
		self.setFireAmount(fireAmount, fireEmitter:fireEmitter, smokeEmitter:smokeEmitter)
	}
	
	private func setFireAmount(_ zeroToOne: Double, fireEmitter: CAEmitterLayer, smokeEmitter: CAEmitterLayer) {
		
		// Update the fire properties
		fireEmitter.setValue(NSNumber(value: zeroToOne * 500), forKeyPath: "emitterCells.fire.birthRate")
		fireEmitter.setValue(NSNumber(value: zeroToOne), forKeyPath: "emitterCells.fire.lifetime")
		fireEmitter.setValue(NSNumber(value: zeroToOne * 0.35), forKeyPath: "emitterCells.fire.lifetimeRange")
		fireEmitter.emitterSize = CGSize(width: CGFloat(50.0 * zeroToOne), height: 0.0)
		//
		fireEmitter.setValue(NSNumber(value: zeroToOne * 4.0), forKeyPath: "emitterCells.smoke.lifetime")
		//let one: CGFloat = 1.0
		//		fireEmitter.setValue(AnyObject:UIColor(red: one, green: one, blue: one, alpha: CGFloat(zeroToOne * 0.3)), forKeyPath: "emitterCells.smoke.color")
		//	[smokeEmitter setValue:(id)[[UIColor colorWithRed:1 green:1 blue:1 alpha:zeroToOne * 0.3] CGColor]
		//	forKeyPath:@"emitterCells.smoke.color"]
	}
}
