import Peanuts.Spline.SplineActor;
import Rice.Positions.GetClosestPlayer;
class ACrowdSurfer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;
	
	UPROPERTY(DefaultComponent)
	UNiagaraComponent TrailFX;

	UPROPERTY()
	ASplineActor SplineRef;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GlowStickLoopStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GlowStickLoopStopEvent;

	UPROPERTY()
	float SpeedAlongSpline = 10000.f;

	UPROPERTY()
	bool bIsActive = false;

	UPROPERTY(ExposeOnSpawn)
	bool SpaceFloater = false;

	AHazePlayerCharacter ClosestPlayer;

	float CurrentDistanceAlongSplinerino = 0.f;

	float WorldUpDownOffset = 0.f;

	FVector AngularVelocityVector;

	FVector TargetAngularVelocityVector;

	private FHazeAudioEventInstance LoopEvent;

	UFUNCTION()
	void StartAndSetup(FVector StartLocation, ASplineActor Spline, float Speed)
	{
		SplineRef = Spline;
		CurrentDistanceAlongSplinerino = SplineRef.Spline.GetDistanceAlongSplineAtWorldLocation(StartLocation);

		if (Speed > 0.f)
			SpeedAlongSpline = Speed;
		
		float RandomOffset = FMath::RandRange(1000.f, 30000.f);
		CurrentDistanceAlongSplinerino -= RandomOffset;
		
		bIsActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpeedAlongSpline = FMath::RandRange(10000.f, 15000.f);
		AngularVelocityVector = Math::GetRandomPointOnSphere();
		AngularVelocityVector *= FMath::DegreesToRadians(FMath::RandRange(100.f, 500.f));
		TargetAngularVelocityVector = Math::GetRandomPointOnSphere();
		TargetAngularVelocityVector *= FMath::DegreesToRadians(FMath::RandRange(100.f, 400.f));
		WorldUpDownOffset = FMath::RandRange(-50.f, 50.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bIsActive && SplineRef != nullptr)
		{
			CurrentDistanceAlongSplinerino += (SpeedAlongSpline * DeltaTime);
			FVector TargetLocation = SplineRef.Spline.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSplinerino, ESplineCoordinateSpace::World);
			FVector NewLocation = FMath::VInterpTo(GetActorLocation(), TargetLocation, DeltaTime, 7.f);
			NewLocation += FVector(0.f, 0.f, WorldUpDownOffset);
			SetActorLocation(NewLocation);

			AngularVelocityVector = FMath::VInterpTo(AngularVelocityVector, TargetAngularVelocityVector, DeltaTime, 1.f);

			AddActorWorldRotation(FQuat(AngularVelocityVector.GetSafeNormal(), AngularVelocityVector.Size() * DeltaTime));

			ClosestPlayer =	GetClosestPlayer(ActorLocation);
			FVector VectorDistanceToClosestPlayer = ActorLocation - ClosestPlayer.ActorLocation;

			float DistanceToClosestPlayer = VectorDistanceToClosestPlayer.Size();
			
			if(DistanceToClosestPlayer >= 20000.f && !SpaceFloater)
			{
				SetActorHiddenInGame(true);
				
			}
			else
				SetActorHiddenInGame(false);

			if(CurrentDistanceAlongSplinerino >= SplineRef.Spline.GetSplineLength())
			{
				SetActorHiddenInGame(true);
				
			}

			// + wiggle room since they travel so fast.
			float AudioRadius = GlowStickLoopStartEvent.HazeMaxAttenuationRadius * HazeAkComp.GetAttenuationScalingFactor() + 3500;
			if (DistanceToClosestPlayer < AudioRadius && LoopEvent.PlayingID == 0)
				LoopEvent = HazeAkComp.HazePostEvent(GlowStickLoopStartEvent);
			else if (DistanceToClosestPlayer > AudioRadius && LoopEvent.PlayingID != 0)
			{
				HazeAkComp.HazeStopEvent(LoopEvent.PlayingID);
				LoopEvent = Audio::EmptyEventInstance;
			}

		}
	}

	UFUNCTION(BlueprintCallable)
	void StopAudio()
	{
		HazeAkComp.HazePostEvent(GlowStickLoopStopEvent);
	}

}
