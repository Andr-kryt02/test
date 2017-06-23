
//
//  PlayerViewController.swift
//  Player
//
//  Created by Boris Bondarenko on 6/1/17.
//  Copyright © 2017 Applikey Solutions. All rights reserved.
//

import UIKit
import AudioKit

private enum Songs: String {
    case Afroman = "Because I got high"
	case RollingStones = "Paint It Black"
    case Elizium = "Море наступает"
    case OP = "Стрекоза"
	case JESSY = "price tag"
}

private let mp3 = "mp3"

class PlayerViewController: UIViewController {
	
    // MARK: Instance Variables
    
    fileprivate var player: EZAudioPlayer!
    fileprivate var originalPlayList: [SongItem] = []
    fileprivate var library: [SongItem] = []
    fileprivate var playerTimer = Timer()
    fileprivate var beeingSeek = false
    fileprivate var tasks: [Int: DispatchWorkItem] = [:]
	
    // MARK: Outlets
    
    @IBOutlet fileprivate weak var blurredAlbumImageView: UIImageView!
    @IBOutlet fileprivate weak var playerSongListView: PlayerSongList!
	@IBOutlet fileprivate weak var sliderView: PlayerSlider!
	@IBOutlet fileprivate weak var waveVisualizer: WaveVisualizer!
	@IBOutlet fileprivate weak var controlsView: PlayerControls!
    @IBOutlet private weak var songNameLabel: UILabel!
    @IBOutlet private weak var songAlbumLabel: UILabel!
    @IBOutlet fileprivate var fadeImageView: UIImageView!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentSongIndex = 0
        configure()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Public
    
    // MARK: Custom Initialization
    
    private func configure() {
        configureNavigationBar()
		configurePlayer()
        configureLibrary()
        configurePlayerSongListView()
        configureBackgroundImage()
    }
	
    private func configurePlayerSongListView() {
		playerSongListView.delegate = self
        playerSongListView.configure(with: library.map{ $0.song })
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
		blurredAlbumImageView.image = blurredAlbumImageView.image
        fadeImageView.isHidden = false
        blurredAlbumImageView.image = currentSongItem?.song.metadata?.artwork
    }
    
    // MARK: Player
    
    private func configureLibrary() {
        library.append(SongItem(song: Song(path: Songs.Elizium.rawValue)))
		library.append(SongItem(song: Song(path: Songs.RollingStones.rawValue)))
        library.append(SongItem(song: Song(path: Songs.OP.rawValue)))
        library.append(SongItem(song: Song(path: Songs.JESSY.rawValue)))
        library.append(SongItem(song: Song(path: Songs.Afroman.rawValue)))
        originalPlayList = library
    }

	fileprivate func rewindForward() {
		if currentSongIndex < library.count {
			currentSongIndex += 1
		}
		updatePlaybackStatus()
	}
    
    fileprivate func rewindBackward() {
        if currentSongIndex > 0 {
            currentSongIndex -= 1
        }
        updatePlaybackStatus()
    }
	
    fileprivate var currentSongIndex: Int = -1 {
		didSet {
            guard currentSongIndex != oldValue else {
                return
            }
			reloadPlayer()
		}
	}
    
    fileprivate var isRepeatModeOn: Bool = false {
        didSet {
            controlsView.isRepeatModeOn = isRepeatModeOn
        }
    }
    
    fileprivate var isShuffleModeOn: Bool = false {
        didSet {
            controlsView.isShuffleModeOn = isShuffleModeOn
            if isShuffleModeOn {
                syncColorsWithOriginalList()
                shufflePlayList()
            } else {
                resetPlaylist()
            }
        }
    }
    
    fileprivate func reloadPlayer() {
        guard let songItem = currentSongItem,
            let url = songItem.song.url else {
                return
        }
        
        let titleColor = songItem.colors
        
        updateForColors(titleColor)
        
        playerSongListView.setCurrentIndex(index: currentSongIndex, animated: true)
        
        player.audioFile = EZAudioFile(url: url)
        if !player.isPlaying {
            player.play()
        }
    }
    
    fileprivate func updateForColors(_ colors: UIImageColors?) {
        guard let songItem = currentSongItem,
            let metadata = songItem.song.metadata else {
                return
        }
        let rightChannelColor = colors?.primaryColor ?? UIColor.green
        let leftChannelColor = colors?.secondaryColor ?? UIColor.blue
        songNameLabel.changeAnimated(metadata.title ?? "Unknown", color: rightChannelColor)
        songAlbumLabel.changeAnimated(metadata.albumName ?? "Unknown", color: .lightGray)
        waveVisualizer.setColors(left: leftChannelColor, right: rightChannelColor)
    }
    
    fileprivate func updateSongLabels(metadata: MetaData, colors: UIImageColors?) {
        songNameLabel.changeAnimated(metadata.title ?? "Unknown", color: colors?.primaryColor ?? .green)
        songAlbumLabel.changeAnimated(metadata.albumName ?? "Unknown", color: .lightGray)
    }
	
	fileprivate var currentSongItem: SongItem? {
		guard self.currentSongIndex >= 0,
			currentSongIndex < self.library.count else {
			return nil
		}
		let song = library[self.currentSongIndex]
		return song
	}
	
	private func configurePlayer() {
        configurePlayerControls()
        configurePlayerTimeSlider()
		player = EZAudioPlayer()
		player.delegate = self
		updatePlaybackStatus()
    }

	fileprivate func updatePlaybackStatus() {
		self.controlsView.isPlaying = self.player.isPlaying
	}
    
    fileprivate func resetPlaylist() {
        resetPendingTasks()
        library = originalPlayList
        configurePlayer(for: originalPlayList.map{ $0.song })
    }
    
    fileprivate func shufflePlayList() {
        resetPendingTasks()
        library.shuffleInPlace()
        configurePlayer(for: library.map{ $0.song })
    }
    
    fileprivate func resetPendingTasks() {
        tasks.values.forEach{ $0.cancel() } //cancel tasks so that there won't be discrepancies in title colors with artwork
        tasks = [:]
    }
    
    fileprivate func syncColorsWithOriginalList() {
        for i in 0..<library.count {
            originalPlayList[i].colors = library[i].colors
        }
    }
    
    fileprivate func configurePlayer(for songs: [Song]) {
        playerSongListView.configure(with: songs)
        let deadlineTime = DispatchTime.now() + .microseconds(1000)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
            self.currentSongIndex = -1
            self.currentSongIndex = 0
        }
    }
	
    fileprivate func togglePlay() {
        let isPlaying = self.player.isPlaying
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        animatePlayToggling()
        self.controlsView.isPlaying = self.player.isPlaying
    }
    
    fileprivate func animatePlayToggling(duration: TimeInterval = 0.2) {
        let viewToAnimate = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        viewToAnimate.image = self.player.isPlaying ? #imageLiteral(resourceName: "play") : #imageLiteral(resourceName: "pause")
        viewToAnimate.alpha = 0
        viewToAnimate.center = view.center
        
        view.addSubview(viewToAnimate)
        view.isUserInteractionEnabled = false
        
        //fading animation
        UIView.animate(withDuration: duration/2, delay: 0, options: .autoreverse, animations: {
            viewToAnimate.alpha = 0.3
        })
        //expanding animation
        UIView.animate(withDuration: duration, animations: {
            viewToAnimate.transform = viewToAnimate.transform.scaledBy(x: 1.7, y: 1.7)
        })
        //remove view when animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration - (duration*0.2)) {
            viewToAnimate.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
    }
    
	private func updateProgress(time : CMTime) {
		guard !beeingSeek else {
			beeingSeek = false
			return
		}
		
		let currentSong = library[currentSongIndex]
		
		guard let duration = currentSong.song.metadata?.duration, duration > 0 else {
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

// MARK: - PlayerSongListDelegate
extension PlayerViewController: PlayerSongListDelegate {
    func scrollBetween(left: CellActivityItem, right: CellActivityItem) {
        fadeImageView.isHidden = false
        
        let origin = left.index == currentSongIndex ? left : right
        let destination = left.index != currentSongIndex ? left : right
        
        blurredAlbumImageView.image = library[origin.index].song.metadata?.artwork
        fadeImageView.image = library[destination.index].song.metadata?.artwork
        
        blurredAlbumImageView.alpha = origin.activity
        fadeImageView.alpha = destination.activity
    }

	func currentSongDidChanged(index : Int) {
        fadeImageView?.isHidden = true
        blurredAlbumImageView.alpha = 1
        blurredAlbumImageView.image = currentSongItem?.song.metadata?.artwork
		self.currentSongIndex = index
    }
	
	func next() {
		updatePlaybackStatus()
	}
	
	func didTap() {
        togglePlay()
	}
	
	func previous() {
		updatePlaybackStatus()
	}
    
    func prefetchItems(at indices: [Int]) {
        for index in indices {
            guard library[index].colors == nil else { continue }
            guard tasks[index] == nil else { continue }
            var item: DispatchWorkItem!
            item = DispatchWorkItem(block: {
                guard !item.isCancelled else { return }
                guard let image = self.library[index].song.metadata?.artwork else { return }
                guard !item.isCancelled else { return }
				image.getColors(scaleDownSize: CGSize(width : 100, height : 100), completionHandler: { (colors) in
                    guard !item.isCancelled else { return }
					self.library[index].colors = colors
					DispatchQueue.main.async(execute: {
						if self.currentSongIndex == index {
                            self.updateForColors(colors)
						}
					})
                })
            })
            tasks[index] = item
            DispatchQueue.global(qos: .default).async(execute: item)
        }
    }
}

// MARK: - PlayerControlsDelegate
extension PlayerViewController : PlayerControlsDelegate {
	
	func onRepeat() {
        self.isRepeatModeOn = !self.isRepeatModeOn
	}
	
	func onRewindBack() {
		rewindBackward()
    }
	
	func onPlay() {
		togglePlay()
	}
	
	func onRewindForward() {
        rewindForward()
	}
	
	func onShuffle() {
        self.isShuffleModeOn = !self.isShuffleModeOn
	}
}

// MARK: - PlayerSliderProtocol
extension PlayerViewController : PlayerSliderProtocol {
	func onValueChanged(progress : Float, timePast : TimeInterval) {
		beeingSeek = true
		let frame = Int64(Float(player.audioFile.totalFrames) * progress)
		self.player.seek(toFrame: frame)
	}
}

// MARK: - EZAudioPlayerDelegate
extension PlayerViewController : EZAudioPlayerDelegate {
	func audioPlayer(_ audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, in audioFile: EZAudioFile!) {
	
        DispatchQueue.main.async {[weak self] in
			self?.updatePlaybackStatus()
		}
		self.waveVisualizer?.updateWaveWithBuffer(buffer, withBufferSize: bufferSize, withNumberOfChannels: numberOfChannels)
	}
	
	func audioPlayer(_ audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, in audioFile: EZAudioFile!) {
		guard !beeingSeek else {
			beeingSeek = false
			return
		}
		
		let duration = audioFile.duration
		let progress = audioFile.totalFrames > 0 ? Float(framePosition) / Float(audioFile.totalFrames) : 0
		let isPlaying = audioPlayer.isPlaying
		DispatchQueue.main.async {[weak sliderView, weak controlsView] in
			controlsView?.isPlaying = isPlaying
			sliderView?.duration = duration
			sliderView?.progress = progress
		}
		
	}
	
	func audioPlayer(_ audioPlayer: EZAudioPlayer!, reachedEndOf audioFile: EZAudioFile!) {
        guard !isRepeatModeOn else {
            DispatchQueue.main.async { [weak self] in
                self?.reloadPlayer()
            }
            return
        }
		guard self.currentSongIndex < library.count else {
			return
		}
		
		let newIndex = currentSongIndex < library.count - 1 ? currentSongIndex + 1 : 0
		DispatchQueue.main.async { [weak self] in
			self?.currentSongIndex = newIndex
		}
	}
}
