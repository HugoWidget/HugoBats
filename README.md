# HugoBats

> [!NOTE]
>
> 建议阅读 [HugoWidget 简介](https://github.com/HugoWidget/HugoWidget) 以了解开发情况

在特别环境下，可能出现 HugoWidget 项目程序无法正常工作的情况，如果急于使用一些功能，这个仓库可能有一点作用。

1. 循环关闭希沃：[disable.bat](src/disable.bat)

   短命令版如下：

   ```
   for /l %a in (1,0,1)do @taskkill /f /im seewo* &timeout /t 1
   ```
   如果接受可能的系统卡顿，可以删去 timeout：

   ```
   for /l %a in (1,0,1)do @taskkill /f /im seewo* 
   ```
   批处理脚本中请将 `%a` 改为 `%%a`

2. Api 解除冰点：[freeze.bat](src/freeze.bat)

   也可直接在浏览器中访问（需重启）：

   - 解除冰点：
     ```
     127.0.0.1:6082/api/v1/set?vol=0
     ```

   - 冻结C盘：
   
     ```
     127.0.0.1:6082/api/v1/set?vol=4
     ```
   
   - 冻结CE盘：
   
     ```
     127.0.0.1:6082/api/v1/set?vol=20
     ```
   

## 许可证

本项目采用 MIT 许可证，详情参见 [LICENSE](LICENSE) 文件。
