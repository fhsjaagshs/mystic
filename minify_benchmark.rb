#!/usr/bin/env ruby

require "mystic/minify"

def bench_minify(string)
  start_time = Time.now
  minified = string.minify
  end_time = Time.now
  return (end_time.to_f - start_time.to_f)/string.length
end

string = "This is a string to    minify  \"This is a    \t quoted string\"   and this is some       more text to minify"

css = "/* -------------------------------------------------------------
      CSS3, Please! The Cross-Browser CSS3 Rule Generator
      ===================================================

      You can edit the underlined values in this css file,
      but don't worry about making sure the corresponding
      values match, that's all done automagically for you.

      Whenever you want, you can copy the whole or part of
      this page and paste it into your own stylesheet.
------------------------------------------------------------- */

 /*                           [to clipboard] [toggle rule off] */
.box_round {
  -webkit-border-radius: 12px; /* Android ≤ 1.6, iOS 1-3.2, Safari 3-4 */
          border-radius: 12px; /* Android 2.1+, Chrome, Firefox 4+, IE 9+, iOS 4+, Opera 10.50+, Safari 5+ */

  /* useful if you don't want a bg color from leaking outside the border: */
  background-clip: padding-box; /* Android 2.2+, Chrome, Firefox 4+, IE 9+, iOS 4+, Opera 10.50+, Safari 4+ */
}
/*                           [to clipboard] [toggle inset on] [toggle rule off] */
.box_shadow {
  -webkit-box-shadow: 0px 0px 4px 0px #ffffff; /* Android 2.3+, iOS 4.0.2-4.2, Safari 3-4 */
          box-shadow: 0px 0px 4px 0px #ffffff; /* Chrome 6+, Firefox 4+, IE 9+, iOS 5+, Opera 10.50+ */
}
/*                           [to clipboard] [toggle rule off] */
.box_gradient {
  background-color: #444444;
  background-image: -webkit-gradient(linear, left top, left bottom, from(#444444), to(#999999)); /* Chrome, Safari 4+ */
  background-image: -webkit-linear-gradient(top, #444444, #999999); /* Chrome 10-25, iOS 5+, Safari 5.1+ */
  background-image:    -moz-linear-gradient(top, #444444, #999999); /* Firefox 3.6-15 */
  background-image:      -o-linear-gradient(top, #444444, #999999); /* Opera 11.10-12.00 */
  background-image:         linear-gradient(to bottom, #444444, #999999); /* Chrome 26, Firefox 16+, IE 10+, Opera 12.10+ */
}
/*                           [to clipboard] [toggle rule on] 
.box_rgba {
  background-color: transparent;
  background-color: rgba(180, 180, 144, 0.6);  /* Chrome, Firefox 3+, IE 9+, Opera 10.10+, Safari 3+ 
}
/* */
/*                           [to clipboard] [toggle rule on] 
.box_rotate {
  -webkit-transform: rotate(7.5deg);  /* Chrome, Safari 3.1+ 
     -moz-transform: rotate(7.5deg);  /* Firefox 3.5-15 
      -ms-transform: rotate(7.5deg);  /* IE 9 
       -o-transform: rotate(7.5deg);  /* Opera 10.50-12.00 
          transform: rotate(7.5deg);  /* Firefox 16+, IE 10+, Opera 12.10+ 
}
/* */
/*                           [to clipboard] [toggle rule on] 
.box_scale {
  -webkit-transform: scale(0.8);  /* Chrome, Safari 3.1+ 
     -moz-transform: scale(0.8);  /* Firefox 3.5+ 
      -ms-transform: scale(0.8);  /* IE 9 
       -o-transform: scale(0.8);  /* Opera 10.50-12.00 
          transform: scale(0.8);  /* Firefox 16+, IE 10+, Opera 12.10+ 
}
/* */
/*                           [to clipboard] [toggle rule on] 
.box_3dtransforms {
  -webkit-perspective: 300px;  /* Chrome 12+, Safari 4+ 
     -moz-perspective: 300px;  /* Firefox 10+ 
      -ms-perspective: 300px;  /* IE 10 
          perspective: 300px;
  -webkit-transform: rotateY(180deg);  -webkit-transform-style: preserve-3d;
     -moz-transform: rotateY(180deg);     -moz-transform-style: preserve-3d;
      -ms-transform: rotateY(180deg);      -ms-transform-style: preserve-3d;
          transform: rotateY(180deg);          transform-style: preserve-3d;
}
/* */
/*                           [to clipboard] [toggle rule off] */
.box_transition {
  -webkit-transition: all 0.3s ease-out;  /* Chrome 1-25, Safari 3.2+ */
     -moz-transition: all 0.3s ease-out;  /* Firefox 4-15 */
       -o-transition: all 0.3s ease-out;  /* Opera 10.50–12.00 */
          transition: all 0.3s ease-out;  /* Chrome 26, Firefox 16+, IE 10+, Opera 12.10+ */
}
/*                           [to clipboard] [toggle rule off] */
.box_textshadow {
  text-shadow: 1px 1px 3px #888; /* Chrome, Firefox 3.5+, IE 10+, Opera 9+, Safari 1+ */
}
/*                           [to clipboard] [toggle rule off] */
.box_opacity {
  opacity: 0.9; /* Android 2.1+, Chrome 4+, Firefox 2+, IE 9+, iOS 3.2+, Opera 9+, Safari 3.1+ */
}
/*                           [to clipboard] */
* {
  -webkit-box-sizing: border-box; /* Android ≤ 2.3, iOS ≤ 4 */
     -moz-box-sizing: border-box; /* Firefox 1+ */
          box-sizing: border-box; /* Chrome, IE 8+, Opera, Safari 5.1 */
}
/*                           [to clipboard] [toggle rule off] */
.box_bgsize {
  -webkit-background-size: 100% 100%; /* Safari 3-4 */
          background-size: 100% 100%; /* Chrome, Firefox 4+, IE 9+, Opera, Safari 5+ */
}
/*                           [to clipboard] [toggle rule on] 
.box_columns {
  -webkit-column-count: 2;  -webkit-column-gap: 15px; /* Chrome, Safari 3 
     -moz-column-count: 2;     -moz-column-gap: 15px; /* Firefox 3.5+ 
          column-count: 2;          column-gap: 15px; /* Opera 11+ 
}
/* */
/*                           [to clipboard] [toggle rule off] */
.box_animation:hover {
  -webkit-animation: myanim 5s infinite; /* Chrome, Safari 5+ */
     -moz-animation: myanim 5s infinite; /* Firefox 5-15 */
       -o-animation: myanim 5s infinite; /* Opera 12.00 */
          animation: myanim 5s infinite; /* Chrome, Firefox 16+, IE 10+, Opera 12.10+ */
}

@-webkit-keyframes myanim {
  0%   { opacity: 0.0; }
  50%  { opacity: 0.5; }
  100% { opacity: 1.0; }
}
@-moz-keyframes myanim {
  0%   { opacity: 0.0; }
  50%  { opacity: 0.5; }
  100% { opacity: 1.0; }
}
@-o-keyframes myanim {
  0%   { opacity: 0.0; }
  50%  { opacity: 0.5; }
  100% { opacity: 1.0; }
}
@keyframes myanim {
  0%   { opacity: 0.0; }
  50%  { opacity: 0.5; }
  100% { opacity: 1.0; }
}
 /*                           [to clipboard] [toggle rule off] */
Oh hai :)

From Peter Nederlof oh noes! Manipulate me, please! rotate scale skew skew move .matrix {
  
Play for output ...

}
/*                           [to clipboard] */ 
@font-face {
  font-family: 'WebFont';
  src: url('myfont.woff') format('woff'), /* Chrome 6+, Firefox 3.6+, IE 9+, Safari 5.1+ */
       url('myfont.ttf') format('truetype'); /* Chrome 4+, Firefox 3.5, Opera 10+, Safari 3—5 */
}
/*                           [to clipboard] [toggle rule off] */
.box_tabsize {
  -moz-tab-size: 2; /* Firefox 4+ */
    -o-tab-size: 2; /* Opera 10.60+ */
       tab-size: 2;
}"

puts "CSS: #{bench_minify(css)} seconds/character"
puts "String: #{bench_minify(string)} seconds/character"