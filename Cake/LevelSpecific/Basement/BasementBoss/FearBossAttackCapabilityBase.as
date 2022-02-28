import Cake.LevelSpecific.Basement.BasementBoss.BasementBoss;

class UFearBossAttackCapabilityBase : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");

	default CapabilityDebugCategory = n"Attack";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	ABasementBoss Boss;

	UPROPERTY()
	FName ActionName;

	UPROPERTY()
	UAnimSequence Anim;

	bool bAnimationFinished = false;
	bool bAnimationInterrupted = false;

	TArray<AActor> ActorsToIgnore;

	float AttackDuration = 5.f;

	UPROPERTY()
	EBasementBossPhase RequiredPhase = EBasementBossPhase::Bat;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Boss = Cast<ABasementBoss>(Owner);
		ActorsToIgnore.Add(Boss);
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Boss.CurrentPhase != RequiredPhase)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStartedDuringTime(ActionName, 0.2f))
			return EHazeNetworkActivation::DontActivate;

        	return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (AttackDuration <= GetActiveDuration())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (IsActioning(n"InterruptAttack"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Boss.TriggerAttack();
	}

	UFUNCTION(NotBlueprintCallable)
	void AnimFinished()
	{
		bAnimationFinished = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}
}

UFUNCTION()
void TriggerFearBossAttack(FName Tag)
{
	TArray<ABasementBoss> Bosses;
	GetAllActorsOfClass(Bosses);
	Bosses[0].SetCapabilityActionState(Tag, EHazeActionState::ActiveForOneFrame);
}