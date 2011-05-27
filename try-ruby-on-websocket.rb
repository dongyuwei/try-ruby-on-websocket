#! /usr/bin/ruby
#author newdongyuwei@gmail.com

%w(rubygems sinatra sinatra/base  erubis eventmachine  em-websocket open3).each{|lib|require lib}

class WebServer < Sinatra::Base
    #enable :sessions

    use Rack::Static, :urls => ["/images","/css","/js" ], :root => "views"

    set  :run, true

    use Rack::Auth::Basic do |name, password|
        cmd = "svn ls https://svn1.intra.sina.com.cn/weibo/readme.txt --username #{name} --password #{password} --non-interactive --no-auth-cache --trust-server-cert"
        #system(cmd) == true # a hack for auth without ldap  ,haha!   
        #[name, password] == ['admin', 'test']
		true
    end
    
    error 403 do
      'Access forbidden'
    end

    get '/secret' do
      403
    end

    before do
       puts 'before filter' 
    end

    after do
       puts 'after filter' 
    end

    
	get '/' do
		'web socket demo:
		<hr>
		<textarea id="content" style="width:500px;height:200px;"></textarea>
		<br>
		<button id="request-permission">request-permission</button>
        <button id="send">send msg</button>
		<hr>
		logs:
		<br>
		<textarea id="log" style="width:500px;height:200px"></textarea>
		<script>
                function Notifier(){}

                Notifier.prototype.RequestPermission = function(cb){
                    window.webkitNotifications.requestPermission(function(){
                        if (cb) {
                            cb(window.webkitNotifications.checkPermission() == 0);
                        }
                    });
                }

                Notifier.prototype.Notify = function(icon, title, body){
                    if (window.webkitNotifications.checkPermission() === 0) {
                        var popup = window.webkitNotifications.createNotification(icon, title, body);
                        popup.show();
                        return true;
                    }
                    return false;
                }

                var notifier = new Notifier();
                document.getElementById("request-permission").onclick = function(){
                    notifier.RequestPermission();
                };
                
                /*------------------------------------------------------------------------------------------*/

				if (window.WebSocket) {
				    var ws = new WebSocket("ws://host:7777".replace("host",window.location.hostname));
				    
				    ws.onopen = function(){
				        ws.send("puts \"web socket demo\" ");
				    };
				    
				    ws.onmessage = function(evt){
				        var data = evt.data;
				        console.log(data);
                        notifier.Notify("http://www.google.com.hk/intl/zh-CN/images/logo_cn.png", "WebSocket message:", data)
		    			var log = document.getElementById("log");
			    		log.value = data;
				    };
				    
				    ws.onclose = function(){
				        console.log("socket closed");
				    };
					
				    document.getElementById("send").onclick = function(){
				        ws.send(document.getElementById("content").value.split("\n").join(";"));
				    };
				}else {
				    alert("You browser does not support  web sockets,try google chrome");
				};
		</script>
        '
	end
end

EM.kqueue = true if EM.kqueue? 
EM.epoll = true if EM.epoll?

EventMachine.run {
    WebServer.run!
    
    EventMachine::WebSocket.start(:host => "0.0.0.0",:port => 7777) do |ws|
        $_ws_ = ws
        module Handler
            def file_modified
                File.open("#{path}","r") do|f|
                    $_ws_.send(f.read)
                end
            end
        end

        EM.watch_file(File.join(Dir.pwd,'test.js'), Handler)
        
        ws.onopen {
          puts "WebSocket connection open"
        }
        ws.onmessage do |msg|
            puts "WebSocket Recieved message: #{msg}"
            begin
                EM.system('ruby','-e',msg) do |out,status|
                    puts status.exitstatus
                    ws.send(out)
                end
            rescue
                puts 'error: #{$!}'
                ws.send($!.to_s)
            end
          
        end
        ws.onclose { puts "WebSocket Connection closed" }
    end
}
