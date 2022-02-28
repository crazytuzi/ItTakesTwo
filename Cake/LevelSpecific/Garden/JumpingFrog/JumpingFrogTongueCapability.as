import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.JumpingFrog.GardenFly;

class UJumpingFrogTongueCapability : UHazeCapability
{
	AJumpingFrog Frog;
	AGardenFly TargetGardenFly;

	FVector TongueEndLocation;

	float TongueRange = 3500.0f;
	float TongueSpeed = 6000.0f;

	bool bTongueRetracting = false;
	bool bDeactivateCapability = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Frog = Cast<AJumpingFrog>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Frog.bShouldActivateTongue)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bDeactivateCapability)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Frog.bShouldActivateTongue = false;
		Frog.bTongueIsActive = true;
		bTongueRetracting = false;
		bDeactivateCapability = false;
		TongueEndLocation = Frog.TongueComp.WorldLocation;
		Frog.TongueComp.SetHiddenInGame(false);
	

		AGardenFly NewGardenFly = Cast<AGardenFly>(ActivationParams.GetObject(JumpingFrogTags::TargetGardenFly));

		if(NewGardenFly != nullptr)
		{
			TargetGardenFly = NewGardenFly;
			TargetGardenFly.FrogEater = Frog;
		}

		Owner.BlockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Frog.TongueComp.SetHiddenInGame(true);
		Frog.bTongueIsActive = false;

		if(TargetGardenFly != nullptr)
		{
			TargetGardenFly.DestroyActor();
			TargetGardenFly = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		const FVector ForwardVector = Owner.GetActorForwardVector();
		const FVector StartLocation = Frog.TongueComp.WorldLocation;


		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);

		FHazeTraceParams Params;
		Params.InitWithObjectTypes(ObjectTypes);
		Params.SetToSphere(TongueRange);
		Params.OverlapLocation = Owner.GetActorLocation();
		Params.IgnoreActor(Owner);
		
		TArray<FOverlapResult> OutOverlaps;

		Params.Overlap(OutOverlaps);
		
		const FVector Up = Owner.GetActorUpVector();
		const FVector Right = Owner.GetActorRightVector();

		const float Length = 400.0f;
		const float HorizontalAngleOffset = 30.0f;
		const float VerticalAngleOffset = 30.0f;
		
		const FVector RightOffset = ForwardVector.RotateAngleAxis(HorizontalAngleOffset, Up);
		const FVector LeftOffset = ForwardVector.RotateAngleAxis(-HorizontalAngleOffset, Up);

		const FVector UpOffset = ForwardVector.RotateAngleAxis(VerticalAngleOffset, Right);
		const FVector BottomOffset = ForwardVector.RotateAngleAxis(-VerticalAngleOffset, Right);

		const float DebugDisplayTime = 60.0f;

		const FVector RightNormal = RightOffset.CrossProduct(Up).GetSafeNormal();
		const FVector LeftNormal = -LeftOffset.CrossProduct(Up).GetSafeNormal();

		const FVector UpNormal = UpOffset.CrossProduct(Right).GetSafeNormal();
		const FVector BottomNormal = -BottomOffset.CrossProduct(Right).GetSafeNormal();

		
		const float HorizontalOffset = 10.0f;
		const float VerticalOffset = 10.0f;

		const FVector RightStartLocation = StartLocation + (Right * HorizontalOffset);
		const FVector LeftStartLocation = StartLocation - (Right * HorizontalOffset);

		const FVector UpStartLocation = StartLocation - (Up * VerticalOffset);
		const FVector BottomStartLocation = StartLocation + (Up * VerticalOffset);

		TargetGardenFly = nullptr;

		FHazeTraceParams VisibilityTraceParams;
		VisibilityTraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		VisibilityTraceParams.SetToLineTrace();
		VisibilityTraceParams.From = Frog.TongueComp.WorldLocation;
		VisibilityTraceParams.IgnoreActor(Owner);

		float MinDistanceSq = TongueRange * TongueRange;

		for(FOverlapResult& Overlap : OutOverlaps)
		{
			AGardenFly GardenFly = Cast<AGardenFly>(Overlap.Actor);

			if(GardenFly == nullptr || (GardenFly != nullptr && GardenFly.FrogEater != nullptr))
			{
				continue;
			}

			const FVector OverlapLocation = Overlap.Actor.ActorLocation;

			const FVector RightDirToTarget = (OverlapLocation - RightStartLocation).GetSafeNormal();
			const FVector LeftDirToTarget = (OverlapLocation - LeftStartLocation).GetSafeNormal();
			const FVector UpDirToTarget = (OverlapLocation - UpStartLocation).GetSafeNormal();
			const FVector BottomToTarget = (OverlapLocation - BottomStartLocation).GetSafeNormal();

			if(RightDirToTarget.DotProduct(RightNormal) > 0.0f && LeftDirToTarget.DotProduct(LeftNormal) > 0.0f
			&& UpDirToTarget.DotProduct(UpNormal) > 0.0f && BottomToTarget.DotProduct(BottomNormal) > 0.0f)
			{
				VisibilityTraceParams.To = OverlapLocation;
				FHazeHitResult Hit;
				VisibilityTraceParams.Trace(Hit);
				if(Hit.bBlockingHit && Hit.Actor == Overlap.Actor)
				{
					const float DistanceSq = StartLocation.DistSquared(OverlapLocation);
					if(DistanceSq < MinDistanceSq)
					{
						MinDistanceSq = DistanceSq;
						TargetGardenFly = GardenFly;
					}
				}
			}
		}

		if(TargetGardenFly != nullptr)
		{
			ActivationParams.AddObject(JumpingFrogTags::TargetGardenFly, TargetGardenFly);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TargetGardenFly != nullptr && TargetGardenFly.FrogEater != Frog)
		{
			TargetGardenFly = nullptr;
		}

		if(!bTongueRetracting)
		{
			const FVector TargetEndLocation = GetTongueTargetLocation();
			TongueEndLocation = FMath::VInterpConstantTo(TongueEndLocation, TargetEndLocation, DeltaTime, TongueSpeed);

			if( (TargetEndLocation - TongueEndLocation).Size() < 0.1f )
			{
				bTongueRetracting = true;
			}
		}
		else
		{
			const FVector TargetEndLocation = Frog.TongueComp.WorldLocation;
			TongueEndLocation = FMath::VInterpConstantTo(TongueEndLocation, TargetEndLocation, DeltaTime, TongueSpeed);

			if(TargetGardenFly != nullptr)
			{
				TargetGardenFly.SetActorLocation(TongueEndLocation);
			}

			if( (TargetEndLocation - TongueEndLocation).Size() < 0.1f )
			{
				bDeactivateCapability = true;
			}
		}

		Frog.TongueComp.SetNiagaraVariableVec3("User.BeamEnd", TongueEndLocation);
		Frog.TongueComp.SetNiagaraVariableVec3("User.BeamStart", Frog.TongueComp.WorldLocation);
	}

	FVector GetTongueTargetLocation() const
	{
		if(TargetGardenFly != nullptr)
		{
			return TargetGardenFly.ActorLocation;
		}

		return Frog.TongueComp.WorldLocation + (Frog.ActorForwardVector * 500.0f);
	}
}
