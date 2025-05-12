//
//  HeaderView.swift
//  triptales
//
//  Created by Jirasak on 11/5/2568 BE.
//


import SwiftUI

struct HeaderView: View {
    var title: String
    var onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .padding()
            }

            Spacer()

            Text(title)
                .font(.headline)
                .foregroundColor(.black)

            Spacer()

            Image("")
                .foregroundColor(.black)
                .padding()
        }
        .background(Color.white)
    }
}
