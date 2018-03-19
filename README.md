# CrunchySub

## The worst thing since mouldy bread

### Now with added cludgeiness and horror

I like Crunchyroll, but sometimes fan-subs are better.
Thus, this bash script abomination was born - it downloads shows off of Crunchyroll (using youtube-dl and ffmpeg to mux into mkv) then scrapes fan-subs from kitsunekko.net, before mashing them together (using mkvmerge) with what will hopefully be the correct episodes (it asks with Zenity, unless you tell it not to).

## Requirements

You'll need [awk-csv-parser](https://github.com/geoffroy-aubry/awk-csv-parser).
