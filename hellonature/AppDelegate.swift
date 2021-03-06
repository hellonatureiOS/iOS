//
//  AppDelegate.beta.swift
//  hellonature
//  Created by HelloNature on 2017. 8. 30..
//


import UserNotifications
import Firebase
import FirebaseMessaging
import FirebaseDynamicLinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate
{
    var window: UIWindow?
    var viewController: ViewController?
    var sharedData: [String : String] = [:]
    let gcmMessageIDKey = "gcm.message_id"
    private var splash : UIImageView!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        debugPrint("@1 AppDelegate DidFinishLaunchingWithOptions")
        print("===1")
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        self.registerForPushNotifications()
        self.window!.rootViewController?.view.backgroundColor = UIColor.white
        self.viewController = self.window?.rootViewController as? ViewController
        
        print("@forground")
        
        
        return true
    }
   
    
    
    
    /** 앱이 백그라운드에서 알림 메시지를받는 경우 **/
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("===2")
        Messaging.messaging().appDidReceiveMessage(userInfo)
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("@3 Message ID: \(messageID)")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("===3")
        if let messageID = userInfo[gcmMessageIDKey] {
            debugPrint("@4 Message ID: \(messageID)")
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
        print("===5")
       
        let token = String(format: "%@", deviceToken as CVarArg)
        Messaging.messaging().apnsToken = deviceToken
        debugPrint("@6 deviceToken: \(token)")
        
    }
    
    /** auto constraints fix **/
    func application(_ application: UIApplication, willChangeStatusBarFrame newStatusBarFrame: CGRect) {
        print("===6")
        
        let windows = UIApplication.shared.windows
        for window in windows {
            window.removeConstraints(window.constraints)
        }
    }
    
    
    func application(received remoteMessage: MessagingRemoteMessage)
    {
        print("===8")
        debugPrint("@7 remoteMessage:\(remoteMessage.appData)")
    }
    
    /** 앱 포그라운드 **/
    func applicationWillEnterForeground(_ application: UIApplication) {
      print("===9")
    }
    
    /** 앱 백그라운드 **/
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("===10")
        Messaging.messaging().shouldEstablishDirectChannel = false
        debugPrint("@8 AppDelegate DidEnterBackground")
    }
    
    /** 앱 활성화 **/
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("===11")
        Messaging.messaging().shouldEstablishDirectChannel = true
        debugPrint("@9 AppDelegate DidBecomeActive")
        
    }
    
    /** 앱 종료 **/
    func applicationWillTerminate(_ application: UIApplication) {
    }
    
    /** FCM 등록 **/
    func registerForPushNotifications()
    {
       print("===13")
        debugPrint("@10 registerForPushNotifications")
        print("?????")
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
        
        
        
    }
    
    func tokenRefreshNotificaiton(_ notification: Foundation.Notification)
    {
        print("===14")
        if let refreshedToken = InstanceID.instanceID().token()
        {
            debugPrint("@12 InstanceID token: \(refreshedToken)")
        }
    }
    
    /** 알림 데이터 전송 **/
    func setSharedData(userInfo: [AnyHashable: Any], send: Bool){
        print("===15")
        print("@@@@\(userInfo)")
        guard let pushNo = userInfo["push_no"] else {
            return
        }
        sharedData["pushno"] = pushNo as? String
        guard let startURL = userInfo["start-url"] as? String ?? userInfo["start_url"] as? String else {
            return
        }
        sharedData["pushlink"] = startURL
        
        if send {
            NotificationCenter.default.post(name: Notification.Name("fcm_data"), object: nil)
        }
    }
    
    
    /** 새로운 FCM 토큰을 받을 때마다 호출 **/
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String)
    {
        print("===16")
        NotificationCenter.default.post(name: Notification.Name("device_token"), object: nil)
        debugPrint("@13 didRefreshRegistrationToken:\(fcmToken)")
    }
    @available(iOS 10.0, *)
    public func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage)
    {
        print("===17")
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
       print("===18")
        print("=========")
        print("=========")
        print("=========")
        print("=========")
        print("=========")
        
        //알림 처리
        self.setSharedData(userInfo: notification.request.content.userInfo, send: false);
        debugPrint("@15 notification: \(notification)")
        //수신완료
        completionHandler([.alert, .sound])
    }
    
    /** 알림 메세지 탭 동작시 호출 **/
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        print("===19")
        //알림 처리
        self.setSharedData(userInfo: response.notification.request.content.userInfo, send: true);
        debugPrint("@16 didReceive response Notification \(response) ")
        //수신완료
        completionHandler()
    }
    
    /** 딥링크 **/
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        //self.splashDidShow()
        // 카카오링크
        if KLKTalkLinkCenter.shared().isTalkLinkCallback(url) {
            sharedData["kakaolink"] = url.query
            NotificationCenter.default.post(name: Notification.Name("kakao_link"), object: nil)
            return true
        }
        // 커스텀 스키마 딥링크
        if let link = url.valueOf("link") {
            sharedData["deeplink"] = link
            NotificationCenter.default.post(name: Notification.Name("deep_link"), object: nil)
            return true
        }
        
        return false
    }
    
    /** 파이어베이스 다이나믹 링크 **/
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        print("===21")
        let handled = DynamicLinks.dynamicLinks()?.handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
            if let link = dynamiclink!.url {
                NotificationCenter.default.post(name: Notification.Name("dynamic_link"), object: nil, userInfo: ["link" : String(describing: link)])
            }
        }
        
        return handled!
    }
    
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        print("===22")
        if KLKTalkLinkCenter.shared().isTalkLinkCallback(url) {
            sharedData["kakaolink"] = url.query
            let alert = UIAlertController(title: "알림", message: "test" , preferredStyle: .alert)
            let aAction = UIAlertAction(title: url.query, style: .default)
            alert.addAction(aAction)
            return true
        }
        return false
    }
}

extension Notification.Name {
    static let fcm_data = Notification.Name("fcm_data")
}

extension MessagingDelegate {
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("===23")
        debugPrint("@17 Firebase registration token: \(fcmToken)")
    }
    // 앱이 포 그라운드 일 때 FCM (APN 무시)에서 직접 iOS 10 이상의 데이터 메시지를받습니다.
    // 직접적인 데이터 메시지를 활성화하려면 Messaging.messaging (). shouldEstablishDirectChannel을 true로 설정합니다.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("===24")
        print("@18 Received data message: \(remoteMessage.appData)")
    }
}

extension URL {
    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}
