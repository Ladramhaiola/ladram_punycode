import gleam/bool
import gleam/int
import gleam/list
import gleam/order
import gleam/result
import gleam/string

const base = 36

const tmin = 1

const tmax = 26

const skew = 38

const damp = 700

const initial_bias = 72

const initial_n = 128

// "-" as utf codepoint
const delimiter = 45

// h - handled code points count
// b - basic code points count
type Encoder {
  Encoder(n: Int, delta: Int, bias: Int, h: Int, b: Int)
}

fn new_encoder(h: Int, b: Int) -> Encoder {
  Encoder(n: initial_n, delta: 0, bias: initial_bias, h:, b:)
}

type Decoder {
  Decoder(n: Int, delta: Int, bias: Int, i: Int, k: Int, w: Int)
}

fn new_decoder(k: Int, w: Int) -> Decoder {
  Decoder(n: initial_n, delta: 0, bias: initial_bias, i: 0, k:, w:)
}

// Encoding

pub fn encode_string(input: String) -> Result(String, Nil) {
  input
  |> string.to_utf_codepoints
  |> list.map(string.utf_codepoint_to_int)
  |> encode
  |> list.try_map(string.utf_codepoint)
  |> result.map(string.from_utf_codepoints)
}

pub fn encode(input: List(Int)) {
  let basic = input |> list.filter(fn(c) { c < 128 }) |> list.reverse

  case list.length(basic) {
    0 -> encode_whileloop(input, [], new_encoder(0, 0))
    n -> encode_whileloop(input, [delimiter, ..basic], new_encoder(n, n))
  }
}

fn encode_whileloop(input: List(Int), output: List(Int), state: Encoder) {
  use <- bool.guard(state.h >= list.length(input), list.reverse(output))

  let m =
    input
    |> list.filter(fn(c) { c >= state.n })
    |> list.max(order.reverse(int.compare))
    |> result.unwrap(0)

  let delta = state.delta + { m - state.n } * { state.h + 1 }
  let n = m

  let #(output, state) =
    encode_foreachloop(input, output, Encoder(..state, delta:, n:))

  encode_whileloop(
    input,
    output,
    Encoder(..state, delta: state.delta + 1, n: state.n + 1),
  )
}

fn encode_foreachloop(input: List(Int), output: List(Int), state: Encoder) {
  let Encoder(n, delta, bias, h, b) = state

  case input {
    [] -> #(output, state)

    [c, ..rest] if c < n ->
      encode_foreachloop(rest, output, Encoder(..state, delta: delta + 1))

    [c, ..rest] if c == n -> {
      let output = encode_loop(output, base, delta, bias)
      let bias = adapt_bias(delta, h + 1, h == b)
      let new_state = Encoder(..state, delta: 0, h: h + 1, bias:)
      encode_foreachloop(rest, output, new_state)
    }

    [_, ..rest] -> encode_foreachloop(rest, output, state)
  }
}

fn encode_loop(output: List(Int), k: Int, q: Int, bias: Int) -> List(Int) {
  let t = threshold(k, bias)

  use <- bool.guard(q < t, [encode_digit(q), ..output])

  let encoded = encode_digit(t + { { q - t } % { base - t } })
  encode_loop([encoded, ..output], k + base, { q - t } / { base - t }, bias)
}

// Decoding

pub fn decode_string(input: String) -> Result(String, Nil) {
  input
  |> string.to_utf_codepoints
  |> list.map(string.utf_codepoint_to_int)
  |> decode
  |> list.try_map(string.utf_codepoint)
  |> result.map(string.from_utf_codepoints)
}

pub fn decode(input: List(Int)) {
  input
  |> list.reverse
  |> decode_split([], [])
}

fn decode_split(input: List(Int), basic: List(Int), extended: List(Int)) {
  case input {
    [] -> decode_whileloop(extended, list.reverse(basic), new_decoder(0, 0))
    [c, ..rest] if c == delimiter -> decode_split([], rest, extended)
    [c, ..rest] -> decode_split(rest, basic, [c, ..extended])
  }
}

fn decode_whileloop(input: List(Int), output: List(Int), state: Decoder) {
  use <- bool.guard(list.is_empty(input), output)

  let old_i = state.i

  let #(rest, state) = decode_loop(input, Decoder(..state, k: base, w: 1))

  let i = state.i
  let x = 1 + list.length(output)
  let bias = adapt_bias(i - old_i, x, old_i == 0)

  let n = state.n + { i / x }
  let i = i % x

  let #(head, tail) = list.split(output, i)

  decode_whileloop(
    rest,
    list.append(head, [n, ..tail]),
    Decoder(..state, n: n, i: i + 1, bias:),
  )
}

fn decode_loop(input: List(Int), state: Decoder) -> #(List(Int), Decoder) {
  let Decoder(_, _, bias, i, k, w) = state
  let assert [c, ..rest] = input

  let d = decode_digit(c)
  let i = i + d * w

  case threshold(k, bias) {
    t if d < t -> #(rest, Decoder(..state, i:))
    t ->
      decode_loop(rest, Decoder(..state, i:, k: k + base, w: w * { base - t }))
  }
}

// helper functions

fn threshold(k: Int, bias: Int) -> Int {
  case k {
    _ if k <= bias -> tmin
    _ if k >= bias + tmax -> tmax
    k -> k - bias
  }
}

fn adapt_bias(delta: Int, numpoints: Int, first_time: Bool) -> Int {
  let delta = case first_time {
    True -> delta / damp
    False -> int.bitwise_shift_right(delta, 1)
  }

  adapt_loop(delta + { delta / numpoints }, 0)
}

fn adapt_loop(delta: Int, k: Int) -> Int {
  case delta > int.bitwise_shift_right({ base - tmin } * tmax, 1) {
    True -> adapt_loop(delta / { base - tmin }, k + base)
    False -> k + { base - tmin + 1 } * delta / { delta + skew }
  }
}

fn encode_digit(n: Int) -> Int {
  case n < 26 {
    True -> n + 22 + 75
    False -> n + 22
  }
}

fn decode_digit(n: Int) -> Int {
  // n >= utf("0") && n <= utf("9")
  case n >= 48 && n <= 57 {
    True -> n - 22
    False -> n - 22 - 75
  }
}
