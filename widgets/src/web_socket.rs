use crate::lua_module::*;
use mlua::prelude::*;
use std::collections::HashMap;
use std::net::TcpListener;
use std::sync::mpsc::{channel, Receiver, Sender};
use std::sync::{Arc, Mutex};
use std::thread::spawn;
use tungstenite::handshake::server::Request;
use tungstenite::{accept_hdr, Message};
struct WsServer {
    connections: Arc<Mutex<HashMap<String, Arc<Connection>>>>,
}
struct Connection {
    //Send to websocket
    sender: Sender<(String, Sender<String>)>,
    // read from WebSocket
    //receiver:Receiver<String>
}
impl WsServer {
    fn new(port: u32) -> WsServer {
        let connections = Arc::new(Mutex::new(HashMap::new()));
        let conns = connections.clone();
        let handler = spawn(move || {
            let server = TcpListener::bind(format!("0.0.0.0:{}", port)).unwrap();
            for stream in server.incoming() {
                let c = conns.clone();
                spawn(move || {
                    let mut url = String::from("");
                    let mut ws = accept_hdr(stream.unwrap(), |req: &Request, resp| {
                        println!("req.url {}", req.uri().to_string());
                        url = req.uri().to_string();
                        Ok(resp)
                    })
                    .unwrap();

                    let (tx, rx) = channel();
                    let connection = Connection { sender: tx.clone() };
                    {
                        let mut c = c.lock().unwrap();
                        c.insert(url, Arc::new(connection));
                    }
                    let mut seq = 0;
                    //
                    loop {
                        let (msg, send_back) = rx.recv().unwrap();
                        ws.send(Message::from(format!("{}:{}", seq, msg)));
                        loop {
                            let msg = ws.read().unwrap();
                            if msg.is_text() {
                                let text_msg = msg.to_text().unwrap();
                                if text_msg.starts_with(&format!("{}:", seq).to_string()) {
                                    send_back.send(String::from(
                                        text_msg.trim_start_matches(format!("{}:", seq).as_str()),
                                    ));
                                }
                                break;
                            }
                        }
                        seq += 1;
                    }
                });
            }
        });
        WsServer { connections }
    }
    fn connection(&self, path: String) -> Option<Arc<Connection>> {
        let connections = self.connections.lock().unwrap();
        for k in connections.keys() {
            println!("ws key::{}:: ::{}:: ",k,path);
        }
        let c = connections.get(&path);
        if let Some(c) = c {
            Some(Arc::clone(c))
        } else {
            None
        }
    }
}

AddMethods!(WsServer,methods=>{
    methods.add_method("connection",|_,s,path:String|{
        let conn = s.connection(path);
        if let Some(conn) = conn {
            Ok(LuaWrapper(conn))
        } else {
            Err(LuaError::runtime("Connection not ready"))
        }
    });
});
AddMethods!(Arc<Connection>,methods=>{
    methods.add_method("send",|_,conn,(str,timeout):(String,u64)|{
        let (tx,rx) = channel::<String>();
        conn.sender.send((str,tx));
        let resp = rx.recv_timeout(std::time::Duration::from_millis(timeout));
        if let Ok(data) = resp {
            Ok(data)
        } else {
            Err(LuaError::runtime("Read response time out"))
        }
    });
});

pub fn exports(lua: &Lua) -> LuaResult<LuaTable> {
    let table = lua.create_table()?;
    table.set(
        "new",
        lua.create_function(|_, port: u32| Ok(LuaWrapper(WsServer::new(port))))?,
    );
    Ok(table)
}
