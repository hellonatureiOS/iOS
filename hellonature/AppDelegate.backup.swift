//
//  AppDelegate.swift
//  hellonature
//
import UIKit
import UserNotifications
import SwiftyJSON
import Firebase
import FirebaseInstanceID
import FirebaseMessaging


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
  
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIApplication.shared.delegate!.window!
        FirebaseApp.configure()
        registFCM(application)
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("========================> didReceiveRemoteNotification")
        if let messageID = userInfo[gcmMessageIDKey] {
            print("========================> didReceiveRemoteNotification messageID: \(messageID)")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("========================> didReceiveRemoteNotification with completionHandler")
        if let messageID = userInfo[gcmMessageIDKey] {
            print("========================> didReceiveRemoteNotification width completionHandler messageID: \(messageID)")
        }
        
        // 앱이 비활성화 되었을때 푸시 메시지 데이터 체크
        if(UIApplication.shared.applicationState != UIApplicationState.active){
            postPushedData(userInfo)
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func registFCM(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            print("========================> registFCM with iso 10.0+")
            let authOptions: UNAuthorizationOptions = [.alert, .sound]
            UNUserNotificationCenter.current().requestAuthorization(options: authOptions,completionHandler: {_, _ in })
            UNUserNotificationCenter.current().delegate = self
            Messaging.messaging().delegate = self
        }
        else{
            print("========================> registFCM with iso")
            let type: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.sound];
            let setting = UIUserNotificationSettings(types: type, categories: nil);
            UIApplication.shared.registerUserNotificationSettings(setting);
            UIApplication.shared.applicationIconBadgeNumber = 0
            UIApplication.shared.registerForRemoteNotifications();
        }
        application.registerForRemoteNotifications()
//        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: .firInstanceIDTokenRefresh, object: nil)
    
    }
 
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = InstanceID.instanceID().token() {
            Messaging.messaging().subscribe(toTopic: "test")
            registServer(refreshedToken)
            print("========================> refreshed id token: \(refreshedToken)")
        }
        
        connectToFcm()
    }
    
    func registServer(_ token:String){
        print("###################### ================>\(token)")
    }

    func connectToFcm() {
        guard InstanceID.instanceID().token() != nil else {
            return;
        }
        
        Messaging.messaging().shouldEstablishDirectChannel = false
        Messaging.messaging().connect { (error) in
            if error != nil {
                print("========================> Unable to connect with FCM. \(error)")
            } else {
                print("========================> Connected to FCM")
            }
        }
    }
  
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        print("========================> didRegisterForRemoteNotificationsWithDeviceToken token as NSData: \(deviceToken as NSData)")
        print("========================> didRegisterForRemoteNotificationsWithDeviceToken deviceTokenString: \(deviceTokenString)")
        InstanceID.instanceID().setAPNSToken(deviceToken, type: InstanceIDAPNSTokenType.prod)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        connectToFcm()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().disconnect()
        print("========================> Disconnected from FCM")
    }
    
    func postPushedData(_ data: [AnyHashable : Any]){
        let aps = JSON(data)
        if(aps != JSON.null){
            NotificationCenter.default.post(name: Notification.Name(rawValue: "aps"), object: aps)
        }
    }
}


@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // 앱이 활성화 되지 않았을때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->Void) {
        let userInfo = notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print("========================> userNotificationCenter inactive userInfo: \(userInfo)")
        completionHandler(UNNotificationPresentationOptions.alert)
        //completionHandler([])
    }
    
    //앱이 활성화 되었을때
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print("========================> userNotificationCenter active userInfo: \(userInfo)")
        postPushedData(userInfo)
        completionHandler()
    }
}


extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    // [END refresh_token]
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}


/*
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        FIRApp.configure()
        NotificationCenter.default.addObserver(self, selector: #selector(tokenRefreshNotification(_:)), name: NSNotification.Name.firInstanceIDTokenRefresh , object: nil)
        
        // iOS 10 support
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){
                (granted, error) in
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            application.registerForRemoteNotifications()
        }
        //iOS 8 ~ 9 support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
        //iOS 7 support
        else {
            application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        }
        
        
        if let savedPush = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary {
            UserDefaults.standard.set(savedPush as! [AnyHashable: Any], forKey: "savedPush")
            UserDefaults.standard.synchronize()
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        // Print APNS Tester console
        print("APNs device token: \(deviceToken as NSData)")
        // Print it to console
        print("APNs device token: \(deviceTokenString)")
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
    }
    
  
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }
    
    //func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        // Let FCM know about the message for analytics etc.
        //FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        // handle your message
    //}
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void ) {
        print("APNs received notification =====================>");
        let notification = JSON(userInfo)
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        // 알림이 있으면 실행
        if notification != JSON.null{
            switch UIApplication.shared.applicationState {
            case UIApplicationState.active:
                print("application state ---------> foreground")
            case UIApplicationState.inactive, UIApplicationState.background:
                NotificationCenter.default.post(name: Notification.Name(rawValue: "pushReceived"), object: notification)
                print("application state ---------> inactive or background")
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        FIRMessaging.messaging().disconnect()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("refreshed token: \(refreshedToken)")
        }
        connectToFcm()
    }

    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
}
 
 */

