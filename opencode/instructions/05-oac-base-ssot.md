# OAC Base Reference

이 문서는 OAC 공통 규약의 참조 문서다.
에이전트 실행 프롬프트가 아니며, 모드/권한 frontmatter를 갖지 않는다.

## 공통 원칙 (SSOT)

- 역할 분리: 오케스트레이터는 조율 중심, 구현/테스트/리뷰/문서화는 서브에이전트 위임 우선.
- Atomic 실행: 작업은 atomic task로 분해하고, 각 task는 목표/변경 범위/검증/Done 기준을 포함.
- 검증 필수: 구현 후 최소 1개 이상 테스트/빌드/타입체크 등 실행.
- Done 규칙: feature subtask와 대응 quality subtask가 모두 완료되어야 상위 task를 done 처리.

## Atomic 실행 순서 (필수)

1. 분해: TaskManager로 atomic task를 정의한다.
2. 구현: 최소 변경으로 deliverable을 구현한다.
3. 검증: 테스트/빌드/타입체크를 실행하고 실패 시 최소 수정 후 재검증한다.
4. TODO done: 완료 기준 충족 시 TODO 상태를 done으로 갱신한다.
5. 실수 기록: 실패/삽질/반려가 있으면 AI_MISTAKES.md에 기록한다.

## Mandatory Subagents

- TaskManager
- ContextScout
- CoderAgent
- BuildAgent
- TestEngineer
- QualityEngineer
- CodeReviewer
- DocWriter

## Worktree 기본 정책

- 기본값: 코드 변경 작업은 worktree 사용.
- 예외: git 저장소가 아니거나, 저위험 초소형 단일 파일 수정(사용자가 worktree 비선호 명시 포함).

## Permission Validator 권장

- 권한 규칙(frontmatter permission) 수정 후 `tool/validate-agent-permissions.ts` 실행을 권장.
- wildcard(`"*"`)와 specific 패턴을 혼용하면 `permission` 블록 주석에 `# permission_precedence: specificity-first` 선언.

## Quality Pass 공통 규칙

- 기능 subtask마다 quality subtask를 1:1로 연결.
- Quality Done 기준:
  - fast-check(테스트/빌드/타입체크) 통과.
  - soak-lite 반복(최소 3회)에서 메모리/핸들/리소스 지표가 지속 증가하지 않음.
  - 품질 징후 발견 시, 수정 전에 검출용 리그레션(테스트/스크립트)을 먼저 추가.
- 실패 시 fail -> 최소 수정 -> 재검증 루프 적용.
- 동일 결함 반복(2~3회) 또는 땜질 확산 시 refactor subtask로 승격.

## 학습/반려 공통 규칙

- 실패/삽질/사용자 반려는 AI_MISTAKES.md에 기록.
- 반려 발생 시 요구사항 재정의 후 atomic task를 재분해하여 재시도.

## 참조 우선순위

아래 문서가 충돌 시 우선한다.

- `instructions/00-oac-orchestration.md`
- `instructions/01-worktree-policy.md`
- `instructions/02-atomic-task-and-tests.md`
- `instructions/03-learning-and-rejection.md`
- `instructions/04-quality-pass.md`
