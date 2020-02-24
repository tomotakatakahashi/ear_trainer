const majorScale = [0, 2, 4, 5, 7, 9, 11];

const rootNote = 60; // C4
const bpm = 60;
const noteRange = 4;
const seqLength = 100;

const mt = new MersenneTwister(new Date().getTime());

function init(){
    menu.render();
}

init();
