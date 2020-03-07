const menu = {
    content: `
  <form>
    <div class="form-group form-row">
      <label for="range" class="col-form-label col-2">Range:</label>
      <div class="col-2">
        <select id="range" class="form-control">
          <option value="2">Re</option>
          <option value="3" selected>Mi</option>
          <option value="4">Fa</option>
          <option value="5">Sol</option>
          <option value="6">La</option>
          <option value="7">Ti</option>
        </select>
      </div>
    </div>
    <div class="form-group form-row">
      <label for="tempo" class="col-form-label col-2">Tempo:</label>
      <div class="col-2">
        <select id="tempo" class="form-control">
          <option selected>40</option>
          <option>60</option>
          <option>90</option>
        </select>
      </div>
    </div>
    <div class="form-group form-row">
      <label for="length" class="col-form-label col-2">Length:</label>
      <div class="col-2">
        <select id="length" class="form-control">
          <option>10</option>
          <option selected>40</option>
          <option>60</option>
          <option>100</option>
        </select>
      </div>
    </div>
    <div class="form-group form-row">
      <label for="key" class="col-form-label col-2">Key:</label>
      <div class="col-2">
        <select id="key" class="form-control">
          <option value="0">C</option>
          <option value="1">Db</option>
          <option value="2">D</option>
          <option value="3">Eb</option>
          <option value="4">E</option>
          <option value="5">F</option>
          <option value="6">Gb</option>
          <option value="7">G</option>
          <option value="8">Ab</option>
          <option value="9">A</option>
          <option value="10">Bb</option>
          <option value="11">B</option>
      </select>
      </div>
      <div class="col-2">
        <button id="shuffleButton" type="button" class="btn btn-primary col-auto">Shuffle</button>
        </div>
    </div>
    <div class="form-group form-row">
      <div class="col-2">
        <button id="startButton" type="button" class="btn btn-primary">Start</button>
      </div>
    </div>
  </form>
`,

    rootRange: [48, 72],
    majorScale: {
        pitch: [0, 2, 4, 5, 7, 9, 11],
        name: ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Ti']
    },
    findRoot: function(key){
        for(i = this.rootRange[0]; i < this.rootRange[1]; i++){
            if(i % 12 == key % 12){
                return i;
            }
        }
    },
    generateSequence: function(range, length){
        const ret = [0];
        let prev = 0;
        while(ret.length < length){
            let next = Math.floor(Math.random() * (range - 1));
            if(next >= prev){
                next++;
            }
            ret.push(next);
            prev = next;
        }
        return ret;
    },
    generateGameSettings: function(){
        const key = parseInt(document.getElementById('key').value);
        const rootNote = this.findRoot(key);
        const range = parseInt(document.getElementById('range').value);
        const length = parseInt(document.getElementById('length').value);
        const tempo = parseInt(document.getElementById('tempo').value);
        const gameSettings = {
            range: range,
            scale: this.majorScale,
            tempo: tempo,
            key: key,
            length: length,
            rootNote: rootNote,
            playSeq: this.generateSequence(range, length)
        }
        return gameSettings;
    },
    getDefaultSettings: function(){
        const storageData = window.localStorage.getItem('earTrainer');
        if(storageData == null){
            return null;
        }

        return JSON.parse(storageData).defaultSettings;
    },
    setDefaultSettings: function(gameSettings){
        const storageDataStr = window.localStorage.getItem('earTrainer');
        let storageData = {}
        if(storageDataStr != null){
            storageData = JSON.parse(storageDataStr);
        }
        storageData.defaultSettings = gameSettings;

        window.localStorage.setItem('earTrainer', JSON.stringify(storageData));
    },
    render: function() {
        const gameArea = document.getElementById("gameArea");
        gameArea.innerHTML = this.content;

        const defaultSettings = this.getDefaultSettings();
        if(defaultSettings != null){
            document.getElementById('range').value = defaultSettings.range;
            document.getElementById('tempo').value = defaultSettings.tempo;
            document.getElementById('length').value = defaultSettings.length;
            document.getElementById('key').value = defaultSettings.key;
        }

        const startButton = document.getElementById("startButton");
        startButton.onclick =
            () => {
                const gameSettings = this.generateGameSettings();
                this.setDefaultSettings(gameSettings);
                play.start(gameSettings);
            };

        const shuffleButton = document.getElementById('shuffleButton');
        shuffleButton.onclick = function(){
            const keySelect = document.getElementById('key');
            keySelect.selectedIndex = Math.floor(Math.random() * keySelect.length);
        }
    }
};
