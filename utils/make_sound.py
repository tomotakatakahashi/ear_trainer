'''Note sound MP3 files generator'''
import tempfile
import subprocess
import os

import pretty_midi as pm
from scipy.io.wavfile import write

INSTRUMENT_NAME = 'Acoustic Grand Piano'
NOTE_LENGTH = .25
VELOCITY = 100
PITCH_RANGE = range(24, 96)
SAMPLING_FREQUENCY = 44100
BIT_DEPTH = 32
MP3_BIT_RATE = 32
OUTPUT_DIR = 'mp3'

def main():
    '''Main function'''

    instrument_program = pm.instrument_name_to_program(INSTRUMENT_NAME)
    for pitch in PITCH_RANGE:
        midi = pm.PrettyMIDI()
        inst = pm.Instrument(program=instrument_program)
        note = pm.Note(velocity=VELOCITY, pitch=pitch, start=0, end=NOTE_LENGTH)

        inst.notes.append(note)
        midi.instruments.append(inst)

        with tempfile.NamedTemporaryFile(delete=False) as wav_file:
            wav_filename = wav_file.name
            numpy_type = 'float{}'.format(BIT_DEPTH)
            write(wav_file, SAMPLING_FREQUENCY, midi.fluidsynth().astype(numpy_type))
        subprocess.run(
            [
                'lame',
                '-b{}'.format(MP3_BIT_RATE),
                wav_filename,
                os.path.join(OUTPUT_DIR, '{:02d}.mp3'.format(pitch))
            ],
            check=True
        )

if __name__ == '__main__':
    main()
