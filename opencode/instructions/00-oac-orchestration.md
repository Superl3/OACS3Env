---
# OAC Orchestration Core Rules (Global)

이 문서는 OpenAgentsControl(OAC) 기반 OpenCode 환경에서 “항상” 적용되는 전역 작업 규칙이다.

## 1) 기본 원칙: 분해 → 실행 → 검증 → 학습
- 어떤 요청이든 먼저 **TaskManager로 서브태스크(atomic)로 분해**한다.
- 각 atomic task는 반드시 다음을 포함한다:
  - 목표(한 문장)
  - 변경 범위(파일/모듈)
  - 검증 방법(테스트/빌드/런)
  - Done(완료 판정 기준)

## 2) 멀티에이전트 분배(역할 분리)
- 오케스트레이터(Primary)는 기본적으로 “조율자”다.
- 구현/테스트/리뷰/문서화는 가능하면 서브에이전트에게 위임한다.
- read-only 역할(컨텍스트 탐색/리서치)은 write/edit를 하지 않는다.

## 3) TODO는 작업의 단일 진실원(Single Source of Truth)
- 할 일이 생기면 todowrite로 TODO를 만든다.
- 진행할 항목은 in_progress로, 끝나면 done으로 바꾼다.
- 대기(사용자 승인/외부 입력)가 필요하면 해당 TODO에 “blocked” 메모를 남기고 상태를 in_progress로 유지하지 말라.

## 4) Worktree는 ‘기본값’이다
- 코드를 바꾸는 작업은 원칙적으로 worktree에서 수행한다.
- worktree 정책은 instructions/01-worktree-policy.md 를 따른다.

## 5) 테스트/검증은 옵션이 아니다
- 변경 후에는 최소 1개 이상의 검증(테스트/빌드/타입체크)을 실행한다.
- 자세한 규칙은 instructions/02-atomic-task-and-tests.md 참고.

## 6) 실수/반려 학습은 파일로 남긴다
- 실수/되돌림/유저 반려가 발생하면 AI_MISTAKES.md에 기록한다.
- 다음 작업 시작 전, AI_MISTAKES.md를 확인한다.
---
