import std/[os, osproc, strformat, strutils, streams]

import ./[utils]


const HELP_MSG = """
USAGE:
    do.exe wiki [OPTION] COUNT
OPTION:
    -h, --help                 ヘルプメッセージを表示"""

proc run*(argv: seq[string]) =
  if argv.len == 0 or argv.len > 1:
    stderrMsgAndExit HELP_MSG
  if argv[0] == "-h" or argv[0] == "--help":
    stdoutMsgAndExit HELP_MSG

  let url = "https://ja.wikipedia.org/w/api.php" &
    "?format=json" &
    "&action=query" &
    "&list=random" &
    "&rnnamespace=0" &
    "&rnfilterredir=nonredirects" &
    "&rnlimit=" & argv[0]

  let (contents, curlRes) = execCmdEx(fmt"""curl -sSL -A "Mozilla/5.0" {url}""")
  if curlRes != 0:
     stderrMsgAndExit "failed to 'curl'"

  # idsの取得
  let jqIdProcess = startProcess("jq", args = ["-r", ".query.random[] | .id"], options = {poUsePath})
  jqIdProcess.inputStream.write(contents)
  jqIdProcess.inputStream.close()
  let ids = jqIdProcess.outputStream.readAll().strip().splitLines()
  let idExit = jqIdProcess.waitForExit()
  jqIdProcess.close()

  # titlesの取得
  let jqTitleProcess = startProcess("jq", args = ["-r", ".query.random[] | .title"], options = {poUsePath})
  jqTitleProcess.inputStream.write(contents)
  jqTitleProcess.inputStream.close()
  let titles = jqTitleProcess.outputStream.readAll().strip().splitLines()
  let titleExit = jqTitleProcess.waitForExit()
  jqTitleProcess.close()

  if idExit != 0 or titleExit != 0 or ids[0] == "" or titles[0] == "":
    stderrMsgAndExit "failed to parse JSON with 'jq'"

  doAssert(ids.len == titles.len)

  let tmpFile = getTempDir() / fmt"nim_wiki_result_{getCurrentProcessId()}.txt"
  var f: File
  if open(f, tmpFile, fmWrite):
    for i in 0..<ids.len:
      f.write fmt"{Magenta}{i+1}{Reset}"
      f.write fmt":{Cyan}{titles[i]}{Reset}"
      f.write fmt":{Green}https://ja.wikipedia.org/?curid={ids[i]}{Reset}"
      f.writeLine ""
    close(f)

  const LessOpt = "-R --silent"
  discard execCmd(fmt"less {LessOpt} {tmpFile}")

  rmIfExist(tmpFile)

when isMainModule:
  run(commandLineParams())
