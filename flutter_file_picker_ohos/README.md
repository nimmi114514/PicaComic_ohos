![fluter_file_picker](https://user-images.githubusercontent.com/27860743/64064695-b88dab00-cbfc-11e9-814f-30921b66035f.png)
<p align="center">
 <a href="https://pub.dartlang.org/packages/file_picker">
    <img alt="File Picker" src="https://img.shields.io/pub/v/file_picker.svg">
  </a>
 <a href="https://github.com/Solido/awesome-flutter">
    <img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square">
  </a>
 <a href="https://www.buymeacoffee.com/gQyz2MR">
    <img alt="Buy me a coffee" src="https://img.shields.io/badge/Donate-Buy%20Me%20A%20Coffee-yellow.svg">
  </a>
  <a href="https://github.com/miguelpruivo/flutter_file_picker/issues"><img src="https://img.shields.io/github/issues/miguelpruivo/flutter_file_picker">
  </a>
  <img src="https://img.shields.io/github/license/miguelpruivo/flutter_file_picker">
  <a href="https://github.com/miguelpruivo/flutter_file_picker/actions/workflows/main.yml">
    <img alt="CI pipeline status" src="https://github.com/miguelpruivo/flutter_file_picker/actions/workflows/main.yml/badge.svg">
  </a>
</p>

# File Picker
A package that allows you to use the native file explorer to pick single or multiple files, with extensions filtering support.

## Currently supported features
* Uses OS default native pickers
* Supports multiple platforms (Mobile, Web, Desktop)
* Pick files using  **custom format** filtering — you can provide a list of file extensions (pdf, svg, zip, etc.)
* Pick files from **cloud files** (GDrive, Dropbox, iCloud)
* Single or multiple file picks
* Supports retrieving as XFile (cross_file) for easy manipulation with other libraries
* Different default type filtering (media, image, video, audio or any)
* Picking directories
* Load file data immediately into memory (`Uint8List`) if needed; 
* Open a save-file / save-as dialog (a dialog that lets the user specify the drive, directory, and name of a file to save)

If you have any feature that you want to see in this package, please feel free to issue a suggestion. 🎉

## Compatibility Chart

| API                   | OHOS               | 
| --------------------- |--------------------| 
| clearTemporaryFiles() | :heavy_check_mark: |
| getDirectoryPath()    | :heavy_check_mark: |
| pickFiles()           | :heavy_check_mark: |
| saveFile()            | :heavy_check_mark: |

## Usage

```yaml
dependencies:
  file_picker: 8.0.6
  file_picker_ohos: 1.0.0
```
#### Single file
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  File file = File(result.files.single.path!);
} else {
  // User canceled the picker
}
```
#### Multiple files
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);

if (result != null) {
  List<File> files = result.paths.map((path) => File(path!)).toList();
} else {
  // User canceled the picker
}
```
#### Multiple files with extension filter
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['jpg', 'pdf', 'doc'],
);
```
#### Pick a directory
```dart
String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

if (selectedDirectory == null) {
  // User canceled the picker
}
```
#### Save-file 
```dart
String? outputFile = await FilePicker.platform.saveFile(
  fileName: 'output-file.pdf',//需要保存的文件名
  initialDirectory:"/data/xxxx/xxxx/.pdf" //需要文件所在的路径（权限收紧后，仅仅支持应用沙箱路径）
);

if (outputFile == null) {
  // User canceled the picker
}
```
在 OpenHarmony/OHOS 设备上，如果同时传入 `bytes` 参数，插件会在 `saveFile` 的流程中直接写入文件内容；如果需要在保存路径返回后再写入数据，也可以单独调用 `await FilePicker.platform.writeFile(uri: outputFile, bytes: data);`。
### Load result and file details
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  PlatformFile file = result.files.first;

  print(file.name);
  print(file.bytes);
  print(file.size);
  print(file.extension);
  print(file.path);
} else {
  // User canceled the picker
}
```
### Retrieve all files as XFiles or individually
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  // All files
  List<XFile> xFiles = result.xFiles;

  // Individually
  XFile xFile = result.files.first.xFile;
} else {
  // User canceled the picker
}
```
#### Pick and upload a file to Firebase Storage with Flutter Web
```dart
FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null) {
  Uint8List fileBytes = result.files.first.bytes;
  String fileName = result.files.first.name;
  
  // Upload file
  await FirebaseStorage.instance.ref('uploads/$fileName').putData(fileBytes);
}
```

For full usage details refer to the **[Wiki](https://github.com/miguelpruivo/flutter_file_picker/wiki)** above.


For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).
