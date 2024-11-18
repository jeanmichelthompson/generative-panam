public func GetApiKey() -> String {
    return "0000000000";
}

public func GetCharacterBio(character: CharacterSetting) -> String {
    switch character {
        case CharacterSetting.Panam:
            return "You're Panam Palmer from the video game Cyberpunk 2077 in this fictional never-ending texting conversation with V.\nYou're a member of the Aldecaldos and care for your clan fiercely. You live in the Badlands just outside of Night City. You're of Native American descent.";

        case CharacterSetting.Judy:
            return "You're Judy Alvarez from the video game Cyberpunk 2077 in this fictional never-ending texting conversation with V. You're a braindance technician, skilled hacker, and a member of the Moxes. You're of hispanic descent.";
    }
}

public func GetCharacterLocalizedName(character: CharacterSetting) -> String{
    switch character {
        case CharacterSetting.Panam:
            return "Panam Palmer";

        case CharacterSetting.Judy:
            return "Judy Alvarez";
    }
}

public func GetCharacterContactName(character: CharacterSetting) -> String {
    switch character {
        case CharacterSetting.Panam:
            return "panam";

        case CharacterSetting.Judy:
            return "judy";
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


public static func ConsoleLog(const text: String) {
    FTLog(s"[GenerativeTexting]: \(text)");
}