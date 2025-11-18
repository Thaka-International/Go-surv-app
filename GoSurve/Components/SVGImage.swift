//
//  SVGImage.swift
//  Go-serve
//
//  Helper to load and display SVG images
//

import SwiftUI
import UIKit

struct SVGImage: View {
    let name: String
    var size: CGSize = CGSize(width: 24, height: 24)
    var tintColor: Color? = nil
    
    var body: some View {
        Group {
            if let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(tintColor != nil ? .template : .original)
                    .foregroundColor(tintColor)
            } else {
                // Fallback to SF Symbol if SVG not found
                Image(systemName: fallbackIcon)
                    .foregroundColor(tintColor)
            }
        }
        .frame(width: size.width, height: size.height)
    }
    
    private var fallbackIcon: String {
        switch name {
        case "cube_1972564", "cube":
            return "cube.transparent.fill"
        case "ticket_1179587", "ticket":
            return "ticket.fill"
        case "home_2040463", "home":
            return "house.fill"
        case "settings_1947805", "settings":
            return "gearshape.fill"
        case "priority_8681379", "priority":
            return "exclamationmark.circle.fill"
        case "hologram_9539613", "hologram":
            return "cube.box.fill"
        default:
            return "photo"
        }
    }
}

