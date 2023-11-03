//
//  MyWebView.swift
//  swiftUITest
//
//  Created by 장우영 on 10/23/23.
//

import SwiftUI
import WebKit

struct MyWebView: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.navigationDelegate = context.coordinator
        
        // 디버깅
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        
        // iOS salesKit으로 접속했는지 파악하도록 웹에 전달
        webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
            let originUserAgent = result as! String
            let agent = originUserAgent + " saleskit_ios_app"
            webView.customUserAgent = agent
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func makeConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // 자바스크립트 컨트롤러 추가
        contentController.add(self.makeCoordinator(), name: "showAlertDialog")
        contentController.add(self.makeCoordinator(), name: "testAPI")
        
        configuration.userContentController = contentController
        return configuration
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MyWebView
        var webView: WKWebView?
        
        init(_ parent: MyWebView) {
            self.parent = parent
        }
        
        // 자바스크립트 컨트롤러 추가
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let webView = message.webView {
                switch message.name {
                case "showAlertDialog":
                    handleAlertDialog(webView: webView, bodyString: message.body as? String)
                case "testAPI":
                    handleTestAPI(webView: webView, bodyString: message.body as? String)
                default:
                    break
                }
            }
        }
        
        func handleAlertDialog(webView: WKWebView, bodyString: String?) {
            if let bodyString = bodyString {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "알림", message: bodyString, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        let response = WebViewResponse(ok: true, data: "UIAlertAction", message: nil)
                        self.executeJavaScript(response, in: webView)
                    })
                    
                    if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                        rootViewController.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
        
        func handleTestAPI(webView: WKWebView, bodyString: String?) {
            if let bodyString = bodyString,
               let jsonData = bodyString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let boolValue = json["bool"] as? Bool {
                
                let secondValue = json["second"] as? Int ?? 0
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(secondValue)) {
                    var messageText = "iOS 다이얼로그 예제입니다.\n"
                    messageText += boolValue ? "참 호출됨" : "거짓 호출됨"
                    let alertController = UIAlertController(title: "알림", message: messageText, preferredStyle: .alert)
                    
                    alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        let response = WebViewResponse(ok: true, data: "UIAlertAction22", message: nil)
                        self.executeJavaScript(response, in: webView)
                    })
                    
                    if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                        rootViewController.present(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
        
        func executeJavaScript(_ response: WebViewResponse, in webView: WKWebView) {
            if let jsonData = try? JSONEncoder().encode(response),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                webView.evaluateJavaScript("responseNative(\(jsonString));", completionHandler: nil)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            self.webView = webView
        }
    }
}

struct MyWebView_Previews: PreviewProvider {
    static var previews: some View {
        MyWebView(urlString: "https://www.example.com")
    }
}

struct WebViewResponse: Codable {
    let ok: Bool
    let data: String?
    let message: String?
}
