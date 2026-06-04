import std/[os, osproc, strformat]
import regex

import ../[utils]


proc run*(distDir: string, downloadDir: string) =
  # 1. 最新バージョンのJSONを取得
  let url = "https://api.github.com/repos/vlang/v/releases/latest"
  let (output, curlRes) = execCmdEx(fmt"""curl -sSL -A "Mozilla/5.0" {url}""")
  if curlRes != 0:
    stderrMsgAndExit "failed to download json"
  
  echo "Download (json) is done"

  # 2. 正規表現で Windows 用の ZIP ファイルのブラウザダウンロード URL を抽出
  let pattern = re2("""browser_download_url":\s*"(https://[^"]+v_windows\.zip)""")
  var m = RegexMatch2()
  let match = find(output, pattern, m)

  var downloadUrl = ""
  if match:
    downloadUrl = output[m.group(0)]

  if downloadUrl == "":
    stderrMsgAndExit "failed to find ZIP URL for v-windows"
  
  echo "Download URL: ", downloadUrl

  # 3. 作業用ディレクトリの作成
  let workDirName = "v-latest-upgrade-working"
  let workDirPath = downloadDir / workDirName

  if dirExists(workDirPath):
    try:
      removeDir(workDirPath)
      echo fmt"""Removed: '{workDirPath}'"""
    except OSError as e:
      stderrMsgAndExit fmt"failed to remove existing work dir: {e.msg}"

  try:
    createDir(workDirPath)
    echo fmt"""Created: '{workDirPath}'"""
  except OSError as e:
    stderrMsgAndExit fmt"failed to createDir: {e.msg}"

  # 4. ZIPファイルのダウンロード
  let localZip = "v-latest.zip"
  let localZipPath = workDirPath / localZip

  let zipProcess = startProcess(
    "curl",
    args = ["-fsSL", "-A", "Mozilla/5.0", downloadUrl, "-o", localZip],
    workingDir = workDirPath,
    options = {poUsePath, poParentStreams}
  )
  let zipExit = zipProcess.waitForExit()
  zipProcess.close()

  if zipExit != 0:
    utils.rmdir(workDirPath)
    echo fmt"""Removed: '{workDirPath}'"""
  
  echo "Download (ZIP) is done"

  # 5. 外部コマンド tar の実行
  let tarProcess = startProcess(
    "tar",
    args = ["-xf", localZip, "--strip-components=1"],
    workingDir = workDirPath,
    options = {poUsePath, poParentStreams}
  )
  let tarExit = tarProcess.waitForExit()
  tarProcess.close()

  if tarExit != 0:
    utils.rmdir(workDirPath)
    stderrMsgAndExit "failed to extract ZIP"
  
  echo "Extraction is done"

  # 6. 不要になったZIPの削除
  if tryRemoveFile(localZipPath):
    echo fmt"""Removed: '{localZipPath}'"""
  else:
    utils.rmdir(workDirPath)
    stderrMsgAndExit "failed to removeFile: '{localZipPath}'"

  # 7. 配置（アップデートの適用）
  try:
    removeDir(distDir, checkDir = true)
    echo fmt"""Removed: '{distDir}'"""
  except OSError as e:
    utils.rmdir(workDirPath)
    stderrMsgAndExit fmt"failed to removeDir: {e.msg}"

  # ワークスペースを作業パスから distDir へ移動
  try:
    moveDir(workDirPath, distDir)
    echo fmt"""Moved: '{workDirPath}' to '{distDir}'"""
    echo fmt"""Updated: '{distDir}'"""
  except OSError as e:
    utils.rmdir(workDirPath)
    stderrMsgAndExit fmt"failed to moveDir: {e.msg}"
