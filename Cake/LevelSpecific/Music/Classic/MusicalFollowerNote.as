import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;
import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollowerKeyDestination;

event void FOnMusicalNoteDestinationReached();

void ActivateNote(AHazeActor NoteActor)
{
	AMusicalFollowerNote Note = Cast<AMusicalFollowerNote>(NoteActor);
	if(Note != nullptr)
	{
		Note.ActivateNote();
	}
}

class AMusicalFollowerNote : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent TrailVFX;
	default TrailVFX.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(Category = Objective)
	AMusicalKeyDestination TargetDestinationActor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent NoteStartsMovingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent NoteReachesDestinationAudioEvent;

	UPROPERTY()
	FOnMusicalNoteDestinationReached OnDestinationReached;

	UPROPERTY(Category = Movement)
	float Acceleration = 500.0f;

	float Drag = 0.85f;

	UPROPERTY(Category = Movement)
	float RotationSpeed = 1.25f;

	UPROPERTY(Category = Movement)
	float MaxVelocity = 4000.0f;

	UPROPERTY(Category = Movement)
	float DestinationSlowdownDistance = 1500.0f;

	private float MovementVelocity = 0.0f;

	// Start moving along spline when within this distance
	UPROPERTY(Category = Movement)
	float StartSplineMovementDistance = 500.0f;
	float GetStartSplineMovementDistanceSq() const property { return FMath::Square(StartSplineMovementDistance); }

	// Considered as having reached destination whenever withing this distance
	UPROPERTY(Category = Movement)
	float AcceptableRadiusForDestination = 50.0f;
	float GetAcceptableRadiusForDestinationSq() const property { return FMath::Square(AcceptableRadiusForDestination); }

	private float SplineDistanceCurrent = 0.0f;

	private bool bStartRotating = false;
	private bool bApproachSpline = true;
	private bool bHasReachedDestination = false;

	UFUNCTION()
	void ActivateNote()
	{
		SplineDistanceCurrent = TargetDestinationActor.SplineComp.SplineLength - (DestinationSlowdownDistance * 0.5f);
		SetActorTickEnabled(true);
		DisableComp.SetUseAutoDisable(false);
		TrailVFX.Activate();
		UHazeAkComponent::GetOrCreate(this).HazePostEvent(NoteStartsMovingAudioEvent);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(TargetDestinationActor == nullptr)
			return;

		if(bApproachSpline)
		{
			const FVector TargetLoc = TargetDestinationActor.SplineStartLocation;
			float DistanceToTargetSq = TargetLoc.DistSquared(ActorLocation);

			float Alpha = FMath::Clamp(DistanceToTargetSq / StartSplineMovementDistanceSq, 0.0f, 1.0f);
			float DistanceScalar = FMath::EaseOut(0.05f, 1.0f, Alpha, 2.0f);

			MovementVelocity += (Acceleration * DistanceScalar) * DeltaTime;
			MovementVelocity = FMath::Min(MovementVelocity, MaxVelocity);
			MovementVelocity *= FMath::Pow(Drag, DeltaTime);

			const FVector DirectionToTarget = (TargetLoc - ActorLocation).GetSafeNormal();
			const FVector NewLocation = ActorLocation + DirectionToTarget * (MovementVelocity * DistanceScalar) * DeltaTime;

			SetActorLocation(NewLocation);

			if(DistanceToTargetSq < StartSplineMovementDistanceSq)
			{
				bStartRotating = true;
				bApproachSpline = false;
			}
		}
		else
		{
			SplineDistanceCurrent = FMath::Max(SplineDistanceCurrent - Acceleration * DeltaTime, 0.0f);
			const FVector TargetLoc = TargetDestinationActor.SplineComp.GetLocationAtDistanceAlongSpline(SplineDistanceCurrent, ESplineCoordinateSpace::World);
			float DistanceToTargetSq = TargetLoc.DistSquared(ActorLocation);
			float Alpha = FMath::Clamp(DistanceToTargetSq / FMath::Square(DestinationSlowdownDistance), 0.0f, 1.0f);
			float DistanceScalar = FMath::EaseOut(0.01f, 1.0f, Alpha, 2.0f);
			MovementVelocity += (Acceleration * DistanceScalar) * DeltaTime;
			MovementVelocity = FMath::Min(MovementVelocity, MaxVelocity);
			MovementVelocity *= FMath::Pow(Drag, DeltaTime);
			
			const FVector DirectionToTarget = (TargetLoc - ActorLocation).GetSafeNormal();
			const FVector NewLocation = ActorLocation + DirectionToTarget * (MovementVelocity * DistanceScalar) * DeltaTime;

			SetActorLocation(NewLocation);
			
			if(SplineDistanceCurrent <= 0.0f)
			{
				if(!bHasReachedDestination)
				{
					if(DistanceToTargetSq < AcceptableRadiusForDestinationSq)
					{
						bHasReachedDestination = true;
						OnDestinationReached.Broadcast();
						UHazeAkComponent::GetOrCreate(this).HazePostEvent(NoteReachesDestinationAudioEvent);
						TrailVFX.Deactivate();
					}
				}

				if(bHasReachedDestination && DistanceToTargetSq < (AcceptableRadiusForDestinationSq * 0.001f) && TargetDestinationActor.ActorRotation.Equals(ActorRotation))
				{	
					SetActorLocationAndRotation(TargetDestinationActor.ActorLocation, TargetDestinationActor.ActorRotation);
					SetActorTickEnabled(false);
					DisableComp.SetUseAutoDisable(true);
				}
			}
		}

		if(bStartRotating)
		{
			const FQuat NewRotation = FQuat::Slerp(ActorRotation.Quaternion(), TargetDestinationActor.ActorRotation.Quaternion(), DeltaTime * RotationSpeed);
			SetActorRotation(NewRotation.Rotator());
		}
	}

	UFUNCTION()
	void TeleportToTargetDestination()
	{
		if(TargetDestinationActor == nullptr)
			return;

		SetActorLocationAndRotation(TargetDestinationActor.ActorLocation, TargetDestinationActor.ActorRotation);
	}
}
