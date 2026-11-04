| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 4 | 258 | 289 |
| tree | 폴더 만들기 ops\newdir | 됨 | 1 | 168 | 198 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 5 | 281 | 314 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 | 4 | 267 | 298 |
| tree | 폴더 지우기 ops\newdir | 됨 | 6 | 256 | 290 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 | 7 | 235 | 310 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 2 | 264 | 290 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 2 | 182 | 391 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 2 | 243 | 278 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 2 | 252 | 276 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 2 | 187 | 412 |
| tab | 열린 파일 지우기 README.md | 됨 | 2 | 301 | 306 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 1 | 195 | 313 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 5 | 230 | 251 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 905 | 954 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 | 1 | 252 | 253 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 728 | 739 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 878 | 888 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 4 | 283 | 308 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 2 | 166 | 191 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 2 | 173 | 198 |
| flood | 폴더 만들기 flood | 됨 | 2 | 262 | 309 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 8 | 537 | 558 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 6 | 359 | 413 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 1 | 252 | 305 |
