//
//  PlayerControls.swift
//  Player
//
//  Created by Boris Bondarenko on 6/1/17.
//  Copyright © 2017 Applikey Solutions. All rights reserved.
//

import UIKit

protocol PlayerControlsDelegate : class {
	func onRepeat()
	func onRewindBack()
	func onPlay()
	func onRewindForward()
	func onShuffle()
}


class PlayerControls: ViewWithXib {

	weak var delegate : PlayerControlsDelegate?
    
	var isPlaying : Bool = false {
		didSet {
			let imageStr = isPlaying ? "pause" : "play"
			self.playButton.setImage(UIImage(named: imageStr), for: .normal)
		}
	}
    var isRepeatModeOn: Bool = false {
        didSet {
            repeatButton.tintColor = isRepeatModeOn ? .white : UIColor.white.withAlphaComponent(0.5)
        }
    }
    var isShuffleModeOn: Bool = false {
        didSet {
            shuffleButton.tintColor = isShuffleModeOn ? .white : UIColor.white.withAlphaComponent(0.5)
        }
    }
    
	@IBOutlet private weak var repeatButton: UIButton!
	@IBOutlet private weak var rewindBackButton: UIButton!
	@IBOutlet private weak var playButton: UIButton!
	@IBOutlet private weak var rewindForwardButton: UIButton!
	@IBOutlet private weak var shuffleButton: UIButton!
	
	override func initUI() {
		isPlaying = false
        isRepeatModeOn = false
        isShuffleModeOn = false
		backgroundColor = .clear
	}

    // MARK: - IBActions
    
	@IBAction private func repeatDidTap(_ sender: Any) {
		delegate?.onRepeat()
	}
	
	@IBAction private func rewindBackDidTap(_ sender: Any) {
		delegate?.onRewindBack()
	}
	
	@IBAction private func playDidTap(_ sender: Any) {
		delegate?.onPlay()
	}
	
	@IBAction private func rewindForwardDidTap(_ sender: Any) {
		delegate?.onRewindForward()
	}
	
	@IBAction private func shuffleDidTap(_ sender: Any) {
		delegate?.onShuffle()
	}

}
