var newProjectName = "NewProject";
var importedProjectName = "ImportedProject";

describe("Projects list", function() {
  
  var target = UIATarget.localTarget(), app = target.frontMostApp(), mainWindow = app.mainWindow();  
  var tabsScrollView = mainWindow.scrollViews()["tabs scrollview"];

  it("should exists", function() {
    expect(tabsScrollView.elements()["projects grid"].isValid()).toBeTruthy();
  });
  
  describe("default toolbar", function() {
  
    var defaultToolbar = tabsScrollView.elements()["default toolbar"]
      , backButton = defaultToolbar.buttons()["Back"]
      , forwardButton = defaultToolbar.buttons()["Forward"];
    
    it("back button should be disabled", function() {
      expect(backButton.isEnabled()).toBeFalsy();
    });
    
    it("should have an 'Add' button", function() {
      expect(defaultToolbar.buttons()["Add"].isValid()).toBeTruthy();
    });
    
    it("should show a popover when tapping the 'Add' button", function() {
      defaultToolbar.buttons()["Add"].tap();
      target.delay(.5);
      expect(mainWindow.popover().isValid()).toBeTruthy();
      mainWindow.popover().dismiss();
    });
    
    describe("new project popover", function() {
      
      var popover;
      
      beforeEach(function() {
        defaultToolbar.buttons()["Add"].tap();
        target.delay(.5);
        popover = mainWindow.popover();
      });
      
      afterEach(function() {
        if (popover.checkIsValid())
          popover.dismiss();
      });
      
      it("should have create and import buttons", function() {
        expect(popover.buttons()["Create new project"].isValid()).toBeTruthy();
        expect(popover.buttons()["Import from iTunes"].isValid()).toBeTruthy();
      });
      
      describe("create project", function() {
        
        beforeEach(function() {
          popover.buttons()["Create new project"].tap();
        });
        
        afterEach(function() {
          if (popover.navigationBar().leftButton().checkIsValid())
            popover.navigationBar().leftButton().tap();
        });
        
        it("should have a back and create button", function() {
            expect(popover.navigationBar().leftButton().isValid()).toBeTruthy();
            expect(popover.navigationBar().rightButton().isValid()).toBeTruthy();
        });
        
        it("should have a label color and text items", function() {
          expect(popover.buttons()["Label color"].isValid()).toBeTruthy();
          expect(popover.textFields().length).toEqual(1);
        });
        
        it("should be able to change label color", function() {
          var labelColorButton = popover.buttons()["Label color"];
          var originalColorLabel = labelColorButton.label();
          labelColorButton.tap();
          target.delay(.5);
          var colorSelector = popover.elements()["color selector"];
          expect(colorSelector).not.toBeNull();
          expect(colorSelector.elements().length == 6).toBeTruthy();
          colorSelector.elements()[0].tap();
          target.delay(.5);
          expect(popover.buttons()["Label color"].label() != originalColorLabel).toBeTruthy();
        });
        
        it("should be able to add a new project named: " + newProjectName, function() {
          popover.textFields()[0].setValue(newProjectName);
          popover.navigationBar().rightButton().tap();
          target.delay(2);
          expect(tabsScrollView.elements()["projects grid"].elements()[newProjectName].checkIsValid()).toBeTruthy();
        });
        
      });
      
      describe("import project", function() {
        
        beforeEach(function() {
          popover.buttons()["Import from iTunes"].tap();
        });
        
        afterEach(function() {
          if (popover.navigationBar().leftButton().checkIsValid())
            popover.navigationBar().leftButton().tap();
        });
        
        it("should have back button and import list", function() {
          expect(popover.navigationBar().leftButton().isValid()).toBeTruthy();
          expect(popover.tableViews().length > 0).toBeTruthy();
        });
        
        it("should import a project (" + importedProjectName + ".zip)", function() {
          expect(popover.tableViews()[0].elements()[importedProjectName + ".zip"].isValid()).toBeTruthy();
          popover.tableViews()[0].elements()[importedProjectName + ".zip"].tap();
          target.delay(2);
          expect(tabsScrollView.elements()["projects grid"].elements()[importedProjectName].checkIsValid()).toBeTruthy();
        });
        
      });
      
    });
    
  });
  
  describe("when existing", function() {
    
    var projectsGrid = tabsScrollView.elements()["projects grid"];
    
    describe("according to setup", function() {
      
      it("should have 2 element", function() {
        expect(projectsGrid.elements().length).toEqual(2);
      });
      
      it("should have the '" + newProjectName + "' and '" + importedProjectName + "' elements", function() {
        expect(projectsGrid.elements()[newProjectName].isValid()).toBeTruthy();
        expect(projectsGrid.elements()[importedProjectName].isValid()).toBeTruthy();
      });
      
    });
    
  });
  
});
