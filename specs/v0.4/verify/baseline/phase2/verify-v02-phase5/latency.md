| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 5 | 164 | 196 |
| tree | 폴더 만들기 ops\newdir | 됨 | 1 | 180 | 202 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 4 | 278 | 299 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 | 3 | 171 | 217 |
| tree | 폴더 지우기 ops\newdir | 됨 | 5 | 251 | 259 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 | 5 | 186 | 226 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 1 | 175 | 227 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 1 | 213 | 249 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 1 | 262 | 306 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 1 | 219 | 226 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 1 | 211 | 441 |
| tab | 열린 파일 지우기 README.md | 됨 | 1 | 286 | 290 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 1 | 191 | 345 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 5 | 218 | 244 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 858 | 872 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 | 6 | 176 | 194 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 816 | 856 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 769 | 788 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 4 | 180 | 219 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 1 | 249 | 274 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 2 | 170 | 203 |
| flood | 폴더 만들기 flood | 됨 | 2 | 267 | 286 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 2 | 516 | 576 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 8 | 397 | 413 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 1 | 218 | 259 |
