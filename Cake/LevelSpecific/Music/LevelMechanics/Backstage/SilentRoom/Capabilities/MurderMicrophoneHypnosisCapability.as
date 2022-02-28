import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneHypnosisCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 10;

	AMurderMicrophone Snake;
	AHazePlayerCharacter Player;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UMurderMicrophoneMovementComponent MoveComp;
	TArray<AActor> CachedIgnoreActors;
	UMurderMicrophoneSettings Settings;
	float TotalHypnosisDuration = 0.f;
	float RequiredRangeDuration = 2.0f;
	bool bOutOfRange = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
		Settings = UMurderMicrophoneSettings::GetSettings(Owner);

		CachedIgnoreActors.Add(Owner);
		CachedIgnoreActors.Add(Game::Cody);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snake.CurrentState != EMurderMicrophoneHeadState::Hypnosis)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player = Game::GetMay();
		Snake.ApplySettings(Snake.HypnosisSettings, this, EHazeSettingsPriority::Override);
		bOutOfRange = false;
		TotalHypnosisDuration = 0.0f;
		Snake.SongOfLifeCharge = Settings.Hypnosis;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TotalHypnosisDuration += DeltaTime;
		if (TotalHypnosisDuration > 10.f)
			Snake.PlayMayBark();
		
		if(!HasControl())
			return;

		const FVector DirectionToTargetFromCore = (Player.ActorCenterLocation - Snake.WeakPoint.WorldLocation).GetSafeNormal2D();
		const FVector DistanceToTargetFromCore = Player.ActorCenterLocation - Snake.WeakPoint.WorldLocation;

		const FVector TargetLocation = (Player.ActorCenterLocation - DirectionToTargetFromCore * (DistanceToTargetFromCore.Size() * 0.2f)) + FVector(0.0f, 0.0f, 700.0f);

		MoveComp.SetTargetLocation(TargetLocation);
		MoveComp.SetTargetFacingDirection(DirectionToTargetFromCore);

		if(TotalHypnosisDuration > RequiredRangeDuration && !TargetingComp.IsTargetWithinChaseRange(Game::May))
		{
			const float DistanceToMay2DSq = Game::May.ActorLocation.DistSquared2D(Snake.SnakeHeadLocation);
			//bOutOfRange = DistanceToMay2DSq > Snake.HypnosisMaxRangeSq;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TotalHypnosisDuration < 1.0f)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		if(!Snake.IsAffectedBySongOfLife())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.CurrentState != EMurderMicrophoneHeadState::Hypnosis)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bOutOfRange)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!HasVisionToMay())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	private bool HasVisionToMay() const
	{
		//return TargetingComp.HasSightToTarget(Game::May);
		const FVector StartLoc = Snake.SnakeHeadCenterLocation;
		const FVector EndLoc = Game::May.ActorLocation;
		FHitResult Hit;
		System::LineTraceSingle(StartLoc, EndLoc, ETraceTypeQuery::Visibility, false, CachedIgnoreActors, EDrawDebugTrace::None, Hit, false);

		if(Hit.Actor == Game::May)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!Snake.IsKilled())
			Snake.SetCurrentState(EMurderMicrophoneHeadState::ExitHypnosis);
		
		Snake.ClearSettingsByInstigator(this);
		Snake.SongOfLifeCharge = 0.0f;
	}
}
