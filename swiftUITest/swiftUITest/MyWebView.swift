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
        
        // ios salesKit으로 접속했는지 파악하도록 웹에 전달
        webView.evaluateJavaScript("navigator.userAgent"){(result, error) in
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
        
        contentController.add(self.makeCoordinator(), name: "contactsExtraction")
        
        configuration.userContentController = contentController
        return configuration
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: MyWebView
        var webView: WKWebView?
        
        init(_ parent: MyWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if let webView = message.webView, message.name == "nativeFunction", let bodyString = message.body as? String {
                DispatchQueue.main.async {
                    self.showAlert(message: bodyString, webView: webView)
                }
            }
        }
        
        private func showAlert(message: String, webView: WKWebView) {
            let alertController = UIAlertController(title: "Message from Web", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // After alert is dismissed, send the WebViewResponse back to the web page
                let response = WebViewResponse(ok: true, data: "[{\"name\":\"Qqq\",\"phoneNumber\":\"010-2629-4884\",\"org\":\"인지소ㅍㅌ\",\"title\":\"직위\"},{\"name\":\"ㅂㅂㅈㄷ교ㅗㅜ\",\"phoneNumber\":\"010-9090-9090\",\"org\":null,\"title\":null}]", message: nil)
                
                // Encode the WebViewResponse to JSON
                if let jsonData = try? JSONEncoder().encode(response),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    let jsCode = "responseNative(\(jsonString));"
                    webView.evaluateJavaScript(jsCode, completionHandler: nil)
                }
            })
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                rootViewController.present(alertController, animated: true, completion: nil)
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
