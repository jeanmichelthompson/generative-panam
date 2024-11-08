import Codeware.*
import Codeware.UI.*

public class GenerativePhoneSystem extends ScriptableService {
    private let initialized: Bool = false;
    private let callbackSystem: wref<CallbackSystem>;
    private let panamSelected: Bool = false;
    private let chatOpen: Bool = false;
    private let parent: wref<inkCanvas>;
    private let contactListSlot: wref<inkCanvas>;
    private let chatContainer: wref<inkCanvas>;
    private let defaultPhoneController: wref<NewHudPhoneGameController>;
    private let defaultChatUi: wref<inkCanvas>;
    private let messageParent: wref<inkVerticalPanel>;
    private let rootAnim: wref<inkAnimDef>;
    private let messageAnim: wref<inkAnimDef>;
    private let player: wref<PlayerPuppet>;
    private let isTyping: Bool = false;
    private let typedMessage: String = "";
    private let typedMessageText: wref<inkText>;
    private let typedMessageWrapper: wref<inkHorizontalPanel>;
    private let chatInputHint: wref<inkImage>;
    private let messengerSlotRoot: wref<inkCanvas>;

    private cb func OnReload() {
        LogChannel(n"DEBUG", "Reloading Generative Phone System...");
        this.initialized = false;
        this.InitializeSystem();
    }
    
    public func GetInitialized() -> Bool {
        return this.initialized;
    }


    // Initialize callbacks, widgets, and other necessary components
    private func InitializeSystem() {
        LogChannel(n"DEBUG", "Initializing Generative Phone System...");
        this.player = GetPlayer(GetGameInstance());
        this.panamSelected = false;
        this.chatOpen = false;
        this.isTyping = false;
        this.callbackSystem = GameInstance.GetCallbackSystem();
        this.callbackSystem.UnregisterCallback(n"Input/Key", this, n"OnKeyInput");
        let inkSystem = GameInstance.GetInkSystem();
        let virtualWindow = inkSystem.GetLayer(n"inkHUDLayer").GetVirtualWindow();
        let virtualWindowRoot = virtualWindow.GetWidget(0) as inkCanvas;
        let hudMiddleWidget = virtualWindowRoot.GetWidget(53) as inkCanvas;
        this.parent = hudMiddleWidget.GetWidget(0) as inkCanvas;
        this.contactListSlot = this.parent.GetWidget(9) as inkCanvas;
        this.defaultChatUi = this.parent.GetWidget(11) as inkCanvas;

        this.InitializeDefaultPhoneController(false);

        this.SetupChatContainer();

        this.initialized = true;
        LogChannel(n"DEBUG", "Generative Phone System initialized");
    }

    // Handle key input events
    private cb func OnKeyInput(event: ref<KeyInputEvent>) {
        if NotEquals(s"\(event.GetAction())", "IACT_Press") {
            return;
        }

        if this.isTyping {
            if Equals(s"\(event.GetKey())", "IK_Enter") {
                this.isTyping = false;
                let message = this.GetInputText();
                this.BuildMessage(message, true, true);
                let input = this.typedMessageWrapper.GetWidget(2) as inkCompoundWidget;
                this.typedMessageWrapper.RemoveChildByName(input.GetName());
                this.typedMessageText.SetVisible(true);
                this.typedMessageText.SetText("Send a message.");
                this.chatInputHint.SetTexturePart(n"mouse_left");
            } 
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
                this.chatOpen = false;
                this.ShowPhoneUI();
                this.HideModChat();
            } else {
                return;
            }
        }

        if Equals(s"\(event.GetKey())", "IK_LeftMouse") {
            if (!this.chatOpen || this.isTyping) {
                return;
            } 

            this.isTyping = true;
            this.typedMessageText.SetText("Start Typing...");
            this.typedMessageText.SetVisible(false);
            this.chatInputHint.SetTexturePart(n"kb_enter");

            this.BuildInput();
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
                .SetRunMode(CallbackRunMode.OncePerTarget);
        } else {
            this.callbackSystem.UnregisterCallback(n"Input/Key", this, n"OnKeyInput");
        }
    }

    public func ToggleIsTyping(value: Bool) {
        this.isTyping = value;
    }

    private func ShowModChat() {
        this.chatOpen = true;
        this.BuildChatUi();
        this.PlaySound(n"ui_menu_map_pin_delete");
        this.callbackSystem.RegisterCallback(n"Input/Key", this, n"OnKeyInput", true);
        LogChannel(n"DEBUG", "Showing mod chat...");
    }

    private func HideModChat() {
        this.chatContainer.RemoveAllChildren();
        LogChannel(n"DEBUG", "Hiding mod chat...");
    }

    // Function to hide the default phone UI
    private func HidePhoneUI() {
        if IsDefined(this.defaultPhoneController) {            
            this.defaultPhoneController.DisableContactsInput();
            this.contactListSlot.SetVisible(false);
            this.parent.ReorderChild(this.chatContainer, 12);
            this.parent.ReorderChild(this.defaultChatUi, 14);
            ConsoleLog("Disabling contacts input...");
        } else {
            LogChannel(n"DEBUG", "defaultPhoneController is not defined, initializing...");
            this.InitializeDefaultPhoneController(true);
        }
    }

    // Function to show the default phone UI
    private func ShowPhoneUI() {
        if (IsDefined(this.defaultPhoneController) && IsDefined(this.contactListSlot)) {            
            this.defaultPhoneController.EnableContactsInput();
            this.contactListSlot.SetVisible(true);
            this.parent.ReorderChild(this.defaultChatUi, 12);
            this.parent.ReorderChild(this.chatContainer, 14);
            ConsoleLog("Enabling contacts input...");
        } else {
            LogChannel(n"DEBUG", "defaultPhoneController or contactListSlot not defined, initializing...");
            this.InitializeDefaultPhoneController(false);
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

    private func InitializeDefaultPhoneController(hidePhone: Bool) {
        let inkSystem = GameInstance.GetInkSystem();

        for controller in inkSystem.GetLayer(n"inkHUDLayer").GetGameControllers() {
            if Equals(s"\(controller.GetClassName())", "NewHudPhoneGameController") {
                this.defaultPhoneController = controller as NewHudPhoneGameController;
            }
        }

        if hidePhone {
            this.HidePhoneUI();
        }
    }

    private func PlaySound(sound: CName) {
        GameObject.PlaySoundEvent(this.player, sound);
    }

    private func BuildInput() {
        let inkSystem = GameInstance.GetInkSystem();
        let input = HubTextInput.Create();
        input.SetText("Start Typing...");
        input.Reparent(this.typedMessageWrapper);

        let inputWidget = this.typedMessageWrapper.GetWidget(2) as inkCompoundWidget;
        inputWidget.RemoveChildByName(n"theme");
        inputWidget.SetTranslation(new Vector2(0.0, -9.0));

        let inputChild1 = inputWidget.GetWidget(1) as inkCompoundWidget;
        let inputChild2 = inputChild1.GetWidget(0) as inkCompoundWidget;
        let inputChild3 = inputChild2.GetWidget(1) as inkText;
        inputChild3.SetTintColor(new Color(Cast(255u), Cast(255u), Cast(78u), Cast(255u)));

        inkSystem.SetFocus(input.GetRootWidget());
    }

    private func GetInputText() -> String {
        let input = this.typedMessageWrapper.GetWidget(2) as inkCompoundWidget;
        let inputChild1 = input.GetWidget(1) as inkCompoundWidget;
        let inputChild2 = inputChild1.GetWidget(0) as inkCompoundWidget;
        let inputChild3 = inputChild2.GetWidget(1) as inkText;
        let message = inputChild3.GetText();
        return message;
    }

    // Function to build a message for the player or NPC
    private func BuildMessage(text: String, fromPlayer: Bool, useAnim: Bool) {
        if !IsDefined(this.messageParent) {
            return;
        }

        let message = new inkFlex();
        message.SetName(n"Root");
        message.SetHAlign(inkEHorizontalAlign.Left);
        message.SetSize(new Vector2(100.0, 100.0));
        message.SetStyle(r"base\\gameplay\\gui\\fullscreen\\phone_quest_menu\\messenger.inkstyle");
        message.Reparent(this.messageParent);

        let wide = new inkCanvas();
        wide.SetName(n"wide");
        wide.SetHAlign(inkEHorizontalAlign.Left);
        wide.SetSize(new Vector2(1200.0, 600.0));
        wide.SetChildOrder(inkEChildOrder.Backward);
        wide.Reparent(message);

        let messageContainer = new inkFlex();
        messageContainer.SetName(n"container");
        messageContainer.SetVAlign(inkEVerticalAlign.Top);
        messageContainer.SetSize(new Vector2(100.0, 100.0));
        messageContainer.Reparent(message);

        let messageBackground = new inkImage();
        messageBackground.SetName(n"background");
        messageBackground.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\phone\\new_phone_assets.inkatlas");
        messageBackground.SetNineSliceScale(true);
        messageBackground.SetTileHAlign(inkEHorizontalAlign.Left);
        messageBackground.SetTileVAlign(inkEVerticalAlign.Top);
        messageBackground.SetSize(new Vector2(32.0, 32.0));
        messageBackground.SetFitToContent(true);
        messageBackground.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        messageBackground.BindProperty(n"tintColor", n"Message.BackgroundColor");
        messageBackground.BindProperty(n"opacity", n"Message.BackgroundOpacity");
        messageBackground.Reparent(messageContainer);

        let messageBorder = new inkImage();
        messageBorder.SetName(n"border");
        messageBorder.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\phone\\new_phone_assets.inkatlas");
        messageBorder.SetNineSliceScale(true);
        messageBorder.SetTileHAlign(inkEHorizontalAlign.Left);
        messageBorder.SetTileVAlign(inkEVerticalAlign.Top);
        messageBorder.SetOpacity(0.5);
        messageBorder.SetSize(new Vector2(32.0, 32.0));
        messageBorder.SetFitToContent(true);
        messageBorder.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        messageBorder.BindProperty(n"tintColor", n"Message.BorderColor");
        messageBorder.Reparent(messageContainer);

        let messageContent = new inkVerticalPanel();
        messageContent.SetName(n"container");
        messageContent.SetHAlign(inkEHorizontalAlign.Left);
        messageContent.SetVAlign(inkEVerticalAlign.Top);
        messageContent.SetMargin(new inkMargin(24.0, 20.0, 20.0, 30.0));
        messageContent.SetFitToContent(true);
        messageContent.Reparent(messageContainer);

        let messageText = new inkText();
        messageText.SetName(n"Message");
        messageText.SetText(text);
        messageText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        messageText.SetFontStyle(n"Medium");
        messageText.SetFontSize(42);
        messageText.SetLetterCase(textLetterCase.OriginalCase);
        messageText.SetContentVAlign(inkEVerticalAlign.Top);
        messageText.SetWrapping(true);
        messageText.SetWrappingAtPosition(1000);
        messageText.SetHAlign(inkEHorizontalAlign.Left);
        messageText.SetVAlign(inkEVerticalAlign.Top);
        messageText.SetMargin(new inkMargin(0.0, 0.0, 10.0, 0.0));
        messageText.SetSize(new Vector2(0.0, 32.0));
        messageText.SetFitToContent(true);
        messageText.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        messageText.BindProperty(n"tintColor", n"Message.TextColor");
        messageText.BindProperty(n"fontSize", n"MainColors.ReadableMedium");
        messageText.Reparent(messageContent);

        if fromPlayer {
            message.SetState(n"Player");
            messageContainer.SetHAlign(inkEHorizontalAlign.Right);
            messageBackground.SetTexturePart(n"msgBuble_reply_bg");
            messageBackground.SetTintColor(new Color(Cast(0u), Cast(255u), Cast(198u), Cast(255u)));
            messageBackground.SetOpacity(0.05);
            messageBorder.SetTexturePart(n"msgBuble_reply_fg");
            messageBorder.SetTintColor(new Color(Cast(0u), Cast(255u), Cast(198u), Cast(255u)));
            messageText.SetTintColor(new Color(Cast(0u), Cast(255u), Cast(188u), Cast(255u)));
        } else {
            messageContainer.SetHAlign(inkEHorizontalAlign.Left);
            messageBackground.SetTexturePart(n"msgBuble_bg");
            messageBackground.SetTintColor(new Color(Cast(23u), Cast(44u), Cast(46u), Cast(255u)));
            messageBackground.SetOpacity(0.35);
            messageBorder.SetTexturePart(n"msgBuble_fg");
            messageBorder.SetTintColor(new Color(Cast(52u), Cast(145u), Cast(151u), Cast(255u)));
            messageText.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        }

        if useAnim {
            let translateAnimMessage = new inkAnimTranslation();
            translateAnimMessage.SetStartTranslation(new Vector2(0.0, 50.0));
            translateAnimMessage.SetEndTranslation(new Vector2(0, 0));
            translateAnimMessage.SetType(inkanimInterpolationType.Linear);
            translateAnimMessage.SetMode(inkanimInterpolationMode.EasyOut);
            translateAnimMessage.SetDuration(0.15);

            let alphaAnim = new inkAnimTransparency();
            alphaAnim.SetStartTransparency(0.0);
            alphaAnim.SetEndTransparency(1.0);
            alphaAnim.SetType(inkanimInterpolationType.Linear);
            alphaAnim.SetMode(inkanimInterpolationMode.EasyOut);
            alphaAnim.SetDuration(0.15);
            
            let animDefMessage = new inkAnimDef();
            animDefMessage.AddInterpolator(translateAnimMessage);
            animDefMessage.AddInterpolator(alphaAnim);

            message.PlayAnimation(animDefMessage);
            this.PlaySound(n"ui_messenger_recieved");
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
        this.messengerSlotRoot = modMessengerSlotRoot;

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
        messagesLine.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        messagesLine.SetMargin(new inkMargin(-20.0, 0.0, -20.0, 0.0));
        messagesLine.SetSize(new Vector2(0.0, 7.0));
        messagesLine.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        messagesLine.BindProperty(n"tintColor", n"MainColors.Blue");
        messagesLine.Reparent(pathContainer);

        let messagesFluff = new inkImage();
        messagesFluff.SetName(n"fluff");
        messagesFluff.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\atlas_common.inkatlas");
        messagesFluff.SetTexturePart(n"ico_envelelope");
        messagesFluff.SetTileHAlign(inkEHorizontalAlign.Left);
        messagesFluff.SetTileVAlign(inkEVerticalAlign.Top);
        messagesFluff.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        messagesFluff.SetHAlign(inkEHorizontalAlign.Center);
        messagesFluff.SetVAlign(inkEVerticalAlign.Center);
        messagesFluff.SetSize(new Vector2(48.0, 48.0));
        messagesFluff.SetFitToContent(true);
        messagesFluff.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
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
        messagesPathText.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        messagesPathText.SetHAlign(inkEHorizontalAlign.Left);
        messagesPathText.SetVAlign(inkEVerticalAlign.Center);
        messagesPathText.SetAnchor(inkEAnchor.Centered);
        messagesPathText.SetAnchorPoint(new Vector2(0.5, 0.5));
        messagesPathText.SetMargin(new inkMargin(10.0, 0.0, 0.0, 0.0));
        messagesPathText.SetFitToContent(true);
        messagesPathText.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
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
        arrowIcon.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        arrowIcon.SetHAlign(inkEHorizontalAlign.Center);
        arrowIcon.SetVAlign(inkEVerticalAlign.Center);
        arrowIcon.SetMargin(new inkMargin(0.0, -20.0, 0.0, 0.0));
        arrowIcon.SetSize(new Vector2(20.0, 20.0));
        arrowIcon.SetFitToContent(true);
        arrowIcon.SetRotation(90);
        arrowIcon.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        arrowIcon.BindProperty(n"tintColor", n"MainColors.Blue");
        arrowIcon.Reparent(horizontalPanelWidget5);

        let nameHolder = new inkFlex();
        nameHolder.SetName(n"name_holder");
        nameHolder.SetMargin(new inkMargin(20.0, 0.0, 0.0, 0.0));
        nameHolder.SetSize(new Vector2(100.0, 100.0));
        nameHolder.Reparent(horizontalPanelWidget5);

        let nameLine = new inkRectangle();
        nameLine.SetName(n"line");
        nameLine.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        nameLine.SetVAlign(inkEVerticalAlign.Bottom);
        nameLine.SetMargin(new inkMargin(-20.0, 0.0, -20.0, 0.0));
        nameLine.SetSize(new Vector2(300.0, 7.0));
        nameLine.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        nameLine.BindProperty(n"tintColor", n"MainColors.Blue");
        nameLine.Reparent(nameHolder);

        let nameText = new inkText();
        nameText.SetName(n"contact_name");
        nameText.SetText("Panam Palmer");
        nameText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        nameText.SetFontStyle(n"Medium");
        nameText.SetFontSize(50);
        nameText.SetLetterCase(textLetterCase.UpperCase);
        nameText.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        nameText.SetHorizontalAlignment(textHorizontalAlignment.Center);
        nameText.SetVerticalAlignment(textVerticalAlignment.Center);
        nameText.SetContentHAlign(inkEHorizontalAlign.Left);
        nameText.SetOverflowPolicy(textOverflowPolicy.AutoScroll);
        nameText.SetWrappingAtPosition(700);
        nameText.SetHAlign(inkEHorizontalAlign.Left);
        nameText.SetVAlign(inkEVerticalAlign.Center);
        nameText.SetMargin(new inkMargin(0.0, -12.0, 0.0, 0.0));
        nameText.SetSizeRule(inkESizeRule.Stretch);
        nameText.SetSize(new Vector2(900.0, 63.0));
        nameText.SetFitToContent(true);
        nameText.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        nameText.BindProperty(n"tintColor", n"MainColors.Blue");
        nameText.Reparent(nameHolder);

        let rectangleRight = new inkRectangle();
        rectangleRight.SetName(n"right");
        rectangleRight.SetTintColor(new Color(Cast(255u), Cast(97u), Cast(89u), Cast(255u)));
        rectangleRight.SetVAlign(inkEVerticalAlign.Center);
        rectangleRight.SetMargin(new inkMargin(30.0, 92.0, 270.0, 0.0));
        rectangleRight.SetSizeRule(inkESizeRule.Stretch);
        rectangleRight.SetSize(new Vector2(0.0, 2.0));
        rectangleRight.SetRenderTransformPivot(new Vector2(1, 0.5));
        rectangleRight.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        rectangleRight.BindProperty(n"tintColor", n"MainColors.PanelRed");
        rectangleRight.Reparent(horizontalPanelWidget5);

        let fluffNameL = new inkText();
        fluffNameL.SetName(n"fluff_name-l");
        fluffNameL.SetText("TRN_TCLAS_800095");
        fluffNameL.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        fluffNameL.SetFontStyle(n"Medium");
        fluffNameL.SetFontSize(20);
        fluffNameL.SetLetterCase(textLetterCase.UpperCase);
        fluffNameL.SetTintColor(new Color(Cast(255u), Cast(97u), Cast(89u), Cast(255u)));
        fluffNameL.SetAnchor(inkEAnchor.TopRight);
        fluffNameL.SetHAlign(inkEHorizontalAlign.Left);
        fluffNameL.SetVAlign(inkEVerticalAlign.Top);
        fluffNameL.SetMargin(new inkMargin(0.0, -20.0, 0.0, 0.0));
        fluffNameL.SetSize(new Vector2(100.0, 32.0));
        fluffNameL.SetFitToContent(true);
        fluffNameL.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
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
        fluffNameR.SetTintColor(new Color(Cast(255u), Cast(97u), Cast(89u), Cast(255u)));
        fluffNameR.SetAnchor(inkEAnchor.TopRight);
        fluffNameR.SetHAlign(inkEHorizontalAlign.Right);
        fluffNameR.SetVAlign(inkEVerticalAlign.Bottom);
        fluffNameR.SetMargin(new inkMargin(0.0, 0.0, 269.00, 10.00));
        fluffNameR.SetRenderTransformPivot(new Vector2(1, 0.5));
        fluffNameR.SetSize(new Vector2(100.0, 32.0));
        fluffNameR.SetFitToContent(true);
        fluffNameR.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        fluffNameR.BindProperty(n"fontStyle", n"MainColors.BodyFontWeight");
        fluffNameR.BindProperty(n"tintColor", n"MainColors.Red");
        fluffNameR.Reparent(topHolder);

        // Widgets under Root/wrapper
        let rootWrapper = new inkVerticalPanel();
        rootWrapper.SetName(n"wrapper");
        rootWrapper.SetMargin(new inkMargin(100.0, 50.0, 0.0, 0.0));
        rootWrapper.SetFitToContent(true);
        rootWrapper.Reparent(modMessengerSlotRoot);

        let wrapperContent = new inkFlex();
        wrapperContent.SetName(n"content");
        wrapperContent.SetAnchor(inkEAnchor.BottomLeft);
        wrapperContent.SetHAlign(inkEHorizontalAlign.Left);
        wrapperContent.SetVAlign(inkEVerticalAlign.Top);
        wrapperContent.SetMargin(new inkMargin(120.0, 0.0, 0.0, 0.0));
        wrapperContent.SetSizeRule(inkESizeRule.Stretch);
        wrapperContent.SetSize(new Vector2(100.0, 100.0));
        wrapperContent.SetAffectsLayoutWhenHidden(true);
        wrapperContent.Reparent(rootWrapper);

        let innerWrapper = new inkVerticalPanel();
        innerWrapper.SetName(n"wrapper");
        innerWrapper.SetMargin(new inkMargin(0.0, 0.0, 24.0, 0.0));
        innerWrapper.SetFitToContent(false);
        innerWrapper.Reparent(wrapperContent);

        let conversation = new inkCanvas();
        conversation.SetName(n"Conversation");
        conversation.SetSizeRule(inkESizeRule.Stretch);
        conversation.SetSize(new Vector2(1300.0, 1400.0));
        conversation.SetAffectsLayoutWhenHidden(true);
        conversation.SetChildOrder(inkEChildOrder.Backward);
        conversation.Reparent(innerWrapper);

        let messageScrollArea = new inkScrollArea();
        messageScrollArea.SetName(n"MessagesScrollArea");
        messageScrollArea.SetMargin(new inkMargin(20.0, 0.0, 35.0, 0.0));
        messageScrollArea.SetAnchor(inkEAnchor.Fill);
        messageScrollArea.useInternalMask = false;
        messageScrollArea.SetSize(new Vector2(600.0, 600.0));
        messageScrollArea.Reparent(conversation);

        let scrollAreaWrapper = new inkFlex();
        scrollAreaWrapper.SetName(n"wrapper");
        scrollAreaWrapper.SetSize(new Vector2(100.0, 100.0));
        scrollAreaWrapper.Reparent(messageScrollArea);

        let scrollAreaContainer = new inkVerticalPanel();
        scrollAreaContainer.SetName(n"container");
        scrollAreaContainer.SetHAlign(inkEHorizontalAlign.Left);
        scrollAreaContainer.SetVAlign(inkEVerticalAlign.Top);
        scrollAreaContainer.SetFitToContent(true);
        scrollAreaContainer.Reparent(scrollAreaWrapper);

        let messagesList = new inkVerticalPanel();
        messagesList.SetName(n"MessagesList");
        messagesList.SetHAlign(inkEHorizontalAlign.Left);
        messagesList.SetVAlign(inkEVerticalAlign.Top);
        messagesList.SetFitToContent(true);
        messagesList.SetMargin(new inkMargin(0.0, 40.0, 0.0, 40.0));
        messagesList.SetChildMargin(new inkMargin(0.0, 5.0, 0.0, 0.0));
        messagesList.Reparent(scrollAreaContainer);
        this.messageParent = messagesList;

        this.BuildMessage("This is a static test message. I am the god of all UI building.", true, false);

        this.BuildMessage("This is a reply message.", false, false);

        let typingIndicator = new inkFlex();
        typingIndicator.SetName(n"typing_indicator");
        typingIndicator.SetVAlign(inkEVerticalAlign.Bottom);
        typingIndicator.SetSize(new Vector2(100.0, 100.0));
        typingIndicator.Reparent(scrollAreaContainer);

        let indicatorContainer = new inkFlex();
        indicatorContainer.SetName(n"container");
        indicatorContainer.SetVAlign(inkEVerticalAlign.Top);
        indicatorContainer.SetMargin(new inkMargin(0.0, 0.0, 0.0, 25.0));
        indicatorContainer.SetSize(new Vector2(100.0, 100.0));

        let indicatorContainer2 = new inkVerticalPanel();
        indicatorContainer2.SetName(n"container");
        indicatorContainer2.SetHAlign(inkEHorizontalAlign.Left);
        indicatorContainer2.SetVAlign(inkEVerticalAlign.Top);
        indicatorContainer2.SetFitToContent(true);
        indicatorContainer2.SetStyle(r"base\\gameplay\\gui\\fullscreen\\phone_quest_menu\\messenger.inkstyle");

        let horizontalPanelWidget16 = new inkHorizontalPanel();
        horizontalPanelWidget16.SetName(n"inkHorizontalPanelWidget16");
        horizontalPanelWidget16.SetHAlign(inkEHorizontalAlign.Left);
        horizontalPanelWidget16.SetFitToContent(true);
        horizontalPanelWidget16.SetChildMargin(new inkMargin(0.0, 0.0, 4.0, 0.0));
        horizontalPanelWidget16.Reparent(indicatorContainer2);

        let isTyping = new inkText();
        isTyping.SetName(n"isTyping");
        isTyping.SetText("Panam Palmer is typing");
        isTyping.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        isTyping.SetFontStyle(n"Medium");
        isTyping.SetFontSize(38);
        isTyping.SetLetterCase(textLetterCase.OriginalCase);
        isTyping.SetContentVAlign(inkEVerticalAlign.Top);
        isTyping.SetWrappingAtPosition(800);
        isTyping.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        isTyping.SetHAlign(inkEHorizontalAlign.Left);
        isTyping.SetVAlign(inkEVerticalAlign.Top);
        isTyping.SetSize(new Vector2(0.0, 32.0));
        isTyping.SetFitToContent(true);
        isTyping.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        isTyping.BindProperty(n"tintColor", n"Message.TextColor");
        isTyping.BindProperty(n"fontSize", n"MainColors.ReadableSmall");
        isTyping.BindProperty(n"fontStyle", n"MainColors.BodyFontWeight");
        isTyping.Reparent(horizontalPanelWidget16);

        let dot1 = new inkText();
        dot1.SetName(n"isTyping");
        dot1.SetText(".");
        dot1.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        dot1.SetFontStyle(n"Semi-Bold");
        dot1.SetFontSize(38);
        dot1.SetLetterCase(textLetterCase.OriginalCase);
        dot1.SetContentVAlign(inkEVerticalAlign.Top);
        dot1.SetWrappingAtPosition(800);
        dot1.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        dot1.SetHAlign(inkEHorizontalAlign.Left);
        dot1.SetVAlign(inkEVerticalAlign.Top);
        dot1.SetSize(new Vector2(0.0, 32.0));
        dot1.SetFitToContent(true);
        dot1.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        dot1.BindProperty(n"tintColor", n"Message.TextColor");
        dot1.BindProperty(n"fontSize", n"MainColors.ReadableSmall");
        dot1.BindProperty(n"fontStyle", n"MainColors.HeaderFontWeight");
        dot1.Reparent(horizontalPanelWidget16);

        let dot2 = new inkText();
        dot2.SetName(n"isTyping");
        dot2.SetText(".");
        dot2.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        dot2.SetFontStyle(n"Semi-Bold");
        dot2.SetFontSize(38);
        dot2.SetLetterCase(textLetterCase.OriginalCase);
        dot2.SetContentVAlign(inkEVerticalAlign.Top);
        dot2.SetWrappingAtPosition(800);
        dot2.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        dot2.SetHAlign(inkEHorizontalAlign.Left);
        dot2.SetVAlign(inkEVerticalAlign.Top);
        dot2.SetSize(new Vector2(0.0, 32.0));
        dot2.SetFitToContent(true);
        dot2.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        dot2.BindProperty(n"tintColor", n"Message.TextColor");
        dot2.BindProperty(n"fontSize", n"MainColors.ReadableSmall");
        dot2.BindProperty(n"fontStyle", n"MainColors.HeaderFontWeight");
        dot2.Reparent(horizontalPanelWidget16);

        let dot3 = new inkText();
        dot3.SetName(n"isTyping");
        dot3.SetText(".");
        dot3.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        dot3.SetFontStyle(n"Semi-Bold");
        dot3.SetFontSize(38);
        dot3.SetLetterCase(textLetterCase.OriginalCase);
        dot3.SetContentVAlign(inkEVerticalAlign.Top);
        dot3.SetWrappingAtPosition(800);
        dot3.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        dot3.SetHAlign(inkEHorizontalAlign.Left);
        dot3.SetVAlign(inkEVerticalAlign.Top);
        dot3.SetSize(new Vector2(0.0, 32.0));
        dot3.SetFitToContent(true);
        dot3.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        dot3.BindProperty(n"tintColor", n"Message.TextColor");
        dot3.BindProperty(n"fontSize", n"MainColors.ReadableSmall");
        dot3.BindProperty(n"fontStyle", n"MainColors.HeaderFontWeight");
        dot3.Reparent(horizontalPanelWidget16);

        let conversationMask = new inkMask();
        conversationMask.SetName(n"mask");
        conversationMask.SetDataSource(inkMaskDataSource.TextureAtlas);
        conversationMask.SetTextureAtlas(r"base\\gameplay\\gui\\common\\masks.inkatlas");
        conversationMask.SetTexturePart(n"gradMask_journal_description");
        conversationMask.SetDynamicTexture(n"entry_mask");
        conversationMask.SetOpacity(0.01);
        conversationMask.SetSize(new Vector2(1920.0, 1500.0));
        conversationMask.Reparent(conversation);

        let slider = new inkVerticalPanel();
        slider.SetName(n"Slider");
        slider.SetAnchor(inkEAnchor.RightFillVerticaly);
        slider.SetMargin(new inkMargin(0.0, 0.0, -5.0, 0.0));
        slider.SetSize(new Vector2(8.0, 1125.0));
        slider.Reparent(conversation);

        let slidingArea = new inkCanvas();
        slidingArea.SetName(n"slidingArea");
        slidingArea.SetSize(new Vector2(8.0, 1125.0));
        slidingArea.SetChildOrder(inkEChildOrder.Backward);
        slidingArea.Reparent(slider);

        let handle = new inkRectangle();
        handle.SetName(n"Handle");
        handle.SetTintColor(new Color(Cast(255u), Cast(97u), Cast(89u), Cast(255u)));
        handle.SetOpacity(0.3);
        handle.SetAnchor(inkEAnchor.TopFillHorizontaly);
        handle.SetMargin(new inkMargin(0.0, 788.07, 0.0, 0.0));
        handle.SetSize(new Vector2(64.0, 20.0));
        handle.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        handle.BindProperty(n"tintColor", n"MainColors.Red");
        handle.Reparent(slidingArea);

        let sliderBackground = new inkRectangle();
        sliderBackground.SetName(n"Background");
        sliderBackground.SetTintColor(new Color(Cast(14u), Cast(14u), Cast(23u), Cast(255u)));
        sliderBackground.SetOpacity(0.8);
        sliderBackground.SetSize(new Vector2(64.0, 64.0));
        sliderBackground.SetAnchor(inkEAnchor.Fill);
        sliderBackground.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        sliderBackground.BindProperty(n"tintColor", n"MainColors.Fullscreen_PrimaryBackgroundDarkest");
        sliderBackground.Reparent(slidingArea);

        let contentFill = new inkImage();
        contentFill.SetName(n"contentFill");
        contentFill.SetAtlasResource(r"base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");
        contentFill.SetTexturePart(n"item_bg");
        contentFill.SetNineSliceScale(true);
        contentFill.SetTileHAlign(inkEHorizontalAlign.Left);
        contentFill.SetTileVAlign(inkEVerticalAlign.Top);
        contentFill.SetTintColor(new Color(Cast(20u), Cast(20u), Cast(20u), Cast(255u)));
        contentFill.SetOpacity(0.2);
        contentFill.SetAnchor(inkEAnchor.Fill);
        contentFill.SetAnchorPoint(new Vector2(0.5, 0.5));
        contentFill.SetSize(new Vector2(500.0, 500.0));
        contentFill.SetFitToContent(true);
        contentFill.SetAffectsLayoutWhenHidden(true);
        contentFill.Reparent(conversation);

        let contentBorder = new inkImage();
        contentBorder.SetName(n"contentBorder");
        contentBorder.SetAtlasResource(r"base\\gameplay\\gui\\common\\shapes\\atlas_shapes_sync.inkatlas");
        contentBorder.SetTexturePart(n"item_fg");
        contentBorder.SetNineSliceScale(true);
        contentBorder.SetTileHAlign(inkEHorizontalAlign.Left);
        contentBorder.SetTileVAlign(inkEVerticalAlign.Top);
        contentBorder.SetTintColor(new Color(Cast(255u), Cast(97u), Cast(89u), Cast(255u)));
        contentBorder.SetOpacity(0.007);
        contentBorder.SetAnchor(inkEAnchor.Fill);
        contentBorder.SetAnchorPoint(new Vector2(0.5, 0.5));
        contentBorder.SetSize(new Vector2(500.0, 500.0));
        contentBorder.SetFitToContent(true);
        contentBorder.SetAffectsLayoutWhenHidden(true);
        contentBorder.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        contentBorder.BindProperty(n"tintColor", n"MainColors.Red");
        contentBorder.Reparent(conversation);

        let replyOptions = new inkVerticalPanel();
        replyOptions.SetName(n"ReplyOptions");
        replyOptions.SetAnchor(inkEAnchor.BottomLeft);
        replyOptions.SetMargin(new inkMargin(0.0, 10.0, 0.0, 10.0));
        replyOptions.SetSizeCoefficient(0.5);
        replyOptions.SetFitToContent(true);
        replyOptions.Reparent(innerWrapper);

        let choicesList = new inkVerticalPanel();
        choicesList.SetName(n"ChoicesList");
        choicesList.SetHAlign(inkEHorizontalAlign.Right);
        choicesList.SetVAlign(inkEVerticalAlign.Top);
        choicesList.SetFitToContent(true);
        choicesList.SetChildMargin(new inkMargin(0.0, 10.0, 0.0, 0.0));
        choicesList.Reparent(replyOptions);

        let choice1 = new inkHorizontalPanel();
        choice1.SetName(n"item");
        choice1.SetFitToContent(true);
        choice1.SetStyle(r"base\\gameplay\\gui\\fullscreen\\phone_quest_menu\\messenger.inkstyle");
        choice1.SetState(n"QuestSelected");
        choice1.SetChildMargin(new inkMargin(0.0, 0.0, 0.0, 7.0));
        choice1.Reparent(choicesList);

        let flexWidget20 = new inkFlex();
        flexWidget20.SetName(n"inkFlexWidget20");
        flexWidget20.SetHAlign(inkEHorizontalAlign.Right);
        flexWidget20.SetVAlign(inkEVerticalAlign.Top);
        flexWidget20.SetMargin(new inkMargin(10.0, 0.0, 0.0, 0.0));
        flexWidget20.SetSizeRule(inkESizeRule.Stretch);
        flexWidget20.SetFitToContent(true);
        flexWidget20.Reparent(choice1);

        let textFlex = new inkFlex();
        textFlex.SetName(n"textFlex");
        textFlex.SetHAlign(inkEHorizontalAlign.Right);
        textFlex.SetVAlign(inkEVerticalAlign.Top);
        textFlex.SetSize(new Vector2(100.0, 100.0));
        textFlex.Reparent(flexWidget20);

        let textBackground = new inkImage();
        textBackground.SetName(n"background");
        textBackground.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\phone\\new_phone_assets.inkatlas");
        textBackground.SetTexturePart(n"msgBuble_reply_bg");
        textBackground.SetNineSliceScale(true);
        textBackground.SetTileHAlign(inkEHorizontalAlign.Left);
        textBackground.SetTileVAlign(inkEVerticalAlign.Top);
        textBackground.SetTintColor(new Color(Cast(161u), Cast(126u), Cast(51u), Cast(255u)));
        textBackground.SetOpacity(0.15);
        textBackground.SetSize(new Vector2(32.0, 32.0));
        textBackground.SetFitToContent(true);
        textBackground.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        textBackground.BindProperty(n"tintColor", n"MessageReply.BackgroundColor");
        textBackground.BindProperty(n"opacity", n"MessageReply.BackgroundOpacity");
        textBackground.Reparent(textFlex);

        let activeTextWrapper = new inkHorizontalPanel();
        activeTextWrapper.SetName(n"active_text_wrapper");
        activeTextWrapper.SetHAlign(inkEHorizontalAlign.Right);
        activeTextWrapper.SetVAlign(inkEVerticalAlign.Center);
        activeTextWrapper.SetFitToContent(true);
        activeTextWrapper.Reparent(textFlex);
        this.typedMessageWrapper = activeTextWrapper;

        let captionImage = new inkHorizontalPanel();
        captionImage.SetName(n"captionImageHorz_primary");
        captionImage.SetHAlign(inkEHorizontalAlign.Right);
        captionImage.SetVAlign(inkEVerticalAlign.Center);
        captionImage.SetMargin(new inkMargin(20.0, 0.0, 0.0, 0.0));
        captionImage.SetFitToContent(true);
        captionImage.SetChildMargin(new inkMargin(0.0, 0.0, 5.0, 0.0));
        captionImage.Reparent(activeTextWrapper);

        let activeItemText = new inkText();
        activeItemText.SetName(n"activeItemText");
        activeItemText.SetText("Send a message.");
        activeItemText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        activeItemText.SetFontStyle(n"Medium");
        activeItemText.SetFontSize(42);
        activeItemText.SetLetterCase(textLetterCase.OriginalCase);
        activeItemText.SetOverflowPolicy(textOverflowPolicy.DotsEnd);
        activeItemText.SetWrappingAtPosition(1000);
        activeItemText.SetTintColor(new Color(Cast(255u), Cast(255u), Cast(78u), Cast(255u)));
        activeItemText.SetHAlign(inkEHorizontalAlign.Left);
        activeItemText.SetVAlign(inkEVerticalAlign.Center);
        activeItemText.SetMargin(new inkMargin(17.0, 17.0, 30.0, 30.0));
        activeItemText.SetSize(new Vector2(750.0, 63.0));
        activeItemText.SetFitToContent(true);
        activeItemText.SetTranslation(new Vector2(0.50, 0.50));
        activeItemText.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        activeItemText.BindProperty(n"fontSize", n"MainColors.ReadableMedium");
        activeItemText.BindProperty(n"fontStyle", n"MainColors.BodyFontWeight");
        activeItemText.BindProperty(n"tintColor", n"MessageReply.TextColor");
        activeItemText.BindProperty(n"opacity", n"MessageReply.TextOpacity");
        activeItemText.Reparent(activeTextWrapper);
        this.typedMessageText = activeItemText;

        let textBorder = new inkImage();
        textBorder.SetName(n"border");
        textBorder.SetAtlasResource(r"base\\gameplay\\gui\\widgets\\phone\\new_phone_assets.inkatlas");
        textBorder.SetTexturePart(n"msgBuble_reply_fg");
        textBorder.SetNineSliceScale(true);
        textBorder.SetTileHAlign(inkEHorizontalAlign.Left);
        textBorder.SetTileVAlign(inkEVerticalAlign.Top);
        textBorder.SetTintColor(new Color(Cast(161u), Cast(126u), Cast(51u), Cast(255u)));
        textBorder.SetSize(new Vector2(32.0, 32.0));
        textBorder.SetFitToContent(true);
        textBorder.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        textBorder.BindProperty(n"tintColor", n"MessageReply.BorderColor");
        textBorder.BindProperty(n"opacity", n"MessageReply.BorderOpacity");
        textBorder.Reparent(textFlex);

        let sqQuestCanvas = new inkCanvas();
        sqQuestCanvas.SetName(n"SQ_quest_canvas");
        sqQuestCanvas.SetVAlign(inkEVerticalAlign.Bottom);
        sqQuestCanvas.SetMargin(new inkMargin(10.0, 0.0, 0.0, 0.0));
        sqQuestCanvas.SetSize(new Vector2(43.0, 43.0));
        sqQuestCanvas.SetAffectsLayoutWhenHidden(true);
        sqQuestCanvas.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        sqQuestCanvas.BindProperty(n"opacity", n"MessageReply.SelectionBulletOpacity");
        sqQuestCanvas.SetChildOrder(inkEChildOrder.Backward);
        sqQuestCanvas.Reparent(choice1);

        let hintReply = new inkHorizontalPanel();
        hintReply.SetName(n"hint_reply");
        hintReply.SetAnchor(inkEAnchor.CenterRight);
        hintReply.SetAnchorPoint(new Vector2(1, 1));
        hintReply.SetHAlign(inkEHorizontalAlign.Left);
        hintReply.SetVAlign(inkEVerticalAlign.Top);
        hintReply.SetMargin(new inkMargin(0.0, 0.0, -36.0, 0.0));
        hintReply.SetFitToContent(true);
        hintReply.SetChildMargin(new inkMargin(0.0, 0.0, 10.0, 0.0));
        hintReply.Reparent(sqQuestCanvas);

        let hintReplyIcon = new inkImage();
        hintReplyIcon.SetName(n"inputIcon");
        hintReplyIcon.SetAtlasResource(r"base\\gameplay\\gui\\common\\input\\icons_keyboard.inkatlas");
        hintReplyIcon.SetTexturePart(n"mouse_left");
        hintReplyIcon.SetTileHAlign(inkEHorizontalAlign.Left);
        hintReplyIcon.SetTileVAlign(inkEVerticalAlign.Top);
        hintReplyIcon.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        hintReplyIcon.SetAnchor(inkEAnchor.Centered);
        hintReplyIcon.SetHAlign(inkEHorizontalAlign.Center);
        hintReplyIcon.SetVAlign(inkEVerticalAlign.Center);
        hintReplyIcon.SetSize(new Vector2(64.0, 64.0));
        hintReplyIcon.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        hintReplyIcon.BindProperty(n"tintColor", n"MainColors.Blue");
        hintReplyIcon.Reparent(hintReply);
        this.chatInputHint = hintReplyIcon;

        let contentSizeProvider = new inkCanvas();
        contentSizeProvider.SetName(n"sizeProvider");
        contentSizeProvider.SetHAlign(inkEHorizontalAlign.Left);
        contentSizeProvider.SetVAlign(inkEVerticalAlign.Top);
        contentSizeProvider.SetMargin(new inkMargin(24.0, 0.0, 24.0, 0.0));
        contentSizeProvider.SetSize(new Vector2(1250.0, 1250.0));
        contentSizeProvider.SetChildOrder(inkEChildOrder.Backward);
        contentSizeProvider.Reparent(wrapperContent);

        let hrUnderContent = new inkRectangle();
        hrUnderContent.SetName(n"hrUnderContent");
        hrUnderContent.SetTintColor(new Color(Cast(255u), Cast(97u), Cast(89u), Cast(255u)));
        hrUnderContent.SetAnchor(inkEAnchor.BottomFillHorizontaly);
        hrUnderContent.SetVAlign(inkEVerticalAlign.Bottom);
        hrUnderContent.SetOpacity(0.2);
        hrUnderContent.SetMargin(new inkMargin(120.0, 10.0, 20.0, 0.0));
        hrUnderContent.SetSize(new Vector2(0.0, 2.0));
        hrUnderContent.SetRenderTransformPivot(new Vector2(0, 0.5));
        hrUnderContent.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        hrUnderContent.BindProperty(n"tintColor", n"MainColors.Red");
        hrUnderContent.Reparent(rootWrapper);

        let wrapperInputHints = new inkHorizontalPanel();
        wrapperInputHints.SetName(n"inputHints");
        wrapperInputHints.SetHAlign(inkEHorizontalAlign.Right);
        wrapperInputHints.SetVAlign(inkEVerticalAlign.Top);
        wrapperInputHints.SetFitToContent(true);
        wrapperInputHints.SetTranslation(new Vector2(0.0, 25.0));
        wrapperInputHints.SetChildMargin(new inkMargin(30.0, 0.0, 0.0, 0.0));
        wrapperInputHints.Reparent(rootWrapper);

        let hintClose = new inkHorizontalPanel();
        hintClose.SetName(n"hint_close");
        hintClose.SetAnchor(inkEAnchor.TopRight);
        hintClose.SetAnchorPoint(new Vector2(1, 0));
        hintClose.SetHAlign(inkEHorizontalAlign.Left);
        hintClose.SetVAlign(inkEVerticalAlign.Top);
        hintClose.SetFitToContent(true);
        hintClose.Reparent(wrapperInputHints);

        let hintCloseIcon = new inkImage();
        hintCloseIcon.SetName(n"inputIcon");
        hintCloseIcon.SetAtlasResource(r"base\\gameplay\\gui\\common\\input\\icons_keyboard.inkatlas");
        hintCloseIcon.SetTexturePart(n"kb_c");
        hintCloseIcon.SetSize(new Vector2(64.0, 64.0));
        hintCloseIcon.SetTileHAlign(inkEHorizontalAlign.Left);
        hintCloseIcon.SetTileVAlign(inkEVerticalAlign.Top);
        hintCloseIcon.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
        hintCloseIcon.SetAnchor(inkEAnchor.Centered);
        hintCloseIcon.SetHAlign(inkEHorizontalAlign.Center);
        hintCloseIcon.SetVAlign(inkEVerticalAlign.Center);
        hintCloseIcon.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        hintCloseIcon.BindProperty(n"tintColor", n"MainColors.Blue");
        hintCloseIcon.Reparent(hintClose);

        let hintCloseText = new inkText();
        hintCloseText.SetName(n"action");
        hintCloseText.SetText("Close");
        hintCloseText.SetFontFamily("base\\gameplay\\gui\\fonts\\raj\\raj.inkfontfamily");
        hintCloseText.SetFontStyle(n"Semi-Bold");
        hintCloseText.SetFontSize(38);
        hintCloseText.SetLetterCase(textLetterCase.UpperCase);
        hintCloseText.SetTintColor(new Color(Cast(255u), Cast(97u), Cast(89u), Cast(255u)));
        hintCloseText.SetAnchor(inkEAnchor.TopRight);
        hintCloseText.SetAnchorPoint(new Vector2(1, 0));
        hintCloseText.SetVAlign(inkEVerticalAlign.Center);
        hintCloseText.SetMargin(new inkMargin(7.5, 5.0, 5.0, 0.0));
        hintCloseText.SetSize(new Vector2(100.0, 32.0));
        hintCloseText.SetFitToContent(true);
        hintCloseText.SetStyle(r"base\\gameplay\\gui\\common\\main_colors.inkstyle");
        hintCloseText.BindProperty(n"fontStyle", n"MainColors.ReadableSmall");
        hintCloseText.BindProperty(n"tintColor", n"MainColors.Red");
        hintCloseText.Reparent(hintClose);

        let translateAnimRoot = new inkAnimTranslation();
        translateAnimRoot.SetStartTranslation(new Vector2(250.0, 0.0));
        translateAnimRoot.SetEndTranslation(new Vector2(0, 0));
        translateAnimRoot.SetType(inkanimInterpolationType.Linear);
        translateAnimRoot.SetMode(inkanimInterpolationMode.EasyOut);
        translateAnimRoot.SetDuration(0.1);

        let alphaAnim = new inkAnimTransparency();
        alphaAnim.SetStartTransparency(0.0);
        alphaAnim.SetEndTransparency(1.0);
        alphaAnim.SetType(inkanimInterpolationType.Linear);
        alphaAnim.SetMode(inkanimInterpolationMode.EasyOut);
        alphaAnim.SetDuration(0.1);

        let animDefRoot = new inkAnimDef();
        animDefRoot.AddInterpolator(translateAnimRoot);
        animDefRoot.AddInterpolator(alphaAnim);

        modMessengerSlotRoot.PlayAnimation(animDefRoot);
    }
}
