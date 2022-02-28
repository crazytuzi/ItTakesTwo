import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerPlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;

struct FWaterImpactData
{
	UPROPERTY()
	ASubmersibleSoilPlantSprayer ImpactSeedSprayerSoil;

	UPROPERTY()
	FVector ImpactLocation;
}

class USubmersibleSoilMayWaterCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = ECapabilityTickGroups::Input;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerOwner;
	UWaterHoseComponent WaterComponent;
	USeedSprayerWitherSimulationContainerComponent ColorContainerComponent;

	const float WaterRadius = 380.f;
	bool bHasZeroActiveProjectiles = false;
	uint LastImpactFrame = 0;

	TArray<FWaterImpactData> PendingRemoteSeedSprayerImpactData;
	float TimeLeftToSendSeedSprayerToRemote = -1;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		WaterComponent = UWaterHoseComponent::Get(PlayerOwner);
		ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(WaterComponent.GetActiveWaterProjectileAmount() > 0)
			return EHazeNetworkActivation::ActivateLocal;

		if(!HasControl() && PendingRemoteSeedSprayerImpactData.Num() > 0)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bHasZeroActiveProjectiles)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(TimeLeftToSendSeedSprayerToRemote > 0)
			{
				TimeLeftToSendSeedSprayerToRemote -= DeltaTime;
				if(TimeLeftToSendSeedSprayerToRemote <= 0)
				{
					TimeLeftToSendSeedSprayerToRemote = -1;
					NetApplyWaterImpact(PendingRemoteSeedSprayerImpactData);
					PendingRemoteSeedSprayerImpactData.Empty();
				}
			}

			FVector ImpactLocation;
			AActor ImpactActor;
			uint WaterImpactFrame = 0;
			if(WaterComponent.GetImpactActorLocationWithFrame(ImpactActor, ImpactLocation, WaterImpactFrame))
			{	
				ASubmersibleSoil ImpactSoil = Cast<ASubmersibleSoil>(ImpactActor);
				if(LastImpactFrame != WaterImpactFrame && ImpactSoil != nullptr && ImpactSoil.IsWaterable())
				{
					LastImpactFrame = WaterImpactFrame;
					
					FWaterImpactData Impact;
					Impact.ImpactSeedSprayerSoil = Cast<ASubmersibleSoilPlantSprayer>(ImpactActor);
					if(Impact.ImpactSeedSprayerSoil != nullptr)
					{
						Impact.ImpactLocation = ImpactLocation;
						ApplyWaterImpactToSeedSprayerSoil(Impact);
						PendingRemoteSeedSprayerImpactData.Add(Impact);
						if(TimeLeftToSendSeedSprayerToRemote < 0)
							TimeLeftToSendSeedSprayerToRemote = 0.2f;
					}
				}
			}	
		}
		else if(PendingRemoteSeedSprayerImpactData.Num() > 0)
		{
			ApplyWaterImpactToSeedSprayerSoil(PendingRemoteSeedSprayerImpactData[0]);
			PendingRemoteSeedSprayerImpactData.RemoveAt(0);
		}

		// Read this in tick active to garantee that we read the last impact location before closing the capability
		bHasZeroActiveProjectiles = WaterComponent.GetActiveWaterProjectileAmount() == 0 && PendingRemoteSeedSprayerImpactData.Num() == 0;
	}

	UFUNCTION(NetFunction)
	void NetApplyWaterImpact(TArray<FWaterImpactData> PendingRemoteImpactData)
	{
		if(HasControl())
			return;
		
		PendingRemoteSeedSprayerImpactData.Append(PendingRemoteImpactData);
	}

	void ApplyWaterImpactToSeedSprayerSoil(FWaterImpactData Impact)
	{
		if(Impact.ImpactSeedSprayerSoil == nullptr)
			return;
		
		if(ColorContainerComponent.ColorSystem == nullptr)
			return;

		ColorContainerComponent.ColorSystem.PaintWaterOnLocation(Impact.ImpactLocation, WaterRadius);
		ColorContainerComponent.ColorSystem.UpdateFullyPlanted(Impact.ImpactSeedSprayerSoil);
		ColorContainerComponent.ColorSystem.UpdatePercentageEvents(Impact.ImpactSeedSprayerSoil);

		// Force enable the soil when the water amount is full
		if(!Impact.ImpactSeedSprayerSoil.SoilIsActive())
		{
			float Alpha = ColorContainerComponent.ColorSystem.GetSoilWateredPercentage(Impact.ImpactSeedSprayerSoil);
			if(ColorContainerComponent.ColorSystem.DebugCPUSideData)
				Print("Watered %: " + Alpha);

			if(Alpha >= Impact.ImpactSeedSprayerSoil.RequierdPercentageForFullyWatered)
			{
				if(HasControl())
					Impact.ImpactSeedSprayerSoil.NetSetActiveAmount(1.f);
			}
			else
			{
				Impact.ImpactSeedSprayerSoil.SetActiveAmount(Alpha);
				PlayerOwner.SetCapabilityAttributeValue(n"AudioSoilWateredAmount", Alpha);
			}
		}

		if(HasControl() && Impact.ImpactSeedSprayerSoil.ShouldApplyWaterImpact())
		{
			Impact.ImpactSeedSprayerSoil.NetApplyWaterImpact();
		}
	}
}