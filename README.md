# Agal To Base64 编译工具

## 这是什么
这是一个AIR程序，用户输入 Agal 代码，这个程序通过 agalminiassembler 将 输入的 agal 指令编译成 bytearray 然后通过 Base64 Encoder 输出

## 这个工具有什么用

这个工具是辅助 Gama Engine SDK 的开发所使用的。 

Gama 的服务基础是 Gama WWW 负责编译性声场，Gama SDK 负责客户端解析。因此 Gama SDK 需要尽量不暴露数据解析的业务逻辑。 

在生成环境中，Gama 的 AIR SDK 将只包含 agalminiassembler 编译候的GPU指令，而不包含原始的 Agal 代码

## UI 结构

![ui sketch](https://raw.github.com/yi/gama-engine-sdk/agal-compile-tool/images/ui_sketch.png?token=9838__eyJzY29wZSI6IlJhd0Jsb2I6eWkvZ2FtYS1lbmdpbmUtc2RrL2FnYWwtY29tcGlsZS10b29sL2ltYWdlcy91aV9za2V0Y2gucG5nIiwiZXhwaXJlcyI6MTM5NTY4MjY0OX0%3D--577ad0691c67d194805fda5f60431a90caa34a4e)
