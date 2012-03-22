
describe("Projects list", function() {
  
  var target = UIATarget.localTarget(), app = target.frontMostApp(), mainWindow = app.mainWindow();  
  var tabsScrollView = mainWindow.scrollViews()["tabs scrollview"];

  it("should exists", function() {
    expect(tabsScrollView.elements()["projects grid"]).not.toBeNull();
  });
  
  describe("default toolbar", function() {
  
    var defaultToolbar = tabsScrollView.elements()["default toolbar"]
      , backButton = defaultToolbar.buttons()["Back"]
      , forwardButton = defaultToolbar.buttons()["Forward"];
    
    it("back button should be disabled", function() {
      expect(backButton.isEnabled()).toBeFalsy();
    });
    
    it("should have an 'Add' button", function() {
      expect(defaultToolbar.buttons()["Add"]).not.toBeNull();
    });
    
    it("should show a popover when tapping the 'Add' button", function() {
      defaultToolbar.buttons()["Add"].tap();
      target.delay(1);
      expect(mainWindow.popover()).not.toBeNull();
      if (mainWindow.popover())
        mainWindow.popover().dismiss();
    });
    
    describe("new project popover", function() {
      
      var popover;
      
      beforeEach(function() {
        defaultToolbar.buttons()["Add"].tap();
        target.delay(1);
        popover = mainWindow.popover();
      });
      
      afterEach(function() {
        popover.dismiss();
      });
      
      it("should have 2 buttons (create and import)", function() {
        expect(popover.buttons().length).toEqual(2);
        expect(popover.buttons()["Create new project"]).not.toBeNull();
        expect(popover.buttons()["Import from iTunes"]).not.toBeNull();
      });
      
    });
    
  });
  
  describe("when existing", function() {
    
    var projectsGrid = tabsScrollView.elements()["projects grid"];
    
    describe("according to setup", function() {
      
      it("should have 1 element", function() {
        expect(projectsGrid.elements().length).toEqual(1);
      });
      
      it("should have the 'Test' element", function() {
        expect(projectsGrid.elements()["Test"]).not.toBeNull();
      });
      
    });
    
  });
  
});
