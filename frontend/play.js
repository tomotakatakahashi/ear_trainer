const play = {
    playIdx: -1,
    audioData: {},
    gameSettings: {},
    userSeq: [],
    userPlayButtons: [],
    buttonOnClick: function(idx){
        this.userSeq[this.playIdx] = idx;
        for(let i = 0; i < this.userPlayButtons.length; i++){
            this.userPlayButtons[i].className = 'btn btn-secondary btn-block';
        }

        if(this.gameSettings.playSeq[this.playIdx] == idx){
            this.userPlayButtons[idx].className = 'btn btn-success btn-block';
        }else{
            this.userPlayButtons[idx].className = 'btn btn-danger btn-block';
            this.userPlayButtons[this.gameSettings.playSeq[this.playIdx]].className = 'btn btn-info btn-block';
        }
    },

    renderUI: function(gameSettings, audioData){
        const gameArea = document.getElementById('gameArea');
        gameArea.innerHTML = '';

        document.addEventListener(
            'keydown',
            (event) => {
                const keys = ['a', 's', 'd', 'f', 'j', 'k', 'l'];
                const keyName = event.key;
                for(let i = 0; i < this.gameSettings.range; i++){
                    if(keyName == keys[i]){
                        this.buttonOnClick(i);
                    }
                }
            }
        );

        const userPlayButtons = [];
        const userPlayButtonRow = document.createElement('div');
        userPlayButtonRow.className = 'row';
        gameArea.appendChild(userPlayButtonRow);
        for(let i = 0; i < this.gameSettings.range; i++){
            const userPlayButtonCol = document.createElement('div');
            userPlayButtonCol.className = 'col text-center';
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'btn btn-primary btn-block';
            button.innerText = this.gameSettings.scale.name[i];
            button.onclick =
                () => this.buttonOnClick(i);

            userPlayButtons.push(button);

            userPlayButtonCol.appendChild(button);
            userPlayButtonRow.appendChild(userPlayButtonCol);
        }
        this.userPlayButtons = userPlayButtons;
    },
    playAndResult: function(){
        this.renderUI();

        const MS_PER_SEC = 1000;
        const SEC_PER_MIN = 60;
        const interval = MS_PER_SEC / (this.gameSettings.tempo / SEC_PER_MIN);
        this.userSeq = new Array(this.gameSettings.length).fill(-1);
        
        this.playIdx = -1;
        const timerId = setInterval(
            () => {
                this.playIdx++;
                if(this.playIdx >= this.gameSettings.playSeq.length){
                    clearInterval(timerId);
                    result.render({
                        gameSettings: this.gameSettings,
                        playResult: {
                            userSeq: this.userSeq,
                            endDate: new Date()
                        }
                    });
                }else{
                    this.audioData[this.gameSettings.playSeq[this.playIdx]].seek(0);
                    this.audioData[this.gameSettings.playSeq[this.playIdx]].play();
                    for(let i = 0; i < this.userPlayButtons.length; i++){
                        this.userPlayButtons[i].disabled = false;
                        this.userPlayButtons[i].className = 'btn btn-primary btn-block';
                    }
                }
            },
            interval
        );
    },
    loadAndPlay: function(){
        document.getElementById('gameArea').innerHTML = "Loading...";
        this.audioData = this.gameSettings.scale.pitch.
              map(x => this.gameSettings.rootNote + x).
              map(x => new Howl({src: `mp3/${x}.mp3`}));

        const timerId = setInterval(
            () => {
                if(this.audioData.every(x => x.state() == 'loaded')){
                    clearInterval(timerId);
                    this.playAndResult();
                }
            },
            100
        );
    },
    
    start: function(gameSettings){
        this.gameSettings = gameSettings;
        this.loadAndPlay();
    },
};
