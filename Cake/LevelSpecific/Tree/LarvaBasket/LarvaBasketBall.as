import Vino.Pickups.PickupActor;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketSettings;

import void LarvaBasketPlayerMissedBall(AHazePlayerCharacter Player, ALarvaBasketBall Ball) from 'Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent';
import void LarvaBasketPlayMissBark(AHazePlayerCharacter Player) from 'Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager';
import bool LarvaBasketGameIsActive() from 'Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager';

class ALarvaBasketBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;

	UPROPERTY(DefaultComponent)
	UDecalComponent ShadowDecal;

	UPROPERTY(DefaultComponent)
	UTrajectoryDrawer TrajectoryDrawer;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter PlayerOwner;

	bool bIsActive = false;
	bool bIsHeld = true;
	FVector Velocity;

	float LifeTime = 0.f;
	bool bHaveBounced = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableActor(this);
	}

	void ActivateBall()
	{
		if (bIsActive)
			return;

		EnableActor(this);
		bIsActive = true;
		bIsHeld = true;
		bHaveBounced = false;

		OnActivateBall();
	}

	void ThrowBall(FTransform Origin, FVector Impulse)
	{
		DetachRootComponentFromParent();

		ActorTransform = Origin;
		Velocity = Impulse;

		bIsHeld = false;
		LifeTime = 0.f;

		OnThrowBall();
	}

	void DeactivateBall()
	{
		if (!bIsActive)
			return;

		DisableActor(this);
		bIsActive = false;

		DetachRootComponentFromParent();

		OnDeactivateBall();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsHeld)
			return;

		LifeTime += DeltaTime;
		Velocity -= FVector::UpVector * LarvaBasket::BallGravity * DeltaTime;

		// Trace until we hit an obstacle once, then just move
		if (!bHaveBounced)
		{
			FHazeTraceParams Trace;
			Trace.InitWithPrimitiveComponent(SphereComp);
			Trace.From = ActorLocation;
			Trace.To = ActorLocation + Velocity * DeltaTime;

			FHazeHitResult Hit;
			Trace.Trace(Hit);

			if (Hit.bBlockingHit)
				HandleHit(Hit.FHitResult);

			ActorLocation = Trace.To;
		}
		else
		{
			ActorLocation = ActorLocation + Velocity * DeltaTime;
		}

		// Trace to the ground to place the shadow
		{
			FHazeTraceParams Trace;
			Trace.InitWithPrimitiveComponent(SphereComp);
			Trace.From = ActorLocation;
			Trace.To = ActorLocation - FVector::UpVector * 9000.f;

			FHazeHitResult GroundHit;
			Trace.Trace(GroundHit);

			if (GroundHit.bBlockingHit)
			{
				ShadowDecal.WorldLocation = GroundHit.FHitResult.Location;
				ShadowDecal.WorldRotation = Math::MakeRotFromX(GroundHit.Normal);
			}
		}

		if (LifeTime > LarvaBasket::BallTotalLifeDuration)
			DeactivateBall();
	}

	void HandleHit(FHitResult Hit)
	{
		if (LifeTime < LarvaBasket::BallIgnoreHitDuration)
			return;

		// Pullback a lot!
		float Time = Hit.Time;
		Time = FMath::Max(Time - 0.2f, 0.f);

		// Constrain normal to a perfect cylinder
		FVector CylinderNormal = Hit.Normal.ConstrainToPlane(FVector::UpVector);
		CylinderNormal.Normalize();

		Velocity = FMath::GetReflectionVector(Velocity, CylinderNormal) * LarvaBasket::BallBounciness;
		Velocity += FVector(0.f, 0.f, LarvaBasket::BallBounceUpImpulse);
		ActorLocation = FMath::Lerp(Hit.TraceStart, Hit.TraceEnd, Time);

		LarvaBasketPlayerMissedBall(PlayerOwner, this);

		if (LarvaBasketGameIsActive())
			LarvaBasketPlayMissBark(PlayerOwner);

		bHaveBounced = true;
	}

	UFUNCTION(BlueprintEvent)
	void OnThrowBall() {}

	UFUNCTION(BlueprintEvent)
	void OnActivateBall() {}

	UFUNCTION(BlueprintEvent)
	void OnDeactivateBall() {}
}
