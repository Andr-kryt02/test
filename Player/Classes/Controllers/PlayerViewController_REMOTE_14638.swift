
//
//  PlayerViewController.swift
//  Player
//
//  Created by Boris Bondarenko on 6/1/17.
//  Copyright © 2017 Applikey Solutions. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

enum Songs: String {
    case Afroman = "Because I got high"
    case Elizium = "Море наступает"
    case OP = "Стрекоза"
}

let mp3 = "mp3"

class PlayerViewController: UIViewController {
	
    // MARK: Instance Variables
    
    fileprivate var player: AVPlayer!
    fileprivate var library: [Song] = []
    fileprivate var playerTimer = Timer()
    fileprivate var beeingSeek = false
	
    // MARK: Outlets
    
    @IBOutlet private weak var blurredAlbumImageView: UIImageView!
    @IBOutlet fileprivate weak var playerSongListView: PlayerSongList!
	@IBOutlet fileprivate weak var sliderView: PlayerSlider!
	@IBOutlet fileprivate weak var waveVisualizer: WaveVisualizer!
	@IBOutlet fileprivate weak var controlsView: PlayerControls!
    @IBOutlet private weak var songNameLabel: UILabel!
    @IBOutlet private weak var songAlbumLabel: UILabel!
    
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
		
		
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: Custom Initialization
    
    private func configure() {
        configureBackgroundImage()
        configureNavigationBar()
        configureLibrary()
        configurePlayer()
        configurePlayerSongListView()
    }
    
    private func configurePlayerSongListView() {
		playerSongListView.delegate = self
        playerSongListView.configure(with: library)
		
    }
    
    private func configureNavigationBar() {
        // Background
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        // Font
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.tintColor = UIColor.white
        title = "Now Playing"
    }
    
    private func configureBackgroundImage() {
		blurredAlbumImageView.image = blurredAlbumImageView.image?.applyDarkEffect()
    }
    
    
    // MARK: Player
    
    private func configureLibrary() {
        library.append(Song(path: Songs.Elizium.rawValue))
        library.append(Song(path: Songs.Afroman.rawValue))
        library.append(Song(path: Songs.OP.rawValue))
		library.append(Song(path: Songs.Elizium.rawValue))
		library.append(Song(path: Songs.Afroman.rawValue))
		library.append(Song(path: Songs.OP.rawValue))
    }
	
	
	fileprivate var currentSongIndex = 0 {
		didSet {
			guard let item = currentItem else {
				return
			}
			item.audioMix = audioTapProcessor?.audioMix
			self.player.replaceCurrentItem(with: item)
			let tm = CMTime(seconds: 0, preferredTimescale: 1000)
			beeingSeek = true
			self.player.seek(to: tm)
		}
	}
	
	fileprivate var currentItem : AVPlayerItem? {
		guard let item = library[self.currentSongIndex].playerItem else {
			return nil
		}
		
		return item
	}
	
	var audioTapProcessor : MYAudioTapProcessor?
	
	private func configurePlayer() {
        configurePlayerControls()
        configurePlayerTimeSlider()
		
		guard let item = library[self.currentSongIndex].playerItem else {
			return
		}
		let track = item.asset.tracks(withMediaType: AVMediaTypeAudio).first!
		
		audioTapProcessor = MYAudioTapProcessor.init(audioAssetTrack: track)
		item.audioMix = audioTapProcessor?.audioMix
		audioTapProcessor?.delegate = self
        player = AVPlayer.init(playerItem: item) //warn
		
		
		
		
		let interval  = CMTime.init(seconds: 1.0, preferredTimescale: 1)
		player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main) { [weak self] (tm) in
			self?.updateProgress(time: tm)
			self?.updatePlaybackStatus()
		}
		NotificationCenter.default.addObserver(self, selector: #selector(onPlaybackFinish), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
		
        player?.play()
    }
	
	
	private dynamic func onPlaybackFinish() {
		updatePlaybackStatus()
	}
	
	fileprivate func updatePlaybackStatus() {
		self.controlsView.isPlaying = self.player.timeControlStatus == .playing
	}
	
	private func updateProgress(time : CMTime) {
		
		
		guard !beeingSeek else {
			beeingSeek = false
			return
		}
		
		let currentSong = library[currentSongIndex]
		
		guard let duration = currentSong.metadata?.duration, duration > 0 else {
			self.sliderView.progress = 0
			return
		}
		
		let seconds = Float(CMTimeGetSeconds(time))
		self.sliderView.duration = duration
		self.sliderView.progress = seconds / Float(duration)
	}
    
    private func configurePlayerControls() {
        controlsView.delegate = self
    }
    
    private func configurePlayerTimeSlider() {
		sliderView.delegate = self
		sliderView.progress = 0.0
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
}

extension PlayerViewController: PlayerSongListDelegate {
	
	func currentSongDidChanged(index : Int) {
		print("Should set song number \(index)")
		
		self.currentSongIndex = index
	}
	
	func next() {
		updatePlaybackStatus()
	}
	
	func didTap() {
		updatePlaybackStatus()
	}
	
	func previous() {
		updatePlaybackStatus()
	}
}

extension PlayerViewController : PlayerControlsDelegate {
	
	func onRepeat() {
	
	}
	
	func onRewindBack() {
        playerSongListView.setCurrentIndex(index: currentSongIndex - 1 >= 0 ? currentSongIndex - 1 : 0 , animated: true)
        updatePlaybackStatus()
    }
	
	func onPlay() {
		let isPlaying = self.player.timeControlStatus == .playing
		if isPlaying {
			self.player.pause()
		} else {
			self.player.play()
		}
		self.controlsView.isPlaying = !isPlaying
	}
	
	func onRewindForward() {
        var index = library.count
        if currentSongIndex + 1 <= library.count {
            currentSongIndex += 1
            index = currentSongIndex
            playerSongListView.setCurrentIndex(index: index, animated: true)
        }
        updatePlaybackStatus()
    }
	
	func onShuffle() {
    
    }
}


extension PlayerViewController : PlayerSliderProtocol {
	func onValueChanged(progress : Float, timePast : TimeInterval) {
		let time = CMTime(seconds: timePast, preferredTimescale: 1000)
		beeingSeek = true
		self.player.seek(to: time)
	}
}


extension PlayerViewController : MYAudioTabProcessorDelegate {
	
	func audioTabProcessor(_ audioTabProcessor: MYAudioTapProcessor!, hasNewLeftChannelValue leftChannelValue: Float, rightChannelValue: Float) {
		self.waveVisualizer.updateWave(leftChannelValue: leftChannelValue, rightChannelValue: rightChannelValue)
	}
	
}

