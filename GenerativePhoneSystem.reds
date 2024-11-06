import Codeware.*

public class GenerativePhoneSystem extends ScriptableService {
    private let initialized: Bool = false;
    private let callbackSystem: wref<CallbackSystem>;
    private let panamSelected: Bool = false;
    private let chatOpen: Bool = false;
    private let parent: wref<inkCanvas>;
    private let contactListSlot: wref<inkCanvas>;
    private let chatContainer: wref<inkCanvas>;
    private let defaultPhoneController: wref<NewHudPhoneGameController>;

    private cb func OnReload() {
        LogChannel(n"DEBUG", "Reloading Generative Phone System...");
        this.initialized = false;
        this.InitializeSystem();
    }
    
    private func InitializeSystem() {
        LogChannel(n"DEBUG", "Initializing Generative Phone System...");
        this.panamSelected = false;
        this.chatOpen = false;
        this.callbackSystem = GameInstance.GetCallbackSystem();
        this.callbackSystem.UnregisterCallback(n"Input/Key", this, n"OnKeyInput");
        let inkSystem = GameInstance.GetInkSystem();
        let virtualWindow = inkSystem.GetLayer(n"inkHUDLayer").GetVirtualWindow();
        let virtualWindowRoot = virtualWindow.GetWidget(0) as inkCanvas;
        let hudMiddleWidget = virtualWindowRoot.GetWidget(53) as inkCanvas;
        this.parent = hudMiddleWidget.GetWidget(0) as inkCanvas;

        this.InitializeDefaultPhoneController();

        this.SetupChatContainer();

        this.initialized = true;
        LogChannel(n"DEBUG", "Generative Phone System initialized");
    }

    private cb func OnKeyInput(event: ref<KeyInputEvent>) {
        if NotEquals(s"\(event.GetAction())", "IACT_Press") {
            return;
        }

        if Equals(s"\(event.GetKey())", "IK_T") {
            if (!this.chatOpen && this.panamSelected) {
                this.HidePhoneUI();
                this.ShowModChat();
            } else {
                ConsoleLog(s"Chat Open: \(this.chatOpen), Panam Selected: \(this.panamSelected)");
                return;
            }
        }

        if Equals(s"\(event.GetKey())", "IK_C") {
            if this.chatOpen {
                this.panamSelected = false;
                this.ShowPhoneUI();
                this.HideModChat();
            } else {
                return;
            }
        }
    }

    public func TogglePanamSelected(value: Bool) {
        if !this.initialized {
            this.InitializeSystem();
        } 

        this.panamSelected = value;
        if this.panamSelected {
            this.callbackSystem.RegisterCallback(n"Input/Key", this, n"OnKeyInput", true)
                .AddTarget(InputTarget.Key(EInputKey.IK_T))
                .AddTarget(InputTarget.Key(EInputKey.IK_C))
                .SetRunMode(CallbackRunMode.OncePerTarget);
        } else {
            this.callbackSystem.UnregisterCallback(n"Input/Key", this, n"OnKeyInput");
        }
    }

    private func ShowModChat() {
        this.chatOpen = true;
        this.BuildChatUi();
        LogChannel(n"DEBUG", "Showing mod chat...");
    }

    private func HideModChat() {
        this.chatOpen = false;
        this.chatContainer.RemoveAllChildren();
        LogChannel(n"DEBUG", "Hiding mod chat...");
    }

    // Function to hide the default phone UI
    private func HidePhoneUI() {
        if IsDefined(this.defaultPhoneController) {            
            this.defaultPhoneController.DisableContactsInput();
            this.contactListSlot.SetVisible(false);
            ConsoleLog("Disabling contacts input...");
        } else {
            LogChannel(n"DEBUG", "defaultPhoneController is not defined, initializing...");
            this.InitializeDefaultPhoneController();
            this.HidePhoneUI();
        }
    }

    // Function to show the default phone UI
    private func ShowPhoneUI() {
        if IsDefined(this.defaultPhoneController) {            
            this.defaultPhoneController.EnableContactsInput();
            this.contactListSlot.SetVisible(true);
            ConsoleLog("Enabling contacts input...");
        } else {
            LogChannel(n"DEBUG", "defaultPhoneController is not defined, initializing...");
            this.InitializeDefaultPhoneController();
            this.ShowPhoneUI();
        }
    }


    private func SetupChatContainer() {
        if this.parent.GetNumChildren() > 14 {
            this.parent.RemoveChildByName(n"mod_messenger_slot");
        }

        let modMessengerSlot = new inkCanvas();
        modMessengerSlot.Reparent(this.parent);
        modMessengerSlot.SetMargin(new inkMargin(80.0, 480.0, 0.0, 0.0));
        modMessengerSlot.SetChildOrder(inkEChildOrder.Backward);
        modMessengerSlot.SetName(n"mod_messenger_slot");
        this.chatContainer = modMessengerSlot;
    }

    private func InitializeDefaultPhoneController() {
        this.contactListSlot = this.parent.GetWidget(9) as inkCanvas;
        let inkSystem = GameInstance.GetInkSystem();

        for controller in inkSystem.GetLayer(n"inkHUDLayer").GetGameControllers() {
            if Equals(s"\(controller.GetClassName())", "NewHudPhoneGameController") {
                this.defaultPhoneController = controller as NewHudPhoneGameController;
            }
        }
    }

    private func BuildChatUi() {
        ConsoleLog("Building chat UI...");

        let modMessengerSlotRoot = new inkCanvas();
        modMessengerSlotRoot.SetName(n"Root");
        modMessengerSlotRoot.SetStyle(r"base\\gameplay\\gui\\common\\styles\\panel.inkstyle");
        modMessengerSlotRoot.BindProperty(n"tintColor", n"MainColors.Blue");
        modMessengerSlotRoot.SetChildOrder(inkEChildOrder.Backward);
        modMessengerSlotRoot.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        modMessengerSlotRoot.SetSize(new Vector2(1500.0, 1500.0));
        modMessengerSlotRoot.Reparent(this.chatContainer);

        // Widgets under Root/container
        let rootContainer = new inkCanvas();
        rootContainer.SetName(n"container");
        rootContainer.SetMargin(new inkMargin(100.0, 0.0, 0.0, 0.0));
        rootContainer.SetSize(new Vector2(1550.0, 1200.0));
        rootContainer.SetChildOrder(inkEChildOrder.Backward);
        rootContainer.Reparent(modMessengerSlotRoot);

        let topHolder = new inkFlex();
        topHolder.SetName(n"top_holder");
        topHolder.SetAnchor(inkEAnchor.TopFillHorizontaly);
        topHolder.SetHAlign(inkEHorizontalAlign.Left);
        topHolder.SetVAlign(inkEVerticalAlign.Top);
        topHolder.SetMargin(new inkMargin(120.0, -60.0, 0.0, 0.0));
        topHolder.SetSize(new Vector2(100.0, 100.0));
        topHolder.Reparent(rootContainer);

        let horizontalPanelWidget5 = new inkHorizontalPanel();
        horizontalPanelWidget5.SetName(n"inkHorizontalPanelWidget5");
        horizontalPanelWidget5.SetSize(new Vector2(100.0, 100.0));
        horizontalPanelWidget5.SetFitToContent(true);
        horizontalPanelWidget5.SetVAlign(inkEVerticalAlign.Top);
        horizontalPanelWidget5.Reparent(topHolder);

        let pathContainer = new inkVerticalPanel();
        pathContainer.SetName(n"pathContainer");
        pathContainer.SetHAlign(inkEHorizontalAlign.Left);
        pathContainer.SetVAlign(inkEVerticalAlign.Top);
        pathContainer.SetPadding(new inkMargin(0.0, 0.0, 20.0, 0.0));
        pathContainer.SetFitToContent(true);
        pathContainer.Reparent(horizontalPanelWidget5);

        let messagesPath = new inkHorizontalPanel();
        messagesPath.SetName(n"messagesPath");
        messagesPath.SetOpacity(0.6);
        messagesPath.SetHAlign(inkEHorizontalAlign.Left);
        messagesPath.SetVAlign(inkEVerticalAlign.Top);
        messagesPath.SetSizeRule(inkESizeRule.Stretch);
        messagesPath.SetFitToContent(true);
        messagesPath.SetChildMargin(new inkMargin(0.0, 20.0, 0.0, 20.0));
        messagesPath.Reparent(pathContainer);

        let messagesLine = new inkRectangle();
        messagesLine.SetName(n"line");
        messagesLine.SetTintColor(new Color(Cast(94), Cast(246u), Cast(255u), Cast(255u)));
        messagesLine.SetMargin(new inkMargin(-20.0, 0.0, -20.0, 0.0));
        messagesLine.SetSize(new Vector2(0.0, 7.0));
        messagesLine.BindProperty(n"tintColor", n"MainColors.Blue");
        messagesLine.Reparent(pathContainer);

        let messagesFluff = new inkImage();
        messagesFluff.SetName(n"fluff");
        messagesFluff.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\atlas_common.inkatlas");
        messagesFluff.SetTexturePart(n"ico_envelelope");
        messagesFluff.SetTileHAlign(inkEHorizontalAlign.Left);
        messagesFluff.SetTileVAlign(inkEVerticalAlign.Top);
        messagesFluff.SetTintColor(new Color(Cast(94), Cast(246u), Cast(255u), Cast(255u)));
        messagesFluff.SetHAlign(inkEHorizontalAlign.Center);
        messagesFluff.SetVAlign(inkEVerticalAlign.Center);
        messagesFluff.SetSize(new Vector2(48.0, 48.0));
        messagesFluff.SetFitToContent(true);
        messagesFluff.BindProperty(n"tintColor", n"MainColors.Blue");
        messagesFluff.BindProperty(n"opacity", n"MenuLabel.MainOpacity");
        messagesFluff.Reparent(messagesPath);

        let messagesPathText = new inkText();
        messagesPathText.SetName(n"txtValue");
        messagesPathText.SetText("Messages");
        messagesPathText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        messagesPathText.SetFontStyle(n"Medium");
        messagesPathText.SetFontSize(50);
        messagesPathText.SetLetterCase(textLetterCase.UpperCase);
        messagesPathText.SetVerticalAlignment(textVerticalAlignment.Center);
        messagesPathText.SetContentHAlign(inkEHorizontalAlign.Center);
        messagesPathText.SetContentVAlign(inkEVerticalAlign.Center);
        messagesPathText.SetTintColor(new Color(Cast(94), Cast(246u), Cast(255u), Cast(255u)));
        messagesPathText.SetHAlign(inkEHorizontalAlign.Left);
        messagesPathText.SetVAlign(inkEVerticalAlign.Center);
        messagesPathText.SetAnchor(inkEAnchor.Centered);
        messagesPathText.SetAnchorPoint(new Vector2(0.5, 0.5));
        messagesPathText.SetMargin(new inkMargin(10.0, 0.0, 0.0, 0.0));
        messagesPathText.SetFitToContent(true);
        messagesPathText.BindProperty(n"tintColor", n"MainColors.Blue");
        messagesPathText.BindProperty(n"fontSize", n"MainColors.ReadableFontSize");
        messagesPathText.BindProperty(n"opacity", n"MenuLabel.MainOpacity");
        messagesPathText.Reparent(messagesPath);

        let arrowIcon = new inkImage();
        arrowIcon.SetName(n"arrow");
        arrowIcon.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\hud_johnny\\notification_assets.inkatlas");
        arrowIcon.SetTexturePart(n"+1");
        arrowIcon.SetTileHAlign(inkEHorizontalAlign.Left);
        arrowIcon.SetTileVAlign(inkEVerticalAlign.Top);
        arrowIcon.SetTintColor(new Color(Cast(94), Cast(246u), Cast(255u), Cast(255u)));
        arrowIcon.SetHAlign(inkEHorizontalAlign.Center);
        arrowIcon.SetVAlign(inkEVerticalAlign.Center);
        arrowIcon.SetMargin(new inkMargin(0.0, -20.0, 0.0, 0.0));
        arrowIcon.SetSize(new Vector2(20.0, 20.0));
        arrowIcon.SetFitToContent(true);
        arrowIcon.SetRotation(90);
        arrowIcon.BindProperty(n"tintColor", n"MainColors.Blue");
        arrowIcon.Reparent(horizontalPanelWidget5);

        let rectangleRight = new inkRectangle();
        rectangleRight.SetName(n"right");
        rectangleRight.SetTintColor(new Color(Cast(255), Cast(97u), Cast(89u), Cast(255u)));
        rectangleRight.SetVAlign(inkEVerticalAlign.Center);
        rectangleRight.SetMargin(new inkMargin(30.0, 92.0, 270.0, 0.0));
        rectangleRight.SetSizeRule(inkESizeRule.Stretch);
        rectangleRight.SetSize(new Vector2(0.0, 2.0));
        rectangleRight.SetRenderTransformPivot(new Vector2(1, 0.5));
        rectangleRight.BindProperty(n"tintColor", n"MainColors.PanelRed");
        rectangleRight.Reparent(horizontalPanelWidget5);

        let fluffNameL = new inkText();
        fluffNameL.SetName(n"fluff_name-l");
        fluffNameL.SetText("TRN_TCLAS_800095");
        fluffNameL.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        fluffNameL.SetFontStyle(n"Medium");
        fluffNameL.SetFontSize(20);
        fluffNameL.SetLetterCase(textLetterCase.UpperCase);
        fluffNameL.SetTintColor(new Color(Cast(255), Cast(97u), Cast(89u), Cast(255u)));
        fluffNameL.SetAnchor(inkEAnchor.TopRight);
        fluffNameL.SetHAlign(inkEHorizontalAlign.Left);
        fluffNameL.SetVAlign(inkEVerticalAlign.Top);
        fluffNameL.SetMargin(new inkMargin(0.0, -20.0, 0.0, 0.0));
        fluffNameL.SetSize(new Vector2(100.0, 32.0));
        fluffNameL.SetFitToContent(true);
        fluffNameL.BindProperty(n"fontStyle", n"MainColors.BodyFontWeight");
        fluffNameL.BindProperty(n"tintColor", n"MainColors.Red");
        fluffNameL.Reparent(topHolder);

        let fluffNameR = new inkText();
        fluffNameR.SetName(n"fluff_name-r");
        fluffNameR.SetText("VER_M6A6T6I");
        fluffNameR.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        fluffNameR.SetFontStyle(n"Medium");
        fluffNameR.SetFontSize(20);
        fluffNameR.SetLetterCase(textLetterCase.UpperCase);
        fluffNameR.SetTintColor(new Color(Cast(255), Cast(97u), Cast(89u), Cast(255u)));
        fluffNameR.SetAnchor(inkEAnchor.TopRight);
        fluffNameR.SetHAlign(inkEHorizontalAlign.Right);
        fluffNameR.SetVAlign(inkEVerticalAlign.Bottom);
        fluffNameR.SetMargin(new inkMargin(0.0, 0.0, 269.00, 10.00));
        fluffNameR.SetRenderTransformPivot(new Vector2(1, 0.5));
        fluffNameR.SetSize(new Vector2(100.0, 32.0));
        fluffNameR.SetFitToContent(true);
        fluffNameR.BindProperty(n"fontStyle", n"MainColors.BodyFontWeight");
        fluffNameR.BindProperty(n"tintColor", n"MainColors.Red");
        fluffNameR.Reparent(topHolder);

        // Widgets under Root/wrapper
        let rootWrapper = new inkVerticalPanel();
        rootWrapper.SetName(n"wrapper");
        rootWrapper.SetMargin(new inkMargin(100.0, 50.0, 0.0, 0.0));
        rootWrapper.SetFitToContent(true);
        rootWrapper.Reparent(modMessengerSlotRoot);
    }
}
