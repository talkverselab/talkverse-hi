# -*- coding: utf-8 -*-
"""회화 장면 컷(A·B 한 쌍 = 1컷, 글자·말풍선 없음)을 Grok(PC 크롬 9246, 「빠른」)에 편마다 4컷씩 한 번에 요청한다(2026-11-22).
일본어앱 tools/grok_scene_batch.py 를 힌디어·PC 크롬용으로 옮김. 받은 그림은 3:2 로 잘라 1168×784 jpg →
~/talkverse/hi-art/talkverse_art/scene/hi/<편id>/cut<N>.jpg (그림 저장소 sparse 클론). 이미 있는 컷은 건너뛴다.
  GROK_CDP_PORT=9246 python3 tools/grok_scene.py <편id> ... [--chat <방 주소>]
한 방에서 이어 쓴다(통일성). 마지막 줄 `CHAT <주소>`. 한도면 종료 코드 3.
"""
import base64, glob, json, os, re, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grok_cdp as G
import grok_text as T

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.expanduser('~/talkverse/hi-art/talkverse_art/scene/hi')
SHEET = os.path.join(ROOT, 'data/review/art/chars_hi_v1.jpg')
TONE = os.path.join(ROOT, 'data/review/uxui/sian_hi_01.jpg')
CAST = {'प्रिया': '시트 1번 프리야(허리까지 오는 검은 땋은 머리, 머스터드 짧은 쿠르타, 남색 두파타)',
        'अनन्या': '시트 2번 아난야(어깨 길이 웨이브 흑발, 둥근 안경, 코 피어싱, 올리브 셔츠)',
        'रोहन': '시트 3번 로한(짧은 곱슬머리, 옅은 수염, 하늘색 저지)',
        'अर्जुन': '시트 4번 아르준(키 큼, 옆가르마 웨이브 머리, 짧은 수염, 흰 짧은 쿠르타)',
        '{name}': '시트 5번 남자 학습자(자홍색 후드티, 갈색 백팩 — 국적 중립적인 얼굴)'}


def who(n):
    return CAST.get(n, f'{n}(시트에 없는 조연 — 역할에 맞는 차림의 인도 사람, 같은 점토 톤, 실존 인물 닮지 않게)')


def prompt(ep, cuts):
    lines = [f'컷{n}: ' + ' / '.join(f"{t['speaker']}「{t['tl']}」({t['ko']})" for t in pair) for n, pair in cuts]
    cast = ', '.join(f'{k} = {who(v)}' for k, v in ep['speakers'].items())
    return (f"[SC-{ep['id']}] **이미지 {len(cuts)}장을 생성해 주세요**(글 설명 없이 그림만, 컷마다 한 장씩 따로 {len(cuts)}장). 힌디어 학습 앱 회화의 장면 컷입니다.\n"
            "첨부 1 = 우리 앱 인물 기준 그림(이 인물들의 얼굴·머리·옷을 그대로), 첨부 2 = 그림 톤 참고.\n"
            "톤: 부드러운 펠트·점토 인형, 파스텔·크림 배경, 둥근 얼굴, 따뜻한 조명, 인도(델리)의 실제 장소 느낌. 3:2 가로. "
            "**그림 안에 글자·말풍선·간판 글씨·로고 없음**. 실존 인물·브랜드 금지.\n"
            f"장면: {ep['scene']}\n등장: {cast}\n"
            "각 컷은 아래 두 대사가 오가는 순간의 표정·동작·장소를 한 장으로(대사는 그리지 말고 상황만):\n" + '\n'.join(lines) +
            f"\n지금 바로 이미지 {len(cuts)}장을 생성하세요.")


IMGS = "[...document.querySelectorAll('img')].filter(i=>i.src.includes('assets.grok.com')&&i.naturalWidth>=300).map(i=>i.src)"
BUSY = ("!![...document.querySelectorAll('button')].find(e=>/응답 중지|Stop/.test(e.getAttribute('aria-label')||''))"
        "||[...document.querySelectorAll('img')].some(i=>i.src.startsWith('data:image')&&i.naturalWidth>200)")


def fetch(c, url):
    d = c.ev("fetch(%s,{credentials:'include'}).then(r=>r.blob()).then(b=>new Promise(ok=>{const f=new FileReader();f.onload=()=>ok(f.result);f.readAsDataURL(b)}))" % json.dumps(url))
    return base64.b64decode(d.split(',', 1)[1]) if isinstance(d, str) and d.startswith('data:') else None


def fit(src, dst):
    def dim(k):
        return int(subprocess.run(['sips', '-g', k, src], capture_output=True, text=True).stdout.split()[-1])
    w, h = dim('pixelWidth'), dim('pixelHeight')
    cw, ch = (int(h * 1.5), h) if w / h > 1.5 else (w, int(w / 1.5))
    subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '88', '--cropToHeightWidth', str(ch), str(cw), src, '--out', dst], capture_output=True)
    subprocess.run(['sips', '-z', '784', '1168', dst], capture_output=True)


def one(ep, chat):
    turns = ep['turns']
    cuts = [((i // 2) + 1, turns[i:i + 2]) for i in range(0, len(turns), 2)]
    out = os.path.join(ART, ep['id']); os.makedirs(out, exist_ok=True)
    miss = [x for x in cuts if not os.path.exists(os.path.join(out, f'cut{x[0]}.jpg'))]
    for k in range(0, len(miss), 4):
        chunk = miss[k:k + 4]
        subprocess.run(['ssh', 'pc', 'cmd /c if not exist D:\\grok_att\\hi mkdir D:\\grok_att\\hi'], capture_output=True)
        remote = []
        for p in (SHEET, TONE):
            subprocess.run(['scp', '-q', p, 'pc:' + T.PC_ATT], check=True)
            remote.append((T.PC_ATT + os.path.basename(p)).replace('/', '\\'))
        url = chat or 'https://grok.com/'
        t = T.new_tab(url)
        try:
            c = G.CDP(t); c.call('Page.bringToFront')
            for _ in range(40):
                if c.ev("!!(%s)" % G.FIND): break
                time.sleep(1)
            time.sleep(4)
            doc = c.call('DOM.getDocument', depth=-1, pierce=True)
            node = c.call('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='input[type=file]')
            if not node.get('nodeId'): sys.exit('파일 입력 없음')
            c.call('DOM.setFileInputFiles', nodeId=node['nodeId'], files=remote); time.sleep(8)
            before = set(c.ev(IMGS) or [])
            lim0 = c.ev("(document.body.innerText.match(/한도에 도달|limit reached/g)||[]).length") or 0
            c.ev("(()=>{const e=%s;e.focus();return 1})()" % G.FIND)
            c.call('Input.insertText', text=prompt(ep, chunk)); time.sleep(1)
            for typ in ('keyDown', 'keyUp'):
                c.call('Input.dispatchKeyEvent', type=typ, key='Enter', code='Enter', windowsVirtualKeyCode=13, nativeVirtualKeyCode=13)
            time.sleep(10)
            new, idle = [], 0
            for _ in range(60):  # 최대 15분
                if (c.ev("(document.body.innerText.match(/한도에 도달|limit reached/g)||[]).length") or 0) > lim0:
                    print('LIMIT', ep['id'], flush=True); sys.exit(3)
                cur = []
                for s in c.ev(IMGS) or []:
                    if s not in before and s not in cur: cur.append(s)
                busy = c.ev(BUSY)
                new = cur
                if len(new) >= len(chunk) and not busy: break
                idle = idle + 1 if (not busy and not new) else 0
                if idle >= 6: break
                time.sleep(15)
            chat = c.ev('location.href') or chat
            print(ep['id'], 'imgs', len(new), flush=True)
            if len(new) < len(chunk):
                print('FAIL', ep['id'], '그림 수 부족', len(new), 'CHAT', chat, flush=True); return False, chat
            for (n, _), u in zip(chunk, new[:len(chunk)]):
                b = fetch(c, u)
                if not b: print('FAIL 받기', u[:80], flush=True); return False, chat
                tmp = os.path.join(out, f'.raw{n}'); open(tmp, 'wb').write(b)
                fit(tmp, os.path.join(out, f'cut{n}.jpg')); os.remove(tmp)
            print('OK', ep['id'], [n for n, _ in chunk], flush=True)
        finally:
            T.close_tab(t)
    return True, chat


def main():
    a = sys.argv[1:]
    chat = a[a.index('--chat') + 1] if '--chat' in a else ''
    ids = [x for x in a if not x.startswith('--') and x != chat]
    done = []
    for i in ids:
        p = glob.glob(os.path.join(ROOT, f'assets/data/dialogues/R*/*/{i}.json'))
        if not p: print('편 없음', i); continue
        ep = json.load(open(p[0], encoding='utf-8'))
        ok, chat = one(ep, chat)
        if not ok:
            ok, chat = one(ep, chat)  # 같은 방에서 한 번 더
        if ok: done.append(i)
    print('DONE', len(done), '/', len(ids), flush=True)
    print('CHAT', chat, flush=True)


if __name__ == '__main__':
    main()
