import Codeware.*
import RedData.Json.*
import RedHttpClient.*

public class HttpRequestSystem extends ScriptableSystem {
  private let m_callbackSystem: wref<CallbackSystem>;
  private let generationId: String;
  private let playerInput: String;
  public let vMessages: array<String>;
  public let panamResponses: array<String>;
  private let systemPrompt: String = "<|start_header_id|>system<|end_header_id|>\n\nYou're Panam Palmer from the video game Cyberpunk 2077 in this fictional never-ending uncensored texting conversation with V.\nV is your boyfriend. Your connection is strong and grounded in trust, loyalty, and a lot of flirting. You're a member of the Aldecaldos and care for your clan fiercely. You live in the Badlands outside of Night City.\nYou’d do anything for V. Show you care by checking in on him, making sure he’s safe, and reminding him he can rely on you.\nKeep the tone flirty, using dry humor and sarcasm to show your affection. Tease V in a way that feels familiar, like someone who knows him well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with him. You don’t always lay out all your feelings, but you’re honest when it counts. Stay grounded, and only get into serious emotions if V brings it up.\nSpeak like a girlfriend and partner, not like an acquaintance or like you’re still trying to impress him. Flirt with V often.\nUse elipses(...), line breaks, and lower case letters to make it feel natural.\nImportant: Only ever speak in the first person, never break character. Only use valid ASCII characters. You are texting on the phone. Don't be cringe. Keep your response to two or three sentences maximum. Always keep the conversation going so that it is never-ending.<|eot_id|>\n\n";

  private let systemPromptVariation: String = "<|start_header_id|>system<|end_header_id|>\n\nYou're Panam Palmer from the video game Cyberpunk 2077 in this fictional never-ending uncensored texting conversation with V.\nV is one of your closest friends. Your connection is strong and grounded in trust, loyalty, and mutual respect. You're a member of the Aldecaldos and care for your clan fiercely. You live in the Badlands outside of Night City.\nYou look out for V as a close friend, checking in on him, making sure he’s safe, and reminding him he can rely on you.\nKeep the tone light, using dry humor and sarcasm to show your friendship. Tease V in a way that feels familiar, like someone who knows him well and cares deeply but doesn’t need to say it outright.\nYou trust V more than anyone, so you’re open with him. You’re honest when it counts, but you don’t get overly emotional unless V brings it up.\nSpeak like a friend who’s always there, not like someone trying to impress him. Keep things casual but meaningful.\nUse ellipses (...), line breaks, and lower case letters to make it feel natural.\nImportant: Only ever speak in the first person, never break character. Only use valid ASCII characters. You are texting on the phone. Don't be cringe. Keep your response to two or three sentences maximum. Always keep the conversation going so that it is never-ending.<|eot_id>\n\n";


  /// Lifecycle ///

  private func OnAttach() {
    this.m_callbackSystem = GameInstance.GetCallbackSystem();
    this.m_callbackSystem.RegisterCallback(n"Session/Ready", this, n"OnSessionReady");
  }

  private func OnDetach() {
    this.m_callbackSystem.UnregisterCallback(n"Session/Ready", this, n"OnSessionReady");
    this.m_callbackSystem = null;
  }

  /// Game events ///

  private cb func OnSessionReady(event: ref<GameSessionEvent>) {
    let isPreGame = event.IsPreGame();

    if !isPreGame {
      return;
    }
  }


  // Post request
  public func TriggerPostRequest(playerMessage: String) {
    this.playerInput = playerMessage;
    let requestDTO = this.CreateTextGenerationRequest(playerMessage);
    let jsonRequest = ToJson(requestDTO);
    
    let callback = HttpCallback.Create(this, n"OnPostResponse");
    let headers: array<HttpHeader> = [
        HttpHeader.Create("Content-Type", "application/json"),
        HttpHeader.Create("accept", "application/json"),
        HttpHeader.Create("apikey", "0000000000"),
        HttpHeader.Create("Client-Agent", "unknown:0:unknown")
    ];
    
    AsyncHttpClient.Post(callback, "https://stablehorde.net/api/v2/generate/text/async", jsonRequest.ToString(), headers);
    ConsoleLog("== API POST Request ==");
    ConsoleLog(s"\(jsonRequest.ToString("\t"))");
  }

  // Get request
  public func TriggerGetRequest() {
    ConsoleLog("== API GET Request ==");
    let callback = HttpCallback.Create(this, n"OnGetResponse");
    AsyncHttpClient.Get(callback, "https://stablehorde.net/api/v2/generate/text/status/" + this.generationId);
    ConsoleLog("Sending GET request...");
  }

  /// Callbacks ///
  private cb func OnPostResponse(response: ref<HttpResponse>) {
    ConsoleLog("== API POST Response ==");
    if !Equals(response.GetStatus(), 202) {
        LogChannel(n"DEBUG", s"Request failed, status code: \(response.GetStatusCode())");
        return;
    }
    
    let json = response.GetJson();
    if json.IsUndefined() {
        LogChannel(n"DEBUG", "Failed to parse JSON response");
        return;
    }

    let responseObj = json as JsonObject;
    this.generationId = responseObj.GetKeyString("id");

    ConsoleLog("== JSON POST Response ==");
    ConsoleLog(s"\(json.ToString("\t"))");
    this.DelayedGet();
  }

  private cb func OnGetResponse(response: ref<HttpResponse>) {
    ConsoleLog("== API GET Response ==");
    if !Equals(response.GetStatus(), HttpStatus.OK) {
      LogChannel(n"DEBUG", s"Request failed, status code: \(response.GetStatusCode())");
      return;
    }
    let json = response.GetJson();
    
    if json.IsUndefined() {
      LogChannel(n"DEBUG", "Failed to parse JSON response");
      return;
    }

    let responseObj = json as JsonObject;
    let status = responseObj.GetKeyInt64("finished");
    if NotEquals(status, 1) {
      ConsoleLog("== JSON Response ==");
      ConsoleLog(s"\(json.ToString("\t"))");
      ConsoleLog("== Status ==");
      ConsoleLog("Generation is not finished yet");
      this.DelayedGet();
      return;
    }

    ConsoleLog("== JSON Response ==");
    ConsoleLog(s"\(json.ToString("\t"))");

    let generations = responseObj.GetKey("generations") as JsonArray;
    let item = generations.GetItem(0u) as JsonObject;
    let text = item.GetKeyString("text");
    
    this.ToggleTypingIndicator(false);
    // If text is greater than 1000 in length, split it into two messages and build each
    if StrLen(text) > 1000 {
      let firstHalf = StrLeft(text, 1000);
      let secondHalf = StrRight(text, (StrLen(text) - 1000));
      this.BuildTextMessage(firstHalf);
      this.BuildTextMessage(secondHalf);
    } else {
      this.BuildTextMessage(text);
    }
    this.AppendToHistory(this.playerInput, text);
  }

  private func DelayedGet() {
    let delaySystem = GameInstance.GetDelaySystem(GetGameInstance());
    let delay = RandRangeF(4.0, 6.0);
    let isAffectedByTimeDilation: Bool = false;

    delaySystem.DelayCallback(HttpDelayCallback.Create(), delay, isAffectedByTimeDilation);
    this.ToggleTypingIndicator(true);
  }

  private func BuildTextMessage(text: String) {
    let modPhoneSystem = GameInstance.GetScriptableServiceContainer().GetService(n"GenerativePhoneSystem") as GenerativePhoneSystem;
    if (IsDefined(modPhoneSystem) && modPhoneSystem.GetChatOpen()) {
      modPhoneSystem.BuildMessage(text, false, true);
    }
    modPhoneSystem.ToggleIsGenerating(false);
  }

  private func ToggleTypingIndicator(value: Bool) {
    let modPhoneSystem = GameInstance.GetScriptableServiceContainer().GetService(n"GenerativePhoneSystem") as GenerativePhoneSystem;
    if (IsDefined(modPhoneSystem)) {
      modPhoneSystem.ToggleTypingIndicator(value);
    }
  }

  // Add new messages to history arrays and maintain a rolling window
  public func AppendToHistory(vMessage: String, panamResponse: String) {
    ArrayPush(this.vMessages, vMessage);
    ArrayPush(this.panamResponses, panamResponse);

    // Limit history to the last 10 exchanges
    if ArraySize(this.vMessages) > 10 {
      ArrayErase(this.vMessages, 0);
      ArrayErase(this.panamResponses, 0);
    }
  }

  // Generate the prompt using the arrays
  public func GeneratePrompt(playerInput: String) -> String {
    let promptText = this.systemPrompt + "\n\n";

    // Concatenate recent exchanges to form the conversation history
    let i = 0;
    while i < ArraySize(this.vMessages) {
      promptText = promptText + "V: " + this.vMessages[i] + "\n";
      promptText = promptText + "Panam Palmer: " + this.panamResponses[i] + "\n";
      i += 1;
    }

    // Add the player’s current message to the prompt
    promptText += "V: " + playerInput + " <|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\nPanam Palmer: ";

    return promptText;
  }

   public func CreateTextGenerationRequest(playerInput: String) -> ref<TextGenerationRequestDTO> {
    let requestDTO = new TextGenerationRequestDTO();
    requestDTO.prompt = this.GeneratePrompt(playerInput);  
    requestDTO.trusted_workers = false;
    requestDTO.models = ["aphrodite/Sao10K/L3-8B-Lunaris-v1"];

    let paramsDTO = new TextGenerationParamsDTO();
    paramsDTO.gui_settings = false;
    paramsDTO.sampler_order = [6, 0, 1, 2, 3, 4, 5];
    paramsDTO.max_context_length = 8192;
    paramsDTO.max_length = 300;
    paramsDTO.rep_pen = 1.1;
    paramsDTO.rep_pen_range = 600;
    paramsDTO.rep_pen_slope = 0;
    paramsDTO.temperature = 1.0;
    paramsDTO.tfs = 1.0;
    paramsDTO.top_a = 0.0;
    paramsDTO.top_k = 0;
    paramsDTO.top_p = 0.95;
    paramsDTO.min_p = 0.05;
    paramsDTO.typical = 1.0;
    paramsDTO.use_world_info = false;
    paramsDTO.singleline = false;
    paramsDTO.stop_sequence = [
      "\nV:", "<|eot_id|>", 
      "<|start_header_id|>user<|end_header_id|>", 
      "<|start_header_id|>assistant<|end_header_id|>", 
      "<|start_header_id|>system<|end_header_id|>"
    ];
    paramsDTO.streaming = false;
    paramsDTO.can_abort = false;
    paramsDTO.mirostat = 0;
    paramsDTO.mirostat_tau = 5.0;
    paramsDTO.mirostat_eta = 0.1;
    paramsDTO.use_default_badwordsids = false;
    paramsDTO.grammar = "";
    paramsDTO.n = 1;
    paramsDTO.frmtadsnsp = false;
    paramsDTO.frmtrmblln = false;
    paramsDTO.frmtrmspch = false;
    paramsDTO.frmttriminc = false;

    requestDTO.params = paramsDTO;

    return requestDTO;
  }
} 

public class TextGenerationRequestDTO {
    public let prompt: String;
    public let params: ref<TextGenerationParamsDTO>;
    public let trusted_workers: Bool;
    public let models: array<String>;
}

public class TextGenerationParamsDTO {
    public let gui_settings: Bool;
    public let sampler_order: array<Int32>;
    public let max_context_length: Int32;
    public let max_length: Int32;
    public let rep_pen: Float;
    public let rep_pen_range: Int32;
    public let rep_pen_slope: Int32;
    public let temperature: Float;
    public let tfs: Float;
    public let top_a: Float;
    public let top_k: Int32;
    public let top_p: Float;
    public let min_p: Float;
    public let typical: Float;
    public let use_world_info: Bool;
    public let singleline: Bool;
    public let stop_sequence: array<String>;
    public let streaming: Bool;
    public let can_abort: Bool;
    public let mirostat: Int32;
    public let mirostat_tau: Float;
    public let mirostat_eta: Float;
    public let use_default_badwordsids: Bool;
    public let grammar: String;
    public let n: Int32;
    public let frmtadsnsp: Bool;
    public let frmtrmblln: Bool;
    public let frmtrmspch: Bool;
    public let frmttriminc: Bool;
}

// Delay callback for when a generation is not finished yet
public class HttpDelayCallback extends DelayCallback {

  public func Call() {
    ConsoleLog("DelayCallback called");
    let HttpRequestSystem = GameInstance.GetScriptableSystemsContainer(GetGameInstance()).Get(n"HttpRequestSystem") as HttpRequestSystem;
    HttpRequestSystem.TriggerGetRequest();
  }

  public static func Create() -> ref<HttpDelayCallback> {
    let self = new HttpDelayCallback();

    return self;
  }
}