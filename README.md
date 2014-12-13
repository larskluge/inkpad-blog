# An Inkpad.io-based Blog Generator

[Ideas and future plans](http://www.inkpad.io/dpOnvOCG0r)


## Install

   npm install -g inkpad-blog


## Generate [a sample blog](http://www.inkpad.io/2dFtYP8H76):

    inkpad-blog --id 2dFtYP8H76

The generated static files output is now in `_build` and can be copied over to your nginx or push to Github Pages or just something that can serve static html files.


## Render 5 blog posts per page (default 3)

    inkpad-blog --id 2dFtYP8H76 --per-page 5


## Custom Themes

    mkdir ~/my-inkpad-blog-theme
    cp templates/* ~/my-inkpad-blog-theme/
    inkpad-blog --id 2dFtYP8H76 --templates-path ~/my-inkpad-blog-theme/

