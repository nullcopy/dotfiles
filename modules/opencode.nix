{ pkgs, ... }:

# opencode (https://opencode.ai) wired to the machine's local ollama
# service and to Prime Intellect inference, configured via
# ~/.config/opencode/opencode.json. Run `ollama pull <model>` for each
# entry under provider.ollama.models.
#
# The Prime Intellect API key stays out of the repo: on each machine,
# run `/connect` in opencode, choose "Other", enter provider ID `prime`
# and paste a key with the Inference permission. opencode keeps it in
# ~/.local/share/opencode/auth.json.

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

    # Prime Intellect's OpenAI-compatible endpoint. List the available
    # model IDs with `prime inference models`.
    provider.prime = {
      npm = "@ai-sdk/openai-compatible";
      name = "Prime Intellect";
      options.baseURL = "https://api.pinference.ai/api/v1";
      models = {
        "prime-intellect/intellect-3".name = "INTELLECT-3";
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
