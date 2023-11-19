//
//  MyWebView.swift
//  swiftUITest
//
//  Created by 장우영 on 10/23/23.
//

import SwiftUI
import WebKit
import AVFoundation
import Contacts

struct MyWebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.translatesAutoresizingMaskIntoConstraints = false // AutoLayout을 사용하여 웹 뷰 크기 조정

        // 뷰의 서브뷰로 추가
        if let rootView = UIApplication.shared.windows.first?.rootViewController?.view {
            rootView.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: rootView.topAnchor),
                webView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
            ])
        }
        
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
        contentController.add(self.makeCoordinator(), name: "getCameraPermission")
        contentController.add(self.makeCoordinator(), name: "contactsExtraction") // 주소록 추출 컨트롤러 추가

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
                case "getCameraPermission":
                    handleGetCameraPermission(webView: webView)
                case "contactsExtraction":
                    handleContactsExtraction(webView: webView)
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
        
        func handleGetCameraPermission(webView: WKWebView) {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    // 카메라 접근 권한이 허용된 경우
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "알림", message: "카메라 접근 권한이 허가되었습니다.", preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            let response = WebViewResponse(ok: true, data: "", message: "카메라 접근 권한이 허가되었습니다.")
                            self.executeJavaScript(response, in: webView)
                        })
                        
                        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                            rootViewController.present(alertController, animated: true, completion: nil)
                        }
                    }
                } else {
                    // 카메라 접근 권한이 거부된 경우
                    DispatchQueue.main.async {
                        let alertController = UIAlertController(title: "알림", message: "카메라 접근 권한이 거부되었습니다. 설정에서 권한을 허용해주세요.", preferredStyle: .alert)

                        alertController.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                            // 설정 앱을 열어 권한 설정 페이지로 이동
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                            }

                            let response = WebViewResponse(ok: false, data: "", message: "카메라 접근 권한이 거부되었습니다.")
                            self.executeJavaScript(response, in: webView)
                        })

                        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                            rootViewController.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        
        // 주소록 데이터 추출 함수
        func handleContactsExtraction(webView: WKWebView) {
            var contacts: [ContactInfo] = []

            // 백그라운드 스레드에서 주소록 데이터 추출
            DispatchQueue.global().async {
                let store = CNContactStore()
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactOrganizationNameKey, CNContactJobTitleKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])

                do {
                    try store.enumerateContacts(with: request) { contact, _ in
                        var contactInfo = ContactInfo(
                            name: "\(contact.familyName)\(contact.givenName)",
                            phoneNumber: contact.phoneNumbers.first?.value.stringValue ?? "",
                            org: contact.organizationName,
                            title: contact.jobTitle
                        )

                        contacts.append(contactInfo)
                    }

                    // 결과를 JavaScript로 전달
                    let response = WebViewResponse(ok: true, data: contacts, message: nil)
                    
                    // 메인 스레드에서 JavaScript 실행
                    DispatchQueue.main.async {
                        self.executeJavaScript(response, in: webView)
                    }
                } catch {
                    // 주소록 데이터 추출 실패 시 오류 메시지를 JavaScript로 전달
                    let response = WebViewResponse(ok: false, data: "", message: "주소록 데이터 추출 실패")
                    
                    // 메인 스레드에서 JavaScript 실행
                    DispatchQueue.main.async {
                        self.executeJavaScript(response, in: webView)
                    }
                }
            }
        }
        
        func executeJavaScript<T: Codable>(_ response: WebViewResponse<T>, in webView: WKWebView) {
            if let jsonData = try? JSONEncoder().encode(response),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                DispatchQueue.main.async {
                    webView.evaluateJavaScript("responseNative(\(jsonString));", completionHandler: nil)
                }
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

struct ContactInfo: Codable {
    var name: String
    var phoneNumber: String
    var org: String?
    var title: String?
}

struct WebViewResponse<T: Codable>: Codable {
    let ok: Bool
    let data: T?
    let message: String?
}
