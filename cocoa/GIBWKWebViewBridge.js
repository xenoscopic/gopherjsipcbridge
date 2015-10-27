function _GIBConnect(sequence, pathBase64) {
    window.webkit.messageHandlers.GIBConnect.postMessage({
        sequence: sequence,
        pathBase64: pathBase64
    });
}

function _GIBConnectionRead(sequence, connectionId, length) {
    window.webkit.messageHandlers.GIBConnectionRead.postMessage({
        sequence: sequence,
        connectionId: connectionId,
        length: length
    });
}

function _GIBConnectionWrite(sequence, connectionId, dataBase64) {
    window.webkit.messageHandlers.GIBConnectionWrite.postMessage({
        sequence: sequence,
        connectionId: connectionId,
        dataBase64: dataBase64
    });
}

function _GIBConnectionClose(sequence, connectionId) {
    window.webkit.messageHandlers.GIBConnectionClose.postMessage({
        sequence: sequence,
        connectionId: connectionId
    });
}

function _GIBListen(sequence, pathBase64) {
    window.webkit.messageHandlers.GIBListen.postMessage({
        sequence: sequence,
        pathBase64: pathBase64
    });
}

function _GIBListenerAccept(sequence, listenerId) {
    window.webkit.messageHandlers.GIBListenerAccept.postMessage({
        sequence: sequence,
        listenerId: listenerId
    });
}

function _GIBListenerClose(sequence, listenerId) {
    window.webkit.messageHandlers.GIBListenerClose.postMessage({
        sequence: sequence,
        listenerId: listenerId
    });
}

_GIBBridge.SetConnectHandler(_GIBConnect);
_GIBBridge.SetConnectionReadHandler(_GIBConnectionRead);
_GIBBridge.SetConnectionWriteHandler(_GIBConnectionWrite);
_GIBBridge.SetConnectionCloseHandler(_GIBConnectionClose);
_GIBBridge.SetListenHandler(_GIBListen);
_GIBBridge.SetListenerAcceptHandler(_GIBListenerAccept);
_GIBBridge.SetListenerCloseHandler(_GIBConnectionClose);
