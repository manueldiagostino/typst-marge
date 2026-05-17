#import "/src/lib.typ": sidenote

#set page(width: 8cm, height: auto, margin: (outside: 4cm, rest: 5mm))

// Test .with() pattern as described in the user's instructions
#let tight-sidenote = sidenote.with(leading-in-gap: false, gap: 2pt)

#lorem(5)
#tight-sidenote[Tight note via .with().]
#tight-sidenote[Another tight note.]
#lorem(10)
