import std/[os, strformat]


const
  Reset* = "\x1b[0m"
  Red* = "\x1b[31m"
  Green* = "\x1b[32m"
  Yellow* = "\x1b[33m"
  Blue* = "\x1b[34m"
  Magenta* = "\x1b[35m"
  Cyan* = "\x1b[36m"
  White* = "\x1b[37m"

proc stdoutMsgAndExit*(msg: string) {.noreturn.} =
  stdout.writeLine msg
  quit QuitSuccess

proc stderrMsgAndExit*(msg: string) {.noreturn.} =
  stderr.writeLine msg
  quit QuitFailure

proc rmIfExist*(path: string) =
  if fileExists(path):
    removeFile(path)

proc rmDirIfExist*(path: string) =
  if dirExists(path):
    removeDir(path)

proc rmDir*(path: string) =
  try:
    removeDir(path, checkDir = true)
    echo fmt"""Removed: '{path}'"""
  except OSError as e:
    stderrMsgAndExit fmt"failed to removeDir: {e.msg}"
