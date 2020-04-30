# Phonograph
iOS Phonograph (Record Player)

Fully functional, realistic, phonograph player. Supports 33's 45's and 78's and can be easily used with custom record designs/images for any audio using minimal and native iOS frameworks. Just download the project!

![Alt Text](https://media.giphy.com/media/S9XGm4qHSvgJ8jcNVw/giphy.gif)

## Implementation
`PhonographController` does the bulk lifting and is how you interface with the overall phonograph player and is implemented as a container view controller which follows the singleton patern. Access to the singleton is as such: `PhonographController.shared`. In order to play, display, and interact with a record it must be enqueued on the `PhonographController`. The source code for the implementation in this project, as a demo, can be found in the `ViewController.swift` file inside of `viewDidLoad`.

> Note: If you fancy creating multiple instances of `PhonographController` you will want to remove the `shared` instance which is defined in the `PhonographController` class and need to remove the `privacy` access level off the initializer for `PhonographController` This may also cause the `setPlaysWhenNoLongerPartOfResponderChain` and `setPlaysInBackground` methods to not work as expected if the particular instance of `PhonographController` is deallocated all together. 

Another important implementation piece to be aware of is the actual tonearm image. If you customize the image you will want to ensure that the anchor point of the tonearm (this is the point that the tonearm will be rotated around) and the stylus point of the tonearm (the point where the needle is on the tonearm) are set properly and accurately to achieve expected results. Both of these properties are stored and can be configured on the `PhonographTonearmView` class. In this base project, I have left the following lines inside the `PhonographController`'s `viewDidLayoutSubviews` method which show where these points are actually located to help during setup:

```swift
// Uncomment this line to tone arm show anchor point
//self.container.tonearm.showPoint(tonearmAnchorPoint, forBounds: CGRect(x: 0, y: 0, width: calculatedTonearmWidth, height: calculatedTonearmHeight))
        
// Uncomment this line to show tone arm stylus point
//self.container.tonearm.showPoint(tonearmStylusPoint, forBounds: CGRect(x: 0, y: 0, width: calculatedTonearmWidth, height: calculatedTonearmHeight))
```

## Inteface
Listed below are all of the methods that can be used to interact with the `PhonographController` object:
```swift
/// Plays current record at indicated time. If a time is not passed, the record will start playing from the beginning or wherever audio track was paused
public func play (atTimeInSeconds time: Double? = nil, animated: Bool, completion: (() -> Void)? = nil)

/// Stops playing the current record and brings the tonearm to the rest position
public func stop (animated: Bool, completion: (() -> Void)? = nil)

/// Flips the current record on the phonograph to the other side of the record (this method will stop the record spin and bring tonearm to rest if the record is playing at the time when this method is called)
public func flip (animated: Bool, completion: (() -> Void)? = nil)

/// Adds a new record to the queue
public func enqueueRecord (_ record: PhonographRecord)

/// Removes  and returns record at index from the queue
@discardableResult
public func dequeueRecord (at index: Int) -> PhonographRecord

/// Moves to next record in the queue (this method will stop the record spin and bring tonearm to rest if the record is playing at the time when this method is called)
public func next (animated: Bool, completion: (() -> Void)? = nil)

/// Continues to play audio after application exits the foreground when set to true
public func setPlaysInBackground (_ playsInBackground: Bool)

/// Continues to play audio after phonograph controller is no longer part of the responder chain when set to true
public func setPlaysWhenNoLongerPartOfResponderChain (_ playsWhenNoLongerPartOfResponderChain: Bool)

/// Sets the volume level of the static noise from the stylus on the record on a scale of zero to one. Default volume is 50%.
public func setStaticNoiseVolume (_ volume: Float)

/// Method to enable or disable static noises coming from the phonograph as a result of the stylus on the record when audio player is not buffering
public func setOnlyPlaysStaticNoiseWhenBuffering (_ onlyPlaysStaticNoiseWhenBuffering: Bool)
```

## Delegate Methods
```swift
/// Occurs whenever tonearm is on the actively spinning vinyl track sound grooves but not playing audio. Also called upon release.
func phonographIsAssumedBuffering (_ phonographController: PhonographController, isAssumedBuffering: Bool)

func phonographTonearmStateWillChange (_ phonographController: PhonographController, newTonearmState: PhonographController.TonearmState)
```
---
Also note that I am not the creator of any of the media content in the assets folder appart from the record images themselves and they should not be used for commercial purposes.
