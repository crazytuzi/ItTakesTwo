import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SongHiHat;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

class USongHiHatAudioCapability : UHazeCapability
{
	ASongHiHat HiHat;
	USongOfLifeComponent SongComp;
	AHazePlayerCharacter May;

	bool bHasPlayedFalling = false;
	bool bHasClosed = false;
	float LastPhysValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HiHat = Cast<ASongHiHat>(Owner);
		SongComp = USongOfLifeComponent::Get(Owner);
		May = Game::GetMay();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SongComp.IsAffectedBySongOfLife())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bHasClosed = false;
		bHasPlayedFalling = false;
		HiHat.HazeAkComp.HazePostEvent(HiHat.HiHatRiseEvent);
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bHasClosed)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HiHat.HazeAkComp.HazePostEvent(HiHat.HiHatClosedEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(SongComp.IsAffectedBySongOfLife())
			return;

		if(!bHasPlayedFalling)
		{
			if(ActiveDuration > 0.5)
				HiHat.HazeAkComp.HazePostEvent(HiHat.HiHatFallEvent);

			bHasPlayedFalling = true;
		}

		if(DidHitLowerBound(HiHat.PhysValue.Value))
			bHasClosed = true;
	}


	bool DidHitLowerBound(float CurrentPhysValue)
	{
		return CurrentPhysValue == HiHat.RESTING_PHYS_VALUE;
	}	
}