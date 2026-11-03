{ pkgs, ... }:

# opencode (https://opencode.ai): server configuration in
# ~/.config/opencode/opencode.json, terminal settings in cli.json
# beside it. The default model comes from opencode's built-in catalog
# (models.dev); its API key stays out of the repo, added per machine
# with `/connect`. Local ollama models are wired in too: run
# `ollama pull <model>` for each entry under provider.ollama.models.

let
  # The model selector is "<providerID>/<modelID>"; ollama model IDs are
  # the ollama tag.
  defaultModel = "venice/deepseek-v4-1-flash";

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

    # Remote MCP servers. Remote servers use OAuth by default: run
    # `/mcps` in opencode and sign in once per server.
    mcp.servers.dagny = {
      type = "remote";
      url = "https://dagny.co/mcp";
    };

    mcp.servers.linear = {
      type = "remote";
      url = "https://mcp.linear.app/mcp";
    };

    model = defaultModel;
  };

  # Terminal settings, kept apart from the server config: model
  # reasoning stays out of the transcript and each run of tool calls
  # collapses to one summary line, so a session reads as prompts,
  # answers and a line per burst of work.
  #
  # Home and End move the prompt cursor to the start and end of the
  # current line, matching their behaviour in the diff viewer, session
  # transcript and dialogs. The defaults, ctrl+a and ctrl+e, stay bound.
  opencodeCliConfig = {
    "$schema" = "https://opencode.ai/v2/cli.json";
    session.thinking = "hide";
    session.verbosity = "low";

    keybinds = {
      "input.line.home" = "ctrl+a,home";
      "input.line.end" = "ctrl+e,end";
    };
  };
in
{
  home.packages = [ pkgs.opencode ];

  xdg.configFile."opencode/opencode.json".source =
    (pkgs.formats.json { }).generate "opencode.json"
      opencodeConfig;

  xdg.configFile."opencode/cli.json".source =
    (pkgs.formats.json { }).generate "cli.json"
      opencodeCliConfig;
}
