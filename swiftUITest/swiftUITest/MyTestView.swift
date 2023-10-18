//
//  MyTestView.swift
//  swiftUITest
//
//  Created by 장우영 on 10/18/23.
//

import SwiftUI

struct MyTestView: View {
    
    @State
    private var index: Int = 0
    
    private let backgroundColors = [
        Color.red,
        Color.yellow,
        Color.orange,
        Color.green,
        Color.blue
    ]
    
    var body: some View {
        VStack{
            Text("배경 아이템 인덱스 \(self.index)")
                .font(.system(size: 30))
                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
        }.background(backgroundColors[index])
            .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            .onTapGesture {
                print("배경아이템 클릭됨.")
                if(self.index == self.backgroundColors.count - 1){
                    self.index = 0
                }
                else{
                    self.index += 1
                }
            }
    }
}

struct MyTestView_Previews: PreviewProvider {
    static var previews: some View {
        MyTestView()
    }
}
