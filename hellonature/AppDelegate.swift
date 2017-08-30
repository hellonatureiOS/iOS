//
//  AppDelegate.beta.swift
//  hellonature
//  Created by HelloNature on 2017. 8. 30..
//
//


import UserNotifications
import SwiftyJSON
import Firebase
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate
{
    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        debugPrint("##############################> @1 AppDelegate DidFinishLaunchingWithOptions")
//        debugPrint("##############################> 1 Firebase Token = \(String(describing: InstanceID.instanceID().token()))")
        self.initializeFCM(application)
        return true
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData)
    {
        debugPrint("##############################> @2 didRegisterForRemoteNotificationsWithDeviceToken: NSDATA")
        
        let token = String(format: "%@", deviceToken as CVarArg)
        Messaging.messaging().apnsToken = deviceToken as Data
        debugPrint("##############################> @3 deviceToken: \(token)")
        debugPrint("##############################> Firebase Token:",InstanceID.instanceID().token() as Any)
    }
    
    // 디바이스토큰 등록완료 후 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        debugPrint("##############################> @4 didRegisterForRemoteNotificationsWithDeviceToken: DATA")
        let token = String(format: "%@", deviceToken as CVarArg)
        Messaging.messaging().apnsToken = deviceToken
        debugPrint("##############################> deviceToken: \(token)")
        debugPrint("Firebase Token:",InstanceID.instanceID().token() as Any)
    }
    
    // 알림 등록성공
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings)
    {
//        debugPrint("##############################> @5 didRegister \(notificationSettings)")
        if (notificationSettings.types == .alert || notificationSettings.types == .badge || notificationSettings.types == .sound)
        {
            application.registerForRemoteNotifications()
        }
    }
    
    // 알림 등록실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        debugPrint("##############################> @6 didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }
    
    // 앱이 백그라운드에서 알림 메시지를받는 경우,
    // 이 콜백은 사용자가 응용 프로그램을 시작하는 알림을 누를 때까지 발생하지 않습니다.
    // TODO : 알림 데이터를 처리합니다.
    // 메시지 ID를 인쇄합니다.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("##############################> Message ID: \(messageID)")
        }
        
        debugPrint("##############################> @7 userInfo \(userInfo)")
    }
    
    
    func application(received remoteMessage: MessagingRemoteMessage)
    {
        debugPrint("##############################> @8 remoteMessage:\(remoteMessage.appData)")
    }
    
    // 앱 비활성화
    func applicationDidEnterBackground(_ application: UIApplication) {
        debugPrint("##############################> @9 AppDelegate DidEnterBackground")
    }
    
    // 앱 활성화
    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        debugPrint("##############################> @10 AppDelegate DidBecomeActive")
    }
    
    // FCM 초기화
    func initializeFCM(_ application: UIApplication)
    {
        print("##############################> @11 initializeFCM")
        // iOS 10에서 알림제어
        if #available(iOS 10.0, *)
        {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.badge, .alert , .sound]) { (accepted, error) in
                if !accepted
                {
                    //알림 거부 선택
                    print("##############################> @12 Notification access denied.")
                }
                else
                {
                    //알림 허용 선택
                    print("##############################> @13 Notification access accepted.")
                    UIApplication.shared.registerForRemoteNotifications();
                }
            }
        }
        else
        {
            let type: UIUserNotificationType = [UIUserNotificationType.badge, UIUserNotificationType.alert, UIUserNotificationType.sound];
            let setting = UIUserNotificationSettings(types: type, categories: nil);
            UIApplication.shared.registerUserNotificationSettings(setting);
            UIApplication.shared.registerForRemoteNotifications();
        }
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotificaiton), name: Notification.Name("NotificationIdentifier"), object: nil)
    }
    
    func tokenRefreshNotificaiton(_ notification: Foundation.Notification)
    {
        if let refreshedToken = InstanceID.instanceID().token()
        {
            debugPrint("##############################> @14 InstanceID token: \(refreshedToken)")
        }
    }

    ///이 메소드는 FCM이 새로운 FCM 토큰을받을 때마다 호출됩니다.
    ///이 토큰을 응용 프로그램 서버에 알림을 보낼 수 있습니다.
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String)
    {
        debugPrint("##############################> @15 messaging:\(messaging)")
        debugPrint("##############################> didRefreshRegistrationToken:\(fcmToken)")
    }
    
    @available(iOS 10.0, *)
    public func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage)
    {
        debugPrint("##############################> @16 messaging:\(messaging)")
        debugPrint("##############################> didReceive Remote Message:\(remoteMessage.appData)")
        guard let data =
            try? JSONSerialization.data(withJSONObject: remoteMessage.appData, options: .prettyPrinted),
            let prettyPrinted = String(data: data, encoding: .utf8) else { return }
        print("##############################> Received direct channel message:\n\(prettyPrinted)")
    }
    
    //앱이 활성화상태에서 알림 수신시 호출
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        //알림 처리
        debugPrint("##############################> @17 willPresent notification")
        debugPrint("##############################> notification: \(notification)")
    }
    
    //앱이 비활성화 상태 알림메세지 탭 동작시 호출
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        //알림 처리
        debugPrint("##############################> @18 didReceive response Notification ")
        debugPrint("##############################> response: \(response)")
    }
}


extension Notification.Name {
    static let yourCustomNotificationName = Notification.Name("yourCustomNotificationName")
}
