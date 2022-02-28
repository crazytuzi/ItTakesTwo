import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.CannonBallActor;
import Peanuts.Aiming.AutoAimStatics;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Trajectory.TrajectoryDrawer;

//import bool CheckIfIsInBossFight(AHazePlayerCharacter Player) from "Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.OnWheelBoatComponent";

UCLASS(Abstract)
class AToyCannonActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CannonShootFromPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FireEffectAttachPoint;
	
	// UPROPERTY(DefaultComponent, Attach = Root)
	// UArrowComponent CannonSpeedArrow;	
    // default CannonSpeedArrow.SetHiddenInGame(true);

	UPROPERTY()
	TSubclassOf<ACannonBallActor> CannonBallClass;

	UPROPERTY(DefaultComponent)
	UTrajectoryDrawer TrajectoryDrawer;

	UPROPERTY(DefaultComponent)
	USceneComponent Crosshair;
	default Crosshair.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent AkComponent;
	
	UPROPERTY()
	FRotator RightWheelRot = FRotator(0,0,90);

	UPROPERTY()
	FRotator LeftWheelRot = FRotator(0,0,90);

	const float _SpeedToAdd = 80000; //How quickly the aim accelerates when holding the button
	const float _MaxCannonSpeed = 10200; //Max speed of the cannon ball - WHY? //Cause it decides the max shooting length!
	const float _MinCannonSpeed = 2250; //Min speed of the cannon ball
	private float _CannonCurrentSpeed = 2250; //The current speed of the cannon ball, which is changed by how long the button is held.
	float CanonSpeedMultiplier = 1.f; // Variable for editing the cannon ball

	float ArrowCurrentSize = 1;
	const float MinArrowSize = 1;
	const float MaxArrowSize = 7;

	const float Gravity = 5200;

	float SpeedPercentage;
	FRotator SavedRotation;
	
	UPROPERTY(Category = "Properties")
	UNiagaraSystem FireEffect;

	// UPROPERTY(Category = "Properties")
	// FVector SpawnEffectLocationOffset = FVector::ZeroVector;

	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> ShootCameraShake;

	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect LowShootForceFeedback;
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect MediumShootForceFeedback;

	UCameraShakeBase CurrentActiveShake = nullptr;	

	AHazeActor ParentBoat;
	private AActor WaveActorToIgnore;	
	AHazePlayerCharacter Player;

	const int AmountOfContainedCannonBalls = 10;
	TArray<ACannonBallActor> CannonBallContainer;
	int CurrentCannonBallIndex = 0;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CannonWheelBoatAimCrankLoopStartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CannonWheelBoatAimCrankLoopStopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CannonWheelBoatFireEvent;

	FHitResult TrajectoryHitResult;
	bool bRequestedInput = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Crosshair.SetHiddenInGame(true, true);
	}

	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(ACannonBallActor CannonBall : CannonBallContainer)
		{
			if(CannonBall != nullptr)
			{
				CannonBall.DestroyCannonBall();	
			}
		}

		CannonBallContainer.Empty();
	}

	void InitializeCanonBalls(AActor ControllingSide, AHazePlayerCharacter ControllingPlayer)
	{
		for(int i = 0; i < AmountOfContainedCannonBalls; ++i)
		{
			auto CannonBall = Cast<ACannonBallActor>(SpawnPersistentActor(CannonBallClass, bDeferredSpawn = true));
			CannonBall.MakeNetworked(this, i);
			CannonBallContainer.Add(CannonBall);
			CannonBall.TraceIgnoreActors.Add(this);
			CannonBall.TraceIgnoreActors.Add(ParentBoat);
			CannonBall.SetControlSide(ControllingSide);
			FinishSpawningActor(CannonBall);
			CannonBall.Initialize(this, ControllingPlayer);
		}
	}
	
	AHazeActor GetWheelBoatActor()const property
	{
		return ParentBoat;
	}

	void SetWaveActor(AActor Wave) property
	{
		for(auto CannonBall : CannonBallContainer)
		{
			if(CannonBall != nullptr)
			{
				if(Wave != nullptr)
					CannonBall.TraceIgnoreActors.Add(Wave);
				else
					CannonBall.TraceIgnoreActors.Remove(WaveActorToIgnore);
			}			
		}

		WaveActorToIgnore = Wave;
	}

	void ResetCannonSpeed()
	{
		_CannonCurrentSpeed = MinCannonSpeed;
		//CannonSpeedArrow.SetWorldScale3D(MinArrowSize);
	}

	void AddSpeedToCannon(float DeltaTime)
	{
		_CannonCurrentSpeed += _SpeedToAdd * DeltaTime;
		_CannonCurrentSpeed = FMath::Clamp(_CannonCurrentSpeed, MinCannonSpeed, MaxCannonSpeed);
		SpeedPercentage = _CannonCurrentSpeed / MaxCannonSpeed;
	}

	float GetMinCannonSpeed()const property
	{
		return _MinCannonSpeed * CanonSpeedMultiplier;
	}

	float GetMaxCannonSpeed()const property
	{
		return _MaxCannonSpeed * CanonSpeedMultiplier;
	}

	float GetCannonCurrentSpeed() const property
	{
		return _CannonCurrentSpeed;
	}

	void ScaleArrowWithSpeed(float Speed)
	{	
		const float TrajectorySize = 3000.0f;

		FTrajectoryPoints Points;

		FVector Direction;
		Direction = CannonShootFromPoint.GetForwardVector();	
		Points = CalculateTrajectory(CannonShootFromPoint.WorldLocation, TrajectorySize, Direction * Speed, Gravity, 1.0f);

		float TraceSize = 0;
		FHazeTraceParams Trace;
		CannonBallContainer[CurrentCannonBallIndex].GetTraceParams(Trace);
		Trace.SetToLineTrace();

		const int MiddleIndex = FMath::CeilToInt(Points.Positions.Num() * 0.5f);
		const int EndIndex = Points.Positions.Num() - 1;

		Trace.From = Points.Positions[0];
		Trace.To =  Points.Positions[MiddleIndex];

		bool bFoundImpact = false;
		FHazeHitResult HazeHit;

		if(!bFoundImpact) // DO EXTRA TRACE FOR INVISIBLE WALLS
		{
			FHazeTraceParams ExtraTrace;
			ExtraTrace.InitWithTraceChannel(ETraceTypeQuery::ETraceTypeQuery_MAX);
			ACannonBallActor BallToShoot = CannonBallContainer[CurrentCannonBallIndex];
			ExtraTrace.IgnoreActors(BallToShoot.TraceIgnoreActors);
			ExtraTrace.SetToSphere(BallToShoot.CollisionSize);
			ExtraTrace.SetToLineTrace();

			ExtraTrace.From = Points.Positions[0];
			ExtraTrace.To =  Points.Positions[MiddleIndex];

			bFoundImpact = ExtraTrace.Trace(HazeHit);
			if(!bFoundImpact)
			{
				TraceSize = ExtraTrace.From.Distance(ExtraTrace.To);
				ExtraTrace.From = Points.Positions[MiddleIndex];
				ExtraTrace.To = Points.Positions[EndIndex];
				bFoundImpact = ExtraTrace.Trace(HazeHit);
				
			}
			if(bFoundImpact)
			{
				if(HazeHit.Component.GetCollisionProfileName() == n"InvisibleWall")
				{
					bFoundImpact = true;
				}
				else
				{
					bFoundImpact = false;
				}
			}
		}	

		if(!bFoundImpact)
		{
			bFoundImpact = Trace.Trace(HazeHit);
			if(!bFoundImpact)
			{
				TraceSize = Trace.From.Distance(Trace.To);
				Trace.From = Points.Positions[MiddleIndex];
				Trace.To = Points.Positions[EndIndex];
				bFoundImpact = Trace.Trace(HazeHit);
			} 
		}

		if(bFoundImpact)
		{
			TraceSize += HazeHit.Distance;
			TrajectoryHitResult = HazeHit.FHitResult;
			Crosshair.SetHiddenInGame(false, true);
			FVector ImpactDireaction = (ParentBoat.GetActorLocation() - TrajectoryHitResult.ImpactPoint).ConstrainToPlane(FVector::UpVector).GetSafeNormal();	
			Crosshair.SetWorldLocationAndRotation(TrajectoryHitResult.Location, Math::MakeRotFromX(TrajectoryHitResult.Normal));
		}
		else
		{
			TrajectoryHitResult = FHitResult();
			Crosshair.SetHiddenInGame(true, true);
		}

		TrajectoryDrawer.DrawTrajectory(CannonShootFromPoint.WorldLocation, TraceSize, Direction * Speed, Gravity, 20.0f, FLinearColor::White, nullptr, TraceSize / 500.0f, 0.8f);
	
	}

	void HideAimGui()
	{
		TrajectoryHitResult = FHitResult();
		Crosshair.SetHiddenInGame(true, true);
	}

}
