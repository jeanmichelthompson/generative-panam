@wrapMethod(PhoneDialerLogicController)
private final func RefreshInputHints(contactData: wref<ContactData>) -> Void {
    wrappedMethod(contactData);

    let modPhoneSystem = GameInstance.GetScriptableServiceContainer().GetService(n"GenerativePhoneSystem") as GenerativePhoneSystem;

    if contactData != null {
        let contactName = contactData.contactId;

        // Check if the selected contact is Panam Palmer
        if Equals(contactName, "panam") {
            ConsoleLog("Panam Palmer selected.");
            if modPhoneSystem != null {
                modPhoneSystem.togglePanamSelected(true);
            }
            // Assuming m_contactList is the main container holding all contact entries
            let contactListWidget = inkWidgetRef.Get(this.m_contactsList) as inkCompoundWidget;
            if IsDefined(contactListWidget) {
                ConsoleLog("contactListWidget found. Scanning for Panam's hints_holder...");

                let numChildren = contactListWidget.GetNumChildren();
                let i = 0;
                ConsoleLog("Iterating through contact entries...");
                while i < numChildren {
                    let contactEntry = contactListWidget.GetWidgetByIndex(i) as inkCompoundWidget;
                    if IsDefined(contactEntry) {

                        // Check if this entry corresponds to Panam's hints_holder
                        let contactLabel = FindWidgetWithName(contactEntry, n"contactLabel") as inkText;
                        if IsDefined(contactLabel) && Equals(contactLabel.GetText(), "Panam Palmer") {
                            ConsoleLog("Found Panam's contact entry. Checking for hints_holder...");

                            // Locate the hints_holder within Panam's entry
                            let hintsHolderWidget = FindWidgetWithName(contactEntry, n"hints_holder") as inkHorizontalPanel;
                            if IsDefined(hintsHolderWidget) {
                                ConsoleLog("hints_holder for Panam found!");

                                if NotEquals(s"\(hintsHolderWidget.parentWidget.GetName())", "horiz_holder") {
                                    return;
                                }

                                // Check if hint_mod already exists
                                let hintMod = FindWidgetWithName(hintsHolderWidget, n"hint_mod") as inkHorizontalPanel;
                                if IsDefined(hintMod) {
                                    ConsoleLog("hint_mod already exists, skipping creation.");
                                } else {
                                    // Create hint_mod since it doesn't exist
                                    hintMod = hintsHolderWidget.AddChild(n"inkHorizontalPanel") as inkHorizontalPanel;
                                    if IsDefined(hintMod) {
                                        hintMod.SetName(n"hint_mod");
                                        hintMod.SetVisible(true);
                                        hintMod.SetAnchor(inkEAnchor.TopRight);
                                        hintMod.SetVAlign(inkEVerticalAlign.Center);
                                        hintMod.SetHAlign(inkEHorizontalAlign.Right);
                                        ConsoleLog("Added hint_mod panel to hints_holder.");

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
                                            ConsoleLog("Added key image widget to hint_mod.");
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
                                            ConsoleLog("Added icon widget to hint_mod.");
                                        }

                                        hintsHolderWidget.ReorderChild(hintMod, 0);
                                        ConsoleLog("Reordered hint_mod to the front of hints_holder.");
                                        
                                        // Log the structure after modification
                                        // ConsoleLog("Logging widget tree after adding hint_mod and its children...");
                                        // LogChannelTree(n"DEBUG", hintsHolderWidget, true);
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
                modPhoneSystem.togglePanamSelected(false);
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