### Do (Windows only .-.)

### Build and Minimizing Binary Size
```sh
$ nimble install regex

$ nim c --cc:vcc --mm:arc -d:release --opt:size --threads:off -o:do.exe src\do.nim
$ upx --best --lzma do.exe
```

### Memo
- [Color](https://stackoverflow.com/questions/6297072/color-for-the-prompt-just-the-prompt-proper-in-cmd-exe-and-powershell)
