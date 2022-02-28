import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunSettings;

event void FPlungerGunOnHit(AHazePlayerCharacter Player, FTransform RelativeTransform);

class UPlungerGunResponseComponent : UActorComponent
{
	FPlungerGunOnHit OnHit;
}

class APlungerGunProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent StemRoot;

	AHazePlayerCharacter PlayerOwner;
	FVector Velocity = FVector::ZeroVector;
	bool bHasHit = false;

	float StickTimer = PlungerGun::ProjectileLifetime;

	const float StemAcceleration = 1400.f;
	const float StemFriction = 8.6f;
	FVector StemVelocity;

	void ActivateProjectile(AHazePlayerCharacter Player, FTransform Transform, float Charge)
	{
		PlayerOwner = Player;
		ActorTransform = Transform;
		Velocity = ActorForwardVector * FMath::Lerp(
			PlungerGun::ProjectileSpeedMin,
			PlungerGun::ProjectileSpeedMax,
			Charge
		);

		StickTimer = PlungerGun::ProjectileLifetime;
		bHasHit = false;

		StemRoot.RelativeRotation = FRotator();
		StemVelocity = FVector::ZeroVector;

		EnableActor(this);
	}

	void DeactivateProjectile()
	{
		DetachRootComponentFromParent();
		DisableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bHasHit)
		{
			Velocity -= FVector::UpVector * PlungerGun::ProjectileGravity * DeltaTime;

			FVector Loc = ActorLocation;
			FVector Delta = Velocity * DeltaTime;

			FHazeTraceParams Trace;
			Trace.From = ActorLocation;
			Trace.SetToSphere(30.f);
			Trace.SetToWithDelta(Velocity * DeltaTime);
			Trace.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
			Trace.IgnoreActor(Game::Cody);
			Trace.IgnoreActor(Game::May);

			FHazeHitResult Hit;
			Trace.Trace(Hit);

			if (Hit.bBlockingHit)
			{
				FTransform Transform;
				Transform.Location = Hit.ImpactPoint;
				Transform.Rotation = Math::MakeQuatFromX(-Hit.Normal);

				Transform = Transform.GetRelativeTransform(Hit.Component.WorldTransform);

				// Control side does the ACTUAL hit
				// PlayerOwner _caaan_ be null in some circumstaces, like a the very end of a match
				if (PlayerOwner != nullptr && PlayerOwner.HasControl())
					NetHitSurface(Hit.Component, Transform);

				// Otherwise just predict :^)
				else
					HandleSurfaceHit(Hit.Component, Transform);
			}
			else
			{
				ActorLocation = ActorLocation + Velocity * DeltaTime;
				ActorRotation = Math::MakeRotFromX(Velocity);
			}
		}
		else
		{
			// A bit of a mess...
			// All of this is to animate the stem to spring into place
			FVector StemForward = StemRoot.ForwardVector;
			FVector CupForward = ActorForwardVector;

			// Accelerate towards being straight
			FVector SpringForce = StemForward.CrossProduct(CupForward);
			StemVelocity += SpringForce * StemAcceleration * DeltaTime;

			// Add friction
			StemVelocity -= StemVelocity * StemFriction * DeltaTime;

			// Add velocity to the world rotation
			FQuat DeltaQuat = FQuat(StemVelocity.GetSafeNormal(), StemVelocity.Size() * DeltaTime);
			FQuat StemQuat = StemRoot.WorldRotation.Quaternion();

			StemQuat = DeltaQuat * StemQuat;
			StemRoot.WorldRotation = StemQuat.Rotator();

			StickTimer -= DeltaTime;
			if (StickTimer <= 0.f)
				DeactivateProjectile();
		}
	}

	// The reason there are two functions:
	// One is called locally from both sides! To predict a hit and stick.
	// The network version is called from the owning players' control side! To determine a final
	// ACTUAL hitting location.
	// And we want that to ALWAYS fire, even if the predict-function has already been called once
	UFUNCTION(NetFunction)
	void NetHitSurface(UPrimitiveComponent HitComponent, FTransform RelativeTransform)
	{
		// Handle hit-responses here, so predicted hits dont trigger gameplay stuff
		if (HitComponent.Owner != nullptr)
		{
			auto ResponseComp = UPlungerGunResponseComponent::Get(HitComponent.Owner);
			if (ResponseComp != nullptr)
			{
				ResponseComp.OnHit.Broadcast(PlayerOwner, RelativeTransform);
			}
		}

		HandleSurfaceHit(HitComponent, RelativeTransform);
	}

	void HandleSurfaceHit(UPrimitiveComponent HitComponent, FTransform RelativeTransform)
	{
		// We want the "stem" to keep its world-rotation after attachment, then we'll spring it upwards after rotating the actual cup
		FRotator PreviousRotation = StemRoot.WorldRotation;

		AttachToComponent(HitComponent, NAME_None, EAttachmentRule::KeepRelative);
		SetActorRelativeTransform(RelativeTransform);

		// Restore rotation
		StemRoot.WorldRotation = PreviousRotation;

		bHasHit = true;
		BP_OnHitSurface(HitComponent, HitComponent.WorldTransform * RelativeTransform);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnHitSurface(UPrimitiveComponent Component, FTransform Transform) {}
}