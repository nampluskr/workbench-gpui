| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 3 | 222 | 264 |
| tree | 폴더 만들기 ops\newdir | 됨 | 1 | 252 | 270 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 4 | 373 | 390 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 | 3 | 167 | 198 |
| tree | 폴더 지우기 ops\newdir | 됨 | 5 | 172 | 207 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 | 5 | 238 | 269 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 3 | 198 | 217 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 1 | 169 | 371 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 2 | 209 | 233 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 1 | 156 | 181 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 3 | 205 | 371 |
| tab | 열린 파일 지우기 README.md | 됨 | 1 | 311 | 348 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 3 | 270 | 585 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 4 | 245 | 282 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 1076 | 1123 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 | 1 | 254 | 279 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 696 | 718 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 942 | 949 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 4 | 192 | 207 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 2 | 159 | 183 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 3 | 173 | 191 |
| flood | 폴더 만들기 flood | 됨 | 1 | 186 | 213 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 2 | 514 | 541 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 4 | 362 | 408 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 1 | 249 | 269 |
