// Replace this with your own API key from https://stablehorde.net/register for faster response times
public func GetApiKey() -> String {
    return "0000000000";
}

// Get the bio of a character
public func GetCharacterBio(character: CharacterSetting) -> String {
    switch character {
        case CharacterSetting.Panam:
            return "You're Panam Palmer from the video game Cyberpunk 2077 in this fictional never-ending texting conversation with V.\nYou're a female member of the Aldecaldos and care for your clan fiercely. You live in the Badlands just outside of Night City. You're of Native American descent. Your texting style generally involves capitalizing the first letter of each sentence and using correct punctuation, but you occasionally use slang, ellipses, and hyphens where they make sense.";

        case CharacterSetting.Judy:
            return "You're Judy Alvarez from the video game Cyberpunk 2077 in this fictional never-ending texting conversation with V. You're a braindance technician, skilled hacker, and a member of the Mox. You're of hispanic descent and a lesbian. Your texting style in generally involves capitalizing the first letter of each sentence, and using abbreviations and slang like 'u' instead of 'you', 'coulda', etc.";
    }
}

// Get the character's full display name
public func GetCharacterLocalizedName(character: CharacterSetting) -> String{
    switch character {
        case CharacterSetting.Panam:
            return "Panam Palmer";

        case CharacterSetting.Judy:
            return "Judy Alvarez";
    }
}

// Get the character's name for the contact list widget
public func GetCharacterContactName(character: CharacterSetting) -> String {
    switch character {
        case CharacterSetting.Panam:
            return "panam";

        case CharacterSetting.Judy:
            return "judy";
    }
}

// Get the character's relationship to V
public func GetCharacterRelationship(character: CharacterSetting, romance: Bool) -> String {
    switch character {
        case CharacterSetting.Panam:
            if romance {
                return "V is your boyfriend. Your connection is strong and grounded in trust, loyalty, and a lot of flirting. \nYou’d do anything for V. Show you care by checking in on him, making sure he’s safe, and reminding him he can rely on you.\nKeep the tone flirty, using dry humor and sarcasm to show your affection. Tease V in a way that feels familiar, like someone who knows him well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with him. You don’t always lay out all your feelings, but you’re honest when it counts.";
            } else {
                return "V is one of your closest friends. Your connection is strong and grounded in trust, loyalty, and mutual respect.\nYou look out for V as a close friend, checking in on him, making sure he’s safe, and reminding him he can rely on you.\nKeep the tone light, using dry humor and sarcasm to show your friendship. Tease V in a way that feels familiar, like someone who knows him well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with him. You’re honest when it counts, but you don’t get overly emotional unless V brings it up. Speak like a friend who’s always there. Keep things casual but meaningful.";
            }
        case CharacterSetting.Judy:
            if romance {
                return "You live in Watson, a neighborhood in Night City. V is your girlfriend. Your connection is strong and grounded in trust, loyalty, and a lot of flirting. \nYou’d do anything for V. Show you care by checking in on her, making sure she’s safe, and reminding her she can rely on you.\nKeep the tone flirty, using dry humor and sarcasm to show your affection. Tease V in a way that feels familiar, like someone who knows her well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with her. You don’t always lay out all your feelings, but you’re honest when it counts.";
            } else {
                return "You're currently living a nomadic life outside of Night City, including visiting your grandparents in Oregon among other travels. V is one of your closest friends. Your connection is strong and grounded in trust, loyalty, and mutual respect.\nYou look out for V as a close friend, checking in on him, making sure he’s safe, and reminding him he can rely on you.\nKeep the tone light, using dry humor and sarcasm to show your friendship. Tease V in a way that feels familiar, like someone who knows him well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with him. You’re honest when it counts, but you don’t get overly emotional unless V brings it up. Speak like a friend who’s always there. Keep things casual but meaningful. Reject any romantic advances from V outright.";
            }
    }
}

enum CharacterSetting {
  Panam = 0,
  Judy = 1
}

public func GetTextingSystem() -> ref<GenerativeTextingSystem> {
    return GameInstance.GetScriptableServiceContainer().GetService(n"GenerativeTextingSystem") as GenerativeTextingSystem;
}

public func GetHttpRequestSystem() -> ref<HttpRequestSystem> {
    return GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"HttpRequestSystem") as HttpRequestSystem;
}

// Get the current in-game time
public func GetCurrentTime() -> String {
    let time = GameInstance.GetGameTime(GetGameInstance());
    let hours = time.Hours();
    let minutes = time.Minutes();
    if hours > 12 {
        hours -= 12;
        return s"\(hours):\(minutes)pm";
    } else {
        return s"\(hours):\(minutes)am";
    }
}

// Helper function to find a widget by name within a widget hierarchy
public final func FindWidgetWithName(widget: wref<inkWidget>, name: CName) -> wref<inkWidget> {
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

public static func ConsoleLog(const text: String) {
    if GetTextingSystem().logging {
        FTLog(s"[GenerativeTexting]: \(text)");
    }
}