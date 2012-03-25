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
  
  describe("when existing", function() {
    
    var fileBrowser = tabsScrollView.tableViews()["file browser"]
    
    it("should have a number of cells", function() {
      expect(fileBrowser.cells().length).not.toEqual(0);
    });
    
  });
    
});