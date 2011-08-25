#! /usr/bin/ruby
#author newdongyuwei@gmail.com

%w(rubygems sinatra sinatra/base eventmachine  em-websocket stringio ).each{|lib|require lib}

class WebServer < Sinatra::Base
    set :run ,true
    set :port, 9999
    set :environment, :production
    set :logging, true

=begin
    use Rack::Auth::Basic do |name, password|
        cmd = "svn ls https://svn1.intra.sina.com.cn/weibo/readme.txt --username #{name} --password #{password} --non-interactive --no-auth-cache --trust-server-cert"
        #system(cmd) == true # a hack for auth without ldap  ,haha!   
        #[name, password] == ['admin', 'test']
	true
    end
=end
    
	get '/' do
		'please input ruby code (try ruby over WebSocket):
		<hr>
		<textarea id="content" style="width:500px;height:200px;"></textarea>
		<br>
		<button id="request-permission">request-permission</button>
        <button id="send">run ruby code!</button>
		<hr>
		excution result:
		<br>
		<textarea id="log" style="width:500px;height:200px"></textarea>
		<script>
			(function() {
				function Notifier() {
				}

				Notifier.prototype.requestPermission = function(cb) {
					window.webkitNotifications.requestPermission( function() {
						if (cb) {
							cb(window.webkitNotifications.checkPermission() == 0);
						}
					});
				}
				Notifier.prototype.notify = function(icon, title, body) {
					if (window.webkitNotifications.checkPermission() === 0) {
						var popup = window.webkitNotifications.createNotification(icon, title, body);
						popup.show();
						setTimeout( function() {
							popup.cancel && popup.cancel();
						}, 5000);//默认5s自动隐藏
						return true;
					}
					return false;
				}
				var notifier = new Notifier() , btn = document.getElementById("request-permission");
				btn.onclick = function() {
					notifier.requestPermission();
				};
				if (!window.webkitNotifications || (window.webkitNotifications && window.webkitNotifications.checkPermission() === 0)) {
					btn.style.display = "none";
				}
				
				if (window.WebSocket || window.MozWebSocket) {
					var url = "ws://host:7777".replace("host",window.location.hostname);
					var ws = window.WebSocket ?  new WebSocket(url) : new MozWebSocket(url);

					ws.onopen = function() {
						ws.send("puts \"web socket demo\" ");
						setInterval( function() {
							if(ws.readyState === 1  && ws.bufferedAmount === 0) {
								ws.send("KeepAlive");
							}
						}, 20000);
					};
					ws.onmessage = function(evt) {
						var data = evt.data;
						console.log(data);
						if (window.webkitNotifications){
							notifier.notify("http://tp3.sinaimg.cn/1645875054/50/1279883161/1", "WebSocket message:", data)
						}else{
							alert(data);
						}
						var log = document.getElementById("log");
						log.value = data;
					};
					ws.onclose = function() {
						console.log("socket closed");
					};
					document.getElementById("send").onclick = function() {
						ws.send(document.getElementById("content").value.split("\n").join(";"));
					};
				} else {
					alert("You browser does not support  web sockets,try chrome,safari5 ,firefox6,or opera11(opera:config#UserPrefs|EnableWebSockets)");
				};
			})();
			    
		</script>
        '
	end
end

EM.kqueue = true if EM.kqueue? 
EM.epoll = true if EM.epoll?

EventMachine.run {
	WebServer.run!
	EventMachine::WebSocket.start(:host => "0.0.0.0",:port => 7777) do |ws|
		ws.onopen {
			puts "WebSocket connection open"
		}
		ws.onmessage do |msg|
			if msg != "KeepAlive"
				puts "WebSocket Recieved message: #{msg}" 
				Thread.start{
					$SAFE = 3 
					begin
						$stdout = StringIO.new
						eval(msg)
						ws.send( $stdout.string)
					rescue
						ws.send($!.to_s) 
					ensure
						 $stdout = STDOUT 
					end
					#ws.send(eval("$SAFE = 3 ; begin $stdout = StringIO.new; #{msg}; $stdout.string; rescue ws.send($!.to_s) ;ensure $stdout = STDOUT; end"))
				}
			end
		end
		ws.onclose { puts "WebSocket Connection closed" }
	end
}

