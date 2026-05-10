import XCTest

final class tattoeUITests: XCTestCase {

    let outDir = "/tmp/tattoe_screens"

    override func setUpWithError() throws {
        continueAfterFailure = false
        try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    }

    func save(_ name: String) {
        let img = XCUIScreen.main.screenshot()
        let url = URL(fileURLWithPath: "\(outDir)/\(name).png")
        try? img.pngRepresentation.write(to: url)
        print("[SAVED] \(name).png")
    }

    func shopJSON(type: String, actief: Bool, daysAgo: Double) -> String {
        let appleRef = 978307200.0
        let nowRef = Date().timeIntervalSince1970 - appleRef
        let regDate = nowRef - daysAgo * 86400
        return "{\"authMethod\":\"email\",\"appleUserID\":\"\",\"bedrijfsnaam\":\"Black Ink Studio\",\"kvk\":\"12345678\",\"btw\":\"NL123456789B01\",\"voornaam\":\"Jan\",\"achternaam\":\"de Vries\",\"email\":\"jan@blackink.nl\",\"wachtwoord\":\"Test1234\",\"telefoon\":\"0612345678\",\"straat\":\"Keizersgracht\",\"huisnummer\":\"123\",\"postcode\":\"1015 CJ\",\"woonplaats\":\"Amsterdam\",\"registratieDatum\":\(regDate),\"abonnementType\":\"\(type)\",\"abonnementActief\":\(actief)}"
    }

    func launch(shopState: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        if let s = shopState {
            app.launchEnvironment["SHOP_TEST_DATA"] = s
        }
        app.launch()
        Thread.sleep(forTimeInterval: 2)
        return app
    }

    func tapShop(_ app: XCUIApplication) {
        // Try by identifier first, then by label
        let byId = app.buttons["btn_shop"]
        let byLabel = app.buttons["SHOP"]
        if byId.waitForExistence(timeout: 5) { byId.tap() }
        else if byLabel.waitForExistence(timeout: 3) { byLabel.tap() }
        Thread.sleep(forTimeInterval: 2)
    }

    @MainActor
    func testShopFlow() throws {

        // 1. Main screen
        let app0 = launch()
        save("00_main")
        tapShop(app0)
        save("01_shop_login")
        app0.terminate()

        // 2. Plan selection (logged in, no plan chosen)
        let app2 = launch(shopState: shopJSON(type: "", actief: false, daysAgo: 1))
        tapShop(app2)
        // Plan cards should be visible
        let planKnop = app2.buttons["plan_knop_starter"]
        if planKnop.waitForExistence(timeout: 5) {
            save("02_plan_kiezen")
            app2.swipeUp()
            Thread.sleep(forTimeInterval: 1)
            save("02b_plan_enterprise")
            app2.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            planKnop.tap()
            Thread.sleep(forTimeInterval: 2.5)
            save("03_after_plan_choice")
        } else {
            print("[WARN] plan_knop_starter not found")
            save("02_debug")
        }
        app2.terminate()

        // 3. Mode keuze (studio, in trial)
        let app3 = launch(shopState: shopJSON(type: "studio", actief: false, daysAgo: 1))
        tapShop(app3)
        let btnBeheren = app3.buttons["btn_beheren"]
        let btnAlsKlant = app3.buttons["btn_als_klant"]
        if btnAlsKlant.waitForExistence(timeout: 5) {
            save("04_mode_keuze")
            btnBeheren.tap()
            Thread.sleep(forTimeInterval: 2)
            save("05_dashboard")
        } else {
            print("[WARN] btn_als_klant not found")
            save("04_debug")
        }
        app3.terminate()

        // 4. Als Klant view
        let app4 = launch(shopState: shopJSON(type: "studio", actief: false, daysAgo: 1))
        tapShop(app4)
        if app4.buttons["btn_als_klant"].waitForExistence(timeout: 5) {
            app4.buttons["btn_als_klant"].tap()
            Thread.sleep(forTimeInterval: 2)
            save("06_als_klant")
        }
        app4.terminate()

        // 5. Verlopen (trial expired, no payment)
        let app5 = launch(shopState: shopJSON(type: "pro", actief: false, daysAgo: 32))
        tapShop(app5)
        Thread.sleep(forTimeInterval: 1)
        save("07_verlopen")
        app5.terminate()
    }
}
