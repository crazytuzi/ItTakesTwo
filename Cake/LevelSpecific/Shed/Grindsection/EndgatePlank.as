import Peanuts.Spline.SplineComponent;
import Peanuts.Movement.SplineLockStatics;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.MovementSettings;

event void FOnDoubleGroundPounded();
class AEndGatePlank : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PlankPivot;

	UPROPERTY(DefaultComponent, Attach = PlankPivot)
	UStaticMeshComponent ShovelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent BalanceSpline;

	UPROPERTY(DefaultComponent , Attach = Root)
	UBoxComponent BalanceTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CounterWeightPivot;

	UPROPERTY(DefaultComponent, Attach = CounterWeightPivot)
	UStaticMeshComponent CounterWeightMesh;

	UPROPERTY(DefaultComponent, Attach = CounterWeightMesh)
	UHazeAkComponent HazeAkCompBucket;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LandOnPlatformAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeavePlatformAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GroundpoundedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoubleGroundpoundedAudioEvent;

	UPROPERTY()
	FOnDoubleGroundPounded OnGroundPounded;

	UPROPERTY()
	UHazeDisableComponent DisableComp;

	TArray<AHazePlayerCharacter> LockedPlayers;
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	FRotator PlankPivotStartRot;
	FRotator CounterWeightStartRot;

	FHazeAcceleratedFloat Float;
	float MayGroundPoundTimer;
	float CodyGroundPoundTimer;
	bool bIsDoubleGroundpounded;
	bool bHasSentEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlankPivotStartRot = PlankPivot.RelativeRotation;
		CounterWeightStartRot = CounterWeightPivot.RelativeRotation;

		BalanceTrigger.OnComponentBeginOverlap.AddUFunction(this ,n"TriggeredOnBeginOverlap");

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		FActorGroundPoundedDelegate OnGroundPound;
		OnGroundPound.BindUFunction(this, n"OnActorGroundPounded");
		BindOnActorGroundPounded(this, OnGroundPound);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		OverlappingPlayers.Add(Player);
		HazeAkCompBucket.HazePostEvent(LandOnPlatformAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Remove(Player);
		HazeAkCompBucket.HazePostEvent(LeavePlatformAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnActorGroundPounded(AHazePlayerCharacter Player)
	{
		if(MayGroundPoundTimer == 0 && CodyGroundPoundTimer == 0)
		{
			Float.AccelerateTo(2.f, 0.2f, ActorDeltaSeconds);
			HazeAkCompBucket.HazePostEvent(GroundpoundedAudioEvent);
		}

		if (Player.IsMay())
		{
			MayGroundPoundTimer = 1.5f;
		}
		else
		{
			CodyGroundPoundTimer = 1.5f;
		}

		if(CodyGroundPoundTimer > 0 && MayGroundPoundTimer > 0 && HasControl())
		{
			NetSetDoubleGroundpounded();
		}
	}

	UFUNCTION(NetFunction)
	void NetSetDoubleGroundpounded()
	{
		bIsDoubleGroundpounded = true;
		HazeAkCompBucket.HazePostEvent(DoubleGroundpoundedAudioEvent);
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr && !LockedPlayers.Contains(Player))
		{
			FConstraintSettings Settings;
			Settings.bLockToEnds = true;
			Settings.SplineToLockMovementTo = BalanceSpline;

			StartSplineLockMovementWithLerp(Player, Settings);
			LockedPlayers.Add(Player);
			
			UMovementSettings::SetWalkableSlopeAngle(Player, 89.f, this);
		}
    }

	float GetAccelerationNormalized() property
	{
		float LargestDistance = 0;

		for(auto Player : OverlappingPlayers)
		{
			float DistToPlayer = PlankPivot.WorldLocation.Distance(Player.ActorLocation);
			LargestDistance += DistToPlayer;
		}

		return LargestDistance / 1400; 
	}

	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsDoubleGroundpounded)
		{
			Float.AccelerateTo(5, 1.5f, DeltaSeconds);

			if(Float.Value > 4.9f)
			{
				if(HasControl() && !bHasSentEvent)
				{
					bHasSentEvent = true;
					NetFinishedDoubleGroundPound();
				}
			}
		}

		else if(CodyGroundPoundTimer > 0 || MayGroundPoundTimer > 0)
		{
			Float.SpringTo(AccelerationNormalized, 200.f, 0.02f,DeltaSeconds);
		}
		else
		{
			Float.SpringTo(AccelerationNormalized, 150.5f, 0.1f, DeltaSeconds);
		}

		UpdateGroundPoundTimers(DeltaSeconds);
		UpdateRotation(Float.Value);
	}

	void UpdateGroundPoundTimers(float Delta)
	{
		MayGroundPoundTimer -= Delta;
		CodyGroundPoundTimer -= Delta;

		MayGroundPoundTimer = FMath::Clamp(MayGroundPoundTimer, 0, 1.5f);
		CodyGroundPoundTimer = FMath::Clamp(CodyGroundPoundTimer, 0, 1.5f);
	}

	UFUNCTION(NetFunction)
	void NetFinishedDoubleGroundPound()
	{
		for (auto player : Game::GetPlayers())
		{
			UMovementSettings::ClearWalkableSlopeAngle(player, this);
			player.DetachFromActor(EDetachmentRule::KeepWorld);
		}
		OnGroundPounded.Broadcast();
	}

	void UpdateRotation(float Alpha)
	{
		FRotator PivotRotation = PlankPivotStartRot;
		FRotator PivotMaxRotation = PlankPivotStartRot;
		
		FRotator CounterWeightRotation = CounterWeightStartRot;
		FRotator CounterWeightMaxRot = CounterWeightStartRot;

		PivotMaxRotation.Pitch = -5;
		CounterWeightMaxRot.Roll = -7;


		CounterWeightPivot.RelativeRotation = FMath::LerpShortestPath(CounterWeightRotation, CounterWeightMaxRot, Alpha);
		PlankPivot.RelativeRotation = FMath::LerpShortestPath(PivotRotation, PivotMaxRotation, Alpha);
	}
}