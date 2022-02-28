
enum ESwarmBehaviourState
{
	None,
	Idle,
	Search,
	PursueSpline,
	PursueMiddle,
	PursuePlayer,
	CirclePlayer,
	Gentleman,
	TelegraphDefence,
	DefendMiddle,
	TelegraphInitial,
	TelegraphBetween,
	Attack,
	AttackUltimate,
	Recover,
	MAX,
};

FName GetSwarmCapabilityTag(ESwarmBehaviourState State)
{
	switch (State)
	{
		case ESwarmBehaviourState::None:
			ensure(false);
			return NAME_None;
		case ESwarmBehaviourState::Idle:
			return n"SwarmIdle";
		case ESwarmBehaviourState::Search:
			return n"SwarmSearch";
		case ESwarmBehaviourState::PursueSpline:
			return n"SwarmPursueSpline";
		case ESwarmBehaviourState::PursueMiddle:
			return n"SwarmPursueMiddle";
		case ESwarmBehaviourState::PursuePlayer:
			return n"SwarmPursuePlayer";
		case ESwarmBehaviourState::CirclePlayer:
			return n"SwarmCirclePlayer";
		case ESwarmBehaviourState::Gentleman:
			return n"SwarmGentleman";
		case ESwarmBehaviourState::TelegraphDefence:
			return n"SwarmTelegraphDefence";
		case ESwarmBehaviourState::DefendMiddle:
			return n"SwarmDefendMiddle";
		case ESwarmBehaviourState::TelegraphInitial:
			return n"SwarmTelegraphInitial";
		case ESwarmBehaviourState::TelegraphBetween:
			return n"SwarmTelegraphBetween";
		case ESwarmBehaviourState::Attack:
			return n"SwarmAttack";
		case ESwarmBehaviourState::AttackUltimate:
			return n"SwarmAttackUltimate";
		case ESwarmBehaviourState::Recover:
			return n"SwarmRecover";
		case ESwarmBehaviourState::MAX:
			ensure(false);
			return NAME_None;
	}
	ensure(false);
	return NAME_None;
}

int32 GetSwarmTickGroupOrder(ESwarmBehaviourState State)
{
	switch (State)
	{
		case ESwarmBehaviourState::None:
			ensure(false);
			return -1;
		case ESwarmBehaviourState::Idle:
			return 10;
		case ESwarmBehaviourState::Search:
			return 20;
		case ESwarmBehaviourState::PursueSpline:
			return 30;
		case ESwarmBehaviourState::PursueMiddle:
			return 31;
		case ESwarmBehaviourState::PursuePlayer:
			return 32;
		case ESwarmBehaviourState::CirclePlayer:
			return 40;
		case ESwarmBehaviourState::Gentleman:
			return 50;
		case ESwarmBehaviourState::TelegraphDefence:
			return 60;
		case ESwarmBehaviourState::DefendMiddle:
			return 70;
		case ESwarmBehaviourState::TelegraphInitial:
			return 80;
		case ESwarmBehaviourState::TelegraphBetween:
			return 81;
		case ESwarmBehaviourState::Attack:
			return 90;
		case ESwarmBehaviourState::AttackUltimate:
			return 100;
		case ESwarmBehaviourState::Recover:
			return 110;
		case ESwarmBehaviourState::MAX:
			return 120;
	}
	ensure(false);
	return -1;
}

FString GetSwarmDebugStateName(ESwarmBehaviourState State)
{
	switch (State)
	{
		case ESwarmBehaviourState::None:
			return "None";
		case ESwarmBehaviourState::Idle:
			return "Idle";
		case ESwarmBehaviourState::Search:
			return "Search";
		case ESwarmBehaviourState::PursueSpline:
			return "PursueSpline";
		case ESwarmBehaviourState::PursueMiddle:
			return "PursueMiddle";
		case ESwarmBehaviourState::PursuePlayer:
			return "PursuePlayer";
		case ESwarmBehaviourState::CirclePlayer:
			return "CirclePlayer";
		case ESwarmBehaviourState::Gentleman:
			return "Gentleman";
		case ESwarmBehaviourState::TelegraphDefence:
			return "TelegraphDefence";
		case ESwarmBehaviourState::DefendMiddle:
			return "DefendMiddle";
		case ESwarmBehaviourState::TelegraphInitial:
			return "TelegraphInitial";
		case ESwarmBehaviourState::TelegraphBetween:
			return "TelegraphBetween";
		case ESwarmBehaviourState::Attack:
			return "Attack";
		case ESwarmBehaviourState::AttackUltimate:
			return "AttackUltimate";
		case ESwarmBehaviourState::Recover:
			return "Recover";
		case ESwarmBehaviourState::MAX:
			return "MAX";
	}
	return "None";
}
