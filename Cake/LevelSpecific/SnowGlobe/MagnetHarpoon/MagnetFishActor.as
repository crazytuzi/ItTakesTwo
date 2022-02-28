import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishSpline;
import Vino.Animations.PoseTrailComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonWater;

enum EMagnetFishState
{
	OnSpline,
	Caught,
	Eaten,
	Released,
	GoingToSpline
}

class AMagnetFishActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent WaterSplashComp;
	default WaterSplashComp.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeSplineFollowComponent FollowComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;

	UPROPERTY(Category = "Setup")
	AMagnetFishSpline FishSpline;

	UPROPERTY(Category = "Setup")
	AMagnetHarpoonWater WaterActorReference;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncFloat;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FishSplashAudioEvent;

	UPROPERTY(DefaultComponent)
	UPoseTrailComponent PoseTrail;
	default PoseTrail.Interval = 100.f;
	default PoseTrail.BoneInterpolationSpeed = 2.f;
	
	UPROPERTY(Category = "CapabilitySheet")
	UHazeCapabilitySheet CapabilitySheet;

	EMagnetFishState MagnetFishState;

	FHazeTraceParams GroundTrace;

	FHazeSplineSystemPosition SystemPos;
	FVector CurrentLoc;

	FHazeMinMax SpeedRange = FHazeMinMax(80.f, 120.f);
	float Speed;
	float SpeedAddition;
	float TargetDot;

	// UPROPERTY()
	// bool bConfirmThrownToSeal;

	AHazeActor ConfirmedSeal;

	UPROPERTY()
	float PlayRateMultiplier;

	float DespawnTimer;

	float ZStartingValue;
	float ZDifference;

	float Gravity = 5000.f;
	FVector Velocity;

	FHazeAcceleratedRotator AccelRot;
	FHazeAcceleratedVector AccelVelocity;

	FHazeAcceleratedRotator AccelRotMove;
	FHazeAcceleratedVector AccelLocMove;
	FRotator TargetRot;
	FVector TargetLoc;

	FVector StartPos;

	bool TEMP_bHasBeenThrown;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (FishSpline != nullptr)
		{
			FHazeSplineSystemPosition TempSystemPos = FishSpline.Spline.GetPositionAtStart();
			SetActorLocation(TempSystemPos.WorldLocation);
			SetActorRotation(TempSystemPos.WorldRotation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapabilitySheet(CapabilitySheet);
		
		FollowComp.ActivateSplineMovement(FishSpline.Spline);
		ActivateMagnetFish();

		GroundTrace.InitWithCollisionProfile(n"BlockAll");
		GroundTrace.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		GroundTrace.SetToLineTrace();
		ZStartingValue = ActorLocation.Z;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ZDifference = ActorLocation.Z - ZStartingValue;
	}

	bool IsAtStartingValue()
	{
		return ZDifference <= 0.f ? true : false;
	}

	void ActivateMagnetFish()
	{
		if (IsActorDisabled())
		{
			EnableActor(this);
			SkelMesh.SetHiddenInGame(false);
		}

		MagnetFishState = EMagnetFishState::OnSpline;
		SystemPos = FishSpline.Spline.GetPositionAtStart();
		StartPos = SystemPos.WorldLocation;
		Speed = SpeedRange.GetRandomValue();
	}

	UFUNCTION()
	void DeactivateFish()
	{
		if (!IsActorDisabled())
		{
			DisableActor(this);
			SkelMesh.SetHiddenInGame(true);
		}
	}

	UFUNCTION(NetFunction)
	void CatchFish()
	{
		MagnetFishState = EMagnetFishState::Caught;
	}

	void ReleaseFish(FVector InVelocity, float InGravity, AHazeActor SealActor)
	{
		Velocity = InVelocity;
		Gravity = InGravity;

		// bCaught = false;

		MagnetFishState = EMagnetFishState::Released;
		ConfirmedSeal = SealActor;
	}

	UFUNCTION()
	void FishReturn()
	{
		MagnetFishState = EMagnetFishState::GoingToSpline;
	}

	UFUNCTION(NetFunction)
	void NetFishOnSpline()
	{
		SystemPos = FishSpline.Spline.GetPositionClosestToWorldLocation(ActorLocation);
		MagnetFishState = EMagnetFishState::OnSpline;
	}

	void FishBeingEaten()
	{
		MagnetFishState = EMagnetFishState::Eaten;
		SkelMesh.SetAnimBoolParam(n"EatFish", true);
		SkelMesh.SetRelativeScale3D(FVector(1.3f));
		TEMP_bHasBeenThrown = true;
	}
}