# CrunchySub

## The worst thing since mouldy bread

### Now with added cludgeiness and horror

I like Crunchyroll, but sometimes fan-subs are better.
Thus, this bash script abomination was born - it downloads shows off of Crunchyroll (using youtube-dl and ffmpeg to mux into mkv) then scrapes fan-subs from [kitsunekko.net](http://kitsunekko.net), before mashing them together (using mkvmerge) with what will hopefully be the correct episodes (it asks with Zenity, unless you tell it not to).

By the way, you'd better become used to setting subtitle delay when you choose fan subs (specifically, when there's a 'Funimation' into or similar). Sorry, just how it's going to be.

## Requirements

You'll need [awk-csv-parser](https://github.com/geoffroy-aubry/awk-csv-parser).

## Not To Be Confused With

[CrunchySubs](https://github.com/7ouma/CrunchySubs)  
The [CrunchySubs](https://anidb.net/perl-bin/animedb.pl?show=group&gid=8811) release group.
