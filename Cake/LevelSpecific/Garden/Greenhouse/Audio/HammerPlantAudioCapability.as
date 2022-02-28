import Peanuts.Audio.AudioStatics;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;
import Cake.LevelSpecific.Garden.Greenhouse.JoyHammerPlant;

class UHammerPlantAudioCapability : UHazeCapability
{
	AJoyHammerPlant HammerPlant;
	UHazeAkComponent HazeAkComp;
	float LastPanningPos = 0.f;

	UPROPERTY()
	UAkAudioEvent SpawnEvent;

	UPROPERTY()
	UAkAudioEvent DeSpawnEvent;

	UPROPERTY()
	UAkAudioEvent SlamImpactGroundEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HammerPlant = Cast<AJoyHammerPlant>(Owner);
		HazeAkComp = UHazeAkComponent::Get(HammerPlant);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HammerPlant.bPlantAlive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(HammerPlant.bPlantAlive)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HazeAkComp.HazePostEvent(SpawnEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ConsumeAction(n"AudioSmashImpact") == EActionStateStatus::Active && HammerPlant.JoyPotGrowingPlant == nullptr)
			HazeAkComp.HazePostEvent(SlamImpactGroundEvent);	

		FVector2D ProjectedScreenPosition;
		if(SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), HammerPlant.GetActorLocation(), ProjectedScreenPosition))
		{
			const float NormalizedXPosition = HazeAudio::NormalizeRTPC(ProjectedScreenPosition.X, 0.f, 1.f, -1.f, 1.f);
			if(NormalizedXPosition != LastPanningPos)
			{
				HazeAudio::SetPlayerPanning(HazeAkComp, nullptr, NormalizedXPosition);
			}
		}
	}
}