import std/[os, osproc, strformat]

import ./[utils]


const HELP_MSG = """
USAGE:
    do.exe diary_search [OPTION] 検索キーワード
OPTION:
    -h, --help                 ヘルプメッセージを表示
REQUIRED:
    環境変数(DIARY_DIR)に日記が入っているディレクトリを設定すること"""

proc run*(argv: seq[string]) =
  if argv.len == 1 and (argv[0] == "-h" or argv[0] == "--help"):
    stdoutMsgAndExit HELP_MSG
  if argv.len != 1:
    stderrMsgAndExit HELP_MSG

  let diaryDir = getEnv("DIARY_DIR")
  if diaryDir == "":
    stderrMsgAndExit "not found 'DIARY_DIR' in env variable"
  if not dirExists(diaryDir):
    stderrMsgAndExit fmt"'{diaryDir}' does not exist or is a file"

  let keyword = argv[0]

  let rgArgs = [
    "rg",
    "--color", "always",
    "--heading",
    "--line-number",
    "--ignore-case",
    "--sort=path",
    keyword,
    diaryDir
  ]

  let (output, rgExitCode) = execCmdEx(quoteShellCommand(rgArgs))

  if rgExitCode != 0:
    if rgExitCode == 1:
      stdoutMsgAndExit fmt"No matches found for '{keyword}'"
    else:
      stderrMsgAndExit fmt"'rg' failed with exit code {rgExitCode}"

  let tmpFile = getTempDir() / fmt"nim_diary_search_result_{getCurrentProcessId()}.txt"
  writeFile(tmpFile, output)

  let lessProcess = startProcess(
    "less",
    args = ["-R", "-i", "--silent", tmpFile],
    options = {poUsePath, poParentStreams}
  )

  let lessExitCode = lessProcess.waitForExit()
  lessProcess.close()

  rmIfExist(tmpFile)

  if lessExitCode != 0:
    stderrMsgAndExit fmt"'less' failed with exit code {lessExitCode}"

when isMainModule:
  run(commandLineParams())
