# Exo Keeper II

Entry for the [KrampusHack 2020](https://tins.amarillion.org/krampu20/) Game Jam. This is a rewrite of an entry for the [Ludum Dare 46](https://ldjam.com/events/ludum-dare/46/exo-keeper). It was rewritten from scratch, from Phaser + JavaScript to [Allegro + D](https://github.com/SiegeLord/DAllegro5).

This game is open source. You may re-use the code according to the terms of the MIT License. See LICENSE.md for details.
Here is the [source code of Allegro version](https://github.com/amarillion/krampus20)
and here is the [source code of original](https://github.com/amarillion/ldjam46/)

During KrampusHack I worked on my own, but the following people's LD46 contributions are still in place:
* Georgii 'Gekaremi' Karelin: Concept and science discusssions.
* Tatiana Kondratieva: Microbe Art.
* Dónall O'Donoghue: Music out of this world.

## How to play

You start with a barren, cold, empty planet. At the start, the planet is completely frozen. The poles of the planet are colder than 217 °K, that's cold enough to make carbon dioxide freeze!

The *goal* of the game is to terraform the planet, and reach a nice temperate average of 298 °K.

You do this by introducing various micro-organisms. Introducing photosynthesising species will release oxygen, making the planet suitable for higher forms of life. Microorganisms will also stain the white snow, lowering the albedo of the planet. A lower albedo means more heat from the sun is retained, thus warming the planet.

Just click on a suitable area, click one of the 12 species buttons, and click "Introduce species". You can click on the "Info" button to get more details on a given species.

Some tips for playing:

* The game looks harder than it is. Just keep at it, you don't have to understand every number on the screen in order to play. 
* Be patient! I've designed the game to be a long-running background game. Just introduce a few species and have a cup of coffee, come back and see what happened.
* A species will indicate (in red) what is ailing it. Just click on an area and look at the details on the right.
* The equator is the hottest, and the poles are coolest.
* If a species complains that there is not enough oxygen, you need to introduce more plant (photosynthesizing) species.
* Plants (producers), Animals (consumers) and Fungi (reducers) are all needed to form a thriving ecosystem.

## KrampusHack 2020

KrampusHack is a secret santa game jam. Every participant made a game for another randomly selected participant. I was the secret santa for Relpatseht, who gave me the following wishlist:

1. Monitor/influence game. I want a game where the world can function without me, and I'm just watching and making influences. Something I can run as a side task forever and devote a little time here or there to to improve. Much closer to ProgressQuest than to StarCraft.

2. Procedural content. I'd like as much as possible to be generated to keep the world always interesting. Infinite worlds are a plus.

3. I want you to implement one of your own wishes.
   (And I picked the following wish from my own list: "I love science, and I love games based on science.")

When I read these rules, I immediately had to think back to Exo Keeper, a game I programmed earlier this year for LD46. Exo Keeper is inspired by [Sid Meier's Sim Earth](https://en.wikipedia.org/wiki/SimEarth), and it has exactly this "gardening" aspect that Relpatseht was asking for.

So here is how I implemented these rules:

Monitor/Influence game: In this game you tend to your planet like a garden, making small adjustments here and there. It's perfectly fine to let the game run for a while and come back to it later. Compared to the original LD46 entry, I've made the game slower. It may take at least 30 minutes to reach a temperate climate.  

Procedural content: the planetscape is generated randomly each time, using a simple "voting rule" to create patches of biotopes. 

Science: the game is a scientific model for albedo, photosynthesis, temperature, respiration. It uses cellular automata as the basis for simulation.

**Happy holidays Relpatseht, and best wishes for 2021!**

## Improvements since the original

I'm not joking when I say the game was completely re-written. It took most of the holidays just to get the game back to a playable state. It wasn't rewriting the simulation code from JavaScript to D, that took only an hour or 2 (And then maybe an extra hour to chase some floating point truncation bugs). There is actually a lot of overlap between JavaScript and D, for example, both can use the 'const' keyword for auto-typed constant variables, so there are whole sections of code that could be transferred unchanged. Actually, most of the effort was in writing a decent GUI system, with buttons, dialogs, and rich text, to replace what the browser environment provides for free. 

Only in the last couple of days of December I was acually able to add a few new features compared to the original. After LD46, a lot of the feedback we got is that the game was hard and confusing. (A typical complaint for my "science" games). So my goal for this remake was to explain the game better. I doubt that I have succeeded to make it completely easy and intuitive, but at least it should be easier now to find out why certain species are growing or not.

Here is what's changed specifically: 
* I styled the right panel to make it easier to find the information you need. 
* Species will now explain what ails them: are they hungry? cold? hot? ...
* The map has little arrow indicators to show which species are growing / decaying.
* Finally, Planetscapes are now procedurally generated.

I had plans for a lot more, but the year ran out on me. Oh well, I'm sure I will come back to it for another *Hack!