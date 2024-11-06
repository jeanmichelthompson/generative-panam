import Codeware.*

public class GenerativePhoneSystem extends ScriptableService {
    private let callbackSystem: wref<CallbackSystem>;
    private let panamSelected: Bool = false;
    private let chatOpen: Bool = false;
    private let blackboardSystem: ref<BlackboardSystem>;
    private let uiBlackboard: wref<IBlackboard>;
    private let widgetInstance: wref<inkWidget>;
    private let parent: wref<inkCanvas>;
    private let chatContainer: wref<inkCanvas>;

    private cb func OnLoad() {
        this.InitializeSystem();
        LogChannel(n"DEBUG", s"System loaded");
    } 

    private cb func OnReload() {
        LogChannel(n"DEBUG", "Scripts reloaded");
        this.InitializeSystem();
    }
    
    private func InitializeSystem() {
        LogChannel(n"DEBUG", "Initializing system...");
        this.panamSelected = false;
        this.chatOpen = false;
        this.callbackSystem = GameInstance.GetCallbackSystem();
        this.callbackSystem.RegisterCallback(n"Input/Key", this, n"OnKeyInput", true);
        let inkSystem = GameInstance.GetInkSystem();
        let virtualWindow = inkSystem.GetLayer(n"inkHUDLayer").GetVirtualWindow();
        let virtualWindowRoot = virtualWindow.GetWidget(0) as inkCanvas;
        let hudMiddleWidget = virtualWindowRoot.GetWidget(53) as inkCanvas;
        this.parent = hudMiddleWidget.GetWidget(0) as inkCanvas;
        this.SetupChatContainer();

        LogChannel(n"DEBUG", "System initialized");

        // Obtain the blackboard system and UI blackboard
        this.blackboardSystem = GetGameInstance().GetBlackboardSystem();
        this.uiBlackboard = this.blackboardSystem.Get(GetAllBlackboardDefs().UI_ComDevice);
    }

    private cb func OnKeyInput(event: ref<KeyInputEvent>) {
        if !this.panamSelected {
            return;
        }

        if NotEquals(s"\(event.GetKey())", "IK_T") || NotEquals(s"\(event.GetAction())", "IACT_Press") {
            return;
        }

        if !this.chatOpen {
            this.HidePhoneUI();
            this.ShowModChat();
        }
    }

    public func togglePanamSelected(value: Bool) {
        this.panamSelected = value;
    }

    private func ShowModChat() {
        this.chatOpen = true;
        this.BuildChatUi();
        LogChannel(n"DEBUG", "Showing mod chat...");
    }

    private func HideModChat() {
        this.chatOpen = false;
        LogChannel(n"DEBUG", "Hiding mod chat...");

        if IsDefined(this.widgetInstance) {
            this.widgetInstance.SetVisible(false);
            LogChannel(n"DEBUG", "Mod chat widget hidden.");
        } else {
            LogChannel(n"DEBUG", "No mod chat widget to hide.");
        }
    }

    // Function to hide the phone UI
    private func HidePhoneUI() {
        if IsDefined(this.uiBlackboard) {
            this.uiBlackboard.SetBool(GetAllBlackboardDefs().UI_ComDevice.ContactsActive, false, true);
            LogChannel(n"DEBUG", "Phone UI hidden.");
        } else {
            LogChannel(n"DEBUG", "Failed to access Blackboard for UI.");
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

        let rootContainer = new inkCanvas();
        rootContainer.SetName(n"container");
        rootContainer.SetMargin(new inkMargin(100.0, 0.0, 0.0, 0.0));
        rootContainer.SetSize(new Vector2(1550.0, 1200.0));
        rootContainer.SetChildOrder(inkEChildOrder.Backward);
        rootContainer.Reparent(modMessengerSlotRoot);

        let rootWrapper = new inkVerticalPanel();
        rootWrapper.SetName(n"wrapper");
        rootWrapper.SetMargin(new inkMargin(100.0, 50.0, 0.0, 0.0));
        rootWrapper.SetFitToContent(true);
        rootWrapper.Reparent(modMessengerSlotRoot);
    }
}
