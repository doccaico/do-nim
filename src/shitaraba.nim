import std/[os, osproc, strformat, strutils, parseutils, unicode]
import regex

import ./[utils]


const HELP_MSG = """
USAGE:
    do.exe shitaraba [OPTION] GENRE ID NUMBER
OPTION:
    -h, --help                 ヘルプメッセージを表示"""

proc convertEmoji(m: RegexMatch2, s: string): string =
  var res: int
  discard s[m.group(0)].parseInt(res)
  $Rune(res)

proc run*(argv: seq[string]) =
  if argv.len == 0 or argv.len > 3:
    stderrMsgAndExit HELP_MSG

  if argv[0] == "-h" or argv[0] == "--help":
    stdoutMsgAndExit HELP_MSG

  let (genre, id ,number) = (argv[0], argv[1], argv[2])

  let url = fmt"https://jbbs.shitaraba.net/bbs/read.cgi/{genre}/{id}/{number}/l50"
  let pipeCmdStr = fmt"""curl -sSL -A "Mozilla/5.0" {url} | busybox64u iconv -f EUC-JP -t UTF-8"""

  let (contents, curlRes) = execCmdEx(fmt"""cmd /C "{pipeCmdStr}"""")
  if curlRes != 0:
     stderrMsgAndExit "failed to 'curl and busybox64u iconv'"

  var name: seq[string]
  var date: seq[string]
  var post: seq[string]
  for m in findAll(contents, re2("<dt.+?<b>(\\w+?)</b>.+?：(.+?)</dt>.+?<dd>(.+?)</dd>", {regexMultiline, regexDotAll})):
    # name
    name.add contents[m.group(0)]
    # date
    date.add contents[m.group(1)].strip(leading = false)
    # post
    var body = contents[m.group(2)].strip().replace("<br>          <br>", "").replace("<br>", "")
    post.add body.replace(re2("&#(\\d+?);"), convertEmoji)

  doAssert(name.len == date.len and name.len == post.len)

  let tmpFile = getTempDir() / fmt"nim_shitaraba_result_{getCurrentProcessId()}.txt"
  var f: File
  if open(f, tmpFile, fmWrite):
    for i in 0..<name.len:
      f.writeLine fmt"{Cyan}{name[i]}{Reset} : {Green}{date[i]}{Reset}"
      f.writeLine post[i]
      f.writeLine ""
    close(f)

  const LessOpt = "-R -i --silent"
  discard execCmd(fmt"less {LessOpt} {tmpFile}")

  removeFile(tmpFile)

when isMainModule:
  run(commandLineParams())
