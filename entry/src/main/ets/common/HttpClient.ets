import http from '@ohos.net.http';
import util from '@ohos.util';

function isAllowedHttpUrl(url: string): boolean {
  const value = url.trim().toLowerCase();
  return value.startsWith('https://') || value.startsWith('http://');
}

function isSafeHeaderName(name: string): boolean {
  return /^[A-Za-z0-9-]{1,64}$/.test(name);
}

function isSafeHeaderValue(value: string): boolean {
  return value.length <= 2048 && value.indexOf('\n') < 0 && value.indexOf('\r') < 0;
}

export class HttpClient {
  static async getBytes(url: string, userAgent: string, referer: string): Promise<ArrayBuffer> {
    if (!isAllowedHttpUrl(url)) throw new Error('Only HTTP/HTTPS URLs are allowed');
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'User-Agent': userAgent.length > 0 ? userAgent : 'Mozilla/5.0 HarmonyOS ComicReader/1.0',
      'Accept': 'image/avif,image/webp,image/png,image/jpeg,image/*;q=0.9,*/*;q=0.5'
    };
    if (referer.length > 0 && isAllowedHttpUrl(referer)) headers['Referer'] = referer;
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: 15000,
        readTimeout: 30000,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });
      if (response.responseCode < 200 || response.responseCode >= 400 || !(response.result instanceof ArrayBuffer)) {
        throw new Error('Cover request failed: HTTP ' + response.responseCode);
      }
      return response.result;
    } finally {
      request.destroy();
    }
  }

  static async getText(url: string, userAgent: string, referer: string): Promise<string> {
    return HttpClient.getTextWithHeaders(url, userAgent, referer, {});
  }

  static async getTextWithProgress(url: string, userAgent: string, referer: string,
    onProgress: (received: number, total: number) => void): Promise<string> {
    // Catalog payloads are tens of megabytes and GitHub Raw can be slow on
    // mobile networks. Keep ordinary page requests at 20 seconds, but allow
    // a foreground, user-confirmed catalog download to finish.
    return HttpClient.requestText(url, userAgent, referer, {}, onProgress, 900000, true);
  }

  static async getTextWithProgressTimeout(url: string, userAgent: string, referer: string,
    onProgress: (received: number, total: number) => void, readTimeout: number): Promise<string> {
    return HttpClient.requestText(url, userAgent, referer, {}, onProgress, readTimeout, true);
  }

  static async getTextWithTimeout(url: string, userAgent: string, referer: string,
    readTimeout: number): Promise<string> {
    return HttpClient.requestText(url, userAgent, referer, {}, undefined, readTimeout);
  }

  static async getTextWithHeaders(url: string, userAgent: string, referer: string, extraHeaders: Record<string, string>): Promise<string> {
    return HttpClient.requestText(url, userAgent, referer, extraHeaders);
  }

  private static async requestText(url: string, userAgent: string, referer: string,
    extraHeaders: Record<string, string>, onProgress?: (received: number, total: number) => void,
    readTimeout: number = 20000, useArrayBuffer: boolean = false): Promise<string> {
    if (!isAllowedHttpUrl(url)) {
      throw new Error('Only HTTP/HTTPS URLs are allowed');
    }
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'User-Agent': userAgent.length > 0 && isSafeHeaderValue(userAgent) ? userAgent : 'Mozilla/5.0 HarmonyOS ComicReader/1.0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.7'
    };
    if (referer.length > 0 && isAllowedHttpUrl(referer) && isSafeHeaderValue(referer)) {
      headers['Referer'] = referer;
    }
    const keys = Object.keys(extraHeaders);
    for (let i = 0; i < keys.length; i++) {
      const name = keys[i];
      const value = extraHeaders[name];
      if (isSafeHeaderName(name) && isSafeHeaderValue(value)) {
        headers[name] = value;
      }
    }
    if (onProgress) {
      request.on('dataReceiveProgress', (info: http.DataReceiveProgressInfo) => {
        onProgress(info.receiveSize, info.totalSize);
      });
    }
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: 15000,
        readTimeout: readTimeout,
        expectDataType: useArrayBuffer ? http.HttpDataType.ARRAY_BUFFER : http.HttpDataType.STRING
      });
      if (response.responseCode < 200 || response.responseCode >= 400) {
        throw new Error('HTTP ' + response.responseCode);
      }
      if (typeof response.result === 'string') {
        return response.result;
      }
      if (response.result instanceof ArrayBuffer) {
        const decoder = new util.TextDecoder('utf-8');
        return decoder.decodeToString(new Uint8Array(response.result));
      }
      return JSON.stringify(response.result);
    } finally {
      request.destroy();
    }
  }
}
