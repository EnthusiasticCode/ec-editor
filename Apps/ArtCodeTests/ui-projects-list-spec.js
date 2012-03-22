
describe("Projects list", function() {
  
  var target = UIATarget.localTarget(), app = target.frontMostApp(), mainWindow = app.mainWindow();  
  var tabsScrollView = mainWindow.scrollViews()["tabs scrollview"]
    , defaultToolbar = tabsScrollView.elements()["default toolbar"]
    , backButton = defaultToolbar.buttons()["Back"]
    , forwardButton = defaultToolbar.buttons()["Forward"];

  it("should exists", function() {
    expect(tabsScrollView.elements()["projects grid"]).not.toBeNull();
  });
  
  describe("when existing", function() {
    
    var projectsGrid = tabsScrollView.elements()["projects grid"];
    
    describe("according to setup", function() {
      
      it("the back button should be disabled", function() {
        expect(backButton.isEnabled()).toBeFalsy();
      });
      
      it("should have 1 element", function() {
        expect(projectsGrid.elements().length).toEqual(1);
      });
      
      it("should have the 'Test' element", function() {
        expect(projectsGrid.elements()["Test"]).not.toBeNull();
      });
      
    });
    
  });
  
});
