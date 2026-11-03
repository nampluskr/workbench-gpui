| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 3 | 252 | 304 |
| tree | 폴더 만들기 ops\newdir | 됨 | 1 | 238 | 239 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 5 | 297 | 332 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 | 3 | 263 | 314 |
| tree | 폴더 지우기 ops\newdir | 됨 | 6 | 253 | 254 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 | 5 | 169 | 196 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 2 | 261 | 306 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 2 | 155 | 356 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 2 | 224 | 231 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 2 | 157 | 181 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 2 | 290 | 571 |
| tab | 열린 파일 지우기 README.md | 됨 | 1 | 326 | 328 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 2 | 264 | 584 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 4 | 227 | 233 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 885 | 911 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 | 1 | 173 | 207 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 792 | 831 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 840 | 849 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 4 | 282 | 310 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 1 | 245 | 284 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 2 | 256 | 293 |
| flood | 폴더 만들기 flood | 됨 | 2 | 210 | 247 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 2 | 564 | 590 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 5 | 340 | 388 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 1 | 180 | 253 |
