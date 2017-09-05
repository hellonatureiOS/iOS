//
//  Updated by team hn.dev on 2017. 02. 21..
//  Copyright (c) 2017 Hellonature. All rights reserved.
//
import UIKit
import WebKit
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import SwiftyJSON
import SwiftyGif


class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler{

    var webView: WKWebView!
    var urlString: String = "http://www.hellonature.net/mobile_shop"
    var splashScreen: UIImageView!
    var splashBackground: UIView!
    var splashDidStop: Bool = false
    var webviewLoaed:Bool = false
    var currentMode: String = "splash"
    var statusBarHidden = true
    
    // 뷰컨트롤러 시작
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createWebview()
        self.startWebview()
        self.showLaunchScreen()
    }
    
    // 웹뷰 초기설정 및 만들기
    func createWebview(){
        let config = WKWebViewConfiguration()
        config.userContentController = self.createWebviewController()
        webView = WKWebView(frame: CGRect(x: 0, y: 24, width: self.view.frame.width, height: self.view.frame.height-24), configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.view.addSubview(webView)
    }
    
    // 웹뷰 컨트롤러 만들기
    func createWebviewController() -> WKUserContentController{
        let contentController = WKUserContentController()
        contentController.add(self, name: "callbackHandler")
        return contentController
    }
    
    // 웹뷰의 시작 페이지 불러오기
    func startWebview(){
        urlString += self.addURLPrameters(urlString)
        let url = URL (string: urlString)
        let requestObj = URLRequest(url: url!);
        webView.load(requestObj)
    }
    
    // 웹뷰 컨트롤러
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            print("JavaScript is sending a message \(NSString(string: message.body as! String))")
        }
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if webView != self.webView {
            decisionHandler(.allow)
            return
        }
        let app: UIApplication = UIApplication.shared
        let url: URL = navigationAction.request.url!
        print("webview open \(url)")
        if (url.scheme != "http" && url.scheme != "https" && url.scheme != "about" && url.scheme != "javascript") {
            app.openURL(url)
            decisionHandler(.cancel)
            return
        } else if url.host == "itunes.apple.com" {
            print("url is itunes")
            app.openURL(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
    

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
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
    
  
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webviewLoaed = true;
        if(self.splashDidStop){
            self.removeSplashScreen()
        }
    }
    
    // 웹주소에 디바이스 정보추가
    func addURLPrameters(_ url:String) -> String{
        let deviceToken = InstanceID.instanceID().token()
        var parameters:String = "UserScreen=iphone_app&hwid="
        if deviceToken != nil {
            parameters += deviceToken!
        }
        var char:String = "?"
        if(url.range(of: "?") != nil){
            char = "&"
        }
        return char + parameters
    }
    
    // 푸시메세지에서 파라미터 가져오기
    func pushReceiver(_ notification: NSNotification){
        let userInfo: JSON = notification.object as! JSON
        let startURL = userInfo["start-url"]
        debugPrint("##############################> @17 \(userInfo)")
        if(startURL != JSON.null){
            urlString = startURL.stringValue + self.addURLPrameters(startURL.stringValue)
            webView.load(URLRequest(url: URL (string: urlString)!));
        }
    }
    
    // Gif 인트로화면 만들기
    func showLaunchScreen(){
        if self.currentMode == "splash" {
            let gifManager = SwiftyGifManager(memoryLimit: 20)
            let gifImage = UIImage(gifName: "intro")
        
            self.splashScreen = UIImageView(gifImage: gifImage, manager: gifManager, loopCount: 3)
            self.splashScreen.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
            self.splashScreen.center = self.view.center
            self.splashScreen.contentMode = UIViewContentMode.scaleAspectFit
            self.splashScreen.delegate = self
            self.splashBackground = UIImageView(frame: self.view.frame)
            self.splashBackground.backgroundColor = UIColor(red: 0.11, green: 0.25, blue: 0.13, alpha:1.0)
            self.view.addSubview(splashBackground)
            self.view.addSubview(self.splashScreen)
        }
    }
    
    // Gif 인트로 화면제거
    func removeSplashScreen(){
        if self.currentMode == "splash"{
        
            UIView.animate(withDuration: 0.5, animations: {
                self.splashScreen.alpha = 0
                self.splashBackground.alpha = 0
                self.webView.alpha = 1
            }, completion: { finished in
                self.splashBackground.removeFromSuperview()
                self.splashScreen.removeFromSuperview()
                self.statusBarHidden = false
                self.setNeedsStatusBarAppearanceUpdate()
                self.currentMode = "main"
            })
        }
    }
    
    
    // 웹뷰 활성화 될때
    override func viewWillAppear(_ animated: Bool) {
        self.statusBarHidden = true
//        debugPrint("##############################> \(Messaging.messaging().)")
        
//        NotificationCenter.default.addObserver(self, selector: #selector(self.pushReceiver), name: NSNotification.Name(rawValue: "aps"), object: nil)
    }
    
    // 웹뷰 비활성화 될때
    override func viewWillDisappear(_ animated: Bool) {
        self.showLaunchScreen()
//        NotificationCenter.default.removeObserver(self)
    }
    
    
    // 상태바 숨기기
    override var prefersStatusBarHidden: Bool{
        return self.statusBarHidden
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}

//Gif 인트로 진행체크
extension ViewController : SwiftyGifDelegate {
    func gifDidLoop(sender: UIImageView) {
        splashDidStop = true;
        if(self.webviewLoaed){
            self.removeSplashScreen()
        }
    }
    
   
}



