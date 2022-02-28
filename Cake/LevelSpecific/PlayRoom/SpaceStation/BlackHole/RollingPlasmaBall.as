import Peanuts.Spline.SplineComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

event void FPlasmaBallKilledPlayer();

class ARollingPlasmaBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BallRoot;

	UPROPERTY(DefaultComponent, Attach = BallRoot)
	UStaticMeshComponent BallMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent KillTrigger;

	UPROPERTY()
	FPlasmaBallKilledPlayer OnKilledPlayer;

	UPROPERTY()
	AActor SplineActor;
	UHazeSplineComponent SplineComp;

	bool bRolling = false;

	float CurrentSpeed = 1000.f;
	float MaxSpeed = 2500.f;
	float DistanceAlongSpline = 0.f;
	float VerticalOffset = 575.f;

	FVector DefaultLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (SplineActor == nullptr)
			return;

		SplineComp = UHazeSplineComponent::Get(SplineActor);

		if (bRolling)
		{
			StartRolling();
		}

		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterKillTrigger");

		DefaultLocation = ActorLocation;
		DisableActor(this);
	}

	UFUNCTION()
	void StartRolling()
	{
		EnableActor(this);
		CurrentSpeed = 1000.f;
		TeleportActor(DefaultLocation, FRotator::ZeroRotator);
		DistanceAlongSpline = SplineComp.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		bRolling = true;
	}

	UFUNCTION()
	void StopRolling()
	{
		bRolling = false;
		DisableActor(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterKillTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		KillPlayer(Player);
		OnKilledPlayer.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (SplineComp == nullptr)
			return;

		if (!bRolling)
			return;

		CurrentSpeed += 60.f * DeltaTime;
		CurrentSpeed = FMath::Clamp(CurrentSpeed, 1000.f, MaxSpeed);
		DistanceAlongSpline += CurrentSpeed * DeltaTime;
		if (DistanceAlongSpline >= SplineComp.SplineLength)
			DistanceAlongSpline = 0.f;

		FVector CurLoc = SplineComp.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector Up = SplineComp.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		CurLoc += Up * VerticalOffset;

		// Calculate travel direction
		FVector BallTravelDirection = CurLoc - ActorLocation;
		BallTravelDirection = BallTravelDirection.GetSafeNormal();

		//Set the rotation of the sphere component
		FVector ActorCross = GetActorUpVector().CrossProduct(BallTravelDirection);
		FRotator BallDirectionRotation = FMath::RotatorFromAxisAndAngle(ActorCross, (CurrentSpeed / 3.f) * DeltaTime);
		FRotator FinalRotation = BallMesh.GetWorldRotation().Compose(BallDirectionRotation);

		SetActorLocation(CurLoc);
		BallMesh.SetWorldRotation(FinalRotation);
	}
}