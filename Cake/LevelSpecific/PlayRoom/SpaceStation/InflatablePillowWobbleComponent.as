import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.BouncePad.BouncePad;

class UInflatablePillowWobbleComponent : USceneComponent
{
	UPROPERTY()
	FHazeTimeLike HoverTimeLike;

	ABouncePad BouncePad;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -200.f;
	default PhysValue.UpperBound = 0.f;
	default PhysValue.LowerBounciness = 0.8f;
	default PhysValue.UpperBounciness = 0.25f;
	default PhysValue.Friction = 1.4f;

	float StartDelay = 0.f;
	float HoverPlayRate = 0.35f;

	float WobbleOffset;
	float WobbleSpeed;

	float RotationSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BouncePad = Cast<ABouncePad>(Owner);
		if (BouncePad == nullptr)
			return;

		TArray<UActorComponent> Components = BouncePad.GetComponentsByClass(UStaticMeshComponent::StaticClass());

		for (UActorComponent CurComp : Components)
		{
			UStaticMeshComponent StaticMeshComp = Cast<UStaticMeshComponent>(CurComp);
			if (StaticMeshComp != nullptr && StaticMeshComp == BouncePad.BouncePadMesh)
			{
				StaticMeshComp.AttachToComponent(this);
				StaticMeshComp.SetRelativeLocation(FVector::UpVector * -50.f);
			}
		}

		StartDelay = FMath::RandRange(0.1f, 1.f);
		HoverPlayRate = FMath::RandRange(0.2f, 0.4f);

		WobbleSpeed = FMath::RandRange(1.f, 3.f);
		WobbleOffset = FMath::RandRange(1.f, 6.f);

		RotationSpeed = FMath::RandRange(10.f, 30.f);
		if (FMath::RandBool())
			RotationSpeed *= -1;

		HoverTimeLike.SetPlayRate(HoverPlayRate);
		HoverTimeLike.BindUpdate(this, n"UpdateHover");
		System::SetTimer(this, n"StartWobbling", StartDelay, false);

		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLanded");
        BindOnDownImpactedByPlayer(BouncePad, OnPlayerLanded);
	}

	UFUNCTION(NotBlueprintCallable)
	void StartWobbling()
	{
		HoverTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateHover(float CurValue)
	{
		float CurHeight = FMath::Lerp(-50.f, 50.f, CurValue);
		BouncePad.BouncePadMesh.SetRelativeLocation(FVector::UpVector * CurHeight);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLanded(AHazePlayerCharacter Player, FHitResult Hit)
	{
		PhysValue.AddImpulse(-1000.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 100.f);
		PhysValue.Update(DeltaTime);

		SetRelativeLocation(FVector::UpVector * PhysValue.Value);

		float Rot = WobbleOffset + (System::GetGameTimeInSeconds() * WobbleSpeed);
		Rot = FMath::Sin(Rot) * WobbleOffset;

		SetRelativeRotation(FRotator(0.f, RelativeRotation.Yaw, Rot));

		AddLocalRotation(FRotator(0.f, RotationSpeed * DeltaTime, 0.f));
	}
}