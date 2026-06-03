import std/[os, strformat]

import ./[utils]

import ./[
  diary_search,            # less, rg
  gitup,                   # git
  shitaraba,               # less, curl
  delete_duplicate_path,
  verse,                   # less, curl
  wiki,                    # less, curl, jq
  nightup,                 # curl, tar
]


const HELP_MSG = """
USAGE:
    do.exe [OPTION] COMMAND
OPTION:
    -h, --help                  ヘルプメッセージを表示
COMMAND:
    diary_search                日記を検索
    gitup                       GithubにPush
    shitaraba                   Shitarabaを閲覧
    delete_duplicate_path       環境変数PATHの重複を解消して表示
    verse                       聖書(新共同訳)を表示
    wiki                        ランダムWIKIのリストを表示
    nightup                     ソフトウェアアップデーター"""

proc main(argv: seq[string]) =
  if argv.len == 0:
    stderrMsgAndExit HELP_MSG
  if argv[0] == "-h" or argv[0] == "--help":
    stdoutMsgAndExit HELP_MSG
  case argv[0]
  of "diary_search": diary_search.run(argv[1..^1])
  of "gitup": gitup.run(argv[1..^1])
  of "shitaraba": shitaraba.run(argv[1..^1])
  of "delete_duplicate_path": delete_duplicate_path.run()
  of "verse": verse.run(argv[1..^1])
  of "wiki": wiki.run(argv[1..^1])
  of "nightup": nightup.run(argv[1..^1])
  else:
    stderr.writeLine fmt"unknown command '{argv[0]}'"
    stderrMsgAndExit HELP_MSG

when isMainModule:
  main(commandLineParams())
