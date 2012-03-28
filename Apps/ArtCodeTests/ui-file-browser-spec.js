describe("File browser", function() {
  
  var target = UIATarget.localTarget(), app = target.frontMostApp(), mainWindow = app.mainWindow();  
  var tabsScrollView = mainWindow.scrollViews()["tabs scrollview"];
  var defaultToolbar = tabsScrollView.elements()["default toolbar"]
    , backButton = defaultToolbar.buttons()["Back"]
    , forwardButton = defaultToolbar.buttons()["Forward"];
  var importedProjectName = "ImportedProject";
  
  it("can be accessed for " + importedProjectName, function() {
    var projectElement = tabsScrollView.elements()["projects grid"].elements()[importedProjectName];
    expect(projectElement.isValid()).toBeTruthy();
    projectElement.tap();
    target.delay(2);
    expect(tabsScrollView.tableViews()["file browser"].checkIsValid()).toBeTruthy();
  });
    
  describe("table", function() {
    
    it("should have a number of cells", function() {
      expect(tabsScrollView.tableViews()["file browser"].cells().length).not.toEqual(0);
    });
    
    it("should have cells ordered by label", function() {
      var cells = tabsScrollView.tableViews()["file browser"].cells();
      var cellsLength = cells.length - 1;
      var lastLabel = "";
      var ordered = true;
      do {
        ordered = cells[cellsLength].label() >= lastLabel;
        lastLabel = cells[cellsLength].label();
      } while(ordered && --cellsLength >= 0);
      expect(ordered).toBeTruthy();
    });
    
  });
  
  describe("default toolbar", function() {
    
    it("should have an add button", function() {
      expect(defaultToolbar.buttons()["Add file or folder"].checkIsValid()).toBeTruthy();
    });
    
    describe("add button", function() {
      
      var popover;
      
      beforeEach(function() {
        defaultToolbar.buttons()["Add file or folder"].tap();
        target.delay(.5);
        popover = mainWindow.popover();
      });
      
      afterEach(function() {
        if (popover.isValid()) {
          popover.dismiss();
        }
      });
      
      it("should open a popover", function() {
        expect(popover.checkIsValid()).toBeTruthy();
      });
      
    });
    
  });
    
});