import Cake.LevelSpecific.Garden.Greenhouse.Joy;
import Cake.LevelSpecific.Garden.Greenhouse.Audio.GardenBossPurpleSapAudioComponent;
import Peanuts.Audio.AudioStatics;

class UGardenBossAudioManagerCapability : UHazeCapability
{
	AJoy Joy;
	UGardenBossPurpleSapAudioComponent PurpleSapAudioComp;
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Hammer Plants Phase")
	UAkAudioEvent DropPotPlatformsEvent;
	UPROPERTY(Category = "Hammer Plants Phase")
	UAkAudioEvent PotPlatformPlantSpawnEvent;
	UPROPERTY(Category = "Hammer Plants Phase")
	UAkAudioEvent SpawnHammerPlantsEvent;

	UPROPERTY(Category = "Global")
	UAkAudioEvent GroundWitherEvent;
	UPROPERTY(Category = "Global")
	UAkAudioEvent GroundUnwitherEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Joy = Cast<AJoy>(Owner);
		HazeAkComp = UHazeAkComponent::Get(Joy);
		PurpleSapAudioComp = UGardenBossPurpleSapAudioComponent::GetOrCreate(Joy);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ConsumeAction(n"AudioSummonHammerPlants") == EActionStateStatus::Active || ConsumeAction(n"AudioPlantsDespawning") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(SpawnHammerPlantsEvent);	
		}

		if(ConsumeAction(n"AudioGroundWither") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(GroundWitherEvent);	
		}

		if(ConsumeAction(n"AudioGroundUnWither") == EActionStateStatus::Active)
		{
			HazeAkComp.HazePostEvent(GroundUnwitherEvent);			
		}

		if(ConsumeAction(n"SapPlaneActivated") == EActionStateStatus::Active)
		{
			PurpleSapAudioComp.PaintablePlane = Cast<APaintablePlane>(GetAttributeObject(n"PaintablePlane"));
		}
		
		if(ConsumeAction(n"SapPlaneDeactivated") == EActionStateStatus::Active)
			PurpleSapAudioComp.PaintablePlane = nullptr;		
	}

}