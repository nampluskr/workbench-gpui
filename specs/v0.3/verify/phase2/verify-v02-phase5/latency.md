| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 4 | 247 | 248 |
| tree | 폴더 만들기 ops\newdir | 됨 | 1 | 189 | 220 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 4 | 275 | 289 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 | 3 | 173 | 199 |
| tree | 폴더 지우기 ops\newdir | 됨 | 5 | 177 | 200 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 | 6 | 271 | 314 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 2 | 180 | 241 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 2 | 160 | 370 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 2 | 268 | 293 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 1 | 250 | 261 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 4 | 281 | 347 |
| tab | 열린 파일 지우기 README.md | 됨 | 1 | 301 | 333 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 2 | 267 | 289 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 5 | 189 | 212 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 901 | 915 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 | 1 | 187 | 219 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 808 | 844 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 901 | 943 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 4 | 272 | 315 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 1 | 172 | 216 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 2 | 218 | 256 |
| flood | 폴더 만들기 flood | 됨 | 1 | 228 | 241 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 3 | 551 | 584 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 6 | 412 | 459 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 1 | 215 | 253 |
