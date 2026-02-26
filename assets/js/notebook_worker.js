// Web Worker for notebook cell execution.
// Loads cyanea-wasm and interprets a simple command language:
//   variable = Namespace.function(args)
//   Namespace.function(args)
//   display(expr)
//   display(expr, "type")
//   // comment or # comment

let wasmReady = false
let api = null

async function initWasm() {
  if (wasmReady) return
  const mod = await import("../vendor/cyanea/cyanea_wasm.js")
  await mod.default("/wasm/cyanea_wasm_bg.wasm")
  api = await import("../vendor/cyanea/index.js")
  wasmReady = true
}

// Namespace registry — maps string names to API namespace objects
function getNamespaces() {
  return {
    Seq: api.Seq,
    Align: api.Align,
    Stats: api.Stats,
    ML: api.ML,
    Chem: api.Chem,
    StructBio: api.StructBio,
    Phylo: api.Phylo,
    IO: api.IO,
    Omics: api.Omics,
    Core: api.Core,
  }
}

// ── Argument Parser ──────────────────────────────────────────────────────
// Parses a comma-separated argument list from a string, returning an array
// of parsed values. Supports: strings, numbers, booleans, null, arrays,
// objects (JSON), and variable references.

function parseArgList(argsStr, context) {
  argsStr = argsStr.trim()
  if (argsStr === "") return []

  const args = []
  let i = 0

  while (i < argsStr.length) {
    // Skip whitespace
    while (i < argsStr.length && argsStr[i] === " ") i++
    if (i >= argsStr.length) break

    const [value, newI] = parseValue(argsStr, i, context)
    args.push(value)
    i = newI

    // Skip whitespace then comma
    while (i < argsStr.length && argsStr[i] === " ") i++
    if (i < argsStr.length && argsStr[i] === ",") i++
  }

  return args
}

function parseValue(str, i, context) {
  // Skip whitespace
  while (i < str.length && str[i] === " ") i++

  const ch = str[i]

  // String literal (double or single quoted)
  if (ch === '"' || ch === "'") {
    return parseString(str, i)
  }

  // Array literal
  if (ch === "[") {
    return parseArray(str, i, context)
  }

  // Object literal
  if (ch === "{") {
    return parseObject(str, i, context)
  }

  // Number, boolean, null, or variable reference
  return parseAtom(str, i, context)
}

function parseString(str, i) {
  const quote = str[i]
  i++ // skip opening quote
  let result = ""
  while (i < str.length && str[i] !== quote) {
    if (str[i] === "\\") {
      i++
      const esc = { n: "\n", t: "\t", r: "\r", "\\": "\\", "'": "'", '"': '"' }
      result += esc[str[i]] || str[i]
    } else {
      result += str[i]
    }
    i++
  }
  i++ // skip closing quote
  return [result, i]
}

function parseArray(str, i, context) {
  i++ // skip [
  const items = []
  while (i < str.length) {
    while (i < str.length && str[i] === " ") i++
    if (str[i] === "]") { i++; break }
    const [val, newI] = parseValue(str, i, context)
    items.push(val)
    i = newI
    while (i < str.length && str[i] === " ") i++
    if (str[i] === ",") i++
  }
  return [items, i]
}

function parseObject(str, i, context) {
  i++ // skip {
  const obj = {}
  while (i < str.length) {
    while (i < str.length && str[i] === " ") i++
    if (str[i] === "}") { i++; break }
    // Parse key (string or unquoted identifier)
    let key
    if (str[i] === '"' || str[i] === "'") {
      const [k, newI] = parseString(str, i)
      key = k
      i = newI
    } else {
      let k = ""
      while (i < str.length && /[a-zA-Z0-9_]/.test(str[i])) { k += str[i]; i++ }
      key = k
    }
    while (i < str.length && str[i] === " ") i++
    if (str[i] === ":") i++ // skip colon
    const [val, newI] = parseValue(str, i, context)
    obj[key] = val
    i = newI
    while (i < str.length && str[i] === " ") i++
    if (str[i] === ",") i++
  }
  return [obj, i]
}

function parseAtom(str, i, context) {
  let token = ""
  // Read until delimiter (comma, paren, bracket, brace, end)
  while (i < str.length && !/[,)\]\}]/.test(str[i])) {
    token += str[i]
    i++
  }
  token = token.trim()

  if (token === "true") return [true, i]
  if (token === "false") return [false, i]
  if (token === "null") return [null, i]

  // Number
  if (/^-?\d+(\.\d+)?$/.test(token)) {
    return [parseFloat(token), i]
  }

  // Variable reference
  if (/^[a-zA-Z_]\w*$/.test(token) && context.has(token)) {
    return [context.get(token), i]
  }

  // Unknown — return as string
  return [token, i]
}

// ── Line Parser ──────────────────────────────────────────────────────────
// Parses a single line of code and returns an execution descriptor.

function parseLine(line) {
  line = line.trim()

  // Empty or comment
  if (!line || line.startsWith("//") || line.startsWith("#")) {
    return { type: "skip" }
  }

  // display(expr) or display(expr, "type")
  const displayMatch = line.match(/^display\((.+)\)$/)
  if (displayMatch) {
    return { type: "display", argsStr: displayMatch[1] }
  }

  // Assignment: varName = Namespace.function(args)
  const assignMatch = line.match(/^([a-zA-Z_]\w*)\s*=\s*(.+)$/)
  if (assignMatch) {
    const varName = assignMatch[1]
    const expr = assignMatch[2].trim()
    const call = parseCall(expr)
    if (call) {
      return { type: "assign", varName, ...call }
    }
    // Could be assigning a literal or variable
    return { type: "assign_literal", varName, expr }
  }

  // Bare call: Namespace.function(args)
  const call = parseCall(line)
  if (call) {
    return { type: "call", ...call }
  }

  // Fallback: treat as expression
  return { type: "expression", expr: line }
}

function parseCall(expr) {
  const match = expr.match(/^([A-Z]\w*)\.(\w+)\((.*)?\)$/)
  if (!match) return null
  return {
    namespace: match[1],
    funcName: match[2],
    argsStr: match[3] || "",
  }
}

// ── Executor ─────────────────────────────────────────────────────────────

function executeCall(namespace, funcName, args) {
  const namespaces = getNamespaces()
  const ns = namespaces[namespace]
  if (!ns) {
    throw new Error(`Unknown namespace: ${namespace}`)
  }
  const fn = ns[funcName]
  if (typeof fn !== "function") {
    throw new Error(`Unknown function: ${namespace}.${funcName}`)
  }
  return fn(...args)
}

function executeCode(code, context) {
  const lines = code.split("\n")
  let lastResult = undefined
  let displayOutputs = []

  for (const line of lines) {
    const parsed = parseLine(line)

    switch (parsed.type) {
      case "skip":
        break

      case "display": {
        const displayArgs = parseArgList(parsed.argsStr, context)
        const value = displayArgs[0]
        const outputType = displayArgs[1] || null
        displayOutputs.push({ value, outputType })
        break
      }

      case "assign": {
        const args = parseArgList(parsed.argsStr, context)
        const result = executeCall(parsed.namespace, parsed.funcName, args)
        context.set(parsed.varName, result)
        lastResult = result
        break
      }

      case "assign_literal": {
        const args = parseArgList(parsed.expr, context)
        const value = args[0]
        context.set(parsed.varName, value)
        lastResult = value
        break
      }

      case "call": {
        const args = parseArgList(parsed.argsStr, context)
        lastResult = executeCall(parsed.namespace, parsed.funcName, args)
        break
      }

      case "expression": {
        // Try to resolve as variable reference
        const trimmed = parsed.expr.trim()
        if (context.has(trimmed)) {
          lastResult = context.get(trimmed)
        }
        break
      }
    }
  }

  return { lastResult, displayOutputs }
}

// ── Auto-detect output type ──────────────────────────────────────────────

function detectOutputType(value) {
  if (value === null || value === undefined) return { type: "text", data: "null" }
  if (typeof value === "string") return { type: "text", data: value }
  if (typeof value === "number") return { type: "text", data: String(value) }
  if (typeof value === "boolean") return { type: "text", data: String(value) }

  if (Array.isArray(value)) {
    if (value.length > 0 && typeof value[0] === "object" && value[0] !== null) {
      return { type: "table", data: value }
    }
    if (value.length > 0 && Array.isArray(value[0])) {
      return { type: "table", data: value }
    }
    return { type: "text", data: JSON.stringify(value, null, 2) }
  }

  if (typeof value === "object") {
    // Alignment result
    if (value.aligned_query && value.aligned_target) {
      return { type: "alignment", data: value }
    }
    // Table-like stats
    if (value.mean !== undefined || value.count !== undefined) {
      return { type: "table", data: [value] }
    }
    return { type: "text", data: JSON.stringify(value, null, 2) }
  }

  return { type: "text", data: String(value) }
}

function buildOutput(value, forcedType) {
  if (forcedType) {
    const data = forcedType === "text" ? String(value) : value
    return { type: forcedType, data }
  }
  return detectOutputType(value)
}

// ── Message handler ──────────────────────────────────────────────────────

self.onmessage = async function (e) {
  const { type, cellId, code, context: contextEntries } = e.data

  if (type !== "execute") return

  try {
    if (!wasmReady) await initWasm()

    // Reconstruct context from entries
    const context = new Map(contextEntries || [])

    const startTime = performance.now()
    const { lastResult, displayOutputs } = executeCode(code, context)
    const elapsed = Math.round(performance.now() - startTime)

    // Build output: prefer display() outputs, fall back to last result
    let output
    if (displayOutputs.length > 0) {
      const last = displayOutputs[displayOutputs.length - 1]
      output = buildOutput(last.value, last.outputType)
    } else if (lastResult !== undefined) {
      output = detectOutputType(lastResult)
    } else {
      output = { type: "text", data: "(no output)" }
    }

    output.timing_ms = elapsed

    self.postMessage({
      type: "result",
      cellId,
      output,
      context: Array.from(context.entries()),
    })
  } catch (err) {
    self.postMessage({
      type: "error",
      cellId,
      message: err.message || String(err),
    })
  }
}
