#!/usr/bin/env python3
"""회화 음성 시험(MOSS): 참고 음성 → 속도 기준 재기 → 문장 조각 → 받아쓰기 검사·재생성 → mp4·R2(D1 은 넣지 않음) → 리뷰 페이지.
  <venv>/bin/python tools/tts/trial.py <작업폴더> <편id>...   venv = mlx-whisper 가 있는 파이썬. PC 는 한 번에 한 세션 — uk 세션 신호를 받은 뒤 돌린다.
중간에 PC 가 끝나면 'PC 끝' 을 찍는다(uk 에 「GPU 끝」 보낼 시점)."""
import glob, json, os, re, statistics, subprocess, sys, time
import ttslib as L
PC = 'Administrator@100.127.143.37'; HERE = os.path.dirname(os.path.abspath(__file__))
work, eps = sys.argv[1], [x for x in sys.argv[2:] if x != '--qa']
QA_ONLY = '--qa' in sys.argv   # 조각이 이미 있으면 검사·재생성부터
job = f'{work}/job'; wav = f'{work}/wav'; ref = f'{work}/ref'
for d in (job, f'{wav}/retake', ref):
    os.makedirs(d, exist_ok=True)
log = lambda *a: print(time.strftime('%H:%M:%S'), *a, flush=True)


def sh(*a, check=True, **k):
    return subprocess.run(a, check=check, capture_output=True, text=True, **k)


def state():
    return sh('ssh', PC, "(Get-ScheduledTask -TaskName 'TTS job 2060').State", check=False).stdout


def clear():
    for n in ('vox_jobs.json', 'moss_jobs.json'):
        if os.path.exists(f'{job}/{n}'):
            os.remove(f'{job}/{n}')


def pc_run():
    while 'Ready' not in state():
        time.sleep(30)
    for n in ('vox_jobs.json', 'moss_jobs.json'):
        if os.path.exists(f'{job}/{n}'):
            sh('scp', '-q', f'{job}/{n}', f'{PC}:D:/tts_test/job/')
        else:
            sh('ssh', PC, f'Remove-Item D:\\tts_test\\job\\{n} -ErrorAction SilentlyContinue', check=False)
    sh('ssh', PC, "Start-ScheduledTask -TaskName 'TTS job 2060'")
    time.sleep(20)
    while 'Ready' not in state():
        time.sleep(30)


def fetch(path, dst):
    os.makedirs(dst, exist_ok=True)
    sh('scp', '-q', '-r', f'{PC}:D:/tts_test/job/out/{path}', dst + '/', check=False)


def dur(f):
    return float(sh('ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f).stdout or 0)


if not QA_ONLY:
    # 1. 참고 음성
    clear(); sh(sys.executable, f'{HERE}/make_jobs.py', job, '--refs', *eps)
    pc_run(); fetch('ref_hi', ref); log('참고 음성 끝', len(glob.glob(f'{ref}/ref_hi/*.wav')))
    # 2. 힌디어 속도 기준 = 참고 음성 글자/초 중앙값
    rates = []
    for e, x in L.V['emotions'].items():
        n = len(re.sub(r'[^\u0900-\u097F]', '', x['ref']))
        for f in glob.glob(f'{ref}/ref_hi/*_{e}.wav'):
            if dur(f) > 0:
                rates.append(n / dur(f))
    if rates:
        L.V['rate'] = round(statistics.median(rates), 1)
        json.dump(L.V, open(f'{L.R}/data/tts/voices.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        log('참고 음성 속도 중앙값', L.V['rate'], '글자/초')
    # 3. 문장 조각
    clear(); log(sh(sys.executable, f'{HERE}/make_jobs.py', job, *eps).stdout.strip())
    pc_run(); log('생성 끝')
    for e in eps:
        fetch(f'hi/{e}', wav)
# 4. 검사·재생성(세 번까지)
for rnd in range(3):
    jobs = []
    for e in eps:
        q = f'{job}/qa_{e}.json'
        try:
            r = subprocess.run([sys.executable, f'{HERE}/qa.py', wav, e, '--jobs', q], capture_output=True, text=True, timeout=600)
            log(e, r.stdout.strip() or r.stderr.strip()[-300:])
        except subprocess.TimeoutExpired:
            log('TIMEOUT', e); continue
        if os.path.exists(q):
            jobs += json.load(open(q, encoding='utf-8')); os.remove(q)
    if not jobs:
        break
    clear(); json.dump(jobs, open(f'{job}/moss_jobs.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    pc_run()
    for e in eps:
        fetch(f'hi/retake/{e}', f'{wav}/retake')
log('PC 끝')
for e in eps:   # 마지막 재생성본 반영
    subprocess.run([sys.executable, f'{HERE}/qa.py', wav, e], capture_output=True, text=True, timeout=600)
