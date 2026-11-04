| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 3 | 265 | 278 |
| tree | 폴더 만들기 ops\newdir | 됨 | 1 | 185 | 242 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 3 | 266 | 302 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 | 3 | 267 | 282 |
| tree | 폴더 지우기 ops\newdir | 됨 | 5 | 166 | 198 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 | 5 | 265 | 279 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 2 | 225 | 242 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 1 | 218 | 394 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 1 | 211 | 234 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 1 | 161 | 185 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 2 | 271 | 312 |
| tab | 열린 파일 지우기 README.md | 됨 | 1 | 386 | 387 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 2 | 162 | 244 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 6 | 258 | 282 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 1023 | 1054 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 | 1 | 169 | 188 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 828 | 835 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 875 | 913 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 4 | 278 | 289 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 1 | 232 | 258 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 2 | 199 | 230 |
| flood | 폴더 만들기 flood | 됨 | 1 | 181 | 208 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 2 | 587 | 618 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 5 | 418 | 423 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 2 | 216 | 247 |
