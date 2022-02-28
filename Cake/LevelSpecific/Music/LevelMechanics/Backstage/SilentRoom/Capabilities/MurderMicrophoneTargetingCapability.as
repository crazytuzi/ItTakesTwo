import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;


class UMurderMicrophoneTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UHazeCrumbComponent CrumbComp;

	float ChangeTargetElapsed = 0.0f;
	float StartElapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(TargetingComp.bIgnorePlayer)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		StartElapsed = ChangeTargetDelay;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StartElapsed -= DeltaTime;

		if(StartElapsed > 0.0f)
			return;

		TargetingComp.UpdateVisibility(Snake.HeadOffset.WorldLocation);

		if(!TargetingComp.HasSightToTarget(Snake.PendingTarget) || !TargetingComp.IsTargetWithinVisionRange(Snake.PendingTarget))
			Snake.ClearPendingTarget();

		ChangeTargetElapsed -= DeltaTime;
		if(Snake.PendingTarget != nullptr && TargetingComp.HasSightToTarget(Snake.PendingTarget) && TargetingComp.IsTargetWithinVisionRange(Snake.PendingTarget))
		{
			if(!Snake.HasTarget())
			{
				Snake.UpdateTarget();
			}
			else if(ChangeTargetElapsed < 0.0f)
			{
				Snake.UpdateTarget();
				ChangeTargetElapsed = ChangeTargetDelay;
			}
		}

		if(Snake.HasTarget() && (!TargetingComp.HasSightToTarget(Snake.TargetPlayer) || !TargetingComp.IsTargetWithinVisionRange(Snake.TargetPlayer)))
		{
			Snake.ClearTarget();
		}

		AHazePlayerCharacter ClosestTarget = TargetingComp.GetClosestTarget();

		if(!Snake.HasTarget() && !Snake.HasPendingTarget() && ClosestTarget != nullptr)
		{
			Snake.SetPendingTargetPlayer(ClosestTarget);
			ChangeTargetElapsed = ChangeTargetDelay;
		}
		else if(Snake.HasTarget() && ClosestTarget != Snake.TargetPlayer && !Snake.HasPendingTarget() && ClosestTarget != nullptr)
		{
			Snake.SetPendingTargetPlayer(ClosestTarget);
			ChangeTargetElapsed = ChangeTargetDelay;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TargetingComp.bIgnorePlayer)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	float GetChangeTargetDelay() const property
	{
		return 0.75f - PredictionLag;
	}

	float GetPredictionLag() const property
	{
		if(Network::IsNetworked())
			return CrumbComp.PredictionLag;

		return 0.0f;
	}
}
