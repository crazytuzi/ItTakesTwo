import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonActor;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;

class UMagnetHarpoonCatchFishCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHarpoonCatchFishCapability");
	default CapabilityTags.Add(n"MagnetHarpoon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetHarpoonActor MagnetHarpoon;

	AMagnetFishActor ChosenFish;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetHarpoon = Cast<AMagnetHarpoonActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
        	return EHazeNetworkActivation::DontActivate;

		if (MagnetHarpoon.CaughtFish != nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if (MagnetHarpoon.HarpoonSpearState != EHarpoonSpearState::ToTarget)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HasControl())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MagnetHarpoon.CaughtFish != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (MagnetHarpoon.HarpoonSpearState != EHarpoonSpearState::ToTarget)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AMagnetFishActor WantedFish = nullptr;

		for (AMagnetFishActor Fish : MagnetHarpoon.MagnetFishArray)
		{
			if (Fish.IsActorDisabled())
				continue;

			if (Fish.MagnetFishState == EMagnetFishState::Caught || Fish.MagnetFishState == EMagnetFishState::Eaten || Fish.MagnetFishState == EMagnetFishState::Released)
				continue;

			float Distance = (Fish.ActorLocation - MagnetHarpoon.HarpoonSpearSkel.WorldLocation).Size();
			
			if (Distance >= MagnetHarpoon.CatchRadius)
				continue;

			WantedFish = Fish;

			break;
		}
		
		if (MagnetHarpoon.UsingPlayer != nullptr)
			if (MagnetHarpoon.HasControl() == MagnetHarpoon.UsingPlayer.HasControl())
				if (WantedFish != MagnetHarpoon.CaughtFish)
					MagnetHarpoon.NetCatchFish(WantedFish);
	}
}