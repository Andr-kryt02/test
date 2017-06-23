//
//  Song.swift
//  Player
//
//  Created by Boris Bondarenko on 6/2/17.
//  Copyright © 2017 Applikey Solutions. All rights reserved.
//

import UIKit
import AVFoundation

struct Song {
    var url: URL?
    var metadata: MetaData?
    var playerItem: AVPlayerItem?
	var path : String?
    
    init(path aPath: String) {
		path = aPath
        if let bundlePath = Bundle.main.path(forResource: aPath, ofType: "mp3") {
            url = URL(fileURLWithPath: bundlePath)
        }
        if let url = url { playerItem = AVPlayerItem(url: url) }
        metadata = MetaData(playerItem: playerItem)
    }
}

struct SongItem {
    let song: Song
    var colors: UIImageColors?
    
    init(song: Song) {
        self.song = song
    }
}
