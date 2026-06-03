import std/[os, strutils, sets]

import ./[utils]


proc run*() =
  let envPath = getEnv("PATH")
  if envPath == "":
    stderrMsgAndExit "not found 'PATH' in env variable"

  let pathSets = toOrderedSet(split($envPath, ';'))

  var pathSeq: seq[string]
  for path in pathSets.items:
    pathSeq.add path
    # echo path

  let newPath = join(pathSeq, ";")
  stdout.write newPath

when isMainModule:
  run()
