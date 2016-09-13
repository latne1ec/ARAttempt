//
//  AppDelegate.swift
//  ARAttempt
//
//  Created by Evan Latner on 9/1/16.
//  Copyright © 2016 levellabs. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var currentUser : PFObject?
    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //FIRApp.configure()
        
//        let rootRef = FIRDatabase.database().reference()
//        let userRef = rootRef.child("users")
//        FIRAuth.auth()?.signInAnonymouslyWithCompletion() { (user, error) in
//            // ...
//            if error != nil {
//                print(error?.description)
//            } else {
//                print(user)
//                
//                let theUser = FIRAuth.auth()?.currentUser
//            }
//        }
        
        
        Parse.setApplicationId("eMPiSiaCNRha0BAqkO88fGepRXaXFNASuaLo43Lj", clientKey: "gg9pkVb3VV3AKilnLkr4yswrLn5h6MIdzDpDNsHF")
        
        var highScore = NSUserDefaults.standardUserDefaults().objectForKey("highScore")
        if highScore == nil {
            highScore = 0
            NSUserDefaults.standardUserDefaults().setObject(highScore, forKey: "highScore")
        }

        let userObjectId = NSUserDefaults.standardUserDefaults().objectForKey("userObjectId")
        
        if userObjectId != nil {
            // already have user, incremnt score etc.
            let query = PFQuery(className: "CustomUser")
            query.whereKey("objectId", equalTo: userObjectId!)
            query.getFirstObjectInBackgroundWithBlock {
                (object: PFObject?, error: NSError?) -> Void in
                if error != nil || object == nil {
                    print("The getFirstObject request failed.")
                } else {
                    // The find succeeded.
                    print("Successfully retrieved the object.")
                    self.currentUser = object
                    self.currentUser?.incrementKey("runCount")
                    self.currentUser?.setObject(highScore!, forKey: "userHighScore")
                    self.currentUser?.saveInBackground()
                }
            }
            
        } else {
            
            // Create user
            
            let newUser = PFObject(className: "CustomUser")
            newUser.setObject(0, forKey: "userHighScore")
            newUser.incrementKey("runCount")
            newUser.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    self.currentUser = newUser;
                    NSUserDefaults.standardUserDefaults().setObject(newUser.objectId, forKey: "userObjectId")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    PFInstallation.currentInstallation()?.setObject(newUser, forKey: "customUser")
                    PFInstallation.currentInstallation()?.saveInBackground()
                    
                } else {
                }
            }
        }
    
        
//        PFAnonymousUtils.logInWithBlock {
//            (user: PFUser?, error: NSError?) -> Void in
//            if error != nil || user == nil {
//                print("Anonymous login failed.")
//            } else {
//                print("Anonymous user logged in.")
//                user?.setObject(highScore!, forKey: "highScore")
//                user?.incrementKey("runCount")
//                user?.saveEventually()
//                PFInstallation.currentInstallation()?.setObject(PFUser.currentUser()!, forKey: "user")
//                PFInstallation.currentInstallation()?.saveInBackground()
//            }
//        }
        
        Chartboost.startWithAppId("57d5db9e04b01621d63b6c7c", appSignature: "422a784fa68d90bf333faaf9704fb06a758c093b", delegate: nil)
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

