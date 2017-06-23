//
//  PlayerSlider.swift
//  Player
//
//  Created by Pavel Yevtukhov on 6/2/17.
//  Copyright © 2017 Applikey Solutions. All rights reserved.
//

import UIKit

protocol PlayerSliderProtocol : class {
	func onValueChanged(progress : Float, timePast : TimeInterval)
}

class PlayerSlider: ViewWithXib {

	@IBOutlet private weak var pastLabel: UILabel!
	@IBOutlet private weak var remainLabel: UILabel!
	
	var delegate : PlayerSliderProtocol?
	var duration : TimeInterval = TimeInterval() {
		didSet {
			updateProgress(self.progress)
		}
	}
	
	var progress : Float {
		set(newValue) {
			guard !isDragging else {
				return
			}
			updateProgress(newValue)
		}
		
		get {
			return _progress
		}
	}
	
	private var _progress : Float = 0
	
	private func updateProgress(_ progress : Float) {
		let minVal : Float = 0
		let maxVal : Float = 1.0
		var actualValue = progress >= minVal ? progress : minVal
		actualValue = progress <= maxVal ? actualValue : maxVal
		
		self._progress = actualValue
	
		self.sliderView.value = actualValue
		
		let pastInterval = Float(duration) * actualValue
		let remainInterval = Float(duration) - pastInterval

		self.pastLabel.text = intervalToString(TimeInterval(pastInterval))
		self.remainLabel.text = intervalToString(TimeInterval(remainInterval))
	}
	
	func intervalToString (_ interval: TimeInterval) -> String? {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.minute, .second]
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		formatter.maximumUnitCount = 2
		return formatter.string(from: interval)
	}
	
	
	@IBOutlet private weak var sliderView: UISlider!
	
	@IBAction private func sliderValueDidChanged(_ sender: Any) {
		updateProgress(sliderView.value)
	}
	
	override func initUI() {
		super.initUI()
		self.sliderView.addTarget(self, action: #selector (dragDidBegin), for: .touchDragInside)
		self.sliderView.addTarget(self, action: #selector (dragDidEnd), for: .touchUpInside)
		self.sliderView.setThumbImage(UIImage(named : "slider_thumb"), for: .normal)
		
	}
	
	
	private var isDragging = false

	dynamic private func dragDidBegin() {
		isDragging = true
	}
	
	dynamic private func dragDidEnd() {
		self.isDragging = false
		self.notifyDelegate()
	}
	
	private func notifyDelegate() {
		let timePast = self.duration * Double(sliderView.value)
		self.delegate?.onValueChanged(progress: sliderView.value, timePast : timePast)
	}
	
}
