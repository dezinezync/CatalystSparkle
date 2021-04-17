//
//  EmptyView.swift
//  UnreadsWidgetExtension
//
//  Created by Nikhil Nigade on 17/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

import SwiftUI

struct EmptyView: View {
    
    var title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: nil, content: {
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
        })
    }
}

struct EmptyView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView(title: "No new unread articles")
    }
}
