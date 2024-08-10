SLIDE_QMD_FILES := $(wildcard *.qmd)
SLIDE_HTML_FILES  := $(subst qmd,html,$(SLIDE_QMD_FILES))

all: images/diag-*.png $(SLIDE_HTML_FILES) 

%.html: %.qmd
	quarto render $<

images/diag-*.png: images/mermaid.md
	mmdc -i images/mermaid.md -o images/diag.png

clean:
	rm -rf images/diag-*.png
	rm -f *.html

