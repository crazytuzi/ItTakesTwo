import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneSuspiciousCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 10;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UMurderMicrophoneMovementComponent MoveComp;

	private bool bBecomeAggressive = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snake.CurrentState != EMurderMicrophoneHeadState::Suspicious)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Snake.AddEyeColor(Snake.AggressiveEyeColor, this, 3);
		const FVector NewTargetLocation = Snake.HeadStartLocation + FVector(0.0f, 0.0f, 300.0f);
		MoveComp.SetTargetLocation(NewTargetLocation);
		bBecomeAggressive = false;
		Snake.ApplySettings(Snake.SuspiciousSettings, this, EHazeSettingsPriority::Override);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Snake.UpdateEyeColorIntensityAlpha(Owner.ActorLocation);

		if(!HasControl())
			return;
		
		bBecomeAggressive = TargetingComp.IsTargetWithinAggressiveRange(Snake.TargetPlayer);
		AHazePlayerCharacter TargetPlayer = Snake.TargetPlayer;
		if(TargetPlayer == nullptr)
			return;

		FVector DirectionToTarget = (Snake.WeakPoint.WorldLocation - TargetPlayer.ActorCenterLocation).GetSafeNormal2D();
		DirectionToTarget = DirectionToTarget.RotateAngleAxis(-45.0f, FVector::ForwardVector);
		//System::DrawDebugArrow(TargetPlayer.ActorCenterLocation, TargetPlayer.ActorCenterLocation + DirectionToTarget * 200.0f, 10, FLinearColor::Green);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Snake.HasTarget() && Snake.PendingTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bBecomeAggressive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.ShouldEnterHypnosis())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.CurrentState != EMurderMicrophoneHeadState::Suspicious)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HasControl() && !Snake.IsKilled())
		{
			if(Snake.ShouldEnterHypnosis())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Hypnosis);
			else if(!Snake.HasTarget())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Sleeping);
			else if(bBecomeAggressive)
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Aggressive);
			else
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Sleeping);
		}

		Snake.RemoveEyeColor(this);
		Snake.ClearSettingsByInstigator(this);
	}
}
