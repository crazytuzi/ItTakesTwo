import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerPlant;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;

class USickleEnemyKillPlantCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::Input;
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroupOrder = 50;
	
	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;
	USeedSprayerWitherSimulationContainerComponent ColorContainerComponent;

	const float KillPlantRadius = 300.f;
	float DelayToNextPaint = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
		ColorContainerComponent = USeedSprayerWitherSimulationContainerComponent::Get(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ColorContainerComponent.ColorSystem == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Time::GetGameTimeSeconds() < DelayToNextPaint)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DelayToNextPaint = Time::GetGameTimeSeconds() + 0.5f;
		FVector PaintLocation = ActivationParams.ActorParams.GetLocation();
		//ColorContainerComponent.ColorSystem.KillFlowerOnLocation(PaintLocation, KillPlantRadius);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
}