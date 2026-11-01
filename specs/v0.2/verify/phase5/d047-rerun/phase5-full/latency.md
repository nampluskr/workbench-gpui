| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 6 | 161 | 171 |
| tree | 폴더 만들기 ops\newdir | 됨 | 11 | 170 | 204 |
| tree | 파일 지우기 ops\f3.txt | 됨 | 12 | 231 | 244 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 | 7 | 212 | 275 |
| tree | 폴더 지우기 ops\newdir | 됨 | 11 | 257 | 314 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 |  | 1201 | 1282 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 3 | 1060 | 1138 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 3 | 246 | 1048 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 3 | 218 | 247 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 2 | 234 | 272 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 5 | 296 | 1101 |
| tab | 열린 파일 지우기 README.md | 됨 | 7 | 262 | 304 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 2 | 278 | 1233 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 4 | 179 | 223 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 965 | 1053 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 |  | 810 | 861 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 165 | 206 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 639 | 693 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 8 | 594 | 643 |
| switch | pb 안 파일 만들기 b2.txt | 됨 | 3 | 157 | 196 |
| own | 앱 작업 직후 바깥 파일 만들기 after-own.txt | 됨 | 4 | 241 | 283 |
| flood | 폴더 만들기 flood | 됨 | 4 | 157 | 195 |
| flood | 파일 600 개 한꺼번에 만들기 | 됨 | 5 | 7722 | 7783 |
| flood | 파일 600 개 한꺼번에 지우기 | 됨 | 6 | 2772 | 2809 |
| junction | 정션 대상 경로로 파일 만들기 jtarget\via-target.txt | 안 됨 |  |  |  |
| junction | 정션 경로로 파일 만들기 jlink\via-link.txt | 안 됨 |  |  |  |
| junction | 루트 안 다른 파일 만들기 poke.txt | 됨 | 3 | 258 | 334 |
