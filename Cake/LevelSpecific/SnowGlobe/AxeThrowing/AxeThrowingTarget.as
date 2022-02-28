import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingSpline;

event void FScoreHit(AAxeThrowingTarget Target, float Points, bool bIsDoublePoints);

enum ETargetType
{
	OneWay,
	WallLeft,
	WallRight,
	Still
};

enum EPointWorth
{
	Normal,
	Special,
};

class AAxeThrowingTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent OrientationRoot;

	UPROPERTY(DefaultComponent, Attach = OrientationRoot)
	UStaticMeshComponent MeshBase; 

	UPROPERTY(DefaultComponent, Attach = OrientationRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshCompPole;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Setup")
	UStaticMesh MeshOnePoints;

	UPROPERTY(Category = "Setup")
	UStaticMesh MeshTwoPoints;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem DoublePointsSystem;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartMovement;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EndMovement;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RaiseTarget;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent LowerTarget;

	FVector WorldForward;

	FScoreHit OnScoreHitEvent;

	AAxeThrowingSpline Lane;

	AHazePlayerCharacter PlayerOwner;

	FHazeAcceleratedFloat AudioAccelValue;

	bool bIsActive = false;
	bool bIsTutorial;
	bool bHasBeenHit;
	bool bIsSpeedUp = false;
	bool bGameIsEnded;

	EPointWorth PointWorth;
	FHazeSplineSystemPosition LanePosition;
	FHazeSplineSystemPosition BacknForthStartPosition;

	FHazeConstrainedPhysicsValue HitRotation;
	default HitRotation.UpperBound = 90.f;
	default HitRotation.LowerBound = 0.f;

	float HitDisableTimer = 0.f;
	const float HitDisableDelay = 5.f;

	const float SpecialSpeedMultiplier = 1.3f;
	const float FastSpeedMultiplier = 1.5f;
	const float DoublePointSpeedMultiplier = 1.25f;
	float SpeedMultiplier = 1.f;

	float StartingTargetRelativeHeight;
	float SideTargetRelativeHeight;
	float SideRelativeOffsetAmount = 40.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableActor(this);
		StartingTargetRelativeHeight = MeshComp.RelativeLocation.Z;
		SideTargetRelativeHeight = StartingTargetRelativeHeight - SideRelativeOffsetAmount;
		AudioAccelValue.SnapTo(0.f);
	}

	void TargetEndGame()
	{
		bGameIsEnded = true;
	}

	void TargetSidewaysSetting(float Roll)
	{
		OrientationRoot.SetRelativeRotation(FRotator(0.f, 0.f, Roll));
		MeshComp.SetRelativeLocation(FVector(MeshComp.RelativeLocation.X, MeshComp.RelativeLocation.Y, SideTargetRelativeHeight));
	}

	void TargetUprightSettingReturn()
	{
		OrientationRoot.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));
		MeshComp.SetRelativeLocation(FVector(MeshComp.RelativeLocation.X, MeshComp.RelativeLocation.Y, StartingTargetRelativeHeight));
	}

	void ActivateInternal(EPointWorth InPointWorth, bool bInTutorial)
	{
		ensure(!bIsActive);

		bIsActive = true;
		bHasBeenHit = false;
		EnableActor(this);

		PointWorth = InPointWorth;
		bIsTutorial = bInTutorial;
		HitRotation.SnapTo(HitRotation.UpperBound, true);
		HitDisableTimer = 0.f;
		SpeedMultiplier = bIsSpeedUp ? FastSpeedMultiplier : 1.f;

		if (PointWorth == EPointWorth::Normal)
			MeshComp.SetStaticMesh(MeshOnePoints);
		else
			MeshComp.SetStaticMesh(MeshTwoPoints);
	}

	void ActivateTarget(AAxeThrowingSpline InLane, EPointWorth InPointWorth, bool bInTutorial)
	{
		ActivateInternal(InPointWorth, bInTutorial);
		Lane = InLane;
		Lane.CurrentTargetCount++;

		AudioStartTargetMovement();

		if (Lane.bBackAndForth)
		{
			BacknForthStartPosition = InLane.Spline.GetPositionAtEnd(true);
			LanePosition = InLane.Spline.GetPositionAtEnd(true);
		}
		else
			LanePosition = InLane.Spline.GetPositionAtStart(true);

		AttachToComponent(InLane.Spline, NAME_None, EAttachmentRule::KeepWorld);
		RootComponent.RelativeLocation = LanePosition.RelativeLocation;
		ActorRotation = Math::MakeRotFromX(WorldForward);

		if (InLane.TargetOrientation == EAxeThrowingTargetOrientation::SidewaysRightSide)
			TargetSidewaysSetting(90.f);
		else if (InLane.TargetOrientation == EAxeThrowingTargetOrientation::SidewaysLeftSide)
			TargetSidewaysSetting(-90.f);
	}

	void ActivateTarget(USceneComponent AttachComp, EPointWorth InPointWorth, bool bInTutorial)
	{
		ActivateInternal(InPointWorth, bInTutorial);
		AttachToComponent(AttachComp, NAME_None, EAttachmentRule::SnapToTarget);
		ActorRotation = Math::MakeRotFromX(WorldForward);

		if (bInTutorial)
			AudioRaiseTarget();
	}

	UFUNCTION()
	void DeactivateTarget()
	{
		ensure(bIsActive);

		AudioEndTargetMovement();

		bIsActive = false;
		
		if (!IsActorDisabled())
			DisableActor(this);

		bHasBeenHit = false;

		DetachRootComponentFromParent();
		
		TargetUprightSettingReturn();

		if (Lane != nullptr)
		{
			Lane.CurrentTargetCount--;
			Lane = nullptr;
		}
	}

	void TargetHit(bool bIsDoublePoints)
	{
		if (!bIsActive)
			return;

		if (bHasBeenHit)
			return;

		int PointsToGive;

		if (PointWorth == EPointWorth::Normal)
			PointsToGive = 1;
		else
			PointsToGive = 2;

		if (bIsDoublePoints)
		{
			PointsToGive *= 2;
			Niagara::SpawnSystemAtLocation(DoublePointsSystem, MeshComp.WorldLocation, MeshComp.WorldRotation, FVector(0.2f));
		}

		if (PlayerOwner.HasControl())
			NetHitWithScore(PointsToGive, bIsDoublePoints);

		bHasBeenHit = true;
		HitRotation.AddImpulse(190.f);

		AudioLowerTarget();
	}

	void TutorialGameEnded()
	{
		HitRotation.AddImpulse(190.f);
		System::SetTimer(this, n"DeactivateTarget", 1.f, false);
	}

	UFUNCTION(NetFunction)
	void NetHitWithScore(int Points, bool bIsDoublePoints)
	{
		OnScoreHitEvent.Broadcast(this, Points, bIsDoublePoints);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Disable if we were hit...
		if (bHasBeenHit)
		{
			HitDisableTimer += DeltaTime;
			if (HitDisableTimer >= HitDisableDelay)
			{
				DeactivateTarget();
				return;
			}
		}

		// Update movement if we have a lane
		if (Lane != nullptr)
		{
			if (bIsSpeedUp)
				AudioSetMovementRTCP(1.25f);
			else
				AudioSetMovementRTCP(1.f);

			if (bIsSpeedUp)
				SpeedMultiplier = FMath::Lerp(SpeedMultiplier, FastSpeedMultiplier, 4.f * DeltaTime);

			float Speed = Lane.TargetSpeed * SpeedMultiplier;

			if (PointWorth == EPointWorth::Special)
				Speed *= DoublePointSpeedMultiplier;

			bool bResult = LanePosition.Move(Speed * DeltaTime);

			float Diff = (LanePosition.RelativeLocation - BacknForthStartPosition.RelativeLocation).Size();
			
			// PreLanePosition = Lane.Spline.GetTransformAtSplinePoint()

			// We hit the edge
			if (!bResult)
			{
				if (Lane.bBackAndForth)
				{
					if (bGameIsEnded && Diff <= 45.f)
					{
						DeactivateTarget();
						bGameIsEnded = false;
					}
					else
					{
						LanePosition.Reverse();
					}
				}
				else
					DeactivateTarget();
			}

			// SetActorRelativeLocation is annoying...
			RootComponent.RelativeLocation = LanePosition.RelativeLocation;
			ActorRotation = Math::MakeRotFromX(WorldForward);
		}

		// Add some juiciness to when the target is hit
		if (bHasBeenHit)
			HitRotation.AccelerateTowards(HitRotation.UpperBound, 500.f);
		else
			HitRotation.AccelerateTowards(HitRotation.LowerBound, 500.f);
		HitRotation.Update(DeltaTime);

		MeshRoot.SetRelativeRotation(FRotator(HitRotation.Value, 0.f, 0.f));
	}

	void AudioStartTargetMovement()
	{
		AkComp.HazePostEvent(StartMovement);
	}

	void AudioEndTargetMovement()
	{
		AkComp.HazePostEvent(EndMovement);
	}

	void AudioSetMovementRTCP(float Value)
	{
		AudioAccelValue.SnapTo(Value);
		AkComp.SetRTPCValue("Rtpc_SideContent_Snowglobe_Minigame_IcicleThrowing_Target_Movement", AudioAccelValue.Value);
	}

	void AudioRaiseTarget()
	{
		Print("AudioRaiseTarget");
		AkComp.HazePostEvent(RaiseTarget);
	}

	void AudioLowerTarget()
	{
		Print("AudioLowerTarget");
		AkComp.HazePostEvent(LowerTarget);
	}
}