//
//  ViewController.swift
//  ARAttempt
//
//  Created by Evan Latner on 9/1/16.
//  Copyright © 2016 levellabs. All rights reserved.
//

import UIKit
//import CameraEngine
import Foundation
import SceneKit
import CoreMotion
import SpriteKit
import AVFoundation
import CoreAudioKit
import HealthKit
import AudioToolbox
import GoogleMobileAds
import Parse

func degreesToRadians(degrees: Float) -> Float {
    return (degrees * Float(M_PI)) / 180.0
}

func radiansToDegrees(radians: Float) -> Float {
    return (180.0/Float(M_PI)) * radians
}

class ViewController: UIViewController, SCNSceneRendererDelegate, SCNPhysicsContactDelegate, UIScrollViewDelegate, GADInterstitialDelegate, GADBannerViewDelegate, CZPickerViewDelegate, CZPickerViewDataSource {
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    //let cameraEngine = CameraEngine()
    var i = 1
    var motionManager : CMMotionManager?
    var boingBallNode : SCNNode?
    var tappableNode : SCNNode?
    var initialAttitude : CMAttitude?
    var scene : SCNScene?
    var trumpScene : SCNScene?
    var pumpkin : SCNNode?
    var cameraNode : SCNNode?
    var fire : SCNParticleSystem?
    var scnView : SCNView?
    var player: AVAudioPlayer?
    var player2: AVAudioPlayer?
    var highScoreLabel : UILabel?
    var scoreLabel : UILabel?
    var tapCount : Int?
    var nodeTimer : NSTimer?
    var speed : Float?
    var gameEnding : Bool?
    var gameIsPlaying : Bool?
    var blurEffectView : UIVisualEffectView?
    var scrollView: UIScrollView?
    var levelView : LevelView?
    var bottomView : BottomView?
    var iPhone4StartButton : UIButton?
    var liveLeaderBoardButton : UIButton?
    var myUsernameLabel : UILabel?
    
    var topArrow : UIImageView?
    var bottomArrow : UIImageView?
    var rightArrow : UIImageView?
    var leftArrow : UIImageView?
    
    var gameCount : Int?
    var appRunning : Bool?
    var popup: GADInterstitial!
    var appDelegate : AppDelegate?
    var picker : CZPickerView?
    
    var tutorialView : TutorialView?
    
    var highScoreUsers : NSMutableArray?
    
    @IBOutlet weak var customLevelView: LevelView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var highScoreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        tapCount = 0
        speed = 1
        gameEnding = false
        gameIsPlaying = false
        gameCount = 0
        
        topArrow = UIImageView()
        topArrow?.frame = CGRectMake(self.view.frame.width/2-75, 0, 150, 50)
        topArrow?.image = UIImage(named: "doubleUp")
        self.view.addSubview(topArrow!)
        topArrow?.alpha = 0.0

        bottomArrow = UIImageView()
        bottomArrow?.frame = CGRectMake(self.view.frame.width/2-75, self.view.frame.size.height-50, 150, 50)
        bottomArrow?.image = UIImage(named: "doubleDown")
        self.view.addSubview(bottomArrow!)
        bottomArrow?.alpha = 0.0
        
        rightArrow = UIImageView()
        rightArrow?.frame = CGRectMake(self.view.frame.size.width-50, self.view.frame.size.height/2-75, 50, 150)
        rightArrow?.image = UIImage(named: "rightDouble")
        self.view.addSubview(rightArrow!)
        rightArrow?.alpha = 0.0
        
        leftArrow = UIImageView()
        leftArrow?.frame = CGRectMake(0, self.view.frame.size.height/2-75, 50, 150)
        leftArrow?.image = UIImage(named: "leftDouble")
        self.view.addSubview(leftArrow!)
        leftArrow?.alpha = 0.0

        // Create Camera
        //self.cameraEngine.startSession()
        self.setupCameraBackground()
        
        // Create Scene
        scene = SCNScene()
        scene?.physicsWorld.contactDelegate = self
        
        let newView = SCNView()
        newView.delegate = self
        newView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
        newView.backgroundColor = UIColor.clearColor()
        
        // Retrieve the SCNView
        self.scnView  = newView
        self.scnView!.delegate = self
        self.scnView!.playing = true
        
        //self.scnView?.gestureRecognizers = nil
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(_:)))
        self.scnView?.addGestureRecognizer(tap)

        
        // set scene to view
        self.scnView!.scene = scene
        self.view.addSubview(newView)
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView!.frame = view.bounds
        blurEffectView?.alpha = 1.0
        blurEffectView!.autoresizingMask = [.FlexibleWidth, .FlexibleHeight] // for supporting device rotation
        self.view.addSubview(blurEffectView!)
        
        self.setupLabelsAndButtons()
        self.createCamera()
        self.scoreLabel?.alpha = 0.0
        
        self.setupScrollViewAndLevels()
        
        popup = createAndLoadInterstitial()
        
        self.getLeaderboardHighScores()
        
        let hasPlayedGame = NSUserDefaults.standardUserDefaults().objectForKey("hasRanAppOnce")
        if hasPlayedGame == nil {
            
            self.hideMenu()
            self.showTutorial()
            
            NSUserDefaults.standardUserDefaults().setObject("yes", forKey: "hasRanAppOnce")
            NSUserDefaults.standardUserDefaults().synchronize()

        } else {
            
        }
        
    }
    
    func showTutorial () {
        
        // Show Tut View
        self.tutorialView = (NSBundle.mainBundle().loadNibNamed("TutorialView", owner: self, options: nil)[0] as? TutorialView)!
        self.tutorialView?.backgroundColor = UIColor.clearColor()
        self.tutorialView!.frame = self.view.frame
        self.view.addSubview(self.tutorialView!)
        self.view.bringSubviewToFront(self.tutorialView!)
        self.tutorialView?.alpha = 1.0
        let tap = UITapGestureRecognizer(target: self, action: #selector(showMenu))
        self.tutorialView?.addGestureRecognizer(tap)
    }
    
    func hideTutorial () {
        
        if self.tutorialView != nil {
            UIView.animateWithDuration(0.12, delay: 0.1, options: UIViewAnimationOptions.TransitionNone, animations: {
                self.tutorialView?.alpha = 0.0
            }) { (true) in
            }
        }
    }
    
    func hideMenu () {
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
            
            if self.iPhone4StartButton != nil {
                self.iPhone4StartButton?.alpha = 0.0
            }
            self.startButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
            self.startButton.alpha = 0.0
            self.blurEffectView!.alpha = 0.0
            self.highScoreLabel?.alpha = 0.0
            self.scrollView?.alpha = 0.0
            self.liveLeaderBoardButton?.alpha = 0.0
            
        }) { (true) in
            UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                self.startButton.alpha = 0.0
                
            }) { (true) in
            }
        }
    }
    
    func showMenu () {
        
        self.hideTutorial()
        
        dispatch_async(dispatch_get_main_queue()) {
            
            UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                self.blurEffectView!.alpha = 1.0
            }) { (true) in
            }
            
            self.startButton.transform = CGAffineTransformMakeScale(0.0, 0.0)
            self.startButton.alpha = 1.0
            if self.iPhone4StartButton != nil {
                self.iPhone4StartButton?.alpha = 1.0
            }
            UIView.animateWithDuration(0.15, delay: 0.80, options: UIViewAnimationOptions.TransitionNone, animations: {
                self.startButton.transform = CGAffineTransformMakeScale(1.15, 1.15)
                self.highScoreLabel?.alpha = 0.88
                self.scrollView?.alpha = 1.0
                self.liveLeaderBoardButton?.alpha = 0.80
            }) { (true) in
                UIView.animateWithDuration(0.16, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                    self.startButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    self.scoreLabel?.alpha = 0.0
                    self.pageControl.alpha = 1.0
                }) { (true) in
                }
            }
        }

        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let bannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
        bannerView.delegate = self
        bannerView.adUnitID = "ca-app-pub-4115283290436108/3883521279"
        bannerView.rootViewController = self
        bannerView.frame = CGRectMake(0, self.view.frame.size.height-50, self.view.frame.size.width, 50)
        let request = GADRequest()
        //request.testDevices = ["004a71076310e236c6691629c9cdbc21"]
        bannerView.loadRequest(request)
        //bannerView.loadRequest(GADRequest())
        bannerView.hidden = false
        self.view.addSubview(bannerView)
        self.view.bringSubviewToFront(bannerView)
        
    }
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        bannerView.hidden = false
        print("Got banner ad!")
    }
    
    func adView(bannerView: GADBannerView!,
                didFailToReceiveAdWithError error: GADRequestError!) {
        print("Banner View Error: \(error.localizedDescription)")
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-4115283290436108/3523594479")
        
        interstitial.delegate = self
        let request = GADRequest()
        //request.testDevices = [ kGADSimulatorID, "004a71076310e236c6691629c9cdbc21" ]
        interstitial.loadRequest(request)
        
        return interstitial
    }
    
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print(error.localizedDescription)
    }
    
    func interstitialDidDismissScreen(ad: GADInterstitial!) {
        //print("called!")
        popup = createAndLoadInterstitial()
    }
    
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        //print("AdMob interstitial did receive ad from: \(ad.adNetworkClassName)")
    }
    
    func setupScrollViewAndLevels () {
        
        self.scrollView = UIScrollView()
        self.scrollView?.delegate = self
        self.scrollView?.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2+12)
        if UIScreen.mainScreen().bounds.size.height < 568.0 {
            self.scrollView?.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2+72)
        }
        if UIScreen.mainScreen().bounds.size.height == 568.0 {
            self.scrollView?.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2+62)
        }
        self.scrollView!.contentSize = CGSizeMake(self.view.frame.size.width+1, self.scrollView!.frame.size.height)
        self.scrollView!.pagingEnabled = true
        self.scrollView!.scrollEnabled = true
        self.scrollView?.bounces = true
        self.scrollView?.showsHorizontalScrollIndicator = false
        self.scrollView?.showsVerticalScrollIndicator = false
        self.view.addSubview(self.scrollView!)
        self.view.bringSubviewToFront(self.scrollView!)
    
        // for i in 0...1 {
        
        let width = self.scrollView?.frame.size.width
        
        self.levelView = NSBundle.mainBundle().loadNibNamed("LevelView", owner: self, options: nil)[0] as? LevelView
        //self.levelView!.frame = CGRectMake(width!*CGFloat(i)+50, 156, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+14)
    
        self.levelView!.frame = CGRectMake(50, 156, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+14)
        
        if UIScreen.mainScreen().bounds.size.height < 568.0 {
            self.levelView!.frame = CGRectMake(50, 60, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+34)
        }
        if UIScreen.mainScreen().bounds.size.height == 568.0 {
            self.levelView!.frame = CGRectMake(50, 98, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+11)
        }
        
        if UIScreen.mainScreen().bounds.size.height > 667.0 {
            self.levelView!.frame = CGRectMake(50, 175, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+14)
        }
    
        self.levelView!.layer.cornerRadius = 20
        self.scrollView!.addSubview(self.levelView!)
    
        if UIScreen.mainScreen().bounds.size.height > 667.0 {
            self.levelView!.currentLevelLabel.font = UIFont(name: "AvenirNext-Bold", size: 23)
        }
    
        self.levelView?.shareButton.addTarget(self, action: #selector(shareMedia), forControlEvents: UIControlEvents.TouchUpInside)
    
        let colorView = UIView()
        colorView.backgroundColor = UIColor.whiteColor()
        colorView.frame = CGRectMake(width!*CGFloat(i)+50, 156, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+10)
        if UIScreen.mainScreen().bounds.size.height < 568.0 {
            colorView.frame = CGRectMake(width!*CGFloat(i)+50, 60, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+34)
        }
        if UIScreen.mainScreen().bounds.size.height == 568.0 {
            colorView.frame = CGRectMake(width!*CGFloat(i)+50, 90, self.view.frame.size.width-100, self.scrollView!.frame.size.height/2+10)
        }
        colorView.layer.cornerRadius = 20
        colorView.alpha = 1.0
        //self.scrollView!.addSubview(colorView)
    
        let lockedLabel = UILabel()
        lockedLabel.frame = CGRectMake(0, 0, colorView.frame.size.width, colorView.frame.size.height)
        lockedLabel.text = "🔒🔒🔒"
        lockedLabel.textAlignment = NSTextAlignment.Center
        lockedLabel.textColor = UIColor.darkTextColor()
        lockedLabel.font = UIFont(name: "AvenirNext-Bold", size: 22)
        lockedLabel.alpha = 0.88
        colorView.addSubview(lockedLabel)
        colorView.bringSubviewToFront(lockedLabel)
    
        let scrollViewScene = SCNScene()
        scrollViewScene.physicsWorld.contactDelegate = self
        
        
        let sceneScrollView = SCNView()
        sceneScrollView.delegate = self
        sceneScrollView.frame = CGRectMake(self.view.frame.size.width/2-95, 62, 190, 190)
        
        //sceneScrollView.allowsCameraControl = true
    
        if UIScreen.mainScreen().bounds.size.height < 568.0 {
            sceneScrollView.frame = CGRectMake(self.view.frame.size.width/2-80, -2, 160, 160)
            self.startButton.removeConstraints(self.startButton.constraints)
            self.startButton.hidden = true
            self.pageControl.removeConstraints(self.pageControl.constraints)
            
            iPhone4StartButton = UIButton()
            iPhone4StartButton?.frame = CGRectMake(self.view.frame.size.width/2-50, self.view.frame.size.height/2+82, 100, 100)
            iPhone4StartButton?.backgroundColor = UIColor(red:0.98, green:0.39, blue:0.37, alpha:1.0)
            iPhone4StartButton?.titleLabel?.font = UIFont(name: "AvenirNext-Heavy", size: 24.0)
            iPhone4StartButton?.setTitle("start", forState: UIControlState.Normal)
            iPhone4StartButton!.layer.cornerRadius = (iPhone4StartButton?.frame.size.width)!/2
            iPhone4StartButton?.addTarget(self, action: #selector(startGame), forControlEvents: UIControlEvents.TouchUpInside)
            self.view.addSubview(iPhone4StartButton!)
            
        }
        if UIScreen.mainScreen().bounds.size.height == 568.0 {
             sceneScrollView.frame = CGRectMake(self.view.frame.size.width/2-90, 12, 180, 180)
        }
        
        if UIScreen.mainScreen().bounds.size.height > 667.0 {
            sceneScrollView.frame = CGRectMake(self.view.frame.size.width/2-95, 82, 190, 190)
        }
        
        sceneScrollView.backgroundColor = UIColor.clearColor()
        
        
        let tempCam = SCNNode()
        tempCam.camera = SCNCamera()
        tempCam.position = SCNVector3(x: 0.0, y:0.0, z:10)
        
        
        // Create light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 0, z: 10)
        scrollViewScene.rootNode.addChildNode(lightNode)
        
        // Create ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scrollViewScene.rootNode.addChildNode(ambientLightNode)
        
        // Make the camera move
        let camera_anim = CABasicAnimation(keyPath: "position.y")
        camera_anim.byValue = 0.0
        camera_anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        camera_anim.autoreverses = true
        camera_anim.repeatCount = Float.infinity
        camera_anim.duration = 10000.0
        
        tempCam.addAnimation(camera_anim, forKey: "camera_motion")
        scrollViewScene.rootNode.addChildNode(tempCam)
        
        let box = SCNSphere(radius: 2.50)
        let dasNode = SCNNode(geometry: box)
        dasNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scrollViewScene.rootNode.addChildNode(dasNode)
        
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(SCNVector4: SCNVector4(x: 0, y: 1, z: 1, w: 0))
        spin.toValue = NSValue(SCNVector4: SCNVector4(x: 0, y: 1, z: 1, w: Float(2 * M_PI)))
        spin.duration = 5.0
        spin.repeatCount = .infinity
        dasNode.addAnimation(spin, forKey: "spin around")
        
        
        let material = SCNMaterial()
        material.specular.contents = UIColor.redColor()
        material.diffuse.contents = UIColor.redColor()
        material.diffuse.contents = UIImage(named: "trump5")
        material.shininess = 1.0
        box.materials = [ material ]
        
        // Fire particle system
        let this = SCNParticleSystem(named: "FireParticles", inDirectory: nil)
        this!.emitterShape = box
        this!.emissionDurationVariation = 0.1
        this?.particleSize = 3.80
        dasNode.addParticleSystem(this!)
        
        // Make the ball bounce
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.byValue = 0.0001
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        animation.duration = 1.05
        
        dasNode.addAnimation(animation, forKey: "bounce")
        
        sceneScrollView.scene = scrollViewScene
        self.scrollView!.addSubview(sceneScrollView)
        
//        self.bottomView = NSBundle.mainBundle().loadNibNamed("BottomView", owner: self, options: nil)[0] as? BottomView
//        self.bottomView?.frame = CGRectMake(0, self.view.frame.size.height-50, self.view.frame.size.width, 50)
//        self.view.addSubview(self.bottomView!)
//        self.view.bringSubviewToFront(self.bottomView!)
        
       
        if UIScreen.mainScreen().bounds.size.height < 568.0 {
            
        } else {
            
            liveLeaderBoardButton = UIButton()
            liveLeaderBoardButton!.frame = CGRectMake(0, self.view.frame.size.height-84, self.view.frame.size.width, 40)
            liveLeaderBoardButton!.setTitle("high scores", forState: UIControlState.Normal)
            liveLeaderBoardButton!.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 16.0)
//            liveLeaderBoardButton!.setTitleColor(UIColor(red:0.98, green:0.39, blue:0.37, alpha:0.70), forState: UIControlState.Normal)
//            liveLeaderBoardButton!.setTitleColor(UIColor(red:0.98, green:0.39, blue:0.37, alpha:0.25), forState: UIControlState.Highlighted)
            
            liveLeaderBoardButton!.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.8), forState: UIControlState.Normal)
            liveLeaderBoardButton!.setTitleColor(UIColor.whiteColor().colorWithAlphaComponent(0.3), forState: UIControlState.Highlighted)
            
            liveLeaderBoardButton!.addTarget(self, action: #selector(showAlert), forControlEvents: UIControlEvents.TouchUpInside)
            liveLeaderBoardButton?.alpha = 0.8
            self.view.addSubview(liveLeaderBoardButton!)
            self.view.bringSubviewToFront(liveLeaderBoardButton!)
            
//            let tutButton = UIButton()
//            tutButton.frame = CGRectMake(self.view.frame.size.width-13, 5, 26, 26)
//            tutButton.addTarget(self, action: #selector(showTutorial), forControlEvents: UIControlEvents.TouchUpInside)
//            //tutButton.imageView?.image = UIImage(named: "tutButton")
//            tutButton.titleLabel?.text = "ttttt"
//            self.view.addSubview(tutButton)
//            self.view.bringSubviewToFront(tutButton)


        }
        
    }
    
    func showAlert() {
        
        let hasReviewedApp = NSUserDefaults.standardUserDefaults().objectForKey("hasReviewedApp")
        
        if hasReviewedApp != nil {
            self.showLiveLeaderBoard()
        } else {
            let alertController = UIAlertController(title: "🔒🔒🔒", message: "Leave us a review in the app store to unlock the worldwide leaderboard and to submit your best score!", preferredStyle:UIAlertControllerStyle.Alert)
            
            alertController.addAction(UIAlertAction(title: "Review", style: UIAlertActionStyle.Default)
            { action -> Void in
                // Put your code here
                self.appDelegate?.userLeftAppFromReviewButton = true
                UIApplication.sharedApplication().openURL(NSURL(string: "https://itunes.apple.com/us/app/blow-up-trump/id1154248528?ls=1&mt=8")!)
                
            })
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel)
            { action -> Void in
                // Put your code here
                })
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    
        
    }
    
    func showLiveLeaderBoard () {
        
        let username = NSUserDefaults.standardUserDefaults().objectForKey("username")
        if username == nil {
            self.showCreateUsernameAlert()
        } else {
            
            //self.getLeaderboardHighScores()
            self.showLeaderBoard()
        }
    }
    
    func showLeaderBoard () {
        
        if self.highScoreUsers?.count < 8 {
          return
        }
        
        //let username = NSUserDefaults.standardUserDefaults().objectForKey("username") as! String
        //let combinedString = "high scores | me: " + username
        
        self.picker = CZPickerView(headerTitle: "high scores", cancelButtonTitle: "cancel", confirmButtonTitle: "confirm")
        self.picker!.delegate = self
        self.picker!.dataSource = self
        self.picker!.show()

    }
    
    func getLeaderboardHighScores () {
            
        self.highScoreUsers = NSMutableArray()
        let query = PFQuery(className: "CustomUser")
        query.whereKeyExists("username")
        query.orderByDescending("userHighScore")
        query.limit = 8
        query.findObjectsInBackgroundWithBlock { (objects: [PFObject]?, error: NSError?) in
            if error == nil {
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) scores.")
                // Do something with the found objects
                if let objects = objects {
                    for object in objects {
                        let usernameString = object.objectForKey("username") as! String
                        let userHighScore = object.objectForKey("userHighScore") as! NSNumber
                        let stringTemp = String(userHighScore)
                        let combinedString = usernameString + " - " + stringTemp
                        self.highScoreUsers?.addObject(combinedString)
                        self.liveLeaderBoardButton?.enabled = true
                        
                        UIView.animateWithDuration(0.15, animations: {
                            //activityView.hidden = true
                            self.liveLeaderBoardButton?.alpha = 0.80
                        }) { (true) in
                            
                        }

                        
                    }
                } else {
                    self.liveLeaderBoardButton?.enabled = true
                    UIView.animateWithDuration(0.15, animations: {
                        //activityView.hidden = true
                        self.liveLeaderBoardButton?.alpha = 0.80
                    }) { (true) in
                    }
                    self.showUnknownError()
                    
                }
                //print(self.highScoreUsers)
                
                // CHANGEE
                //self.showLeaderBoard()
                
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
                UIView.animateWithDuration(0.15, animations: {
                    //activityView.hidden = true
                    self.liveLeaderBoardButton?.alpha = 0.80
                }) { (true) in
                }
                self.showUnknownError()
            }
        }
    }
    
    
    func showUnknownError () {
        
        let alertController = UIAlertController(title: "server error", message: "an unknown error occurred, please try again.", preferredStyle:UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Cancel)
        { action -> Void in
            // save user username to db
        })
        
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    func showCreateUsernameAlert () {
        
        let alertController = UIAlertController(title: "create username", message: "Create a username to show off your high score!", preferredStyle:UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: "save", style: UIAlertActionStyle.Default)
        { action -> Void in
            // save user username to db
            let usernameTextFieldString = alertController.textFields?.first?.text
            self.saveUsernameInParse(usernameTextFieldString!)
        })
        
        alertController.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
            textField.placeholder = "create username"

        }
        
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    func saveUsernameInParse (username: String) {
        
        let query = PFQuery(className: "CustomUser")
        query.whereKey("username", equalTo: username)
        query.getFirstObjectInBackgroundWithBlock {
            (object: PFObject?, error: NSError?) -> Void in
            
            if object != nil {
                // username already exists
                self.showError()
                return
            }
            if error != nil || object == nil {
                // username doesnt exists, create it
                
                if self.appDelegate?.currentUser == nil {
                    // SHOW ERROR
                    print("ERRORROROR!")
                    
                } else {
                    
                    self.appDelegate?.currentUser?.setObject(username, forKey: "username")
                    self.appDelegate?.currentUser?.saveInBackgroundWithBlock {
                        (success: Bool, error: NSError?) -> Void in
                        if (success) {
                            NSUserDefaults.standardUserDefaults().setObject(username, forKey: "username")
                            NSUserDefaults.standardUserDefaults().synchronize()
                            self.showLiveLeaderBoard()
                        }
                    }

                }                
            }
        }
    }
    
    func showError () {
        
        let alertController = UIAlertController(title: "error", message: "that username already exists.", preferredStyle:UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Cancel)
        { action -> Void in
            // save user username to db
            self.showCreateUsernameAlert()
        })
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    

    func numberOfRowsInPickerView(pickerView: CZPickerView) -> Int {
        return 8
    }
    
    func czpickerView(pickerView: CZPickerView, titleForRow row: Int) -> String {
        
        switch row {
        case 0:
            
            let combinedString = "🌟  " + ((self.highScoreUsers?.objectAtIndex(0))! as! String) + "  🌟"            
            return combinedString
            
        case 1:
            return (self.highScoreUsers?.objectAtIndex(1))! as! String
            
        case 2:
            return (self.highScoreUsers?.objectAtIndex(2))! as! String
            
        case 3:
            return (self.highScoreUsers?.objectAtIndex(3))! as! String
            
        case 4:
            return (self.highScoreUsers?.objectAtIndex(4))! as! String
            
        case 5:
            return (self.highScoreUsers?.objectAtIndex(5))! as! String

        case 6:
            return (self.highScoreUsers?.objectAtIndex(6))! as! String

        case 7:
            return (self.highScoreUsers?.objectAtIndex(7))! as! String

        case 8:
            return (self.highScoreUsers?.objectAtIndex(8))! as! String

        case 9:
            return (self.highScoreUsers?.objectAtIndex(9))! as! String
            
        case 10:
            return (self.highScoreUsers?.objectAtIndex(10))! as! String
        
        default:
            return "null"
        }
    }
    
    func shareMedia () {
        
        //Create the UIImage
        UIGraphicsBeginImageContextWithOptions(self.levelView!.frame.size, self.view.opaque, 0.0)
        view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //Save it to the camera roll
        //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let message = "Bet you can't beat my score on Blow Up Trump: bit.ly/blowuptrump"
        let activityViewController = UIActivityViewController(activityItems: [message, image], applicationActivities: nil)
        activityViewController.view.layer.speed = 2
        self.presentViewController(activityViewController, animated: true, completion: { () -> Void in
        })
    }

    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        let pageWidth: CGFloat = scrollView.frame.size.width
        let page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        self.pageControl.currentPage = Int(page)

    }
    
    func createCamera () {
        
        // Create camera
        self.cameraNode = SCNNode()
        self.cameraNode!.camera = SCNCamera()
        self.cameraNode!.position = SCNVector3(x: 0.0, y:0.0, z:15)
        
        // Create light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene!.rootNode.addChildNode(lightNode)
        
        // Create ambient light
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene!.rootNode.addChildNode(ambientLightNode)
        
        // Make the camera move
        let camera_anim = CABasicAnimation(keyPath: "position.y")
        camera_anim.byValue = 0.0
        camera_anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        camera_anim.autoreverses = true
        camera_anim.repeatCount = Float.infinity
        camera_anim.duration = 10000.0
        
        self.cameraNode!.addAnimation(camera_anim, forKey: "camera_motion")
        scene!.rootNode.addChildNode(self.cameraNode!)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        //self.setupCameraBackground()
        
        if appRunning == true {
            return
        } else {
        
            let blueView = UIView()
            blueView.frame = self.view.frame
            //blueView.backgroundColor = UIColor(red:0.4, green:0.65, blue:0.88, alpha:1.0)
            //blueView.backgroundColor = UIColor(red:1.0, green:0.35, blue:0.33, alpha:1.0)
            blueView.backgroundColor = UIColor(red:0.97, green:0.98, blue:0.28, alpha:1.0)
            self.view.addSubview(blueView)
            
            UIView.animateWithDuration(0.15, delay: 0.7, options: UIViewAnimationOptions.TransitionNone, animations: {
                blueView.alpha = 0.0
            }) { (true) in
            }
        }
    }
    
    func setupCameraBackground () {
        captureSession = AVCaptureSession()
        //captureSession?.sessionPreset = AVCaptureSessionPresetPhoto
        //let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
        }
        
        if error == nil && captureSession!.canAddInput(input) {
            captureSession!.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession!.canAddOutput(stillImageOutput) {
                captureSession!.addOutput(stillImageOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                previewLayer!.frame = self.view.frame
                self.view.layer.addSublayer(previewLayer!)
                captureSession!.startRunning()
            }
        }
    }

    
    func setupLabelsAndButtons () {
        
        self.scoreLabel = UILabel()
        self.scoreLabel?.frame = CGRectMake(0,self.view.frame.size.height/2-150, self.view.frame.size.width, 100)
        self.scoreLabel?.textColor = UIColor.whiteColor()
        self.scoreLabel?.textAlignment = NSTextAlignment.Center
        self.scoreLabel?.font = UIFont(name: "AvenirNext-Heavy", size: 64.0)
        self.scoreLabel?.text = "0"
        self.scoreLabel?.alpha = 0.88
        self.view.addSubview(self.scoreLabel!)
        self.view.bringSubviewToFront(self.scoreLabel!)
        
        self.startButton.layer.cornerRadius = self.startButton.frame.size.width / 2
        self.startButton.addTarget(self, action: #selector(growButton), forControlEvents: UIControlEvents.TouchDown)
        self.startButton.addTarget(self, action: #selector(shrinkButton), forControlEvents: UIControlEvents.TouchDragExit)
        self.startButton.addTarget(self, action: #selector(startGame), forControlEvents: UIControlEvents.TouchUpInside)
        //self.startButton.backgroundColor = UIColor(red:0.4, green:0.65, blue:0.88, alpha:1.0)
        self.startButton.backgroundColor = UIColor(red:0.98, green:0.39, blue:0.37, alpha:1.0)
        self.view.bringSubviewToFront(self.startButton)
        
        let highScore = NSUserDefaults.standardUserDefaults().objectForKey("highScore")
        NSUserDefaults.standardUserDefaults().setObject(highScore, forKey: "highScore")
        
        self.highScoreLabel = UILabel()
        self.highScoreLabel?.frame = CGRectMake(0,56, self.view.frame.size.width, 40)
        self.highScoreLabel?.textColor = UIColor.whiteColor()
        self.highScoreLabel?.textAlignment = NSTextAlignment.Center
        self.highScoreLabel?.font = UIFont(name: "AvenirNext-Heavy", size: 22.0)
        
        //self.highScoreLabel?.text = "🌟 high score: \(highScore!) 🌟"
        dispatch_async(dispatch_get_main_queue()) {
            self.levelView!.bestScoreLabel.text = "\(highScore!)"
            self.levelView!.newScoreLabel.text = "\(self.scoreLabel!.text!)"
        }
        self.highScoreLabel?.alpha = 0.88
        self.view.addSubview(self.highScoreLabel!)
        self.highScoreLabel?.hidden = true
        
        self.pageControl.numberOfPages = 1
        self.view.bringSubviewToFront(self.pageControl)
        
        //self.view.bringSubviewToFront(self.customLevelView)
        
    }

    func shrinkButton () {
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
            self.startButton.transform = CGAffineTransformMakeScale(1.0, 1.0)
        }) { (true) in
        }
    }
    
    func growButton () {
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
            self.startButton.transform = CGAffineTransformMakeScale(1.12, 1.12)
        }) { (true) in
        }
    }
    
    func startGame () {
        
        self.hideMenu()
        self.removeAllNodes()
        self.sceneSetup()
        self.initialAttitude = nil
        self.scoreLabel?.alpha = 0.880
        self.pageControl.alpha = 0.0
        self.scoreLabel?.text = "0"
        tapCount = 0
        
        trumpScene = SCNScene(named: "art.scnassets/TrumpBallFinal.scn")!
        self.startGameTimer()
        
        appRunning = true
        gameCount = gameCount! + 1
        gameIsPlaying = true
        gameEnding = false;

    
    }
    
    func startGameTimer () {
    
        let seconds = 0.01
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            // here code perfomed with delay
            self.nodeTimer = NSTimer.scheduledTimerWithTimeInterval(0.55, target: self, selector: #selector(ViewController.createBall), userInfo: nil, repeats: true)
        })

        
    }
    
    func endGame () {
        
        if (gameCount < 2) {
            
        } else {
            
            let rando = arc4random_uniform(4) + 1;
            if rando % 2 == 0 {
                let timeSeconds = 0.50
                let theDelay = timeSeconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
                let totalDispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(theDelay))
                
                dispatch_after(totalDispatchTime, dispatch_get_main_queue(), {
                    if self.popup.isReady {
                        self.popup.presentFromRootViewController(self)
                    } else {
                        print("Ad wasn't ready")
                    }
                })
            }
        }
    
        self.startButton.enabled = false
        self.liveLeaderBoardButton?.enabled = false
        gameIsPlaying = false
        dispatch_async(dispatch_get_main_queue()) {
            UIView.animateWithDuration(0.14, animations: {
                self.topArrow?.alpha = 0.0
                self.bottomArrow?.alpha = 0.0
                self.rightArrow?.alpha = 0.0
                self.leftArrow?.alpha = 0.0
            })
        }
        
        let url = NSBundle.mainBundle().URLForResource("bomb", withExtension: "mp3")!
        
        do {
            player = try AVAudioPlayer(contentsOfURL: url)
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSessionCategoryAmbient, withOptions: .DuckOthers)
            } catch {
                print("AVAudioSession cannot be set")
            }
            
            guard let player = player else { return }
            
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
        } catch let error as NSError {
            print(error.description)
        }
        
        if gameEnding == true {
            return
        }
        
        let highScore = NSUserDefaults.standardUserDefaults().objectForKey("highScore") as! Int
        let currentScore : Int? = Int(self.scoreLabel!.text!)
        
        if currentScore > highScore {
            NSUserDefaults.standardUserDefaults().setObject(currentScore!, forKey: "highScore")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            if self.appDelegate?.currentUser == nil {
                // SHOW ERROR
                print("ERRORROROR!")
            } else {
                
                self.appDelegate?.currentUser?.setObject(highScore, forKey: "userHighScore")
                self.appDelegate?.currentUser?.saveInBackgroundWithBlock {
                    (success: Bool, error: NSError?) -> Void in
                    print("saved")
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.levelView!.bestScoreLabel.text = "\(currentScore!)"
                self.levelView!.newScoreLabel.text = "\(self.scoreLabel!.text!)"
                
            }
        } else {
            dispatch_async(dispatch_get_main_queue()) {
                self.levelView!.newScoreLabel.text = "\(self.scoreLabel!.text!)"
            }
        }
        
        self.showMenu()
        
        fire?.particleSize = 5
        fire?.emissionDuration = 2
        boingBallNode!.runAction(SCNAction.scaleBy(2.0, duration: 0.15))
        
        gameEnding = true;
        
        let seconds = 0.750
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        trumpScene = nil
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
           self.removeAllNodes()
            self.startButton.enabled = true
            self.liveLeaderBoardButton?.enabled = true
        })
    
        nodeTimer?.invalidate()
        gameEnding = true;
    
    }
    
    func removeAllNodes () {
        
        //scene?.removeAllParticleSystems()
        scene!.rootNode.enumerateChildNodesUsingBlock { (node, stop) -> Void in
            node.removeAllParticleSystems()
            node.removeAllAnimations()
            node.removeFromParentNode()
            self.boingBallNode = nil
            self.pumpkin = nil
            
        }
    }
    
    func createBall () {
        
        var ballCount = 1;
        
        if tapCount > 3 {
            ballCount = 2
        }
        
        
        for i in 1...ballCount {
            
            i
            let lowerx  = -8
            let upperx  = 8
            let randomx = Int(arc4random_uniform(UInt32(upperx - lowerx + 1))) +   lowerx
            
            let lowery  = -60
            let uppery  = 60
            let randomy = Int(arc4random_uniform(UInt32(uppery - lowery + 1))) +   lowery
            
            // Create Ball
            let ball = SCNSphere(radius: 2.0)
            pumpkin = trumpScene?.rootNode.childNodeWithName("Sphere", recursively: false)!
            boingBallNode = pumpkin!.copy() as? SCNNode
            //boingBallNode = SCNNode(geometry: ball)
            pumpkin = nil
            
            // Fire particle system
            fire = SCNParticleSystem(named: "FireParticles", inDirectory: nil)
            fire!.emitterShape = ball
            fire!.emissionDurationVariation = 0.1
            fire?.particleSize = 5
            boingBallNode!.addParticleSystem(fire!)
            
            let spin = CABasicAnimation(keyPath: "rotation")
            spin.fromValue = NSValue(SCNVector4: SCNVector4(x: 0, y: 1, z: 0, w: 0))
            spin.toValue = NSValue(SCNVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(2 * M_PI)))
            spin.duration = 4
            spin.repeatCount = .infinity
            boingBallNode!.addAnimation(spin, forKey: "spin around")
            
            let biggerBall = SCNSphere(radius: 3.50)
            let dasNode = SCNNode(geometry: biggerBall)
            
            let material2 = SCNMaterial()
            material2.specular.contents = UIColor.clearColor()
            material2.diffuse.contents = UIColor.clearColor()
            material2.shininess = 1.0
            biggerBall.materials = [ material2 ]
            
            let newNode = boingBallNode!.copy() as! SCNNode;
            dasNode.position = SCNVector3(x: Float(randomx), y: Float(randomy), z: -120)
            dasNode.addChildNode(newNode)
            scene!.rootNode.addChildNode(dasNode)
            
            let lowerp  = -3
            let upperp  = 3
            let randomp = Int(arc4random_uniform(UInt32(upperp - lowerp + 1))) +   lowerp
            
            let position = SCNVector3(x: 0, y:Float(randomp), z:13)
            let action = SCNAction.moveTo(position, duration: 4)
            dasNode.runAction(action,completionHandler:{
                self.endGame()
            })
            
            let animation2 = CABasicAnimation(keyPath: "position.y")
            animation2.toValue = cameraNode?.eulerAngles.y
            animation2.delegate = self
            animation2.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
            animation2.autoreverses = false
            animation2.repeatCount = 0
            animation2.duration = 5.0
            dasNode.addAnimation(animation2, forKey: "fly2")
            
        }
    }
    
    func handleTap(sender: UITapGestureRecognizer? = nil) {

        let location: CGPoint = (sender?.locationInView(self.scnView!))!
        let hits = self.scnView!.hitTest(location, options: nil)
        
        if hits.count > 0 {
            
            if gameEnding == true {
                return
            }
            
            self.incrementScore()
            let result = hits[0]
            let tappedNode = result.node
            
            // Tap Animation
            tappedNode.runAction(SCNAction.sequence([
                SCNAction.scaleTo(1.76, duration: 0.05)]))
            
            let seconds = 0.06
            let delay = seconds * Double(NSEC_PER_SEC)
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            
            dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                self.removeNodeFromParent(tappedNode)
            })
        }
    }
    
    func incrementScore () {
        tapCount = tapCount! + 1
        let str = "\(tapCount!)"
        self.scoreLabel?.text = str
        
        if gameEnding == true {
            return
        }
        
        UIView.animateWithDuration(0.1, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
            self.scoreLabel?.transform = CGAffineTransformMakeScale(1.2, 1.2)
            self.scoreLabel?.alpha = 0.88
        }) { (true) in
            
            UIView.animateWithDuration(0.08, delay: 0.0, options: UIViewAnimationOptions.TransitionNone, animations: {
                self.scoreLabel?.transform = CGAffineTransformMakeScale(1.0, 1.0)
                self.scoreLabel?.alpha = 0.78
            }) { (true) in
            }
        }
    }

    
    func removeNodeFromParent (node: SCNNode) {
        
        let url = NSBundle.mainBundle().URLForResource("bomb2", withExtension: "mp3")!
        
        do {
            player = try AVAudioPlayer(contentsOfURL: url)
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(AVAudioSessionCategoryAmbient, withOptions: .DuckOthers)
            } catch {
                print("AVAudioSession cannot be set")
            }
            guard let player = player else { return }
            
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
        } catch let error as NSError {
            print(error.description)
        }
        
        
        node.removeFromParentNode()
    }
    
    func sceneSetup() {
        if (motionManager == nil) {
            motionManager = CMMotionManager()
        }
        
        if (motionManager?.deviceMotionAvailable != nil) {
            motionManager?.deviceMotionUpdateInterval = 1.0/60.0;
            motionManager?.startDeviceMotionUpdatesToQueue(NSOperationQueue(), withHandler: {
                [weak self] (data:CMDeviceMotion?, error:NSError?) -> Void in
                if self!.initialAttitude == nil {
                    
                    // Capture the initial position
                    self!.initialAttitude = data!.attitude
                    
                    return
                }
                
                // make the new position value to be comparative to initial one
                data!.attitude.multiplyByInverseOfAttitude(self!.initialAttitude!)
                
                let xRotationDelta: Float = (Float)((data?.attitude.pitch)!)
                let yRotationDelta: Float = (Float)((data?.attitude.roll)!)
                let zRotationDelta: Float = (Float)((data?.attitude.yaw)!)
                
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    self?.rotateCamera(-yRotationDelta, y: xRotationDelta, z: zRotationDelta)
                })
            })
        }
    }
    
    func rotateCamera(x: Float, y: Float, z: Float) {
        self.cameraNode?.eulerAngles.x = y
        self.cameraNode?.eulerAngles.y = -x
        self.cameraNode?.eulerAngles.z = z
        
        if (gameIsPlaying == true) {
            
            if cameraNode?.eulerAngles.y > 0.23 {
                self.view.bringSubviewToFront(rightArrow!)
                UIView.animateWithDuration(0.14, animations: {
                    self.rightArrow?.alpha = 1.0
                })
                
            } else if cameraNode?.eulerAngles.y < -0.23 {
                self.view.bringSubviewToFront(leftArrow!)
                UIView.animateWithDuration(0.14, animations: {
                    self.leftArrow?.alpha = 1.0
                })
            }
            
            if cameraNode?.eulerAngles.x > 0.2 {
                self.view.bringSubviewToFront(bottomArrow!)
                UIView.animateWithDuration(0.14, animations: {
                    self.bottomArrow?.alpha = 1.0
                })
            } else if cameraNode?.eulerAngles.x < -0.2 {
                self.view.bringSubviewToFront(topArrow!)
                UIView.animateWithDuration(0.14, animations: {
                    self.topArrow?.alpha = 1.0
                })
                
            } else {
                UIView.animateWithDuration(0.14, animations: {
                    self.topArrow?.alpha = 0.0
                    self.bottomArrow?.alpha = 0.0
                    self.rightArrow?.alpha = 0.0
                    self.leftArrow?.alpha = 0.0
                })
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
//        let layer = self.cameraEngine.previewLayer
//        layer.frame = self.view.bounds
//        self.view.layer.insertSublayer(layer, atIndex: 0)
//        self.view.layer.masksToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

