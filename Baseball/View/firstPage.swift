//
//  firstPage.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct firstPage: View {
    @State private var isLaunch: Bool = false
    var body: some View {
        VStack{
            if isLaunch{
                SignIn()
            } else{
                VStack{
                    Text("누구나 야구를")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                .transition(.opacity)
                .onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                        withAnimation{
                            isLaunch = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    firstPage()
}
