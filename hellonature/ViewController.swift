//
//  Updated by team hn.dev on 2017. 09. 05..
//  Copyright (c) 2017 Hellonature. All rights reserved.
//
import UIKit
import WebKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
//import SwiftyJSON
import SwiftyGif


let SITE_DOMAIN:String = "http://www.hellonature.net/mobile_shop/"
let SITE_PARAMETER:String = "UserScreen=iphone_app&hwid="
let SITE_BANNER:String = "http://www.hellonature.net/mobile_dev/app/index.html"
let LOADED_APP_BANNER:String = "loaded app banner"
let CLOSE_APP_BANNER:String = "close app banner"

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler{
    
    var webView: WKWebView!
    var banner: WKWebView!
    var navigated:Bool = false
    var showStatusBar:Bool = false
    
    /** 뷰컨트롤러 시작 **/
    override func viewDidLoad() {
 
        super.viewDidLoad()
        self.createWebview()
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushReceiver), name: Notification.Name("fcm_data"), object: nil)
    }
    
    
    func createWebview(){
        let config = WKWebViewConfiguration()
        config.userContentController = self.createWebviewController()
        self.createMainview(config: config)
        self.createBannerview(config: config)
        self.startWebview()
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
    }
    
    /** 웹뷰 컨트롤러 만들기 **/
    func createWebviewController() -> WKUserContentController{
        let js = "javascript: localStorage.setItem('key', 'value')";
        let userScript = WKUserScript(source: js, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false);
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")
        contentController.addUserScript(userScript)
        return contentController
    }
    
    /** 기본 웹뷰의 시작 페이지 불러오기 **/
    func startWebview(){
        let deviceToken = InstanceID.instanceID().token()
        let token = deviceToken == nil ? "" : deviceToken!
        // 도메인 + 기본 URL파라미터 + 디바이스 토큰
        webView.load(URLRequest(url: URL(string: "\(SITE_DOMAIN)?\(SITE_PARAMETER)\(token)")!))
    }
    
    /** 배너뷰 컨트롤러 **/
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            debugPrint("JavaScript is sending a message \(NSString(string: message.body as! String))")
            //자바스크립트에서 배너뷰 닫기 호출
            if message.body as! String == CLOSE_APP_BANNER {
                self.banner.removeFromSuperview()
                showStatusBar = true
                setNeedsStatusBarAppearanceUpdate()
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
        if let url = navigationAction.request.url {
            // a태그 _blank 새창띄우기
            if navigationAction.targetFrame == nil {
                if app.canOpenURL(url) {
                    app.openURL(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            // 폰 이메일 새창띄위기
            if url.scheme == "tel" || url.scheme == "mailto" {
                if app.canOpenURL(url) {
                    app.openURL(url)
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
        if webView == self.webView{
            self.navigated = true
            self.banner.evaluateJavaScript("appReady()")
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
    

    /** FCM 메세지에서 시작페이지 가져오기 **/
    func pushReceiver(_ notification: NSNotification){
        let userInfo = notification.userInfo,
            startURL = userInfo?["start-url"],
            deviceToken = self.getDeviceToken();
        if(startURL != nil){
            webView.load(URLRequest(url: URL (string: "\(startURL!)?\(SITE_PARAMETER)\(deviceToken)")!));
        }
    }
    
    func getDeviceToken() ->String{
        let deviceToken = InstanceID.instanceID().token()
        return deviceToken == nil ? "" : deviceToken!
    }
    
    
    /** 웹뷰 활성화 될때 푸시된 데이터메세지 수신 메서드 등록하기 **/
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    /** 웹뷰 비활성화 될때 **/
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    /** 상태바 숨기기 **/
//    override var prefersStatusBarHidden: Bool{
//        return self.statusBarHidden
//    }
    
    
    override var prefersStatusBarHidden: Bool {
        if showStatusBar == true {
            //does not prefer status bar hidden
            print("does not prefer status bar hidden")
            return false
            
        } else {
            //does prefer status bar hidden
            print("does prefer status bar hidden")
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






