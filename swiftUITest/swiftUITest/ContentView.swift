import SwiftUI
import WebKit

struct ContentView: View {
    
    @State
    private var isActivated: Bool = false
    
    var body: some View {
        NavigationView{
            VStack {
                HStack {
                    MyView(isActivated: $isActivated)
                    MyView(isActivated: $isActivated)
                }.padding(isActivated ? 50.0 : 10.0)
                    .background(isActivated ? Color.yellow : Color.black)
                    .onTapGesture {
                        print("HStack 이 클릭됨.")
                        withAnimation{
                            self.isActivated.toggle()
                        }
                    }
                NavigationLink(destination: MyTestView()) {
                    Text("네비게이션")
                        .fontWeight(.heavy)
                        .font(.system(size: 30))
                        .padding()
                        .background(Color.black)
                        .cornerRadius(30)
                }.padding(.top, 50)
                NavigationLink(destination: MyWebView(urlString: "http://61.109.169.166:9001/")) {
                    Text("웹")
                        .fontWeight(.heavy)
                        .font(.system(size: 30))
                        .padding()
                        .background(Color.black)
                        .cornerRadius(30)
                }.padding(.top, 50)
            }
        }
    }
}

// 프리뷰
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct MyView: View {
    
    @Binding
    var isActivated: Bool
    
    // 처음 값 설정
    init(isActivated: Binding<Bool> = .constant(true)) {
        _isActivated = isActivated
    }
    
    var body: some View {
        Text("클릭!")
            .fontWeight(.bold)
            .font(.system(size: 60))
            .background(self.isActivated ? Color.green : Color.red)
    }
}
