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


let TRANS_VIEW_LEFT = "tans view left"
let TRANS_VIEW_RIGHT = "tans view right"
let TRANS_VIEW_TOP = "tans view top"
let TRANS_VIEW_BOTTOM = "tans view bottom"

let SITE_DOMAIN:String = "https://www.hellonature.net/mobile_shop/"
let SITE_PARAMETER:String = "UserScreen=iphone_app&hwid="
let SITE_BANNER:String = "https://www.hellonature.net/mobile_shop/app/index.html"
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
    }
    
    func createWebview(){
        let config = WKWebViewConfiguration()
        config.userContentController = self.createWebviewController()
        self.createMainview(config: config)
        self.createBannerview(config: config)
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
        self.changeViewTween(type: self.mainView == self.banner ? TRANS_VIEW_TOP : TRANS_VIEW_LEFT, current: self.splash, next: self.mainView)
        showStatusBar = true
        setNeedsStatusBarAppearanceUpdate()
    }
    
    /** 기본 웹뷰 초기설정 및 만들기 **/
    func createMainview(config: WKWebViewConfiguration){
        webView = WKWebView(frame: CGRect(x: 0, y: 24, width: self.view.frame.width, height: self.view.frame.height-24), configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.view.addSubview(webView)
        self.startWebview(token: self.getDeviceToken())
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
    
    /** 뷰 에니메이션 **/
    func changeViewTween(type:String, current:UIView, next:UIView){
        var currDestX:CGFloat = 0.0
        var currDestY:CGFloat = 0.0
        let nextDestX:CGFloat = next.frame.origin.x
        let nextDestY:CGFloat = next.frame.origin.y
        switch type {
            case TRANS_VIEW_LEFT:next.frame.origin.x = next.frame.width
                currDestX = CGFloat(Int(-next.frame.width))
                currDestY = 0.0
            case TRANS_VIEW_RIGHT: next.frame.origin.x = -next.frame.width
                currDestX = CGFloat(Int(next.frame.width))
                currDestY = 0.0
            case TRANS_VIEW_TOP: next.frame.origin.y = next.frame.height
                currDestX = 0.0
                currDestY = CGFloat(Int(-next.frame.height))
            case TRANS_VIEW_BOTTOM: next.frame.origin.y = -next.frame.height
                currDestX = 0.0
                currDestY = CGFloat(Int(next.frame.height))
            default: next.frame.origin.y = 0
                currDestX = 0.0
                currDestY = 0.0
        }
        UIView.animate(withDuration: 0.4,
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
                        current.frame.origin.x = currDestX
                        current.frame.origin.y = currDestY
                        next.frame.origin.x = nextDestX
                        next.frame.origin.y = nextDestY
        }, completion: { finished in
            current.removeFromSuperview()
            
        })
    }
    
    
    /** 웹뷰 컨틀롤러에 추가될 스크립트 **/
    func getUserScript(script: String) -> WKUserScript{
        return WKUserScript(source: script, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
    }
    
    /** 기본 웹뷰의 시작 페이지 불러오기 **/
    func startWebview(token:String){
        debugPrint("\(SITE_DOMAIN)?\(SITE_PARAMETER)\(token)")
        webView.load(URLRequest(url: URL(string: "\(SITE_DOMAIN)?\(SITE_PARAMETER)\(token)")!))
    }
    
    /** 스크립트메시지 핸들러 **/
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            if let body:NSDictionary = (message.body as? NSDictionary){
                debugPrint("JavaScript is sending a message \(NSString(string: body["message"] as! NSString))")
                //자바스크립트에서 배너뷰 닫기 호출
                if body["message"] as! String == CLOSE_APP_BANNER {
                    self.changeViewTween(type: TRANS_VIEW_LEFT, current: self.banner, next: self.webView)
                    self.mainView = self.webView
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
        } else if url.host == "itunes.apple.com" {
            print("url is itunes")
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }else{
            // a태그 _blank 새창띄우기
            if navigationAction.targetFrame == nil {
                if app.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    decisionHandler(.cancel)
                    debugPrint("@20 C")
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
            debugPrint("@21 \(navigationAction.request)")
            webView.load(navigationAction.request)
        }
        return nil
    }
    /** SSL 설정 **/
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
    
    /** 페이지 로딩 완료, webView의 페이지가 로드가 완료 & 처음 페이지 로드시에만 js함수 호출 **/
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView == self.webView && !self.webViewStarted{
            self.webViewStarted = true
            /** 배너 로드 완료 **/
            self.banner.evaluateJavaScript("appReady('\(version())')", completionHandler: nil)
 
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
    
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Strat to load")
    }
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        print("finish to load")
    }
    
    func version() -> String{
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        return version
    }
    

    /** FCM 메세지에서 시작페이지 가져오기 **/
    @objc func pushReceiver(_ notification: NSNotification){
        let userInfo = notification.userInfo,
            startURL = userInfo?["start-url"]
        if(startURL != nil){
            webView.load(URLRequest(url: URL (string: startURL as! String)!));
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
        sleep(1)
        self.removeSplash()
    }
}





