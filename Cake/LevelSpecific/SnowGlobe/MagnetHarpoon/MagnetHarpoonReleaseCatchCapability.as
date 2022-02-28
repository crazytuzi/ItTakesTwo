import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
import Vino.Trajectory.TrajectoryStatics;

class UMagnetHarpoonReleaseCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHarpoonReleaseCatchCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHarpoonActor MagnetHarpoon;

	FHazeAcceleratedVector AccelVector;
	FHazeTraceParams TraceParamsFindSurface;

	FVector Velocity;
	FVector NetVelocity;

	float MinYawRange = -35.f;

	float ThrowRange = 600.f;

	float Gravity = 4300.f;
	float ReleaseSpeed = 1200.f;

	float ReleaseFinishedTimer;
	float ReleaseFinishedDefault = 1.f;

	int RandomPlayer;

	bool bFirstTime;

	bool bDeactivateRelease;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(Owner);
		MagnetHarpoon.HarpoonSeal.OnFishEaten.AddUFunction(this, n"FishEaten");
		bFirstTime = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MagnetHarpoon.bPlayerReleasedCatch /* && MagnetHarpoon.CanPendingFire() */)
        	return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bDeactivateRelease)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// PrintToScreen("" + Owner.Name + ": " + MagnetHarpoon.bPlayerReleasedCatch);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if (MagnetHarpoon.SealCamDot >= 0.993f)
			OutParams.AddNumber(n"ThrowToSeal", 1);
		else
			OutParams.AddNumber(n"ThrowToSeal", 0);

		if (bFirstTime)
		{
			bFirstTime = false;
			RandomPlayer = 0;
		}
		else
		{
			if (RandomPlayer == 0)
				RandomPlayer = FMath::RandRange(2, 3);	

			RandomPlayer--;
		}

		OutParams.AddNumber(n"RandomPlayer", RandomPlayer);

		AMagnetFishActor MagnetFish = Cast<AMagnetFishActor>(MagnetHarpoon.CaughtFish);
		OutParams.AddObject(n"MagnetFish", MagnetHarpoon.CaughtFish);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagnetHarpoon.AudioReleaseCatch();
		MagnetHarpoon.SetClawState(EHarpoonClawAnimState::Open);
		AMagnetFishActor MagnetFish = Cast<AMagnetFishActor>(ActivationParams.GetObject(n"MagnetFish"));

		ReleaseFinishedTimer = ReleaseFinishedDefault;

		float SealCheck = ActivationParams.GetNumber(n"ThrowToSeal");

		RandomPlayer = ActivationParams.GetNumber(n"RandomPlayer");

		if (SealCheck == 1)
		{
			if (RandomPlayer == 0)
			{
				if (MagnetHarpoon.UsingPlayer.IsMay())
					PlayFoghornVOBankEvent(MagnetHarpoon.VOLevelBank, n"FoghornDBSnowGlobeLakeMagnetHarpoonFeedSealMay");
				else
					PlayFoghornVOBankEvent(MagnetHarpoon.VOLevelBank, n"FoghornDBSnowGlobeLakeMagnetHarpoonFeedSealCody");
			}

			PrepareSealsAndSetVelocity(MagnetFish, MagnetFish.ActorLocation);
		}
		else
		{
			VelocityNormalReturn(MagnetFish, MagnetFish.ActorLocation);
		}

		MagnetHarpoon.HarpoonSeal.bPlayerHasFish = false;	
		MagnetHarpoon.HarpoonSeal.ClearPreviousFish();

		bDeactivateRelease = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagnetHarpoon.bPlayerReleasedCatch = false;
		MagnetHarpoon.CompleteRelease();
	}

	void VelocityNormalReturn(AMagnetFishActor MagnetFish, FVector FishStartLoc)
	{
		Velocity = CalculateVelocityForPathWithHorizontalSpeed(MagnetHarpoon.AimPoint.WorldLocation, MagnetHarpoon.TraceEndPoint, Gravity, ReleaseSpeed);
		MagnetFish.ReleaseFish(Velocity, Gravity, nullptr);
	}

	void PrepareSealsAndSetVelocity(AMagnetFishActor MagnetFish, FVector FishStartLoc)
	{
		Velocity = CalculateVelocityForPathWithHorizontalSpeed(MagnetFish.ActorLocation, MagnetHarpoon.HarpoonSeal.EatLoc.WorldLocation, Gravity, ReleaseSpeed);
		MagnetFish.ReleaseFish(Velocity, Gravity, MagnetHarpoon.HarpoonSeal);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ReleaseFinishedTimer -= DeltaTime;

		if (ReleaseFinishedTimer <= 0.f)
		{
			bDeactivateRelease = true;
		}
	}

	UFUNCTION()
	void FishEaten()
	{
		bDeactivateRelease = true;
		Online::UnlockAchievement(MagnetHarpoon.UsingPlayer, n"FeedTheSeals");	
	}
}