import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlightCharacterComponent;

class ULightRoomDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LightRoomDeathCapability");

	default CapabilityDebugCategory = n"LightRoomDeathCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeCrumbComponent CrumbComp;
	ULightRoomSpotlightCharacterComponent Comp;

	float DeathTimer = 0.f;
	float DeathTimerDuration = 4.f;
	float HealthTimer = 0.f;
	float TimeToActivateDeathLight = 2.f;
	bool bWasInLight = false;
	bool bControlIsInLight = false;
	bool bHasTriggeredBark = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Comp = ULightRoomSpotlightCharacterComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Comp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!Comp.bLightRoomDeathEnabled) 
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Comp == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!Comp.bLightRoomDeathEnabled) 
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DeathTimer = 0.f;
		HealthTimer = 0.f;
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_PlayerInLight", 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bWasInLight = false;
		bControlIsInLight = false;
		Player.StopForceFeedback(Comp.DeathForceFeedback, n"LightRoomDeath");
		Comp.DeathLightActor.PointLight.SetIntensity(0.f);
		Player.HealPlayerHealth(1.f);
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_PlayerInLight", 1);
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if(HasControl())
		{
			bool bIsInLight = false;

			for (auto LocActor : Comp.SpotlightLocationActors)
			{
				if (LocActor.IsProvidingLightToPlayer(Player))
				{
					bIsInLight = true;
					break;
				}	
			}

			if (!bIsInLight)
			{
				for (auto SafeZone : Comp.SafeZones)
				{
					if (SafeZone.IsProvidingLightToPlayer(Player))
					{
						bIsInLight = true;
						break;
					}	
				}
			}

			if(bIsInLight && !bWasInLight)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddActionState(n"IsInLight");
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetIsInLight"), CrumbParams);
				Player.StopForceFeedback(Comp.DeathForceFeedback, n"LightRoomDeath");
			}
			else if(!bIsInLight && bWasInLight)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetIsInLight"), CrumbParams);
				Player.PlayForceFeedback(Comp.DeathForceFeedback, false, false, n"LightRoomDeath");
			}

			bWasInLight = bIsInLight;
		}

		if(!bControlIsInLight)
		{
			DeathTimer += DeltaTime;
			HealthTimer += DeltaTime;
			
			if (DeathTimer >= TimeToActivateDeathLight)
				Comp.DeathLightActor.PointLight.SetIntensity(FMath::Lerp(0.0f, 100000.f, (DeathTimer - TimeToActivateDeathLight) / (DeathTimerDuration - TimeToActivateDeathLight)));

			if (HealthTimer >= DeathTimerDuration / 8.0f)
			{
				HealthTimer = 0.0f;
				Player.DamagePlayerHealth(0.125f, Comp.DamageEffect);
			}
		}

		//for audio
		if(bControlIsInLight)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_PlayerInLight", 1);
			bHasTriggeredBark = false;
		}
		else if(!bControlIsInLight)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_World_Music_Backstage_Platform_LightRoomSpotLight_PlayerInLight", 0);
			
			if (!bHasTriggeredBark)
			{
				bHasTriggeredBark = true;
				PlayFoghornVOBankEvent(Comp.FoghornDataAsset, n"FoghornDBMusicBackstageLightRoomTakeDamage");
			}
		}
	}

	UFUNCTION()
	private void Crumb_SetIsInLight(const FHazeDelegateCrumbData& CrumbData)
	{
		bControlIsInLight = CrumbData.GetActionState(n"IsInLight");

		if(bControlIsInLight)
		{
			DeathTimer = 0.f;
			HealthTimer = 0.f;
			Comp.DeathLightActor.PointLight.SetIntensity(0.0f);
			Player.HealPlayerHealth(1.f);
		}
	}
}
