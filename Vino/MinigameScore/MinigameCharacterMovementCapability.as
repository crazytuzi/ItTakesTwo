import Vino.MinigameScore.MinigameStatics;
import Vino.MinigameScore.MinigameCharacter;

class UMinigameCharacterMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MinigameCharacterMovementCapability");
	default CapabilityTags.Add(MinigameCapabilityTags::Minigames);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMinigameCharacter Tambourine;

	FHazeAcceleratedVector AccelToCenter;

	TArray<FHazeAcceleratedVector> AccelImpulseArray;
	TArray<FHazeAcceleratedVector> RemoveImpulseArray;

	FVector StartLoc;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tambourine = Cast<AMinigameCharacter>(Owner);
		Tambourine.OnTambourineImpact.AddUFunction(this, n"OnImpact");
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
		StartLoc = Tambourine.ActorLocation;
		AccelToCenter.SnapTo(StartLoc);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AccelImpulseArray.Num() != 0)
		{
			for(FHazeAcceleratedVector& AccelImpulse : AccelImpulseArray)
			{
				AccelImpulse.AccelerateTo(FVector(0.f, 0.f, 0.f), 1.2f, DeltaTime);
				FVector ImpactOffsetLocation = Tambourine.ActorLocation + AccelImpulse.Value;
				AccelToCenter.SnapTo(ImpactOffsetLocation);	

				if (AccelImpulse.Value.Size() <= 0.05f)
					RemoveImpulseArray.Add(AccelImpulse);
			}

			if (RemoveImpulseArray.Num() != 0)
			{
				for(FHazeAcceleratedVector& AccelImpulse : RemoveImpulseArray)
				{
					if (AccelImpulseArray.Contains(AccelImpulse))
						AccelImpulseArray.Remove(AccelImpulse);
				}

				RemoveImpulseArray.Empty();
			}
		}

		AccelToCenter.AccelerateTo(StartLoc, 0.4f, DeltaTime);
		Tambourine.SetActorLocation(AccelToCenter.Value);
	}

	UFUNCTION()
	void OnImpact(FVector HitFromLoc, float Impulse)
	{
		FVector HitDir = Tambourine.ActorLocation - HitFromLoc;
		HitDir.Normalize();
		FVector HitVelocity = HitDir * Impulse;
		FHazeAcceleratedVector NewImpulse;
		NewImpulse.SnapTo(HitVelocity);
		AccelImpulseArray.Add(NewImpulse);
	}
}