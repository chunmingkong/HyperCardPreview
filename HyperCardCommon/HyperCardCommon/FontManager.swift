//
//  FontManager.swift
//  HyperCard
//
//  Created by Pierre Lorenzi on 03/03/2017.
//  Copyright © 2017 Pierre Lorenzi. All rights reserved.
//


public class FontManager {
    
    private let resources: ResourceSystem
    
    private var cachedFonts: [FontDescriptor: BitmapFont]
    
    public init(resources: ResourceSystem) {
        self.resources = resources
        cachedFonts = [:]
    }
    
    public func findFont(withIdentifier identifier: Int, size: Int, style: TextStyle) -> BitmapFont {
        
        /* Look in the cache */
        let descriptor = FontDescriptor(identifier: identifier, size: size, style: style)
        if let cachedFont = cachedFonts[descriptor] {
            return cachedFont
        }
        
        /* Build it */
        let font = retrieveFont(forDescriptor: descriptor)
        cachedFonts[descriptor] = font
        return font
        
    }
    
    private func retrieveFont(forDescriptor descriptor: FontDescriptor) -> BitmapFont {
        
        /* Look for the font family */
        guard let familyResource = resources.findResource(ofType: ResourceTypes.fontFamily, withIdentifier: descriptor.identifier) else {
            return findAnyFont(forDescriptor: descriptor)
        }
        
        /* Check if a bitmap font with the right parameters is available */
        let family = familyResource.content
        if let existingFamilyFont = family.bitmapFonts.first(where: { $0.size == descriptor.size && $0.style == descriptor.style }) {
            return existingFamilyFont.font
        }
        
        /* If the style is not plain, look for a plain version on which to apply the style */
        if descriptor.style != PlainTextStyle {
            let plainDescriptor = FontDescriptor(identifier: descriptor.identifier, size: descriptor.size, style: PlainTextStyle)
            let plainFont = retrieveFont(forDescriptor: plainDescriptor)
            return FontDecorating.decorateFont(from: plainFont, with: descriptor.style, in: family)
        }
        
        /* Look for a vector font */
        if let plainVectorFont = family.vectorFonts.first(where: { $0.style == PlainTextStyle }) {
            return VectorFontConverting.convertVectorFont(CTFontCreateWithGraphicsFont(plainVectorFont.font, CGFloat(descriptor.size), nil, nil))
        }
        
        /* We can't do anything, just return whatever font */
        NSLog("Unavailable font family: %d", descriptor.identifier)
        return findAnyFont(forDescriptor: descriptor)
    }
    
    private func findAnyFont(forDescriptor descriptor: FontDescriptor) -> BitmapFont {
        
        return findFont(withIdentifier: UsualIdentifiers.geneva, size: descriptor.size, style: descriptor.style)
    }
    
    public enum UsualIdentifiers {
        public static let chicago = 0
        public static let newYork = 2
        public static let geneva = 3
        public static let monaco = 4
        public static let venice = 5
        public static let london = 6
        public static let athens = 7
        public static let sanFrancisco = 8
        public static let cairo = 11
        public static let losAngeles = 12
        public static let palatino = 16
        public static let times = 20
        public static let helvetica = 21
        public static let courier = 22
        public static let symbol = 23
        public static let charcoal = 2002
    }
    
}



private struct FontDescriptor: Equatable, Hashable {
    public var identifier: Int
    public var size: Int
    public var style: TextStyle
    
    public init(identifier: Int, size: Int, style: TextStyle) {
        self.identifier = identifier
        self.size = size
        self.style = style
    }
    
    public var hashValue: Int {
        var hash = identifier &* 31 ^ size
        hash = style.bold ? hash << 3 ^ 80 : hash
        hash = style.italic ? hash << 3 ^ 70 : hash
        hash = style.underline ? hash << 3 ^ 60 : hash
        hash = style.shadow ? hash << 3 ^ 50 : hash
        hash = style.outline ? hash << 3 ^ 40 : hash
        hash = style.condense ? hash << 3 ^ 30 : hash
        hash = style.extend ? hash << 3 ^ 20 : hash
        hash = style.group ? hash << 3 ^ 10 : hash
        return hash
    }
    
    public static func ==(f1: FontDescriptor, f2: FontDescriptor) -> Bool {
        return f1.identifier == f2.identifier && f1.size == f2.size && f1.style == f2.style
    }
}

