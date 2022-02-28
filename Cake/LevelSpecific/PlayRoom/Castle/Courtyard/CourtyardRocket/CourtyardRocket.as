import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneMagnet;
class ACourtyardRocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	private bool bRocketActivated = false;
	private bool bComplete = false;

	const float MoveDuration = 1.5f;
	float CurrentDuration = 0.f;

	UPROPERTY()
	ACourtyardCraneMagnet CraneMagnet;

	FVector StartLocation;

	UPROPERTY()
	UNiagaraSystem Explosion;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CraneMagnet == nullptr)
			return;

		if (!bRocketActivated)
			return;

		if (bComplete)
			return;
		
		CurrentDuration += DeltaTime;
		float Alpha = FMath::Clamp(CurrentDuration / MoveDuration, 0.f, 1.f);

		FVector TargetLocation = CraneMagnet.ActorLocation;
		if (CraneMagnet.BallActor != nullptr)
			TargetLocation = CraneMagnet.BallActor.ActorLocation;

		FVector ControlPoint = (StartLocation + TargetLocation) / 2.f;
		ControlPoint.Z = TargetLocation.Z;

		FVector CurrentLocation = ActorLocation;
		FVector NewLocation = Math::GetPointOnQuadraticBezierCurve(StartLocation, ControlPoint, TargetLocation, Alpha);
		FVector Up = NewLocation - ActorLocation;
		SetActorRotation(FRotator::MakeFromZ(Up));
		SetActorLocation(NewLocation);

		if (Alpha >= 1.f && !bComplete)
		{
			bComplete = true;
			RocketComplete();
		}
	}

	void ActivateRocket()
	{
		bRocketActivated = true;
	}

	void RocketComplete()
	{
		if (Explosion != nullptr)
			Niagara::SpawnSystemAtLocation(Explosion, ActorLocation);

		FVector Impulse = ((CraneMagnet.ActorLocation - StartLocation).ConstrainToPlane(FVector::UpVector)).GetSafeNormal() * 2.5f;
		if (CraneMagnet.BallActor != nullptr)
			CraneMagnet.BallActor.SetCapabilityAttributeVector(n"ExplosionImpulse", Impulse);
		else
			CraneMagnet.SetCapabilityAttributeVector(n"ExplosionImpulse", Impulse);

		DestroyActor();
	}
}