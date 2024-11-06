import Codeware.*

public class GenerativePhoneSystem extends ScriptableService {
    private let callbackSystem: wref<CallbackSystem>;
    private let panamSelected: Bool = false;
    private let chatOpen: Bool = false;
    private let blackboardSystem: ref<BlackboardSystem>;
    private let uiBlackboard: wref<IBlackboard>;
    private let widgetInstance: wref<inkWidget>;
    private let parent: wref<inkCanvas>;

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
        LogChannel(n"DEBUG", s"Panam selected: \(this.panamSelected)");
    }

    private func ShowModChat() {
        this.chatOpen = true;
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
            ConsoleLog("Removing existing mod messenger slot...");
            this.parent.RemoveChildByName(n"mod_messenger_slot");
        }

        let modMessengerSlot = new inkCanvas();
        modMessengerSlot.Reparent(this.parent);
        modMessengerSlot.SetMargin(new inkMargin(1400.0, 480.0, 0.0, 0.0));
        modMessengerSlot.SetChildOrder(inkEChildOrder.Backward);
        modMessengerSlot.SetName(n"mod_messenger_slot");
    }
}
