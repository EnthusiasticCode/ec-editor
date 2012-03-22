#import "../../ThirdParty/jasmine/JasmineStyleUIAutomationTests/jasmine-uiautomation.js"
#import "../../ThirdParty/jasmine/JasmineStyleUIAutomationTests/jasmine/lib/jasmine-core/jasmine.js"
#import "../../ThirdParty/jasmine/JasmineStyleUIAutomationTests/jasmine-uiautomation-reporter.js"

#import "ui-main-window-spec.js"
#import "ui-projects-list-spec.js"

jasmine.getEnv().addReporter(new jasmine.UIAutomation.Reporter());
jasmine.getEnv().execute();