const EXTENSION_MSG_PATH = "extensionRequest";

const _msgCompleters = {};

// send request to host app
async function requestApp({ id, message, request }) {
  return new Promise((resolve, reject) => {
    _msgCompleters[message + id] = { resolve, reject };
    window.send(EXTENSION_MSG_PATH, {
      id,
      msgType: message,
      request,
      url: window.location.href,
    });
  });
}

// get response from host app
function onAppResponse(msgType, response, error) {
  if (_msgCompleters[msgType]) {
    if (error) {
      _msgCompleters[msgType].reject(error);
    } else {
      _msgCompleters[msgType].resolve(response);
    }
  }
}

// send message to dapp page as extension-content
function _postResponse(data) {
  window.postMessage({ ...data, origin: "content" }, "*");
}

// handle message from dapp page as extension-content
async function handleMsg(data) {
  let response;
  switch (data.message) {
    case "pub(authorize.tab)":
      // get auth result from host app
      response = await requestApp(data);
      // always approve extension auth
      return _postResponse({ id: data.id, response });
    case "pub(accounts.list)":
      // get accounts from host app
      response = await requestApp(data);
      // then send result back to dapp page
      return _postResponse({ id: data.id, response });
    case "pub(metadata.list)":
      // we dont need this function, so return false
      return _postResponse({ id: data.id, response: false });
    case "pub(metadata.provide)":
      // we dont need this function, so return true
      return _postResponse({ id: data.id, response: true });
    case "pub(accounts.subscribe)":
      // // get accounts from host app
      requestApp(data).then((subscription) => {
        // then send result back to dapp page
        _postResponse({ id: data.id, subscription });
      });
      return _postResponse({ id: data.id, response: true });
    case "pub(bytes.sign)":
    case "pub(extrinsic.sign)":
      try {
        response = await requestApp(data);
        return _postResponse({ id: data.id, response });
      } catch (err) {
        return _postResponse({ id: data.id, error: err.message });
      }
    default:
      throw new Error(`Unable to handle message: ${data.message}`);
  }
}

export default {
  handleMsg,
  onAppResponse,
};
