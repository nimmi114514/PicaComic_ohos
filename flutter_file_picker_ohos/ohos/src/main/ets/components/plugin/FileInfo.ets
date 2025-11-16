/*
 * Copyright (C) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

export class FileInfo {
  path: string;
  name: string;
  size: number;
  bytes: Uint8Array;
  uri: string;

  constructor(path: string, name: string, size: number, bytes: Uint8Array, uri: string) {
    this.path = path;
    this.name = name;
    this.size = size;
    this.bytes = bytes;
    this.uri = uri;
  }

  static Builder(): FileInfoBuilder {
    return new FileInfoBuilder();
  }

  toMap(): Map<string, Object> {
    let data: Map<string, Object> = new Map();
    data.set("path", this.path);
    data.set("name", this.name);
    data.set("size", this.size);
    data.set("bytes", this.bytes);
    data.set("identifier", this.uri);
    return data;
  }
}

export class FileInfoBuilder {
  path: string;
  name: string;
  size: number;
  bytes: Uint8Array;
  uri: string;

  constructor() {
    this.path = '';
    this.name = '';
    this.size = 0;
    this.bytes = new Uint8Array();
    this.uri = '';
  }

  withPath(path: string): FileInfoBuilder {
    this.path = path;
    return this;
  }

  withName(name: string): FileInfoBuilder {
    this.name = name;
    return this;
  }

  withSize(size: number): FileInfoBuilder {
    this.size = size;
    return this;
  }

  withData(bytes: Uint8Array): FileInfoBuilder {
    this.bytes = bytes;
    return this;
  }

  withUri(uri: string): FileInfoBuilder {
    this.uri = uri;
    return this;
  }

  build(): FileInfo {
    return new FileInfo(this.path, this.name, this.size, this.bytes, this.uri);
  }
}
