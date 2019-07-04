//
//  GameSession.swift
//  ChessBoard
//
//  Copyright © 2018 Gary Hanson.
//  Licensed under the MIT license, see LICENSE file
//

import UIKit
import MultipeerConnectivity


let kServiceType = "chess-mc"


protocol GameSessionDelegate: class {

	func connectedAsBlack(_ isBlack: Bool)
	func connectionLost()
	func receivedMove(_ moves: [Move])
	
}


final class GameSession: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {

	private weak var delegate: GameSessionDelegate?
	
	private var sessionPeerID: MCPeerID
	private var peers: [MCPeerID]
	private var session: MCSession!
	private var advertiser: MCNearbyServiceAdvertiser!
	private var mcBrowser: MCNearbyServiceBrowser!

	private var isBlack = false
	private var inviteTimeStamp: TimeInterval?		// timestamp used to let first one to initiate play white
	

	// MARK: Session

	func sendMove(_ moves: [Move]) {
		
		//println("\(self.sessionPeerID.displayName) is sending moves.")
        let encoder = JSONEncoder()
        
		do {
            let jsonData = try encoder.encode(moves)
			try self.session?.send(jsonData, toPeers: self.peers, with: .reliable)
		} catch _ {
            print("Error sending move")
		}
	}
	
	// MARK: MCSessionDelegate
	
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		switch state {
			case .connecting:
				print("\(self.sessionPeerID.displayName) Connecting to peer: \(peerID.displayName)")
			
			case .connected:
				self.peers.append(peerID)
				DispatchQueue.main.async() {
					self.delegate?.connectedAsBlack(self.isBlack)
					}
				self.stopAdvertising()
				self.stopBrowsing()
				print("\(self.sessionPeerID.displayName) Connected to peer: \(peerID.displayName)")
			
			case .notConnected:
				print("\(self.sessionPeerID.displayName) Did not connect to peer: \(peerID.displayName)")
        @unknown default:
            fatalError("Unhandled switch statement in session")
        }
	}
	
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {

        let decoder = JSONDecoder()
        do {
            let moves = try decoder.decode([Move].self, from: data)
            DispatchQueue.main.async() {
                self.delegate?.receivedMove(moves)
		}
        } catch _ {
            print("error receiving moves")
        }
	}
	
	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		// not used
	}
	
	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		// not used
	}
	
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		// not used
	}
	
	
	// MARK: Advertiser delegate
	
	fileprivate func stopAdvertising() {
		self.advertiser?.delegate = nil
		self.advertiser?.stopAdvertisingPeer()
		self.advertiser = nil
	}
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping(Bool, MCSession?) -> Void) {
		
		//print("\(self.sessionPeerID.displayName) Received invitation from peer: \(peerID.displayName)")

		if (peerID.displayName == self.sessionPeerID.displayName) {
			return
		}
		
		var peerInviteTimeStamp = TimeInterval()
		(context! as NSData).getBytes(&peerInviteTimeStamp, length: 100)
		if ( self.inviteTimeStamp == nil || peerInviteTimeStamp < self.inviteTimeStamp! ) {						// the first one to send invite gets to be white
			//print("\(self.sessionPeerID.displayName) Accepting invitation from peer: \(peerID.displayName)")
			invitationHandler(true, self.session)
			//self.peers.append(peerID)
			
			self.isBlack = true
        } else {
            //print("\(self.sessionPeerID.displayName) Received older invitation from peer - ignored: \(peerID.displayName)")
            //print(self.inviteTimeStamp ?? TimeInterval(0.0))
            //print(peerInviteTimeStamp)
        }
	}
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		//if error != nil {
			print("\(self.sessionPeerID.displayName) had an error starting advertising peer: \(error.localizedDescription)")
		//}

	}

	
	// MARK: Browser delegate
	
	func stopBrowsing() {
		self.mcBrowser?.delegate = nil
		self.mcBrowser?.stopBrowsingForPeers()
		self.mcBrowser = nil
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {

		//print("\(self.sessionPeerID.displayName) Browser found peer: \(peerID.displayName)")
		
		if (peerID.displayName == self.sessionPeerID.displayName) {
			return
		}

		if (self.inviteTimeStamp == nil) {
			self.inviteTimeStamp = Date().timeIntervalSince1970
		}

        let s = MemoryLayout<TimeInterval>.size
        let context = Data(bytes: &self.inviteTimeStamp, count: s)
        browser.invitePeer(peerID, to: self.session, withContext: context, timeout: 60)

		//print("\(self.sessionPeerID.displayName) Browser inviting peer: \(peerID.displayName)")
	}
	
	// A nearby peer has stopped advertising
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		//print("\(self.sessionPeerID.displayName) nearby peer: \(peerID.displayName) has stopped advertising")
	}
	

	// MARK: Init and start/stop
	
	override init() {
		self.sessionPeerID = MCPeerID(displayName: UIDevice.current.name)
		self.peers = []
		
		super.init()
	}
	
	
	func startSession(_ delegate: GameSessionDelegate) {
		
		self.delegate = delegate

		self.isBlack = false
		
		//self.session = MCSession(peer: self.sessionPeerID, securityIdentity: nil, encryptionPreference: .required)  // don't really think we need encryption for sending Ints
		self.session = MCSession(peer: self.sessionPeerID)
		self.session?.delegate = self

		self.advertiser = MCNearbyServiceAdvertiser(peer: self.sessionPeerID, discoveryInfo: nil, serviceType: kServiceType)
		self.advertiser?.delegate = self
		self.advertiser?.startAdvertisingPeer()
		
		self.mcBrowser = MCNearbyServiceBrowser(peer: self.sessionPeerID, serviceType: kServiceType)
		self.mcBrowser?.delegate = self
		self.mcBrowser?.startBrowsingForPeers()
	
	}

	func endSession() {
		self.session?.disconnect()
		self.session?.delegate = nil
		self.session = nil
		self.stopAdvertising()
		self.stopBrowsing()
	}

}

