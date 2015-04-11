## try-ruby （ http://tryruby.org/ ） 的一个简单克隆实现，实现了基本功能。访问 http://ruby.session.im 可以体验 ##

# 在浏览器中输入ruby代码，即时在服务器端执行，通过 WebSocket 实时把执行结果反馈给浏览器. #

使用chrome firefox safari opera浏览器可以测试。

firefox4,firefox5,opera11需要配置开启websocket才能测试：
  1. opera11默认关闭websocket，可以通过opera:config#UserPrefs|EnableWebSockets来启用；
  1. firefox4,firefox5，在about:config中配置network.websocket.override-security-block为true就可以激活WebSocket）。

  1. 代码运行在安全sandbox内（$SAFE = 3，但尚未限制脚本运行时间和占用资源量）
  1. 定时心跳，避免连接断开