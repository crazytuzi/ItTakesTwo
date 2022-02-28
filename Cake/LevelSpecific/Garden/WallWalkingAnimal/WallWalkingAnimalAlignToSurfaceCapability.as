import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;

class UWallWalkingAnimalAlignToSurfaceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SurfaceAlign");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	AWallWalkingAnimal TargetAnimal;
	UWallWalkingAnimalMovementComponent MoveComp;

	FVector LastActorWorldUp;
	FHazeAcceleratedVector LerpedWorldUp;
	int LastHorizontalNormal = 0;
	int InvalidHorizontalNormalCount = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TargetAnimal = Cast<AWallWalkingAnimal>(Owner);
		MoveComp = UWallWalkingAnimalMovementComponent::GetOrCreate(Owner);

		const FVector2D CollisionSize = TargetAnimal.GetCollisionSize();

		FVector LocalOffset = FVector(CollisionSize.X * 2.f, 0.f, 0.f);
		
		const int TraceAmount = 5;
		const float RotationAmount = 360.f / TraceAmount;
	
		for(int i = 0; i < TraceAmount; i++)
		{
			const float CurrentRotationAmount = i * RotationAmount;
			TargetAnimal.GroundTraces.AddTrace(FRotator(0.f, CurrentRotationAmount, 0.f).RotateVector(LocalOffset));
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{   
		if(!TargetAnimal.bMounted)
			return EHazeNetworkActivation::DontActivate;

		if(TargetAnimal.bIsControlledByCutscene)
			return EHazeNetworkActivation::DontActivate;	

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TargetAnimal.bMounted)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TargetAnimal.bIsControlledByCutscene)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LastActorWorldUp = TargetAnimal.MoveComp.GetWorldUp();
		LerpedWorldUp.SnapTo(LastActorWorldUp);
		TargetAnimal.GroundTraces.SetTracesNormal(LastActorWorldUp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TargetAnimal.Mesh.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FHitResult CurrentGround = MoveComp.GetDownHit();
		const bool bHasValidGround = TargetAnimal.IsAnimalHitSurfaceStandable(CurrentGround);

		if(TargetAnimal.bHasBeenResetted)
		{
			TargetAnimal.Mesh.SetRelativeRotation(FQuat::Identity);
			TargetAnimal.bHasBeenResetted = false;
			TargetAnimal.GroundTraces.UpdateTraces(TargetAnimal, 100.f);
			FVector NewWorldUp = TargetAnimal.GroundTraces.GetImpactNormal();
			LerpedWorldUp.SnapTo(NewWorldUp);
			TargetAnimal.ChangeActorWorldUp(LerpedWorldUp.Value);
			return;
		}
		else if(!bHasValidGround)
		{
			TargetAnimal.bHasBeenResetted = false;
			InvalidHorizontalNormalCount = 10;
			LastActorWorldUp = TargetAnimal.MoveComp.GetWorldUp();
			TargetAnimal.GroundTraces.SetTracesNormal(LastActorWorldUp);
			return;
		}

		if(TargetAnimal.bPreparingToLaunch)
		{
			FVector CurrentUp = TargetAnimal.GetMovementWorldUp();
			TargetAnimal.GroundTraces.SetTracesNormal(CurrentUp);
		}

		LastActorWorldUp = TargetAnimal.MoveComp.GetWorldUp();
	
		if(HasControl())
		{		
			float DebugTime = -1;
		#if EDITOR
			if(IsDebugActive())
				DebugTime = 0;
		#endif

			TargetAnimal.GroundTraces.UpdateTraces(TargetAnimal, 100.f, DebugTime);
			UpdateMovementWorldUp(DeltaTime);
			TargetAnimal.ChangeActorWorldUp(LerpedWorldUp.Value.GetSafeNormal());	
		}
		else
		{
			FHazeActorReplicationFinalized ReplicatedParams;
			TargetAnimal.CrumbComp.GetCurrentReplicatedData(ReplicatedParams);
			TargetAnimal.ChangeActorWorldUp(ReplicatedParams.Rotation.UpVector);
		}
	}



	void UpdateMovementWorldUp(float DeltaTime)
	{
		if(TargetAnimal.IsTransitioning())
		{
			LerpedWorldUp.SnapTo(MoveComp.WorldUp);
			return;
		}

		if(!MoveComp.IsGrounded())
		{
			LerpedWorldUp.SnapTo(MoveComp.WorldUp);
			return;
		}
		 	
		const FHitResult& Ground = MoveComp.Impacts.DownImpact;
	  	FVector BonusTraceNormal = TargetAnimal.GroundTraces.GetImpactNormal();
		FVector NewNormal = (BonusTraceNormal + Ground.Normal).GetSafeNormal();

		//int HorizontalNormal = FMath::Sign(LastActorWorldUp.DotProduct(TargetAnimal.GetActorRightVector()));
		int CurrentHorizontalNormal = FMath::Sign(NewNormal.DotProduct(TargetAnimal.GetActorRightVector()));
		if(LastHorizontalNormal != CurrentHorizontalNormal && InvalidHorizontalNormalCount < 1)
		{
			InvalidHorizontalNormalCount++;
			LerpedWorldUp.AccelerateTo(LastActorWorldUp, 1.f, DeltaTime);
		}
		else
		{
			InvalidHorizontalNormalCount = 0;
			LerpedWorldUp.AccelerateTo(NewNormal, 1.f, DeltaTime);
		}	

		LastHorizontalNormal = CurrentHorizontalNormal;
	}
}