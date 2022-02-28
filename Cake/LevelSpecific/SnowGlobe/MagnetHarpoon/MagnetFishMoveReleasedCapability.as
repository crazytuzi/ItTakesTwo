import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonHarpSeal;

class MagnetFishMoveReleasedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetFishMoveReleasedCapability");
	default CapabilityTags.Add(n"MagnetFish");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AMagnetFishActor MagnetFish;

	AHarpoonHarpSeal TheSeal;
	
	bool bPlayedSplash;

	bool bReturnedFishToSpline;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetFish = Cast<AMagnetFishActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MagnetFish.MagnetFishState != EMagnetFishState::Released)
        	return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (MagnetFish.MagnetFishState != EMagnetFishState::Released)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		// AHarpoonHarpSeal NetSeal = Cast<AHarpoonHarpSeal>(MagnetFish.ConfirmedSeal);

		// if (NetSeal != nullptr)
		// 	OutParams.AddObject(n"")
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPlayedSplash = false;
		MagnetFish.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld,	EDetachmentRule::KeepWorld);

		TheSeal = Cast<AHarpoonHarpSeal>(MagnetFish.ConfirmedSeal);
		
		if (TheSeal != nullptr)
		{
			TheSeal.SetAnimBoolParam(n"ReadyForFish", true);
			MagnetFish.SkelMesh.SetAnimBoolParam(n"ReadyForFish", true);
		}
		else
		{
			// Print("SEAL IS NULLPTR", 15.f);
		}

		bReturnedFishToSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		ControlMovement(DeltaTime);
		
		if (TheSeal != nullptr)
		{
			float Distance = MagnetFish.GetDistanceTo(TheSeal);

			if (Distance <= TheSeal.EatDistance)
				TheSeal.EatFish(MagnetFish);
		}
		else if (MagnetFish.ActorLocation.Z < MagnetFish.WaterActorReference.ActorLocation.Z && !bPlayedSplash)
		{
			bPlayedSplash = true;
			MagnetFish.WaterSplashComp.Activate(true);
			MagnetFish.HazeAkComp.HazePostEvent(MagnetFish.FishSplashAudioEvent);
		}
	}

	void ControlMovement(float DeltaTime)
	{
		FVector GravityVelocity(0.f, 0.f, MagnetFish.Gravity);
		MagnetFish.Velocity -= GravityVelocity * DeltaTime;
		FVector NextLoc = MagnetFish.ActorLocation + MagnetFish.Velocity * DeltaTime;
		MagnetFish.ActorLocation = NextLoc;

		if (MagnetFish.IsAtStartingValue() && !bReturnedFishToSpline)
		{
			Sync::FullSyncPoint(MagnetFish, n"FishReturn");
			bReturnedFishToSpline = true;
		}
	}
}