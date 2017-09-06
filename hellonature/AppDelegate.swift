//
//  AppDelegate.beta.swift
//  hellonature
//  Created by HelloNature on 2017. 8. 30..
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
        debugPrint("@1 AppDelegate DidFinishLaunchingWithOptions")
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        self.registerForPushNotifications()
        return true
    }



    /** 알림 등록성공 **/
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings)
    {
        debugPrint("@2 didRegister \(notificationSettings)")
        if (notificationSettings.types == .alert || notificationSettings.types == .badge || notificationSettings.types == .sound)
        {
            application.registerForRemoteNotifications()
        }
    }


    /**
    앱이 백그라운드에서 알림 메시지를받는 경우,
    이 콜백은 사용자가 응용 프로그램을 시작하는 알림을 누를 때까지 발생하지 않습니다.
    TODO : 알림 데이터를 처리합니다.
    메시지 ID를 인쇄합니다.
    **/
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        debugPrint("@3 userInfo: \(userInfo)")
        Messaging.messaging().appDidReceiveMessage(userInfo)
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("@3 Message ID: \(messageID)")
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("@4 userInfo: \(userInfo)")
            debugPrint("@4: \(messageID)")
            Messaging.messaging().appDidReceiveMessage(userInfo)
            completionHandler(UIBackgroundFetchResult.newData)
        }
    }

    /** 알림 등록실패 **/
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error){
        debugPrint("@5 didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }

    /** 디바이스토큰 등록완료 후 호출 **/
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        debugPrint("@6 didRegisterForRemoteNotificationsWithDeviceToken: DATA")
        let token = String(format: "%@", deviceToken as CVarArg)
        Messaging.messaging().apnsToken = deviceToken
        debugPrint("@6 deviceToken: \(token)")
        debugPrint("@6 Firebase Token:", InstanceID.instanceID().token() as Any)
    }


    func application(received remoteMessage: MessagingRemoteMessage)
    {
        debugPrint("@7 remoteMessage:\(remoteMessage.appData)")
    }

    /** 앱 비활성화 **/
    func applicationDidEnterBackground(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = false
        debugPrint("@8 AppDelegate DidEnterBackground")
    }

    /** 앱 활성화 **/
    func applicationDidBecomeActive(_ application: UIApplication) {
        Messaging.messaging().shouldEstablishDirectChannel = true

//        application.applicationIconBadgeNumber = 0
        debugPrint("@9 AppDelegate DidBecomeActive")
    }

    /** FCM 등록 **/
    func registerForPushNotifications()
    {
        debugPrint("@10 registerForPushNotifications")
        
        // iOS 10에서 알림제어
        if #available(iOS 10.0, *)
        {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert , .sound]) { (accepted, error) in
                if !accepted
                {
                    //알림 거부 선택
                    print("@11 Notification access denied.")
                }
                else
                {
                    //알림 허용 선택
                    print("@11 Notification access accepted.")
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
            debugPrint("@12 InstanceID token: \(refreshedToken)")
        }
    }
    /** 알림 데이터 전송 **/
    func postNotification(userInfo: [AnyHashable: Any]){
        debugPrint("@19 post Notification userInfo: \(userInfo)")
        NotificationCenter.default.post(name: Notification.Name("fcm_data"), object: nil, userInfo: userInfo)
    }

    /**
    FCM이 새로운 FCM 토큰을 받을 때마다 호출
    알림허용 주제를 설정
    이 토큰을 응용 프로그램 서버에 알림을 보낼 수 있습니다.
    **/
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String)
    {
        Messaging.messaging().subscribe(toTopic: self.topic)
        debugPrint("@13 messaging:\(messaging)")
        debugPrint("@13 didRefreshRegistrationToken:\(fcmToken)")
    }

    @available(iOS 10.0, *)
    public func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage)
    {
        debugPrint("@14 messaging:\(messaging)")
        debugPrint("@14 didReceive Remote Message:\(remoteMessage.appData)")
        guard let data =
            try? JSONSerialization.data(withJSONObject: remoteMessage.appData, options: .prettyPrinted),
            let prettyPrinted = String(data: data, encoding: .utf8) else { return }
        debugPrint("@14 Received direct channel message:\n\(prettyPrinted)")
    }

    /** 앱이 활성화상태에서 알림 수신시 호출 **/
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        //알림 처리
        self.postNotification(userInfo: notification.request.content.userInfo);
        debugPrint("@15 notification: \(notification)")
        //수신완료
        completionHandler([.alert, .sound])
    }

    /** 알림 메세지 탭 동작시 호출 **/
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        //알림 처리
        self.postNotification(userInfo: response.notification.request.content.userInfo);
        debugPrint("@16 didReceive response Notification \(response) ")
        //수신완료
        completionHandler()
    }
}


extension Notification.Name {
    static let fcm_data = Notification.Name("fcm_data")
}


extension MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        debugPrint("@17 Firebase registration token: \(fcmToken)")
    }
    // 앱이 포 그라운드 일 때 FCM (APN 무시)에서 직접 iOS 10 이상의 데이터 메시지를받습니다.
    // 직접적인 데이터 메시지를 활성화하려면 Messaging.messaging (). shouldEstablishDirectChannel을 true로 설정합니다.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("@18 Received data message: \(remoteMessage.appData)")
    }
}
