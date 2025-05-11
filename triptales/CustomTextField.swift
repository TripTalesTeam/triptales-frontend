//
//  CustomTextField.swift
//  triptales
//
//  Created by Jirasak on 11/5/2568 BE.
//


import SwiftUI

struct CustomTextField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.black)

            TextField("", text: $text)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
        }
    }
}
