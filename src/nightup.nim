import std/[os, strformat, parsecfg]

import ./[utils]

import ./nightup/[
  zig,    # curl, tar
  odin,   # curl, tar
  v,      # curl, tar
  go,     # curl, tar
  vim,    # curl
  ]


const HELP_MSG = """
USAGE:
    do.exe nightup go
    do.exe nightup odin
    do.exe nightup v
    do.exe nightup zig
    do.exe nightup vim
OPTION:
    -h, --help                 ヘルプメッセージを表示"""

proc getDistDir(cfg: Config, key: string): string =
  result = getSectionValue(cfg, "Windows", key)
  if result == "":
    stderrMsgAndExit fmt"""nightup ini: not found path: "{key}""""

proc run*(args: seq[string]) =
  if args.len == 1 and (args[0] == "-h" or args[0] == "--help"):
    stdoutMsgAndExit HELP_MSG
  if args.len != 1:
    stderrMsgAndExit HELP_MSG

  # 1. ホームディレクトリの取得
  let homeDir = getHomeDir()
  if homeDir == "":
    stderrMsgAndExit "Impossible to get your home dir!"

  # パスの結合 ($HOME/.nightup)
  let iniPath = homeDir / ".nightup"

  # 2. INIファイルのロード
  var cfg: Config
  try:
    cfg = loadConfig(iniPath)
  except CatchableError:
    stderrMsgAndExit fmt"failed to open: {iniPath}"

  # 3. 一時保存ディレクトリの設定
  var downloadDir = getTempDir()
  if downloadDir == "":
    stderrMsgAndExit "failed to getTempDIr"

  # 4. 各言語のアップデート処理への振り分け
  case args[0]
  of "zig":
    let distDir = getDistDir(cfg, "zig")
    zig.run(distDir, downloadDir)
  of "odin":
    let distDir = getDistDir(cfg, "odin")
    odin.run(distDir, downloadDir)
  of "v":
    let distDir = getDistDir(cfg, "v")
    v.run(distDir, downloadDir)
  of "go":
    let distDir = getDistDir(cfg, "go")
    go.run(distDir, downloadDir)
  of "vim":
    vim.run()
  else:
    stderr.writeLine fmt"nightup: unknown command '{args[0]}'"
    stderrMsgAndExit HELP_MSG

when isMainModule:
  run(commandLineParams())
