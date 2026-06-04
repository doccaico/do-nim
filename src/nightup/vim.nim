import std/[os, osproc, strformat]
import regex

import ../[utils]

proc run*() =
  # 1. 最新リリースのJSONを取得
  let url = "https://api.github.com/repos/vim/vim-win32-installer/releases/latest"
  let (output, curlRes) = execCmdEx(fmt"""curl -sSL -A "Mozilla/5.0" {url}""")
  if curlRes != 0:
    stderrMsgAndExit "failed to download json"
  
  echo "Download (json) is done"

  # 2. 正規表現でインストーラー（.exe）のダウンロードURLを抽出
  let pattern = re2("""browser_download_url":\s*"(https://[^"]+_x64_signed\.exe)""")
  var m = RegexMatch2()
  let match = find(output, pattern, m)

  var downloadUrl = ""
  if match:
    downloadUrl = output[m.group(0)]

  if downloadUrl == "":
    stderrMsgAndExit "failed to find ZIP URL for gvim-x64-signed"
  
  echo "Download URL: ", downloadUrl

  # 3. ユーザーの「ダウンロード」フォルダパスを構築 ($HOME/Downloads)
  let homeDir = getHomeDir()
  if homeDir == "":
    stderrMsgAndExit "Impossible to get your home dir!"
  
  let userDownloadDir = homeDir / "Downloads"

  # 4. curl を使ってインストーラーをダウンロード
  # -fsSOL オプションを使用して、ダウンロードフォルダ（userDownloadDir）に保存します
  let exeProcess = startProcess(
    "curl",
    args = ["-fsSOL", "-A", "Mozilla/5.0", downloadUrl],
    workingDir = userDownloadDir,
    options = {poUsePath, poParentStreams}
  )
  let exeExit = exeProcess.waitForExit()
  exeProcess.close()

  if exeExit != 0:
    stderrMsgAndExit "failed to download EXE"
  
  echo "Download (ZIP) is done"

  # 5. 外部コマンド cmd /C start explorer . の実行
  # ダウンロードしたディレクトリを基点にしてエクスプローラーを開きます
  let explorerProcess = startProcess(
    "cmd",
    args = ["/C", "start", "explorer", "."],
    workingDir = userDownloadDir,
    options = {poUsePath, poParentStreams}
  )
  let explorerExit = explorerProcess.waitForExit()
  explorerProcess.close()

  if explorerExit != 0:
    stderrMsgAndExit "failed to open explorer"

  echo "Opened EXPLORER.EXE"
