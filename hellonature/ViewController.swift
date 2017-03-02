//
//  TosController.swift
//  getcha
//
//  Updated by jeenoo on 2017. 02. 21..
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
//    var webView: UIWebView!
    var webView: WKWebView!
    var urlString: String!
    var splashScreen: UIImageView!
    var splashBackground: UIView!
    var splashDidStop: Bool = false
    var webviewLoaed:Bool = false
    var deviceToken: String = ""
    var currentMode: String = "splash"
    var statusBarHidden = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if FIRInstanceID.instanceID().token() != nil {
            deviceToken = FIRInstanceID.instanceID().token()!
        }
        
        print("========================>deviceToken: \(deviceToken)")
        
        let contentController = WKUserContentController()
//        let userScript = WKUserScript(
//            source: "redHeader()",
//            injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
//            forMainFrameOnly: true
//        )
//        contentController.addUserScript(userScript)
        
        contentController.add(self, name: "callbackHandler")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        webView = WKWebView(frame: CGRect(x: 0, y: 24, width: self.view.frame.width, height: self.view.frame.height-24), configuration: config)

        if urlString == nil {
            urlString = "http://www.hellonature.net/mobile_shop/?UserScreen=iphone_app&hwid=" + deviceToken
        }
        
        let url = URL (string: urlString!)
        let requestObj = URLRequest(url: url!);
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.load(requestObj)
//        webView.alpha = 0
        print("webView load")
//      webView.delegate = self


        self.view.addSubview(webView)
        self.showLaunchScreen()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
//            print("JavaScript is sending a message \(NSString(string: message.body as! String))")
            //let tags : [NSObject : AnyObject] = [NSString(string: "userId") : NSString(string: message.body as! String)]
            //PushNotificationManager.pushManager().setTags(tags)
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
            print("webview open scheme \(url.scheme)")
//            if app.canOpenURL(url) {
                app.openURL(url)
                decisionHandler(.cancel)
                return
//            }
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
    
    
//    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
//        if let url = request.URL where (url.scheme == "ios") {
//            
//            let tags : [NSObject : AnyObject] = [NSString(string: "userId") : NSString(string: url.absoluteString.stringByReplacingOccurrencesOfString("ios://", withString: ""))]
//            PushNotificationManager.pushManager().setTags(tags)
//            webView.goBack();
//            return false
//        } else {
//            return true
//        }
//    }
    
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
    
//    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
////        print("DIDSTART \(webView.URL)")
//    }
    
//    override var prefersStatusBarHidden : Bool {
//        return false
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("viewWillAppear")
        self.statusBarHidden = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushReceiver), name: NSNotification.Name(rawValue: "aps"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.showLaunchScreen()
        NotificationCenter.default.removeObserver(self)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webviewLoaed = true;
        if(self.splashDidStop){
            self.removeSplashScreen()
        }
    }

    func pushReceiver(_ notification: NSNotification){
        let userInfo: JSON = notification.object as! JSON
        let startURL = userInfo["start-url"]
        if(startURL != JSON.null){
            urlString = startURL.stringValue + "?hwid=" + deviceToken
            webView.load(URLRequest(url: URL (string: urlString!)!));
        }
    }
    
    /*
    func showLaunchScreen() {
        var animation: CAKeyframeAnimation
        var images:[UIImage] = []
        for i in 1...61{
            images.append(UIImage(named: "splash00\(String(format: "%02d", i))")!)
        }
        
        animation = CAKeyframeAnimation(keyPath: "contents")
        animation.calculationMode = kCAAnimationDiscrete
        animation.duration = 2.0
        animation.values = images.map{ $0.cgImage as Any }
        animation.repeatCount = 1
        animation.isRemovedOnCompletion = false
        animation.delegate = self

        self.splashBackground = UIImageView(frame: self.view.frame)
        self.splashBackground.backgroundColor = UIColor(red: 0.11, green: 0.25, blue: 0.13, alpha:1.0)
        
        self.splashScreen = UIImageView(frame: self.view.frame)
        self.splashScreen.image = images.last
        
        self.splashScreen.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        self.splashScreen.center = self.view.center
        self.splashScreen.contentMode = UIViewContentMode.scaleAspectFit
        self.splashScreen.layer.add(animation, forKey: "animation")

        self.view.addSubview(splashBackground)
        self.view.addSubview(self.splashScreen)

    }
     */
    
    func showLaunchScreen(){
        if self.currentMode == "splash" {
            let gifManager = SwiftyGifManager(memoryLimit: 20)
            let gifImage = UIImage(gifName: "intro")
        
            self.splashScreen = UIImageView(gifImage: gifImage, manager: gifManager, loopCount: 1)
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
    
    func removeSplashScreen(){
        print("###############\(self.currentMode)")
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
    
    override var prefersStatusBarHidden: Bool{
        return self.statusBarHidden
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


extension ViewController : SwiftyGifDelegate {
    func gifDidLoop() {
        splashDidStop = true;
        if(self.webviewLoaed){
            self.removeSplashScreen()
        }
    }
}



