
describe("Main window", function() {

  var target = UIATarget.localTarget(), app = target.frontMostApp(), mainWindow = app.mainWindow();
  
  it("should have one scroll view for tabs content", function() {
    expect(mainWindow.scrollViews()["tabs scrollview"]).not.toBeNull();
  });
  
  describe("tab content", function() {
    
    var tabsScrollView = mainWindow.scrollViews()["tabs scrollview"];
    
    it("should have a default top tool bar", function() {
      expect(tabsScrollView.elements()["default toolbar"]).not.toBeNull();
    });
    
    describe("default toolbar", function() {
      
      var defaultToolbar = tabsScrollView.elements()["default toolbar"];
      
      it("should have at least 3 buttons", function() {
        expect(defaultToolbar.buttons().length >= 3).toBeTruthy();
      });
      
      it("should have a back button", function() {
        expect(defaultToolbar.buttons()["Back"]).not.toBeNull();
      });

      it("should have a forward button", function() {
        expect(defaultToolbar.buttons()["Forward"]).not.toBeNull();
      });
      
    });
    
  });
  
});
