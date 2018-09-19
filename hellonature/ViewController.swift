//
//  Updated by team hn.dev on 2017. 09. 05..
//  Copyright (c) 2017 Hellonature. All rights reserved.
//
import UIKit
import WebKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import SwiftyGif
import EasyAnimation
import UserNotifications

// PG사 도메인
enum Billing: String, RawRepresentable {
    case Inicis = "inicis.com"
    case Hyundaicard = "hyundaicard.com"
    case Samsungcard = "samsungcard.co.kr"
    case Shinhancard = "shinhancard.com"
    case Lottecard = "lottecard.co.kr"
    case Nonghyup = "nonghyup.com"
    case Hanacard = "hanacard.co.kr"
    case Citibank = "citibank.co.kr"
}

// 팝업허용 도메인
enum Blank: String, RawRepresentable {
    case Itunes = "itunes.apple.com"
    case Kakaostory = "story.kakao.com"
    case Naverblog = "blog.naver.com"
    case Facebook = "ko-kr.facebook.com"
    case Instagram = "www.instagram.com"
}

// 스키마 모음
enum Scheme: String, RawRepresentable {
    case Http = "http"
    case Https = "https"
    case About = "about"
    case Javascript = "javascript"
    case Kakaolink = "kakaolink"
    case Kakaotalk = "kakaotalk"
    case Deeplink = "deeplink"
    case Ispmobile = "ispmobile"
}

// 헬로네이처
enum Hellonature: String {
    case Mobile
    case Banner
    case Domain
    case Push
    var Base: String {
        return "https://www.hellonature.net"
    }
    var url: String {
        switch self {
        case .Mobile:
            return "\(Base)/mobile_shop"
        case .Banner:
            return "\(Base)/mobile_shop/app"
        default:
            return Base
        }
    }
}

//푸시 API
enum Push: String {
    case Update
    var API: String{
        return "https://push.hellonature.net/push"
    }
    var url: String {
        switch self {
        case .Update:
            return "\(API)/update"
        }
    }
}

// 웹뷰 인터페이스
enum Bridge: String {
    case Openbanner = "open app banner"
    case Closebanner = "close app banner"
    case OpenSettings = "push permission setting"
    case SettingsInfo = "push permission info"
}

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler{
    var webView: WKWebView!
    var banner: WKWebView!
    var splash: UIView!
    var mainView: WKWebView?
    var webViewStarted:Bool = false
    @objc var showStatusBar:Bool = false
    var screenSize:CGRect!
    var uagt: String?
    
    /** 뷰컨트롤러 시작 **/
    override func viewDidLoad() {
        EasyAnimation.enable()
        super.viewDidLoad()
        self.screenSize = UIScreen.main.bounds
        
        sleep(1)
        
        self.createWebview()
        self.createToolbar()
        self.mainView = self.webView
        self.view.backgroundColor = UIColor.white
        
        UIApplication.shared.statusBarView?.backgroundColor = UIColor.white
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushReceiver), name: Notification.Name("fcm_data"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.linkReceiver), name: Notification.Name("deep_link"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.linkReceiver), name: Notification.Name("kakao_link"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.linkReceiver), name: Notification.Name("dynamic_link"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenReceiver), name: Notification.Name("device_token"), object: nil)
    }
    
    /** 앱 활성화될 때 **/
    @objc func applicationDidBecomeActive(_ notification: NSNotification?) {
        // 웹뷰가 만들어졌다면 웹뷰에 알림등록 상태를 전달한다.
        if webView != nil {
            self.sendRegisteredForNotifications()
        }
        // 앱델리게이트에서 푸시, 카카오링크, 딥링크등의 정보를 얻어와서 해당링크로 이동시킨다.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let pushNo = appDelegate.sharedData["pushno"] {
            self.httpRequest("\(Push.Update.url)\(pushNo)", parameters: ["uid": self.getDeviceToken()] as AnyObject)
            guard let startURL = appDelegate.sharedData["pushlink"], startURL.count > 0 else {
                return
            }
            self.banner.removeFromSuperview()
            self.mainView = self.webView
            self.startWebview(startURL)
            appDelegate.sharedData["pushno"] = nil
            appDelegate.sharedData["pushlink"] = nil
        } else if let kakaolink = appDelegate.sharedData[Scheme.Kakaolink.rawValue] {
            self.loadPage("\(Hellonature.Domain.url)\(kakaolink)", key: Scheme.Kakaolink.rawValue)
            return
        } else if let deeplink = appDelegate.sharedData[Scheme.Deeplink.rawValue] {
            self.loadPage(deeplink, key: Scheme.Deeplink.rawValue)
            return
        } else if let userInfo = notification?.userInfo, let deeplink = userInfo["link"] as? String {
            self.loadPage(deeplink)
        }
    }
    
   
    /** 결제시 백버튼에 사용할 네이게이션 툴바 **/
    func createToolbar(){
        let item: UIBarButtonItem = UIBarButtonItem(title: "돌아가기", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.backwardWebview))
        toolbarItems = [item]
        navigationController?.isToolbarHidden = true
        navigationController?.isNavigationBarHidden = true
    }
    
    /** 백버튼 **/
    @objc func backwardWebview() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    /** 웹뷰 만들기 **/
    func createWebview(){
        let config = WKWebViewConfiguration()
        config.userContentController = self.createWebviewController()
        self.createMainview(config: config)
    }
    
    /** 기본 웹뷰의 시작 페이지 불러오기 **/
    func startWebview(_ url: String?){
        // 웹뷰 custom userAgnet 설정
        guard let url = url else {
            return
        }
        self.setUserAgent()
        webView.load(URLRequest(url: URL(string: url)!))
    }
    
    func loadPage(_ url: String, key: String? = nil) -> () {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.startWebview(url)
                self.banner.removeFromSuperview()
                self.mainView = self.webView
                self.navigationController?.isToolbarHidden = true
            }
            if let key = key {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.sharedData[key] = nil
                }
            }
        }
    }
    
    /** 웹뷰의 userAgent 설정 **/
    @objc func setUserAgent() {
        webView.evaluateJavaScript("navigator.userAgent") { [weak webView] (result, error) in
            if let webView = webView, var userAgent = result as? String {
                if let uagt = self.uagt {
                    userAgent = uagt
                } else {
                    self.uagt = userAgent
                }
                userAgent += " token/\(self.getDeviceToken())"
                userAgent += " platform/iphone_app"
                userAgent += " version/\(self.version())"
                webView.customUserAgent = userAgent
                print("@@@\(userAgent)")
            }
        }
    }
    
    /** 기본 웹뷰 초기설정 및 만들기 **/
    func createMainview(config: WKWebViewConfiguration){
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: self.screenSize.width, height: self.screenSize.height), configuration: config)
        //webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.configuration.preferences.setValue(true, forKey : "developerExtrasEnabled")
        self.view.addSubview(webView)
        self.startWebview(Hellonature.Mobile.url)
    }
    
    /** 웹뷰 컨트롤러 만들기 **/
    func createWebviewController() -> WKUserContentController{
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")
        contentController.addUserScript(self.getUserScript(script: "javascript: localStorage.setItem('key', 'value')"))
        contentController.addUserScript(self.getUserScript(script: "javascript: sessionStorage.setItem('key', 'value')"))
        return contentController
    }
    
    /** 웹뷰 컨틀롤러에 추가될 스크립트 **/
    func getUserScript(script: String) -> WKUserScript{
        return WKUserScript(source: script, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
    }
    
    // 웹뷰 보안 체크
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        print("@@@\(url)")
        // 아이튠즈는 기본적으로 사파리로 이동
        if url.absoluteString.contains(Blank.Itunes.rawValue) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        // scheme 형태로 호출할 경우
        if !Scheme.values.contains(url.scheme ?? "") {
            // 앱이 설치되어 있는 경우
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            // 앱이 설치되어 있지 않은 경우
            } else {
                var warnning: (message: String, url: String)?
                if let scheme = url.scheme {
                    switch scheme {
                        //카카오 톡일 경우
                        case Scheme.Kakaotalk.rawValue: warnning = (message: "카카오톡 앱이 설치되지 않았습니다.", url: "https://itunes.apple.com/kr/app/kakaotalk/id362057947?mt=8")
                        //이니시스 결제
                        case Scheme.Ispmobile.rawValue: warnning = (message: "ISP/페이북 앱이 설치되지 않았습니다.", url: "https://itunes.apple.com/kr/app/isp-%ED%8E%98%EC%9D%B4%EB%B6%81/id369125087?mt=8")
                        // 그외
                        default: warnning = nil
                    }
                }
                // 경고 정보가 있다면
                if let options = warnning {
                    let alert = UIAlertController(title: "알림", message: options.message , preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    let aAction = UIAlertAction(title: "다운받으러가기", style: .default){ (action:UIAlertAction) in
                        UIApplication.shared.open(URL(string: options.url)!, options: [:], completionHandler: nil)
                    }
                    alert.addAction(aAction)
                    alert.addAction(alertAction)
                    present(alert, animated: true, completion: nil)
                    decisionHandler(.cancel)
                    return
                }
            }
        // http, https 일반
        }else{
            // 카드사목록 포함되어 있는지 체크
            let contains = Billing.values.filter({ (host) -> Bool in
                return url.absoluteString.contains(host)
            })
            
            // 히스토리 백버튼 보이기
            if url.scheme != Scheme.About.rawValue {
                navigationController?.setToolbarHidden(contains.count == 0, animated: true)
            }
    
            //ISP 백버튼 이동 시 리다이렉팅 탈출!
            if(navigationAction.navigationType == .backForward) {
                //URL 요청이 중 이니시스 게이트웨이가 포함되어 있으면 한번더 강제 백이동
                if url.absoluteString.contains("smart/wcard/gateway") {
                    self.backwardWebview()
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
    
    // 팝업
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let url = navigationAction.request.url, let host = url.host else {
            return nil
        }
        // 팝업이 허용된 도메인들
        if navigationAction.targetFrame == nil {
            // 사파리로 팝업
            if Blank.values.contains(host) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                return nil
            }
            // 허용되지 않은 도메인들은 웹뷰로
            webView.load(navigationAction.request)
        }
        return nil
    }
 
    /** 페이지 로딩 완료, webView의 페이지가 로드가 완료 & 처음 페이지 로드시에만 js함수 호출 **/
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView == self.webView && !self.webViewStarted{
            self.webViewStarted = true
            self.banner.evaluateJavaScript("c")
        }
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil,
                                                preferredStyle: UIAlertControllerStyle.alert);
        alertController.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.cancel) {
            _ in completionHandler()}
        );
        self.present(alertController, animated: true, completion: {});
    }
    
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in
            completionHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in
            completionHandler(false)
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    
    /** 웹뷰 활성화 될때 푸시된 데이터메세지 수신 메서드 등록하기 **/
    override func viewWillAppear(_ animated: Bool) {
        
    }

    /** 웹뷰 비활성화 될때 **/
    override func viewWillDisappear(_ animated: Bool) {

    }
}



extension UIColor{
    convenience init(rgb: UInt){
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

/** 뷰컨트롤러 확장 **/
extension ViewController {
    /** 스크립트메시지 핸들러 **/
    @available(iOS 8.0, *)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            if let body:NSDictionary = (message.body as? NSDictionary){
                guard let message = body["message"] as? String else {
                    return
                }
                switch message {
                // 앱 배너 열기
                case Bridge.Openbanner.rawValue:
                    self.banner.isHidden = false
                    self.mainView = self.banner
                // 앱 배너 닫기, 페이지 이동
                case Bridge.Closebanner.rawValue:
                    if !self.banner.isHidden {
                        setNeedsStatusBarAppearanceUpdate()
                    }
                    self.tween(current: self.banner, next: self.webView)
                    self.webView.frame.origin.y = UIApplication.shared.statusBarFrame.size.height
                    guard let url = body["param"] as? String, !url.isEmpty else {
                        return
                    }
                    self.startWebview(url)
                // 앱 알림설정
                case Bridge.OpenSettings.rawValue:
                    self.openAppSettings()
                case Bridge.SettingsInfo.rawValue:
                    self.sendRegisteredForNotifications()
                default:
                    setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }
    
    @objc func tokenReceiver(_ notification: NSNotification?){
        self.setUserAgent()
    }
    
    /** FCM 메세지에서 시작페이지 가져오기 **/
    @objc func pushReceiver(_ notification: NSNotification?){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let pushNo = appDelegate.sharedData["pushno"] {
            self.httpRequest("https://push.hellonature.net/push/update/\(pushNo)", parameters: ["uid": self.getDeviceToken()] as AnyObject)
            guard let startURL = appDelegate.sharedData["pushlink"], startURL.count > 0 else {
                return
            }
            self.banner.removeFromSuperview()
            self.mainView = self.webView
            self.startWebview(startURL)
            appDelegate.sharedData["pushno"] = nil
            appDelegate.sharedData["pushlink"] = nil
        }
    }
    
    
    /** 딥링크로 이동하기 **/
    @objc func linkReceiver(_ notification: NSNotification?){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let kakaolink = appDelegate.sharedData[Scheme.Kakaolink.rawValue] {
            self.loadPage("\(Hellonature.Domain.url)\(kakaolink)", key: Scheme.Kakaolink.rawValue)
            return
        } else if let deeplink = appDelegate.sharedData[Scheme.Deeplink.rawValue] {
            self.loadPage(deeplink, key: Scheme.Deeplink.rawValue)
            return
        } else if let userInfo = notification?.userInfo, let deeplink = userInfo["link"] as? String {
            self.loadPage(deeplink)
        }
    }
    
    /** 디바이스 토큰 가져오기 **/
    func getDeviceToken() ->String{
        guard let deviceToken = InstanceID.instanceID().token() else {
            return ""
        }
        return deviceToken
    }
    

    func openAppSettings() {
        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    //기기 알림설정 정보 보내기
    func sendRegisteredForNotifications() -> () {
        webView.evaluateJavaScript("javascript:events.dispatch('hn.app.notification.enabled', \(self.isRegisteredForRemoteNotifications()))", completionHandler: nil)
    }
    //기기 알림설정 알아오기
    func isRegisteredForRemoteNotifications() -> Bool {
        if #available(iOS 10.0, *) {
            var isRegistered = false
            let semaphore = DispatchSemaphore(value: 0)
            let current = UNUserNotificationCenter.current()
            current.getNotificationSettings(completionHandler: { settings in
                if settings.authorizationStatus != .authorized {
                    isRegistered = false
                } else {
                    isRegistered = true
                }
                semaphore.signal()
            })
            _ = semaphore.wait(timeout: .now() + 5)
            return isRegistered
        } else {
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                return true
            } else {
                return false
            }
        }
    }
    
    /** 앱버전 정보 **/
    func version() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "\(version).\(build)"
    }
    
    /** 스라이드 애니메이션 **/
    func tween(current:UIView, next:UIView){
        next.frame.origin.x = next.frame.width
        UIView.animate(withDuration: 1.0,
                       delay: 0.0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.0,
                       options: [],
                       animations: {
                        current.frame.origin.x = -current.frame.width
                        next.frame.origin.x = 0
        },
                       completion: { finished in
                        current.removeFromSuperview()
        })
    }
    
    
    /** 비동기 POST 요청 **/
    private func httpRequest(_ url: String, parameters: AnyObject) {
        guard let url = URL(string: url) else { return }
        debugPrint(url)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                return
            }
            }.resume()
    }
    
    /** json 파싱 **/
    func parseJSON(_ data: Data?) -> AnyObject? {
        if let data = data {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                return json as AnyObject
            } catch let error {
                debugPrint(error.localizedDescription)
            }
        }
        return nil
    }
}

// enum 형태를 Array 형태로 반환 해줌
extension RawRepresentable where Self: Hashable {
    private static func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var index = 0
        let closure: () -> T? = {
            let next = withUnsafePointer(to: &index) {
                $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
            }
            guard next.hashValue == index else { return nil }
            index += 1
            return next
        }
        return AnyIterator(closure)
    }
    
    static var values: [Self.RawValue] {
        return iterateEnum(self).map { $0.rawValue }
    }
    
    static var cases: [Self] {
        return iterateEnum(self).map { $0 }
    }
}

extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}





