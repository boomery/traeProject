console.log('视频检测脚本已注入');
let detectedUrls = new Set();

function isVideoUrl(url) {
    const videoExtensions = ['.mp4', '.m3u8', '.ts', '.flv', '.f4v', '.mov', '.m4v', '.avi', '.mkv', '.wmv'];
    return videoExtensions.some(ext => url.toLowerCase().includes(ext));
}

function postVideoResource(type, url) {
    if (!detectedUrls.has(url) && isVideoUrl(url)) {
        console.log('检测到视频资源:', type, url);
        detectedUrls.add(url);
        window.webkit.messageHandlers.videoResource.postMessage([{
            type: type,
            url: url,
            title: document.title || '未知视频'
        }]);
    }
}

const originalXHR = window.XMLHttpRequest;
window.XMLHttpRequest = function() {
    const xhr = new originalXHR();
    const originalOpen = xhr.open;
    xhr.open = function() {
        const url = arguments[1];
        if (isVideoUrl(url)) {
            postVideoResource('XHR请求', url);
        }
        return originalOpen.apply(this, arguments);
    };
    return xhr;
};

const originalFetch = window.fetch;
window.fetch = function(input) {
    const url = (input instanceof Request) ? input.url : input;
    if (isVideoUrl(url)) {
        postVideoResource('Fetch请求', url);
    }
    return originalFetch.apply(this, arguments);
};

function detectVideoResources() {
    document.querySelectorAll('video').forEach(video => {
        if (video.src) {
            postVideoResource('video标签', video.src);
        }
        video.querySelectorAll('source').forEach(source => {
            if (source.src) {
                postVideoResource('source标签', source.src);
            }
        });
    });
    
    document.querySelectorAll('source[type^="video/"]').forEach(source => {
        if (source.src) {
            postVideoResource('source标签', source.src);
        }
    });
    
    document.querySelectorAll('a').forEach(link => {
        if (link.href && isVideoUrl(link.href)) {
            postVideoResource('链接', link.href);
        }
    });
}

const observer = new MutationObserver(() => {
    detectVideoResources();
});

observer.observe(document.body, {
    childList: true,
    subtree: true
});

detectVideoResources();