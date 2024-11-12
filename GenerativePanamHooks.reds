@wrapMethod(PlayerPuppet)
protected cb func OnMakePlayerVisibleAfterSpawn(evt: ref<EndGracePeriodAfterSpawn>) -> Bool { 
    wrappedMethod(evt);
    
    let modPhoneSystem = GameInstance.GetScriptableServiceContainer().GetService(n"GenerativePhoneSystem") as GenerativePhoneSystem;
    if IsDefined(modPhoneSystem) {
        modPhoneSystem.InitializeSystem();
    } else {
        ConsoleLog("Phone system not defined.");
    }
}

@wrapMethod(PhoneDialerLogicController)
private final func RefreshInputHints(contactData: wref<ContactData>) -> Void {
    wrappedMethod(contactData);

    let modPhoneSystem = GameInstance.GetScriptableServiceContainer().GetService(n"GenerativePhoneSystem") as GenerativePhoneSystem;

    if contactData != null {
        let contactName = contactData.contactId;

        // Check if the selected contact is Panam Palmer
        if Equals(contactName, "panam") {
            if modPhoneSystem != null {
                modPhoneSystem.TogglePanamSelected(true);
            }
            // Assuming m_contactList is the main container holding all contact entries
            let contactListWidget = inkWidgetRef.Get(this.m_contactsList) as inkCompoundWidget;
            if IsDefined(contactListWidget) {

                let numChildren = contactListWidget.GetNumChildren();
                let i = 0;
                while i < numChildren {
                    let contactEntry = contactListWidget.GetWidgetByIndex(i) as inkCompoundWidget;
                    if IsDefined(contactEntry) {

                        // Check if this entry corresponds to Panam's hints_holder
                        let contactLabel = FindWidgetWithName(contactEntry, n"contactLabel") as inkText;
                        if IsDefined(contactLabel) && Equals(contactLabel.GetText(), "Panam Palmer") {

                            // Locate the hints_holder within Panam's entry
                            let hintsHolderWidget = FindWidgetWithName(contactEntry, n"hints_holder") as inkHorizontalPanel;
                            if IsDefined(hintsHolderWidget) {

                                if NotEquals(s"\(hintsHolderWidget.parentWidget.GetName())", "horiz_holder") {
                                    return;
                                }

                                // Check if hint_mod already exists
                                let hintMod = FindWidgetWithName(hintsHolderWidget, n"hint_mod") as inkHorizontalPanel;
                                if IsDefined(hintMod) {

                                } else {
                                    // Create hint_mod since it doesn't exist
                                    hintMod = hintsHolderWidget.AddChild(n"inkHorizontalPanel") as inkHorizontalPanel;
                                    if IsDefined(hintMod) {
                                        hintMod.SetName(n"hint_mod");
                                        hintMod.SetVisible(true);
                                        hintMod.SetAnchor(inkEAnchor.TopRight);
                                        hintMod.SetVAlign(inkEVerticalAlign.Center);
                                        hintMod.SetHAlign(inkEHorizontalAlign.Right);
                                        ConsoleLog("Adding modded input hint to UI.");

                                        // Add icon and text to hint_mod
                                        let keyWidget = hintMod.AddChild(n"inkImage") as inkImage;
                                        if IsDefined(keyWidget) {
                                            keyWidget.SetName(n"inputIcon");
                                            keyWidget.SetAtlasResource(r"base\\gameplay\\gui\\common\\input\\icons_keyboard.inkatlas");
                                            keyWidget.SetTexturePart(n"kb_t");
                                            keyWidget.SetSize(new Vector2(64.0, 64.0));
                                            keyWidget.SetScale(new Vector2(1, 1));
                                            keyWidget.SetAnchor(inkEAnchor.Centered);
                                            keyWidget.SetVisible(true);
                                            keyWidget.SetVAlign(inkEVerticalAlign.Center);
                                            keyWidget.SetHAlign(inkEHorizontalAlign.Center);
                                            keyWidget.BindProperty(n"tintColor", n"ContactListItem.fontColor");
                                            keyWidget.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
                                        }

                                        let iconWidget = hintMod.AddChild(n"inkImage") as inkImage;
                                        if IsDefined(iconWidget) {
                                            iconWidget.SetName(n"fluff");
                                            iconWidget.SetAtlasResource(r"base\\gameplay\\gui\\common\\icons\\atlas_common.inkatlas");
                                            iconWidget.SetTexturePart(n"ico_envelelope_reply1");
                                            iconWidget.SetSize(new Vector2(48.0, 48.0));    
                                            iconWidget.SetScale(new Vector2(1, 1));
                                            iconWidget.SetAnchor(inkEAnchor.TopLeft);
                                            iconWidget.SetVAlign(inkEVerticalAlign.Center);
                                            iconWidget.SetHAlign(inkEHorizontalAlign.Center);
                                            iconWidget.SetMargin(new inkMargin(7.0, 9.0, 8.0, 0.0));
                                            iconWidget.SetFitToContent(true);
                                            iconWidget.SetTintColor(new Color(Cast(94u), Cast(246u), Cast(255u), Cast(255u)));
                                            iconWidget.BindProperty(n"tintColor", n"MainColors.Blue");
                                            iconWidget.BindProperty(n"opacity", n"MenuLabel.MainOpacity");
                                            iconWidget.SetVisible(true);
                                        }

                                        hintsHolderWidget.ReorderChild(hintMod, 0);
                                        
                                    } else {
                                        ConsoleLog("Failed to add hint_mod to hints_holder.");
                                    }
                                }
                            } else {
                                ConsoleLog("hints_holder not found in Panam's entry.");
                            }
                            break;
                        }
                    }
                    i += 1;
                }
            } else {
                ConsoleLog("contactListWidget not found.");
            }
        } else {
            if modPhoneSystem != null {
                modPhoneSystem.TogglePanamSelected(false);
            }
        }
    }
}

// Helper function to find a widget by name within a widget hierarchy
private final func FindWidgetWithName(widget: wref<inkWidget>, name: CName) -> wref<inkWidget> {
    if Equals(widget.GetName(), name) {
        return widget;
    }
    let compoundWidget = widget as inkCompoundWidget;
    if IsDefined(compoundWidget) {
        let numChildren = compoundWidget.GetNumChildren();
        let i = 0;
        while i < numChildren {
            let foundWidget = FindWidgetWithName(compoundWidget.GetWidgetByIndex(i), name);
            if IsDefined(foundWidget) {
                return foundWidget;
            }
            i += 1;
        }
    }
    return null;
}

@wrapMethod(PhoneDialerLogicController)
public final func Hide() -> Void {
    wrappedMethod();
    let modPhoneSystem = GameInstance.GetScriptableServiceContainer().GetService(n"GenerativePhoneSystem") as GenerativePhoneSystem;

    if IsDefined(modPhoneSystem) {
        modPhoneSystem.TogglePanamSelected(false);
        modPhoneSystem.ToggleIsTyping(false);
    }
}

@wrapMethod(MessengerNotification)
public cb func SetNotificationData(notificationData: ref<GenericNotificationViewData>) -> Void {
    wrappedMethod(notificationData);
    ConsoleLog("Setting notification data.");
}

@addMethod(NewHudPhoneGameController)
public final func PushCustomSMSNotification(text: String) -> Void {
    let notificationData: gameuiGenericNotificationData;
    let userData: ref<PhoneMessageNotificationViewData> = new PhoneMessageNotificationViewData();
    let action = new OpenPhoneMessageAction();
    action.m_phoneSystem = this.m_PhoneSystem;
    userData.title = "Panam Palmer";
    userData.SMSText = text;
    userData.animation = n"notification_phone_MSG";
    userData.soundEvent = n"PhoneSmsPopup";
    userData.soundAction = n"OnOpen";
    userData.action = action;
    notificationData.time = 6.70;
    notificationData.widgetLibraryItemName = n"notification_message";
    notificationData.notificationData = userData;
    this.AddNewNotificationData(notificationData);
}

