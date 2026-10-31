{ pkgs, ... }:

# Speech-to-text dictation, desktop only (it needs a microphone and a
# niri session): imported by ../profiles/desktop.nix. The niri bind in
# ./niri.nix (Mod+D) spawns the `dictate` script, which toggles: the
# first press records the microphone, the second stops it, transcribes
# the clip locally with whisper.cpp, and types the text into the
# focused window (a copy lands on the clipboard, so apps that refuse
# synthetic keystrokes still get a paste). Typing goes through wtype
# over niri's virtual-keyboard protocol, so there is no daemon, no
# input group and no uinput permission. Everything runs offline; the
# only download is the pinned model below.
let
  # ~57 MB quantised English model: good dictation quality, a short clip
  # transcribes in a couple of seconds on CPU. For more accuracy trade
  # speed for, e.g. ggml-small.en-q5_1.bin; the full list is at
  # https://huggingface.co/ggerganov/whisper.cpp/tree/main
  model = pkgs.fetchurl {
    url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en-q5_1.bin";
    hash = "sha256-S69w3Q18Qke6K4H6/ZwBAFrHfC+e8GTgDc8ZXQ4v3S8=";
  };

  dictate = pkgs.writeShellApplication {
    name = "dictate";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      libnotify
      pipewire # pw-record
      whisper-cpp
      wl-clipboard
      wtype
    ];
    text = ''
      state=''${XDG_RUNTIME_DIR:?not in a session}/dictate
      base="$state/clip"
      wav="$base.wav"
      txt="$base.txt"
      pidfile="$state/pw-record.pid"
      mkdir -p "$state"

      if [[ ! -f $pidfile ]]; then
        pw-record --rate 16000 --channels 1 "$wav" &
        pid=$!
        echo "$pid" >"$pidfile"
        # pw-record exits at once when it cannot open the capture
        # stream (no microphone, or it is muted); a quick liveness
        # check makes that show up on this press instead of the next.
        sleep 0.2
        if ! kill -0 "$pid" 2>/dev/null; then
          rm -f "$pidfile" "$wav"
          notify-send -a dictate -u critical "Dictation" "the recorder failed to start"
          exit 1
        fi
        notify-send -a dictate "Dictation" "listening…"
        exit 0
      fi

      # Second press: stop the recorder, transcribe, type the text.
      pid=$(<"$pidfile")
      rm -f "$pidfile"
      if ! kill -INT "$pid" 2>/dev/null; then
        # The recorder is gone (it failed at startup, or died with the
        # session); there is nothing to transcribe.
        notify-send -a dictate -u critical "Dictation" "the recorder is gone"
        rm -f "$wav" "$txt"
        exit 1
      fi

      # pw-record finalises the wav on SIGINT; wait for it to exit, and
      # force it out if it ever hangs past the wait.
      for _ in {1..30}; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
      done
      kill -KILL "$pid" 2>/dev/null || true

      # 16 kHz mono 16-bit is 32000 bytes/s. A shorter clip is a second
      # press with nothing said, or a recorder that died early:
      # transcribing it would make whisper hallucinate over silence.
      if [[ ! -s $wav ]] || (( $(wc -c <"$wav") < 36000 )); then
        notify-send -a dictate "Dictation" "nothing recorded"
        rm -f "$wav" "$txt"
        exit 0
      fi

      if ! whisper-cli -m ${model} -f "$wav" -otxt -of "$base" -np >"$state/whisper.log" 2>&1; then
        notify-send -a dictate -u critical "Dictation" "transcription failed; $state/whisper.log has the log"
        rm -f "$wav" "$txt"
        exit 1
      fi

      text=$(tr '\n' ' ' <"$txt" | awk '{$1=$1};1')
      if [[ -z $text ]]; then
        notify-send -a dictate "Dictation" "nothing understood"
        rm -f "$wav" "$txt" "$state/whisper.log"
        exit 0
      fi

      printf %s "$text" | wl-copy
      if ! printf %s "$text" | wtype -; then
        notify-send -a dictate -u critical "Dictation" "typing failed; the text is on the clipboard"
        rm -f "$wav" "$txt" "$state/whisper.log"
        exit 1
      fi

      notify-send -a dictate "Dictation" "inserted"
      rm -f "$wav" "$txt" "$state/whisper.log"
    '';
  };
in

{
  home.packages = [ dictate ];
}
