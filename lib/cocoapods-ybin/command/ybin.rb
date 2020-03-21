require 'cocoapods-ybin/command/ybin/link'

module Pod
  class Command
    class Ybin < Command
      self.abstract_command = true
      self.summary = '将二进制库与源码建立映射，实现断点自动跳入对应源码部分进行调试应用程序。作者: houmanager@qq.com'
    end
  end
end
