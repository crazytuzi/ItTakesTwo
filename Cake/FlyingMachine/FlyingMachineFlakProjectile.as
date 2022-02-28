import Cake.FlyingMachine.FlyingMachineSettings;

event void OnFlakHit(AActor HitActor, FVector RelativeLocation);
event void OnFlakHittableHit(AFlyingMachineFlakProjectile Projectile, UPrimitiveComponent HitComponent);

class UFlyingMachineFlakHittableComponent : UActorComponent
{
	UPROPERTY()
	OnFlakHittableHit OnHit;
}

class AFlyingMachineFlakProjectile : AHazeActor
{
	bool bIsActive = false;
	bool bIsControlSide = false;
	bool bHasHit = false;

	UPROPERTY(Category = "Effects")
	float FadeOutDuration = 2.f;

	float TimeoutTimer = 10.f;

	// Called when the flak projectile hits something
	OnFlakHit OnHit;
	AActor IgnoredOwner;

	FFlyingMachineGunnerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableActor(this);
	}

	void InitializeProjectile(FVector Source, FVector Forward, bool bControlSide, FVector InheritedVelocity)
	{
		bIsActive = true;

		SetActorLocation(Source);
		SetActorRotation(Math::MakeRotFromX(Forward));
		bIsControlSide = bControlSide;

		TimeoutTimer = 10.f;
		FadeOutDuration = 2.f;
		bHasHit = false;
		IsFirstFrame = true;

		BP_OnInitialize(Source, Forward, InheritedVelocity);
		EnableActor(this);
	}

	void DeactivateProjectile()
	{
		bIsActive = false;
		DisableActor(this);
	}

	bool IsFirstFrame = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Dont move for one frame... this is to give the niagara effects time to start up
		if (IsFirstFrame)
		{
			IsFirstFrame = false;
			return;	
		}

		if (!bHasHit)
		{
			// Timeout timer
			TimeoutTimer -= DeltaTime;
			if (TimeoutTimer < 0.f)
			{
				bHasHit = true;
				return;
			}

			FVector Loc = ActorLocation;
			FVector Delta = ActorForwardVector * Settings.FlakProjectileSpeed * DeltaTime;
			
			if (bIsControlSide)
			{
				TArray<AActor> IgnoreActors;
				IgnoreActors.Add(Game::GetMay());
				IgnoreActors.Add(Game::GetCody());
				IgnoreActors.Add(IgnoredOwner);

				FHitResult Hit;
				System::LineTraceSingle(Loc, Loc + Delta, ETraceTypeQuery::WeaponTrace, false, IgnoreActors, EDrawDebugTrace::None, Hit, true);

				if (Hit.bBlockingHit)
				{
					// Transform hit into local-space, so that the impact happens on the same object over network
					FVector RelativeHitLocation;
					RelativeHitLocation = Hit.Component.WorldTransform.InverseTransformPosition(Hit.ImpactPoint);

					NetTriggerHit(Hit.Actor, Hit.Component, RelativeHitLocation, Hit.ImpactNormal);
				}
			}

			// If nothing was hit this frame, just move forward
			if (!bHasHit)
			{
				AddActorWorldOffset(Delta);
			}
		}
		else
		{
			FadeOutDuration -= DeltaTime;
			if (FadeOutDuration <= 0.f)
			{
				DeactivateProjectile();
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetTriggerHit(AActor HitActor, UPrimitiveComponent HitComponent, FVector RelativeLocation, FVector Normal)
	{
		if (HitActor != nullptr)
		{
			// Call events on flak hittable actors
			auto Hittable = UFlyingMachineFlakHittableComponent::Get(HitActor);
			if (Hittable != nullptr)
			{
				Hittable.OnHit.Broadcast(this, HitComponent);
			}
		}

		FVector WorldHitLocation = ActorLocation;
		if (HitComponent != nullptr)
			WorldHitLocation  = HitComponent.WorldTransform.TransformPosition(RelativeLocation);

		SetActorLocation(WorldHitLocation);
		BP_PlayHitEffect(HitComponent, WorldHitLocation, Normal);
		bHasHit = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnInitialize(FVector Origin, FVector Direction, FVector InheritedVelocity)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_PlayHitEffect(UPrimitiveComponent HitComponent, FVector Location, FVector Normal)
	{
	}


}