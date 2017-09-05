import UIKit
import Foundation

import Firebase
import FirebaseInstanceID
import FirebaseMessaging

import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    let topic = "/topics/test"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //adapt the storyboard if the device is an iPad or a iPhone
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)//self.adaptStoryboard()
        self.window?.rootViewController = storyboard.instantiateInitialViewController()
        self.window?.makeKeyAndVisible()
        
        // MARK: Init Notification
        registerForPushNotifications(application: application)
        
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: Notification.Name("NotificationIdentifier"),
                                               object: nil)
        
        if let token = InstanceID.instanceID().token() {
            print("TOKEN....")
            print(token)
            connectToFcm()
        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("Application: DidEnterBackground")
    }
    func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("Application: DidBecomeActive")
        connectToFcm()
    }
    func applicationWillTerminate(_ application: UIApplication) {
    }
}

extension AppDelegate {
    /**
     Register for push notification.
     
     Parameter application: Application instance.
     */
    func registerForPushNotifications(application: UIApplication) {
        print(#function)
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self as? MessagingDelegate
            print("Notification: registration for iOS >= 10 using UNUserNotificationCenter")
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            print("Notification: registration for iOS < 10 using Basic Notification Center")
        }
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
    }
    
    func tokenRefreshNotification(_ notification: Notification) {
        print(#function)
        if let refreshedToken = InstanceID.instanceID().token() {
            print("Notification: refresh token from FCM -> \(refreshedToken)")
        }
        
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    
    func connectToFcm() {
        // Won't connect since there is no token
        guard InstanceID.instanceID().token() != nil else {
            print("FCM: Token does not exist.")
            return
        }
        
        // Disconnect previous FCM connection if it exists.
        Messaging.messaging().disconnect()
        
        Messaging.messaging().connect { (error) in
            if error != nil {
                print("FCM: Unable to connect with FCM. \(error.debugDescription)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Notification: Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the InstanceID token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        var token = ""
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        print("Notification: APNs token: \((deviceToken as NSData))")
        print("Notification: APNs token retrieved: \(token)")
        // With swizzling disabled you must set the APNs token here.
        /*FIRInstanceID
         .instanceID()
         .setAPNSToken(deviceToken,
         type: FIRInstanceIDAPNSTokenType.sandbox)*/
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Notification: basic delegate")
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
//        analyse(notification: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Notification: basic delegate (background fetch)")
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
            
        }
        
//        analyse(notification: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Notification: iOS 10 delegate(willPresent notification)")
        let userInfo = notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
            print("userInfo\(userInfo)")
           
        }
        
//        analyse(notification: userInfo)
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("Notification: iOS 10 delegate(didReceive response)")
        
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
            print("userInfo\(userInfo)")
        }
        
        // Print full message.
//        analyse(notification: userInfo)
        completionHandler()
    }
    
    // FCM이 새로운 FCM 토큰을받을 때마다 호출
    // 알림허용 주제를 설정
    ///이 토큰을 응용 프로그램 서버에 알림을 보낼 수 있습니다.
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String)
    {
        Messaging.messaging().subscribe(toTopic: self.topic)
        debugPrint("##############################> @15 messaging:\(messaging)")
        debugPrint("##############################> didRefreshRegistrationToken:\(fcmToken)")
    }
}

extension MessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: MessagingRemoteMessage) {
        print("Notification: Firebase FCM delegate remote message.")
//        analyse(notification: remoteMessage.appData)
    }
}

extension Notification.Name {
    static let yourCustomNotificationName = Notification.Name("yourCustomNotificationName")
}

