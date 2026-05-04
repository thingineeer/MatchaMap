import Foundation

public extension AppUser {
    /// Preview/Test 픽스처. 의도된 더미 값.
    static func fixture(
        uid: String = "test-uid",
        displayName: String = "MatchaFan",
        homeCountry: Country = Country(rawValue: "KR")!,
        country: Country? = Country(rawValue: "KR")!,
        authMethod: AuthMethod = .apple
    ) -> AppUser {
        let now = Date(timeIntervalSince1970: 1_780_000_000)
        return AppUser(
            uid: uid,
            displayName: displayName,
            photoURL: nil,
            locale: "ko-KR",
            homeCountry: homeCountry,
            country: country,
            cohortD0: now,
            authMethod: authMethod,
            stats: .zero,
            createdAt: now,
            updatedAt: now
        )
    }
}
