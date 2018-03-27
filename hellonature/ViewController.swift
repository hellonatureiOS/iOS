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

enum Blank: String, RawRepresentable {
    case Itunes = "itunes.apple.com"
    case Kakaostory = "story.kakao.com"
    case Naverblog = "blog.naver.com"
    case Facebook = "www.facebook.com"
    case Instagram = "www.instagram.com"
}

enum Web: String, RawRepresentable {
    case Http = "http"
    case Https = "https"
    case About = "about"
    case Javascript = "javascript"
}

enum App: String {
    case Kakaolink = "kakaolink"
    case Ispmobile = "ispmobile"
}

enum This: String {
    case Domain = "https://www.hellonature.net"
    case Banner = "/app/"
    case Base = "/mobile_shop"
    case Openbanner = "open app banner"
    case Closebanner = "close app banner"
}

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler{
    
    var webView: WKWebView!
    var banner: WKWebView!
    var splash: UIView!
    var progressView: UIProgressView?
    var mainView: WKWebView?
    var webViewStarted:Bool = false
    var showStatusBar:Bool = false
    var releaseVers:String?
    typealias JSON = [String: AnyObject]
    
    /** 뷰컨트롤러 시작 **/
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createWebview()
        self.createSplash()
        self.createToolbar()
        self.mainView = self.webView
        self.view.backgroundColor = UIColor.white
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushReceiver), name: Notification.Name("fcm_data"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.kakaoReceiver), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func createToolbar(){
        let item: UIBarButtonItem = UIBarButtonItem(title: "돌아가기", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.backwardWebview))
        toolbarItems = [item]
        navigationController?.isToolbarHidden = true
        navigationController?.isNavigationBarHidden = true
    }
    
    @objc func backwardWebview() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    func createWebview(){
        let config = WKWebViewConfiguration()
        config.userContentController = self.createWebviewController()
        self.createMainview(config: config)
        self.createBannerview(config: config)
    }
    
    /** 기본 웹뷰의 시작 페이지 불러오기 **/
    func startWebview(_ url: String){
        // 웹뷰 custom userAgnet 설정
        webView.evaluateJavaScript("navigator.userAgent") { [weak webView] (result, error) in
            if let webView = webView, var userAgent = result as? String {
                userAgent += " token/\(self.getDeviceToken())"
                userAgent += " platform/iphone_app"
                userAgent += " updated/\(self.updateAvailable())"
                webView.customUserAgent = userAgent
            }
        }
        webView.load(URLRequest(url: URL(string: url)!))
    }
    
    /** 스플래시 애니메이션 붙이기 **/
    func createSplash(){
        let gifManager = SwiftyGifManager(memoryLimit: 20)
        let gifImage = UIImage(gifName: "intro")
        let gifView = UIImageView(gifImage: gifImage, manager: gifManager, loopCount: 1)
        
        gifView.frame = CGRect(x: 0, y: 0, width: 250, height: 250)
        gifView.center = self.view.center
        gifView.contentMode = UIViewContentMode.scaleAspectFit
        gifView.delegate = self
        self.splash = UIView(frame: self.view.frame)
        self.splash.addSubview(gifView)
        self.splash.backgroundColor = UIColor(red: 0.11, green: 0.25, blue: 0.13, alpha:1.0)
        self.view.addSubview(self.splash)
    }
    
    /** 스플래시 애니메이션 삭제 **/
    func removeSplash(){
        self.animateRTL(current: self.splash, next: self.mainView!)
        if self.mainView == self.webView {
            showStatusBar = true
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    /** 기본 웹뷰 초기설정 및 만들기 **/
    func createMainview(config: WKWebViewConfiguration){
        webView = WKWebView(frame: CGRect(x: 0, y: 24, width: self.view.frame.width, height: self.view.frame.height-24), configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.view.addSubview(webView)
        self.startWebview("\(This.Domain.rawValue)/\(This.Base.rawValue)")
    }
    
    
    /** 배너뷰 초기설정 및 만들기 **/
    func createBannerview(config: WKWebViewConfiguration){
        banner = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), configuration: config)
        banner.navigationDelegate = self
        banner.uiDelegate = self
        banner.scrollView.isScrollEnabled = false
        banner.scrollView.bounces = false
        banner.backgroundColor = UIColor(rgb: 0x1C3F21)
        banner.load(URLRequest(url: URL(string: "\(This.Domain.rawValue)/\(This.Banner.rawValue)")!))
        banner.isHidden = true
        banner.evaluateJavaScript("document.getElementById('ios').textContent", completionHandler: { (html: Any?, error: Error?) in
            print(html)
        })
        self.view.addSubview(banner)
    }
    
    /** 웹뷰 컨트롤러 만들기 **/
    func createWebviewController() -> WKUserContentController{
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")
        contentController.addUserScript(self.getUserScript(script: "javascript: localStorage.setItem('key', 'value')"))
        contentController.addUserScript(self.getUserScript(script: "javascript: sessionStorage.setItem('key', 'value')"))
        return contentController
    }
    
    /** 스라이드 애니메이션 **/
    func animateRTL(current:UIView, next:UIView){
        next.frame.origin.x = next.frame.width
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
                        current.frame.origin.x = -current.frame.width
                        next.frame.origin.x = 0
        }, completion: { finished in
            current.removeFromSuperview()
        })
    }
    
    /** 웹뷰 컨틀롤러에 추가될 스크립트 **/
    func getUserScript(script: String) -> WKUserScript{
        return WKUserScript(source: script, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
    }
    
    /** 스크립트메시지 핸들러 **/
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            if let body:NSDictionary = (message.body as? NSDictionary){
                guard let message = body["message"] as? String else {
                    return
                }
                switch message {
                case This.Openbanner.rawValue:
                    self.banner.isHidden = false
                    self.mainView = self.banner
                case This.Closebanner.rawValue:
                    showStatusBar = true
                    self.animateRTL(current: self.banner, next: self.webView)
                    setNeedsStatusBarAppearanceUpdate()
                default:
                    showStatusBar = true
                    setNeedsStatusBarAppearanceUpdate()
                }
                guard let url = body["param"] else {
                    return
                }
                self.startWebview(url as! String)
            }
        }
    }
    
   
    // 웹뷰 보안 체크
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // 아이튠즈는 기본적으로 사파리로 이동
        if url.absoluteString.contains(Blank.Itunes.rawValue) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        // scheme 형태로 호출할 경우
        if !Web.values.contains(url.scheme ?? "") {
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
                        case App.Kakaolink.rawValue: warnning = (message: "카카오톡 앱이 설치되지 않았습니다.", url: "https://itunes.apple.com/kr/app/kakaotalk/id362057947?mt=8")
                        //이니시스 결제
                        case App.Ispmobile.rawValue: warnning = (message: "ISP/페이북 앱이 설치되지 않았습니다.", url: "https://itunes.apple.com/kr/app/isp-%ED%8E%98%EC%9D%B4%EB%B6%81/id369125087?mt=8")
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
            
            // 팝업은 체크 하지 말자.
            if url.scheme != Web.About.rawValue {
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
    
    func bannerAnimation(fadeIn:Bool){
        UIView.animate(withDuration: 0.5, animations: {
            self.banner.alpha = fadeIn ? 1 : 0
        }, completion: {
            (value: Bool) in
            if !fadeIn{
                self.banner.removeFromSuperview()
            }
        })
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
    
    
    /** FCM 메세지에서 시작페이지 가져오기 **/
    @objc func pushReceiver(_ notification: NSNotification){
        guard let userInfo = notification.userInfo else {
            return
        }
        debugPrint("@@@@userInfo", userInfo)
        guard let pushNo = userInfo["push_no"] else {
            return
        }
        
        self.httpRequest("https://api.hellonature.net/push/update/\(pushNo)", parameters: ["uid": self.getDeviceToken()] as AnyObject)
        guard let startURL = userInfo["start_url"] as? String else {
            return
        }
        
        if startURL.count == 0 {
            return
        }
        
        debugPrint("@@@@startURL", startURL)
        self.banner.removeFromSuperview()
        self.mainView = self.webView
        self.startWebview(startURL)
    }
    
    /** 카카오링크 시작페이지 가져오기 **/
    @objc func kakaoReceiver(_ notification: NSNotification?){
        var link = ""
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let kakaolink = appDelegate.sharedData[App.Kakaolink.rawValue] {
            let range = kakaolink.index(kakaolink.startIndex, offsetBy: 12)
            link = String(kakaolink[range...])
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.startWebview("\(This.Domain.rawValue)\(link)")
                    self.banner.removeFromSuperview()
                    self.mainView = self.webView
                    self.navigationController?.isToolbarHidden = true
                }
            }
            appDelegate.sharedData[App.Kakaolink.rawValue] = nil
        }
    }
    
    /** 디바이스 토큰 가져오기 **/
    func getDeviceToken() ->String{
        let deviceToken = InstanceID.instanceID().token()
        return deviceToken == nil ? "" : deviceToken!
    }
    
    
    /** 웹뷰 활성화 될때 푸시된 데이터메세지 수신 메서드 등록하기 **/
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    /** 웹뷰 비활성화 될때 **/
    override func viewWillDisappear(_ animated: Bool) {
        //NotificationCenter.default.removeObserver(self)
    }
    
    /** 상태바 숨기기 설정 **/
    override var prefersStatusBarHidden: Bool {
        if showStatusBar == true {
            return false
        } else {
            return true
        }
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


extension ViewController{
    /** 앱 버전 체크 **/
    func updateAvailable() -> Bool{
        var needUpdate:Bool = false
        do {
            guard let info = Bundle.main.infoDictionary,
                let userAppVersion = info["CFBundleShortVersionString"] as? String,
                let identifier = info["CFBundleIdentifier"] as? String,
                let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)") else {
                    throw VersionError.invalidBundleInfo
            }
            debugPrint("userAppVersion : \(userAppVersion)");
            let data = try Data(contentsOf: url)
            guard let json = self.parseJSON(data) else {
                throw VersionError.invalidResponse
            }
            if let result = (json["results"] as? [Any])?.first as? [String: Any], let appStroeVersion = result["version"] as? String {
                debugPrint("appStroeAppVersion : \(appStroeVersion)");
                needUpdate = userAppVersion < appStroeVersion
            }
            throw VersionError.invalidResponse
        } catch {
            print(error)
        }
        return needUpdate
    }
    
    enum VersionError: Error {
        case invalidResponse, invalidBundleInfo
    }
    
    /** 서버 통신 **/
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


/** 스플래시 애니메이션 완료 시 **/
extension ViewController: SwiftyGifDelegate {
    func gifDidLoop(sender: UIImageView) {
        print("splash finished")
        self.removeSplash()
    }
}

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





