import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneAggressiveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 10;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UMurderMicrophoneMovementComponent MoveComp;
	UMurderMicrophoneSettings Settings;

	AHazePlayerCharacter TargetPlayer;

	private bool bTargetOutOfRange = false;
	private bool bEatTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
		Settings = UMurderMicrophoneSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snake.CurrentState != EMurderMicrophoneHeadState::Aggressive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Snake.SetCurrentState(EMurderMicrophoneHeadState::Aggressive);
		bTargetOutOfRange = false;
		bEatTarget = false;
		Snake.ApplySettings(Snake.AggressiveSettings, this, EHazeSettingsPriority::Override);
		Snake.AddEyeColor(Snake.AggressiveEyeColor, this, 2);
		TargetPlayer = Snake.TargetPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl() || TargetPlayer == nullptr)
			return;

		FVector DirectionToTarget = (Snake.WeakPoint.WorldLocation - TargetPlayer.ActorCenterLocation).GetSafeNormal2D();
		DirectionToTarget = DirectionToTarget.RotateAngleAxis(-45.0f, FVector::ForwardVector);

		const FVector OffsetPlayerLocation = TargetPlayer.ActorCenterLocation + FVector(0, 0, 250.0f);
		const FVector TargetLocation = OffsetPlayerLocation + DirectionToTarget * 250.0f;
		MoveComp.SetTargetLocation(TargetLocation);
		//System::DrawDebugSphere(TargetLocation, 100.0f, 12, FLinearColor::Green);

		bTargetOutOfRange = !TargetingComp.IsTargetWithinChaseRange(TargetPlayer);

		const float DistToTargetSq = TargetLocation.DistSquared(Snake.SnakeHeadLocation);
		bEatTarget = (DistToTargetSq - FMath::Square(Settings.AggressiveEatRange)) < 0.0f && !TargetingComp.IsTargetBeingEatenBySnake(TargetPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Snake.HasTarget())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bEatTarget)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.ShouldEnterHypnosis())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!Snake.HasTarget())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TargetPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!Snake.IsSnakeInsideChaseRadius())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!TargetingComp.IsTargetWithinChaseRange(TargetPlayer))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.CurrentState != EMurderMicrophoneHeadState::Aggressive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AHazePlayerCharacter TargetToEat = Cast<AHazePlayerCharacter>(DeactivationParams.GetObject(n"TargetToEat"));

		if(HasControl() && !Snake.IsKilled())
		{
			if(bEatTarget && Snake.HasTarget())
				Snake.StartEatingPlayer(Snake.TargetPlayer);
			else if(Snake.ShouldEnterHypnosis())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Hypnosis);
			else
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Retreat);
		}

			Snake.ClearSettingsByInstigator(this);
		Snake.RemoveEyeColor(this);
	}
}
