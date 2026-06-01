#import "resolve.typ": *
#import "validate.typ": validate

/// Global state for all margin notes across the document.
#let global-state = state("marge/notes", ())
/// Get the container mark metadata for a specific page.
#let page-container(page) = metadata("marge/container-" + str(page))
/// The sidenote counter.
#let counter = counter("sidenote")

/// The default format for margin notes.
#let default-format(it) = {
  let num = if it.numbering != none {
    link(it.source, super(numbering(it.numbering, ..it.counter.at(it.source))))
    h(0.05em)
  }

  let indent = measure(num).width
  let _start = repr(resolve-side(start))

  pad(..((_start): indent), {
    if num != none {
      box(num, inset: ((_start): -indent))
      sym.wj + h(0pt, weak: true)
    }
    it.body
  })
}

/// A container of all margin notes of the current page.
///
/// To be used as the page's `background` or `foreground` parameter when the
/// page width is set to `auto`, as notes then cannot be automatically placed
/// in the right margin.
#let container = context {
  page-container(here().page())

  let all-notes = global-state.final()
  let current-page = here().page()
  let notes = all-notes.filter(note => note.anchor.position().page == current-page)
  let leading = par.leading.to-absolute()
  let (width: page-width, height: page-height) = resolve-page-size()
  let bottom-margin = resolve-margin(bottom)

  // Compute final positions with overlap avoidance and overflow correction
  let computed = ()
  for note in notes {
    let position = note.anchor.position()
    position.y += note.dy.to-absolute() - if note.anchor-param == "top" { measure[x].height } else { note.height }

    // Set x-position of note depending on side.
    position.x = if note.side == right and page-width != auto { page-width - note.margin }
                 else { 0pt }

    if note.dir == rtl { position.x += note.margin }

    // Move note down to avoid overlap with previous one.
    let prev = computed.at(-1, default: none)
    if prev != none and prev.side == note.side {
      let gap = calc.max(note.gap, prev.gap)
      let extra = if note.leading-in-gap { leading } else { 0pt }
      let overlap = prev.position.y + prev.height - position.y + extra + gap
      position.y += calc.max(0pt, overlap)
    }

    // Move note up to avoid overflow into bottom page margin.
    let overflow = position.y + note.height - page-height + bottom-margin
    position.y -= calc.max(0pt, overflow)

    computed.push((
      position: position,
      height: note.height,
      side: note.side,
      gap: note.gap,
      leading-in-gap: note.leading-in-gap,
      padding: note.padding,
      dir: note.dir,
      body: note.body,
    ))
  }

  // Move previous notes up to restore the gap and prevent overlap with
  // previously moved up notes, starting from the bottom.
  let current = computed.at(-1, default: none)
  if current != none {
    for (i, prev) in computed.enumerate().rev().filter(((_, n)) => n.side == current.side) {
      if i >= computed.len() - 1 { continue }
      let gap = calc.max(current.gap, prev.gap)
      let extra = if current.leading-in-gap { leading } else { 0pt }
      let overlap = prev.position.y + prev.height - current.position.y + extra + gap
      computed.at(i).position.y -= calc.max(0pt, overlap)
      current = computed.at(i)
    }
  }

  for note in computed {
    set text(dir: note.dir)
    place(top + note.side, note.body, dy: note.position.y)
  }
}

/// A sidenote to be placed in the page margin.
/// 
/// If this note ends up on the right margin of a page with width set to
/// `auto`, it cannot be placed automatically. In this case, the page's
/// `background` or `foreground` should be set to the include the `container`
/// provided by this package.
/// 
/// There are two correction mechanisms in place:
/// - When two notes would overlap, the second one is moved down to avoid this.
/// - When a note would overflow into the bottom margin, it is moved up. Any
///   previous notes that this note would now overlap with are also moved up.
/// 
/// # Parameters:
/// - `side`: The margin where the note should be placed.
/// - `dy`: A custom offset by which the note should be moved along the y-axis.
/// - `padding`: The space between the note and the page or content border.
/// - `gap`: The minimum gap between two consecutive notes.
/// - `leading-in-gap`: Whether to include the paragraph leading in the overlap
///   calculation.
/// - `numbering`: How the note should be numbered.
/// - `counter`: The counter to be used for numbering.
/// - `format`: The "show rule" of the note.
/// - `body`: The body of the note.
#let sidenote(
  side: auto,
  dy: 0pt,
  anchor: "top",
  padding: 2em,
  gap: 0.4em,
  leading-in-gap: true,
  numbering: none,
  counter: counter,
  format: it => it.default,
  body
) = {
  // Validate parameters.
  validate(
    side: side,
    dy: dy,
    anchor: anchor,
    padding: padding,
    gap: gap,
    leading-in-gap: leading-in-gap,
    numbering: numbering,
    counter: counter,
    format: format,
    body: body
  )

  // Place number in paragraph.
  if numbering != none {
    h(0pt, weak: true)

    context if resolve-dir() == rtl [\u{200E}]
    counter.step()

    context {
      let num = counter.display(numbering)
      link(here(), super(num))
    }
  }
  
  h(0pt, weak: true) + sym.wj + context if resolve-dir() == rtl [\u{200E}] + context {
    // Use side with largest margin if side is `auto`.
    let side = if side != auto { side } else {
      let margin-left = resolve-margin(left)
      let margin-right = resolve-margin(right)

      if margin-left > margin-right { left }
      else if margin-right > margin-left { right }
      else { "outside" }
    }

    // Resolve values.
    let dir = resolve-dir()
    let side = resolve-side(side)
    let padding = resolve-padding(padding)
    let margin = resolve-margin(side)
    let bottom-margin = resolve-margin(bottom)
    let (width: page-width, height: page-height) = resolve-page-size()
    let gap = gap.to-absolute()
    let leading = par.leading.to-absolute()

    // Create note content.
    let note-body = block(inset: padding, width: margin, {
      set align(start)
      set text(size: 0.85em)
      set par(leading: 0.5em)
      set par.line(numbering: none)

      let source = here()
      context {
        let it = (
          side: side,
          numbering: numbering,
          counter: counter,
          padding: padding,
          margin: margin,
          source: source,
          body: body,
        )
        it.default = default-format(it)
        format(it)
      }
    })
    
    // Resolve dy relative to note-height (if given as ratio).
    let note-height = measure(note-body).height
    let dy = if type(dy) == length { dy }
             else if type(dy) == ratio { dy * note-height }
             else if type(dy) == relative { dy.ratio * note-height + dy.length }
  
    // Register note in the global state with anchor location and metadata.
    // All placement, overlap avoidance, and overflow correction happen
    // in the container background phase.
    let anchor-loc = here()
    global-state.update(notes => {
      notes + ((
        anchor: anchor-loc,
        height: note-height,
        side: side,
        gap: gap,
        leading-in-gap: leading-in-gap,
        padding: padding,
        dir: dir,
        body: note-body,
        dy: dy,
        anchor-param: anchor,
        margin: margin,
      ),)
    })
  }
}
