import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;

class UFlyingMachineFinalizeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Movement);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;
	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;

	// Settings
	FFlyingMachineSettings Settings;
	UHazeCrumbComponent CrumbComp;

	FHazeAcceleratedRotator RemoteRotation;
	
	UFUNCTION()
    float GetReplicatedTargetSpeed(float AlphaValue) const
    {    
		return FMath::EaseOut(1.0f, 4.f, AlphaValue, 1.5f);       
    }

	float BoostTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Machine = Cast<AFlyingMachine>(Owner);
		CrumbComp = Machine.CrumbComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	} 

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RemoteRotation.SnapTo(Machine.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CrumbComp.SetCrumbDebugActive(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsDebugActive())
		{
			CrumbComp.SetCrumbDebugActive(this, true);
		}

		// Apply speed
		Machine.SpeedPercent = FMath::GetMappedRangeValueClamped(
			FVector2D(Settings.MinSpeed, Settings.MaxSpeed),
			FVector2D(0.f, 1.f),
			Machine.Speed
		);

		FFlyingMachineOrientation Orientation = Machine.Orientation;
		FVector WorldDelta = Orientation.Forward * Machine.Speed * DeltaTime;
		FVector FinalDelta = FVector::ZeroVector;
	
		// Check for collisions
		TArray<FHitResult> Hits;
		Trace::SweepComponentForHits(Machine.MovementCollision, WorldDelta, Hits);

		FHitResult Hit;
		for(FHitResult HitTest : Hits)
		{
			if (HitTest.bBlockingHit)
			{
				Hit = HitTest;
				break;
			}
		}

		FinalDelta += WorldDelta;
		if (Hit.bBlockingHit)
		{
			// Immediately de-penetrate
			FinalDelta += Hit.ImpactNormal * Hit.PenetrationDepth * 4.f;
			Machine.OnCollision.Broadcast(Hit);
		}

		if (HasControl())
		{
			Machine.SetActorLocationAndRotation(Machine.ActorLocation + FinalDelta, Orientation.Rotator());
			//FHazeActorReplication Params = Machine.MakeReplicationData();
			//Params.ModifyVelocity(Orientation.Forward * Machine.Speed);

			// Pack the speed in the custom rotation so it dont get compressed
			CrumbComp.SetCustomCrumbVector(FVector(Machine.Speed, 0.f, 0.f));
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized Params;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, Params);
			RemoteRotation.AccelerateTo(Params.Rotation, 0.5f, DeltaTime);
			Machine.SetActorLocationAndRotation(Machine.ActorLocation + Params.DeltaTranslation, RemoteRotation.Value);
		}			

		Machine.CallOnTickEvent(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString Str = "";

		return Str;
	}
}