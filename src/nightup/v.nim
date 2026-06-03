import std/[os, osproc, strformat]
import regex

import ../[utils]

proc run*(distDir: string, downloadDir: string) =
  # 1. 最新バージョンのJSONを取得
  let url = "https://api.github.com/repos/vlang/v/releases/latest"
  let (output, curlRes) = execCmdEx(fmt"""curl -sSL -A "Mozilla/5.0" "{url}"""")
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

  try:
    rmDirIfExist(workDirPath)
    echo fmt"""Removed: "{workDirPath}""""
  except CatchableError:
    stderrMsgAndExit fmt"failed to remove existing work dir: {workDirPath}"

  try:
    createDir(workDirPath)
    echo fmt"""Created: "{workDirPath}""""
  except CatchableError:
    stderrMsgAndExit fmt"failed to create work dir: {workDirPath}"

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
    rmDirIfExist(workDirPath)
    stderrMsgAndExit "failed to download ZIP"
  
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
    rmDirIfExist(workDirPath)
    stderrMsgAndExit "failed to extract ZIP"
  
  echo "Extraction is done"

  # 6. 不要になったZIPの削除
  try:
    rmIfExist(localZipPath)
    echo fmt"""Removed: "{localZipPath}""""
  except CatchableError:
    rmDirIfExist(workDirPath)
    stderrMsgAndExit "failed to remove local ZIP file"

  # 7. 配置（アップデートの適用）
  try:
    rmDirIfExist(distDir)
    echo fmt"""Removed: "{distDir}""""
  except CatchableError:
    rmDirIfExist(workDirPath)
    stderrMsgAndExit fmt"failed to remove distDir: {distDir}"

  # ワークスペースを作業パスから distDir へ移動
  try:
    moveDir(workDirPath, distDir)
    echo fmt"""Moved: "{workDirPath}" to "{distDir}""""
    echo fmt"""Updated: "{distDir}""""
  except CatchableError:
    rmDirIfExist(workDirPath)
    stderrMsgAndExit fmt"failed to move directory to {distDir}"
