import gleam/list
import gleeunit
import ladram_punycode as punycode

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn encode_decode_table_test() {
  let cases = [
    #("", ""),
    #("-", "--"),
    #("-a", "-a-"),
    #("-a-", "-a--"),
    #("a", "a-"),
    #("a-", "a--"),
    #("a-b", "a-b-"),
    #("London", "London-"),
    #("London-", "London--"),
    #("München", "Mnchen-3ya"),
    #("ยจฆฟคฏข", "22cdfh1b8fsa"),
    #("도메인", "hq1bm8jm9l"),
    #("Hello世界", "Hello-ck1hg65u"),
    #("🥹 + ⭐ -> 🤩", " +  -> -iu5er7119avwa"),
    //
    // The test cases below come from RFC 3492 section 7.1 with Errata 3026.
    //
    // (A) Arabic (Egyptian).
    #("ليهمابتكلموشعربي؟", "egbpdaj6bu4bxfgehfvwxn"),
    // (B) Chineese (simplified).
    #("他们为什么不说中文", "ihqwcrb4cv8a8dqg056pqjye"),
    // (C) Chineese (traditonal).
    #("他們爲什麽不說中文", "ihqwctvzc91f659drss3x8bo0yb"),
    // (D) Czech.
    #("Pročprostěnemluvíčesky", "Proprostnemluvesky-uyb24dma41a"),
    // (E) Hebrew.
    #("למההםפשוטלאמדבריםעברית", "4dbcagdahymbxekheh6e0a7fei0b"),
    // (F) Hindi (Devanagari).
    #("यहलोगहिन्दीक्योंनहींबोलसकतेहैं", "i1baa7eci9glrd9b2ae1bj0hfcgg6iyaf8o0a1dig0cd"),
    // (G) Japanese (kanji and hiragana).
    #("なぜみんな日本語を話してくれないのか", "n8jok5ay5dzabd5bym9f0cm5685rrjetr6pdxa"),
    // (H) Korean (Hangul syllables).
    #(
      "세계의모든사람들이한국어를이해한다면얼마나좋을까",
      "989aomsvi5e83db1d2a355cv1e0vak1dwrv93d5xbh15a0dt30a5jpsd879ccm6fea98c",
    ),
    // (I) Russian (Cyrillic).
    #("почемужеонинеговорятпорусски", "b1abfaaepdrnnbgefbadotcwatmq2g4l"),
    // (J) Spanish.
    #(
      "PorquénopuedensimplementehablarenEspañol",
      "PorqunopuedensimplementehablarenEspaol-fmd56a",
    ),
    // (K) Vietnamese.
    #(
      "TạisaohọkhôngthểchỉnóitiếngViệt",
      "TisaohkhngthchnitingVit-kjcr8268qyxafd2f1b9g",
    ),
    // (L) 3<nen>B<gumi><kinpachi><sensei>.
    #("3年B組金八先生", "3B-ww4c5e180e575a65lsy2b"),
    // (M) <amuro><namie>-with-SUPER-MONKEYS.
    #("安室奈美恵-with-SUPER-MONKEYS", "-with-SUPER-MONKEYS-pc58ag80a8qai00g7n9n"),
    // (N) Hello-Another-Way-<sorezore><no><basho>.
    #("Hello-Another-Way-それぞれの場所", "Hello-Another-Way--fc4qua05auwb3674vfr0b"),
    // (O) <hitotsu><yane><no><shita>2.
    #("ひとつ屋根の下2", "2-u9tlzr9756bt3uc0v"),
    // (P) Maji<de>Koi<suru>5<byou><mae>
    #("MajiでKoiする5秒前", "MajiKoi5-783gue6qz075azm5e"),
    // (Q) <pafii>de<runba>
    #("パフィーdeルンバ", "de-jg4avhby1noc0d"),
    // (R) <sono><supiido><de>
    #("そのスピードで", "d9juau41awczczp"),
    // (S) -> $1.00 <-
    #("-> $1.00 <-", "-> $1.00 <--"),
  ]

  list.each(cases, fn(tc: #(String, String)) {
    let assert Ok(encoded) = punycode.encode_string(tc.0)
    assert encoded == tc.1 as { "encode: assertion failed for: " <> tc.0 }

    let assert Ok(decoded) = punycode.decode_string(encoded)
    assert decoded == tc.0 as { "decode: assertion failed for: " <> tc.0 }
  })
}
