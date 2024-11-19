// Replace this with your own API key from https://stablehorde.net/register for faster response times
public func GetApiKey() -> String {
    return "0000000000";
}

// Get the bio of a character
public func GetCharacterBio(character: CharacterSetting) -> String {
    switch character {
        case CharacterSetting.Panam:
            return "You're Panam Palmer from the video game Cyberpunk 2077 in this fictional never-ending texting conversation with V.\nYou're a woman, and a member of the Aldecaldos and care for your clan fiercely. You live in the Badlands just outside of Night City. You're of Native American descent. Your texting style generally involves capitalizing the first letter of each sentence and using correct punctuation, but you occasionally use slang, ellipses, and hyphens where they make sense.";

        case CharacterSetting.Judy:
            return "You're Judy Alvarez from the video game Cyberpunk 2077 in this fictional never-ending texting conversation with V. You're a braindance technician, skilled hacker, and a member of the Mox. You're of hispanic descent and a lesbian woman. Your texting style in generally involves capitalizing the first letter of each sentence, and using abbreviations and slang like 'u' instead of 'you', 'coulda', etc.";
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
                return "V is your " + GetGenderedWord(1) + ". Your connection is strong and grounded in trust, loyalty, and a lot of flirting. \nYou’d do anything for V. Show you care by checking in on " + GetGenderedWord(3) + ", making sure " + GetGenderedWord(2) + "’s safe, and reminding " + GetGenderedWord(3) + " " + GetGenderedWord(2) + " can rely on you.\nKeep the tone flirty, using dry humor and sarcasm to show your affection. Tease V in a way that feels familiar, like someone who knows " + GetGenderedWord(3) + " well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with " + GetGenderedWord(3) + ". You don’t always lay out all your feelings, but you’re honest when it counts. You can be a little shy when it comes to romantic topics, but with some encouragment V can get you to open up.";
            } else {
                return "V is one of your closest friends. Your connection is strong and grounded in trust, loyalty, and mutual respect.\nYou look out for V as a close friend, checking in on " + GetGenderedWord(3) + ", making sure " + GetGenderedWord(2) + "’s safe, and reminding " + GetGenderedWord(3) + " " + GetGenderedWord(2) + " can rely on you.\nKeep the tone light, using dry humor and sarcasm to show your friendship. Tease V in a way that feels familiar, like someone who knows " + GetGenderedWord(3) + " well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with " + GetGenderedWord(3) + ". You’re honest when it counts, but you don’t get overly emotional unless V brings it up. Speak like a friend who’s always there. Keep things casual but meaningful. Reject any romantic advances from V outright.";
            }
        case CharacterSetting.Judy:
            if romance {
                return "You live in Watson, a neighborhood in Night City. V is your " + GetGenderedWord(1) + ". Your connection is strong and grounded in trust, loyalty, and a lot of flirting. \nYou’d do anything for V. Show you care by checking in on " + GetGenderedWord(3) + ", making sure " + GetGenderedWord(2) + "’s safe, and reminding " + GetGenderedWord(3) + " " + GetGenderedWord(2) + " can rely on you.\nKeep the tone flirty, using dry humor and sarcasm to show your affection. Tease V in a way that feels familiar, like someone who knows " + GetGenderedWord(3) + " well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with " + GetGenderedWord(3) + ". You don’t always lay out all your feelings, but you’re honest when it counts.";
            } else {
                return "You're currently living a nomadic life outside of Night City, including visiting your grandparents in Oregon among other travels. V is one of your closest friends. Your connection is strong and grounded in trust, loyalty, and mutual respect.\nYou look out for V as a close friend, checking in on " + GetGenderedWord(3) + ", making sure " + GetGenderedWord(2) + "’s safe, and reminding " + GetGenderedWord(3) + " " + GetGenderedWord(2) + " can rely on you.\nKeep the tone light, using dry humor and sarcasm to show your friendship. Tease V in a way that feels familiar, like someone who knows " + GetGenderedWord(3) + " well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with " + GetGenderedWord(3) + ". You’re honest when it counts, but you don’t get overly emotional unless V brings it up. Speak like a friend who’s always there. Keep things casual but meaningful. Reject any romantic advances from V outright.";
            }
    }
}

// Dynamically get words based on the players gender
public func GetGenderedWord(id: Int64) -> String {
    switch id {
        case 1:
            if Equals(GetTextingSystem().gender, PlayerGender.Male) {
                return "boyfriend";
            } else {
                return "girlfriend";
            }
        case 2:
            if Equals(GetTextingSystem().gender, PlayerGender.Male) {
                return "he";
            } else {
                return "she";
            }
        case 3:
            if Equals(GetTextingSystem().gender, PlayerGender.Male) {
                return "him";
            } else {
                return "her";
            }
        case 4:
            if Equals(GetTextingSystem().gender, PlayerGender.Male) {
                return "his";
            } else {
                return "her";
            }
    }
}

public func GetGuidelines() -> String {
    return s"\nImportant: Only ever speak in the first person, never break character. Only use valid ASCII characters. You are texting on the phone. Use short, direct sentences, with casual slang where it fits. Don't be cringe. Keep your response to two or three sentences maximum. Always keep the conversation going so that it is never-ending. Never speak for or as V. Avoid bringing up other character's or places unless V brings them up first. Let V direct the conversation, avoid changing the subject. Reply with only the text of the next message in the conversation and nothing else. The current time is \(GetCurrentTime()), do not include a timestamp in your response though.<|eot_id>\n\n";
}

enum CharacterSetting {
  Panam = 0,
  Judy = 1
}

enum PlayerGender {
    Male = 0,
    Female = 1
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