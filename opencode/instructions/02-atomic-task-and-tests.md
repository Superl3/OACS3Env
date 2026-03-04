---
# Atomic Task + Tests Policy

## Atomic Task 정의
Atomic task란:
- “하나의 원인 → 하나의 결과”로 닫히는 최소 변경 단위
- 되돌리기 쉬움
- 검증(테스트/빌드/런)까지 포함했을 때 끝남

## 실행 순서(반드시)
1) TaskManager로 atomic task 정의
2) (필요 시) ContextScout로 관련 파일/패턴 확인
3) 구현(최소 변경)
4) 테스트/빌드/타입체크 실행
5) 실패하면 원인 분석 → 최소 수정 → 다시 테스트
6) 통과하면 TODO 업데이트(done)
7) 실수나 삽질이 있었으면 AI_MISTAKES.md에 기록

## 테스트 원칙
- “테스트를 못 돌린다”는 결론을 내리기 전에:
  - 레포의 테스트 커맨드를 탐색(package.json, Makefile, README, CI 설정 등)
  - 최소 스모크 테스트(빌드/런)라도 수행
- 새 기능/버그 수정이라면 최소 1개 이상의 단위 테스트 추가를 고려
---
