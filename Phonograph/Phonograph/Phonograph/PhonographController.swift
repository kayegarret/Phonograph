//
//  PhonographController.swift
//  TestApplication
//
//  Created by Garret Kaye on 2/15/20.
//  Copyright © 2020 Garret Kaye. All rights reserved.
//

import UIKit
import AVFoundation

class PhonographController : ContainerViewController<PhonographView> {
    
    fileprivate var audioPlayer : AVAudioPlayer?
    fileprivate var staticNoiseAudioPlayer : AVAudioPlayer?
    fileprivate var displayLink : CADisplayLink?

    fileprivate(set) var queue = [PhonographRecord]()
    fileprivate(set) var shouldPlayWhenNoLongerPartOfResponderChain = false
    fileprivate(set) var shouldPlayInBackground = true
    fileprivate(set) var staticNoiseVolume = Float(0.5)
    fileprivate(set) var onlyPlaysStaticNoiseWhenBuffering = false
    fileprivate(set) var isAssumedBuffering = false
    fileprivate var controlPoints : ControlPoints?
    
    public static var shared = PhonographController()
    public weak var delegate : PhonographDelegate?
    
    fileprivate(set) var tonearmState : TonearmState = .tonearmIsOnRest {
        
        willSet (newState) {
                        
            guard newState != tonearmState
                else { return }
            
            // Alert delegate
            self.delegate?.phonographTonearmStateWillChange(self, newTonearmState: newState)
            
            switch newState {
            case .tonearmIsOnRest:
                self.container.flipperScrollView.isUserInteractionEnabled = true
                break
            case .tonearmNotOnRecord:
                self.container.flipperScrollView.isUserInteractionEnabled = false
                break
            case .userIsHoldingTonearm:
                self.container.flipperScrollView.isUserInteractionEnabled = false
                break
            case .tonearmIsOnLeadInGroove:
                self.container.flipperScrollView.isUserInteractionEnabled = false
                break
            case .tonearmIsOnVinylTrack:
                self.container.flipperScrollView.isUserInteractionEnabled = false
                break
            case .tonearmIsOnRunOutGroove:
                self.container.flipperScrollView.isUserInteractionEnabled = false
                break
            case .tonearmIsOnCenterLabel:
                
                self.container.flipperScrollView.isUserInteractionEnabled = false
                
                guard let controlPoints = self.controlPoints
                    else { break }
                
                self.bringTonearmToAngle(controlPoints.tonearmTrueZeroAngle, animated: true) {
                    self.tonearmState = .tonearmIsOnRest
                }
            }
            
            switch (tonearmState.causesRecordToSpin, newState.causesRecordToSpin) {
            case (true, false):
                self.stopRecordSpin()
            case (false, true):
                self.beginRecordSpin()
            default:
                break
            }
            
            switch (tonearmState.causesTrackToPlay, newState.causesTrackToPlay) {
            case (true, false):
                self.stopPlayingCurrentRecordAudio()
            case (false, true):
                
                // Check and make control points have been set and record exists
                guard let controlPoints = self.controlPoints,
                    let currentRecord = self.currentRecord
                    else { return }
                
                // Calculate what time index the audio track should be playing at
                let currentTonearmAngle = atan2(self.container.tonearm.layer.transform.m12, self.container.tonearm.layer.transform.m11)
                let anglesCompleted = abs(currentTonearmAngle - controlPoints.vinylTrackStartAngle)
                let trackAngleRange = abs(controlPoints.vinylTrackStartAngle - controlPoints.vinylTrackEndAngle)
                let percentCompleted = anglesCompleted / trackAngleRange
                let calculatedDuration = Double(percentCompleted) * currentRecord.sideUp.durations.reduce(0, +)
                
                self.beginPlayingCurrentRecordAudio(atTimeIndex: calculatedDuration)
                
            default:
                break
            }
            
        }
    }
    
    
    
    private init () {
        super.init(nibName: nil, bundle: nil)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func didMove(toParent parent: UIViewController?) {
        
        // Check whether or not the phonograph controller is being added or removed from parent
        let wasRemovedFromParent = parent == nil
        
        if wasRemovedFromParent {
            
            // The phonograph controller has been removed from parent
            // Shut down processes if necessary
            
            if self.tonearmState.causesRecordToSpin {
                self.stopRecordSpin()
                
                if self.shouldPlayWhenNoLongerPartOfResponderChain == true {
                    self.stop(animated: false)
                    self.queue.removeAll()
                    self.container.record.image = nil
                }
            }
            
        }
        else {
            
            // Phonograph controller was added to parent
            // Restart any processes if necessary
            
            if self.tonearmState.causesRecordToSpin && self.shouldPlayWhenNoLongerPartOfResponderChain == false {
                self.play(animated: false)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure that the flipper scroll view content size is proportional to record size for pagation
        self.container.flipperScrollView.delegate = nil
        self.container.flipperScrollView.contentSize.height = self.container.record.frame.size.height * 3
        self.container.flipperScrollView.contentSize.width = self.container.record.frame.size.width * 3
        self.container.flipperScrollView.contentOffset.y = self.container.record.frame.size.height
        self.container.flipperScrollView.contentOffset.x = self.container.record.frame.size.width
        self.container.flipperScrollView.delegate = self
        
        // Size up turntable center peg to fit hole if a current record exists at this point
        if let currentRecord = self.currentRecord {
            let turntableCenterPegConstraints = self.container.turntableCenterPeg.getAllConstraints()
            let appliedScale = self.container.record.frame.size.width / currentRecord.sideUp.image.size.width
            turntableCenterPegConstraints.width?.constant = currentRecord.centerHoleDiameter * appliedScale
            turntableCenterPegConstraints.height?.constant = currentRecord.centerHoleDiameter * appliedScale
        }
        
        // Ensure that the distance between the anchor of the tone arm and the center of the record the tunearm length divided by root 2
        // Do this by adjusting the size of the tone arm as needed
        
        // Define anchor point and stylus point (will differ depending on the tone arm image)
        let tonearmAnchorPoint = CGPoint(x: 0.76, y: 0.2125)
        let tonearmStylusPoint = CGPoint(x: 0.1, y: 0.875)
                
        // Gather dimensional data to calculate the size we need to make the tonearm
        let stylusAnchorXDisplacement = abs(tonearmAnchorPoint.x - tonearmStylusPoint.x)
        let stylusAnchorYDisplacement = abs(tonearmAnchorPoint.y - tonearmStylusPoint.y)
        let tonearmImageWidth = self.container.tonearm.image!.size.width
        let tonearmImageHeight = self.container.tonearm.image!.size.height
        let actualTonearmAnchorPoint = CGPoint(x: tonearmAnchorPoint.x * tonearmImageWidth, y: tonearmAnchorPoint.y * tonearmImageHeight)
        let actualTonearmStylusPoint = CGPoint(x: tonearmStylusPoint.x * tonearmImageWidth, y: tonearmStylusPoint.y * tonearmImageHeight)
        let distanceBetweenStylusAndAnchorX = abs(actualTonearmStylusPoint.x - actualTonearmAnchorPoint.x)
        let distanceBetweenStylusAndAnchorY = abs(actualTonearmStylusPoint.y - actualTonearmAnchorPoint.y)
        let distanceBetweenStylusAndAnchor = sqrt(pow(actualTonearmStylusPoint.x - actualTonearmAnchorPoint.x, 2) + pow(actualTonearmStylusPoint.y - actualTonearmAnchorPoint.y, 2))
        let stylusAnchorTriangleLeftAngle = acos(distanceBetweenStylusAndAnchorX / distanceBetweenStylusAndAnchor)
        let stylusAnchorTriganleTopAngle = acos(distanceBetweenStylusAndAnchorY / distanceBetweenStylusAndAnchor)
        guard
            let tonearmTopMostPos = self.container.tonearm.getConstraint(whereFirstAttributeIsEqualTo: .top)?.constant,
            let tonearmRightMostPos = self.container.tonearm.getConstraint(whereFirstAttributeIsEqualTo: .right)?.constant
        else {
            fatalError("tonearm's position is not constrained by .top and .right layout attributes")
        }
        let distanceBetweenRecordAndTunearm = sqrt(pow(self.container.record.center.x - (tonearmRightMostPos + self.container.frame.width), 2) + pow(self.container.record.center.y - tonearmTopMostPos, 2))
        let stylusAnchorTriangleLegX = distanceBetweenRecordAndTunearm * cos(stylusAnchorTriangleLeftAngle)
        let stylusAnchorTriangleLegY = distanceBetweenRecordAndTunearm * cos(stylusAnchorTriganleTopAngle)
        let tonearmHeightToWidthRatio = tonearmImageHeight / tonearmImageWidth
        let stylusAnchorTriangleLegXMultiplier = 1 + (1 - stylusAnchorXDisplacement - (1 - tonearmAnchorPoint.x))
        let styulsAnchorTriangleLegYMultiplier = 1 + (1 - stylusAnchorYDisplacement - tonearmAnchorPoint.y)
        
        // Define calculated tone arm height and width
        var calculatedTonearmWidth : CGFloat
        var calculatedTonearmHeight : CGFloat
        
        if tonearmHeightToWidthRatio > 1 {
            calculatedTonearmHeight = stylusAnchorTriangleLegY * styulsAnchorTriangleLegYMultiplier
            calculatedTonearmWidth = calculatedTonearmHeight / tonearmHeightToWidthRatio
        } else {
            calculatedTonearmWidth = stylusAnchorTriangleLegX * stylusAnchorTriangleLegXMultiplier
            calculatedTonearmHeight = calculatedTonearmWidth * tonearmHeightToWidthRatio
        }
        
        // Set calculated size for tonearm
        let tonearmConstraints = self.container.tonearm.getAllConstraints()
        tonearmConstraints.width?.constant = calculatedTonearmWidth
        tonearmConstraints.height?.constant = calculatedTonearmHeight
        
        // Set true zero rect, stylus point, anchor point, and adjust layer translation
        self.container.tonearm.trueZeroFrame = CGRect(x: self.container.tonearm.frame.origin.x, y: self.container.tonearm.frame.origin.y, width: calculatedTonearmWidth, height: calculatedTonearmHeight)
        self.container.tonearm.stylusPoint = tonearmStylusPoint
        self.container.tonearm.anchorPoint = tonearmAnchorPoint
        self.container.tonearm.layer.transform = CATransform3DMakeTranslation(
            calculatedTonearmWidth * (self.container.tonearm.anchorPoint.x - 0.5),
            calculatedTonearmHeight * (self.container.tonearm.anchorPoint.y - 0.5),
            0
        )
        
        // Calculate and set rotation angle of tune arm vertically parallel with the board
        let currentTonearmAngle = atan(abs(actualTonearmStylusPoint.x - actualTonearmAnchorPoint.x) / abs(actualTonearmStylusPoint.y - actualTonearmAnchorPoint.y))
        self.container.tonearm.layer.transform = CATransform3DRotate(self.container.tonearm.layer.transform, -currentTonearmAngle, 0, 0, 1)
        
        // Uncomment this line to tone arm show anchor point
        //self.container.tonearm.showPoint(tonearmAnchorPoint, forBounds: CGRect(x: 0, y: 0, width: calculatedTonearmWidth, height: calculatedTonearmHeight))
        
        // Uncomment this line to show tone arm stylus point
        //self.container.tonearm.showPoint(tonearmStylusPoint, forBounds: CGRect(x: 0, y: 0, width: calculatedTonearmWidth, height: calculatedTonearmHeight))
        
        // Uncomment this line to show the record center
        //self.container.record.showPoint(CGPoint(x: 0.5, y: 0.5))
        
        // CALLED DIRECTLY BECAUSE IT WORKS
        self.container.layoutSubviews()
    }
    
    private func setup () {
        
        // Add gesture recognizers
        self.container.tonearm.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(tonearmPanGesture(sender:))))
        
        // Assign delegates
        self.container.flipperScrollView.delegate = self
        
        // Check if record is already loaded in the model
        if let record = self.currentRecord {
            self.container.record.image = record.sideUp.image
        }
        
        // Listen for orientation chagnes
        self.addEventListenerForOrientation()
        
        // Should play in background
        self.setPlaysInBackground(self.shouldPlayInBackground)
    }
    
    fileprivate func configureControlPointsForCurrentRecord () {
        
        guard let record = self.currentRecord
            else { return }
        
        self.controlPoints = ControlPoints(
            tonearmFrame: self.container.tonearm.trueZeroFrame,
            tonearmAnchorPoint: self.container.tonearm.anchorPoint,
            tonearmStylusPoint: self.container.tonearm.stylusPoint,
            boardBounds: self.container.bounds,
            leadInGrooveWidth: record.leadInGrooveWidth,
            centerLabelDiameter: record.centerLabelDiameter,
            runOutGrooveWidth: record.sideUp.runOutGrooveWidth,
            recordDiameter: record.sideUp.image.size.width,
            appliedRecordImageScale: self.container.record.frame.size.width / record.sideUp.image.size.width
        )
    }
    
    @objc private func tonearmPanGesture (sender: UIPanGestureRecognizer) {
        
        // Set control points if they have not been setup
        if self.controlPoints == nil {
            self.configureControlPointsForCurrentRecord()
        }
        
        // Check and make control points have been set
        guard let controlPoints = self.controlPoints
            else { return }
        
        // Define touch location for calculations
        let touchLocation = sender.location(in: self.view)
        
        // Define anchor location for calculations
        let anchorLocation = self.container.tonearm.convert(CGPoint(x: self.container.tonearm.trueZeroFrame.size.width * self.container.tonearm.anchorPoint.x, y: self.container.tonearm.trueZeroFrame.size.height * self.container.tonearm.anchorPoint.y), to: self.container)
        
        // Define stylus location for calculations
        let stylusLocation = self.container.tonearm.convert(CGPoint(x: self.container.tonearm.trueZeroFrame.size.width * self.container.tonearm.stylusPoint.x, y: self.container.tonearm.trueZeroFrame.size.height * self.container.tonearm.stylusPoint.y), to: self.container)
        
        // Calculate angle for tone arm and get current translation identity for the tonearm
        let calculatedAngle = atan(abs(touchLocation.x - anchorLocation.x) / abs(touchLocation.y - anchorLocation.y)) + controlPoints.tonearmTrueZeroAngle
        let currentTransformIdentity = self.container.tonearm.layer.transform
        let currentTranslationIdenty = CATransform3DMakeTranslation(currentTransformIdentity.m41, currentTransformIdentity.m42, currentTransformIdentity.m43)
        
        // Calculate actual angle for tone arm based off of stylus and anchor
        let actualAngle = atan(abs(stylusLocation.x - anchorLocation.x) / abs(stylusLocation.y - anchorLocation.y)) + controlPoints.tonearmTrueZeroAngle
        
        // Determine recognizer state so we can update tone arm state
        switch sender.state {
        case .began, .changed:
            
            self.tonearmState = .userIsHoldingTonearm
            
        default:
            
            // Set the last tonearm touchdown angle
            self.controlPoints?.tonearmLastTouchdownAngle = actualAngle
            
            // Evaluate tone arm position to determine state
            if actualAngle <= controlPoints.tonearmTrueZeroAngle {
                self.tonearmState = .tonearmIsOnRest
            }
            else if actualAngle < controlPoints.leadInGrooveStartAngle {
                self.tonearmState = .tonearmNotOnRecord
            }
            else if actualAngle >= controlPoints.leadInGrooveStartAngle && calculatedAngle < controlPoints.leadInGrooveEndAngle {
                self.tonearmState = .tonearmIsOnLeadInGroove
            }
            else if actualAngle >= controlPoints.vinylTrackStartAngle && calculatedAngle < controlPoints.vinylTrackEndAngle {
                self.tonearmState = .tonearmIsOnVinylTrack
            }
            else if actualAngle >= controlPoints.runOutGrooveStartAngle && calculatedAngle < controlPoints.runOutGrooveEndAngle {
                self.tonearmState = .tonearmIsOnRunOutGroove
            }
            else {
                self.tonearmState = .tonearmIsOnCenterLabel
            }
        }
        
        // Make sure tone arm doesn't swing beyond the center of the record
        guard controlPoints.tonearmTrueCenterAngle > calculatedAngle else {
            self.container.tonearm.layer.transform = CATransform3DRotate(currentTranslationIdenty, (controlPoints.tonearmTrueCenterAngle), 0, 0, 1)
            return
        }
        
        // Make sure tone arm doesn't swing beyond the tone arm rest
        guard touchLocation.x < anchorLocation.x else {
            self.container.tonearm.layer.transform = CATransform3DRotate(currentTranslationIdenty, controlPoints.tonearmTrueZeroAngle, 0, 0, 1)
            return
        }
        
        // Set angle for tone arm, blend with current translation identity
        self.container.tonearm.layer.transform = CATransform3DRotate(currentTranslationIdenty, calculatedAngle, 0, 0, 1)
        
    }
    
    private func beginRecordSpin () {
        
        // Setup display link
        self.displayLink = CADisplayLink(target: self, selector: #selector(onFrameInterval(displayLink:)))
        self.displayLink?.preferredFramesPerSecond = 60
        self.displayLink?.add(to: .current, forMode: RunLoop.Mode.default)
    }
    
    private func stopRecordSpin () {
        
        // Invalidate display link
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    
    
    fileprivate func bringTonearmToAngle (_ angle: CGFloat, animated: Bool, completion: (() -> Void)? = nil) {
        
        // Get current transformation identities
        let currentTransformIdentity = self.container.tonearm.layer.transform
        let currentTranslationIdenty = CATransform3DMakeTranslation(currentTransformIdentity.m41, currentTransformIdentity.m42, currentTransformIdentity.m43)
        
        if animated {
            
            // Disable user interaction on tonearm until animation is finished
            self.container.tonearm.isUserInteractionEnabled = false
            
            // Rotate tonearm animated
            self.container.tonearm.layer.applyStickyTransformationAnimation(moveToNewValue: CATransform3DRotate(currentTranslationIdenty, angle, 0, 0, 1), withDuration: 1.0, andTimingFunction: .easeInEaseOut) {
                
                // Re-enable user interaction on tone arm
                self.container.tonearm.isUserInteractionEnabled = true
                
                // Call completion
                completion?()
            }
        }
        else {
            self.container.tonearm.layer.transform = CATransform3DRotate(currentTranslationIdenty, angle, 0, 0, 1)
            completion?()
        }
        
    }
    
    
    @objc private func onFrameInterval (displayLink: CADisplayLink) {
        
        // Unwrap current record and control points
        guard let currentRecord = self.currentRecord,
            let controlPoints = self.controlPoints
            else { return }
        
        // Get frames per second
        let framesPerSecond = Double(displayLink.preferredFramesPerSecond)
        
        // Based on fps, calculate how much record should spin each interval
        let rotationsPerSecond = (currentRecord.style.rawValue) / 60
        let anglePerSecond = rotationsPerSecond * (2 * Double.pi)
        let anglePerInterval = CGFloat(anglePerSecond / framesPerSecond)
        
        // Rotate record to match the current angle of the interval
        self.container.record.layer.transform = CATransform3DRotate(self.container.record.layer.transform, anglePerInterval, 0, 0, 1)
        
        
        // Define variables to calculate how we should move the stylus
        var shouldUpdateStylusLoc = false
        var angleRange : Double!
        var calculatedDuration : Double!
        var doNotExceedAngle : CGFloat!
        var flagStateIfNeeded : TonearmState!
        
        // Check if tone arm is on lead-in groove
        if self.tonearmState == .tonearmIsOnLeadInGroove {
            
            guard let tonearmLastTouchdownAngle = controlPoints.tonearmLastTouchdownAngle
                else { return }
            
            // Flag, then calculate variables
            shouldUpdateStylusLoc = true
            angleRange = Double(abs(controlPoints.leadInGrooveStartAngle - controlPoints.leadInGrooveEndAngle))
            calculatedDuration = currentRecord.leadInGrooveDuration * (Double(abs(tonearmLastTouchdownAngle - controlPoints.leadInGrooveEndAngle)) / angleRange)
            doNotExceedAngle = controlPoints.leadInGrooveEndAngle
            flagStateIfNeeded = .tonearmIsOnVinylTrack
        }
        
        // Check if tone arm is on vinyl track
        else if self.tonearmState == .tonearmIsOnVinylTrack {
            
            // Make sure audio player is playing and not buffering or something
            guard let audioPlayer = self.audioPlayer,
                audioPlayer.isPlaying == true else {
                    
                    // Alert delegate that we are in a buffer of some sort if we have not already
                    if self.isAssumedBuffering == false {
                        self.isAssumedBuffering = true
                        self.delegate?.phonographIsAssumedBuffering(self, isAssumedBuffering: self.isAssumedBuffering)
                        
                        // Check if we should load static noise audio player
                        if self.onlyPlaysStaticNoiseWhenBuffering == true {
                            self.loadStaticNoiseAudioContents()
                            self.staticNoiseAudioPlayer?.play()
                        }
                    }
                    
                    return
            }
            
            // Check if we just got out of an assumed buffer
            if self.isAssumedBuffering == true {
                self.isAssumedBuffering = false
                self.delegate?.phonographIsAssumedBuffering(self, isAssumedBuffering: self.isAssumedBuffering)
                
                // Check if we should kill the static noise audio player
                if self.onlyPlaysStaticNoiseWhenBuffering == true {
                    self.staticNoiseAudioPlayer?.stop()
                    self.staticNoiseAudioPlayer = nil
                }
            }
            
            // Flag, then calculate variables
            shouldUpdateStylusLoc = true
            angleRange = Double(abs(controlPoints.vinylTrackStartAngle - controlPoints.vinylTrackEndAngle))
            calculatedDuration = currentRecord.sideUp.durations.reduce(0, +)
            doNotExceedAngle = controlPoints.vinylTrackEndAngle
            flagStateIfNeeded = .tonearmIsOnRunOutGroove
        }
        
        // Check if tone arm is on run-out groove
        else if self.tonearmState == .tonearmIsOnRunOutGroove {
            
            guard let tonearmLastTouchdownAngle = controlPoints.tonearmLastTouchdownAngle
                else { return }
            
            let proportionalAngle = max(tonearmLastTouchdownAngle, controlPoints.runOutGrooveStartAngle)
        
            // Flag, then calculate variables
            shouldUpdateStylusLoc = true
            angleRange = Double(abs(controlPoints.runOutGrooveStartAngle - controlPoints.runOutGrooveEndAngle))
            calculatedDuration = currentRecord.sideUp.runOutGrooveDuration * (Double(abs(proportionalAngle - controlPoints.runOutGrooveEndAngle)) / angleRange)
            doNotExceedAngle = controlPoints.runOutGrooveEndAngle
            flagStateIfNeeded = .tonearmIsOnCenterLabel
        }
        
        // Update the tonearm stylus location if needed
        if shouldUpdateStylusLoc {
            
            self.updateStylusLocation(
                basedOnDuration: calculatedDuration,
                framesPerSecond: framesPerSecond,
                andAngleRange: angleRange,
                doNotExceedAngle: doNotExceedAngle,
                flagStateIfNeeded: flagStateIfNeeded
            )
        }
    }
    
    private func updateStylusLocation (basedOnDuration duration: Double, framesPerSecond: Double, andAngleRange angleRange: Double, doNotExceedAngle: CGFloat, flagStateIfNeeded flagState: TonearmState) {
        
        // Get current tone arm angle
        let currentTonearmAngle = atan2(self.container.tonearm.layer.transform.m12, self.container.tonearm.layer.transform.m11)
        
        // Calculate angles per frame the tone arm needs to move at
        let tonearmAnglesPerFrame = CGFloat(angleRange / duration / framesPerSecond)
        
        // Make sure angles per frame does not exceed the true center angle of the center of the record
        guard tonearmAnglesPerFrame + currentTonearmAngle < doNotExceedAngle else {
            
            // Separate transformation identies
            let currentTransformIdentity = self.container.tonearm.layer.transform
            let currentTranslationIdenty = CATransform3DMakeTranslation(currentTransformIdentity.m41, currentTransformIdentity.m42, currentTransformIdentity.m43)
            
            // Set true center angle for tone arm
            self.container.tonearm.layer.transform = CATransform3DRotate(currentTranslationIdenty, doNotExceedAngle, 0, 0, 1)
            
            // Flag tone arm state and return
            self.tonearmState = flagState
            return
        }
        
        // Rotate tonearm by claculated tone arm angles per frame, thus updating the stylus location
        self.container.tonearm.layer.transform = CATransform3DRotate(self.container.tonearm.layer.transform, tonearmAnglesPerFrame, 0, 0, 1)
    }
    
    fileprivate func updateStylusLocaton (basedOnAudioTrackTimeIndex timeIndex: Double, animated: Bool, completion: (() -> Void)? = nil) {
        
        // Unwrap control points and record
        guard let controlPoints = self.controlPoints,
            let record = self.currentRecord
            else { return }
        
        // Define start angle and total angle range of track
        let startAngle = controlPoints.vinylTrackStartAngle
        let angleRange = abs(controlPoints.vinylTrackStartAngle - controlPoints.vinylTrackEndAngle)
        let percentOfAudioTrackComplete = CGFloat(timeIndex / record.sideUp.durations.reduce(0, +))
        let calculatedAngleOfTonearmForTimeIndex = angleRange * percentOfAudioTrackComplete + startAngle
        
        // Update sylus location
        self.bringTonearmToAngle(calculatedAngleOfTonearmForTimeIndex, animated: animated) {
            completion?()
        }
    }
    
    fileprivate func loadCurrentRecord (shouldLayoutIfNeeded: Bool = true) {
        
        guard let currentRecord = self.currentRecord
            else { return }
        
        // Load audio for record
        self.loadCurrentRecordAudioContents()
        
        // Set image for record
        self.container.record.image = currentRecord.sideUp.image
        
        // Check if the current record is a 45, if so opt for the adapter for the center peg
        if currentRecord.style == .EP {
            self.container.turntableCenterPeg.image = UIImage(named: "record_player_fourty-five_adapter")!
        } else {
            self.container.turntableCenterPeg.image = UIImage(named: "record_player_turntable_center_peg")!
        }
        
        if shouldLayoutIfNeeded {
            
            // Size up turntable center peg to fit hole
            let turntableCenterPegConstraints = self.container.turntableCenterPeg.getAllConstraints()
            let appliedScale = self.container.record.frame.size.width / currentRecord.sideUp.image.size.width
            turntableCenterPegConstraints.width?.constant = currentRecord.centerHoleDiameter * appliedScale
            turntableCenterPegConstraints.height?.constant = currentRecord.centerHoleDiameter * appliedScale
            self.container.turntableCenterPeg.layoutIfNeeded()
        }
        
    }
    
    fileprivate func loadStaticNoiseAudioContents () {
        
        self.staticNoiseAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "static_noise_effect.mp3", ofType: nil)!))
        self.staticNoiseAudioPlayer?.numberOfLoops = -1 // Plays on infinite loop until we want to stop it
        self.staticNoiseAudioPlayer?.setVolume(self.staticNoiseVolume, fadeDuration: 0)
        self.staticNoiseAudioPlayer?.prepareToPlay()
    }
    
    fileprivate func loadCurrentRecordAudioContents () {
        
        guard let currentRecord = self.currentRecord
            else { return }
        
        do {
            
            // Try to load audio contents of url
            self.audioPlayer = try AVAudioPlayer(contentsOf: currentRecord.sideUp.audioFileURL)
            
            // URL is valid, prepare to play and set delegate
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.delegate = self
            
            
        } catch {
            print("Phonograph unable to load audio file for record: \(currentRecord.sideUp.audioFileURL.absoluteString)")
        }
        
        // Check if we should load static noise audio player
        if self.onlyPlaysStaticNoiseWhenBuffering == false {
            self.loadStaticNoiseAudioContents()
        }
    }
    
    fileprivate func beginPlayingCurrentRecordAudio (atTimeIndex timeIndex: Double) {
        
        self.audioPlayer?.currentTime = TimeInterval(exactly: timeIndex) ?? timeIndex
        self.audioPlayer?.play()
        self.staticNoiseAudioPlayer?.play()
    }
    
    fileprivate func stopPlayingCurrentRecordAudio () {
        
        self.audioPlayer?.pause()
        self.audioPlayer?.currentTime = TimeInterval(exactly: 0) ?? 0
        self.audioPlayer?.prepareToPlay()
        self.staticNoiseAudioPlayer?.stop()
        self.staticNoiseAudioPlayer?.prepareToPlay()
    }
}


// MARK: - Interface methods
extension PhonographController {
    
    /// Returns current record on the phonograph (the last record in the queue)
    public var currentRecord : PhonographRecord? {
        return queue.last
    }
    
    /// Plays current record at indicated time. If a time is not passed, the record will start playing from the beginning or wherever audio track was paused
    public func play (atTimeInSeconds time: Double? = nil, animated: Bool, completion: (() -> Void)? = nil) {
        
        let specifiedTime = time ?? self.audioPlayer?.currentTime ?? 0
        
        // Make sure we have set the control points
        if self.controlPoints == nil {
            self.configureControlPointsForCurrentRecord()
        }
        
        // Make sure stylus location matches up with new time set for the audio track
        if animated {
            
            self.updateStylusLocaton(basedOnAudioTrackTimeIndex: specifiedTime, animated: true) {
                
                // Flag tonearm state
                self.tonearmState = .tonearmIsOnVinylTrack
            }
        }
        else {
            
            self.updateStylusLocaton(basedOnAudioTrackTimeIndex: specifiedTime, animated: false)
            
            // Flag tonearm state
            self.tonearmState = .tonearmIsOnVinylTrack
        }
        
    }
    
    /// Stops playing the current record and brings the tonearm to the rest position
    public func stop (animated: Bool, completion: (() -> Void)? = nil) {
        
        // Check and make control points have been set
        guard let controlPoints = self.controlPoints
            else { return }
        
        // Bring tonearm to rest
        self.bringTonearmToAngle(controlPoints.tonearmTrueZeroAngle, animated: animated) {
            
            // Flag tonearm state
            self.tonearmState = .tonearmIsOnRest
            
            completion?()
        }
    }
    
    /// Flips the current record on the phonograph to the other side of the record (this method will stop the record spin and bring tonearm to rest if the record is playing at the time when this method is called)
    public func flip (animated: Bool, completion: (() -> Void)? = nil) {
        
        // Unwrap current record
        guard let currentRecord = self.currentRecord
            else { return }
        
        // Check if we need to stop spining the current record
        if self.tonearmState != .tonearmIsOnRest {
            self.stop(animated: animated) {
                self.flip(animated: animated, completion: completion)
            }
            return
        }
        
        if animated {
            
            // Disable user interaction on tonearm until animation is finished
            self.container.tonearm.isUserInteractionEnabled = false
            
            // Set record z index
            self.container.record.layer.zPosition = CGFloat(MAXFLOAT)
            
            // Flip record halfway animated
            self.container.record.layer.applyStickyTransformationAnimation(
                moveToNewValue: CATransform3DConcat(CATransform3DRotate(self.container.record.layer.transform, CGFloat.pi/2, 1, 1, 0), CATransform3DMakeScale(1.25, 1.25, 1)),
                withDuration: 0.5,
                andTimingFunction: .easeIn
            ) {
                
                // Switch record image to the other side and update the orientation property of the record
                if currentRecord.orientation == .a {
                    self.queue[self.queue.count - 1].orientation = .b
                } else {
                    self.queue[self.queue.count - 1].orientation = .a
                }
                
                // Re-load this record for the contents of the new side
                self.loadCurrentRecord(shouldLayoutIfNeeded: false)
                
                // Finish record flip animated
                self.container.record.layer.applyStickyTransformationAnimation(
                    moveToNewValue: CATransform3DConcat(CATransform3DRotate(self.container.record.layer.transform, -CGFloat.pi/2, 1, 1, 0), CATransform3DMakeScale(0.75, 0.75, 1)),
                    withDuration: 0.5,
                    andTimingFunction: .easeOut
                ) {
                    
                    // Re-enable user interaction on tonearm
                    self.container.tonearm.isUserInteractionEnabled = true
                    
                    // Reset record z index
                    self.container.record.layer.zPosition = 0
                    
                    // Call completion
                    completion?()
                }
            }
        }
        else {
            
            // Switch record image to the other side and update the orientation property of the record
            if currentRecord.orientation == .a {
                self.queue[self.queue.count - 1].orientation = .b
            } else {
                self.queue[self.queue.count - 1].orientation = .a
            }
            
            // Re-load this record for the contents of the new side
            self.loadCurrentRecord(shouldLayoutIfNeeded: false)
            
            // Call completion
            completion?()
        }
    }
    
    /// Adds a new record to the queue
    public func enqueueRecord (_ record: PhonographRecord) {
        
        // Add record to queue
        self.queue.insert(record, at: 0)
        
        // If this is the first record added to the queue, we should begin loading audio and set the record image
        if self.queue.count == 1 {
            
            // Load record
            self.loadCurrentRecord()
        }
    }
    
    
    
    /// Removes  and returns record at index from the queue
    @discardableResult
    public func dequeueRecord (at index: Int) -> PhonographRecord {
        
        // Store this record so we may return it
        let record = self.queue[index]
        
        // If this is the current record we are dequeuing, go to next
        if self.queue.count - 1 == index {
            self.stop(animated: false)
            self.container.record.image = nil
        }
        
        // Remove
        self.queue.remove(at: index)
        
        return record
    }
    
    
    /// Moves to next record in the queue (this method will stop the record spin and bring tonearm to rest if the record is playing at the time when this method is called)
    public func next (animated: Bool, completion: (() -> Void)? = nil) {
        
        // Check if we need to stop spining the current record
        if self.tonearmState != .tonearmIsOnRest {
            self.stop(animated: animated) {
                self.next(animated: animated, completion: completion)
            }
            return
        }
        
        // Make sure we have another record in the queue to move to
        guard self.queue.count > 1
            else { fatalError("Phonograph: next record was not found in the queue") }
        
        // Remove last record from queue
        self.queue.removeLast()
        
        if animated {
                
            // Disable user interaction on tonearm until animation is finished
            self.container.tonearm.isUserInteractionEnabled = false
            
            // Set record z index
            self.container.record.layer.zPosition = CGFloat(MAXFLOAT)
            
            // Get current record rotation angle and calculate how much we need to rotate the record by to acheive an angle of zero
            let currentRecordAngle = atan2(self.container.record.layer.transform.m12, self.container.record.layer.transform.m11)
            var halfToZeroAngle : CGFloat {
                if ((CGFloat.pi * 2) - currentRecordAngle) / 2 == CGFloat.zero {
                    return CGFloat.pi
                } else {
                    return ((CGFloat.pi * 2) - currentRecordAngle) / 2
                }
            }
            
            // Flip record halfway animated
            self.container.record.layer.applyStickyTransformationAnimation(
                moveToNewValue: CATransform3DConcat(CATransform3DRotate(self.container.record.layer.transform, halfToZeroAngle, 0, 0, 1), CATransform3DMakeScale(1.25, 1.25, 1)),
                withDuration: 0.5,
                opacityChange: 0,
                andTimingFunction: .easeIn
            ) {
                
                // Load record
                self.loadCurrentRecord()
                
                // Finish record flip animated
                self.container.record.layer.applyStickyTransformationAnimation(
                    moveToNewValue: CATransform3DConcat(CATransform3DRotate(self.container.record.layer.transform, halfToZeroAngle, 0, 0, 1), CATransform3DMakeScale(0.75, 0.75, 1)),
                    withDuration: 0.5,
                    opacityChange: 1,
                    andTimingFunction: .easeOut
                ) {
                    
                    // Re-enable user interaction on tonearm
                    self.container.tonearm.isUserInteractionEnabled = true
                    
                    // Reset record z index
                    self.container.record.layer.zPosition = 0
                    
                    // Call completion
                    completion?()
                }
            }
        }
        else {
            
            // Load record
            self.loadCurrentRecord()
            
            // Bring record to center rotation
            self.container.record.layer.transform = CATransform3DMakeRotation(0, 1, 1, 1)
            
            // Call completion
            completion?()
        }
    }
    
    /// Continues to play audio after application exits the foreground when set to true
    public func setPlaysInBackground (_ playsInBackground: Bool) {
        
        // Flag
        self.shouldPlayInBackground = playsInBackground
        
        if playsInBackground {
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error)
            }
        }
        else {
            
            do {
                try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers, .allowAirPlay])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print(error)
            }
        }
    }
    
    /// Continues to play audio after phonograph controller is no longer part of the responder chain when set to true
    public func setPlaysWhenNoLongerPartOfResponderChain (_ playsWhenNoLongerPartOfResponderChain: Bool) {
        self.shouldPlayWhenNoLongerPartOfResponderChain = playsWhenNoLongerPartOfResponderChain
    }
    
    /// Sets the volume level of the static noise from the stylus on the record on a scale of zero to one. Default volume is 50%.
    public func setStaticNoiseVolume (_ volume: Float) {
        self.staticNoiseVolume = volume
    }
    
    /// Method to enable or disable static noises coming from the phonograph as a result of the stylus on the record when audio player is not buffering
    public func setOnlyPlaysStaticNoiseWhenBuffering (_ onlyPlaysStaticNoiseWhenBuffering: Bool) {
        
        self.onlyPlaysStaticNoiseWhenBuffering = onlyPlaysStaticNoiseWhenBuffering
        
        // Make sure the static noise audio player is dead if true
        if onlyPlaysStaticNoiseWhenBuffering {
            self.staticNoiseAudioPlayer?.stop()
            self.staticNoiseAudioPlayer = nil
        }
    }
}

