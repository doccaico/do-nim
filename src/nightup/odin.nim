import std/[os, osproc, strformat]
import regex

import ../[utils]

proc run*(distDir: string, downloadDir: string) =
  # 1. 最新バージョンのJSONを取得
  let url = "https://f001.backblazeb2.com/file/odin-binaries/nightly.json"
  let (output, curlRes) = execCmdEx(fmt"""curl -sSL -A "Mozilla/5.0" "{url}"""")
  if curlRes != 0:
    stderrMsgAndExit "failed to download nightly.json"
  
  echo "Download (nightly.json) is done"

  # 2. 正規表現で日付（YYYY-MM-DD）を抽出
  let pattern = re2("""([\d]{4}-[\d]{2}-[\d]{2})T""")
  var m = RegexMatch2()
  let match = find(output, pattern, m)

  var nightlyDate = ""
  if match:
    nightlyDate = output[m.group(0)]

  if nightlyDate == "":
    stderrMsgAndExit "failed to find ZIP URL for odin-windows-amd64 nightly"

  # URLエンコードされた「+」である「%2B」を使用してZIP名とURLを構築
  let zipName = "odin-windows-amd64-nightly%2B" & nightlyDate & ".zip"
  let downloadUrl = "https://f001.backblazeb2.com/file/odin-binaries/nightly/" & zipName
  echo "Download URL: ", downloadUrl

  # 3. 作業用ディレクトリの作成
  let workDirName = "odin-nightly-upgrade-working"
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
  let localZip = "odin-nightly-latest.zip"
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
