#import "/src/lib.typ": sidenote

#set page(width: 8cm, height: auto, margin: (outside: 4cm, rest: 5mm))

// Test 1: Default behavior (leading-in-gap: true) — same-line notes should be spaced apart
#lorem(5)
#sidenote[Note 1 with default leading.]
#sidenote[Note 2 with default leading.]
#lorem(10)

// Test 2: leading-in-gap: false — same-line notes should stack tightly
#lorem(5)
#sidenote(leading-in-gap: false, gap: 2pt)[Tight note 1.]
#sidenote(leading-in-gap: false, gap: 2pt)[Tight note 2.]
#lorem(10)

// Test 3: Different-line notes with leading-in-gap: false should still respect line spacing
#lorem(5)
#sidenote(leading-in-gap: false, gap: 2pt)[Different line note.]
#lorem(20)
#sidenote(leading-in-gap: false, gap: 2pt)[Another different line note.]
#lorem(5)
