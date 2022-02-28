import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogTags;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.LevelActors.FrogPond.FrogPondScaleActor;

class UJumpingFrogScaleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	AJumpingFrog Frog;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	AFrogPondScaleActor Scale;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Frog = Cast<AJumpingFrog>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(Scale != nullptr)
			Scale.RemoveFrogFromScale(Frog);

		Scale = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FHitResult DownHit = MoveComp.GetDownHit();
		auto WantedScale = Cast<AFrogPondScaleActor>(DownHit.Actor);
		if(Scale != WantedScale)
		{
			if(WantedScale != nullptr)
			{
				FVector TempLocation;
				const float LeftDistance = WantedScale.LeftWeightNode.GetWorldLocation().DistSquared(Frog.GetActorLocation());
				const float RightDistance = WantedScale.RightWeightNode.GetWorldLocation().DistSquared(Frog.GetActorLocation());
				if(LeftDistance < RightDistance)
				{
					WantedScale.AddFrogsOnLeftScale(Frog);
				}
				else
				{
					WantedScale.AddFrogsOnRightScale(Frog);
				}
			}
			else
			{
				Scale.RemoveFrogFromScale(Frog);
			}

			Scale = WantedScale;
		}
	}
}
