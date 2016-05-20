//
//  TosController.swift
//  getcha
//
//  Created by james on 2015. 7. 7..
//  Copyright (c) 2015년 INSOMENIA. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
//    var webView: UIWebView!
    var webView: WKWebView!
    var urlString: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let contentController = WKUserContentController();
//        let userScript = WKUserScript(
//            source: "redHeader()",
//            injectionTime: WKUserScriptInjectionTime.AtDocumentStart,
//            forMainFrameOnly: true
//        )
//        contentController.addUserScript(userScript)
        
        contentController.addScriptMessageHandler(self, name: "callbackHandler")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: CGRectMake(0, 0, self.view.frame.width, self.view.frame.height), configuration: config)
        
        if urlString == nil {
            urlString = "http://www.hellonature.net/mobile_shop/?UserScreen=iphone_app&hwid=\(PushNotificationManager.pushManager().getHWID())"
//            urlString = "http://typer.insomenia.com/test.html"
        }
        
        
        let url = NSURL (string: urlString!)
        let requestObj = NSURLRequest(URL: url!);
        webView.navigationDelegate = self
        webView.UIDelegate = self
        webView.loadRequest(requestObj);
//        webView.delegate = self

        self.view.addSubview(webView)
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
//            print("JavaScript is sending a message \(NSString(string: message.body as! String))")
            let tags : [NSObject : AnyObject] = [NSString(string: "userId") : NSString(string: message.body as! String)]
            PushNotificationManager.pushManager().setTags(tags)
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        
        if webView != self.webView {
            decisionHandler(.Allow)
            return
        }
        let app: UIApplication = UIApplication.sharedApplication()
        let url: NSURL = navigationAction.request.URL!
        print("webview open \(url)")
        if (url.scheme != "http" && url.scheme != "https" && url.scheme != "about" && url.scheme != "javascript") {
            print("webview open scheme \(url.scheme)")
//            if app.canOpenURL(url) {
                app.openURL(url)
                decisionHandler(.Cancel)
                return
//            }
        } else if url.host == "itunes.apple.com" {
            print("url is itunes")
            app.openURL(url)
            decisionHandler(.Cancel)
            return
        }
        decisionHandler(.Allow)
    }
    

    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.loadRequest(navigationAction.request)
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
    
    func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        let alertController = UIAlertController(title: message, message: nil,
                                                preferredStyle: UIAlertControllerStyle.Alert);
        
        alertController.addAction(UIAlertAction(title: "확인", style: UIAlertActionStyle.Cancel) {
            _ in completionHandler()}
        );
        
        self.presentViewController(alertController, animated: true, completion: {});
    }
    
//    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
////        print("DIDSTART \(webView.URL)")
//    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    
    
}
