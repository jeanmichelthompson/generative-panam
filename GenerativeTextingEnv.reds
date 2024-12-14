// Copy file into r6\scripts\GenerativeTexting\
import Codeware.*
import RedFileSystem.*

// See https://github.com/psiberx/cp2077-codeware/wiki#lifecycle

public class GenerativeTextingEnv extends ScriptableEnv {
  private let m_storage: ref<FileSystemStorage>;

  public func GetStorage() -> ref<FileSystemStorage> {
    return this.m_storage;
  }

  private cb func OnLoad() {
    this.m_storage = FileSystem.GetStorage("GenerativeTexting");
  }
}

public static func GetGenerativeTextingEnv() -> ref<GenerativeTextingEnv> {
  return ScriptableEnv.Get(n"GenerativeTextingEnv") as GenerativeTextingEnv;
}
