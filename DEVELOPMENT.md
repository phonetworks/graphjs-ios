## Development Guidelines

 - https://swift.org/documentation/api-design-guidelines/

## Environment setup

 - http://developer.apple.com/downloads/

### How to open project

 - Open Xcode
 - Main menu: File -> Open...
 - Go through simple wizard
 - Done

### How to run unit tests

 - Select `GraphJSTests` schema
 - Command+U

OR

 - Open terminal & switch to project directory
 - Run `xcodebuild -project GraphJS-iOS.xcodeproj -scheme GraphJSTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone X,OS=11.4'`
