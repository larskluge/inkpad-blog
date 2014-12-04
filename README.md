# An Inkpad.io-based Blog

To render this sample blog: http://www.inkpad.io/2dFtYP8H76

    gulp --id 2dFtYP8H76


Render 5 blog posts per page (default 3)

    gulp --id 2dFtYP8H76 --per-page 5


## Custom Themes

    mkdir ~/my-inkpad-blog-theme
    cp templates/* ~/my-inkpad-blog-theme/
    gulp --id 2dFtYP8H76 --templates-path ~/my-inkpad-blog-theme/

