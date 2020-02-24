const menu = {
    mt: new MersenneTwister(new Date().getTime()),

    content: `
  <form>
    <div class="form-group form-row">
      <label for="range" class="col-form-label col-2">Range:</label>
      <div class="col-2">
        <select id="range" class="form-control">
          <option value="2">Re</option>
          <option value="3">Mi</option>
          <option value="4" selected>Fa</option>
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
          <option>40</option>
          <option selected>60</option>
          <option>90</option>
        </select>
      </div>
    </div>
    <div class="form-group form-row">
      <label for="length" class="col-form-label col-2">Length:</label>
      <div class="col-2">
        <select id="length" class="form-control">
          <option>10</option>
          <option selected>100</option>
        </select>
      </div>
    </div>
    <div class="form-group form-row">
      <label for="key" class="col-form-label col-2">Key:</label>
      <div class="col-2">
        <select id="key" class="form-control">
          <option value="0">C</option>
          <option value="7">G</option>
          <option value="2">D</option>
      </select>
      </div>
      <div class="col-2">
        <button type="button" class="btn btn-primary col-auto">Shuffle</button>
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
            let next = this.mt.nextInt(range - 1);
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
    render: function() {
        const gameArea = document.getElementById("gameArea");
        gameArea.innerHTML = this.content;

        const startButton = document.getElementById("startButton");
        startButton.onclick =
            () => {
                const gameSettings = this.generateGameSettings();
                play.start(gameSettings);
            };
    }
};
