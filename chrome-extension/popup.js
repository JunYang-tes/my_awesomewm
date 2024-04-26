window.addEventListener("load", () => {
  console.log(chrome)
  const port = document.getElementById("port")
  const delay = document.getElementById("delay")
  const save = document.getElementById("save")
  const stateEle = document.getElementById("state")
  const getValue = () => {
    port.value = localStorage.getItem("port") || "9098"
    delay.value = localStorage.getItem("delay") || "2"
    stateEle.innerText = ""
  }
  save.addEventListener("click", () => {
    localStorage.setItem("port", port.value)
    localStorage.setItem("delay", delay.value)
    chrome.runtime.sendMessage({ port: port.value, delay: delay.value })
  })
  getValue()

  chrome.runtime.sendMessage({ port: port.value, delay: delay.value })
  chrome.runtime.sendMessage({ type: 'query-state' })
  chrome.runtime.onMessage.addListener((e) => {
    stateEle.innerText = e
  })
})
