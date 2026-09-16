// CodeEditor - 嵌入式代码编辑器组件
// 参考 QuickEdit 高级版的核心编辑功能，为 HarmonyOS 适配的轻量级代码编辑器
// 支持行号、语法高亮、搜索、缩进控制、只读查看模式

export interface CodeEditorTheme {
  background: string;
  text: string;
  lineNumber: string;
  keyword: string;
  string: string;
  number: string;
  boolean: string;
  nullColor: string;
  punctuation: string;
  searchHighlight: string;
  currentLine: string;
  selection: string;
}

export function defaultEditorTheme(isDark: boolean): CodeEditorTheme {
  if (isDark) {
    return {
      background: '#1E1E2E',
      text: '#CDD6F4',
      lineNumber: '#585B70',
      keyword: '#CBA6F7',
      string: '#A6E3A1',
      number: '#FAB387',
      boolean: '#F38BA8',
      nullColor: '#6C7086',
      punctuation: '#9399B2',
      searchHighlight: '#F9E2AF',
      currentLine: '#313244',
      selection: '#45475A'
    };
  }
  return {
    background: '#FFFFFF',
    text: '#4C4F69',
    lineNumber: '#9CA3AF',
    keyword: '#8839EF',
    string: '#40A02B',
    number: '#FE640B',
    boolean: '#D20F39',
    nullColor: '#6C6F85',
    punctuation: '#7287FD',
    searchHighlight: '#DF8E1D',
    currentLine: '#E6E9EF',
    selection: '#CCD0DA'
  };
}

// JSON 语法高亮：逐行分析，返回带颜色的文本段
export interface HighlightSegment {
  text: string;
  color: string;
}

export function highlightJsonLine(line: string, theme: CodeEditorTheme): HighlightSegment[] {
  const segments: HighlightSegment[] = [];
  let i = 0;
  while (i < line.length) {
    const ch = line[i];
    // 字符串
    if (ch === '"') {
      let end = i + 1;
      while (end < line.length) {
        if (line[end] === '\\' && end + 1 < line.length) { end += 2; continue; }
        if (line[end] === '"') { end++; break; }
        end++;
      }
      const str = line.substring(i, end);
      // 判断是 key 还是 value
      const after = line.substring(end).trimStart();
      const isKey = after.startsWith(':');
      segments.push({ text: str, color: isKey ? theme.keyword : theme.string });
      i = end;
      continue;
    }
    // 数字
    if (ch >= '0' && ch <= '9' || (ch === '-' && i + 1 < line.length && line[i + 1] >= '0' && line[i + 1] <= '9')) {
      let end = i + 1;
      while (end < line.length && ((line[end] >= '0' && line[end] <= '9') || line[end] === '.' || line[end] === 'e' || line[end] === 'E' || line[end] === '+' || line[end] === '-')) {
        end++;
      }
      segments.push({ text: line.substring(i, end), color: theme.number });
      i = end;
      continue;
    }
    // true/false
    if (line.substring(i, i + 4) === 'true') {
      segments.push({ text: 'true', color: theme.boolean });
      i += 4;
      continue;
    }
    if (line.substring(i, i + 5) === 'false') {
      segments.push({ text: 'false', color: theme.boolean });
      i += 5;
      continue;
    }
    // null
    if (line.substring(i, i + 4) === 'null') {
      segments.push({ text: 'null', color: theme.nullColor });
      i += 4;
      continue;
    }
    // 标点符号
    if (ch === '{' || ch === '}' || ch === '[' || ch === ']' || ch === ':' || ch === ',') {
      segments.push({ text: ch, color: theme.punctuation });
      i++;
      continue;
    }
    // 其他文本
    let end = i;
    while (end < line.length && line[end] !== '"' && line[end] !== '{' && line[end] !== '}' && line[end] !== '[' && line[end] !== ']' && line[end] !== ':' && line[end] !== ',' && !(line[end] >= '0' && line[end] <= '9')) {
      end++;
    }
    if (end === i) end = i + 1;
    segments.push({ text: line.substring(i, end), color: theme.text });
    i = end;
  }
  return segments;
}

// 搜索匹配
export interface SearchMatch {
  lineIndex: number;
  startCol: number;
  endCol: number;
}

export function findSearchMatches(lines: string[], query: string, useRegex: boolean, caseSensitive: boolean): SearchMatch[] {
  const matches: SearchMatch[] = [];
  if (!query) return matches;
  let pattern: RegExp;
  try {
    if (useRegex) {
      pattern = new RegExp(query, caseSensitive ? 'g' : 'gi');
    } else {
      const escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      pattern = new RegExp(escaped, caseSensitive ? 'g' : 'gi');
    }
  } catch (err) {
    return matches;
  }
  for (let li = 0; li < lines.length; li++) {
    pattern.lastIndex = 0;
    let m: RegExpExecArray | null = pattern.exec(lines[li]);
    while (m !== null) {
      const match: SearchMatch = { lineIndex: li, startCol: m.index, endCol: m.index + m[0].length };
      matches.push(match);
      if (m[0].length === 0) pattern.lastIndex++;
      m = pattern.exec(lines[li]);
    }
  }
  return matches;
}

// JSON 验证结果
export interface ValidationResult {
  valid: boolean;
  error: string;
}

// 格式化 JSON 文本（缩进美化）
export function formatJson(text: string, indentSize: number): string {
  try {
    const parsed: Object = JSON.parse(text);
    return JSON.stringify(parsed, null, indentSize);
  } catch (e) {
    return text;
  }
}

// 验证 JSON 是否有效
export function validateJson(text: string): ValidationResult {
  try {
    JSON.parse(text);
    const result: ValidationResult = { valid: true, error: '' };
    return result;
  } catch (e) {
    const result: ValidationResult = { valid: false, error: (e as Error).message };
    return result;
  }
}

// 行数据源：用于 LazyForEach 虚拟化渲染，避免大量行导致 OOM
export class LineDataSource implements IDataSource {
  private lines: string[] = [];
  private listeners: DataChangeListener[] = [];

  constructor(lines: string[]) {
    this.lines = lines;
  }

  totalCount(): number {
    return this.lines.length;
  }

  getData(index: number): string {
    return this.lines[index];
  }

  updateData(lines: string[]): void {
    this.lines = lines;
    for (const listener of this.listeners) {
      listener.onDataReloaded();
    }
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener);
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const idx = this.listeners.indexOf(listener);
    if (idx >= 0) {
      this.listeners.splice(idx, 1);
    }
  }
}