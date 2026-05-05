import SwiftUI

public enum MMSpacing {
    public static let xxs: CGFloat = 4
    public static let xs:  CGFloat = 8
    public static let sm:  CGFloat = 12
    public static let md:  CGFloat = 16
    public static let lg:  CGFloat = 20
    public static let xl:  CGFloat = 24
    public static let xxl: CGFloat = 32
    public static let xxxl: CGFloat = 48
}

public enum MMRadius {
    public static let xs:    CGFloat = 4
    public static let sm:    CGFloat = 8
    public static let md:    CGFloat = 10
    public static let lg:    CGFloat = 12
    public static let xl:    CGFloat = 14
    public static let xxl:   CGFloat = 16
    public static let xxxl:  CGFloat = 18
    public static let pill:  CGFloat = 28
}

public enum MMMotion {
    public static let fast     = Animation.easeOut(duration: 0.15)
    public static let standard = Animation.easeOut(duration: 0.25)
    public static let slow     = Animation.easeInOut(duration: 0.40)
    public static let spring   = Animation.spring(response: 0.45, dampingFraction: 0.8)
}
