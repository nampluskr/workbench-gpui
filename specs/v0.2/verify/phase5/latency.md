| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 7 | 204 | 243 |
| tree | 폴더 만들기 ops\newdir | 됨 | 5 | 182 | 217 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 34 | 290 | 311 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 |  | 173 | 1203 |
| tree | 폴더 지우기 ops\newdir | 됨 | 8 | 229 | 244 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 |  | 1118 | 1209 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 2 | 1044 | 1126 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 3 | 258 | 1278 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 2 | 239 | 297 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 2 | 218 | 231 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 5 | 274 | 1085 |
| tab | 열린 파일 지우기 README.md | 됨 | 10 | 168 | 224 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 3 | 253 | 1249 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 4 | 176 | 665 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 54 | 128 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 | 4 | 697 | 745 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 136 | 180 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 293 | 339 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 5 | 632 | 692 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 3 | 222 | 252 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 6 | 254 | 290 |
| flood | 폴더 만들기 flood | 됨 | 4 | 928 | 934 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 5 | 7366 | 7394 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 7 | 2737 | 2775 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 3 | 339 | 380 |
