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
    let topic = "/topics/test"


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        debugPrint("##############################> @1 AppDelegate DidFinishLaunchingWithOptions")
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        self.registerForPushNotifications()
        return true
    }



    // 알림 등록성공
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings)
    {
        debugPrint("##############################> @5 didRegister \(notificationSettings)")
        if (notificationSettings.types == .alert || notificationSettings.types == .badge || notificationSettings.types == .sound)
        {
            application.registerForRemoteNotifications()
        }
    }


    // 앱이 백그라운드에서 알림 메시지를받는 경우,
    // 이 콜백은 사용자가 응용 프로그램을 시작하는 알림을 누를 때까지 발생하지 않습니다.
    // TODO : 알림 데이터를 처리합니다.
    // 메시지 ID를 인쇄합니다.
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        debugPrint("##############################> @7-1 userInfo: \(userInfo)")
        Messaging.messaging().appDidReceiveMessage(userInfo)
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("##############################> Message ID: \(messageID)")
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("##############################> @7-2 userInfo: \(userInfo)")
            debugPrint("##############################> @7-2 messageID: \(messageID)")
            Messaging.messaging().appDidReceiveMessage(userInfo)
            completionHandler(UIBackgroundFetchResult.newData)
        }
    }

    // 알림 등록실패
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error){
        debugPrint("##############################> @7-3 didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }

    // 디바이스토큰 등록완료 후 호출
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        debugPrint("##############################> @7-4 didRegisterForRemoteNotificationsWithDeviceToken: DATA")
        let token = String(format: "%@", deviceToken as CVarArg)
        Messaging.messaging().apnsToken = deviceToken
        debugPrint("##############################> deviceToken: \(token)")
        debugPrint("Firebase Token:",InstanceID.instanceID().token() as Any)
    }


    func application(received remoteMessage: MessagingRemoteMessage)
    {
        debugPrint("##############################> @8 remoteMessage:\(remoteMessage.appData)")
    }

    // 앱 비활성화
    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = false
        debugPrint("##############################> @9 AppDelegate DidEnterBackground")
    }

    // 앱 활성화
    func applicationDidBecomeActive(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = true

//        application.applicationIconBadgeNumber = 0
        debugPrint("##############################> @10 AppDelegate DidBecomeActive")
    }

    // FCM 초기화
    func registerForPushNotifications()
    {
        print("##############################> @11 registerForPushNotifications")
        // iOS 10에서 알림제어
        if #available(iOS 10.0, *)
        {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert , .sound]) { (accepted, error) in
                if !accepted
                {
                    //알림 거부 선택
                    print("##############################> @12 Notification access denied.")
                }
                else
                {
                    //알림 허용 선택
                    print("##############################> @13 Notification access accepted.")
                }
            }
        }
        else
        {
            let type: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.sound];
            let setting = UIUserNotificationSettings(types: type, categories: nil);
            UIApplication.shared.registerUserNotificationSettings(setting);
        }

        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        UIApplication.shared.registerForRemoteNotifications();
//        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotificaiton), name: Notification.Name("NotificationIdentifier"), object: nil)
    }

    func tokenRefreshNotificaiton(_ notification: Foundation.Notification)
    {
        if let refreshedToken = InstanceID.instanceID().token()
        {
            debugPrint("##############################> @14 InstanceID token: \(refreshedToken)")
        }
    }

    // FCM이 새로운 FCM 토큰을 받을 때마다 호출
    // 알림허용 주제를 설정
    ///이 토큰을 응용 프로그램 서버에 알림을 보낼 수 있습니다.
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String)
    {
        Messaging.messaging().subscribe(toTopic: self.topic)
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
        let userInfo = notification.request.content.userInfo
        //알림 처리
        debugPrint("##############################> @17 willPresent notification")
        debugPrint("##############################> @17 notification: \(notification)")
        debugPrint("##############################> @17 userInfo: \(userInfo)")
        //수신완료
        completionHandler([.alert, .sound])
    }

    //앱이 비활성화 상태 알림메세지 탭 동작시 호출
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        let userInfo = response.notification.request.content.userInfo
        //알림 처리
        debugPrint("##############################> @18 didReceive response Notification ")
        debugPrint("##############################> @18 response: \(response)")
        debugPrint("##############################> @18 userInfo: \(userInfo)")
        //수신완료
        completionHandler()
    }
}


extension Notification.Name {
    static let yourCustomNotificationName = Notification.Name("yourCustomNotificationName")
}


extension MessagingDelegate {
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
