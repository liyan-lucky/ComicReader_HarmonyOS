import http from '@ohos.net.http';

export class HttpClient {
  static async getText(url: string, userAgent: string, referer: string): Promise<string> {
    return HttpClient.getTextWithHeaders(url, userAgent, referer, {});
  }

  static async getTextWithHeaders(url: string, userAgent: string, referer: string, extraHeaders: Record<string, string>): Promise<string> {
    const request = http.createHttp();
    const headers: Record<string, string> = {
      'User-Agent': userAgent.length > 0 ? userAgent : 'Mozilla/5.0 HarmonyOS ComicReader/1.0',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.7'
    };
    if (referer.length > 0) {
      headers['Referer'] = referer;
    }
    const keys = Object.keys(extraHeaders);
    for (let i = 0; i < keys.length; i++) {
      headers[keys[i]] = extraHeaders[keys[i]];
    }
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: 15000,
        readTimeout: 20000,
        expectDataType: http.HttpDataType.STRING
      });
      if (response.responseCode < 200 || response.responseCode >= 400) {
        throw new Error('HTTP ' + response.responseCode);
      }
      if (typeof response.result === 'string') {
        return response.result;
      }
      return JSON.stringify(response.result);
    } finally {
      request.destroy();
    }
  }
}
