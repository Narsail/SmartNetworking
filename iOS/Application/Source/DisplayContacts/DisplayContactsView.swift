//
//  DisplayContactsView.swift
//  iOS Application
//
//  Created by Moeller David on 3/11/19.
//  Copyright © 2019 David Moeller. All rights reserved.
//

import Foundation
import SwiftUI

struct DisplayContactsView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
            }
            .navigationBarTitle("Contacts")
            .navigationBarItems(trailing:
                Button(action: {
                    print("Add contacts")
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                        .font(.title)
                }
            )
        }
    }
}
