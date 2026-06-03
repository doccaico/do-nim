import std/[os, osproc, strutils, strformat]

import ./[utils]


const HELP_MSG = """
USAGE:
    do.exe gitup [OPTION] DIR "Up"
    do.exe gitup [OPTION]     "Up"
OPTION:
    -h, --help                 ヘルプメッセージを表示"""

proc execCmdStream(cmd: string, args: openArray[string] = []): int =
  var p = startProcess(cmd, args = args, options = {poUsePath, poParentStreams})
  result = p.waitForExit()
  p.close()

proc run*(argv: seq[string]) =
  if argv.len == 0 or argv.len > 2:
    stderrMsgAndExit HELP_MSG
  if argv[0] == "-h" or argv[0] == "--help":
    stdoutMsgAndExit HELP_MSG

  var dirPath: string
  var commitMsg: string

  if argv.len == 2:
    if not dirExists(argv[0]):
      stderrMsgAndExit fmt"Does not exist: {argv[0]}"
    dirPath = argv[0]
    commitMsg = argv[1]
  else:
    dirPath = ""
    commitMsg = argv[0]

  if dirPath != "":
    setCurrentDir dirpath

  var statusRes = execCmdEx("git status --porcelain")
  if statusRes.exitCode != 0:
     stderrMsgAndExit "not a git repository (or git command failed)"

  let statusOutput = statusRes.output.strip()
  if statusOutput == "":
    stdoutMsgAndExit "There is no need to update"

  # 変更内容を事前に少し表示（親切設計）
  echo "==> Detected changes:"
  echo statusOutput.indent(4)
  echo ""

  # git add .
  echo "==> Running: git add ."
  if execCmdStream("git", ["add", "."]) != 0:
    stderrMsgAndExit "failed to run 'git add .'"

  # git commit -m "..."
  echo fmt"==> Running: git commit -m ""{commitMsg}"""
  if execCmdStream("git", ["commit", "-m", commitMsg]) != 0:
    stderrMsgAndExit "failed to run 'git commit'"

  # git push
  echo "==> Running: git push"
  if execCmdStream("git", ["push"]) != 0:
    stderrMsgAndExit "failed to run 'git push'"

  echo "==> Success! All changes updated and pushed."

when isMainModule:
  run(commandLineParams())
