export class ClientSideServiceWebSocket {
  constructor(url, reconnectDelay, stateChange, provider) {
    const connect = () => {
      stateChange("connecting")
      console.log("connect ", url)
      this.ws = new WebSocket(url)
      let reconnectTimer;
      this.ws.addEventListener('open', () => {
        stateChange("connected")
      })
      this.ws.addEventListener('message', async (event) => {
        const indexOfSep = event.data.indexOf(':')
        if (indexOfSep > 0) {
          const seq = event.data.substring(0, indexOfSep);
          const payload = event.data.substring(indexOfSep + 1);
          let callInfo = JSON.parse(payload)
          let { args, method } = callInfo
          console.log('Message from server ', payload)
          if (method in provider) {
            console.log("call", method)
            let result = null;
            try {
              result = await provider[method](...(args || []))
              this.ws.send(seq + ':' + JSON.stringify({
                type: 'ok',
                result
              }))
            } catch (e) {
              this.ws.send(seq + ':' + JSON.stringify({
                type: 'error',
                result: e.message
              }))
            }
          }
        }
      })
      this.ws.addEventListener("close", () => {
        if (this.ws.readyState === WebSocket.CLOSED && !this.closed) {
          stateChange("close")
          setTimeout(connect, reconnectDelay)
        }
      })
    }
    connect()
  }
  close() {
    this.closed = true
    this.ws.close()
  }
}
