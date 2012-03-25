//https://developer.apple.com/library/ios/#documentation/DeveloperTools/Reference/UIAutomationRef/_index.html
describe("Projects list", function() {
  
  var target = UIATarget.localTarget(), app = target.frontMostApp(), mainWindow = app.mainWindow();  
  var tabsScrollView = mainWindow.scrollViews()["tabs scrollview"];
  var newProjectName = "NewProject";
  var importedProjectName = "ImportedProject";

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
          target.delay(.5);
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
          target.delay(1);
          expect(tabsScrollView.elements()["projects grid"].elements()[newProjectName].checkIsValid()).toBeTruthy();
        });
        
        it("should clear the name field", function() {
          expect(popover.textFields()[0].value() != newProjectName).toBeTruthy();
        });
        
        it("should not be able to add another project with the name: " + newProjectName, function() {
          var originalElementsCount = tabsScrollView.elements()["projects grid"].elements().length;
          popover.textFields()[0].setValue(newProjectName);
          popover.navigationBar().rightButton().tap();
          target.delay(1);
          expect(tabsScrollView.elements()["projects grid"].elements().length == originalElementsCount).toBeTruthy();
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
          target.delay(1);
          expect(tabsScrollView.elements()["projects grid"].elements()[importedProjectName].checkIsValid()).toBeTruthy();
        });
        
      });
            
    });
    
    it("should have an 'edit' button", function() {
      expect(defaultToolbar.buttons()["Edit"].isValid()).toBeTruthy();
    });
    
    describe("when in edit mode", function() {
      
      beforeEach(function() {
        defaultToolbar.buttons()["Edit"].tap();
        target.delay(.5);
      });
      
      afterEach(function() {
        if (defaultToolbar.buttons()["Delete"].isValid()) {
          defaultToolbar.buttons()["Edit"].tap();
          target.delay(.5);
        }
      });
      
      it("should show editing buttons in edit mode", function() {
        expect(defaultToolbar.buttons()["Export"].isValid()).toBeTruthy();
        expect(defaultToolbar.buttons()["Duplicate"].isValid()).toBeTruthy();
        expect(defaultToolbar.buttons()["Delete"].isValid()).toBeTruthy();
      });
      
      it("should have editing buttons disabled with no slection", function() {
        expect(defaultToolbar.buttons()["Export"].isEnabled()).toBeFalsy();
        expect(defaultToolbar.buttons()["Duplicate"].isEnabled()).toBeFalsy();
        expect(defaultToolbar.buttons()["Delete"].isEnabled()).toBeFalsy();
      });
      
      it("should enable editing buttons with selection", function() {
        tabsScrollView.elements()["projects grid"].elements()[newProjectName].tap();
        target.delay(.5);
        expect(defaultToolbar.buttons()["Export"].isEnabled()).toBeTruthy();
        expect(defaultToolbar.buttons()["Duplicate"].isEnabled()).toBeTruthy();
        expect(defaultToolbar.buttons()["Delete"].isEnabled()).toBeTruthy();
      });
      
      describe("and a project selected", function() {
        
        beforeEach(function() {
          tabsScrollView.elements()["projects grid"].elements()[newProjectName].tap();
          target.delay(.5);
        });
        
        it("should disable editing buttons when no selection", function() {
          tabsScrollView.elements()["projects grid"].elements()[newProjectName].tap();
          target.delay(.5);
          expect(defaultToolbar.buttons()["Export"].isEnabled()).toBeFalsy();
          expect(defaultToolbar.buttons()["Duplicate"].isEnabled()).toBeFalsy();
          expect(defaultToolbar.buttons()["Delete"].isEnabled()).toBeFalsy();
        });
        
        it("should show a confirmation popover when deleting", function() {
          defaultToolbar.buttons()["Delete"].tap();
          target.delay(.5);
          expect(mainWindow.popover().isValid()).toBeTruthy();
          expect(mainWindow.popover().actionSheet().buttons()["Delete permanently"].isValid()).toBeTruthy();
          mainWindow.popover().dismiss();
        });
        
        it("should be able to delete a project", function() {
          defaultToolbar.buttons()["Delete"].tap();
          target.delay(.5);
          mainWindow.popover().actionSheet().buttons()["Delete permanently"].tap();
          target.delay(.5);
          expect(tabsScrollView.elements()["projects grid"].elements()[newProjectName].checkIsValid()).toBeFalsy();
        });
        
      });
      
    });
    
  });
  
  describe("when existing", function() {
    
    var projectsGrid = tabsScrollView.elements()["projects grid"];
    
    describe("according to setup", function() {
      
      it("should have the '" + importedProjectName + "' element", function() {
        // Do not relay on items count in the projectGrid, scroll bars are also added.
        expect(projectsGrid.elements()[importedProjectName].isValid()).toBeTruthy();
      });
      
    });
    
  });
  
});
