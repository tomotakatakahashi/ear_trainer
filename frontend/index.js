const majorScale = [0, 2, 4, 5, 7, 9, 11];

const rootNote = 60; // C4
const bpm = 60;

function playSequence(sequence, interval){
    const audioElements = sequence.map(
        x => new Audio(`mp3/${x}.mp3`)
    );
    idx = 0;
    const startPlaying = function(){
        const timerId = setInterval(() => {
            if(idx >= sequence.length){
                clearInterval(timerId);
            }else{
                const audioPath = `mp3/${sequence[idx]}.mp3`;
                const audioElement = new Audio(audioPath);
                audioElement.play();
                idx++;
            }
        }, interval);
    };

    audioElements.forEach(
        audioElement => {
            audioElement.oncanplaythrough = function () {
                const HAVE_ENOUGH_DATA = 4
                if(audioElements.every(x => x.readyState >= HAVE_ENOUGH_DATA)){
                    startPlaying();
                }
            }
        }
    );
}

document.getElementById('playButton').onclick = function(){
    const scaleNotes = majorScale.map(x => x + rootNote);
    const MS_PER_SEC = 1000;
    const SEC_PER_MIN = 60;
    const interval = MS_PER_SEC / (bpm / SEC_PER_MIN);
    playSequence(scaleNotes, interval);
};
