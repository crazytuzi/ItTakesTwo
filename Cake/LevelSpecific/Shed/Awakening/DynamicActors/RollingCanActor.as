import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Peanuts.Spline.SplineComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class ARollingCanActor : AHazeActor
{
	float Velocity;
	const float Friction = 0.999f;
	const float AccelerationMulti = 1.5f;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UPROPERTY(DefaultComponent ,RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncPosition;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SyncRotation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncVelo;

	UPROPERTY()
	float RollingIdleMultiplier = 1.2f;

	UPROPERTY()
	float BouncyNess = 0.5f;

	UPROPERTY(DefaultComponent)
	UBoxComponent LeftBlock;

	UPROPERTY(DefaultComponent)
	UBoxComponent RightBlock;

	UPROPERTY(DefaultComponent)
	UBoxComponent OuterLeftBlock;

	UPROPERTY(DefaultComponent)
	UBoxComponent OuterRightBlock;

	UPROPERTY(DefaultComponent)
	UBoxComponent OuterLeftLowerBlock;

	UPROPERTY(DefaultComponent)
	UBoxComponent OuterRightLowerBlock;


	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UArrowComponent ForwardDir;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent CanTrigger;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RollingCanLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnHitSplineStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnHitSplineEndEvent;

	TArray<AHazePlayerCharacter> KillTriggerOverlappingPlayers;

	float TimeIdle;
	float LastDistAlongSpline;
	FVector LastPosition;
	float VeloRtpc;
	float EndOfSplineDist;

	UPROPERTY()
	bool FlipRotation;

	UPROPERTY()
	bool bLockInPlace;

	float SpeedToAdd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline.DetachFromParent(true);
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		HazeAkComp.HazePostEvent(RollingCanLoopAudioEvent);

		CanTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		CanTrigger.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
		
		OuterLeftLowerBlock.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		OuterLeftLowerBlock.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");

		OuterRightLowerBlock.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		OuterRightLowerBlock.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
		UActorImpactedCallbackComponent CallbackComp = UActorImpactedCallbackComponent::Get(this);
		// Since the control side is the only side using the callback then we don't need to send the impact event over network.
		CallbackComp.bCanBeActivedLocallyOnTheRemote = true;

		ActorLocation = Spline.GetPositionClosestToWorldLocation(ActorLocation, true).GetWorldLocation();
	}

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);
        
		if (OverlappingPlayer != nullptr)
		{
			if (!KillTriggerOverlappingPlayers.Contains(OverlappingPlayer))
			{
				KillTriggerOverlappingPlayers.Add(OverlappingPlayer);
			}			
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);

        if (OverlappingPlayer != nullptr)
		{
			KillTriggerOverlappingPlayers.Remove(OverlappingPlayer);
		}
    }

	float GetDotToPlayers() property
	{
		if (ShouldBeStuck)
			return 0;

		FVector PlayerDir;
		float Dot = 0;

		if(OverlappingPlayers.Num() == 0)
		return 0;

		for(auto Player : OverlappingPlayers)
		{
			FVector DirToPlayer = ForwardDir.WorldLocation - Player.ActorLocation;
			Dot += DirToPlayer.GetSafeNormal().DotProduct(ForwardDir.ForwardVector);
		}

		Dot /= OverlappingPlayers.Num();

		return Dot;
	}

	float GetAcceleration() property
	{
		float LargestDistance = 0;


		for(auto Player : OverlappingPlayers)
		{
			float DistToPlayer = ForwardDir.WorldLocation.Distance(Player.ActorLocation);

			if (DistToPlayer > LargestDistance)
			{
				LargestDistance = DistToPlayer;
			}
		}
		return LargestDistance * AccelerationMulti;
	}

	bool GetShouldBeStuck() property
	{
		FVector Position;
		float DistAlongSpline = 0;
		Spline.FindDistanceAlongSplineAtWorldLocation(ActorLocation, Position, DistAlongSpline);

		if (FMath::IsNearlyEqual(DistAlongSpline, Spline.SplineLength, 150.1f) && bLockInPlace)
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		OverlappingPlayers.Add(Player);
		HazeAkComp.SetRTPCValue("Rtpc_Shed_Awakening_Platform_RollingCan_Positioning", 0.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Remove(Player);

		if(OverlappingPlayers.Num() == 0)
			HazeAkComp.SetRTPCValue("Rtpc_Shed_Awakening_Platform_RollingCan_Positioning", 1.f);		
	}

	void EndCheck()
	{

	}

	void IdleBehaviour(float DeltaTime)
	{
		if (ShouldBeStuck)
			return;

		if (OverlappingPlayers.Num() == 0)
		{
			TimeIdle += DeltaTime;
			Velocity += FMath::Sin(TimeIdle) * RollingIdleMultiplier;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (HasControl())
		{
			IdleBehaviour(DeltaTime);

			Velocity += Acceleration * DotToPlayers * DeltaTime;
			Velocity -= Velocity * Friction * DeltaTime;

			EndOfSplineDist = Spline.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
			FVector EndOfSplinePos = Spline.GetLocationAtDistanceAlongSpline(EndOfSplineDist, ESplineCoordinateSpace::World);

			if( FMath::IsNearlyEqual(EndOfSplineDist, 0 , 0.0001f) && Velocity > 0 || 
				FMath::IsNearlyEqual(EndOfSplineDist, Spline.GetSplineLength() , 0.0001f) && Velocity < 0)
			{
				Velocity *= -BouncyNess;
			}

			VeloRtpc = FMath::Abs(FMath::GetMappedRangeValueClamped(FVector2D(-200.f, 200.f), FVector2D(-1.f, 1.f), Velocity));
			ActorLocation -= ForwardDir.ForwardVector * Velocity * DeltaTime;
			
			FRotator RelativeRot = FRotator::ZeroRotator;

			float flipMultiplier = 1;

			if (FlipRotation)
			{
				flipMultiplier *= -1;
			}

			RelativeRot.Yaw = flipMultiplier * (Velocity * DeltaTime) / 3.14f;
			Mesh.AddLocalRotation(RelativeRot);

			OutsideSplineCorrection();			

			SyncPosition.Value = ActorLocation;
			SyncRotation.Value = Mesh.RelativeRotation;
			SyncVelo.Value = VeloRtpc;
		}
		else
		{
			Mesh.RelativeRotation = SyncRotation.Value;
			ActorLocation = SyncPosition.Value;
			VeloRtpc = SyncVelo.Value;
		}

		HazeAkComp.SetRTPCValue("Rtpc_Shed_Awakening_Platform_RollingCan", VeloRtpc);
		float Velo = (SyncPosition.Value - LastPosition).Size();
		LastPosition = SyncPosition.Value;

		EvaluateKillingPlayers();

		bool bHitSplineEnd = false;

		if(DidHitSplineBounds(EndOfSplineDist, bHitSplineEnd))
		{
			UAkAudioEvent HitEvent = bHitSplineEnd ? OnHitSplineEndEvent : OnHitSplineStartEvent;
			NetHitSplineBounds(HitEvent);
		}

		LastDistAlongSpline = EndOfSplineDist;
	}

	UFUNCTION(NetFunction)
	void NetHitSplineBounds(UAkAudioEvent& HitEvent)
	{
		HazeAkComp.HazePostEvent(HitEvent);
	}

	void EvaluateKillingPlayers()
	{
		for (auto Player : KillTriggerOverlappingPlayers)
		{
			if (Player.IsPlayerDead())
				continue;

			FVector PlayerLocation = Player.ActorLocation;

			FVector RelativeDirection = Math::ConstrainVectorToPlane(Player.ActorLocation - Mesh.WorldLocation, Mesh.UpVector);
			System::DrawDebugArrow(Mesh.WorldLocation, Mesh.WorldLocation + RelativeDirection);
			float DistanceToplayer = RelativeDirection.Size();
			
			if (DistanceToplayer > 300)
			{
				KillPlayer(Player);
			}
		}
	}

	void OutsideSplineCorrection()
	{
		FVector Position;
		float DistAlongSpline = 0;
		Spline.FindDistanceAlongSplineAtWorldLocation(ActorLocation, Position, DistAlongSpline);


		if (FMath::IsNearlyEqual(DistAlongSpline, 0 , 0.1f))
		{
			ActorLocation = Spline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);
		}

		else if (FMath::IsNearlyEqual(DistAlongSpline, Spline.SplineLength, 0.1f))
		{
			ActorLocation = Spline.GetLocationAtDistanceAlongSpline(Spline.SplineLength, ESplineCoordinateSpace::World);
		}
	}


	bool DidHitSplineBounds(const float CurrentDistanceAlongSpline, bool& bHitOnEnd)
	{
		if(!HasControl())
			return false;			
		
		// Don't act upon to small of changes in movement i.e prevent spam on ends
		if(FMath::Abs(CurrentDistanceAlongSpline - LastDistAlongSpline) < 2.f)
			return false;

		if(FMath::IsNearlyEqual(CurrentDistanceAlongSpline, Spline.SplineLength))
		{
			bHitOnEnd = true;
			return true;
		}

		else if(FMath::IsNearlyEqual(CurrentDistanceAlongSpline, 0.f))
		{
			bHitOnEnd = false;
			return true;
		}

		return false;
	}
}
