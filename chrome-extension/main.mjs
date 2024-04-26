import { ClientSideServiceWebSocket } from './WebSocket.mjs'
function promiseify(fn) {
  return (...args) => new Promise((res, rej) => {
    args = [...args, (...ret) => res(...ret)]
    fn(...args)
  })
}
const getWindows = promiseify(chrome.windows.getAll)
const getTabs = promiseify(chrome.tabs.query)
const updateTab = promiseify(chrome.tabs.update)
const updateWin = promiseify(chrome.windows.update)
const removeTab = promiseify(chrome.tabs.remove)
const reloadTab = promiseify(chrome.tabs.reload)
const getCurrentTab = promiseify(chrome.tabs.getCurrent)
const newTab = promiseify(chrome.tabs.create)
const getBookmarks = promiseify(chrome.bookmarks.getRecent)
const getHistory = promiseify(chrome.history.search)
const notify = promiseify(chrome.notifications.create)
const createWin = promiseify(chrome.windows.create)

function activeTab(tid) {
  return updateTab(tid, {
    active: true
  })
}
function activeWin(wid) {
  return updateWin(wid, {
    focused: true
  })
}

const provider = {
  getHistory,
  async getTabs() {
    return getTabs({})
    // let wins = (await getWindows())
    // return (await Promise.all(wins.map(win => getTabs(win.id))))
    //   .reduce((a, b) => (a.push(...b), a), [])
    //   .map(tab => ({
    //     active: tab.active,
    //     title: tab.title,
    //     url: tab.url,
    //     winId: tab.windowId,
    //     id: tab.id
    //   }))
  },
  async activeTab(winId, tabId) {
    await activeTab(tabId)
    await activeWin(winId)
  },
  async closeTab(tabId) {
    await removeTab(tabId)
  },
  async reloadTab(tabId) {
    await reloadTab(tabId)
  },
  async getCurrent() {
    return (await getCurrentTab()).map(tab => ({
      active: tab.active,
      title: tab.title,
      url: tab.url,
      winId: tab.windowId,
      id: tab.id
    }))
  },
  async newTab(prop) {
    await newTab(prop)
  },
  getBookmarks(count) {
    return getBookmarks(count)
  },
  async getHistory(opt) {
    opt.text = opt.text || ""
    return (await getHistory(opt)).map(h => ({
      title: h.title,
      url: h.url
    }))
  },
  //https://developer.chrome.com/apps/notifications#property-NotificationOptions-iconUrl
  async notify(prop) {
    prop.iconUrl = prop.iconUrl || chrome.extension.getURL("images/default.png")
    await notify(prop)
  },
  async createWin(prop) {
    await createWin(prop)
  }
}
let port = 9098
let delay = 2000
let cspSocket = new ClientSideServiceWebSocket(`ws://127.0.0.1:${port}/chrome`, delay, (state) => {
  //localStorage.setItem("state", state)
  chrome.runtime.sendMessage(state)
}, provider)
const states = {
  [WebSocket.CLOSED]: 'closed',
  [WebSocket.CLOSING]: 'closing',
  [WebSocket.CONNECTING]: 'connecting',
  [WebSocket.OPEN]: 'Connected'
}

chrome.runtime.onMessage.addListener((e) => {
  if (e.type == "query-state") {
    chrome.runtime.sendMessage(states[cspSocket.ws.readyState])
  } else {
    cspSocket.close();
    cspSocket = new ClientSideServiceWebSocket(`ws://127.0.0.1:${e.port}/chrome`,+e.delay, (state) => {
      chrome.runtime.sendMessage(state)
    }, provider)
  }
})

