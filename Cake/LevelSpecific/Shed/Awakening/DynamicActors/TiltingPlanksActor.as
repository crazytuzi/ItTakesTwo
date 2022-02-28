import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class ATiltingPlankActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TiltRoot;

	UPROPERTY(DefaultComponent, Attach = TiltRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UArrowComponent ForwardDir;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMovingAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HitGroundAudioEvent;	

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	const float Friction = 0.999f;

	float DeltaVelocity;
	float Velocity = 0;
	float VelocityLastFrame = 0;

	UPROPERTY()
	float OffsetForce = 0;

	UPROPERTY()
	float UnevenOffsetForce = 0;

	UPROPERTY()
	float BouncyNess = 0.25f;

	UPROPERTY()
	bool bIsUneven = false;

	UPROPERTY()
	float PlayerWeight = 2.f;
	
	UPROPERTY()
	float MaxRotation = 0;

	UPROPERTY()
	float MinRotation = -30;

	bool bHitMax;
	bool bLeftMax;
	float MaxCooldown;

	float GetDotToPlayers() property
	{
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
			float Dot = 0;
			FVector DirToPlayer = ForwardDir.WorldLocation - Player.ActorLocation;
			Dot = DirToPlayer.GetSafeNormal().DotProduct(ForwardDir.ForwardVector);

			LargestDistance += DistToPlayer * Dot;
		}

		return LargestDistance * PlayerWeight;
	}

	bool GetIsLeaningForward() property
	{
		float MiddleRotation = (MaxRotation - MinRotation) * 0.5f;
		MiddleRotation = MinRotation + MiddleRotation;

		if (TiltRoot.RelativeRotation.Pitch > MiddleRotation)
		{
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		OverlappingPlayers.Add(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		OverlappingPlayers.Remove(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Velocity += Acceleration * 1 * DeltaTime;
		Velocity += OffsetForce * DeltaTime;
		Velocity -= Velocity * Friction * DeltaTime;

		if (bIsUneven && OverlappingPlayers.Num() == 0)
		{
			if (IsLeaningForward)
			{
				Velocity += UnevenOffsetForce * DeltaTime;
			}
			else
			{
				Velocity -= UnevenOffsetForce * DeltaTime;
			}	
		}

		FRotator RelativeRot = FRotator::ZeroRotator;
		RelativeRot.Pitch = (Velocity * DeltaTime) / 3.14f;
		TiltRoot.AddLocalRotation(RelativeRot);
		
		FRotator ClampedRot = TiltRoot.RelativeRotation;
		ClampedRot.Pitch = FMath::Clamp(TiltRoot.RelativeRotation.Pitch, MinRotation, MaxRotation);

		TiltRoot.RelativeRotation = ClampedRot;
		



		if(FMath::IsNearlyEqual(TiltRoot.RelativeRotation.Pitch, MinRotation , 0.0001f) || FMath::IsNearlyEqual(TiltRoot.RelativeRotation.Pitch, MaxRotation , 0.0001f))
		{
			if (FMath::Abs(Velocity) > 1)
			{
				Velocity *= -BouncyNess;

				if (!bHitMax)
				{
					if (MaxCooldown == 0)
					{
						UHazeAkComponent::HazePostEventFireForget(HitGroundAudioEvent, GetActorTransform());
						bHitMax = true;
						bLeftMax = false;
						MaxCooldown = 0.5f;
					}
				}
				else
				{
					Velocity = 0;
				}
			}

			else
			{
				Velocity = 0;
			}

		}

		if (VelocityLastFrame == 0 && FMath::Abs(Velocity) > 0 && !bLeftMax)
		{
			if(bHitMax && !bLeftMax)
			{
				bLeftMax = true;
				bHitMax = false;
				UHazeAkComponent::HazePostEventFireForget(StartMovingAudioEvent, GetActorTransform());
				MaxCooldown = 0.5f;
			}
		}

		if (MaxCooldown > 0)
		{
			MaxCooldown -= DeltaTime;

			if (MaxCooldown < 0)
				MaxCooldown = 0;
		}

		VelocityLastFrame = Velocity;
	}
}