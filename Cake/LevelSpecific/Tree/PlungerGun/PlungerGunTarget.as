import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunProjectile;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunLamp;

import bool PlungerGunGameIsActive() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import void PlungerGunPlayHitBark(AHazePlayerCharacter Player) from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import void PlungerGunTargetReachedEdge(APlungerGunTarget Target, bool bFront) from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import FVector PlungerGunGetGameForward() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import AHazePlayerCharacter PlungerGunGetFrontPlayer() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import AHazePlayerCharacter PlungerGunGetBackPlayer() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import void PlungerGunIncreaseTargetCounter() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';
import void PlungerGunDecreaseTargetCounter() from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager';

enum EPlungerGunTargetState
{
	Idle,
	ActiveHidden,
	ActiveShowing,
	Resetting
}

class APlungerGunTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	USceneComponent SwingRoot;

	UPROPERTY(DefaultComponent)
	UPlungerGunResponseComponent ResponseComp;

	UPROPERTY(EditInstanceOnly, Category = "Lane")
	AActor LaneActor;

	UPROPERTY(EditInstanceOnly, Category = "Lane")
	bool bMovingForward = true;

	UPROPERTY(EditInstanceOnly, Category = "Lane")
	float ShowDelay = 0.f;

	EPlungerGunTargetState State = EPlungerGunTargetState::Idle;
	float ResetTimer = 0.f;
	float ShowTimer = 0.f;
	bool bOriginForward = false;

	bool bIsMoving = false;
	bool bIsUpright = false;

	int HitCount = 0;

	FVector GameForward;
	AHazePlayerCharacter PlayerToHurt;

	UPROPERTY(NotEditable)
	FHazeConstrainedPhysicsValue FacingValue;
	default FacingValue.LowerBound = 0.f;
	default FacingValue.LowerBounciness = 0.3f;
	default FacingValue.UpperBound = 180.f;
	default FacingValue.UpperBounciness = 0.3f;

	UPROPERTY(NotEditable)
	FHazeConstrainedPhysicsValue UprightValue;
	default UprightValue.LowerBound = -90.f;
	default UprightValue.LowerBounciness = 0.6f;
	default UprightValue.UpperBound = 0.f;
	default UprightValue.UpperBounciness = 0.6f;
	default UprightValue.Value = 0.f;

	FHazeSplineSystemPosition Position;
	FHazeSplineSystemPosition OriginPosition;

	float MovePauseTimer = 1.f;

	TMap<bool, APlungerGunLamp> Lamps;

	void InitSplineStuff()
	{
		if (LaneActor != nullptr)
		{
			auto Spline = UHazeSplineComponentBase::Get(LaneActor);
			AttachToComponent(Spline);
			ActorRelativeTransform = FTransform();

			OriginPosition = Position = Spline.GetPositionAtDistanceAlongSpline(Spline.SplineLength / 2.f, true);
			MovementRoot.RelativeTransform = Position.RelativeTransform;
		}

		FacingValue.Value = bMovingForward ? FacingValue.LowerBound : FacingValue.UpperBound;
		SwingRoot.RelativeRotation = FRotator(UprightValue.Value, FacingValue.Value, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		InitSplineStuff();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitSplineStuff();

		ResponseComp.OnHit.AddUFunction(this, n"HandlePlungerHit");
		SwingRoot.SetRelativeRotation(FRotator(UprightValue.LowerBound, 0.f, 0.f));

		bOriginForward = bMovingForward;
		GameForward = PlungerGunGetGameForward();

		ShowTimer = ShowDelay;
		HitCount = 0;

		// Find the lamps attached to the lane
		if (LaneActor != nullptr)
		{
			TArray<AActor> LaneChildren;
			LaneActor.GetAttachedActors(LaneChildren, false);

			for(auto Child : LaneChildren)
			{
				auto Lamp = Cast<APlungerGunLamp>(Child);
				if (Lamp == nullptr)
					return;

				// Add lamps to lamp-map
				Lamps.Add(Lamp.bForward, Lamp);
			}
		}
	}

	UFUNCTION()
	void HandlePlungerHit(AHazePlayerCharacter PlungerOwner, FTransform RelativeTransform)
	{
		if (State != EPlungerGunTargetState::ActiveShowing)
			return;

		if (PlungerOwner != PlayerToHurt)
			return;

		if (!PlungerOwner.HasControl())
			return;

		BP_OnHit();
		NetChangeDirection(Position);
		PlungerGunPlayHitBark(PlungerOwner);
	}

	UFUNCTION(NetFunction)
	void NetChangeDirection(FHazeSplineSystemPosition TurnPosition)
	{
		bMovingForward = !bMovingForward;
		HitCount++;
		MovePauseTimer = 1.f;

		// Add an initial spin impulse
		FacingValue.AddImpulse((bMovingForward ? -1.f : 1.f) * 500.f);

		Position = TurnPosition;
		PlayerToHurt = bMovingForward ? PlungerGunGetFrontPlayer() : PlungerGunGetBackPlayer();

		BP_OnTurnAround();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bMovedThisFrame = false;
		bool bUprightThisFrame = ShouldBeUpright();

		if (bUprightThisFrame != bIsUpright)
		{
			if (bUprightThisFrame)
				BP_OnStandUp();
			else
				BP_OnLayDown();

			bIsUpright = bUprightThisFrame;
		}

		UprightValue.AccelerateTowards(ShouldBeUpright() ? UprightValue.UpperBound : UprightValue.LowerBound, 800.f);
		UprightValue.Update(DeltaTime);

		FacingValue.AccelerateTowards(bMovingForward ? FacingValue.LowerBound : FacingValue.UpperBound, 800.f);
		FacingValue.Update(DeltaTime);

		switch(State)
		{
			// Don't do anything :^)
			case EPlungerGunTargetState::Idle:
			{
				break;
			}

			// Game is active, we're waiting to spring to action...
			case EPlungerGunTargetState::ActiveHidden:
			{
				ShowTimer -= DeltaTime;
				if (ShowTimer <= 0.f)
				{
					State = EPlungerGunTargetState::ActiveShowing;
					PlungerGunIncreaseTargetCounter();
				}

				break;
			}

			// Hunt the players
			case EPlungerGunTargetState::ActiveShowing:
			{
				MovePauseTimer -= DeltaTime;
				if (MovePauseTimer < 0.f)
				{
					float SpeedIncreaseAlpha = float(HitCount) / PlungerGun::TargetSpeedIncreaseHitCount;
					SpeedIncreaseAlpha = Math::Saturate(SpeedIncreaseAlpha);

					float Speed = FMath::Lerp(PlungerGun::TargetSpeed_Min, PlungerGun::TargetSpeed_Max, SpeedIncreaseAlpha);
					if (!bMovingForward)
						Speed = -Speed;

					float RubberBandMultiplier = FMath::Lerp(PlungerGun::TargetRubberBandFactor, 1.f, GetFractionTraveled());
					Speed *= RubberBandMultiplier;

					bool bSuccess = Position.Move(Speed * DeltaTime);

					// If the move didn't succeed, we've hit an edge!
					if (!bSuccess && PlayerToHurt.HasControl())
						NetHitEdge(bMovingForward);

					MovementRoot.RelativeTransform = Position.RelativeTransform;

					BP_OnMove(Speed / PlungerGun::TargetMaxSpeed);
					bMovedThisFrame = true;
				}
				break;
			}

			// Reset to the middle
			case EPlungerGunTargetState::Resetting:
			{
				// If we're the target that lost someone the game, delay a bit before resetting
				ResetTimer -= DeltaTime;

				if (ResetTimer <= 0.f)
				{
					bMovingForward = bOriginForward;

					float DistToOrigin = Position.DistanceClosest(OriginPosition);
					float DeltaMove = PlungerGun::TargetResetSpeed * DeltaTime;

					// Oh! We're closer to origin than our delta move. We've finished resetting!
					if (FMath::Abs(DistToOrigin) < DeltaMove)
					{
						PlayerToHurt = bMovingForward ? PlungerGunGetFrontPlayer() : PlungerGunGetBackPlayer();
						Position = OriginPosition;

						if (PlungerGunGameIsActive())
						{
							State = EPlungerGunTargetState::ActiveShowing;
						}
						else
						{
							State = EPlungerGunTargetState::Idle;
							PlungerGunDecreaseTargetCounter();
						}
						break;
					}

					// Make sure we're moving in the right direction...
					DeltaMove *= FMath::Sign(DistToOrigin);
					Position.Move(DeltaMove);

					BP_OnMove(PlungerGun::TargetResetSpeed / PlungerGun::TargetMaxSpeed);
					bMovedThisFrame = true;
				}
				break;
			}
		}

		MovementRoot.RelativeTransform = Position.RelativeTransform;
		MovementRoot.SetWorldRotation(Math::MakeQuatFromXZ(GameForward, Position.WorldUpVector));
		SwingRoot.RelativeRotation = FRotator(UprightValue.Value, FacingValue.Value, 0.f);

		if (bIsMoving != bMovedThisFrame)
		{
			if (bMovedThisFrame)
				BP_OnStartMoving();
			else
				BP_OnStopMoving();

			bIsMoving = bMovedThisFrame;
		}
	}

	bool ShouldBeUpright()
	{
		if (State == EPlungerGunTargetState::ActiveShowing)
			return true;

		if (State == EPlungerGunTargetState::Resetting && ResetTimer > 0.f)
			return true;

		return false;
	}

	void ActivateTarget()
	{
		State = EPlungerGunTargetState::ActiveHidden;
		PlayerToHurt = bMovingForward ? PlungerGunGetFrontPlayer() : PlungerGunGetBackPlayer();
	}

	float GetFractionTraveled()
	{
		float Distance = Position.DistanceAlongSpline;
		float SplineLen = Position.Spline.SplineLength;

		float Fraction = Distance / SplineLen;
		if (!bMovingForward)
			Fraction = 1.f - Fraction;

		return Fraction;
	}

	void ResetTarget()
	{
		if (State == EPlungerGunTargetState::Idle)
			return;

		State = EPlungerGunTargetState::Resetting;
		ShowTimer = ShowDelay;
		HitCount = 0;
	}

	UFUNCTION(NetFunction)
	void NetHitEdge(bool bForward)
	{
		PlungerGunTargetReachedEdge(this, bForward);
		ResetTimer = PlungerGun::TargetEdgeResetDelay;

		ResetTarget();
		BP_OnReachEnd(bForward);

		// Light up the lamp corresponding to this edge of the lane
		auto Lamp = Lamps[bForward];
		Lamp.LightUp();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnReachEnd(bool bFront)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnHit()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStandUp()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnLayDown()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartMoving()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnMove(float Speed)
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnStopMoving()
	{

	}

	UFUNCTION(BlueprintEvent)
	void BP_OnTurnAround()
	{

	}
}