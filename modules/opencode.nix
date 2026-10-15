{ pkgs, ... }:

# opencode (https://opencode.ai) wired to the machine's local ollama
# service, configured via ~/.config/opencode/opencode.json. Run
# `ollama pull <model>` for each entry under provider.ollama.models.

let
  # The model selector is "<providerID>/<modelID>"; the modelID is the
  # ollama tag.
  defaultModel = "ollama/qwen3.6:35b";

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";

    # ollama's OpenAI-compatible endpoint.
    provider.ollama = {
      npm = "@ai-sdk/openai-compatible";
      name = "Ollama (local)";
      options.baseURL = "http://127.0.0.1:11434/v1";
      # Add/remove entries as you pull models. The keys must match the
      # exact ollama tag.
      models = {
        "llama3.2:3b".name = "Llama 3.2 3B";
        "qwen2.5-coder:32b".name = "Qwen2.5 Coder 32B";
        "gpt-oss:20b".name = "GPT-OSS 20B";
        "gpt-oss:120b".name = "GPT-OSS 120B";
        "granite4.1:30b".name = "Granite 4.1 30B";
        "qwen3-coder:30b".name = "Qwen3 Coder 30B";
        "qwen3.6:35b".name = "Qwen 3.6 35B";
      };
    };

    model = defaultModel;
  };
in
{
  home.packages = [ pkgs.opencode ];

  xdg.configFile."opencode/opencode.json".source =
    (pkgs.formats.json { }).generate "opencode.json"
      opencodeConfig;
}
