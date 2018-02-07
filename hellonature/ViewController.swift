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

var SITE_DOMAIN:String = "https://dev.hellonature.net/mobile_shop"
let SITE_PARAMETER:String = "/UserScreen=iphone_app&hwid="
let SITE_BANNER:String = "\(SITE_DOMAIN)/app/index.html"
let LOADED_APP_BANNER:String = "loaded app banner"
let CLOSE_APP_BANNER:String = "close app banner"

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler{
    
    var webView: WKWebView!
    var banner: WKWebView!
    var splash: UIView!
    var mainView: WKWebView!
    var webViewStarted:Bool = false
    var showStatusBar:Bool = false

    /** 뷰컨트롤러 시작 **/
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createWebview()
        self.createSplash()
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushReceiver), name: Notification.Name("fcm_data"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.startWebview), name: Notification.Name("kakao"), object: nil)
    }
    
    func createWebview(){
        let config = WKWebViewConfiguration()
        config.userContentController = self.createWebviewController()
        self.createMainview(config: config)
        self.createBannerview(config: config)
        self.startWebview(nil)
    }
    
    /** 기본 웹뷰의 시작 페이지 불러오기 **/
    @objc func startWebview(_ notification: NSNotification?){
        let deviceToken = InstanceID.instanceID().token()
        let token = deviceToken == nil ? "" : deviceToken!
        var kakaourl = ""
        if notification != nil{
            let userInfo = notification!.userInfo
            let iosparam = userInfo?["iosParam"] as! String
            let indexStartOfiosparam = iosparam.index(iosparam.startIndex, offsetBy: 12)
            kakaourl = String(iosparam[indexStartOfiosparam...])
        }
        
        var update:Bool = false
        do {
            update = try self.isUpdateAvailable()
        } catch {
            print(error)
        }
        
         webView.evaluateJavaScript("navigator.userAgent") { [weak webView] (result, error) in
            if let webView = webView, let userAgent = result as? String {
                webView.customUserAgent = userAgent + "/iosCustom/\(update)"
            }
        }
        
        DispatchQueue.global().async {
                DispatchQueue.main.async {
                    let request = URLRequest(url: URL(string: "\(SITE_DOMAIN+kakaourl)?\(SITE_PARAMETER)\(token)&needUpdate=\(update)")!)
                    // 도메인 + 기본 URL파라미터 + 디바이스 토큰 + update유무
                    debugPrint("\(SITE_DOMAIN+kakaourl)?\(SITE_PARAMETER)\(token)")
                    self.webView.load(request)
                }
            
        }
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
        self.animateRTL(current: self.splash, next: self.mainView)
    }
    
    /** 기본 웹뷰 초기설정 및 만들기 **/
    func createMainview(config: WKWebViewConfiguration){
        webView = WKWebView(frame: CGRect(x: 0, y: 24, width: self.view.frame.width, height: self.view.frame.height-24), configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.view.addSubview(webView)
    }
    
    
    /** 배너뷰 초기설정 및 만들기 **/
    func createBannerview(config: WKWebViewConfiguration){
        banner = WKWebView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), configuration: config)
        banner.navigationDelegate = self
        banner.uiDelegate = self
        banner.scrollView.isScrollEnabled = false
        banner.scrollView.bounces = false
        banner.backgroundColor = UIColor(rgb: 0x1C3F21)
        banner.load(URLRequest(url: URL(string: SITE_BANNER)!))
        self.view.addSubview(banner)
        self.mainView = self.banner
    }
    
    /** 웹뷰 컨트롤러 만들기 **/
    func createWebviewController() -> WKUserContentController{
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")
        contentController.addUserScript(self.getUserScript(script: "javascript: localStorage.setItem('key', 'value')"))
        contentController.addUserScript(self.getUserScript(script: "javascript: sessionStorage.setItem('key', 'value')"))
        return contentController
    }
    
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
    

    
    enum VersionError: Error {
        case invalidResponse, invalidBundleInfo
    }
    
    
    func isUpdateAvailable() throws -> Bool {
        guard let info = Bundle.main.infoDictionary,
            let currentVersion = info["CFBundleShortVersionString"] as? String,
            let identifier = info["CFBundleIdentifier"] as? String,
            let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)") else {
                throw VersionError.invalidBundleInfo
        }
        debugPrint("currentVersion : \(currentVersion)");
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any] else {
            throw VersionError.invalidResponse
        }
        if let result = (json["results"] as? [Any])?.first as? [String: Any], let version = result["version"] as? String {
            debugPrint("version : \(version)");
            return version != currentVersion
        }
        throw VersionError.invalidResponse
    }

    /** 스크립트메시지 핸들러 **/
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            if let body:NSDictionary = (message.body as? NSDictionary){
                debugPrint("JavaScript is sending a message \(NSString(string: body["message"] as! NSString))")
                //자바스크립트에서 배너뷰 닫기 호출
                if body["message"] as! String == CLOSE_APP_BANNER {
//                    self.bannerAnimation(fadeIn: false)
                    self.animateRTL(current: self.banner, next: self.webView)
                    self.mainView = self.webView
                    showStatusBar = true
                    setNeedsStatusBarAppearanceUpdate()
                    //배너클릭 주소로 웹뷰 이동
                    if body["param"] != nil {
                        webView.load(URLRequest(url: URL(string: body["param"] as! String)!))
                    }
                }
            }
        }
    }

    
    /** 팝업 설정 **/
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView != self.webView {
            decisionHandler(.allow)
            return
        }
        let app = UIApplication.shared
        
        let url: URL = navigationAction.request.url!
        debugPrint("@20 navigation url\(url)")
        if (url.scheme != "http" && url.scheme != "https" && url.scheme != "about" && url.scheme != "javascript") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        } else if url.host == "itunes.apple.com"{
            print("url is itunes")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }else{
            // a태그 _blank 새창띄우기
            if navigationAction.targetFrame == nil || url.absoluteString.contains("facebook.com/sharer") || url.absoluteString.contains("story.kakao.com/s/share") || url.absoluteString.contains("blog.naver.com/openapi/share?"){
                if app.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
            }
            // 폰 이메일 새창띄위기
            if url.scheme == "tel" || url.scheme == "mailto" {
                if app.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
    
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
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
        let userInfo = notification.userInfo,
            startURL = userInfo?["start-url"],
            deviceToken = self.getDeviceToken();
        print("startURL : \(startURL!)")
        if(startURL != nil){
            print("startURL nil: \(startURL!)")
            webView.load(URLRequest(url: URL (string: "\(startURL!)?\(SITE_PARAMETER)\(deviceToken)")!));
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

/** 스플래시 애니메이션 완료 시 **/
extension ViewController: SwiftyGifDelegate {
    func gifDidLoop(sender: UIImageView) {
        print("splash finished")
        self.removeSplash()
    }
}




