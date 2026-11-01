| 사례 | 바깥 변경 | 반영 | recv_ms | app_ms | seen_ms |
| --- | --- | --- | ---: | ---: | ---: |
| tree | 파일 만들기 ops\new-ext.txt | 됨 | 5 | 163 | 194 |
| tree | 폴더 만들기 ops\newdir | 됨 |  | 254 | 263 |
| tree | 파일 지우기 ops\f3.txt | 됨 |  | 167 | 177 |
| tree | 파일 이름 바꾸기 ops\f1.txt → f1-renamed.txt | 됨 |  | 167 | 214 |
| tree | 폴더 지우기 ops\newdir | 됨 | 10 | 250 | 303 |
| tree | 펼친 폴더 이름 바꾸기 ops\sub → sub2 | 됨 |  | 234 | 301 |
| tree | 접힌 폴더 안 파일 만들기 src\added.rs | 됨 | 3 | 246 | 286 |
| tab | 활성 탭 파일 내용 바꾸기 README.md | 됨 | 3 | 180 | 339 |
| tab | 활성이 아닌 탭 파일 내용 바꾸기 notes.txt | 됨 | 3 | 240 | 280 |
| tab | 같은 내용으로 다시 쓰기 README.md | 됨 | 3 | 267 | 296 |
| tab | 임시 파일에 쓰고 바꿔 넣기 README.md | 됨 | 6 | 288 | 486 |
| tab | 열린 파일 지우기 README.md | 됨 | 14 | 249 | 290 |
| tab | 지운 파일 다시 만들기 README.md | 됨 | 3 | 158 | 307 |
| root | 활성 등록 폴더 이름 바꾸기 proj → proj-gone | 됨 | 4 | 226 | 276 |
| root | 이름 되돌리기 proj-gone → proj | 됨 |  | 977 | 1023 |
| root | 되돌린 뒤 바깥 파일 만들기 back.txt | 됨 |  | 163 | 205 |
| root | 활성이 아닌 등록 폴더 지우기 proj2 | 됨 |  | 147 | 184 |
| root | 활성이 아닌 등록 폴더 다시 만들기 proj2 | 됨 |  | 819 | 857 |
| root | 활성 등록 폴더 지우기 proj | 됨 | 12 | 603 | 653 |
